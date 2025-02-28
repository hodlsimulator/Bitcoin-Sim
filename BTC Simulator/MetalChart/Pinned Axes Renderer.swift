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
    
    private let device: MTLDevice
    private let textRenderer: RuntimeGPUTextRenderer
    
    private var axisPipelineState: MTLRenderPipelineState?
    
    var viewportSize: CGSize = .zero
    
    /// Axis colour
    var axisColor = SIMD4<Float>(1, 1, 1, 1)
    
    /// Tick (grid line) colour
    var tickColor = SIMD4<Float>(0.6, 0.6, 0.6, 1.0)
    
    /// Thick pinned axes, stored as triangle strips
    private var xAxisQuadBuffer: MTLBuffer?
    private var xAxisQuadVertexCount: Int = 0
    
    private var yAxisQuadBuffer: MTLBuffer?
    private var yAxisQuadVertexCount: Int = 0
    
    /// Grid lines for X and Y ticks, stored as triangle lists
    private var xTickBuffer: MTLBuffer?
    private var xTickVertexCount = 0
    
    private var yTickBuffer: MTLBuffer?
    private var yTickVertexCount = 0
    
    init(device: MTLDevice,
         textRenderer: RuntimeGPUTextRenderer,
         library: MTLLibrary) {
        
        self.device = device
        self.textRenderer = textRenderer
        buildAxisPipeline(library: library)
    }
    
    private func buildAxisPipeline(library: MTLLibrary) {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = library.makeFunction(name: "axisVertexShader_screenSpace")
        descriptor.fragmentFunction = library.makeFunction(name: "axisFragmentShader")
        
        // If using MSAA
        descriptor.rasterSampleCount = 4
        
        // Vertex = position(float4) + color(float4)
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
    
    /// Updates axis quads + tick lines.
    func updateAxes(minX: Float,
                    maxX: Float,
                    minY: Float,
                    maxY: Float,
                    chartTransform: matrix_float4x4) {
        
        // Pinned axis screen position
        let pinnedScreenX: Float = 50
        let pinnedScreenY: Float = Float(viewportSize.height) - 40
        
        // Axis thickness
        let axisThickness: Float = 2
        
        // Build pinned X axis quad as a triangle strip
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
        
        // Build pinned Y axis quad as a triangle strip
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
        
        // Generate nice tick values
        let xTicks = generateNiceTicks(minVal: Double(minX), maxVal: Double(maxX), desiredCount: 6)
        let yTicks = generateNiceTicks(minVal: Double(minY), maxVal: Double(maxY), desiredCount: 6)
        
        // Build the grid lines across the chart using .triangleList geometry.
        // Each line is a thin rectangle (2 triangles = 6 vertices).
        buildXTicks(xTicks, minY: minY, maxY: maxY, chartTransform: chartTransform)
        buildYTicks(yTicks, minX: minX, maxX: maxX, chartTransform: chartTransform)
    }
    
    /// Renders pinned axes + grid lines.
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        guard let axisPipeline = axisPipelineState else { return }
        
        // Viewport size buffer
        var vp = ViewportSize(size: SIMD2<Float>(Float(viewportSize.width),
                                                 Float(viewportSize.height)))
        guard let vpBuffer = device.makeBuffer(
            bytes: &vp,
            length: MemoryLayout<ViewportSize>.size,
            options: .storageModeShared
        ) else {
            print("Failed to create viewport buffer")
            return
        }
        
        renderEncoder.setVertexBuffer(vpBuffer, offset: 0, index: 1)
        
        // Draw horizontal grid lines
        if let buf = yTickBuffer, yTickVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            // We use .triangleList for the grid lines
            renderEncoder.drawPrimitives(type: .triangle,
                                         vertexStart: 0,
                                         vertexCount: yTickVertexCount)
        }
        
        // Draw vertical grid lines
        if let buf = xTickBuffer, xTickVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(buf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle,
                                         vertexStart: 0,
                                         vertexCount: xTickVertexCount)
        }
        
        // Draw pinned X axis (triangle strip)
        if let quadBuf = xAxisQuadBuffer, xAxisQuadVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(quadBuf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: xAxisQuadVertexCount)
        }
        
        // Draw pinned Y axis (triangle strip)
        if let quadBuf = yAxisQuadBuffer, yAxisQuadVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(quadBuf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: yAxisQuadVertexCount)
        }
    }
}

// MARK: - Private Helpers

extension PinnedAxesRenderer {
    
    // Build vertical grid lines for X ticks
    private func buildXTicks(_ xTicks: [Double],
                             minY: Float,
                             maxY: Float,
                             chartTransform: matrix_float4x4) {
        
        var xTickVerts: [Float] = []
        let lineThickness: Float = 1.0
        let halfT = lineThickness * 0.5
        
        // Convert data Y range to screen
        let topY = dataYtoScreenY(dataY: maxY, transform: chartTransform)
        let botY = dataYtoScreenY(dataY: minY, transform: chartTransform)
        
        for tick in xTicks {
            let sx = dataXtoScreenX(dataX: Float(tick), transform: chartTransform)
            
            // Make a vertical rectangle from (sx-halfT, botY) to (sx+halfT, topY)
            xTickVerts.append(contentsOf: makeQuadList(
                x0: sx - halfT,
                y0: botY,
                x1: sx + halfT,
                y1: topY,
                color: tickColor
            ))
        }
        
        xTickVertexCount = xTickVerts.count / 8  // each vertex = 8 floats
        xTickBuffer = device.makeBuffer(
            bytes: xTickVerts,
            length: xTickVerts.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
    }
    
    // Build horizontal grid lines for Y ticks
    private func buildYTicks(_ yTicks: [Double],
                             minX: Float,
                             maxX: Float,
                             chartTransform: matrix_float4x4) {
        
        var yTickVerts: [Float] = []
        let lineThickness: Float = 1.0
        let halfT = lineThickness * 0.5
        
        // Convert data X range to screen
        let leftX  = dataXtoScreenX(dataX: minX, transform: chartTransform)
        let rightX = dataXtoScreenX(dataX: maxX, transform: chartTransform)
        
        for tick in yTicks {
            let sy = dataYtoScreenY(dataY: Float(tick), transform: chartTransform)
            
            // Make a horizontal rectangle from (leftX, sy-halfT) to (rightX, sy+halfT)
            yTickVerts.append(contentsOf: makeQuadList(
                x0: leftX,
                y0: sy - halfT,
                x1: rightX,
                y1: sy + halfT,
                color: tickColor
            ))
        }
        
        yTickVertexCount = yTickVerts.count / 8
        yTickBuffer = device.makeBuffer(
            bytes: yTickVerts,
            length: yTickVerts.count * MemoryLayout<Float>.size,
            options: .storageModeShared
        )
    }
    
    /// Build a horizontal pinned axis (triangle strip).
    private func buildXAxisQuad(minDataX: Float,
                                maxDataX: Float,
                                transform: matrix_float4x4,
                                pinnedScreenX: Float,
                                pinnedScreenY: Float,
                                thickness: Float,
                                color: SIMD4<Float>) -> [Float] {
        
        // Convert maxX -> screen
        var rightX = dataXtoScreenX(dataX: maxDataX, transform: transform)
        if rightX < pinnedScreenX { rightX = pinnedScreenX }
        
        let halfT = thickness * 0.5
        let y0 = pinnedScreenY - halfT
        let y1 = pinnedScreenY + halfT
        
        // 4 vertices in a strip
        var verts: [Float] = []
        
        // v0
        verts.append(pinnedScreenX); verts.append(y0)
        verts.append(0);             verts.append(1)
        verts.append(color.x);       verts.append(color.y)
        verts.append(color.z);       verts.append(color.w)
        
        // v1
        verts.append(pinnedScreenX); verts.append(y1)
        verts.append(0);             verts.append(1)
        verts.append(color.x);       verts.append(color.y)
        verts.append(color.z);       verts.append(color.w)
        
        // v2
        verts.append(rightX);        verts.append(y0)
        verts.append(0);            verts.append(1)
        verts.append(color.x);      verts.append(color.y)
        verts.append(color.z);      verts.append(color.w)
        
        // v3
        verts.append(rightX);        verts.append(y1)
        verts.append(0);            verts.append(1)
        verts.append(color.x);      verts.append(color.y)
        verts.append(color.z);      verts.append(color.w)
        
        return verts
    }
    
    /// Build a vertical pinned axis (triangle strip).
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
        
        // 4 vertices in a strip
        var verts: [Float] = []
        
        // v0
        verts.append(x0);        verts.append(pinnedScreenY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        // v1
        verts.append(x1);        verts.append(pinnedScreenY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        // v2
        verts.append(x0);        verts.append(topY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        // v3
        verts.append(x1);        verts.append(topY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        return verts
    }
    
    /// Single rectangle as a triangle list (6 vertices).
    /// Two triangles: (v0, v1, v2) and (v2, v1, v3)
    private func makeQuadList(x0: Float,
                              y0: Float,
                              x1: Float,
                              y1: Float,
                              color: SIMD4<Float>) -> [Float] {
        return [
            // Triangle 1
            x0, y0, 0, 1, color.x, color.y, color.z, color.w,  // v0
            x0, y1, 0, 1, color.x, color.y, color.z, color.w,  // v1
            x1, y0, 0, 1, color.x, color.y, color.z, color.w,  // v2
            
            // Triangle 2
            x1, y0, 0, 1, color.x, color.y, color.z, color.w,  // v2
            x0, y1, 0, 1, color.x, color.y, color.z, color.w,  // v1
            x1, y1, 0, 1, color.x, color.y, color.z, color.w   // v3
        ]
    }
    
    // Convert data X -> screen X
    private func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(dataX, 0, 0, 1)
        let ndcX = clip.x / clip.w
        return (ndcX * 0.5 + 0.5) * Float(viewportSize.width)
    }
    
    // Convert data Y -> screen Y
    private func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        return (1 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
    }
    
    /// Basic 'nice ticks' generator
    private func generateNiceTicks(minVal: Double,
                                   maxVal: Double,
                                   desiredCount: Int) -> [Double] {
        guard minVal < maxVal, desiredCount > 0 else { return [] }
        let range = maxVal - minVal
        let rawStep = range / Double(desiredCount)
        
        let mag = pow(10.0, floor(log10(rawStep)))
        let leading = rawStep / mag
        let niceLeading: Double
        if leading < 2 { niceLeading = 2 }
        else if leading < 5 { niceLeading = 5 }
        else { niceLeading = 10 }
        
        let step = niceLeading * mag
        let start = floor(minVal / step) * step
        
        var result: [Double] = []
        var v = start
        while v <= maxVal {
            if v >= minVal {
                result.append(v)
            }
            v += step
        }
        return result
    }
}
