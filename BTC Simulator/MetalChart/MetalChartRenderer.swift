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
    
    var pinnedBottom: CGFloat = 40

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
    
    var bestFitVertexBuffer: MTLBuffer?
    var bestFitTriangleCount: Int = 0
    
    // Add a flag so we can print once in draw(in:).
    private var hasLoggedOnce = false
    
    // If you want the pinned axes to know about the "real" top (after margins):
    private var effectiveDomainMaxY: Float = 1.0
    
    private var effectiveDomainMinY: Float = 0.0

    // MARK: - Setup
    
    /// Initializes Metal and sets up the renderer
    func setupMetal(in size: CGSize,
                    chartDataCache: ChartDataCache,
                    simSettings: SimulationSettings)
    {
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
        
        // Create pinned axes renderer
        if let textRenderer = textRendererManager?.getTextRenderer() {
            pinnedAxesRenderer = PinnedAxesRenderer(
                device: device,
                textRenderer: textRenderer,
                textRendererManager: textRendererManager!,
                library: library
            )
            
            pinnedAxesRenderer?.pinnedAxisX = Float(pinnedLeft)
            pinnedAxesRenderer?.domainMaxLogY = domainMaxY
            
        } else {
            print("No textRenderer => pinned axes won't show text.")
        }
    }
    
    // MARK: - Build Data in Log Space
    
    /// Builds the vertex buffer for chart lines in log space
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else {
            print("No chartDataCache or simSettings => skipping.")
            return
        }
        
        var thinLineVertices: [Float] = []    // for normal runs
        var thinLineSizes: [Int] = []
        
        var thickLineVertices: [Float] = []   // for best fit run
        // var thickLineSizes: [Int] = []        // number of *triangle* vertices

        let simulations = cache.allRuns ?? []
        let bestFitId = cache.bestFitRun?.first?.id
        
        // 1) Gather all X and Y to find domain
        var allXVals: [Double] = []
        var allYVals: [Double] = []
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
        
        // 2) Set domain and log scale
        domainMinX = Float(max(0.0, minX))
        domainMaxX = Float(maxX)
        let extendedTop = rawMaxY * 1.2
        let candidateTicks = generateNiceTicks(
            minVal: rawMinY,
            maxVal: extendedTop,
            desiredCount: 15
        )
        guard !candidateTicks.isEmpty else {
            print("generateNiceTicks gave nothing.")
            return
        }
        let finalTick = candidateTicks.last!
        domainMinY = Float(log10(rawMinY))
        domainMaxY = Float(log10(finalTick))
        
        // 3) Build geometry
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor: Color = isBestFit ? .orange :
                customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            // Convert points into [SIMD2<Float>], log-scale y
            let simPoints: [SIMD2<Float>] = sim.points.map { pt in
                let rawX = Float(convertPeriodToYears(pt.week, simSettings))
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                let logY = Float(log10(rawY))
                return SIMD2<Float>(rawX, logY)
            }
            
            if !isBestFit {
                // ------------------------------
                // Normal lines -> lineStrip
                // ------------------------------
                let startThinCount = thinLineVertices.count
                for v in simPoints {
                    // position
                    thinLineVertices.append(v.x)
                    thinLineVertices.append(v.y)
                    thinLineVertices.append(0)
                    thinLineVertices.append(1)
                    
                    // colour
                    thinLineVertices.append(r)
                    thinLineVertices.append(g)
                    thinLineVertices.append(b)
                    thinLineVertices.append(a)
                }
                let addedCount = (thinLineVertices.count - startThinCount) / 8
                thinLineSizes.append(addedCount)
                
            } else {
                // ------------------------------
                // Best fit line -> thick polygons
                // ------------------------------
                
                // We'll store pairs (p1,p2), (p2,p3) etc.
                // For each segment, generate 4 vertices => two triangles forming a rectangle.
                let thicknessInPixels: Float = 2.0 // tweak as you like
                
                // We’ll accumulate the polygons in thickLineVertices
                for i in 0..<(simPoints.count - 1) {
                    let p1 = simPoints[i]
                    let p2 = simPoints[i+1]
                    
                    // Convert these domain coords to screen coords so we can extrude outwards
                    // We reuse "domainToScreen(...)" which you'll add below
                    let s1 = domainToScreen(domainPoint: p1)
                    let s2 = domainToScreen(domainPoint: p2)
                    
                    // direction of the line in screen space
                    let dx = s2.x - s1.x
                    let dy = s2.y - s1.y
                    
                    // normal in screen space (perpendicular)
                    let length = sqrtf(dx*dx + dy*dy + 1e-9)
                    var nx = -dy / length
                    var ny =  dx / length
                    
                    // half the thickness => offset by half on each side
                    nx *= (thicknessInPixels * 0.5)
                    ny *= (thicknessInPixels * 0.5)
                    
                    // build 2 corners around p1
                    let leftP1  = SIMD2<Float>(s1.x + nx, s1.y + ny)
                    let rightP1 = SIMD2<Float>(s1.x - nx, s1.y - ny)
                    
                    // build 2 corners around p2
                    let leftP2  = SIMD2<Float>(s2.x + nx, s2.y + ny)
                    let rightP2 = SIMD2<Float>(s2.x - nx, s2.y - ny)
                    
                    // Now transform them back to domain space so they work
                    // with the same orthographic pipeline
                    let dLeftP1  = screenToDomainPoint(screenPoint: leftP1)
                    let dRightP1 = screenToDomainPoint(screenPoint: rightP1)
                    let dLeftP2  = screenToDomainPoint(screenPoint: leftP2)
                    let dRightP2 = screenToDomainPoint(screenPoint: rightP2)
                    
                    // We add these 2 triangles (dLeftP1, dLeftP2, dRightP1) and (dRightP1, dLeftP2, dRightP2)
                    // But simpler is to add them as a quad in “triangle strip” order:
                    let quadPoints = [
                        dLeftP1,   // 0
                        dLeftP2,   // 1
                        dRightP1,  // 2
                        dRightP2   // 3
                    ]
                    
                    // Each point => 8 floats (pos + colour)
                    // Triangle strip with 4 corners => we’ll just keep appending
                    for qp in quadPoints {
                        thickLineVertices.append(qp.x)
                        thickLineVertices.append(qp.y)
                        thickLineVertices.append(0)
                        thickLineVertices.append(1)
                        
                        thickLineVertices.append(r)
                        thickLineVertices.append(g)
                        thickLineVertices.append(b)
                        thickLineVertices.append(a)
                    }
                }
            }
        }

        // Make GPU buffers
        let device = self.device!
        
        // 4) Thin lines buffer
        let thinByteCount = thinLineVertices.count * MemoryLayout<Float>.size
        let thinBuffer = device.makeBuffer(bytes: thinLineVertices,
                                           length: thinByteCount,
                                           options: .storageModeShared)
        
        // 5) Thick lines buffer
        let thickByteCount = thickLineVertices.count * MemoryLayout<Float>.size
        let thickBuffer = device.makeBuffer(bytes: thickLineVertices,
                                            length: thickByteCount,
                                            options: .storageModeShared)
        
        // Store them somewhere accessible for drawing
        self.vertexBuffer = thinBuffer
        self.lineSizes = thinLineSizes
        
        // For the thick lines, store a separate buffer & sizes
        self.bestFitVertexBuffer = thickBuffer
        self.bestFitTriangleCount = thickLineVertices.count / 8   // each vertex is 8 floats
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
        chartScale = max(1.0, chartScale)
        
        let viewWidth = Float(viewportSize.width)
        let pinnedLeftFloat = Float(pinnedLeft)
        let fracLeft = pinnedLeftFloat / viewWidth
        let fracRight: Float = 1.0
        
        let domainWidth = domainMaxX - domainMinX
        let visibleWidth = domainWidth / chartScale
        
        var visibleMinX = offsetX
        var visibleMaxX = offsetX + visibleWidth
        
        // -- clamp X to domain
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
        
        // pinned transform for X
        let rangeX = visibleMaxX - visibleMinX
        let denom = fracRight - fracLeft
        let leftPart  = fracLeft * rangeX / denom
        let rightPart = (1.0 - fracRight) * rangeX / denom
        let left  = visibleMinX - leftPart
        let right = visibleMaxX + rightPart
        
        // -- Y dimension (log domain)
        let domainHeight = domainMaxY - domainMinY
        let visibleHeight = domainHeight / chartScale
        
        var visibleMinY = offsetY
        var visibleMaxY = offsetY + visibleHeight
        
        // clamp Y
        if visibleMinY < domainMinY {
            visibleMinY = domainMinY
            visibleMaxY = visibleMinY + visibleHeight
        } else if visibleMaxY > domainMaxY {
            visibleMaxY = domainMaxY
            visibleMinY = visibleMaxY - visibleHeight
        }
        offsetY = visibleMinY
        
        // --------------------------------------------------
        //  ADD TOP & BOTTOM MARGINS (in domain space)
        // --------------------------------------------------
        
        // Choose how many screen pixels to spare from the top:
        let topScreenMargin: Float = 30
        // ...and from the bottom:
        let bottomScreenMargin: Float = 20
        
        // domainPerPixel => how many domain units per 1 screen pixel
        let totalScreenHeight = Float(viewportSize.height)
        let domainPerPixel = visibleHeight / totalScreenHeight
        
        // Convert those margins into domain units
        let domainMarginTop = topScreenMargin * domainPerPixel
        let domainMarginBottom = bottomScreenMargin * domainPerPixel
        
        // SHIFT the top domain downward by domainMarginTop
        // SHIFT the bottom domain upward by domainMarginBottom
        let bottom = visibleMinY - domainMarginBottom
        let top    = visibleMaxY + domainMarginTop
        
        // Store these in case pinnedAxesRenderer needs them
        effectiveDomainMinY = bottom
        effectiveDomainMaxY = top

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
        // Print once
        if !hasLoggedOnce {
            print("[MetalChartRenderer] draw(in:) called for the first time.")
            hasLoggedOnce = true
        }
        
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }

        // 1) Convert pinnedLeft and pinnedBottom from points -> device pixels
        let scale = view.contentScaleFactor
        let pinnedLeftPixels   = Int(pinnedLeft   * scale) // pinned y-axis
        let pinnedBottomPixels = Int(pinnedBottom * scale) // pinned x-axis
        
        let viewWidthPixels  = Int(view.drawableSize.width)
        let viewHeightPixels = Int(view.drawableSize.height)
        
        // 2) Set scissor so we keep only the “main chart area,”
        //    i.e. X >= pinnedLeft, Y <= (viewHeight - pinnedBottom).
        let scissorX = pinnedLeftPixels
        let scissorY = 0
        let scissorW = max(0, viewWidthPixels - pinnedLeftPixels)
        let scissorH = max(0, viewHeightPixels - pinnedBottomPixels)
        
        encoder.setScissorRect(MTLScissorRect(
            x: scissorX,
            y: scissorY,
            width: scissorW,
            height: scissorH
        ))
        
        // 3) Draw normal (thin) chart lines
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        
        var startIndex = 0
        for count in lineSizes {
            encoder.drawPrimitives(
                type: .lineStrip,
                vertexStart: startIndex,
                vertexCount: count
            )
            startIndex += count
        }
        
        // 3b) Draw thick best-fit line, if any
        if let bfBuffer = bestFitVertexBuffer, bestFitTriangleCount > 0 {
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(bfBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            
            // We’re using .triangleStrip to render thick geometry
            encoder.drawPrimitives(type: .triangleStrip,
                                   vertexStart: 0,
                                   vertexCount: bestFitTriangleCount)
        }
        
        // 4) Reset scissor => full screen for pinned axes
        encoder.setScissorRect(MTLScissorRect(
            x: 0,
            y: 0,
            width: viewWidthPixels,
            height: viewHeightPixels
        ))
        
        // 5) Draw pinned axes
        if let pinnedAxes = pinnedAxesRenderer {
            if let axisPipeline = pinnedAxes.axisPipelineState {
                encoder.setRenderPipelineState(axisPipeline)
            }
            
            pinnedAxes.viewportSize = view.bounds.size
            pinnedAxes.updateAxes(
                minX: domainMinX,
                maxX: domainMaxX,
                minY: effectiveDomainMinY,
                maxY: effectiveDomainMaxY,
                chartTransform: projectionMatrix
            )
            pinnedAxes.drawAxes(renderEncoder: encoder)
        }

        // 6) Finish
        encoder.endEncoding()
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
    
    /// Convert domain space (x, logY) to *screen* coords using your pinnedLeft logic
    func domainToScreen(domainPoint: SIMD2<Float>) -> SIMD2<Float> {
        // The “updateOrthographic()” sets up an orthographic matrix, but we can
        // do a simpler approach: we figure out fraction across the domain, then convert to screen coords.
        
        let chartWidth = Float(viewportSize.width) - Float(pinnedLeft)
        let domainW = (domainMaxX - domainMinX)
        let fracX = (domainPoint.x - domainMinX) / domainW
        let screenX = Float(pinnedLeft) + fracX * chartWidth
        
        let domainH = (domainMaxY - domainMinY)
        let fracY = (domainPoint.y - domainMinY) / domainH
        let screenY = (1.0 - fracY) * Float(viewportSize.height)
        
        return SIMD2<Float>(x: screenX, y: screenY)
    }

    /// Convert screen space (x,y) back to domain
    func screenToDomainPoint(screenPoint: SIMD2<Float>) -> SIMD2<Float> {
        let chartWidth = Float(viewportSize.width) - Float(pinnedLeft)
        let fracX = (screenPoint.x - Float(pinnedLeft)) / chartWidth
        let domainX = domainMinX + fracX * (domainMaxX - domainMinX)

        let fracY = 1.0 - (screenPoint.y / Float(viewportSize.height))
        let domainY = domainMinY + fracY * (domainMaxY - domainMinY)

        return SIMD2<Float>(x: domainX, y: domainY)
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

/// A simple "nice ticks" function used above.
fileprivate func generateNiceTicks(
    minVal: Double,
    maxVal: Double,
    desiredCount: Int
) -> [Double] {
    guard minVal < maxVal, desiredCount > 0 else { return [] }
    let range = maxVal - minVal
    let rawStep = range / Double(desiredCount)
    let mag = pow(10.0, floor(log10(rawStep)))
    let leading = rawStep / mag
    
    // For a simple approach, we use {1,2,5,10}
    let niceLeading: Double
    if leading < 2.0 {
        niceLeading = 2.0
    } else if leading < 5.0 {
        niceLeading = 5.0
    } else {
        niceLeading = 10.0
    }
    
    let step = niceLeading * mag
    let start = floor(minVal / step) * step
    
    var result: [Double] = []
    var v = start
    while v <= maxVal {
        if v >= minVal { result.append(v) }
        v += step
    }
    return result
}
    
