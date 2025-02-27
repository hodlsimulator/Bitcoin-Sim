//
//  InteractiveMonteCarloChartView.swift
//  BTCMonteCarlo
//
//  Created by Conor on ...
//

import SwiftUI
import MetalKit

struct InteractiveMonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    // The Metal renderer (no old SwiftUI Chart code)
    @State private var metalChart = MetalChartRenderer()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // The MTKView wrapped in SwiftUI
                MTKViewWrapper(metalChart: metalChart)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onAppear {
                        // Pass in size & chartDataCache so we can load the data
                        metalChart.setupMetal(in: geo.size, chartDataCache: chartDataCache)
                    }
                    .onChange(of: geo.size) { newSize in
                        metalChart.updateViewport(to: newSize)
                    }
            }
        }
    }
}

// MARK: - MetalChartRenderer

class MetalChartRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    // Data from your environment object
    var simulationData: [SimulationRun] = []
    var chartDataCache: ChartDataCache?   // So we can grab the data
    
    func setupMetal(in size: CGSize, chartDataCache: ChartDataCache) {
        self.chartDataCache = chartDataCache

        device = MTLCreateSystemDefaultDevice()
        guard let device = device else {
            print("Metal not supported on this machine.")
            return
        }

        commandQueue = device.makeCommandQueue()

        // Load the default library (with your vertexShader & fragmentShader)
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")

        // 1) Create the MTLVertexDescriptor
        let vertexDescriptor = MTLVertexDescriptor()

        // Attribute 0 => position (float4)
        vertexDescriptor.attributes[0].format = .float4   // 4 floats = float4
        vertexDescriptor.attributes[0].offset = 0         // starts at offset 0 in the struct
        vertexDescriptor.attributes[0].bufferIndex = 0    // buffer slot 0

        // Attribute 1 => color (float4)
        vertexDescriptor.attributes[1].format = .float4
        // The color starts after the position in memory:
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0

        // Layout for buffer 0 => stride = size of position + color
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // 2) Create the pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        // 3) Assign the vertex descriptor
        pipelineDescriptor.vertexDescriptor = vertexDescriptor

        // 4) Make the pipeline state
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }

        // Now load the simulation data
        loadSimulationData()
    }
    
    func loadSimulationData() {
        simulationData = chartDataCache?.allRuns ?? []
    }
    
    func updateViewport(to size: CGSize) {
        // Handle resizing or recalc if needed
    }
    
    // MARK: MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Called when the drawable size changes
    }
    
    func draw(in view: MTKView) {
        guard
            let pipelineState = pipelineState,    // ensure not nil
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else { return }

        renderEncoder.setRenderPipelineState(pipelineState)

        // ...
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - MTKViewWrapper

struct MTKViewWrapper: UIViewRepresentable {
    let metalChart: MetalChartRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = metalChart.device ?? MTLCreateSystemDefaultDevice()
        mtkView.delegate = metalChart
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1) // black background
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // If SwiftUI changes -> trigger updates here
    }
}
