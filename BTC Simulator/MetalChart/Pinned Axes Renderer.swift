//
//  PinnedAxesRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import MetalKit
import simd
import UIKit

struct ViewportSize {
    var size: SIMD2<Float>
}

class PinnedAxesRenderer {
    
    var idleManager: IdleManager?
    var textRendererManager: TextRendererManager
    
    let device: MTLDevice
    let textRenderer: GPUTextRenderer
    
    var axisPipelineState: MTLRenderPipelineState?
    
    // Set each frame from outside
    var viewportSize: CGSize = .zero
    
    // Pinned at the left edge (x=0)
    var pinnedAxisX: Float = 0
    
    // Colours
    var axisColor = SIMD4<Float>(1, 1, 1, 1)
    var tickColor = SIMD4<Float>(0.7, 0.7, 0.7, 1.0)
    var gridColor = SIMD4<Float>(0.4, 0.4, 0.4, 0.6) // alpha=0.6 for grid

    // --- Axis buffers ---
    private var xAxisQuadBuffer: MTLBuffer?
    private var xAxisQuadVertexCount = 0
    
    private var yAxisQuadBuffer: MTLBuffer?
    private var yAxisQuadVertexCount = 0
    
    // --- Tick line buffers ---
    private var xTickBuffer: MTLBuffer?
    private var xTickVertexCount = 0
    
    private var yTickBuffer: MTLBuffer?
    private var yTickVertexCount = 0
    
    // --- Grid line buffers ---
    var xGridBuffer: MTLBuffer?
    var xGridVertexCount = 0
    
    var yGridBuffer: MTLBuffer?
    var yGridVertexCount = 0
    
    var domainMaxLogY: Float = 0
    
    // Tick text
    private var xTickTextBuffers: [MTLBuffer] = []
    private var xTickTextVertexCounts: [Int] = []
    private var yTickTextBuffers: [MTLBuffer] = []
    private var yTickTextVertexCounts: [Int] = []
    
    // Axis labels (we'll transform them later)
    private var xAxisLabelBuffer: MTLBuffer?
    private var xAxisLabelVertexCount = 0
    private var yAxisLabelBuffer: MTLBuffer?
    private var yAxisLabelVertexCount = 0
    
    // MARK: - Init
    
    init(device: MTLDevice,
         textRenderer: GPUTextRenderer,
         textRendererManager: TextRendererManager,
         library: MTLLibrary,
         idleManager: IdleManager? = nil)
    {
        self.device = device
        self.textRenderer = textRenderer
        self.textRendererManager = textRendererManager
        self.idleManager = idleManager
        
        print("[PinnedAxesRenderer] init with idleManager = \(String(describing: idleManager))")
        
        buildAxisPipeline(library: library)
    }
    
    // Build the axis pipeline for lines/axes
    private func buildAxisPipeline(library: MTLLibrary) {
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "axisVertexShader_screenSpace")
        desc.fragmentFunction = library.makeFunction(name: "axisFragmentShader")
        desc.rasterSampleCount = 4 // if using MSAA
        
        let vDesc = MTLVertexDescriptor()
        vDesc.attributes[0].format = .float4
        vDesc.attributes[0].offset = 0
        vDesc.attributes[0].bufferIndex = 0
        
        vDesc.attributes[1].format = .float4
        vDesc.attributes[1].offset = MemoryLayout<Float>.size * 4
        vDesc.attributes[1].bufferIndex = 0
        
        vDesc.layouts[0].stride = MemoryLayout<Float>.size * 8
        desc.vertexDescriptor = vDesc
        
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.colorAttachments[0].isBlendingEnabled = true
        desc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        desc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            axisPipelineState = try device.makeRenderPipelineState(descriptor: desc)
        } catch {
            print("Error building axis pipeline: \(error)")
        }
    }
    
    // MARK: - Update each frame
    
    func updateAxes(
        minX: Float,
        maxX: Float,
        minY: Float,
        maxY: Float,
        chartTransform: matrix_float4x4
    ) {
        let pinnedScreenX = pinnedAxisX
        let pinnedScreenY = Float(viewportSize.height) - 40
        let axisThickness: Float = 0.1

        // X-axis quad (unchanged)
        let xQuadVerts = buildXAxisQuad(
            minDataX: minX,
            maxDataX: maxX,
            transform: chartTransform,
            pinnedScreenX: pinnedScreenX,
            pinnedScreenY: pinnedScreenY,
            thickness: axisThickness,
            color: axisColor
        )
        xAxisQuadVertexCount = xQuadVerts.count / 8
        xAxisQuadBuffer = device.makeBuffer(
            bytes: xQuadVerts,
            length: xQuadVerts.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )

        // Y-axis quad (unchanged)
        let yQuadVerts = buildYAxisQuad(
            minDataY: minY,
            maxDataY: maxY,
            transform: chartTransform,
            pinnedScreenX: pinnedScreenX,
            pinnedScreenY: pinnedScreenY,
            thickness: axisThickness,
            color: axisColor
        )
        yAxisQuadVertexCount = yQuadVerts.count / 8
        yAxisQuadBuffer = device.makeBuffer(
            bytes: yQuadVerts,
            length: yQuadVerts.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )

        // Dynamic tick counts
        let screenDomainWidth = dataXtoScreenX(dataX: maxX, transform: chartTransform)
                              - dataXtoScreenX(dataX: minX, transform: chartTransform)
        let approxDesiredCountX = Int((screenDomainWidth / 80.0).rounded())
        let desiredCountX = max(2, min(50, approxDesiredCountX))

        let screenDomainHeight = dataYtoScreenY(dataY: minY, transform: chartTransform)
                               - dataYtoScreenY(dataY: maxY, transform: chartTransform)
        let approxDesiredCountY = Int((abs(screenDomainHeight) / 80.0).rounded())
        let desiredCountY = max(2, min(50, approxDesiredCountY))

        // Generate x-axis ticks (unchanged)
        let tickXValues = generateNiceTicks(
            minVal: Double(minX),
            maxVal: Double(maxX),
            desiredCount: desiredCountX
        )

        // Generate y-axis ticks with all powers of 10 when feasible
        let minYLog = Double(minY)
        let maxYLog = Double(maxY)
        let start = floor(minYLog)
        let end = ceil(maxYLog)
        let numPowers = Int(end - start) + 1
        let screenHeight = Float(viewportSize.height)
        let pixelsPerTick = numPowers > 1 ? screenHeight / Float(numPowers - 1) : screenHeight

        // Define tickYValues with a type annotation and assign it in both branches
        let tickYValues: [Double]
        if pixelsPerTick >= 30 { // Ensure at least 30 pixels between ticks
            tickYValues = stride(from: start, through: end, by: 1).map { $0 }
        } else {
            tickYValues = generateNiceTicks(
                minVal: minYLog,
                maxVal: maxYLog,
                desiredCount: desiredCountY
            )
        }

        // Call buildYTicks once and unpack the tuple
        let (yTickVerts, yTickTexts) = buildYTicks(
            tickYValues,
            pinnedScreenX: pinnedScreenX,
            chartTransform: chartTransform,
            maxDataValue: maxYLog
        )

        // Grid lines
        buildXGridLines(
            tickXValues,
            minY: 0,
            maxY: pinnedScreenY,
            pinnedScreenX: pinnedScreenX,
            chartTransform: chartTransform
        )
        buildYGridLines(
            tickYValues,
            minX: pinnedScreenX,
            maxX: Float(viewportSize.width),
            chartTransform: chartTransform
        )

        // X-axis ticks (unchanged)
        let (xTickVerts, xTickTexts) = buildXTicks(
            tickXValues,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform,
            minX: minX,
            maxX: maxX
        )
        xTickVertexCount = xTickVerts.count / 8
        xTickBuffer = xTickVerts.isEmpty
            ? nil
            : device.makeBuffer(bytes: xTickVerts,
                                length: xTickVerts.count * MemoryLayout<Float>.size,
                                options: .storageModeShared)
        xTickTextBuffers = xTickTexts.map { $0.0 }
        xTickTextVertexCounts = xTickTexts.map { $0.1 }

        // Y-axis ticks
        yTickVertexCount = yTickVerts.count / 8
        yTickBuffer = yTickVerts.isEmpty
            ? nil
            : device.makeBuffer(bytes: yTickVerts,
                                length: yTickVerts.count * MemoryLayout<Float>.size,
                                options: .storageModeShared)
        yTickTextBuffers = yTickTexts.map { $0.0 }
        yTickTextVertexCounts = yTickTexts.map { $0.1 }

        // Axis labels (unchanged)
        let labelColor = SIMD4<Float>(1, 1, 1, 0.6)
        let scale: Float = 0.35
        let (maybeXBuf, xCount) = textRenderer.buildTextVertices(
            string: "Period",
            x: 0,
            y: 0,
            color: labelColor,
            scale: scale,
            screenWidth: Float(viewportSize.width),
            screenHeight: Float(viewportSize.height),
            letterSpacing: 4.0
        )
        if let xBuf = maybeXBuf {
            xAxisLabelBuffer = xBuf
            xAxisLabelVertexCount = xCount
        }
        let (maybeYBuf, yCount) = textRenderer.buildTextVertices(
            string: "USD",
            x: 0,
            y: 0,
            color: labelColor,
            scale: scale,
            screenWidth: Float(viewportSize.width),
            screenHeight: Float(viewportSize.height),
            letterSpacing: 5.0
        )
        if let yBuf = maybeYBuf {
            yAxisLabelBuffer = yBuf
            yAxisLabelVertexCount = yCount
        }
    }
    
    func generateNiceTicks(
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
    
    // MARK: - Draw
    
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        guard let axisPipeline = axisPipelineState else { return }
        
        // Build a viewport buffer for the vertex shader
        var vp = ViewportSize(size: SIMD2<Float>(Float(viewportSize.width),
                                                 Float(viewportSize.height)))
        guard let vpBuf = device.makeBuffer(bytes: &vp,
                                            length: MemoryLayout<ViewportSize>.size,
                                            options: .storageModeShared) else {
            return
        }
        renderEncoder.setVertexBuffer(vpBuf, offset: 0, index: 1)
        
        // Use axis pipeline
        renderEncoder.setRenderPipelineState(axisPipeline)
        
        // Draw grids
        if let buf = xGridBuffer, xGridVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xGridVertexCount)
        }
        if let buf = yGridBuffer, yGridVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yGridVertexCount)
        }
        
        // Draw tick lines
        if let buf = xTickBuffer, xTickVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xTickVertexCount)
        }
        if let buf = yTickBuffer, yTickVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yTickVertexCount)
        }
        
        // Draw the axes
        if let buf = xAxisQuadBuffer, xAxisQuadVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: xAxisQuadVertexCount)
        }
        if let buf = yAxisQuadBuffer, yAxisQuadVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: yAxisQuadVertexCount)
        }
        
        // Switch to text pipeline
        if let textPipeline = textRenderer.pipelineState {
            renderEncoder.setRenderPipelineState(textPipeline)
            
            // Standard orthographic projection
            let col0 = SIMD4<Float>(2.0 / Float(viewportSize.width), 0, 0, 0)
            let col1 = SIMD4<Float>(0, -2.0 / Float(viewportSize.height), 0, 0)
            let col2 = SIMD4<Float>(0, 0, 1, 0)
            let col3 = SIMD4<Float>(-1, 1, 0, 1)
            var baseProj = matrix_float4x4(col0, col1, col2, col3)
            
            guard let baseProjBuf = device.makeBuffer(bytes: &baseProj,
                                                      length: MemoryLayout<matrix_float4x4>.size,
                                                      options: .storageModeShared) else {
                print("Failed to create projection buffer for text.")
                return
            }
            renderEncoder.setVertexBuffer(baseProjBuf, offset: 0, index: 1)
            
            // Draw X tick text
            renderEncoder.setFragmentTexture(textRenderer.atlas.texture, index: 0)
            for (buf, vCount) in zip(xTickTextBuffers, xTickTextVertexCounts) {
                renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vCount)
            }
            // Draw Y tick text
            for (buf, vCount) in zip(yTickTextBuffers, yTickTextVertexCounts) {
                renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vCount)
            }
            
            // --- Axis labels ---
            // We'll apply different transforms for each label.
            // The pinnedScreenY is near the bottom, so to go "above" it, we subtract.

            // 1) "Period" above X-axis (centered horizontally)
            if let xBuf = xAxisLabelBuffer, xAxisLabelVertexCount > 0 {
                let pinnedScreenY = Float(viewportSize.height) - 40
                let labelX = Float(viewportSize.width) * 0.5
                let labelY = pinnedScreenY - 10  // 10 px above the axis
                
                let translatePeriod = matrix_float4x4.make2DTranslation(x: labelX, y: labelY)
                var periodTransform = baseProj * translatePeriod
                if let periodBuf = device.makeBuffer(bytes: &periodTransform,
                                                     length: MemoryLayout<matrix_float4x4>.size,
                                                     options: .storageModeShared) {
                    renderEncoder.setVertexBuffer(periodBuf, offset: 0, index: 1)
                    renderEncoder.setVertexBuffer(xBuf, offset: 0, index: 0)
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xAxisLabelVertexCount)
                }
            }
            
            // 2) "USD" further from Y-axis, rotated 90°
            if let yBuf = yAxisLabelBuffer, yAxisLabelVertexCount > 0 {
                let angle = Float.pi * 0.5
                let rotate = matrix_float4x4.make2DRotation(angle)
                // pinnedAxisX is the left edge. We'll add +30 so it's further away.
                // y is 10% down from the top. Tweak if needed.
                let translateUSD = matrix_float4x4.make2DTranslation(
                    x: pinnedAxisX + 30,
                    y: Float(viewportSize.height) * 0.1
                )
                var usdTransform = baseProj * translateUSD * rotate
                if let usdBuf = device.makeBuffer(bytes: &usdTransform,
                                                  length: MemoryLayout<matrix_float4x4>.size,
                                                  options: .storageModeShared) {
                    renderEncoder.setVertexBuffer(usdBuf, offset: 0, index: 1)
                    renderEncoder.setVertexBuffer(yBuf, offset: 0, index: 0)
                    renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yAxisLabelVertexCount)
                }
            }
        }
    }
}

// MARK: - Helpers for 2D matrix ops
extension matrix_float4x4 {
    init(_ col0: SIMD4<Float>, _ col1: SIMD4<Float>, _ col2: SIMD4<Float>, _ col3: SIMD4<Float>) {
        self.init()
        self.columns = (col0, col1, col2, col3)
    }
    
    // Make a 2D translation matrix
    static func make2DTranslation(x: Float, y: Float) -> matrix_float4x4 {
        matrix_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, 0, 1)
        )
    }
    
    // Make a simple 2D rotation (in radians) around the origin
    static func make2DRotation(_ radians: Float) -> matrix_float4x4 {
        let c = cos(radians)
        let s = sin(radians)
        return matrix_float4x4(
            SIMD4<Float>( c,  -s,  0, 0),
            SIMD4<Float>( s,   c,  0, 0),
            SIMD4<Float>( 0,   0,  1, 0),
            SIMD4<Float>( 0,   0,  0, 1)
        )
    }
}
