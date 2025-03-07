//
//  GPUTextRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Metal
import simd
import Foundation

/// A GPU-based text renderer that uses a font atlas generated at runtime.
public class GPUTextRenderer {

    public let device: MTLDevice
    public var atlas: RuntimeFontAtlas
    var pipelineState: MTLRenderPipelineState?

    public init(device: MTLDevice,
                atlas: RuntimeFontAtlas,
                library: MTLLibrary) {
        self.device = device
        self.atlas = atlas
        buildPipeline(library: library)
    }

    private func buildPipeline(library: MTLLibrary) {
        // Make sure these names match your .metal file
        let vertexFunc   = library.makeFunction(name: "textVertexShader")
        let fragmentFunc = library.makeFunction(name: "textFragmentShader")

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        descriptor.rasterSampleCount = 4  // If using MSAA
        
        // Vertex layout: position.xy, texcoord.xy, color.rgba
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2 // texcoord
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].format = .float4 // color
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        descriptor.vertexDescriptor = vertexDescriptor

        // Enable alpha blending
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Failed to create text pipeline: \(error)")
        }
    }

    /// Build a vertex buffer for the given string at (x,y).
    public func buildTextVertices(
        string: String,
        x: Float,
        y: Float,
        // Force white text by default:
        color: simd_float4 = simd_float4(1, 1, 1, 1),
        scale: Float = 1.0,
        screenWidth: Float,
        screenHeight: Float,
        letterSpacing: Float = 0.0
    ) -> (MTLBuffer?, Int) {

        var vertices: [Float] = []
        var penX = x
        let penY = y

        for ch in string {
            guard let gm = atlas.glyphs[ch] else { continue }

            let x0 = penX + gm.xOffset * scale
            let y0 = penY + gm.yOffset * scale
            let x1 = x0 + gm.width * scale
            let y1 = y0 + gm.height * scale

            // Cull offscreen
            if x1 < 0 || x0 > screenWidth || y1 < 0 || y0 > screenHeight {
                penX += (gm.xAdvance * scale) + letterSpacing
                continue
            }

            // Build triangles
            vertices.append(contentsOf: [
                x0, y0, gm.uMin, gm.vMin, color.x, color.y, color.z, color.w,
                x1, y0, gm.uMax, gm.vMin, color.x, color.y, color.z, color.w,
                x0, y1, gm.uMin, gm.vMax, color.x, color.y, color.z, color.w,

                x1, y0, gm.uMax, gm.vMin, color.x, color.y, color.z, color.w,
                x1, y1, gm.uMax, gm.vMax, color.x, color.y, color.z, color.w,
                x0, y1, gm.uMin, gm.vMax, color.x, color.y, color.z, color.w
            ])

            // Advance pen
            penX += (gm.xAdvance * scale) + letterSpacing
        }

        let vertexCount = vertices.count / 8
        if vertexCount == 0 {
            return (nil, 0)
        }

        let length = vertices.count * MemoryLayout<Float>.size
        guard let buffer = device.makeBuffer(
            bytes: vertices,
            length: length,
            options: .storageModeShared
        ) else {
            return (nil, 0)
        }

        return (buffer, vertexCount)
    }

    /// Draw a previously built text buffer
    public func drawText(
        encoder: MTLRenderCommandEncoder,
        vertexBuffer: MTLBuffer,
        vertexCount: Int,
        transformBuffer: MTLBuffer? = nil
    ) {
        guard let pipelineState = pipelineState else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // If no transform buffer provided, use an identity matrix
        if let transformBuffer = transformBuffer {
            encoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        } else {
            var identity = matrix_identity_float4x4
            let identityBuffer = device.makeBuffer(bytes: &identity,
                                                   length: MemoryLayout<matrix_float4x4>.size,
                                                   options: .storageModeShared)
            if let identityBuffer = identityBuffer {
                encoder.setVertexBuffer(identityBuffer, offset: 0, index: 1)
            }
        }

        encoder.setFragmentTexture(atlas.texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}

// MARK: - Large-Number Suffix Logic (Optional)
extension Decimal {
    /// Groups exponent in multiples of 3 and returns a short suffix (K,M,B,T,Q,Qn,Se).
    /// If exponent > 21, we fallback to a simple 2-decimal string with no suffix.
    fileprivate func formattedGroupedSuffix() -> String {
        if self == 0 {
            return "0.00"
        }
        let sign = (self < 0) ? "-" : ""
        let absVal = self.magnitude

        // If < 1,000, just show e.g. "999.99".
        if absVal < 1000 {
            return sign + String(format: "%.2f", NSDecimalNumber(decimal: absVal).doubleValue)
        }

        let doubleVal = NSDecimalNumber(decimal: absVal).doubleValue
        let exponent = Int(floor(log10(doubleVal)))

        // If exponent > 21, fallback
        if exponent > 21 {
            return sign + String(format: "%.2f", doubleVal)
        }

        // Round exponent down to nearest multiple of 3
        let groupedExponent = exponent - (exponent % 3)
        let leadingNumber = doubleVal / pow(10, Double(groupedExponent))

        let suffix = suffixForGroupedExponent(groupedExponent)
        return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
    }

    fileprivate func suffixForGroupedExponent(_ groupedExp: Int) -> String {
        switch groupedExp {
        case 0:  return ""
        case 3:  return "K"
        case 6:  return "M"
        case 9:  return "B"
        case 12: return "T"
        case 15: return "Q"
        case 18: return "Qn"
        case 21: return "Se"
        default:
            return ""
        }
    }
}

/// Helper to format Decimal -> short-suffix or decimal
public extension GPUTextRenderer {
    func formatTickDecimal(_ val: Decimal) -> String {
        val.formattedGroupedSuffix()
    }
    
    /// Build a text buffer for a tick label at (x, y).
    func buildTickLabelVertices(
        value: Decimal,
        x: Float,
        y: Float,
        color: simd_float4,
        scale: Float = 1.0,
        screenWidth: Float,
        screenHeight: Float
    ) -> (MTLBuffer?, Int) {
        let text = formatTickDecimal(value)
        return buildTextVertices(
            string: text,
            x: x,
            y: y,
            color: color,
            scale: scale,
            screenWidth: screenWidth,
            screenHeight: screenHeight
        )
    }
}

extension GPUTextRenderer {
    /// Measures total width of a single-line string in pixels (GPU side).
    func measureStringWidth(_ string: String,
                            scale: Float = 1.0,
                            letterSpacing: Float = 0.0) -> Float {
        var width: Float = 0
        for ch in string {
            guard let gm = atlas.glyphs[ch] else { continue }
            width += (gm.xAdvance * scale) + letterSpacing
        }
        return width
    }

    /// Measures the maximum character height for a single-line string in pixels.
    func measureStringHeight(_ string: String,
                             scale: Float = 1.0) -> Float {
        var maxH: Float = 0
        for ch in string {
            guard let gm = atlas.glyphs[ch] else { continue }
            let h = gm.height * scale
            if h > maxH {
                maxH = h
            }
        }
        return maxH
    }
}
