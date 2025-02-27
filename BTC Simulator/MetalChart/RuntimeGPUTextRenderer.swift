//
//  RuntimeGPUTextRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Metal
import simd

/// A GPU-based text renderer that uses a font atlas generated at runtime.
public class RuntimeGPUTextRenderer {
    
    public let device: MTLDevice
    public let atlas: RuntimeFontAtlas
    private var pipelineState: MTLRenderPipelineState?
    
    public init(device: MTLDevice,
                atlas: RuntimeFontAtlas,
                library: MTLLibrary) {
        self.device = device
        self.atlas = atlas
        buildPipeline(library: library)
    }
    
    private func buildPipeline(library: MTLLibrary) {
        // We assume you have text shaders "textVertexShader" + "textFragmentShader"
        let vertexFunc   = library.makeFunction(name: "textVertexShader")
        let fragmentFunc = library.makeFunction(name: "textFragmentShader")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        
        // We'll define a layout: position.xy, texcoord.xy, color.rgba
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
    
    /// Build a vertex buffer for the given string at (x,y) in your coordinate system (screen coords or data coords).
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
            // Typically, penY + gm.yOffset - gm.height if you want baseline logic
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
        guard let buffer = device.makeBuffer(bytes: vertices, length: length, options: .storageModeShared) else {
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
        
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // If you want a transform uniform buffer (like MVP), pass it here as index 1, if your vertex shader is set up for it:
        if let transformBuffer = transformBuffer {
            encoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        }
        
        // Font atlas as the fragment texture
        encoder.setFragmentTexture(atlas.texture, index: 0)
        
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
