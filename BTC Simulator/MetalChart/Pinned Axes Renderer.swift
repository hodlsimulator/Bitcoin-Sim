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
    
    var textRendererManager: TextRendererManager
    
    private let device: MTLDevice
    private let textRenderer: RuntimeGPUTextRenderer
    private var axisPipelineState: MTLRenderPipelineState?
    
    /// Current view size; set each frame.
    var viewportSize: CGSize = .zero
    
    /// Colours
    var axisColor = SIMD4<Float>(1, 1, 1, 1)
    var tickColor = SIMD4<Float>(0.7, 0.7, 0.7, 1.0)
    // Reduced opacity for grid lines (alpha 0.6)
    var gridColor = SIMD4<Float>(0.4, 0.4, 0.4, 0.6)
    
    // MARK: - Axis geometry (triangle strips)
    private var xAxisQuadBuffer: MTLBuffer?
    private var xAxisQuadVertexCount = 0
    
    private var yAxisQuadBuffer: MTLBuffer?
    private var yAxisQuadVertexCount = 0
    
    // MARK: - Ticks (short lines on the axes) - triangle list
    private var xTickBuffer: MTLBuffer?
    private var xTickVertexCount = 0
    
    private var yTickBuffer: MTLBuffer?
    private var yTickVertexCount = 0
    
    // MARK: - Grid lines (spanning inside chart) - triangle list
    private var xGridBuffer: MTLBuffer?
    private var xGridVertexCount = 0
    
    private var yGridBuffer: MTLBuffer?
    private var yGridVertexCount = 0
    
    // MARK: - Text buffers for tick labels
    private var xTickTextBuffers: [MTLBuffer] = []
    private var xTickTextVertexCounts: [Int] = []
    private var yTickTextBuffers: [MTLBuffer] = []
    private var yTickTextVertexCounts: [Int] = []
    
    init(device: MTLDevice,
         textRenderer: RuntimeGPUTextRenderer,
         textRendererManager: TextRendererManager,
         library: MTLLibrary) {
        self.device = device
        self.textRenderer = textRenderer
        self.textRendererManager = textRendererManager
        buildAxisPipeline(library: library, textRendererManager: textRendererManager)
    }
    
    // Build a basic pipeline for the axes/ticks
    private func buildAxisPipeline(library: MTLLibrary, textRendererManager: TextRendererManager) {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "axisVertexShader_screenSpace")
        descriptor.fragmentFunction = library.makeFunction(name: "axisFragmentShader")
        descriptor.rasterSampleCount = 4  // if using MSAA
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        descriptor.vertexDescriptor = vertexDescriptor
        
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            axisPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Error building axis pipeline: \(error)")
        }
    }
    
    // MARK: - Update
    
    /// Called every frame to rebuild geometry for axes, ticks, and grid lines.
    func updateAxes(minX: Float,
                    maxX: Float,
                    minY: Float,
                    maxY: Float,
                    chartTransform: matrix_float4x4) {
        
        // Pinned axis positions in screen space.
        let pinnedScreenX: Float = 50
        let pinnedScreenY: Float = Float(viewportSize.height) - 40
        
        // Axis thickness.
        let axisThickness: Float = 2
        
        // 1) Build pinned X axis
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
        
        // 2) Build pinned Y axis
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
        
        // Generate tick and grid values.
        let tickXValues = generateNiceTicks(minVal: Double(minX), maxVal: Double(maxX), desiredCount: 6)
        let tickYValues = generateNiceTicks(minVal: Double(minY), maxVal: Double(maxY), desiredCount: 6)
        let gridXValues = generateNiceTicks(minVal: Double(minX), maxVal: Double(maxX), desiredCount: 10)
        let gridYValues = generateNiceTicks(minVal: Double(minY), maxVal: Double(maxY), desiredCount: 10)
        
        // 3) Build short ticks and text labels on pinned axes
        let (xTickVerts, xTickTexts) = buildXTicks(
            tickXValues,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform,
            tickColor: tickColor
        )
        xTickVertexCount = xTickVerts.count / 8
        xTickBuffer = device.makeBuffer(
            bytes: xTickVerts,
            length: xTickVerts.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
        self.xTickTextBuffers = xTickTexts.map { $0.0 }
        self.xTickTextVertexCounts = xTickTexts.map { $0.1 }
        
        let (yTickVerts, yTickTexts) = buildYTicks(
            tickYValues,
            pinnedScreenX: pinnedScreenX,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform,
            tickColor: tickColor
        )
        yTickVertexCount = yTickVerts.count / 8
        yTickBuffer = device.makeBuffer(
            bytes: yTickVerts,
            length: yTickVerts.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
        self.yTickTextBuffers = yTickTexts.map { $0.0 }
        self.yTickTextVertexCounts = yTickTexts.map { $0.1 }
        
        // 4) Build grid lines that span the chart interior
        buildXGridLines(gridXValues,
                        minY: 0,
                        maxY: pinnedScreenY,
                        pinnedScreenX: pinnedScreenX,
                        chartTransform: chartTransform)
        buildYGridLines(gridYValues,
                        minX: pinnedScreenX,
                        maxX: Float(viewportSize.width),
                        pinnedScreenY: pinnedScreenY,
                        chartTransform: chartTransform)
    }
    
    func renderTextBuffer(renderEncoder: MTLRenderCommandEncoder, buffer: MTLBuffer, vertexCount: Int) {
        // Check if the buffer's size is correct
        let bufferLength = buffer.length
        let expectedSize = vertexCount * MemoryLayout<Float>.size * 8 // Assuming 8 elements per vertex (x, y, z, w, color)
        if bufferLength != expectedSize {
            print("Warning: Buffer size mismatch. Expected: \(expectedSize), Got: \(bufferLength)")
        }
        
        // Set the buffer and draw primitives
        renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
    
    // MARK: - Draw
    
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        guard let axisPipeline = axisPipelineState else { return }
        
        // Build a viewport buffer for the axis vertex shader
        var vp = ViewportSize(size: SIMD2<Float>(Float(viewportSize.width),
                                                 Float(viewportSize.height)))
        guard let vpBuffer = device.makeBuffer(bytes: &vp,
                                               length: MemoryLayout<ViewportSize>.size,
                                               options: .storageModeShared) else {
            return
        }
        renderEncoder.setVertexBuffer(vpBuffer, offset: 0, index: 1)
        
        // Draw axes, ticks, and grid lines
        renderEncoder.setRenderPipelineState(axisPipeline)
        
        if let buf = xGridBuffer, xGridVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xGridVertexCount)
        }
        if let buf = yGridBuffer, yGridVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yGridVertexCount)
        }
        if let buf = xTickBuffer, xTickVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: xTickVertexCount)
        }
        if let buf = yTickBuffer, yTickVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: yTickVertexCount)
        }
        if let buf = xAxisQuadBuffer, xAxisQuadVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: xAxisQuadVertexCount)
        }
        if let buf = yAxisQuadBuffer, yAxisQuadVertexCount > 0 {
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: yAxisQuadVertexCount)
        }
        
        // Draw tick label texts
        if let textPipelineState = textRenderer.pipelineState {
            renderEncoder.setRenderPipelineState(textPipelineState)
            
            // Create projection matrix for text (screen space to NDC)
            let width = Float(viewportSize.width)
            let height = Float(viewportSize.height)
            var projectionMatrix = matrix_float4x4(
                [2/width, 0, 0, 0],
                [0, -2/height, 0, 0],
                [0, 0, 1, 0],
                [-1, 1, 0, 1]
            )
            guard let projectionBuffer = device.makeBuffer(bytes: &projectionMatrix,
                                                           length: MemoryLayout<matrix_float4x4>.size,
                                                           options: .storageModeShared) else {
                print("Failed to create projection buffer")
                return
            }
            renderEncoder.setVertexBuffer(projectionBuffer, offset: 0, index: 1)
            
            // Set the font atlas texture for the fragment shader
            renderEncoder.setFragmentTexture(textRenderer.atlas.texture, index: 0)
            
            // Draw all text buffers
            for (buffer, vertexCount) in zip(xTickTextBuffers, xTickTextVertexCounts) {
                renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            }
            for (buffer, vertexCount) in zip(yTickTextBuffers, yTickTextVertexCounts) {
                renderEncoder.setVertexBuffer(buffer, offset: 0, index: 0)
                renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            }
        }
    }
}

// MARK: - Private Build Methods

extension PinnedAxesRenderer {

    // 1) X axis quad as a triangle strip
    private func buildXAxisQuad(minDataX: Float,
                                maxDataX: Float,
                                transform: matrix_float4x4,
                                pinnedScreenX: Float,
                                pinnedScreenY: Float,
                                thickness: Float,
                                color: SIMD4<Float>) -> [Float] {

        var rightX = dataXtoScreenX(dataX: maxDataX, transform: transform)
        if rightX < pinnedScreenX { rightX = pinnedScreenX }

        let halfT = thickness * 0.5
        let y0 = pinnedScreenY - halfT
        let y1 = pinnedScreenY + halfT

        var verts: [Float] = []
        // v0
        verts.append(pinnedScreenX); verts.append(y0); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        // v1
        verts.append(pinnedScreenX); verts.append(y1); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        // v2
        verts.append(rightX); verts.append(y0); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        // v3
        verts.append(rightX); verts.append(y1); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)

        return verts
    }

    // 2) Y axis quad as a triangle strip
    private func buildYAxisQuad(minDataY: Float,
                                maxDataY: Float,
                                transform: matrix_float4x4,
                                pinnedScreenX: Float,
                                pinnedScreenY: Float,
                                thickness: Float,
                                color: SIMD4<Float>) -> [Float] {

        var topY = dataYtoScreenY(dataY: maxDataY, transform: transform)
        if topY > pinnedScreenY { topY = pinnedScreenY }

        let halfT = thickness * 0.5
        let x0 = pinnedScreenX - halfT
        let x1 = pinnedScreenX + halfT

        var verts: [Float] = []
        // v0
        verts.append(x0); verts.append(pinnedScreenY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        // v1
        verts.append(x1); verts.append(pinnedScreenY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        // v2
        verts.append(x0); verts.append(topY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        // v3
        verts.append(x1); verts.append(topY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)

        return verts
    }

    // 3) Short vertical ticks and text labels along the X axis
    private func buildXTicks(_ xTicks: [Double],
                             pinnedScreenY: Float,
                             chartTransform: matrix_float4x4,
                             tickColor: SIMD4<Float>) -> ([Float], [(MTLBuffer, Int)]) {
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []
        let tickLen: Float = 6
        let halfT: Float = 0.5
        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            if sx < 50 { continue }

            // Build tick line
            let y0 = pinnedScreenY
            let y1 = pinnedScreenY + tickLen
            verts.append(contentsOf: makeQuadList(x0: sx - halfT,
                                                  y0: y0,
                                                  x1: sx + halfT,
                                                  y1: y1,
                                                  color: tickColor))
            // Format and build text label for year ticks
            let formattedTickValue = String(format: "%.0f", val)
            let (textBuffer, vertexCount) = textRenderer.buildTextVertices(
                string: formattedTickValue,
                x: sx,
                y: y1 + 3,
                color: tickColor
            )
            if let buffer = textBuffer {
                textBuffers.append((buffer, vertexCount))
            }
        }
        return (verts, textBuffers)
    }

    // 4) Short horizontal ticks and text labels along the Y axis
    private func buildYTicks(_ yTicks: [Double],
                             pinnedScreenX: Float,
                             pinnedScreenY: Float,
                             chartTransform: matrix_float4x4,
                             tickColor: SIMD4<Float>) -> ([Float], [(MTLBuffer, Int)]) {
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []
        let tickLen: Float = 6
        let halfT: Float = 0.5
        for val in yTicks {
            let sy = dataYtoScreenY(dataY: Float(val), transform: chartTransform)
            if sy < 0 || sy > pinnedScreenY { continue }

            // Build tick line
            let x0 = pinnedScreenX - tickLen
            let x1 = pinnedScreenX
            verts.append(contentsOf: makeQuadList(x0: x0,
                                                  y0: sy - halfT,
                                                  x1: x1,
                                                  y1: sy + halfT,
                                                  color: tickColor))

            // Use formattedGroupedSuffix() to format the USD values
            let formattedTickValue = val.formattedGroupedSuffix() // Call the extension here for formatting
            let (textBuffer, vertexCount) = textRenderer.buildTextVertices(
                string: formattedTickValue,
                x: x0 - 5,
                y: sy,
                color: tickColor
            )
            if let buffer = textBuffer {
                textBuffers.append((buffer, vertexCount))
            }
        }
        return (verts, textBuffers)
    }

    // 5) Vertical grid lines that span from top (0) to bottom (pinnedScreenY)
    private func buildXGridLines(_ xTicks: [Double],
                                 minY: Float,
                                 maxY: Float,
                                 pinnedScreenX: Float,
                                 chartTransform: matrix_float4x4) {
        var verts: [Float] = []
        let lineThickness: Float = 1
        let halfT = lineThickness * 0.5
        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            if sx < pinnedScreenX { continue }
            if sx > Float(viewportSize.width) { continue }
            let top = minY
            let bot = maxY
            verts.append(contentsOf: makeQuadList(x0: sx - halfT,
                                                  y0: top,
                                                  x1: sx + halfT,
                                                  y1: bot,
                                                  color: gridColor))
        }
        xGridVertexCount = verts.count / 8
        xGridBuffer = device.makeBuffer(bytes: verts,
                                        length: verts.count * MemoryLayout<Float>.size,
                                        options: .storageModeShared)
    }

    // 6) Horizontal grid lines that span from left (pinnedScreenX) to right (viewport width)
    private func buildYGridLines(_ yTicks: [Double],
                                 minX: Float,
                                 maxX: Float,
                                 pinnedScreenY: Float,
                                 chartTransform: matrix_float4x4) {
        var verts: [Float] = []
        let lineThickness: Float = 1
        let halfT = lineThickness * 0.5
        for val in yTicks {
            let sy = dataYtoScreenY(dataY: Float(val), transform: chartTransform)
            if sy < 0 { continue }
            if sy > pinnedScreenY { continue }
            let left = minX
            let right = maxX
            verts.append(contentsOf: makeQuadList(x0: left,
                                                  y0: sy - halfT,
                                                  x1: right,
                                                  y1: sy + halfT,
                                                  color: gridColor))
        }
        yGridVertexCount = verts.count / 8
        yGridBuffer = device.makeBuffer(bytes: verts,
                                        length: verts.count * MemoryLayout<Float>.size,
                                        options: .storageModeShared)
    }
}

// MARK: - Shared Helpers

extension PinnedAxesRenderer {
    /// Builds a rectangle (2 triangles, 6 vertices) for a .triangle draw call
    private func makeQuadList(x0: Float,
                              y0: Float,
                              x1: Float,
                              y1: Float,
                              color: SIMD4<Float>) -> [Float] {
        return [
            // Triangle 1
            x0, y0, 0, 1, color.x, color.y, color.z, color.w,
            x0, y1, 0, 1, color.x, color.y, color.z, color.w,
            x1, y0, 0, 1, color.x, color.y, color.z, color.w,
            // Triangle 2
            x1, y0, 0, 1, color.x, color.y, color.z, color.w,
            x0, y1, 0, 1, color.x, color.y, color.z, color.w,
            x1, y1, 0, 1, color.x, color.y, color.z, color.w
        ]
    }

    /// Convert data X coordinate to screen X coordinate
    private func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(dataX, 0, 0, 1)
        let ndcX = clip.x / clip.w
        return (ndcX * 0.5 + 0.5) * Float(viewportSize.width)
    }

    /// Convert data Y coordinate to screen Y coordinate
    private func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        return (1 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
    }

    /// Simple 'nice' ticks generator
    private func generateNiceTicks(minVal: Double,
                                   maxVal: Double,
                                   desiredCount: Int) -> [Double] {
        guard minVal < maxVal, desiredCount > 0 else { return [] }
        let range = maxVal - minVal
        let rawStep = range / Double(desiredCount)
        let mag = pow(10.0, floor(log10(rawStep)))
        let leading = rawStep / mag
        let niceLeading: Double = (leading < 2) ? 2 : (leading < 5 ? 5 : 10)
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
}
