//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based version
//

import Foundation
import MetalKit
import simd
import SwiftUI

// 1) Struct for the uniform buffer (placed at top of file or inside class – either is fine)
struct TransformUniform {
    var transformMatrix: matrix_float4x4
}

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    
    // MARK: - Domain & Transform
    // For a strictly forward-looking chart, domainMinX=0 so we never show negative X.
    // domainMaxX, domainMinY, domainMaxY come from data.
    var domainMinX: Float = 0
    var domainMaxX: Float = 1
    var domainMinY: Float = 0
    var domainMaxY: Float = 1000
    
    // Offsets in domain space
    var offsetX: Float = 0
    var offsetY: Float = 0
    
    // Single scale factor controlling zoom on both axes.
    var chartScale: Float = 1.0
    
    // The orthographic projection matrix
    private var projectionMatrix = matrix_float4x4(1.0)

    // MARK: - Metal
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    // We'll store the projection matrix in a small uniform buffer
    private var uniformBuffer: MTLBuffer?
    
    // If you have text rendering
    var textRendererManager: TextRendererManager?
    
    // For lines
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    
    // The size of the MTKView in points
    var viewportSize: CGSize = .zero
    
    // The local data or chart cache
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?

    // For debugging or reference
    private var chartHasLoaded = false
    
    // MARK: - Setup
    
    func setupMetal(in size: CGSize,
                    chartDataCache: ChartDataCache,
                    simSettings: SimulationSettings) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        // domainMinX = 0 if strictly forward.
        // domainMaxX, domainMinY, domainMaxY extracted from data in buildLineBuffer() below.
        
        // 1) Create Metal device & commandQueue
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported on this machine.")
            return
        }
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        
        // 2) Load default library
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library.")
            return
        }
        
        // 3) Optionally set up text rendering
        textRendererManager = TextRendererManager()
        textRendererManager?.generateFontAtlasAndRenderer(device: device)
        
        // 4) Create pipeline state
        let vertexFunction   = library.makeFunction(name: "orthographicVertex")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        // Position
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        // Colour
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable alpha blending if desired
        pipelineDesc.colorAttachments[0].isBlendingEnabled = true
        pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // Possibly enable MSAA
        pipelineDesc.rasterSampleCount = 4
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            print("Error creating pipeline state: \(error)")
        }
        
        // 5) Create uniform buffer for projection matrix
        //    Use 'MemoryLayout<TransformUniform>.size' to match the struct
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<TransformUniform>.size,
            options: .storageModeShared
        )
        
        // 6) Build line buffer from data
        buildLineBuffer()
        
        // 7) Set initial offset/scale so x=0 is at the left, etc.
        offsetX = 0
        offsetY = 0
        chartScale = 1.0
        
        // 8) Update orthographic matrix
        viewportSize = size
        updateOrthographic()
    }
    
    // MARK: - Build data => domain coords
    
    /// Reads the chart data, finds min/max X/Y, and creates a buffer of domain coordinates + color
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else {
            print("No chartDataCache or simSettings, cannot build lines.")
            return
        }
        
        var allXVals: [Double] = []
        var allYVals: [Double] = []
        
        let simulations = cache.allRuns ?? []
        for run in simulations {
            for pt in run.points {
                let xVal = convertPeriodToYears(pt.week, simSettings)
                allXVals.append(xVal)
                
                // If your data can’t be negative, clamp to a small positive number:
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                allYVals.append(rawY)
            }
        }
        
        guard let minX = allXVals.min(),
              let maxX = allXVals.max(),
              let rawMinY = allYVals.min(),
              let rawMaxY = allYVals.max() else {
            print("No data => skipping line build.")
            return
        }
        
        // Domain: [0..]
        // If minX is negative or small, clamp to 0
        let finalMinX = max(0.0, minX)
        
        // Y in log space => domainMinY=log10(rawMinY), domainMaxY=log10(rawMaxY)
        let logMinY = log10(rawMinY)
        let logMaxY = log10(rawMaxY)
        
        self.domainMinX = Float(finalMinX)
        self.domainMaxX = Float(maxX)
        self.domainMinY = Float(logMinY)
        self.domainMaxY = Float(logMaxY)
        
        var vertexData: [Float] = []
        var lineCounts: [Int] = []
        
        let bestFitId = cache.bestFitRun?.first?.id
        
        for (runIndex, sim) in simulations.enumerated() {
            let isBestFit = (sim.id == bestFitId)
            let chosenColor: Color = isBestFit ? .orange : customPalette[runIndex % customPalette.count]
            let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
            
            let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
            
            var vertexCount = 0
            for pt in sim.points {
                let rawX = convertPeriodToYears(pt.week, simSettings)
                let floatX = Float(rawX)
                
                // clamp to 1e-9 before log
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                let logY = Float(log10(rawY))
                
                // domain coords => x= floatX, y= logY
                vertexData.append(floatX)
                vertexData.append(logY)
                vertexData.append(0.0)
                vertexData.append(1.0)
                
                // RGBA
                vertexData.append(r)
                vertexData.append(g)
                vertexData.append(b)
                vertexData.append(a)
                
                vertexCount += 1
            }
            lineCounts.append(vertexCount)
        }
        
        self.lineSizes = lineCounts
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: byteCount,
            options: .storageModeShared
        )
        
        print("Created line buffer with \(vertexData.count) floats for log-scale Y coords.")
    }
    
    let customPalette: [Color] = [
        .white,
        .yellow,
        .red,
        .blue,
        .green
    ]
    
    func colorToFloats(_ c: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let ui = UIColor(c)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        aa *= CGFloat(opacity)
        return (Float(rr), Float(gg), Float(bb), Float(aa))
    }
    
    // Convert from e.g. week => years, if needed
    func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
        if simSettings.periodUnit == .weeks {
            return Double(week) / 52.0
        } else {
            // if months
            return Double(week) / 12.0
        }
    }
    
    // MARK: - Orthographic updates
    
    /// Rebuild the orthographic matrix from offsetX..offsetX+visibleWidth, etc.
    func updateOrthographic() {
        let domainWidth  = domainMaxX - domainMinX
        let domainHeight = domainMaxY - domainMinY
        
        let visibleWidth  = domainWidth  / chartScale
        let visibleHeight = domainHeight / chartScale
        
        let left   = offsetX
        let right  = offsetX + visibleWidth
        let bottom = offsetY
        let top    = offsetY + visibleHeight
        
        // near/far for 2D
        let near: Float = 0
        let far:  Float = 1
        
        projectionMatrix = makeOrthographicMatrix(left: left,
                                                  right: right,
                                                  bottom: bottom,
                                                  top: top,
                                                  near: near,
                                                  far: far)
        
        // 9) Store it in uniformBuffer
        if let ptr = uniformBuffer?.contents().bindMemory(to: matrix_float4x4.self, capacity: 1) {
            ptr.pointee = projectionMatrix
        }
    }
    
    /// A classic 2D orthographic matrix
    func makeOrthographicMatrix(left: Float,
                                right: Float,
                                bottom: Float,
                                top: Float,
                                near: Float,
                                far: Float) -> matrix_float4x4 {
        let rml = right - left
        let tmb = top - bottom
        let fmn = far - near
        
        // scale
        let sx =  2.0 / rml
        let sy =  2.0 / tmb
        let sz =  1.0 / fmn
        
        // translation
        let tx = -(right + left) / rml
        let ty = -(top + bottom) / tmb
        let tz = -near / fmn
        
        return matrix_float4x4(columns: (
            SIMD4<Float>( sx,  0,  0,  0),
            SIMD4<Float>( 0,  sy,  0,  0),
            SIMD4<Float>( 0,   0,  sz,  0),
            SIMD4<Float>( tx,  ty, tz,  1)
        ))
    }
    
    // MARK: - MTKViewDelegate
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // If you need to handle auto resizing
        let newSize = view.bounds.size
        viewportSize = newSize
        // We typically keep the same domain offset/scale,
        // just re-calling updateOrthographic() might suffice
        updateOrthographic()
    }
    
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        renderEncoder?.setRenderPipelineState(pipelineState)
        
        // Provide the line buffer
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Provide the uniform buffer (matrix)
        if let ubuf = uniformBuffer {
            renderEncoder?.setVertexBuffer(ubuf, offset: 0, index: 1)
        }
        
        // Draw each line
        var startIndex = 0
        for count in lineSizes {
            renderEncoder?.drawPrimitives(type: .lineStrip,
                                          vertexStart: startIndex,
                                          vertexCount: count)
            startIndex += count
        }
        
        renderEncoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // Example usage for pinch anchor: convert a screen point to domain coords
    func screenToDomain(_ screenPoint: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let domainWidth  = domainMaxX - domainMinX
        let visibleWidth = domainWidth / chartScale
        
        let fracX = Float(screenPoint.x) / Float(viewSize.width)
        let domainX = offsetX + fracX * visibleWidth
        
        let domainHeight = domainMaxY - domainMinY
        let visibleHeight = domainHeight / chartScale
        
        let fracY = 1.0 - (Float(screenPoint.y) / Float(viewSize.height))
        let domainY = offsetY + fracY * visibleHeight
        
        return SIMD2<Float>(domainX, domainY)
    }
}
