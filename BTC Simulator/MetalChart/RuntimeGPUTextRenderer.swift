//
//  RuntimeGPUTextRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Metal
import simd
import Foundation

/// A GPU-based text renderer that uses a font atlas generated at runtime.
public class RuntimeGPUTextRenderer {
    
    public let device: MTLDevice
    public let atlas: RuntimeFontAtlas
    var pipelineState: MTLRenderPipelineState?
    
    public init(device: MTLDevice,
                atlas: RuntimeFontAtlas,
                library: MTLLibrary) {
        self.device = device
        self.atlas = atlas
        buildPipeline(library: library)
    }
    
    private func buildPipeline(library: MTLLibrary) {
        // We assume you have text shaders: "textVertexShader" + "textFragmentShader"
        let vertexFunc   = library.makeFunction(name: "textVertexShader")
        let fragmentFunc = library.makeFunction(name: "textFragmentShader")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        
        descriptor.rasterSampleCount = 4
        
        // Layout: position.xy, texcoord.xy, color.rgba
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
    
    /// Build a vertex buffer for the given string at (x,y) in your coordinate system.
    public func buildTextVertices(string: String,
                                  x: Float,
                                  y: Float,
                                  color: simd_float4) -> (MTLBuffer?, Int) {
        
        var vertices: [Float] = []
        var penX = x
        let penY = y
        
        for ch in string {
            guard let gm = atlas.glyphs[ch] else { continue }
            
            let x0 = penX + gm.xOffset
            // Typically, penY + gm.yOffset - gm.height for baseline logic
            let y0 = penY + gm.yOffset - gm.height
            let x1 = x0 + gm.width
            let y1 = y0 + gm.height
            
            let u0 = gm.uMin
            let v0 = gm.vMin
            let u1 = gm.uMax
            let v1 = gm.vMax
            
            // Triangle #1
            vertices.append(contentsOf: [x0, y0, u0, v0, color.x, color.y, color.z, color.w])
            vertices.append(contentsOf: [x1, y0, u1, v0, color.x, color.y, color.z, color.w])
            vertices.append(contentsOf: [x0, y1, u0, v1, color.x, color.y, color.z, color.w])
            
            // Triangle #2
            vertices.append(contentsOf: [x1, y0, u1, v0, color.x, color.y, color.z, color.w])
            vertices.append(contentsOf: [x1, y1, u1, v1, color.x, color.y, color.z, color.w])
            vertices.append(contentsOf: [x0, y1, u0, v1, color.x, color.y, color.z, color.w])
            
            penX += gm.xAdvance
        }
        
        let vertexCount = vertices.count / 8
        if vertexCount == 0 { return (nil, 0) }
        
        let length = vertices.count * MemoryLayout<Float>.size
        guard let buffer = device.makeBuffer(bytes: vertices,
                                             length: length,
                                             options: .storageModeShared) else {
            return (nil, 0)
        }
        
        return (buffer, vertexCount)
    }
    
    /// Draw the text from a buffer of vertices
    public func drawText(encoder: MTLRenderCommandEncoder,
                         vertexBuffer: MTLBuffer,
                         vertexCount: Int,
                         transformBuffer: MTLBuffer? = nil) {
        guard let pipelineState = pipelineState else { return }
        encoder.setRenderPipelineState(pipelineState)
        
        // Vertex buffer at index 0
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Transform buffer or identity
        if let transformBuffer = transformBuffer {
            encoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        } else {
            var identity = matrix_identity_float4x4
            let identityBuffer = device.makeBuffer(bytes: &identity,
                                                   length: MemoryLayout<matrix_float4x4>.size,
                                                   options: .storageModeShared)
            encoder.setVertexBuffer(identityBuffer, offset: 0, index: 1)
        }
        
        // Font atlas texture
        encoder.setFragmentTexture(atlas.texture, index: 0)
        
        // Draw
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}

// MARK: - Large-Number Suffix Logic

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
        
        // exponent = floor(log10(absVal))
        // We'll do it with Double or NSDecimalNumber:
        let doubleVal = NSDecimalNumber(decimal: absVal).doubleValue
        let exponent = Int(floor(log10(doubleVal)))
        
        // If exponent > 21, fallback
        if exponent > 21 {
            return sign + String(format: "%.2f", doubleVal)
        }
        
        // e.g. 19 => 18, 10 => 9, 7 => 6
        let groupedExponent = exponent - (exponent % 3)
        let leadingNumber = doubleVal / pow(10, Double(groupedExponent))
        
        let suffix = suffixForGroupedExponent(groupedExponent)
        return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
    }
    
    /// Helper to map exponent multiple-of-3 => suffix
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
            // fallback for weird exponent
            return ""
        }
    }
}

// MARK: - Public Tick Formatting

public extension RuntimeGPUTextRenderer {
    /// Format a Decimal as a short suffix (K, M, B, T...) or full decimal if under 1K or exponent>21.
    func formatTickDecimal(_ val: Decimal) -> String {
        val.formattedGroupedSuffix()
    }
    
    /// Builds a vertex buffer for a tick label from a Decimal, placing it at (x, y).
    func buildTickLabelVertices(value: Decimal,
                                x: Float,
                                y: Float,
                                color: simd_float4) -> (MTLBuffer?, Int) {
        let text = formatTickDecimal(value)
        return buildTextVertices(string: text, x: x, y: y, color: color)
    }
}
