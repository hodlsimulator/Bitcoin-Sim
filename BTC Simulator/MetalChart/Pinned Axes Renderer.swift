//
//  PinnedAxesRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import MetalKit
import simd

class PinnedAxesRenderer {
    
    // The device and a reference to your text renderer
    private let device: MTLDevice
    private let textRenderer: RuntimeGPUTextRenderer
    
    // Pipelines for lines (or reuse existing)
    private var axisPipelineState: MTLRenderPipelineState?
    
    // Axes geometry buffers
    private var xAxisLineBuffer: MTLBuffer?
    private var xAxisLineVertexCount: Int = 0
    
    private var yAxisLineBuffer: MTLBuffer?
    private var yAxisLineVertexCount: Int = 0
    
    // Tick label buffers
    private struct TickLabel {
        let buffer: MTLBuffer
        let count: Int
    }
    private var xTickLabels: [TickLabel] = []
    private var yTickLabels: [TickLabel] = []
    
    // Axis color, label color, etc.
    var axisColor = SIMD4<Float>(1, 1, 1, 1)
    var labelColor = SIMD4<Float>(1, 1, 1, 1)
    
    // The size of the viewport in screen pixels (needed for pinned transforms)
    var viewportSize: CGSize = .zero
    
    init(device: MTLDevice,
         textRenderer: RuntimeGPUTextRenderer,
         library: MTLLibrary) {
        self.device = device
        self.textRenderer = textRenderer
        
        buildPipeline(library: library)
    }
    
    private func buildPipeline(library: MTLLibrary) {
        // Similar to your chart’s pipeline, or you can reuse it
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        guard let vertexFunc = library.makeFunction(name: "axisVertexShader"),
              let fragFunc   = library.makeFunction(name: "axisFragmentShader")
        else { return }
        
        descriptor.vertexFunction   = vertexFunc
        descriptor.fragmentFunction = fragFunc
        
        // If you store position+color in a single buffer
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // color
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        descriptor.vertexDescriptor = vertexDescriptor
        
        do {
            axisPipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Error building pinned axis pipeline: \(error)")
        }
    }
    
    // MARK: - Update & Generate
    
    /// Call this each frame or whenever you need to update axis geometry
    /// minX/maxX come from your visible data range in X
    /// minY/maxY come from your visible data range in Y
    /// transform is your chart data transform (which we partially use)
    func updateAxes(minX: Float,
                    maxX: Float,
                    minY: Float,
                    maxY: Float,
                    chartTransform: matrix_float4x4) {
        
        // 1) Build line for X axis pinned at bottom (y = bottom of screen).
        //    But we want the data-based horizontal range to match the chart’s x-range.
        //    That means we apply the chart’s scale/translation *only* in X dimension,
        //    while forcing Y to a specific screen coordinate.
        
        // The simplest approach: we build the “pinned line” in **screen space** directly.
        // Then we skip any transformation in the vertex shader (or pass an identity MVP).
        
        // Let’s say the bottom edge is at y = viewportSize.height - 1 px offset?
        let bottomY: Float = Float(viewportSize.height - 30) // e.g., 30 px from bottom if you want spacing
        // Convert x data coords -> screen coords, but y is pinned
        let xLineVerts = buildXAxisLine(minDataX: minX,
                                        maxDataX: maxX,
                                        chartTransform: chartTransform,
                                        pinnedScreenY: bottomY,
                                        color: axisColor)
        xAxisLineVertexCount = xLineVerts.count / 8
        xAxisLineBuffer = device.makeBuffer(bytes: xLineVerts,
                                            length: xLineVerts.count * MemoryLayout<Float>.size,
                                            options: .storageModeShared)
        
        // 2) Build line for Y axis pinned at left
        let leftX: Float = 50 // e.g. pinned 50 px from left
        let yLineVerts = buildYAxisLine(minDataY: minY,
                                        maxDataY: maxY,
                                        chartTransform: chartTransform,
                                        pinnedScreenX: leftX,
                                        color: axisColor)
        yAxisLineVertexCount = yLineVerts.count / 8
        yAxisLineBuffer = device.makeBuffer(bytes: yLineVerts,
                                            length: yLineVerts.count * MemoryLayout<Float>.size,
                                            options: .storageModeShared)
        
        // 3) Build tick labels (x)
        xTickLabels.removeAll()
        let xTicks = generateNiceTicks(minVal: Double(minX), maxVal: Double(maxX), desiredCount: 5)
        for tickVal in xTicks {
            let floatVal = Float(tickVal)
            let screenX = dataXtoScreenX(dataX: floatVal, transform: chartTransform)
            // pinned at the bottom
            let screenY = bottomY - 15 // e.g. put label slightly below axis line
            let labelStr = formatTick(floatVal)
            
            // Build text in screen coords (so no transform in the vertex shader).
            // Usually, you store those coords in data space. But here we want pinned screen space.
            let (buf, count) = textRenderer.buildTextVertices(
                string: labelStr,
                x: screenX,
                y: screenY,
                color: labelColor
            )
            if let b = buf {
                xTickLabels.append(TickLabel(buffer: b, count: count))
            }
        }
        
        // 4) Build tick labels (y)
        yTickLabels.removeAll()
        let yTicks = generateNiceTicks(minVal: Double(minY), maxVal: Double(maxY), desiredCount: 5)
        for tickVal in yTicks {
            let floatVal = Float(tickVal)
            let screenY = dataYtoScreenY(dataY: floatVal, transform: chartTransform)
            let screenX = leftX // pinned to left
            let labelStr = formatTick(floatVal)
            
            let (buf, count) = textRenderer.buildTextVertices(
                string: labelStr,
                x: screenX,
                y: screenY,
                color: labelColor
            )
            if let b = buf {
                yTickLabels.append(TickLabel(buffer: b, count: count))
            }
        }
    }
    
    // MARK: - Drawing
    
    func drawAxes(renderEncoder: MTLRenderCommandEncoder) {
        guard let pso = axisPipelineState else { return }
        
        renderEncoder.setRenderPipelineState(pso)
        
        // 1) Draw x-axis line
        if let xBuf = xAxisLineBuffer {
            renderEncoder.setVertexBuffer(xBuf, offset: 0, index: 0)
            // We’re drawing in screen space, so we might pass an identity MVP or
            // handle it in the vertex shader. For now, assume identity transform:
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: xAxisLineVertexCount)
        }
        
        // 2) Draw y-axis line
        if let yBuf = yAxisLineBuffer {
            renderEncoder.setVertexBuffer(yBuf, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: yAxisLineVertexCount)
        }
        
        // 3) Draw x-axis labels
        for label in xTickLabels {
            textRenderer.drawText(encoder: renderEncoder,
                                  vertexBuffer: label.buffer,
                                  vertexCount: label.count,
                                  transformBuffer: nil /* identity, screen space */)
        }
        
        // 4) Draw y-axis labels
        for label in yTickLabels {
            textRenderer.drawText(encoder: renderEncoder,
                                  vertexBuffer: label.buffer,
                                  vertexCount: label.count,
                                  transformBuffer: nil)
        }
    }
    
    // MARK: - Helpers
    
    /// Convert data X to screen X using the chart’s transform.
    /// We only extract the relevant scale/translation from the transform’s first column/last column, etc.
    private func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        // Apply your transform but ignore Y
        // Alternatively, you can transform a 4D vector (dataX, 0, 0, 1) and take the clip space to screen routine.
        
        // For demonstration, let's assume your transform is typical (scale, then translate)
        // We'll do a simplified approach:
        // m[3].x is translation.x, m[0].x is scale.x, etc. This is pseudo.
        
        // In reality, you might do the full multiply:
        // let v = float4(dataX, 0, 0, 1)
        // let clip = transform * v
        // let ndcX = clip.x / clip.w
        // let screenX = (ndcX * 0.5 + 0.5) * viewportSize.width
        // That’s the precise way. Here is a shorter approach if your transform is purely 2D scale+translate:
        
        let sx = transform.columns.0.x   // scaleX
        let tx = transform.columns.3.x   // translateX
        
        // dataX -> scaledX
        let scaledX = dataX * sx + tx
        
        // scaledX is in clip space [-1..1], map to screen
        let screenX = (scaledX * 0.5 + 0.5) * Float(viewportSize.width)
        return screenX
    }
    
    private func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        let sy = transform.columns.1.y
        let ty = transform.columns.3.y
        
        let scaledY = dataY * sy + ty
        let screenY = (1.0 - (scaledY * 0.5 + 0.5)) * Float(viewportSize.height)
        return screenY
    }
    
    private func buildXAxisLine(minDataX: Float, maxDataX: Float,
                                chartTransform: matrix_float4x4,
                                pinnedScreenY: Float,
                                color: SIMD4<Float>) -> [Float] {
        let leftScreenX = dataXtoScreenX(dataX: minDataX, transform: chartTransform)
        let rightScreenX = dataXtoScreenX(dataX: maxDataX, transform: chartTransform)
        
        // We store in screen space (x,y,0,1)
        var verts: [Float] = []
        // Start
        verts.append(leftScreenX)
        verts.append(pinnedScreenY)
        verts.append(0)
        verts.append(1)
        
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        // End
        verts.append(rightScreenX)
        verts.append(pinnedScreenY)
        verts.append(0)
        verts.append(1)
        
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        return verts
    }
    
    private func buildYAxisLine(minDataY: Float, maxDataY: Float,
                                chartTransform: matrix_float4x4,
                                pinnedScreenX: Float,
                                color: SIMD4<Float>) -> [Float] {
        let bottomScreenY = dataYtoScreenY(dataY: minDataY, transform: chartTransform)
        let topScreenY    = dataYtoScreenY(dataY: maxDataY, transform: chartTransform)
        
        var verts: [Float] = []
        // Start
        verts.append(pinnedScreenX)
        verts.append(bottomScreenY)
        verts.append(0)
        verts.append(1)
        
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        // End
        verts.append(pinnedScreenX)
        verts.append(topScreenY)
        verts.append(0)
        verts.append(1)
        
        verts.append(color.x)
        verts.append(color.y)
        verts.append(color.z)
        verts.append(color.w)
        
        return verts
    }
    
    private func generateNiceTicks(minVal: Double, maxVal: Double, desiredCount: Int) -> [Double] {
        // same “nice ticks” approach as earlier
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
            if v >= minVal { result.append(v) }
            v += step
        }
        return result
    }
    
    private func formatTick(_ value: Float) -> String {
        // e.g. handle large values with suffix
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
