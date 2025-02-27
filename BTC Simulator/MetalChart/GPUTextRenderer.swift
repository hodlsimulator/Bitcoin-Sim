//
//  GPUTextRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Metal
import simd

public class GPUTextRenderer {
    
    private let device: MTLDevice
    private let atlas: GPUFontAtlas
    private var pipelineState: MTLRenderPipelineState?
    
    public init(device: MTLDevice, atlas: GPUFontAtlas, library: MTLLibrary) {
        self.device = device
        self.atlas = atlas
        self.buildPipeline(library: library)
    }
    
    private func buildPipeline(library: MTLLibrary) {
        let vertexFunc   = library.makeFunction(name: "sdfTextVertexShader")
        let fragmentFunc = library.makeFunction(name: "sdfTextFragmentShader")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction   = vertexFunc
        descriptor.fragmentFunction = fragmentFunc
        
        let vertexDescriptor = MTLVertexDescriptor()
        // position
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // texcoord
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0
        // color
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[2].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        descriptor.vertexDescriptor = vertexDescriptor
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("Error creating pipeline: \(error)")
        }
    }
    
    /// Build a vertex buffer for a given string
    public func buildTextVertices(string: String, x: Float, y: Float, color: SIMD4<Float>) -> (MTLBuffer?, Int) {
        
        var vertices: [Float] = []
        var penX = x
        let penY = y
        
        for ch in string {
            guard let g = atlas.glyphs[ch] else { continue }
            
            let x0 = penX + g.xOffset
            let y0 = penY + g.yOffset - g.height
            let x1 = x0 + g.width
            let y1 = y0 + g.height
            
            // short-names
            let u0 = g.uMin
            let v0 = g.vMin
            let u1 = g.uMax
            let v1 = g.vMax
            
            // Tri #1
            vertices.append(contentsOf: [ x0, y0, u0, v0, color.x, color.y, color.z, color.w ])
            vertices.append(contentsOf: [ x1, y0, u1, v0, color.x, color.y, color.z, color.w ])
            vertices.append(contentsOf: [ x0, y1, u0, v1, color.x, color.y, color.z, color.w ])
            
            // Tri #2
            vertices.append(contentsOf: [ x1, y0, u1, v0, color.x, color.y, color.z, color.w ])
            vertices.append(contentsOf: [ x1, y1, u1, v1, color.x, color.y, color.z, color.w ])
            vertices.append(contentsOf: [ x0, y1, u0, v1, color.x, color.y, color.z, color.w ])
            
            penX += g.xAdvance
        }
        
        if vertices.isEmpty { return (nil, 0) }
        
        let length = vertices.count * MemoryLayout<Float>.size
        guard let buffer = device.makeBuffer(bytes: vertices, length: length, options: .storageModeShared) else {
            return (nil, 0)
        }
        
        let count = vertices.count / 8
        return (buffer, count)
    }
    
    public func drawText(encoder: MTLRenderCommandEncoder,
                         vertexBuffer: MTLBuffer,
                         vertexCount: Int,
                         transformBuffer: MTLBuffer? = nil)
    {
        guard let pipelineState = pipelineState else { return }
        
        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        if let transformBuffer = transformBuffer {
            encoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        }
        
        encoder.setFragmentTexture(atlas.texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
