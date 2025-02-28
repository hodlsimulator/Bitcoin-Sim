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
        descriptor.rasterSampleCount = 4

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2  // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.attributes[1].format = .float2  // texcoord
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
        vertexDescriptor.attributes[1].bufferIndex = 0

        vertexDescriptor.attributes[2].format = .float4  // color
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[2].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8  // 8 attributes per vertex (x, y, u, v, color)
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

            let u0 = g.uMin
            let v0 = g.vMin
            let u1 = g.uMax
            let v1 = g.vMax

            // Triangle #1
            vertices.append(contentsOf: [ x0, y0, u0, v0, color.x, color.y, color.z, color.w ])
            vertices.append(contentsOf: [ x1, y0, u1, v0, color.x, color.y, color.z, color.w ])
            vertices.append(contentsOf: [ x0, y1, u0, v1, color.x, color.y, color.z, color.w ])

            // Triangle #2
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

        let count = vertices.count / 8  // 8 attributes per vertex (position, texcoord, color)
        return (buffer, count)
    }

    public func drawText(encoder: MTLRenderCommandEncoder,
                         vertexBuffer: MTLBuffer,
                         vertexCount: Int,
                         transformBuffer: MTLBuffer? = nil) {
        guard let pipelineState = pipelineState else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        // Log the transform buffer size before setting it.
        if let transformBuffer = transformBuffer {
            print("Transform buffer size: \(transformBuffer.length) bytes")  // Should print 64 bytes for matrix_float4x4
            encoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)  // Buffer index 1 for transformation matrix
        } else {
            var identity = matrix_identity_float4x4
            let identityBuffer = device.makeBuffer(bytes: &identity,
                                                   length: MemoryLayout<matrix_float4x4>.size,
                                                   options: .storageModeShared)
            
            // Log the identity buffer size
            if let identityBuffer = identityBuffer {
                print("Identity buffer size: \(identityBuffer.length) bytes")  // Should print 64 bytes for matrix_float4x4
                encoder.setVertexBuffer(identityBuffer, offset: 0, index: 1)  // Buffer index 1
            } else {
                print("Failed to create identity buffer.")
            }
        }

        encoder.setFragmentTexture(atlas.texture, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
