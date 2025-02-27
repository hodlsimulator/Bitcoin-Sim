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
    
    var vertexBuffer: MTLBuffer?
    
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

        // Load shaders
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")

        // Create a vertex descriptor as before
        let vertexDescriptor = MTLVertexDescriptor()
        // position => attribute(0)
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // color => attribute(1)
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // layout => stride of 8 floats (32 bytes)
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 8
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        // Set up pipeline
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }

        // Example: a single triangle in Normalized Device Coordinates ([-1..1] range)
        // 3 vertices, each with position(x,y,z,w) and color(r,g,b,a)
        let vertices: [Float] = [
            // 1) vertex
             0.0,  0.5, 0.0, 1.0,   1.0, 0.0, 0.0, 1.0,
            // 2) vertex
            -0.5, -0.5, 0.0, 1.0,   0.0, 1.0, 0.0, 1.0,
            // 3) vertex
             0.5, -0.5, 0.0, 1.0,   0.0, 0.0, 1.0, 1.0
        ]
        
        // Create our MTLBuffer from the above array
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: vertices.count * MemoryLayout<Float>.size,
                                         options: .storageModeShared)
        
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
            let pipelineState = pipelineState,
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Bind our MTLBuffer to index 0 (matching 'bufferIndex = 0' in vertex descriptor)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // Draw 3 vertices => one triangle
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
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
