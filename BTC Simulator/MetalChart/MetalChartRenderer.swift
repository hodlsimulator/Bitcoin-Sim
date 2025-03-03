//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based version with pinned axes pass.
//

import Foundation
import MetalKit
import simd
import SwiftUI

// MARK: - Uniform struct for transformation matrix
struct TransformUniform {
    var transformMatrix: matrix_float4x4
}

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    
    // MARK: - Domain & Transform
    
    /// Minimum x-value in domain space
    var domainMinX: Float = 0
    /// Maximum x-value in domain space
    var domainMaxX: Float = 1
    /// Minimum y-value in domain space (log scale)
    var domainMinY: Float = 0
    /// Maximum y-value in domain space (log scale)
    var domainMaxY: Float = 1000
    
    /// X-offset in domain space for panning
    var offsetX: Float = 0
    /// Y-offset in domain space for panning
    var offsetY: Float = 0
    
    /// Single scale factor for zooming both axes
    var chartScale: Float = 1.0
    
    /// Orthographic projection matrix
    private var projectionMatrix = matrix_float4x4(1.0)
    
    /// Left margin in pixels where the y-axis is pinned
    var pinnedLeft: CGFloat = 50

    // MARK: - Metal Properties
    
    /// Metal device
    var device: MTLDevice!
    /// Command queue for rendering
    var commandQueue: MTLCommandQueue!
    /// Pipeline state for rendering chart lines
    var pipelineState: MTLRenderPipelineState!
    
    /// Buffer for storing the projection matrix
    private var uniformBuffer: MTLBuffer?
    
    /// Manager for text rendering (optional)
    var textRendererManager: TextRendererManager?
    
    /// Buffer containing vertex data for chart lines
    var vertexBuffer: MTLBuffer?
    /// Number of vertices per line
    var lineSizes: [Int] = []
    
    /// Size of the MTKView in points
    var viewportSize: CGSize = .zero
    
    /// Cached chart data (declared elsewhere in your project)
    var chartDataCache: ChartDataCache?
    /// Simulation settings (declared elsewhere in your project)
    var simSettings: SimulationSettings?

    /// Renderer for pinned axes (declared elsewhere in your project)
    var pinnedAxesRenderer: PinnedAxesRenderer?
    
    // MARK: - Setup
    
    /// Initializes Metal and sets up the renderer
    func setupMetal(in size: CGSize,
                    chartDataCache: ChartDataCache,
                    simSettings: SimulationSettings) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported on this machine.")
            return
        }
        self.device = device
        commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library.")
            return
        }
        
        // Set up text rendering (optional)
        textRendererManager = TextRendererManager()
        textRendererManager?.generateFontAtlasAndRenderer(device: device)
        
        // Create the main chart pipeline
        let vertexFunction = library.makeFunction(name: "orthographicVertex")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // color
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable MSAA if you’d like
        pipelineDesc.rasterSampleCount = 4
        
        // Enable blending
        pipelineDesc.colorAttachments[0].isBlendingEnabled = true
        pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            print("Error creating pipeline state: \(error)")
        }
        
        // Create uniform buffer
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<TransformUniform>.size,
            options: .storageModeShared
        )
        
        // Build the vertex buffer for chart lines
        buildLineBuffer()
        
        // Initialise transforms
        viewportSize = size
        autoFitChartWithLeftMargin(viewSize: size, pinnedLeft: pinnedLeft)
        
        // Create pinned axes renderer (optional)
        if let textRenderer = textRendererManager?.getTextRenderer() {
            pinnedAxesRenderer = PinnedAxesRenderer(
                device: device,
                textRenderer: textRenderer,
                textRendererManager: textRendererManager!,
                library: library
            )
            
            pinnedAxesRenderer?.pinnedAxisX = Float(pinnedLeft)
        } else {
            print("No textRenderer => pinned axes won't show text.")
        }
    }
    
    // MARK: - Build Data in Log Space
    
    /// Builds the vertex buffer for chart lines in log space
    func buildLineBuffer() {
        guard let cache = chartDataCache, let simSettings = simSettings else {
            print("No chartDataCache or simSettings => skipping")
            return
        }
        
        var allXVals: [Double] = []
        var allYVals: [Double] = []
        
        let simulations = cache.allRuns ?? []
        for run in simulations {
            for pt in run.points {
                let xVal = convertPeriodToYears(pt.week, simSettings)
                allXVals.append(xVal)
                
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                allYVals.append(rawY)
            }
        }
        
        guard let minX = allXVals.min(),
              let maxX = allXVals.max(),
              let rawMinY = allYVals.min(),
              let rawMaxY = allYVals.max() else {
            print("No data => skipping line build.")
            return
        }
        
        // Convert to float
        let finalMinX = max(0.0, minX)
        let logMinY = log10(rawMinY)
        let logMaxY = log10(rawMaxY)
        
        domainMinX = Float(finalMinX)
        domainMaxX = Float(maxX)
        domainMinY = Float(logMinY)
        domainMaxY = Float(logMaxY)
        
        var vertexData: [Float] = []
        var lineCounts: [Int] = []
        
        let bestFitId = cache.bestFitRun?.first?.id
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor: Color = isBestFit ? .orange : customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            var vertexCount = 0
            for pt in sim.points {
                let rawX = Float(convertPeriodToYears(pt.week, simSettings))
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                let logY = Float(log10(rawY))
                
                // Position
                vertexData.append(rawX)
                vertexData.append(logY)
                vertexData.append(0)
                vertexData.append(1)
                
                // Colour
                vertexData.append(r)
                vertexData.append(g)
                vertexData.append(b)
                vertexData.append(a)
                
                vertexCount += 1
            }
            lineCounts.append(vertexCount)
        }
        
        lineSizes = lineCounts
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: byteCount,
                                         options: .storageModeShared)
        
        print("Created line buffer with \(vertexData.count) floats. Y is log scale.")
    }
    
    /// Automatically fits the chart to display the entire domain with a pinned left margin
    func autoFitChartWithLeftMargin(viewSize: CGSize, pinnedLeft: CGFloat = 50) {
        self.pinnedLeft = pinnedLeft
        let domainW = domainMaxX - domainMinX
        let domainH = domainMaxY - domainMinY
        guard domainW > 0, domainH > 0 else { return }
        
        let chartWidthPx = max(1, viewSize.width - pinnedLeft)
        let chartHeightPx = max(1, viewSize.height)
        
        let scaleX = Float(chartWidthPx) / domainW
        let scaleY = Float(chartHeightPx) / domainH
        
        chartScale = min(scaleX, scaleY)
        offsetX = domainMinX
        offsetY = domainMinY
        viewportSize = viewSize
        updateOrthographic()
        
        print("AutoFit => pinnedLeft=\(pinnedLeft), chartScale=\(chartScale), offsetX=\(offsetX), offsetY=\(offsetY)")
    }
    
    /// Colour palette for chart lines
    let customPalette: [Color] = [.white, .yellow, .red, .blue, .green]
    
    /// Converts a SwiftUI Color to RGBA floats
    func colorToFloats(_ c: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let ui = UIColor(c)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        aa *= CGFloat(opacity)
        return (Float(rr), Float(gg), Float(bb), Float(aa))
    }
    
    /// Converts simulation period to years
    func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
        // Keep as Double here, but we cast to Float later when needed
        if simSettings.periodUnit == .weeks {
            return Double(week) / 52.0
        } else {
            return Double(week) / 12.0
        }
    }
    
    // MARK: - Orthographic Projection
    
    /// Updates the orthographic projection matrix
    func updateOrthographic() {
        let viewWidth = Float(viewportSize.width)
        let pinnedLeftFloat = Float(pinnedLeft)
        
        // Define the screen space mapping fractions
        let fracLeft = pinnedLeftFloat / viewWidth   // pinned side
        let fracRight: Float = 1.0                   // right edge is 1.0 in fraction
        
        // Calculate the visible domain width based on the scale
        let domainWidth = domainMaxX - domainMinX
        let visibleWidth = domainWidth / chartScale
        
        // Calculate visible range with offset, clamped to domain bounds
        var visibleMinX = offsetX
        var visibleMaxX = offsetX + visibleWidth
        
        // Clamp the visible range to stay within [domainMinX, domainMaxX]
        if visibleMinX < domainMinX {
            visibleMinX = domainMinX
            visibleMaxX = visibleMinX + visibleWidth
            if visibleMaxX > domainMaxX {
                visibleMaxX = domainMaxX
                visibleMinX = visibleMaxX - visibleWidth
            }
        } else if visibleMaxX > domainMaxX {
            visibleMaxX = domainMaxX
            visibleMinX = visibleMaxX - visibleWidth
            if visibleMinX < domainMinX {
                visibleMinX = domainMinX
                visibleMaxX = visibleMinX + visibleWidth
            }
        }
        
        // Update offsetX to reflect clamped visibleMinX
        offsetX = visibleMinX
        
        // Break it into smaller pieces
        let rangeX = (visibleMaxX - visibleMinX)
        let denom = (fracRight - fracLeft)
        
        let leftPart = fracLeft * rangeX / denom
        let one: Float = 1.0
        let rightPart = (one - fracRight) * rangeX / denom
        
        // These final `left` and `right` now use the *current* visible range
        let left = visibleMinX - leftPart
        let right = visibleMaxX + rightPart
        
        // If you also want vertical panning, do the same clamp logic for Y:
        let domainHeight = domainMaxY - domainMinY
        let visibleHeight = domainHeight / chartScale
        var visibleMinY = offsetY
        var visibleMaxY = offsetY + visibleHeight
        
        // (Optional: clamp if you want to prevent scrolling below domainMinY)
        // if visibleMinY < domainMinY { ... etc. }
        // offsetY = visibleMinY
        
        let bottom = domainMinY  // or visibleMinY if you want vertical panning
        let top    = domainMaxY  // or visibleMaxY
        
        // Build the projection matrix
        let near: Float = 0
        let far: Float = 1
        projectionMatrix = makeOrthographicMatrix(
            left: left,
            right: right,
            bottom: bottom,
            top: top,
            near: near,
            far: far
        )
        
        // Store it in the uniform buffer
        if let ptr = uniformBuffer?.contents().bindMemory(to: matrix_float4x4.self, capacity: 1) {
            ptr.pointee = projectionMatrix
        }
        
        // Debugging
        print("DEBUG [updateOrthographic]:")
        print("  domainMinX=\(domainMinX), domainMaxX=\(domainMaxX), domainMinY=\(domainMinY), domainMaxY=\(domainMaxY)")
        print("  offsetX=\(offsetX), offsetY=\(offsetY), chartScale=\(chartScale)")
        print("  pinnedLeft=\(pinnedLeft), viewWidth=\(viewWidth)")
        print("  visibleMinX=\(visibleMinX), visibleMaxX=\(visibleMaxX)")
        print("  => orthographic left=\(left), right=\(right), bottom=\(bottom), top=\(top)")
    }
    
    /// Creates an orthographic projection matrix
    func makeOrthographicMatrix(left: Float, right: Float,
                                bottom: Float, top: Float,
                                near: Float, far: Float) -> matrix_float4x4 {
        let rml = right - left
        let tmb = top - bottom
        let fmn = far - near
        
        let sx = 2.0 / rml
        let sy = 2.0 / tmb
        let sz = 1.0 / fmn
        
        let tx = -(right + left) / rml
        let ty = -(top + bottom) / tmb
        let tz = -near / fmn
        
        return matrix_float4x4(columns: (
            SIMD4<Float>(sx, 0, 0, 0),
            SIMD4<Float>(0, sy, 0, 0),
            SIMD4<Float>(0, 0, sz, 0),
            SIMD4<Float>(tx, ty, tz, 1)
        ))
    }
    
    // MARK: - MTKViewDelegate Methods
    
    /// Updates the viewport size
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    /// Handles drawable size changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let newSize = view.bounds.size
        viewportSize = newSize
        updateOrthographic()
    }
    
    /// Renders the chart
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        
        // Render chart lines
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        var startIndex = 0
        for count in lineSizes {
            encoder?.drawPrimitives(
                type: .lineStrip,
                vertexStart: startIndex,
                vertexCount: count
            )
            startIndex += count
        }
        
        // Render pinned axes (if available)
        if let pinnedAxes = pinnedAxesRenderer {
            if let axisPipeline = pinnedAxes.axisPipelineState {
                encoder?.setRenderPipelineState(axisPipeline)
            }
            
            pinnedAxes.viewportSize = view.bounds.size
            pinnedAxes.updateAxes(
                minX: domainMinX,
                maxX: domainMaxX,
                minY: domainMinY,
                maxY: domainMaxY,
                chartTransform: projectionMatrix
            )
            pinnedAxes.drawAxes(renderEncoder: encoder!)
        }

        encoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    /// Converts screen coordinates to domain coordinates
    func screenToDomain(_ screenPoint: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let pinnedLeftFloat = Float(pinnedLeft)
        let chartWidth = Float(viewSize.width) - pinnedLeftFloat
        let fracX = (Float(screenPoint.x) - pinnedLeftFloat) / chartWidth
        let visibleWidth = (domainMaxX - domainMinX) / chartScale
        let domainX = offsetX + fracX * visibleWidth
        
        let domainHeight = domainMaxY - domainMinY
        let fracY = 1.0 - (Float(screenPoint.y) / Float(viewSize.height))
        let domainY = domainMinY + fracY * domainHeight
        
        return SIMD2<Float>(domainX, domainY)
    }
}

// Helper extension for matrix initialisation
extension matrix_float4x4 {
    init(_ scalar: Float) {
        self.init(
            SIMD4<Float>(scalar, 0, 0, 0),
            SIMD4<Float>(0, scalar, 0, 0),
            SIMD4<Float>(0, 0, scalar, 0),
            SIMD4<Float>(0, 0, 0, scalar)
        )
    }
}
