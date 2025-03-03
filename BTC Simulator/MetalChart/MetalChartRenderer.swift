//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based version with pinned axes, auto-fit, and pan/zoom support.
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
    
    /// Minimum x-value in domain space (typically 0)
    var domainMinX: Float = 0
    /// Maximum x-value in domain space
    var domainMaxX: Float = 1
    /// Minimum y-value in domain space (log scale)
    var domainMinY: Float = 0
    /// Maximum y-value in domain space (log scale)
    var domainMaxY: Float = 1
    
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
        
        // (Optional) set up text rendering
        textRendererManager = TextRendererManager()
        textRendererManager?.generateFontAtlasAndRenderer(device: device)
        
        // Create the main chart pipeline
        let vertexFunction = library.makeFunction(name: "orthographicVertex")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // colour
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable MSAA if you like
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
        
        // Build the vertex buffer for chart lines (log scale if you like)
        buildLineBuffer()
        
        // Prepare initial transforms & pinned left margin
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
            print("No chartDataCache or simSettings => skipping.")
            return
        }
        
        var allXVals: [Double] = []
        var allYVals: [Double] = []
        
        let simulations = cache.allRuns ?? []
        for run in simulations {
            for pt in run.points {
                let xVal = convertPeriodToYears(pt.week, simSettings)
                allXVals.append(xVal)
                
                // clamp Y > 0
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                allYVals.append(rawY)
            }
        }
        
        // Find overall min/max
        guard let minX = allXVals.min(),
              let maxX = allXVals.max(),
              let rawMinY = allYVals.min(),
              let rawMaxY = allYVals.max() else {
            print("No data => skipping line build.")
            return
        }
        
        // Store them in domain variables
        let finalMinX = max(0.0, minX)
        domainMinX = Float(finalMinX)
        domainMaxX = Float(maxX)
        
        // log scale for Y
        domainMinY = Float(log10(rawMinY))
        domainMaxY = Float(log10(rawMaxY))
        
        // Build one big vertex array
        var vertexData: [Float] = []
        var lineCounts: [Int] = []
        
        let bestFitId = cache.bestFitRun?.first?.id
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor: Color = isBestFit
                ? .orange
                : customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            var vertexCount = 0
            for pt in sim.points {
                let rawX = Float(convertPeriodToYears(pt.week, simSettings))
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                let logY = Float(log10(rawY))
                
                // Position in "domain space" (x, log10(y))
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
        
        // Finalise
        lineSizes = lineCounts
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: byteCount,
                                         options: .storageModeShared)
        print("Created line buffer with \(vertexData.count) floats. Y is log scale.")
    }
    
    // MARK: - Auto-Fit to Screen
    
    /// Makes the entire domain from domainMinX..domainMaxX visible from pinnedLeft..(right edge).
    func autoFitChartWithLeftMargin(viewSize: CGSize, pinnedLeft: CGFloat = 50) {
        let domainW = domainMaxX - domainMinX
        guard domainW > 0 else { return }
        
        // Set chartScale = 1.0 so visibleWidth = domainWidth
        chartScale = 1.0
        
        // Entire domain initially visible
        offsetX = domainMinX
        offsetY = domainMinY
        
        // Save size
        viewportSize = viewSize
        
        // Rebuild
        updateOrthographic()
    }
    
    /// Basic colour palette for chart lines
    let customPalette: [Color] = [.white, .yellow, .red, .blue, .green]
    
    /// Converts a SwiftUI Color to RGBA floats
    func colorToFloats(_ c: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let ui = UIColor(c)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        aa *= CGFloat(opacity)
        return (Float(rr), Float(gg), Float(bb), Float(aa))
    }
    
    /// Convert a simulation period in weeks (or months) to fractional years
    func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
        if simSettings.periodUnit == .weeks {
            return Double(week) / 52.0
        } else {
            // e.g. if periodUnit == .months
            return Double(week) / 12.0
        }
    }
    
    // MARK: - Orthographic Projection with pinned-left
    
    /// Updates the orthographic projection matrix
    func updateOrthographic() {
        // Clamp so we can't zoom out smaller than the initial size
        chartScale = max(1.0, chartScale)
        
        let viewWidth = Float(viewportSize.width)
        let pinnedLeftFloat = Float(pinnedLeft)
        
        // fraction of total width that is pinned margin
        let fracLeft = pinnedLeftFloat / viewWidth
        let fracRight: Float = 1.0 // right edge fraction = 1.0
        
        // total domain in X
        let domainWidth = domainMaxX - domainMinX
        
        // given chartScale, find how wide the visible domain is
        let visibleWidth = domainWidth / chartScale
        
        // portion of domain we are showing
        var visibleMinX = offsetX
        var visibleMaxX = offsetX + visibleWidth
        
        // clamp to [domainMinX..domainMaxX]
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
        offsetX = visibleMinX
        
        // pinned transform: map [visibleMinX..visibleMaxX] => [fracLeft..1.0]
        let rangeX = visibleMaxX - visibleMinX
        let denom = fracRight - fracLeft
        
        let leftPart  = fracLeft * rangeX / denom
        let rightPart = (1.0 - fracRight) * rangeX / denom
        
        let left  = visibleMinX - leftPart
        let right = visibleMaxX + rightPart
        
        // --- Y dimension: same logic for vertical zoom/pan ---
        let domainHeight = domainMaxY - domainMinY
        let visibleHeight = domainHeight / chartScale
        
        var visibleMinY = offsetY
        var visibleMaxY = offsetY + visibleHeight
        
        // clamp Y if you want
        if visibleMinY < domainMinY {
            visibleMinY = domainMinY
            visibleMaxY = visibleMinY + visibleHeight
        } else if visibleMaxY > domainMaxY {
            visibleMaxY = domainMaxY
            visibleMinY = visibleMaxY - visibleHeight
        }
        offsetY = visibleMinY
        
        let bottom = visibleMinY
        let top    = visibleMaxY
        
        // Build orthographic matrix
        let near: Float = 0
        let far:  Float = 1
        projectionMatrix = makeOrthographicMatrix(
            left: left,
            right: right,
            bottom: bottom,
            top: top,
            near: near,
            far: far
        )
        
        // Store in uniform buffer
        if let ptr = uniformBuffer?.contents().bindMemory(to: matrix_float4x4.self, capacity: 1) {
            ptr.pointee = projectionMatrix
        }
        
        // Debug
        print("DEBUG [updateOrthographic]: chartScale=\(chartScale)")
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
            SIMD4<Float>(sx,   0,   0,   0),
            SIMD4<Float>(0,    sy,  0,   0),
            SIMD4<Float>(0,    0,   sz,  0),
            SIMD4<Float>(tx,   ty,  tz,  1)
        ))
    }
    
    // MARK: - MTKViewDelegate
    
    /// Updates the viewport size
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    /// Called when the drawable size changes
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        let newSize = view.bounds.size
        viewportSize = newSize
        updateOrthographic()
    }
    
    /// Renders the chart each frame
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        
        // Render the lines
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        var startIndex = 0
        for count in lineSizes {
            encoder?.drawPrimitives(type: .lineStrip,
                                    vertexStart: startIndex,
                                    vertexCount: count)
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
    
    // MARK: - Helpers
    
    /// Converts a screen coordinate to domain coordinate, accounting for pinnedLeft
    func screenToDomain(_ screenPoint: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let pinnedLeftFloat = Float(pinnedLeft)
        let chartWidth = Float(viewSize.width) - pinnedLeftFloat
        
        // fraction across the workable region
        let fracX = (Float(screenPoint.x) - pinnedLeftFloat) / chartWidth
        
        // domain window = domainWidth / chartScale
        let domainW = (domainMaxX - domainMinX)
        let visibleWidth = domainW / chartScale
        
        let domainX = offsetX + fracX * visibleWidth
        
        // Y dimension
        let domainHeight = domainMaxY - domainMinY
        let fracY = 1.0 - (Float(screenPoint.y) / Float(viewSize.height))
        let domainY = domainMinY + fracY * domainHeight
        
        return SIMD2<Float>(domainX, domainY)
    }
}

// MARK: - matrix_float4x4 convenience
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
