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
    
    private let device: MTLDevice
    private let textRenderer: GPUTextRenderer
    private var axisPipelineState: MTLRenderPipelineState?
    
    // Set each frame from outside
    var viewportSize: CGSize = .zero
    
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
    private var xGridBuffer: MTLBuffer?
    private var xGridVertexCount = 0
    
    private var yGridBuffer: MTLBuffer?
    private var yGridVertexCount = 0
    
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
        // Where the pinned axes should be drawn
        let pinnedScreenX: Float = 50
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
        xAxisQuadBuffer = device.makeBuffer(bytes: xQuadVerts,
                                            length: xQuadVerts.count * MemoryLayout<Float>.size,
                                            options: .storageModeShared)
        
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
        yAxisQuadBuffer = device.makeBuffer(bytes: yQuadVerts,
                                            length: yQuadVerts.count * MemoryLayout<Float>.size,
                                            options: .storageModeShared)
        
        // Generate tick arrays
        let tickXValues = generateNiceTicks(minVal: Double(minX),
                                            maxVal: Double(maxX),
                                            desiredCount: 6)
        // Increase Y ticks to 10 instead of 6
        let tickYValues = generateNiceTicks(minVal: Double(minY),
                                            maxVal: Double(maxY),
                                            desiredCount: 10)
        
        let gridXValues = generateNiceTicks(minVal: Double(minX),
                                            maxVal: Double(maxX),
                                            desiredCount: 10)
        // Use the exact same array so grid lines match the ticks
        let gridYValues = tickYValues
        
        // 3) Ticks + labels
        let (xTickVerts, xTickTexts) = buildXTicks(
            tickXValues,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform,
            minX: minX,
            maxX: maxX
        )
        xTickVertexCount = xTickVerts.count / 8
        xTickBuffer = device.makeBuffer(bytes: xTickVerts,
                                        length: xTickVerts.count * MemoryLayout<Float>.size,
                                        options: .storageModeShared)
        xTickTextBuffers = xTickTexts.map { $0.0 }
        xTickTextVertexCounts = xTickTexts.map { $0.1 }
        
        let (yTickVerts, yTickTexts) = buildYTicks(
            tickYValues,
            pinnedScreenX: pinnedScreenX,
            pinnedScreenY: pinnedScreenY,
            chartTransform: chartTransform
        )
        yTickVertexCount = yTickVerts.count / 8
        yTickBuffer = device.makeBuffer(bytes: yTickVerts,
                                        length: yTickVerts.count * MemoryLayout<Float>.size,
                                        options: .storageModeShared)
        yTickTextBuffers = yTickTexts.map { $0.0 }
        yTickTextVertexCounts = yTickTexts.map { $0.1 }
        
        // 4) Grid lines
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
        
        // 5) Axis labels (“Years”, “USD”) at smaller scale
        let (maybeXBuf, xCount) = textRenderer.buildTextVertices(
            string: "Period",
            x: pinnedScreenX + 100,
            y: pinnedScreenY + 15,
            color: axisColor,
            scale: 0.35,
            screenWidth: Float(viewportSize.width),
            screenHeight: Float(viewportSize.height)
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
            screenHeight: Float(viewportSize.height)
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
                [2/width, 0,       0, 0],
                [0,       -2/height,0, 0],
                [0,        0,       1, 0],
                [-1,       1,       0, 1]
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

// MARK: - Building the Ticks (no decimals)

extension PinnedAxesRenderer {
    
    /// X Ticks: Switch among years, months, or weeks (no decimals).
    private func buildXTicks(
        _ xTicks: [Double],
        pinnedScreenY: Float,
        chartTransform: matrix_float4x4,
        minX: Float,
        maxX: Float
    ) -> ([Float], [(MTLBuffer, Int)]) {
        
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []
        
        // We'll do a trivial cutoff:
        // If (maxX - minX) > 2 => treat as years
        // else if > 0.5 => treat as months
        // else => weeks
        let range = Double(maxX - minX)
        
        let tickLen: Float = 6
        let halfT: Float = 0.5
        
        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            if sx < 50 { continue } // skip left side
            
            // Build short tick line
            let y0 = pinnedScreenY
            let y1 = pinnedScreenY - tickLen
            verts.append(contentsOf: makeQuadList(
                x0: sx - halfT,
                y0: y1,
                x1: sx + halfT,
                y1: y0,
                color: tickColor
            ))
            
            // Decide label format
            var label = ""
            if range > 2.0 {
                // Show integer years with "y"
                label = "\(Int(val))y"
            } else if range > 0.5 {
                // Show months
                let months = Int(val * 12.0)
                label = "\(months)m"
            } else {
                // Show weeks
                let weeks = Int(val * 52.0)
                label = "\(weeks)w"
            }
            
            // Place the text just above the axis
            let textY = pinnedScreenY - tickLen - 10
            let (tBuf, vCount) = textRenderer.buildTextVertices(
                string: label,
                x: sx,
                y: textY,
                color: tickColor,
                scale: 0.35,
                screenWidth: Float(viewportSize.width),
                screenHeight: Float(viewportSize.height)
            )
            if let buf = tBuf {
                textBuffers.append((buf, vCount))
            }
        }
        
        return (verts, textBuffers)
    }
    
    /// Y Ticks: Use big number suffix, no decimals
    private func buildYTicks(
        _ yTicks: [Double],
        pinnedScreenX: Float,
        pinnedScreenY: Float,
        chartTransform: matrix_float4x4
    ) -> ([Float], [(MTLBuffer, Int)]) {
        
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []
        let tickLen: Float = 6
        let halfT: Float = 0.5
        
        for val in yTicks {
            let sy = dataYtoScreenY(dataY: Float(val), transform: chartTransform)
            if sy < 0 || sy > pinnedScreenY { continue }

            // Short tick line to the left of the axis
            let x1 = pinnedScreenX
            let x0 = pinnedScreenX - tickLen
            
            verts.append(contentsOf: makeQuadList(
                x0: x0,
                y0: sy - halfT,
                x1: x1,
                y1: sy + halfT,
                color: tickColor
            ))
            
            // Format using a no‐decimal big number suffix
            let formatted = val.formattedGroupedSuffixNoDecimals()
            
            // Put text left of the axis
            let textX = pinnedScreenX - tickLen - 30
            let textY = sy - 5
            
            let (tBuf, vCount) = textRenderer.buildTextVertices(
                string: formatted,
                x: textX,
                y: textY,
                color: tickColor,
                scale: 0.35,
                screenWidth: Float(viewportSize.width),
                screenHeight: Float(viewportSize.height)
            )
            if let buf = tBuf {
                textBuffers.append((buf, vCount))
            }
        }
        
        return (verts, textBuffers)
    }
}

// MARK: - Grid Lines

extension PinnedAxesRenderer {
    private func buildXGridLines(
        _ xTicks: [Double],
        minY: Float,
        maxY: Float,
        pinnedScreenX: Float,
        chartTransform: matrix_float4x4
    ) {
        var verts: [Float] = []
        let thickness: Float = 1
        let halfT = thickness * 0.5
        
        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            if sx < pinnedScreenX { continue }
            if sx > Float(viewportSize.width) { continue }
            
            verts.append(contentsOf: makeQuadList(
                x0: sx - halfT,
                y0: minY,
                x1: sx + halfT,
                y1: maxY,
                color: gridColor
            ))
        }
        xGridVertexCount = verts.count / 8
        xGridBuffer = device.makeBuffer(bytes: verts,
                                        length: verts.count * MemoryLayout<Float>.size,
                                        options: .storageModeShared)
    }
    
    private func buildYGridLines(
        _ yTicks: [Double],
        minX: Float,
        maxX: Float,
        pinnedScreenY: Float,
        chartTransform: matrix_float4x4
    ) {
        var verts: [Float] = []
        let thickness: Float = 1
        let halfT = thickness * 0.5
        
        for val in yTicks {
            let sy = dataYtoScreenY(dataY: Float(val), transform: chartTransform)
            if sy < 0 { continue }
            if sy > pinnedScreenY { continue }
            
            verts.append(contentsOf: makeQuadList(
                x0: minX,
                y0: sy - halfT,
                x1: maxX,
                y1: sy + halfT,
                color: gridColor
            ))
        }
        yGridVertexCount = verts.count / 8
        yGridBuffer = device.makeBuffer(bytes: verts,
                                        length: verts.count * MemoryLayout<Float>.size,
                                        options: .storageModeShared)
    }
}

// MARK: - Helpers

extension PinnedAxesRenderer {
    
    /// Build 2 triangles (6 vertices) for a filled quad
    func makeQuadList(
        x0: Float, y0: Float,
        x1: Float, y1: Float,
        color: SIMD4<Float>
    ) -> [Float] {
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
    
    /// Converts data X to screen X
    func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(dataX, 0, 0, 1)
        let ndcX = clip.x / clip.w
        return (ndcX * 0.5 + 0.5) * Float(viewportSize.width)
    }

    /// Converts data Y to screen Y
    func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        return (1 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
    }

    /// Simple "nice" ticks
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
        let niceLeading: Double = (leading < 2.0) ? 2.0 : (leading < 5.0 ? 5.0 : 10.0)
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
    
    // X axis triangle strip
    func buildXAxisQuad(
        minDataX: Float,
        maxDataX: Float,
        transform: matrix_float4x4,
        pinnedScreenX: Float,
        pinnedScreenY: Float,
        thickness: Float,
        color: SIMD4<Float>
    ) -> [Float] {
        var rightX = dataXtoScreenX(dataX: maxDataX, transform: transform)
        if rightX < pinnedScreenX {
            rightX = pinnedScreenX
        }
        
        let halfT = thickness * 0.5
        let y0 = pinnedScreenY - halfT
        let y1 = pinnedScreenY + halfT
        
        var verts: [Float] = []
        verts.append(pinnedScreenX); verts.append(y0); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        verts.append(pinnedScreenX); verts.append(y1); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        verts.append(rightX);        verts.append(y0); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        verts.append(rightX);        verts.append(y1); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        return verts
    }
    
    // Y axis triangle strip
    func buildYAxisQuad(
        minDataY: Float,
        maxDataY: Float,
        transform: matrix_float4x4,
        pinnedScreenX: Float,
        pinnedScreenY: Float,
        thickness: Float,
        color: SIMD4<Float>
    ) -> [Float] {
        
        var topY = dataYtoScreenY(dataY: maxDataY, transform: transform)
        if topY > pinnedScreenY {
            topY = pinnedScreenY
        }
        
        let halfT = thickness * 0.5
        let x0 = pinnedScreenX - halfT
        let x1 = pinnedScreenX + halfT
        
        var verts: [Float] = []
        verts.append(x0); verts.append(pinnedScreenY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        verts.append(x1); verts.append(pinnedScreenY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        verts.append(x0); verts.append(topY);         verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        verts.append(x1); verts.append(topY);         verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        return verts
    }
}
