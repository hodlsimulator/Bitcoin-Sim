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
    
    /// Axis colour and label colour
    var axisColor = SIMD4<Float>(1, 1, 1, 1)
    var labelColor = SIMD4<Float>(0.8, 0.8, 0.8, 1.0)
    
    /// We’ll store quads for each axis instead of lines
    private var xAxisQuadBuffer: MTLBuffer?
    private var xAxisQuadVertexCount: Int = 0
    
    private var yAxisQuadBuffer: MTLBuffer?
    private var yAxisQuadVertexCount: Int = 0
    
    struct TickLabelBuffer {
        let buffer: MTLBuffer
        let vertexCount: Int
    }
    private var xTickLabels: [TickLabelBuffer] = []
    private var yTickLabels: [TickLabelBuffer] = []
    
    init(device: MTLDevice,
         textRenderer: RuntimeGPUTextRenderer,
         library: MTLLibrary) {
        
        self.device = device
        self.textRenderer = textRenderer
        buildAxisPipeline(library: library)
    }
    
    private func buildAxisPipeline(library: MTLLibrary) {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "axisVertexShader_screenSpace")
        descriptor.fragmentFunction = library.makeFunction(name: "axisFragmentShader")
        
        // Match your sample count if needed
        descriptor.rasterSampleCount = 4
        
        // Our vertices: position (float4) + colour (float4)
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
    
    /// Updates the pinned axes (drawn as quads).
    func updateAxes(minX: Float,
                    maxX: Float,
                    minY: Float,
                    maxY: Float,
                    chartTransform: matrix_float4x4) {
        
        // Where the axes meet in screen space
        let pinnedScreenX: Float = 50
        let pinnedScreenY: Float = Float(viewportSize.height) - 40
        
        // If you want a thicker axis, increase this
        let axisThickness: Float = 2
        
        // Build a quad for the X axis (horizontal rectangle).
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
        
        // Build a quad for the Y axis (vertical rectangle).
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
        
        // Build tick labels (same as before)
        let xTicks = generateNiceTicks(minVal: Double(minX), maxVal: Double(maxX), desiredCount: 5)
        let yTicks = generateNiceTicks(minVal: Double(minY), maxVal: Double(maxY), desiredCount: 5)
        
        xTickLabels.removeAll()
        for tick in xTicks {
            let floatVal = Float(tick)
            let screenX = dataXtoScreenX(dataX: floatVal, transform: chartTransform)
            let labelY = pinnedScreenY + 5
            let labelStr = formatTick(floatVal)
            
            let (buf, count) = textRenderer.buildTextVertices(
                string: labelStr,
                x: screenX,
                y: labelY,
                color: labelColor
            )
            if let b = buf {
                xTickLabels.append(TickLabelBuffer(buffer: b, vertexCount: count))
            }
        }
        
        yTickLabels.removeAll()
        for tick in yTicks {
            let floatVal = Float(tick)
            let screenY = dataYtoScreenY(dataY: floatVal, transform: chartTransform)
            let labelX = pinnedScreenX - 30
            let labelStr = formatTick(floatVal)
            
            let (buf, count) = textRenderer.buildTextVertices(
                string: labelStr,
                x: labelX,
                y: screenY,
                color: labelColor
            )
            if let b = buf {
                yTickLabels.append(TickLabelBuffer(buffer: b, vertexCount: count))
            }
        }
    }
    
    /// Draw everything
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        guard let axisPipeline = axisPipelineState else { return }
        
        // Pass viewport size in buffer index 1
        var vp = ViewportSize(size: SIMD2<Float>(Float(viewportSize.width), Float(viewportSize.height)))
        guard let vpBuffer = device.makeBuffer(bytes: &vp, length: MemoryLayout<ViewportSize>.size, options: .storageModeShared) else {
            print("Failed to create viewport buffer")
            return
        }
        
        renderEncoder.setVertexBuffer(vpBuffer, offset: 0, index: 1)
        
        // Draw X axis quad
        if let quadBuf = xAxisQuadBuffer, xAxisQuadVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(quadBuf, offset: 0, index: 0)
            // We use .triangleStrip to draw the rectangle as 4 vertices in a strip
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: xAxisQuadVertexCount)
        }
        
        // Draw Y axis quad
        if let quadBuf = yAxisQuadBuffer, yAxisQuadVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(quadBuf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip,
                                         vertexStart: 0,
                                         vertexCount: yAxisQuadVertexCount)
        }
        
        // Draw tick labels
        for label in xTickLabels {
            textRenderer.drawText(encoder: renderEncoder,
                                  vertexBuffer: label.buffer,
                                  vertexCount: label.vertexCount,
                                  transformBuffer: nil)
        }
        for label in yTickLabels {
            textRenderer.drawText(encoder: renderEncoder,
                                  vertexBuffer: label.buffer,
                                  vertexCount: label.vertexCount,
                                  transformBuffer: nil)
        }
    }
}

// MARK: - Helper Methods

extension PinnedAxesRenderer {
    
    /// Build a horizontal quad for the X axis, pinned at (pinnedScreenX, pinnedScreenY).
    private func buildXAxisQuad(minDataX: Float,
                                maxDataX: Float,
                                transform: matrix_float4x4,
                                pinnedScreenX: Float,
                                pinnedScreenY: Float,
                                thickness: Float,
                                color: SIMD4<Float>) -> [Float] {
        
        // Convert maxX to screen
        var rightX = dataXtoScreenX(dataX: maxDataX, transform: transform)
        if rightX < pinnedScreenX { rightX = pinnedScreenX }
        
        // We'll draw the axis as a rectangle from Y-thickness/2 to Y+thickness/2
        let halfT = thickness * 0.2
        let y0 = pinnedScreenY - halfT
        let y1 = pinnedScreenY + halfT
        
        // We have 4 vertices in a triangle strip layout:
        // (leftX, y0), (leftX, y1), (rightX, y0), (rightX, y1)
        var verts: [Float] = []
        
        // V0
        verts.append(pinnedScreenX); verts.append(y0)
        verts.append(0);             verts.append(1)
        verts.append(color.x);       verts.append(color.y)
        verts.append(color.z);       verts.append(color.w)
        
        // V1
        verts.append(pinnedScreenX); verts.append(y1)
        verts.append(0);             verts.append(1)
        verts.append(color.x);       verts.append(color.y)
        verts.append(color.z);       verts.append(color.w)
        
        // V2
        verts.append(rightX);        verts.append(y0)
        verts.append(0);             verts.append(1)
        verts.append(color.x);       verts.append(color.y)
        verts.append(color.z);       verts.append(color.w)
        
        // V3
        verts.append(rightX);        verts.append(y1)
        verts.append(0);             verts.append(1)
        verts.append(color.x);       verts.append(color.y)
        verts.append(color.z);       verts.append(color.w)
        
        return verts
    }
    
    /// Build a vertical quad for the Y axis, pinned at (pinnedScreenX, pinnedScreenY).
    private func buildYAxisQuad(minDataY: Float,
                                maxDataY: Float,
                                transform: matrix_float4x4,
                                pinnedScreenX: Float,
                                pinnedScreenY: Float,
                                thickness: Float,
                                color: SIMD4<Float>) -> [Float] {
        
        // Convert maxY to screen
        var topY = dataYtoScreenY(dataY: maxDataY, transform: transform)
        if topY > pinnedScreenY { topY = pinnedScreenY }
        
        let halfT = thickness * 0.2
        let x0 = pinnedScreenX - halfT
        let x1 = pinnedScreenX + halfT
        
        // 4 vertices in triangle strip:
        // (x0, bottomY), (x1, bottomY), (x0, topY), (x1, topY)
        var verts: [Float] = []
        
        // V0
        verts.append(x0);        verts.append(pinnedScreenY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        // V1
        verts.append(x1);        verts.append(pinnedScreenY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        // V2
        verts.append(x0);        verts.append(topY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        // V3
        verts.append(x1);        verts.append(topY)
        verts.append(0);         verts.append(1)
        verts.append(color.x);   verts.append(color.y)
        verts.append(color.z);   verts.append(color.w)
        
        return verts
    }
    
    /// Convert data X coordinate to screen X
    private func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(dataX, 0, 0, 1)
        let ndcX = clip.x / clip.w
        return (ndcX * 0.5 + 0.5) * Float(viewportSize.width)
    }
    
    /// Convert data Y coordinate to screen Y
    private func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        return (1 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
    }
    
    /// Basic "nice ticks" generator
    private func generateNiceTicks(minVal: Double, maxVal: Double, desiredCount: Int) -> [Double] {
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
    
    private func formatTick(_ value: Float) -> String {
        let absVal = abs(value)
        switch absVal {
        case 1_000_000_000...:
            return String(format: "%.1fB", value / 1e9)
        case 1_000_000...:
            return String(format: "%.1fM", value / 1e6)
        case 1_000...:
            return String(format: "%.1fK", value / 1e3)
        default:
            return String(format: "%.2f", value)
        }
    }
}
