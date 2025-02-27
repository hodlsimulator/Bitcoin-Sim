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
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    // Transform properties
    var viewportSize: CGSize = .zero
    var scale: Float = 1.0
    var translation = SIMD2<Float>(0, 0)
    var transformBuffer: MTLBuffer?
    
    // (NEW) A pinned axes renderer
    var pinnedAxesRenderer: PinnedAxesRenderer?
    
    // (OPTIONAL) Example visible min/max (for pinned axes)
    var xMinVis: Float = 0
    var xMaxVis: Float = 10
    var yMinVis: Float = 1
    var yMaxVis: Float = 1_000_000
    
    // MARK: - Setup
    
    func setupMetal(
        in size: CGSize,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        // 1) Create the default MTLDevice
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported on this machine.")
            return
        }
        self.device = device
        
        // 2) Create the command queue
        commandQueue = device.makeCommandQueue()
        
        // 3) Build your main chart pipeline
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library.")
            return
        }
        
        let vertexFunction   = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        // position float4
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // color float4
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
        
        // Enable blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // Enable MSAA for smoother lines
        pipelineDescriptor.rasterSampleCount = 4
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print(">> Pipeline state created successfully.")
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }
        
        // 4) Build the static vertex buffer for your lines (using your chartDataCache, etc.)
        buildLineBuffer()
        
        // 5) Create the transform uniform buffer
        transformBuffer = device.makeBuffer(
            length: MemoryLayout<matrix_float4x4>.size,
            options: .storageModeShared
        )
        updateTransform()
        
        // 6) (NEW) Create a pinned axes renderer + text renderer for axis labels, if desired
        
        // 6a) Build a GPU font atlas
        let fontSize: CGFloat = 14
        if let fontAtlas = generateFontAtlas(
            device: device,
            font: UIFont.systemFont(ofSize: fontSize)
        ) {
            // 6b) Create a GPU text renderer
            let textRenderer = RuntimeGPUTextRenderer(
                device: device,
                atlas: fontAtlas,
                library: library
            )
            
            // 6c) Create your pinned axes renderer (from your PinnedAxesRenderer.swift)
            //     It may build its own pipeline or reuse a second pipeline function in AxisShaders.metal.
            pinnedAxesRenderer = PinnedAxesRenderer(
                device: device,
                textRenderer: textRenderer,
                library: library
            )
            
            // optional: tweak axis styling
            pinnedAxesRenderer?.axisColor  = SIMD4<Float>(1, 1, 1, 1)
            pinnedAxesRenderer?.labelColor = SIMD4<Float>(0.8, 0.8, 0.8, 1.0)
        }
        
        // If your pinned axes approach uses “screen space” vertices and a specialized vertex shader:
        // pinnedAxesRenderer might do something like:
        //
        //    let axisVertexFunc = library.makeFunction(name: "axisVertexShader_screenSpace")
        //    let axisFragFunc   = library.makeFunction(name: "axisFragmentShader")
        //    // build pipeline ...
        //
        // That is typically done INSIDE the pinned axes renderer’s init or pipeline-building method.
        
        // Done! You’re now set up with your main chart pipeline + pinned axes pipeline.
    }
    
    // MARK: - Building Line Data
    
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else { return }
        
        let simulations = cache.allRuns ?? []
        
        // Build vertex data for your lines
        let (vertexData, lineSizes) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: 0.0,
            xMax: (simSettings.periodUnit == .weeks)
            ? Double(simSettings.userPeriods) / 52.0
            : Double(simSettings.userPeriods) / 12.0,
            yMin: 1.0,
            yMax: 1_000_000_000_000.0,
            customPalette: customPalette,
            chartDataCache: cache
        )
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: byteCount,
            options: .storageModeShared
        )
        self.lineSizes = lineSizes
    }
    
    // MARK: - Updating Transform
    
    func updateTransform() {
        // The final transform is translation * scale
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        let transform = matrix_multiply(translationMatrix, scaleMatrix)
        
        let bufferPointer = transformBuffer?.contents().bindMemory(
            to: matrix_float4x4.self,
            capacity: 1
        )
        bufferPointer?.pointee = transform
    }
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
        print(">> updateViewport() - new size: \(size)")
    }
    
    private func currentTransformMatrix() -> matrix_float4x4 {
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        return matrix_multiply(translationMatrix, scaleMatrix)
    }
    
    // MARK: - Coordinate Conversion
    
    func convertPointToNDC(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndx = Float(point.x / viewSize.width) * 2.0 - 1.0
        let ndy = Float((viewSize.height - point.y) / viewSize.height) * 2.0 - 1.0
        return SIMD2<Float>(ndx, ndy)
    }
    
    func convertPointToData(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndc = convertPointToNDC(point, viewSize: viewSize)
        let ndcVec = SIMD4<Float>(ndc.x, ndc.y, 0, 1)
        let inverseTransform = simd_inverse(currentTransformMatrix())
        let dataVec = matrix_multiply(inverseTransform, ndcVec)
        return SIMD2<Float>(dataVec.x, dataVec.y)
    }
    
    func convertDataToPoint(_ dataCoord: SIMD2<Float>, viewSize: CGSize) -> CGPoint {
        let dataVec = SIMD4<Float>(dataCoord.x, dataCoord.y, 0, 1)
        let ndcVec = matrix_multiply(currentTransformMatrix(), dataVec)
        let xScreen = (ndcVec.x + 1) * 0.5 * Float(viewSize.width)
        let yScreen = (1 - (ndcVec.y + 1) * 0.5) * Float(viewSize.height)
        return CGPoint(x: CGFloat(xScreen), y: CGFloat(yScreen))
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print(">> drawableSizeWillChange() - new drawableSize: \(size)")
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
        
        // --- Optional: Recompute visible data range from transform (so xMinVis, etc. are accurate) ---
        // updateVisibleRangeFromTransform()
        // (This method, if implemented, would invert your transform matrix or track bounding boxes to find
        //  the portion of the data currently in view.)
        
        // --- 1) Draw Chart Lines ---
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Provide your transform (scale+translate) buffer
        if let transformBuffer = transformBuffer {
            renderEncoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        }
        
        // For each simulation run’s line data, draw it as a line strip
        var offsetIndex = 0
        for count in lineSizes {
            renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: offsetIndex, vertexCount: count)
            offsetIndex += count
        }
        
        // --- 2) Update and Draw Pinned Axes ---
        if let pinnedAxes = pinnedAxesRenderer {
            // Pass the screen size to pinnedAxes, so it knows how big the view is
            pinnedAxes.viewportSize = view.bounds.size
            
            // Suppose xMinVis..yMaxVis are manually set or computed from inverse transform
            pinnedAxes.updateAxes(
                minX: xMinVis,
                maxX: xMaxVis,
                minY: yMinVis,
                maxY: yMaxVis,
                chartTransform: currentTransformMatrix()
            )
            
            // Draw axis lines + tick labels in screen space
            pinnedAxes.drawAxes(renderEncoder: renderEncoder)
        }
        
        // --- 3) Finish ---
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
    // MARK: - Build Vertex Data
    
    /// A palette used when building line data (change colours as desired).
    let customPalette: [Color] = [
        .white,
        .yellow,
        .red,
        .blue,
        .green
    ]
    
    /// Builds an array of float-based vertex data (positions + colours) and
    /// an array of line segment sizes, one per simulation run.
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
        
        // Optionally, handle a "best fit" run separately
        let bestFitId = chartDataCache.bestFitRun?.first?.id
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor: Color = isBestFit ? .orange : customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            var vertexCount = 0
            for pt in sim.points {
                let rawX = convertPeriodToYears(pt.week, simSettings)
                let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
                
                // normalise X -> [-1..1]
                let ratioX = (rawX - xMin) / (xMax - xMin)
                let nx = Float(ratioX * 2.0 - 1.0)
                
                // normalise Y on a log scale -> [-1..1]
                let logVal = log10(rawY)
                let logMin = log10(yMin)
                let logMax = log10(yMax)
                let ratioY = (logVal - logMin) / (logMax - logMin)
                let ny = Float(ratioY * 2.0 - 1.0)
                
                // Position
                vertexData.append(nx)
                vertexData.append(ny)
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
    
    /// Converts SwiftUI Color to RGBA floats, factoring in 'opacity'.
    func colorToFloats(_ swiftColor: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let uiColor = UIColor(swiftColor)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        alpha *= CGFloat(opacity)
        return (Float(red), Float(green), Float(blue), Float(alpha))
    }
}
