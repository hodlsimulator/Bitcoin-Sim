//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import MetalKit
import simd
import SwiftUI // for Color

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    // MARK: - Metal
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    // MARK: - Chart Data
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    // MARK: - Transform & Viewport
    var viewportSize: CGSize = .zero
    var scaleX: Float = 1.0
    var scaleY: Float = 1.0
    
    // If older code references `renderer.scale`, we keep it:
    var scale: Float {
        get {
            (scaleX + scaleY) * 0.5
        }
        set {
            scaleX = newValue
            scaleY = newValue
            updateTransform()
        }
    }
    
    var translation = SIMD2<Float>(0, 0)
    var transformBuffer: MTLBuffer?
    
    // Store actual data min/max for X
    private var actualMinX: Float = 0
    private var actualMaxX: Float = 1
    
    // MARK: - Axes
    var pinnedAxesRenderer: PinnedAxesRenderer?
    private let pinnedAxisOffset: CGFloat = 50
    
    // This will remember how wide the chart was (in screen points) in its default layout,
    // so we can clamp future zoom-outs.
    private var baseChartWidthScreen: CGFloat = 0
    
    // MARK: - Setup
    
    func setupMetal(
        in size: CGSize,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings
    ) {
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
        
        // Build pipeline
        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable alpha blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // MSAA
        pipelineDescriptor.rasterSampleCount = 4
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }
        
        buildLineBuffer()
        
        // Create uniform buffer for the transform matrix
        transformBuffer = device.makeBuffer(
            length: MemoryLayout<matrix_float4x4>.size,
            options: .storageModeShared
        )
        updateTransform()
        
        // Move chart so left edge is pinned at x=50 initially
        anchorLeftEdgeAtLoad()
        
        // Measure how wide the chart is now (default fill) so we can keep it from shrinking below that
        let defaultLeftX = convertDataToPoint(SIMD2<Float>(actualMinX, 0), viewSize: size).x
        let defaultRightX = convertDataToPoint(SIMD2<Float>(actualMaxX, 0), viewSize: size).x
        baseChartWidthScreen = defaultRightX - defaultLeftX
        
        // If you have pinned axes with GPU-based text
        let fontSize: CGFloat = 14
        if let fontAtlas = generateFontAtlas(device: device, font: UIFont.systemFont(ofSize: fontSize)) {
            let textRenderer = RuntimeGPUTextRenderer(device: device, atlas: fontAtlas, library: library)
            pinnedAxesRenderer = PinnedAxesRenderer(device: device, textRenderer: textRenderer, library: library)
        }
    }
    
    // MARK: - Build Data
    
    func buildLineBuffer() {
        guard let cache = chartDataCache, let simSettings = simSettings else { return }
        
        var allXValues: [Double] = []
        let simulations = cache.allRuns ?? []
        for sim in simulations {
            for pt in sim.points {
                let rawX = convertPeriodToYears(pt.week, simSettings)
                allXValues.append(rawX)
            }
        }
        
        guard let minX = allXValues.min(), let maxX = allXValues.max() else {
            print("No data to build line buffer.")
            return
        }
        
        actualMinX = Float(minX)
        actualMaxX = Float(maxX)
        
        let (vertexData, lineCounts) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: minX,
            xMax: maxX,
            yMin: 1.0,
            yMax: 1_000_000_000_000.0,
            customPalette: customPalette,
            chartDataCache: cache
        )
        
        self.lineSizes = lineCounts
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: byteCount,
                                         options: .storageModeShared)
    }
    
    // MARK: - Updating Transform
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    func updateTransform() {
        // SxSy
        let scaleMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(scaleX, 0, 0, 0),
            SIMD4<Float>(0, scaleY, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
        
        // T
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        
        let final = matrix_multiply(translationMatrix, scaleMatrix)
        
        let ptr = transformBuffer?.contents().bindMemory(
            to: matrix_float4x4.self,
            capacity: 1
        )
        ptr?.pointee = final
    }
    
    func currentTransformMatrix() -> matrix_float4x4 {
        let scaleMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(scaleX, 0, 0, 0),
            SIMD4<Float>(0, scaleY, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        ))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        return matrix_multiply(translationMatrix, scaleMatrix)
    }
    
    // MARK: - Coordinate Conversions
    
    func convertPointToNDC(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndx = Float(point.x / viewSize.width) * 2.0 - 1.0
        let ndy = Float((viewSize.height - point.y) / viewSize.height) * 2.0 - 1.0
        return SIMD2<Float>(ndx, ndy)
    }
    
    func convertPointToData(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndc2 = convertPointToNDC(point, viewSize: viewSize)
        let ndc4 = SIMD4<Float>(ndc2.x, ndc2.y, 0, 1)
        let invMatrix = simd_inverse(currentTransformMatrix())
        let data4 = invMatrix * ndc4
        return SIMD2<Float>(data4.x, data4.y)
    }
    
    func convertDataToPoint(_ dataCoord: SIMD2<Float>, viewSize: CGSize) -> CGPoint {
        let data4 = SIMD4<Float>(dataCoord.x, dataCoord.y, 0, 1)
        let ndc4 = currentTransformMatrix() * data4
        let ndcX = ndc4.x / ndc4.w
        let ndcY = ndc4.y / ndc4.w
        
        let screenX = CGFloat((ndcX + 1) * 0.5) * viewSize.width
        let screenY = CGFloat(1.0 - ((ndcY + 1) * 0.5)) * viewSize.height
        return CGPoint(x: screenX, y: screenY)
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Typically handle if needed
    }
    
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }
        
        // 1) Draw lines with scissor from x=50
        renderEncoder.setRenderPipelineState(pipelineState)
        
        let deviceScale = view.drawableSize.width / view.bounds.size.width
        let scissorX = Int(pinnedAxisOffset * deviceScale)
        
        renderEncoder.setScissorRect(MTLScissorRect(
            x: scissorX,
            y: 0,
            width: max(0, Int(view.drawableSize.width) - scissorX),
            height: Int(view.drawableSize.height)
        ))
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        if let tbuf = transformBuffer {
            renderEncoder.setVertexBuffer(tbuf, offset: 0, index: 1)
        }
        
        var offsetIndex = 0
        for count in lineSizes {
            renderEncoder.drawPrimitives(type: .lineStrip,
                                         vertexStart: offsetIndex,
                                         vertexCount: count)
            offsetIndex += count
        }
        
        // 2) Draw pinned axes (no scissor)
        renderEncoder.setScissorRect(MTLScissorRect(
            x: 0,
            y: 0,
            width: Int(view.drawableSize.width),
            height: Int(view.drawableSize.height)
        ))
        
        if let pinnedAxes = pinnedAxesRenderer {
            pinnedAxes.viewportSize = view.bounds.size
            
            let (xMinVis, xMaxVis) = computeVisibleRangeX()
            let (yMinVis, yMaxVis) = computeVisibleRangeY()
            
            pinnedAxes.updateAxes(
                minX: xMinVis,
                maxX: xMaxVis,
                minY: yMinVis,
                maxY: yMaxVis,
                chartTransform: currentTransformMatrix()
            )
            pinnedAxes.drawAxes(renderEncoder: renderEncoder)
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // MARK: - Build Vertex Data
    
    let customPalette: [Color] = [
        .white,
        .yellow,
        .red,
        .blue,
        .green
    ]
    
    func buildLineVertexData(
        simulations: [SimulationRun],
        simSettings: SimulationSettings,
        xMin: Double,
        xMax: Double,
        yMin: Double,
        yMax: Double,
        customPalette: [Color],
        chartDataCache: ChartDataCache
    ) -> ([Float], [Int]) {
        
        var vertexData: [Float] = []
        var lineCounts: [Int] = []
        
        let bestFitId = chartDataCache.bestFitRun?.first?.id
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor = isBestFit ? Color.orange : customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            var vertexCount = 0
            for pt in sim.points {
                let rawX = convertPeriodToYears(pt.week, simSettings)
                let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
                
                // Normalise x
                let ratioX = (rawX - xMin) / (xMax - xMin)
                let ndcX = Float(ratioX * 2.0 - 1.0)
                
                // Log scale y => [-1..+1]
                let logVal = log10(rawY)
                let logMin = log10(yMin)
                let logMax = log10(yMax)
                let ratioY = (logVal - logMin) / (logMax - logMin)
                let ndcY = Float(ratioY * 2.0 - 1.0)
                
                // Vertex position
                vertexData.append(ndcX)
                vertexData.append(ndcY)
                vertexData.append(0.0)
                vertexData.append(1.0)
                
                // Colour
                vertexData.append(r)
                vertexData.append(g)
                vertexData.append(b)
                vertexData.append(a)
                
                vertexCount += 1
            }
            lineCounts.append(vertexCount)
        }
        
        return (vertexData, lineCounts)
    }
    
    func colorToFloats(_ c: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        a *= CGFloat(opacity)
        return (Float(r), Float(g), Float(b), Float(a))
    }
    
    // MARK: - Visible Range
    
    func computeVisibleRangeX() -> (Float, Float) {
        let inv = simd_inverse(currentTransformMatrix())
        let leftNDC  = SIMD4<Float>(-1, 0, 0, 1)
        let rightNDC = SIMD4<Float>(+1, 0, 0, 1)
        
        let leftData  = inv * leftNDC
        let rightData = inv * rightNDC
        
        let xMinVis = min(leftData.x / leftData.w, rightData.x / rightData.w)
        let xMaxVis = max(leftData.x / leftData.w, rightData.x / rightData.w)
        return (xMinVis, xMaxVis)
    }
    
    func computeVisibleRangeY() -> (Float, Float) {
        let inv = simd_inverse(currentTransformMatrix())
        let bottomNDC = SIMD4<Float>(0, -1, 0, 1)
        let topNDC    = SIMD4<Float>(0, +1, 0, 1)
        
        let bottomData = inv * bottomNDC
        let topData    = inv * topNDC
        
        let yMinVis = min(bottomData.y / bottomData.w, topData.y / topData.w)
        let yMaxVis = max(bottomData.y / bottomData.w, topData.y / topData.w)
        return (yMinVis, yMaxVis)
    }
    
    // MARK: - Pin Edges
    
    func anchorLeftEdgeAtLoad() {
        guard viewportSize.width > 0 else { return }
        
        let pinnedLeft: Float = 50
        let leftClipPoint = SIMD4<Float>(-1, 0, 0, 1)
        let ndc = currentTransformMatrix() * leftClipPoint
        let leftNDCX = ndc.x / ndc.w
        let leftScreenX = (leftNDCX + 1) * 0.5 * Float(viewportSize.width)
        
        let delta = pinnedLeft - leftScreenX
        translation.x += delta / (0.5 * Float(viewportSize.width))
        updateTransform()
    }
    
    /// Ensures we never shrink below our "default" width and also anchors the chart edges.
    func anchorEdges() {
        guard viewportSize.width > 0 else { return }
        
        let pinnedLeft: CGFloat = 50
        let pinnedRight: CGFloat = viewportSize.width
        
        // 1) Check how wide the chart is in screen coords right now
        let dataLeftScreenX = convertDataToPoint(SIMD2<Float>(actualMinX, 0), viewSize: viewportSize).x
        let dataRightScreenX = convertDataToPoint(SIMD2<Float>(actualMaxX, 0), viewSize: viewportSize).x
        let chartWidth = dataRightScreenX - dataLeftScreenX
        
        // If it's below our default fill width, scale back up
        if chartWidth < baseChartWidthScreen {
            let neededScaleFactor = Float(baseChartWidthScreen / chartWidth)
            scaleX *= neededScaleFactor
            scaleY *= neededScaleFactor
            updateTransform()
        }
        
        // 2) Anchor the left edge at pinnedLeft
        let leftClipPoint = SIMD4<Float>(-1, 0, 0, 1)
        let leftNDC = currentTransformMatrix() * leftClipPoint
        let leftNDCX = leftNDC.x / leftNDC.w
        let leftScreenX = (leftNDCX + 1) * 0.5 * Float(viewportSize.width)
        
        if CGFloat(leftScreenX) > pinnedLeft {
            let delta = Float(pinnedLeft) - leftScreenX
            translation.x += delta / (0.5 * Float(viewportSize.width))
        }
        
        // 3) Anchor the right edge at pinnedRight
        let rightClipPoint = SIMD4<Float>(+1, 0, 0, 1)
        let rightNDC = currentTransformMatrix() * rightClipPoint
        let rightNDCX = rightNDC.x / rightNDC.w
        let rightScreenX = (rightNDCX + 1) * 0.5 * Float(viewportSize.width)
        
        if CGFloat(rightScreenX) < pinnedRight {
            let delta = Float(pinnedRight) - rightScreenX
            translation.x += delta / (0.5 * Float(viewportSize.width))
        }
        
        updateTransform()
    }
    
    // MARK: - Possibly needed
    
    func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
        if simSettings.periodUnit == .weeks {
            return Double(week) / 52.0
        } else {
            return Double(week) / 12.0
        }
    }
}
