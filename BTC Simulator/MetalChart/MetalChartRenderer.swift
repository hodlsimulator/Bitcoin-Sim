//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based version with pinned axes pass
//

import Foundation
import MetalKit
import simd
import SwiftUI

// 1) Uniform struct
struct TransformUniform {
    var transformMatrix: matrix_float4x4
}

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    
    // MARK: - Domain & Transform
    var domainMinX: Float = 0
    var domainMaxX: Float = 1
    var domainMinY: Float = 0
    var domainMaxY: Float = 1000
    
    // Offsets in domain space
    var offsetX: Float = 0
    var offsetY: Float = 0
    
    // Single scale factor for both axes
    var chartScale: Float = 1.0
    
    // Orthographic matrix
    private var projectionMatrix = matrix_float4x4(1.0)

    // MARK: - Metal
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    private var uniformBuffer: MTLBuffer?
    
    // For text rendering (optional)
    var textRendererManager: TextRendererManager?
    
    // The line buffer
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    
    // The size of the MTKView in points
    var viewportSize: CGSize = .zero
    
    // For data
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?

    // (Optional) pinned axes
    var pinnedAxesRenderer: PinnedAxesRenderer?
    
    // Debug/tracking
    private var chartHasLoaded = false
    
    // MARK: - Setup
    
    func setupMetal(in size: CGSize,
                    chartDataCache: ChartDataCache,
                    simSettings: SimulationSettings) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal not supported on this machine.")
            return
        }
        self.device = device
        commandQueue = device.makeCommandQueue()
        
        guard let library = device.makeDefaultLibrary() else {
            print("Failed to create default library.")
            return
        }
        
        // Optionally set up text rendering
        textRendererManager = TextRendererManager()
        textRendererManager?.generateFontAtlasAndRenderer(device: device)
        
        // 1) Create the main chart pipeline (orthographicVertex -> fragmentShader)
        let vertexFunction   = library.makeFunction(name: "orthographicVertex")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // color
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        
        let pipelineDesc = MTLRenderPipelineDescriptor()
        pipelineDesc.vertexFunction = vertexFunction
        pipelineDesc.fragmentFunction = fragmentFunction
        pipelineDesc.vertexDescriptor = vertexDescriptor
        pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineDesc.rasterSampleCount = 4
        
        // blending
        pipelineDesc.colorAttachments[0].isBlendingEnabled = true
        pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            print("Error creating pipeline state: \(error)")
        }
        
        // 2) Uniform buffer
        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<TransformUniform>.size,
            options: .storageModeShared
        )
        
        // 3) Build the lines in log space
        buildLineBuffer()
        
        // 4) init transforms
        offsetX = 0
        offsetY = 0
        chartScale = 1.0
        
        viewportSize = size
        updateOrthographic()
        
        // 5) Create pinned axes renderer (if you want axes)
        //    Provide the same device & library you used above, plus any textRenderer:
        if let textRenderer = textRendererManager?.getTextRenderer() {
            pinnedAxesRenderer = PinnedAxesRenderer(
                device: device,
                textRenderer: textRenderer,
                textRendererManager: textRendererManager!,
                library: library
            )
            
            // Example: Pin the axis at x=50
            pinnedAxesRenderer?.pinnedAxisX = 50
        } else {
            print("No textRenderer => pinned axes won't show text.")
        }
    }
    
    // MARK: - Build Data in Log Space
    
    func buildLineBuffer() {
        guard let cache = chartDataCache, let simSettings = simSettings else {
            print("No chartDataCache or simSettings => skipping")
            return
        }
        
        var allXVals: [Double] = []
        var allYVals: [Double] = []
        
        let simulations = cache.allRuns ?? []
        for run in simulations {
            for pt in run.points {
                let xVal = convertPeriodToYears(pt.week, simSettings)
                allXVals.append(xVal)
                
                // clamp to 1e-9
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
        
        let finalMinX = max(0.0, minX)
        let logMinY = log10(rawMinY)
        let logMaxY = log10(rawMaxY)
        
        domainMinX = Float(finalMinX)
        domainMaxX = Float(maxX)
        domainMinY = Float(logMinY)
        domainMaxY = Float(logMaxY)
        
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
                let rawX = Float(convertPeriodToYears(pt.week, simSettings))
                let rawY = max(1e-9, NSDecimalNumber(decimal: pt.value).doubleValue)
                let logY = Float(log10(rawY))
                
                vertexData.append(rawX)
                vertexData.append(logY)
                vertexData.append(0)
                vertexData.append(1)
                
                vertexData.append(r)
                vertexData.append(g)
                vertexData.append(b)
                vertexData.append(a)
                
                vertexCount += 1
            }
            lineCounts.append(vertexCount)
        }
        
        lineSizes = lineCounts
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: byteCount,
                                         options: .storageModeShared)
        
        print("Created line buffer with \(vertexData.count) floats. Y is log scale.")
    }
    
    let customPalette: [Color] = [.white, .yellow, .red, .blue, .green]
    
    func colorToFloats(_ c: Color, opacity: Double) -> (Float, Float, Float, Float) {
        let ui = UIColor(c)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        aa *= CGFloat(opacity)
        return (Float(rr), Float(gg), Float(bb), Float(aa))
    }
    
    func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
        if simSettings.periodUnit == .weeks {
            return Double(week) / 52.0
        } else {
            return Double(week) / 12.0
        }
    }
    
    // MARK: - Orthographic
    
    func updateOrthographic() {
        let domainWidth  = domainMaxX - domainMinX
        let domainHeight = domainMaxY - domainMinY
        
        let visibleWidth  = domainWidth  / chartScale
        let visibleHeight = domainHeight / chartScale
        
        let left   = offsetX
        let right  = offsetX + visibleWidth
        let bottom = offsetY
        let top    = offsetY + visibleHeight
        
        // For debugging, print domain & transform details
        print("DEBUG [updateOrthographic]:")
        print("  domainMinX=\(domainMinX), domainMaxX=\(domainMaxX), domainMinY=\(domainMinY), domainMaxY=\(domainMaxY)")
        print("  offsetX=\(offsetX), offsetY=\(offsetY), chartScale=\(chartScale)")
        print("  => orthographic left=\(left), right=\(right), bottom=\(bottom), top=\(top)")
        
        // Build the projection matrix
        let near: Float = 0
        let far:  Float = 1
        
        projectionMatrix = makeOrthographicMatrix(left: left,
                                                  right: right,
                                                  bottom: bottom,
                                                  top: top,
                                                  near: near,
                                                  far: far)
        
        // Store it in the uniform buffer
        if let ptr = uniformBuffer?.contents().bindMemory(to: matrix_float4x4.self, capacity: 1) {
            ptr.pointee = projectionMatrix
        }
    }
    
    func makeOrthographicMatrix(left: Float, right: Float,
                                bottom: Float, top: Float,
                                near: Float,   far: Float) -> matrix_float4x4 {
        let rml = right - left
        let tmb = top - bottom
        let fmn = far - near
        
        let sx = 2.0 / rml
        let sy = 2.0 / tmb
        let sz = 1.0 / fmn
        
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
        let newSize = view.bounds.size
        viewportSize = newSize
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

        // One pass, one encoder
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        
        // 1) Chart lines
        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder?.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
        var startIndex = 0
        for count in lineSizes {
            encoder?.drawPrimitives(type: .lineStrip,
                                    vertexStart: startIndex,
                                    vertexCount: count)
            startIndex += count
        }
        
        // 2) pinnedAxes
        if let pinnedAxes = pinnedAxesRenderer {
            // Must set the pinned axis pipeline
            if let axisPipeline = pinnedAxes.axisPipelineState {
                encoder?.setRenderPipelineState(axisPipeline)
            }
            
            pinnedAxes.viewportSize = view.bounds.size
            pinnedAxes.updateAxes(
                minX: domainMinX,
                maxX: domainMaxX,
                minY: domainMinY,
                maxY: domainMaxY,
                chartTransform: projectionMatrix
            )
            pinnedAxes.drawAxes(renderEncoder: encoder!)
        }

        // end
        encoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    // Convert a screen point to domain coords for pinch anchors, etc.
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
