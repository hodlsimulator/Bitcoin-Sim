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

/// A simple class that draws pinned x and y axes in screen space:
///  - X-axis pinned at the bottom
///  - Y-axis pinned at the left
/// It also draws tick labels using the RuntimeGPUTextRenderer.
class PinnedAxesRenderer {
    
    // MARK: - Properties
    
    /// Device and text renderer
    private let device: MTLDevice
    private let textRenderer: RuntimeGPUTextRenderer
    
    /// Pipeline state for axis lines (we can reuse or create a small one).
    private var axisPipelineState: MTLRenderPipelineState?
    
    /// The size of the screen in pixels. Set each frame in your draw call.
    var viewportSize: CGSize = .zero
    
    /// If you want to style your axis lines
    var axisColor = SIMD4<Float>(1, 1, 1, 1)
    
    /// If you want to style your label text
    var labelColor = SIMD4<Float>(0.8, 0.8, 0.8, 1.0)
    
    // Axis line buffers
    private var xAxisLineBuffer: MTLBuffer?
    private var xAxisLineVertexCount: Int = 0
    private var yAxisLineBuffer: MTLBuffer?
    private var yAxisLineVertexCount: Int = 0
    
    // Tick label buffers
    struct TickLabelBuffer {
        let buffer: MTLBuffer
        let vertexCount: Int
    }
    private var xTickLabels: [TickLabelBuffer] = []
    private var yTickLabels: [TickLabelBuffer] = []
    
    // MARK: - Init
    
    init(device: MTLDevice,
         textRenderer: RuntimeGPUTextRenderer,
         library: MTLLibrary) {
        
        self.device = device
        self.textRenderer = textRenderer
        
        // Build a minimal pipeline for the axes lines
        buildAxisPipeline(library: library)
    }
    
    // MARK: - Pipeline
    
    private func buildAxisPipeline(library: MTLLibrary) {
        let descriptor = MTLRenderPipelineDescriptor()
        
        // Vertex/fragment for lines (you can reuse your chart pipeline if it’s the same layout)
        let vertexFunction = library.makeFunction(name: "axisVertexShader_screenSpace")
        let fragmentFunction = library.makeFunction(name: "axisFragmentShader")
        
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        
        // If you're using MSAA in the main pass:
        descriptor.rasterSampleCount = 4 // or match your actual sample count
        
        // Vertex descriptor: position float4, color float4
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // color
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
    
    // MARK: - Update & Build Buffers
    
    /// Updates the pinned axes lines + tick labels.
    /// - Parameters:
    ///   - minX, maxX, minY, maxY: the currently *visible* data range
    ///   - chartTransform: the matrix you use to convert data -> NDC
    func updateAxes(minX: Float,
                    maxX: Float,
                    minY: Float,
                    maxY: Float,
                    chartTransform: matrix_float4x4) {
        
        // Build pinned x-axis line at bottom
        // We'll position it, say, 50px from the bottom. Tweak as desired.
        let bottomScreenY: Float = Float(viewportSize.height - 40)  // 40 px from top
        print(">> viewportSize.height =", viewportSize.height, "=> bottomScreenY =", bottomScreenY)
        
        let xLineVerts = buildXAxisLine(minDataX: minX,
                                        maxDataX: maxX,
                                        transform: chartTransform,
                                        pinnedScreenY: bottomScreenY,
                                        color: axisColor)
        xAxisLineVertexCount = xLineVerts.count / 8
        if let buf = device.makeBuffer(bytes: xLineVerts,
                                       length: xLineVerts.count * MemoryLayout<Float>.size,
                                       options: .storageModeShared) {
            xAxisLineBuffer = buf
        }
        
        // Build pinned y-axis at left
        let leftScreenX: Float = 50 // pinned 50 px from left
        print(">> viewportSize.width =", viewportSize.width, "=> leftScreenX =", leftScreenX)
        
        let yLineVerts = buildYAxisLine(minDataY: minY,
                                        maxDataY: maxY,
                                        transform: chartTransform,
                                        pinnedScreenX: leftScreenX,
                                        color: axisColor)
        yAxisLineVertexCount = yLineVerts.count / 8
        if let buf = device.makeBuffer(bytes: yLineVerts,
                                       length: yLineVerts.count * MemoryLayout<Float>.size,
                                       options: .storageModeShared) {
            yAxisLineBuffer = buf
        }
        
        // Generate ticks. This is just a simplistic “nice ticks” approach:
        let xTicks = generateNiceTicks(minVal: Double(minX), maxVal: Double(maxX), desiredCount: 5)
        let yTicks = generateNiceTicks(minVal: Double(minY), maxVal: Double(maxY), desiredCount: 5)
        
        // Build label buffers
        xTickLabels.removeAll()
        for tick in xTicks {
            let floatVal = Float(tick)
            let screenX = dataXtoScreenX(dataX: floatVal, transform: chartTransform)
            let labelY = bottomScreenY - 15 // place label just below the axis line
            let labelStr = formatTick(floatVal)
            
            print(">> xTick =", floatVal, "=> screenX =", screenX, "labelY =", labelY, "labelStr =", labelStr)
            
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
            let labelX = leftScreenX // pinned to left
            let labelStr = formatTick(floatVal)
            
            print(">> yTick =", floatVal, "=> screenY =", screenY, "labelX =", labelX, "labelStr =", labelStr)
            
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
    
    // MARK: - Drawing
    
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        guard let axisPipeline = axisPipelineState else { return }
        
        // Create a ViewportSize instance matching the current viewport dimensions.
        var vp = ViewportSize(size: SIMD2<Float>(Float(viewportSize.width), Float(viewportSize.height)))
        guard let vpBuffer = device.makeBuffer(bytes: &vp, length: MemoryLayout<ViewportSize>.size, options: .storageModeShared) else {
            print("Failed to create viewport buffer")
            return
        }
        
        // Set the viewport buffer at vertex buffer index 1 (expected by your screen-space vertex shader)
        renderEncoder.setVertexBuffer(vpBuffer, offset: 0, index: 1)
        
        // Draw pinned x-axis line
        if let xBuf = xAxisLineBuffer, xAxisLineVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(xBuf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: xAxisLineVertexCount)
        }
        
        // Draw pinned y-axis line
        if let yBuf = yAxisLineBuffer, yAxisLineVertexCount > 0 {
            renderEncoder.setRenderPipelineState(axisPipeline)
            renderEncoder.setVertexBuffer(yBuf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: yAxisLineVertexCount)
        }
        
        // Draw x-axis tick labels (already built in screen space)
        for label in xTickLabels {
            textRenderer.drawText(encoder: renderEncoder,
                                  vertexBuffer: label.buffer,
                                  vertexCount: label.vertexCount,
                                  transformBuffer: nil)
        }
        
        // Draw y-axis tick labels
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
    
    /// Build a line from (xMinData, pinnedScreenY) to (xMaxData, pinnedScreenY) in *screen space*.
    private func buildXAxisLine(minDataX: Float,
                                maxDataX: Float,
                                transform: matrix_float4x4,
                                pinnedScreenY: Float,
                                color: SIMD4<Float>) -> [Float] {
        
        let leftX = dataXtoScreenX(dataX: minDataX, transform: transform)
        let rightX = dataXtoScreenX(dataX: maxDataX, transform: transform)
        
        print(">> X-axis line from (", leftX, ",", pinnedScreenY, ") to (", rightX, ",", pinnedScreenY, ")")
        
        var verts: [Float] = []
        
        // vertex #1
        verts.append(leftX)
        verts.append(pinnedScreenY)
        verts.append(0)   // z
        verts.append(1)   // w
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        // vertex #2
        verts.append(rightX)
        verts.append(pinnedScreenY)
        verts.append(0)
        verts.append(1)
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        return verts
    }
    
    /// Build a line from (pinnedScreenX, yMinData) to (pinnedScreenX, yMaxData) in screen space.
    private func buildYAxisLine(minDataY: Float,
                                maxDataY: Float,
                                transform: matrix_float4x4,
                                pinnedScreenX: Float,
                                color: SIMD4<Float>) -> [Float] {
        
        let bottomY = dataYtoScreenY(dataY: minDataY, transform: transform)
        let topY    = dataYtoScreenY(dataY: maxDataY, transform: transform)
        
        var verts: [Float] = []
        
        // vertex #1
        verts.append(pinnedScreenX)
        verts.append(bottomY)
        verts.append(0)
        verts.append(1)
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        // vertex #2
        verts.append(pinnedScreenX)
        verts.append(topY)
        verts.append(0)
        verts.append(1)
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        return verts
    }
    
    /// Convert a data X coordinate to screen X, ignoring Y (which is pinned).
    private func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        // Full approach: multiply by transform and convert to screen space
        let clip = transform * float4(dataX, 0, 0, 1)
        let ndcX = clip.x / clip.w
        let screenX = (ndcX * 0.5 + 0.5) * Float(viewportSize.width)
        return screenX
    }
    
    /// Convert a data Y coordinate to screen Y, ignoring X.
    private func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * float4(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        let screenY = (1 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
        return screenY
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
    
    /// Basic formatting for numeric tick values
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
