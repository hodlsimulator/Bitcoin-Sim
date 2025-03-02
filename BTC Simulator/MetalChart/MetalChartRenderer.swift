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
    
    private var glyphOutlineInfos: [GlyphOutlineInfo] = []
    private var computePipelineState: MTLComputePipelineState?
    
    // MARK: - Metal
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var textRendererManager: TextRendererManager?
    
    // MARK: - Chart Data
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    // MARK: - Transform & Viewport
    var viewportSize: CGSize = .zero
    var scaleX: Float = 1.0
    var scaleY: Float = 1.0
    
    /// If older code references `renderer.scale`, we keep it:
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
    
    /// Remember how wide the chart was (in screen points) in its default layout,
    /// so we can clamp future zoom-outs.
    private var baseChartWidthScreen: CGFloat = 0
    
    // MARK: - Setup
    
    private var chartHasLoaded = false
    
    /// Main setup for metal rendering
    func setupMetal(
        in size: CGSize,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        // Optionally clamp chartDataCache.minX so we don't go negative
        self.actualMinX = max(0, chartDataCache.minX)
        self.actualMaxX = chartDataCache.maxX
        
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
        
        // Log for debugging
        print("Initializing TextRendererManager...")
        textRendererManager = TextRendererManager()
        print("TextRendererManager initialized: \(String(describing: textRendererManager))")

        // Ensure TextRendererManager is available before proceeding
        if let textRendererManager = textRendererManager {
            print("TextRendererManager is available, proceeding with setup.")
            
            // Ensure the font atlas and text renderer are generated
            textRendererManager.generateFontAtlasAndRenderer(device: device)
            
            if let textRenderer = textRendererManager.getTextRenderer() {
                print("TextRenderer is available. Proceeding with pipeline setup.")
                
                // Create pinned axes
                pinnedAxesRenderer = PinnedAxesRenderer(
                    device: device,
                    textRenderer: textRenderer,
                    textRendererManager: textRendererManager,
                    library: library
                )
            } else {
                print("TextRenderer is nil after initialization. Cannot proceed.")
                return
            }
        } else {
            print("TextRendererManager is nil. Cannot proceed with setup.")
            return
        }

        // Build the standard (render) pipeline
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
        
        // Build the line buffer from the data
        buildLineBuffer()
        
        // Create uniform buffer for the transform matrix
        transformBuffer = device.makeBuffer(
            length: MemoryLayout<matrix_float4x4>.size,
            options: .storageModeShared
        )
        updateTransform()
        
        // Move chart so left edge is pinned at x=50 initially
        anchorLeftEdgeAtLoad()
        
        // Measure how wide the chart is now
        let defaultLeftX = convertDataToPoint(SIMD2<Float>(actualMinX, 0), viewSize: size).x
        let defaultRightX = convertDataToPoint(SIMD2<Float>(actualMaxX, 0), viewSize: size).x
        baseChartWidthScreen = defaultRightX - defaultLeftX
        
        // If you have pinned axes with GPU-based text
        let fontSize: CGFloat = 14
        if let atlas = generateFontAtlas(device: device,
                                         font: UIFont.systemFont(ofSize: fontSize)) {
            // Update your textRendererManager with the new atlas
            textRendererManager?.updateRuntimeAtlas(atlas)
            
            // Now retrieve a textRenderer that uses that atlas
            if let textRenderer = textRendererManager?.getTextRenderer() {
                // Build pinned axes
                pinnedAxesRenderer = PinnedAxesRenderer(
                    device: device,
                    textRenderer: textRenderer,
                    textRendererManager: textRendererManager!,
                    library: library
                )
            } else {
                print("TextRenderer is nil")
            }
        } else {
            print("Failed to generate font atlas.")
        }
    }
    
    // MARK: - Build Data
    
    func buildLineBuffer() {
        guard let cache = chartDataCache, let simSettings = simSettings else { return }

        // Gather all X values from the data
        var allXValues: [Double] = []
        // Also gather all Y values
        var allYValues: [Double] = []
        
        let simulations = cache.allRuns ?? []
        for sim in simulations {
            for pt in sim.points {
                let rawX = convertPeriodToYears(pt.week, simSettings)
                allXValues.append(rawX)
                
                // Collect Y
                let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
                allYValues.append(rawY)
            }
        }

        // (A) Find minX, maxX
        guard let rawMinX = allXValues.min(),
              let rawMaxX = allXValues.max() else {
            print("No data to build line buffer.")
            return
        }
        
        // (A) Also find minY, maxY
        guard let rawMinY = allYValues.min(),
              let rawMaxY = allYValues.max() else {
            print("No data to build line buffer (no Y).")
            return
        }

        // (A) Clamp the minimum X to 0
        let clampedMinX = max(0, rawMinX)

        // (A) Update actualMinX / actualMaxX
        actualMinX = Float(clampedMinX)
        actualMaxX = Float(rawMaxX)

        // (B) Define yMin as the starting BTC price (must be > 0)
        let startingBTC = max(0.000001, simSettings.initialBTCPriceUSD)
        let yMin = startingBTC
        
        // (B) Define yMax from the data
        let yMax = rawMaxY

        // Build the vertex data with new yMin/yMax
        let (vertexData, lineCounts) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: clampedMinX,
            xMax: rawMaxX,
            yMin: yMin,
            yMax: yMax,
            customPalette: customPalette,
            chartDataCache: cache
        )

        self.lineSizes = lineCounts

        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: byteCount,
            options: .storageModeShared
        )
    }
    
    // MARK: - Updating Transform
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    func updateTransform() {
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
        
        let final = matrix_multiply(translationMatrix, scaleMatrix)
        
        if let ptr = transformBuffer?.contents().bindMemory(
            to: matrix_float4x4.self,
            capacity: 1
        ) {
            ptr.pointee = final
        }
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
        // If your chart adjusts on size changes, do it here
    }
    
    func draw(in view: MTKView) {
        // If view is paused, skip
        if view.isPaused {
            print("View is paused. Skipping draw.")
            return
        }
        
        guard
            let pipelineState    = pipelineState,
            let drawable         = view.currentDrawable,
            let rpd              = view.currentRenderPassDescriptor,
            let commandBuffer    = commandQueue.makeCommandBuffer(),
            let renderEncoder    = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }
        
        //------------------------------------------------
        // 1) Draw the chart lines first, *with* scissoring
        //------------------------------------------------
        let deviceScale  = view.drawableSize.width / view.bounds.size.width
        let scissorX     = Int(pinnedAxisOffset * deviceScale)
        let chartRect    = MTLScissorRect(
            x: scissorX,
            y: 0,
            width: max(0, Int(view.drawableSize.width) - scissorX),
            height: Int(view.drawableSize.height)
        )
        renderEncoder.setScissorRect(chartRect)
        
        // Use the chart pipeline
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set the chart vertex buffer
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Any uniform/transform buffer for the chart
        if let tbuf = transformBuffer {
            renderEncoder.setVertexBuffer(tbuf, offset: 0, index: 1)
        }
        
        // Draw all the line strips
        var offsetIndex = 0
        for count in lineSizes {
            renderEncoder.drawPrimitives(type: .lineStrip,
                                         vertexStart: offsetIndex,
                                         vertexCount: count)
            offsetIndex += count
        }
        
        //----------------------------------------------------
        // 2) Draw pinned axes & text *last*, without scissoring
        //----------------------------------------------------
        let fullRect = MTLScissorRect(
            x: 0,
            y: 0,
            width: Int(view.drawableSize.width),
            height: Int(view.drawableSize.height)
        )
        renderEncoder.setScissorRect(fullRect)
        
        // Update and draw pinned axes on top
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
        
        // Finish the pass
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func runComputePass() {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder(),
              let computePipelineState = computePipelineState else {
            return
        }
        computeEncoder.setComputePipelineState(computePipelineState)

        var glyphCountValue: UInt32 = UInt32(glyphOutlineInfos.count)
        computeEncoder.setBytes(&glyphCountValue,
                                length: MemoryLayout<UInt32>.size,
                                index: 2)

        // Dispatch threads, etc...
        computeEncoder.endEncoding()
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
                
                // Position (x, y, z=0, w=1)
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
        
        let pinnedLeft: CGFloat  = 50
        let pinnedRight: CGFloat = viewportSize.width
        
        // 1) Measure how wide the chart currently is in screen coords
        let dataLeftScreenX  = convertDataToPoint(SIMD2<Float>(actualMinX, 0),
                                                  viewSize: viewportSize).x
        let dataRightScreenX = convertDataToPoint(SIMD2<Float>(actualMaxX, 0),
                                                  viewSize: viewportSize).x
        let chartWidth = dataRightScreenX - dataLeftScreenX
        
        // 2) If the chart is narrower/equal to the viewport, clamp edges
        if chartWidth <= viewportSize.width {
            
            // 2a) If it's below the desired fill width, scale back up
            if chartWidth < baseChartWidthScreen {
                let neededScaleFactorCG = baseChartWidthScreen / chartWidth
                let neededScaleFactor = Float(neededScaleFactorCG)
                
                scaleX *= neededScaleFactor
                scaleY *= neededScaleFactor
                updateTransform()
            }
            
            // 2b) Anchor the left edge so it can't go beyond pinnedLeft=50
            let leftClipPoint = SIMD4<Float>(-1, 0, 0, 1)
            let leftNDC       = currentTransformMatrix() * leftClipPoint
            let leftNDCX      = leftNDC.x / leftNDC.w
            let leftScreenX   = (leftNDCX + 1) * 0.5 * Float(viewportSize.width)
            
            if CGFloat(leftScreenX) > pinnedLeft {
                let delta = Float(pinnedLeft) - leftScreenX
                translation.x += delta / (0.5 * Float(viewportSize.width))
                updateTransform()
            }
            
            // 2c) Anchor the right edge so it can't go beyond pinnedRight
            let rightClipPoint = SIMD4<Float>(+1, 0, 0, 1)
            let rightNDC       = currentTransformMatrix() * rightClipPoint
            let rightNDCX      = rightNDC.x / rightNDC.w
            let rightScreenX   = (rightNDCX + 1) * 0.5 * Float(viewportSize.width)
            
            if CGFloat(rightScreenX) < pinnedRight {
                let delta = Float(pinnedRight) - rightScreenX
                translation.x += delta / (0.5 * Float(viewportSize.width))
                updateTransform()
            }
            
            // 2d) Ensure dataX=0 sits exactly at pinnedLeft=50 if chart <= viewport
            let zeroScreenPt = convertDataToPoint(SIMD2<Float>(0, 0), viewSize: viewportSize)
            let zeroScreenX  = zeroScreenPt.x
            if zeroScreenX != pinnedLeft {
                let delta = pinnedLeft - zeroScreenX
                translation.x += Float(delta) / (0.5 * Float(viewportSize.width))
                updateTransform()
            }
        } else {
            // 3) If the chart is wider than viewport, let user pan off edges
            //    but we still might disallow negative X if desired:
        }
        
        // 4) Finally, ensure we never see negative X in the visible range:
        let (xMinVis2, _) = computeVisibleRangeX()
        if xMinVis2 < 0 {
            let zeroScreenPt = convertDataToPoint(SIMD2<Float>(0, 0), viewSize: viewportSize)
            let zeroScreenX  = zeroScreenPt.x
            if zeroScreenX != pinnedLeft {
                let delta = pinnedLeft - zeroScreenX
                translation.x += Float(delta) / (0.5 * Float(viewportSize.width))
                updateTransform()
            }
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
