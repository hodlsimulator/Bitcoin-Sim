//
//  MetalChartRenderer.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import MetalKit
import simd
import SwiftUI  // for Color

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    // Transform properties
    var viewportSize: CGSize = .zero
    var scale: Float = 1.0
    var translation = SIMD2<Float>(0, 0)
    var transformBuffer: MTLBuffer?
    
    func setupMetal(
        in size: CGSize,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        device = MTLCreateSystemDefaultDevice()
        guard let device = device else {
            print("Metal not supported on this machine.")
            return
        }
        commandQueue = device.makeCommandQueue()
        
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4 // position
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4 // colour
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // Enable blending
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        // Enable MSAA for smoother lines
        pipelineDescriptor.rasterSampleCount = 4
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print(">> Pipeline state created successfully.")
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }
        
        // Build the static vertex buffer using full data
        buildLineBuffer()
        
        // Create the transform uniform buffer
        transformBuffer = device.makeBuffer(
            length: MemoryLayout<matrix_float4x4>.size,
            options: .storageModeShared
        )
        updateTransform()
    }
    
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else { return }
        
        let simulations = cache.allRuns ?? []
        
        // Build the vertex data (positions + colours) for all lines
        let (vertexData, lineSizes) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: 0.0,
            xMax: (simSettings.periodUnit == .weeks)
                ? Double(simSettings.userPeriods) / 52.0
                : Double(simSettings.userPeriods) / 12.0,
            yMin: 1.0,                   // minimum Y
            yMax: 1_000_000_000_000.0,   // maximum Y
            customPalette: customPalette,
            chartDataCache: cache
        )
        
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(
            bytes: vertexData,
            length: byteCount,
            options: .storageModeShared
        )
        self.lineSizes = lineSizes
    }
    
    func updateTransform() {
        // The final transform is translation * scale
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        let transform = matrix_multiply(translationMatrix, scaleMatrix)
        
        let bufferPointer = transformBuffer?.contents().bindMemory(
            to: matrix_float4x4.self,
            capacity: 1
        )
        bufferPointer?.pointee = transform
    }
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
        print(">> updateViewport() - new size: \(size)")
    }
    
    /// Converts a screen point (UIKit coords) to normalised device coords [-1..1].
    func convertPointToNDC(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndx = Float(point.x / viewSize.width) * 2.0 - 1.0
        let ndy = Float((viewSize.height - point.y) / viewSize.height) * 2.0 - 1.0
        return SIMD2<Float>(ndx, ndy)
    }
    
    /// Returns the current transform matrix: (translation * scale).
    private func currentTransformMatrix() -> matrix_float4x4 {
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        return matrix_multiply(translationMatrix, scaleMatrix)
    }
    
    /// Converts a screen point to "data space" by:
    /// 1) Converting screen -> NDC.
    /// 2) Applying the inverse transform so we get data coords.
    func convertPointToData(_ point: CGPoint, viewSize: CGSize) -> SIMD2<Float> {
        let ndc = convertPointToNDC(point, viewSize: viewSize)
        let ndcVec = SIMD4<Float>(ndc.x, ndc.y, 0, 1)
        let inverseTransform = simd_inverse(currentTransformMatrix())
        let dataVec = matrix_multiply(inverseTransform, ndcVec)
        return SIMD2<Float>(dataVec.x, dataVec.y)
    }
    
    /// Converts a data-space coordinate back to screen coords:
    /// 1) Multiply by the forward transform to get NDC.
    /// 2) Map NDC to screen.
    func convertDataToPoint(_ dataCoord: SIMD2<Float>, viewSize: CGSize) -> CGPoint {
        let dataVec = SIMD4<Float>(dataCoord.x, dataCoord.y, 0, 1)
        let ndcVec = matrix_multiply(currentTransformMatrix(), dataVec)
        let xScreen = (ndcVec.x + 1) * 0.5 * Float(viewSize.width)
        let yScreen = (1 - (ndcVec.y + 1) * 0.5) * Float(viewSize.height)
        return CGPoint(x: CGFloat(xScreen), y: CGFloat(yScreen))
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print(">> drawableSizeWillChange() - new drawableSize: \(size)")
    }
    
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState,
              let drawable = view.currentDrawable,
              let rpd = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        if let transformBuffer = transformBuffer {
            renderEncoder.setVertexBuffer(transformBuffer, offset: 0, index: 1)
        }
        
        var offsetIndex = 0
        for count in lineSizes {
            renderEncoder.drawPrimitives(type: .lineStrip, vertexStart: offsetIndex, vertexCount: count)
            offsetIndex += count
        }
        
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Build Vertex Data

/// A palette used when building line data (change colours as desired).
let customPalette: [Color] = [
    .white,
    .yellow,
    .red,
    .blue,
    .green
]

/// Builds an array of float-based vertex data (positions + colours) and
/// an array of line segment sizes, one per simulation run.
func buildLineVertexData(
    simulations: [SimulationRun],
    simSettings: SimulationSettings,
    xMin: Double,
    xMax: Double,
    yMin: Double,
    yMax: Double,
    customPalette: [Color],
    chartDataCache: ChartDataCache
) -> ([Float], [Int]) {
    
    var vertexData: [Float] = []
    var lineSizes: [Int] = []
    
    // Optionally, handle a "best fit" run separately
    let bestFitId = chartDataCache.bestFitRun?.first?.id
    
    for (runIndex, sim) in simulations.enumerated() {
        let isBestFit = (sim.id == bestFitId)
        let chosenColor: Color = isBestFit ? .orange : customPalette[runIndex % customPalette.count]
        let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
        let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
        
        var vertexCount = 0
        for pt in sim.points {
            let rawX = convertPeriodToYears(pt.week, simSettings)
            let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
            
            // normalise X -> [-1..1]
            let ratioX = (rawX - xMin) / (xMax - xMin)
            let nx = Float(ratioX * 2.0 - 1.0)
            
            // normalise Y on a log scale -> [-1..1]
            let logVal = log10(rawY)
            let logMin = log10(yMin)
            let logMax = log10(yMax)
            let ratioY = (logVal - logMin) / (logMax - logMin)
            let ny = Float(ratioY * 2.0 - 1.0)
            
            // Position
            vertexData.append(nx)
            vertexData.append(ny)
            vertexData.append(0.0)
            vertexData.append(1.0)
            
            // Colour
            vertexData.append(r)
            vertexData.append(g)
            vertexData.append(b)
            vertexData.append(a)
            
            vertexCount += 1
        }
        lineSizes.append(vertexCount)
    }
    return (vertexData, lineSizes)
}

/// Converts SwiftUI Color to RGBA floats, factoring in 'opacity'.
func colorToFloats(_ swiftColor: Color, opacity: Double) -> (Float, Float, Float, Float) {
    let uiColor = UIColor(swiftColor)
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    alpha *= CGFloat(opacity)
    return (Float(red), Float(green), Float(blue), Float(alpha))
}

/// Converts a 'week' (or month) index to years, based on user settings.
func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
    if simSettings.periodUnit == .weeks {
        return Double(week) / 52.0
    } else {
        return Double(week) / 12.0
    }
}
