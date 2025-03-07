//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based version with pinned axes, auto-fit, and pan/zoom support.
//  Modified to optionally render either BTC or Portfolio data (no snapshots, no orientation observer).
//

import Foundation
import MetalKit
import simd
import SwiftUI

// MARK: - Orthographic uniform
struct TransformUniform {
    var transformMatrix: matrix_float4x4
}

// MARK: - Thick-line uniform (matches ThickLineShaders.metal)
/// Matches the final thickLineMatrixUniforms in Metal
struct ThickLineUniforms {
    var transformMatrix: matrix_float4x4  // 64 bytes
    var viewportSize: SIMD2<Float>        // 8 bytes (2 floats)
    var thicknessPixels: Float            // 4 bytes
    /// We add one float of padding because Metal typically aligns
    /// the next boundary to 16 bytes. This brings total up to 80.
    var _padding: Float = 0              // 4 bytes => total 80
}

// MARK: - CPU struct matching ThickLineVertexIn in .metal
/// Each pair of vertices forms one line segment with side=+1 or -1
struct ThickLineVertexIn {
    var pos: SIMD2<Float>     // domain coords of current
    var nextPos: SIMD2<Float> // domain coords of next
    var side: Float           // +1 or -1
    var color: SIMD4<Float>   // RGBA
}

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    
    // MARK: - Domain & Transform
    
    var domainMinX: Float = 0
    var domainMaxX: Float = 1
    var domainMinY: Float = 0
    var domainMaxY: Float = 1
    
    var offsetX: Float = 0
    var offsetY: Float = 0
    var chartScale: Float = 1.0
    
    private var projectionMatrix = matrix_float4x4(1.0)
    
    var pinnedLeft: CGFloat = 50
    var pinnedBottom: CGFloat = 40

    // MARK: - Metal stuff
    
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    
    /// Pipeline for normal lines
    var pipelineState: MTLRenderPipelineState!
    /// Pipeline for thick best-fit lines
    var thickLinePipelineState: MTLRenderPipelineState!
    
    var uniformBuffer: MTLBuffer?  // for TransformUniform (orthographic)
    var thickLineUniformBuffer: MTLBuffer? // for ThickLineUniforms
    
    var textRendererManager: TextRendererManager?
    
    /// Normal lines
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    
    /// Thick best-fit lines
    var bestFitVertexBuffer: MTLBuffer?
    var bestFitVertexCount: Int = 0  // how many thickLine vertices
    
    var viewportSize: CGSize = .zero
    
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    var pinnedAxesRenderer: PinnedAxesRenderer?
    
    private var hasLoggedOnce = false
    
    private var effectiveDomainMaxY: Float = 1.0
    private var effectiveDomainMinY: Float = 0.0
    
    // We'll add this to remember if it's portfolio or BTC
    private var isPortfolioChart: Bool = false

    // MARK: - Setup
    
    /// Call this once. Provide `isPortfolioChart = true` if you want the portfolio data.
    func setupMetal(
        in size: CGSize,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings,
        isPortfolioChart: Bool = false
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.isPortfolioChart = isPortfolioChart
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported.")
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library.")
            return
        }
        
        // 1) Create the pipeline for normal lines (orthographicVertex)
        let vertexFunction = library.makeFunction(name: "orthographicVertex")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        // position
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDesc.rasterSampleCount = 4
        pipelineDesc.colorAttachments[0].isBlendingEnabled = true
        pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            print("Error creating pipeline state: \(error)")
        }
        
        // 2) Create a second pipeline for thick best-fit lines (screen-space offset)
        guard let thickLineVertexFunc = library.makeFunction(name: "thickLineVertexShader"),
              let thickLineFragmentFunc = library.makeFunction(name: "thickLineFragmentShader")
        else {
            print("Could not find thickLine shaders in library.")
            return
        }
        
        let thickDesc = MTLRenderPipelineDescriptor()
        thickDesc.vertexFunction = thickLineVertexFunc
        thickDesc.fragmentFunction = thickLineFragmentFunc
        thickDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        thickDesc.rasterSampleCount = 4
        thickDesc.colorAttachments[0].isBlendingEnabled = true
        thickDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        thickDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            thickLinePipelineState = try device.makeRenderPipelineState(descriptor: thickDesc)
        } catch {
            print("Error creating thickLine pipeline state: \(error)")
        }
        
        // 3) Create buffers
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<TransformUniform>.size,
            options: .storageModeShared
        )
        thickLineUniformBuffer = device.makeBuffer(
            length: MemoryLayout<ThickLineUniforms>.stride,
            options: .storageModeShared
        )
        
        // 4) Build geometry
        buildLineBuffers()
        
        // 5) Set up for first draw
        viewportSize = size
        autoFitChartWithLeftMargin(viewSize: size, pinnedLeft: pinnedLeft)
        
        // (Optional) text rendering
        textRendererManager = TextRendererManager()
        textRendererManager?.generateFontAtlasAndRenderer(device: device)
        if let textRenderer = textRendererManager?.getTextRenderer() {
            pinnedAxesRenderer = PinnedAxesRenderer(
                device: device,
                textRenderer: textRenderer,
                textRendererManager: textRendererManager!,
                library: library
            )
            pinnedAxesRenderer?.pinnedAxisX = Float(pinnedLeft)
            pinnedAxesRenderer?.domainMaxLogY = domainMaxY
        }
    }
    
    // MARK: - Build Data
    
    /// Build line geometry. If `isPortfolioChart` is true,
    /// we read from `chartDataCache?.portfolioRuns` and `chartDataCache?.bestFitPortfolioRun`;
    /// otherwise, we read from `chartDataCache?.allRuns` and `chartDataCache?.bestFitRun`.
    func buildLineBuffers() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else {
            print("No chart data => skipping.")
            return
        }
        
        // Decide which data set to read
        let (simulations, bestFitRun) = {
            if isPortfolioChart {
                let sims = cache.portfolioRuns ?? []
                let bfID = cache.bestFitPortfolioRun?.first?.id
                return (sims, bfID)
            } else {
                let sims = cache.allRuns ?? []
                let bfID = cache.bestFitRun?.first?.id
                return (sims, bfID)
            }
        }()
        
        if simulations.isEmpty {
            print("No simulations => skipping.")
            return
        }
        
        // Flatten to get X and Y min/max
        var allX: [Double] = []
        var allY: [Double] = []
        
        for run in simulations {
            for pt in run.points {
                // Convert the X axis from weeks/months to years
                let xVal = convertPeriodToYears(pt.week, simSettings)
                allX.append(xVal)
                
                // Our Y is the run value (log scale => must be > 0)
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                allY.append(rawY)
            }
        }
        
        guard let minX = allX.min(),
              let maxX = allX.max(),
              let rawMinY = allY.min(),
              let rawMaxY = allY.max()
        else {
            print("No data => skipping.")
            return
        }
        
        // Domain range for X
        domainMinX = Float(max(0.0, minX))
        domainMaxX = Float(maxX)
        
        // For Y, use log scale
        let extendedTop = rawMaxY * 1.2
        let candidateTicks = generateNiceTicks(
            minVal: rawMinY,
            maxVal: extendedTop,
            desiredCount: 15
        )
        guard !candidateTicks.isEmpty else {
            print("generateNiceTicks => empty.")
            return
        }
        let finalTick = candidateTicks.last!
        
        domainMinY = Float(log10(rawMinY))
        domainMaxY = Float(log10(finalTick))
        
        // Build normal lines vs best-fit thick lines
        var thinLineVerts: [Float] = []
        var thinLineSizes: [Int] = []
        
        var thickLineVerts: [ThickLineVertexIn] = []
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFitRun = (sim.id == bestFitRun)
            let chosenColor: Color = isBestFitRun ? .orange
            : customPalette[runIndex % customPalette.count]
            // Lighter alpha for non-best-fit
            let chosenOpacity: Float = isBestFitRun ? 1.0 : 0.2
            
            // Convert color to RGBA
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            let colVec = SIMD4<Float>(r, g, b, a)
            
            // Build domain coords (x in years, y in log10)
            let runPoints: [SIMD2<Float>] = sim.points.map { pt in
                let rx = Float(convertPeriodToYears(pt.week, simSettings))
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                let ry = Float(log10(rawY))
                return SIMD2<Float>(rx, ry)
            }
            guard runPoints.count >= 2 else { continue }
            
            if !isBestFitRun {
                // Normal lines => old pipeline => lineStrip
                let startIndex = thinLineVerts.count
                for p in runPoints {
                    thinLineVerts.append(p.x)
                    thinLineVerts.append(p.y)
                    thinLineVerts.append(0)
                    thinLineVerts.append(1)
                    
                    thinLineVerts.append(colVec.x)
                    thinLineVerts.append(colVec.y)
                    thinLineVerts.append(colVec.z)
                    thinLineVerts.append(colVec.w)
                }
                let addedCount = (thinLineVerts.count - startIndex) / 8
                thinLineSizes.append(addedCount)
                
            } else {
                // Best-fit => thick line pipeline => for each segment we push 2 vertices
                for i in 0..<(runPoints.count - 1) {
                    let p1 = runPoints[i]
                    let p2 = runPoints[i + 1]
                    
                    thickLineVerts.append(
                        ThickLineVertexIn(pos: p1, nextPos: p2, side: +1, color: colVec)
                    )
                    thickLineVerts.append(
                        ThickLineVertexIn(pos: p1, nextPos: p2, side: -1, color: colVec)
                    )
                }
            }
        }
        
        // Create GPU buffers
        guard let device = self.device else { return }
        
        // Normal lines
        let thinByteCount = thinLineVerts.count * MemoryLayout<Float>.size
        if thinByteCount > 0 {
            self.vertexBuffer = device.makeBuffer(
                bytes: thinLineVerts,
                length: thinByteCount,
                options: .storageModeShared
            )
            self.lineSizes = thinLineSizes
        } else {
            // No normal lines
            self.vertexBuffer = nil
            self.lineSizes = []
        }
        
        // Thick best-fit lines
        let thickByteCount = thickLineVerts.count * MemoryLayout<ThickLineVertexIn>.size
        if thickByteCount > 0 {
            self.bestFitVertexBuffer = device.makeBuffer(
                bytes: thickLineVerts,
                length: thickByteCount,
                options: .storageModeShared
            )
            self.bestFitVertexCount = thickLineVerts.count
        } else {
            // No best-fit lines
            self.bestFitVertexBuffer = nil
            self.bestFitVertexCount = 0
        }
    }
    
    // MARK: - Auto-Fit
    
    func autoFitChartWithLeftMargin(viewSize: CGSize, pinnedLeft: CGFloat = 50) {
        let domainW = domainMaxX - domainMinX
        guard domainW > 0 else { return }
        
        chartScale = 1.0
        offsetX = domainMinX
        offsetY = domainMinY
        
        viewportSize = viewSize
        updateOrthographic()
    }
    
    // MARK: - Orthographic
    
    func updateOrthographic() {
        let viewWidth = Float(viewportSize.width)
        let pinnedLeftFloat = Float(pinnedLeft)
        let fracLeft = pinnedLeftFloat / viewWidth
        let fracRight: Float = 1.0
        
        let domainWidth = domainMaxX - domainMinX
        let visibleWidth = domainWidth / chartScale
        
        var visibleMinX = offsetX
        var visibleMaxX = offsetX + visibleWidth
        
        if visibleMinX < domainMinX {
            visibleMinX = domainMinX
            visibleMaxX = visibleMinX + visibleWidth
        } else if visibleMaxX > domainMaxX {
            visibleMaxX = domainMaxX
            visibleMinX = visibleMaxX - visibleWidth
        }
        offsetX = visibleMinX
        
        let rangeX = visibleMaxX - visibleMinX
        let denom = fracRight - fracLeft
        let leftPart  = fracLeft * rangeX / denom
        let rightPart = (1.0 - fracRight) * rangeX / denom
        let left  = visibleMinX - leftPart
        let right = visibleMaxX + rightPart
        
        let domainH = domainMaxY - domainMinY
        let visibleH = domainH / chartScale
        
        var visibleMinY = offsetY
        var visibleMaxY = offsetY + visibleH
        
        if visibleMinY < domainMinY {
            visibleMinY = domainMinY
            visibleMaxY = visibleMinY + visibleH
        } else if visibleMaxY > domainMaxY {
            visibleMaxY = domainMaxY
            visibleMinY = visibleMaxY - visibleH
        }
        offsetY = visibleMinY
        
        // add top/bottom margin in domain units
        let topMarginPixels: Float = 30
        let botMarginPixels: Float = 20
        let totalScreenHeight = Float(viewportSize.height)
        let domainPerPixel = visibleH / totalScreenHeight
        
        let domainMarginTop = topMarginPixels * domainPerPixel
        let domainMarginBot = botMarginPixels * domainPerPixel
        
        let bottom = visibleMinY - domainMarginBot
        let top    = visibleMaxY + domainMarginTop
        
        effectiveDomainMinY = bottom
        effectiveDomainMaxY = top
        
        let proj = makeOrthographicMatrix(
            left: left, right: right,
            bottom: bottom, top: top,
            near: 0, far: 1
        )
        projectionMatrix = proj
        
        // write to uniform buffer
        if let ptr = uniformBuffer?.contents().bindMemory(to: matrix_float4x4.self, capacity: 1) {
            ptr.pointee = proj
        }
    }
    
    func makeOrthographicMatrix(left: Float, right: Float,
                                bottom: Float, top: Float,
                                near: Float, far: Float) -> matrix_float4x4
    {
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
            SIMD4<Float>(sx, 0,   0,   0),
            SIMD4<Float>(0,  sy,  0,   0),
            SIMD4<Float>(0,  0,   sz,  0),
            SIMD4<Float>(tx, ty,  tz,  1)
        ))
    }
    
    // MARK: - Draw
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        viewportSize = view.bounds.size
        updateOrthographic()
    }
    
    func draw(in view: MTKView) {
        if !hasLoggedOnce {
            print("[MetalChartRenderer] draw(in:) called first time.")
            hasLoggedOnce = true
        }
        
        guard let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let cmdBuf = commandQueue.makeCommandBuffer(),
              let encoder = cmdBuf.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }
        
        // 1) scissor to main chart area
        let scale = view.contentScaleFactor
        let pinnedLeftPixels   = Int(pinnedLeft * scale)
        let pinnedBottomPixels = Int(pinnedBottom * scale)
        let vwPixels = Int(view.drawableSize.width)
        let vhPixels = Int(view.drawableSize.height)
        
        let scissorX = pinnedLeftPixels
        let scissorY = 0
        let scissorW = max(0, vwPixels - pinnedLeftPixels)
        let scissorH = max(0, vhPixels - pinnedBottomPixels)
        
        encoder.setScissorRect(MTLScissorRect(
            x: scissorX,
            y: scissorY,
            width: scissorW,
            height: scissorH
        ))
        
        // 2) draw normal lines with orthographic pipeline
        encoder.setRenderPipelineState(pipelineState)
        if let vb = vertexBuffer,
           let ub = uniformBuffer {
            encoder.setVertexBuffer(vb, offset: 0, index: 0)
            encoder.setVertexBuffer(ub, offset: 0, index: 1)
            
            var start = 0
            for count in lineSizes {
                encoder.drawPrimitives(type: .lineStrip,
                                       vertexStart: start,
                                       vertexCount: count)
                start += count
            }
        }
        
        // 2b) draw thick best-fit lines using the thickLine pipeline
        if let thickPSO = thickLinePipelineState,
           let thickBuf = bestFitVertexBuffer,
           bestFitVertexCount > 0
        {
            // Fill in the thickLine uniforms (transformMatrix + viewport + thickness)
            if let ptr = thickLineUniformBuffer?.contents().bindMemory(
                to: ThickLineUniforms.self, capacity: 1
            ) {
                ptr.pointee.transformMatrix = projectionMatrix
                ptr.pointee.viewportSize = SIMD2<Float>(
                    Float(view.drawableSize.width),
                    Float(view.drawableSize.height)
                )
                // Let thickness shrink with zoom, but clamp to a minimal width
                let baseThickness: Float = 9.0
                ptr.pointee.thicknessPixels = max(baseThickness / chartScale, 5.0)
            }
            
            encoder.setRenderPipelineState(thickPSO)
            encoder.setVertexBuffer(thickBuf, offset: 0, index: 0)
            encoder.setVertexBuffer(thickLineUniformBuffer, offset: 0, index: 1)
            
            // triangleStrip => for each segment we have 2 vertices => forms a thick line
            encoder.drawPrimitives(type: .triangleStrip,
                                   vertexStart: 0,
                                   vertexCount: bestFitVertexCount)
        }
        
        // 3) reset scissor => full screen => pinned axes
        encoder.setScissorRect(MTLScissorRect(
            x: 0,
            y: 0,
            width: vwPixels,
            height: vhPixels
        ))
        
        // 4) pinned axes
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
        
        encoder.endEncoding()
        cmdBuf.present(drawable)
        cmdBuf.commit()
    }
    
    // MARK: - Utils
    
    let customPalette: [Color] = [.white, .yellow, .red, .blue, .green]
    
    func colorToFloats(_ c: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let ui = UIColor(c)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        aa *= CGFloat(opacity)
        return (Float(rr), Float(gg), Float(bb), Float(aa))
    }
    
    func convertPeriodToYears(_ w: Int, _ settings: SimulationSettings) -> Double {
        if settings.periodUnit == .weeks {
            return Double(w) / 52.0
        } else {
            return Double(w) / 12.0
        }
    }
    
    /// Convert a screen coordinate to domain coordinate, accounting for pinnedLeft
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

// MARK: - Ticks
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
