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
    // MARK: - Metal Properties
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
    var scale: Float = 1.0
    var translation = SIMD2<Float>(0, 0)
    var transformBuffer: MTLBuffer?
    
    // We’ll store the actual min/max of data’s X to ensure the *true* left edge is pinned
    private var actualMinX: Float = 0
    private var actualMaxX: Float = 1
    
    // MARK: - Axes
    var pinnedAxesRenderer: PinnedAxesRenderer?
    
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
        
        // Build the pipeline
        let vertexFunction   = library.makeFunction(name: "vertexShader")
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
        
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // If you want MSAA for smoother lines:
        pipelineDescriptor.rasterSampleCount = 4
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }
        
        // Build line vertex data
        buildLineBuffer()
        
        // Create a uniform buffer for transforms
        transformBuffer = device.makeBuffer(
            length: MemoryLayout<matrix_float4x4>.size,
            options: .storageModeShared
        )
        
        // Initial transform
        updateTransform()
        
        // Optional pinned axes
        let fontSize: CGFloat = 14
        if let fontAtlas = generateFontAtlas(device: device,
                                             font: UIFont.systemFont(ofSize: fontSize)) {
            let textRenderer = RuntimeGPUTextRenderer(device: device,
                                                      atlas: fontAtlas,
                                                      library: library)
            pinnedAxesRenderer = PinnedAxesRenderer(device: device,
                                                    textRenderer: textRenderer,
                                                    library: library)
        }
    }
    
    // MARK: - Build Line Data
    
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else { return }
        
        // Collect all X values from all runs so we can find the *true* min & max
        var allXValues: [Double] = []
        
        let simulations = cache.allRuns ?? []
        for sim in simulations {
            for pt in sim.points {
                let rawX = convertPeriodToYears(pt.week, simSettings)
                allXValues.append(rawX)
            }
        }
        
        guard let minX = allXValues.min(), let maxX = allXValues.max() else {
            print("No data to build line buffer")
            return
        }
        
        // Save these so anchorLeftEdge() can reference them
        actualMinX = Float(minX)
        actualMaxX = Float(maxX)
        
        // We'll normalise from [minX..maxX] to [-1..+1]
        let (vertexData, lineSizes) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: minX,
            xMax: maxX,
            yMin: 1.0,
            yMax: 1_000_000_000_000.0,
            customPalette: customPalette,
            chartDataCache: cache
        )
        
        self.lineSizes = lineSizes
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: byteCount,
                                         options: .storageModeShared)
    }
    
    // MARK: - Updating Transform
    
    /// Called by SwiftUI when the view size changes
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    /// Rebuilds the T*S matrix, stores it in `transformBuffer`.
    func updateTransform() {
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        
        let finalTransform = matrix_multiply(translationMatrix, scaleMatrix)
        
        let ptr = transformBuffer?.contents().bindMemory(
            to: matrix_float4x4.self,
            capacity: 1
        )
        ptr?.pointee = finalTransform
    }
    
    /// Returns the current T*S matrix, which your coordinator might also need.
    func currentTransformMatrix() -> matrix_float4x4 {
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        return matrix_multiply(translationMatrix, scaleMatrix)
    }
    
    // MARK: - Coordinate Conversions (Gesture Coordinator Needs)
    
    /// Convert a screen point (UIKit coords) -> NDC [-1..+1].
    func convertPointToNDC(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndx = Float(point.x / viewSize.width) * 2.0 - 1.0
        // Flip Y because UIKit top-left is (0,0)
        let ndy = Float((viewSize.height - point.y) / viewSize.height) * 2.0 - 1.0
        return SIMD2<Float>(ndx, ndy)
    }
    
    /// Convert screen point -> data coords (like unproject).
    func convertPointToData(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndc2 = convertPointToNDC(point, viewSize: viewSize)
        let ndc4 = SIMD4<Float>(ndc2.x, ndc2.y, 0, 1)
        let invT = simd_inverse(currentTransformMatrix())
        let data4 = invT * ndc4
        return SIMD2<Float>(data4.x, data4.y)
    }
    
    /// Convert data coords -> screen points (like project).
    func convertDataToPoint(_ dataCoord: SIMD2<Float>, viewSize: CGSize) -> CGPoint {
        let d4 = SIMD4<Float>(dataCoord.x, dataCoord.y, 0, 1)
        let ndc4 = currentTransformMatrix() * d4
        let ndcX = ndc4.x / ndc4.w
        let ndcY = ndc4.y / ndc4.w
        
        let screenX = CGFloat((ndcX + 1) * 0.5) * viewSize.width
        let screenY = CGFloat(1 - ((ndcY + 1) * 0.5)) * viewSize.height
        return CGPoint(x: screenX, y: screenY)
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Called when the view changes size; do any needed recalculations here.
    }
    
    func draw(in view: MTKView) {
        // 1) Pin the chart's left edge (the real minX in data) to the pinned axis
        anchorLeftEdge()
        
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }
        
        // 2) Draw lines
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        if let transformBuffer = transformBuffer {
            renderEncoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        }
        
        var offsetIndex = 0
        for count in lineSizes {
            renderEncoder.drawPrimitives(type: .lineStrip,
                                         vertexStart: offsetIndex,
                                         vertexCount: count)
            offsetIndex += count
        }
        
        // 3) Draw pinned axes
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
        
        // 4) Finish
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
        var lineSizes: [Int] = []
        
        let bestFitId = chartDataCache.bestFitRun?.first?.id
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor = isBestFit ? Color.orange : customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            var vertexCount = 0
            for pt in sim.points {
                // Convert 'week' to x in data space
                let rawX = convertPeriodToYears(pt.week, simSettings)
                // Convert the decimal to a Double for Y
                let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
                
                // Normalise X from [minX..maxX] to [-1..+1]
                let ratioX = (rawX - xMin) / (xMax - xMin) // 0..1
                let ndcX = Float(ratioX * 2.0 - 1.0)       // -1..+1
                
                // Normalise Y in log scale -> [-1..+1]
                let logVal = log10(rawY)
                let logMin = log10(yMin)
                let logMax = log10(yMax)
                let ratioY = (logVal - logMin) / (logMax - logMin) // 0..1
                let ndcY = Float(ratioY * 2.0 - 1.0)               // -1..+1
                
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
            lineSizes.append(vertexCount)
        }
        
        return (vertexData, lineSizes)
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
    
    // MARK: - Possibly needed by your code
    /// Example for turning weeks -> years or months -> years
    func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
        // fill in however you were doing it
        if simSettings.periodUnit == .weeks {
            return Double(week) / 52.0
        } else {
            return Double(week) / 12.0
        }
    }
    
    // MARK: - Pin the left edge so the chart's min X aligns with pinned Y-axis
    
    /// Forces the chart’s *true* min X data to remain at the pinned axis.
    /// The pinned axis in `PinnedAxesRenderer` is typically 50 px from the left.
    private func anchorLeftEdge() {
        guard viewportSize.width > 0 else { return }
        
        // The PinnedAxesRenderer draws the vertical axis at 50 px from left.
        let pinnedScreenX: Float = 50
        
        // Convert pinnedScreenX to NDC:  (0..width) -> (-1..+1)
        let desiredNDC_X = (pinnedScreenX / Float(viewportSize.width)) * 2.0 - 1.0
        
        // The *true* minimum X in data space was normalised to -1 in the vertex data.
        // So let’s see where “-1 in clip space” currently transforms to *now*:
        // We can just directly check: a point at clipX=-1 => ( -1, 0, 0, 1 ).
        // Where is that on screen after the current transform?
        
        let testClipPoint = SIMD4<Float>(-1, 0, 0, 1)
        let ndc = currentTransformMatrix() * testClipPoint
        let currentNDC_X = ndc.x / ndc.w
        
        // Compare to the desired pinned axis location in clip coords
        let delta = desiredNDC_X - currentNDC_X
        
        if abs(delta) > 0.00001 {
            translation.x += delta
            updateTransform()
        }
    }
}
