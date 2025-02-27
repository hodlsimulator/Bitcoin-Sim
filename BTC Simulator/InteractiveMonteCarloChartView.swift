//
//  InteractiveMonteCarloChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import SwiftUI
import MetalKit
import simd

struct InteractiveMonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings

    @State private var metalChart = MetalChartRenderer()
    
    // Gesture states for pinch and pan
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureTranslation: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                MTKViewWrapper(metalChart: metalChart)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onAppear {
                        metalChart.viewportSize = geo.size
                        metalChart.setupMetal(
                            in: geo.size,
                            chartDataCache: chartDataCache,
                            simSettings: simSettings
                        )
                    }
                    .onChange(of: geo.size) { _, newSize in
                        metalChart.viewportSize = newSize
                        metalChart.updateViewport(to: newSize)
                    }
                    .gesture(combinedGesture(geoSize: geo.size))
            }
        }
    }
    
    func combinedGesture(geoSize: CGSize) -> some Gesture {
        // Pinch gesture updates the scale factor.
        let pinch = MagnificationGesture()
            .updating($gestureScale) { current, state, _ in
                state = current
            }
            .onEnded { finalScale in
                // Update the GPU transform matrix
                metalChart.scale *= Float(finalScale)
                metalChart.updateTransform()
            }
        
        // Drag gesture updates the translation.
        let drag = DragGesture()
            .updating($gestureTranslation) { current, state, _ in
                state = current.translation
            }
            .onEnded { final in
                // Convert drag (in points) to normalized device translation:
                let dx = Float(final.translation.width) / Float(geoSize.width) * 2.0
                let dy = Float(final.translation.height) / Float(geoSize.height) * 2.0
                // Note: Screen Y is inverted relative to Metal's NDC
                metalChart.translation.x += dx
                metalChart.translation.y -= dy
                metalChart.updateTransform()
            }
        
        return SimultaneousGesture(pinch, drag)
    }
}

// MARK: - Metal Renderer with GPU Transform

class MetalChartRenderer: NSObject, MTKViewDelegate, ObservableObject {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    // Static vertex data: built once from the full data range.
    // (We assume that all vertex positions are computed using the full domain.)
    
    // GPU-side transform properties
    var viewportSize: CGSize = .zero
    var scale: Float = 1.0
    var translation = SIMD2<Float>(0, 0)
    var transformBuffer: MTLBuffer?
    
    // We'll build the vertex buffer once.
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
        
        vertexDescriptor.attributes[1].format = .float4 // color
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
        
        // Build the static vertex buffer using full data.
        buildLineBuffer()
        
        // Create the transform uniform buffer.
        transformBuffer = device.makeBuffer(length: MemoryLayout<matrix_float4x4>.size, options: .storageModeShared)
        updateTransform()
    }
    
    // Build the vertex buffer only once from full data.
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else { return }
        
        let simulations = cache.allRuns ?? []
        let (vertexData, lineSizes) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: 0.0,
            xMax: (simSettings.periodUnit == .weeks) ? Double(simSettings.userPeriods)/52.0 : Double(simSettings.userPeriods)/12.0,
            yMin: 1.0,
            yMax: 1000000000000.0,
            customPalette: customPalette,
            chartDataCache: cache
        )
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: byteCount, options: .storageModeShared)
        self.lineSizes = lineSizes
    }
    
    // Update the transformation matrix uniform based on scale and translation.
    func updateTransform() {
        // Build an orthographic projection matrix in NDC.
        // Our vertex data is already in [-1, 1] space.
        // We simply apply a scale and translation.
        let scaleMatrix = matrix_float4x4(diagonal: SIMD4<Float>(scale, scale, 1, 1))
        let translationMatrix = matrix_float4x4(columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, 0, 1)
        ))
        let transform = matrix_multiply(translationMatrix, scaleMatrix)
        // Write transform to the buffer.
        let bufferPointer = transformBuffer?.contents().bindMemory(to: matrix_float4x4.self, capacity: 1)
        bufferPointer?.pointee = transform
    }
    
    func updateViewport(to size: CGSize) {
        viewportSize = size
        print(">> updateViewport() - new size: \(size)")
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
        // Pass the transform uniform at buffer index 1.
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

// MARK: - Building the Vertex Data

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
    let bestFitId = chartDataCache.bestFitRun?.first?.id
    
    for (runIndex, sim) in simulations.enumerated() {
        let isBestFit = (sim.id == bestFitId)
        var chosenColor: Color = isBestFit ? .orange : customPalette[runIndex % customPalette.count]
        var chosenOpacity: Float = isBestFit ? 1.0 : 0.2
        let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
        
        var vertexCount = 0
        for pt in sim.points {
            let rawX = convertPeriodToYears(pt.week, simSettings)
            let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
            // Normalize using full domain for static data.
            let ratioX = (rawX - xMin) / (xMax - xMin)
            let nx = Float(ratioX * 2.0 - 1.0)
            
            let logVal = log10(rawY)
            let logMin = log10(yMin)
            let logMax = log10(yMax)
            let ratioY = (logVal - logMin) / (logMax - logMin)
            let ny = Float(ratioY * 2.0 - 1.0)
            
            vertexData.append(nx)
            vertexData.append(ny)
            vertexData.append(0.0)
            vertexData.append(1.0)
            
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

// MARK: - Helpers

let customPalette: [Color] = [
    .white, .yellow, .red, .blue, .green
]

func colorToFloats(_ swiftColor: Color, opacity: Double) -> (Float, Float, Float, Float) {
    let uiColor = UIColor(swiftColor)
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    alpha *= CGFloat(opacity)
    return (Float(red), Float(green), Float(blue), Float(alpha))
}

func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
    return simSettings.periodUnit == .weeks ? Double(week) / 52.0 : Double(week) / 12.0
}

// MARK: - Wrapper for the MTKView

struct MTKViewWrapper: UIViewRepresentable {
    let metalChart: MetalChartRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = metalChart.device ?? MTLCreateSystemDefaultDevice()
        mtkView.delegate = metalChart
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.sampleCount = 4  // For MSAA
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) { }
}
