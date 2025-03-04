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
    
    // --- Text buffers ---
    private var xTickTextBuffers: [MTLBuffer] = []
    private var xTickTextVertexCounts: [Int] = []
    private var yTickTextBuffers: [MTLBuffer] = []
    private var yTickTextVertexCounts: [Int] = []
    
    // Axis labels
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
        // pinnedAxisX is the horizontal screen coordinate where we pin the y-axis
        let pinnedScreenX = pinnedAxisX
        // pinnedScreenY is how tall we want the x-axis region. This example uses (height - 40).
        let pinnedScreenY: Float = Float(viewportSize.height) - 40
        
        let axisThickness: Float = 1
        
        // 1) X axis
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
        
        // 2) Y axis
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
        
        // Dynamic calculation for how many ticks we want based on screen space:
        // We'll aim for ~80 pixels between ticks.
        let screenDomainWidth = dataXtoScreenX(dataX: maxX, transform: chartTransform)
                              - dataXtoScreenX(dataX: minX, transform: chartTransform)
        let approxDesiredCountX = Int((screenDomainWidth / 80.0).rounded())
        let desiredCountX = max(2, min(50, approxDesiredCountX))  // clamp to something reasonable
        
        let screenDomainHeight = dataYtoScreenY(dataY: minY, transform: chartTransform)
                               - dataYtoScreenY(dataY: maxY, transform: chartTransform)
        let approxDesiredCountY = Int((abs(screenDomainHeight) / 80.0).rounded())
        let desiredCountY = max(2, min(50, approxDesiredCountY))
        
        // 3) Ticks
        let tickXValues = generateNiceTicks(
            minVal: Double(minX),
            maxVal: Double(maxX),
            desiredCount: desiredCountX
        )
        let tickYValues = generateNiceTicks(
            minVal: Double(minY),
            maxVal: Double(maxY),
            desiredCount: desiredCountY
        )
        
        // 4) Grid lines
        let gridXValues = tickXValues
        let gridYValues = tickYValues
        
        // Build X Ticks + Label
        let (xTickVerts, xTickTexts) = buildXTicks(
            tickXValues,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform,
            minX: minX,
            maxX: maxX
        )
        xTickVertexCount = xTickVerts.count / 8
        if !xTickVerts.isEmpty {
            xTickBuffer = device.makeBuffer(
                bytes: xTickVerts,
                length: xTickVerts.count * MemoryLayout<Float>.size,
                options: .storageModeShared
            )
        } else {
            xTickBuffer = nil
        }
        xTickTextBuffers = xTickTexts.map { $0.0 }
        xTickTextVertexCounts = xTickTexts.map { $0.1 }
        
        // Build Y Ticks + Label
        let (yTickVerts, yTickTexts) = buildYTicks(
            tickYValues,
            pinnedScreenX: pinnedScreenX,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform
        )
        
        if !yTickVerts.isEmpty {
            yTickBuffer = device.makeBuffer(
                bytes: yTickVerts,
                length: yTickVerts.count * MemoryLayout<Float>.size,
                options: .storageModeShared
            )
        } else {
            yTickBuffer = nil
        }
        yTickVertexCount = yTickVerts.count / 8
        yTickTextBuffers = yTickTexts.map { $0.0 }
        yTickTextVertexCounts = yTickTexts.map { $0.1 }
        
        // Build Grid lines
        buildXGridLines(
            gridXValues,
            minY: 0,
            maxY: pinnedScreenY,
            pinnedScreenX: pinnedScreenX,
            chartTransform: chartTransform
        )
        buildYGridLines(
            gridYValues,
            minX: pinnedScreenX,
            maxX: Float(viewportSize.width),
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform
        )
        
        // 5) Axis labels (unchanged)
        let (maybeXBuf, xCount) = textRenderer.buildTextVertices(
            string: "Period",
            x: pinnedScreenX + 100,
            y: pinnedScreenY + 15,
            color: axisColor,
            scale: 0.35,
            screenWidth: Float(viewportSize.width),
            screenHeight: Float(viewportSize.height),
            letterSpacing: 5.0
        )
        if let xBuf = maybeXBuf {
            xAxisLabelBuffer = xBuf
            xAxisLabelVertexCount = xCount
        }

        let (maybeYBuf, yCount) = textRenderer.buildTextVertices(
            string: "USD",
            x: pinnedScreenX - 40,
            y: pinnedScreenY * 0.5,
            color: axisColor,
            scale: 0.35,
            screenWidth: Float(viewportSize.width),
            screenHeight: Float(viewportSize.height),
            letterSpacing: 7.0
        )
        if let yBuf = maybeYBuf {
            yAxisLabelBuffer = yBuf
            yAxisLabelVertexCount = yCount
        }
    }
    
    // MARK: - Draw
    
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        idleManager?.resetIdleTimer()
        
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
        
        // Use axis pipeline for axis lines + grids + ticks
        renderEncoder.setRenderPipelineState(axisPipeline)
        
        // Draw X grid
        if let buf = xGridBuffer, xGridVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xGridVertexCount)
        }
        
        // Draw Y grid
        if let buf = yGridBuffer, yGridVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yGridVertexCount)
        }
        
        // Draw X ticks
        if let buf = xTickBuffer, xTickVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xTickVertexCount)
        }
        
        // Draw Y ticks
        if let buf = yTickBuffer, yTickVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yTickVertexCount)
        }
        
        // Draw X axis quad
        if let buf = xAxisQuadBuffer, xAxisQuadVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: xAxisQuadVertexCount)
        }
        
        // Draw Y axis quad
        if let buf = yAxisQuadBuffer, yAxisQuadVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: yAxisQuadVertexCount)
        }
        
        // Draw tick label text
        if let textPipeline = textRenderer.pipelineState {
            renderEncoder.setRenderPipelineState(textPipeline)
            
            // Setup orthographic projection (screen space)
            let width = Float(viewportSize.width)
            let height = Float(viewportSize.height)
            var proj = matrix_float4x4(
                [2/width,  0,        0, 0],
                [0,       -2/height, 0, 0],
                [0,        0,        1, 0],
                [-1,       1,        0, 1]
            )
            guard let pBuf = device.makeBuffer(bytes: &proj,
                                               length: MemoryLayout<matrix_float4x4>.size,
                                               options: .storageModeShared) else {
                print("Failed to create projection buffer for text.")
                return
            }
            renderEncoder.setVertexBuffer(pBuf, offset: 0, index: 1)
            
            // Font atlas
            renderEncoder.setFragmentTexture(textRenderer.atlas.texture, index: 0)
            
            // X tick text
            for (buf, vCount) in zip(xTickTextBuffers, xTickTextVertexCounts) {
                renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vCount)
            }
            
            // Y tick text
            for (buf, vCount) in zip(yTickTextBuffers, yTickTextVertexCounts) {
                renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vCount)
            }
            
            // X axis label
            if let xBuf = xAxisLabelBuffer, xAxisLabelVertexCount > 0 {
                renderEncoder.setVertexBuffer(xBuf, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xAxisLabelVertexCount)
            }
            
            // Y axis label
            if let yBuf = yAxisLabelBuffer, yAxisLabelVertexCount > 0 {
                renderEncoder.setVertexBuffer(yBuf, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yAxisLabelVertexCount)
            }
        }
    }
}
