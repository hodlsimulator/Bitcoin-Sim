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
    
    @State private var metalChart = MetalChartRenderer()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // The MTKView embedded in SwiftUI
                MTKViewWrapper(metalChart: metalChart)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onAppear {
                        // On first appear, set up the Metal pipeline
                        metalChart.setupMetal(in: geo.size,
                                              chartDataCache: chartDataCache,
                                              simSettings: simSettings)
                    }
                    .onChange(of: geo.size) { newSize in
                        // Update if orientation or size changes
                        metalChart.updateViewport(to: newSize)
                    }
            }
        }
    }
}

// MARK: - Metal Renderer

class MetalChartRenderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    
    // The GPU buffer with all lines from all runs
    var vertexBuffer: MTLBuffer?
    
    // For each run, how many vertices in its line strip?
    var lineSizes: [Int] = []
    
    // We'll keep references to the data
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
    // Domain for log scale
    var domainMin: Double = 1.0
    var domainMax: Double = 2.0
    var totalYears: Double = 1.0

    func setupMetal(
        in size: CGSize,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        
        // 1) Prepare the Metal device
        device = MTLCreateSystemDefaultDevice()
        guard let device = device else {
            print("Metal not supported on this machine.")
            return
        }
        
        commandQueue = device.makeCommandQueue()
        
        // 2) Load shaders
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        // 3) Create a vertex descriptor (position + color)
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
        
        // 4) Create the pipeline descriptor
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
        
        // 5) Prepare the domain
        setupDomainValues()
        
        // 6) Build the GPU buffer from simulation lines
        buildLineBuffer()
    }
    
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else { return }
        
        // 1) Grab all simulation runs
        let simulations = cache.allRuns ?? []
        
        // 2) Build vertex data (positions + colors for all runs)
        let (vertexData, lineSizes) = buildLineVertexData(simulations: simulations,
                                                          simSettings: simSettings,
                                                          domainMin: domainMin,
                                                          domainMax: domainMax,
                                                          totalYears: totalYears,
                                                          customPalette: customPalette)
        
        // 3) Create GPU buffer
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertexData,
                                         length: byteCount,
                                         options: .storageModeShared)
        
        // 4) Store line sizes so we know how many vertices per run
        self.lineSizes = lineSizes
    }
    
    /// Sets domainMin, domainMax, and totalYears from the data
    func setupDomainValues() {
        guard let cache = chartDataCache,
              let settings = simSettings else { return }
        
        let simulations = cache.allRuns ?? []
        let allPoints = simulations.flatMap { $0.points }
        let decimalValues = allPoints.map { $0.value }
        
        let minVal = decimalValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        let maxVal = decimalValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        // Replicate your old log-scale domain logic
        var bottomExp = floor(log10(minVal))
        if minVal <= pow(10, bottomExp), bottomExp > 0 {
            bottomExp -= 1
        }
        domainMin = max(pow(10.0, bottomExp), 1.0)
        
        var topExp = floor(log10(maxVal))
        if maxVal >= pow(10.0, topExp) {
            topExp += 1
        }
        domainMax = pow(10.0, topExp)
        
        // totalPeriods => totalYears
        let totalPeriods = Double(settings.userPeriods)
        let yrs = (settings.periodUnit == .weeks) ? totalPeriods / 52.0
                                                  : totalPeriods / 12.0
        totalYears = (yrs < 1e-9) ? 1.0 : yrs // just a safety fallback
    }
    
    func updateViewport(to size: CGSize) {
        // If you want to recalc transforms based on new size, do it here
    }
    
    // MARK: - MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Called if the view’s underlying drawable size changes
    }
    
    func draw(in view: MTKView) {
        guard
            let pipelineState = pipelineState,
            let drawable = view.currentDrawable,
            let rpd = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        else {
            return
        }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Bind the single buffer for position/color
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        // We'll draw each line strip.
        // lineSizes[i] = # of vertices in i-th run
        var offsetIndex = 0
        for count in lineSizes {
            renderEncoder.drawPrimitives(type: .lineStrip,
                                         vertexStart: offsetIndex,
                                         vertexCount: count)
            offsetIndex += count
        }
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Building the Vertex Data

/// Replaces your old `simulationLines` function.
/// Instead of returning ChartContent, we return raw float vertices + lineSizes.
func buildLineVertexData(
    simulations: [SimulationRun],
    simSettings: SimulationSettings,
    domainMin: Double,
    domainMax: Double,
    totalYears: Double,
    customPalette: [Color]
) -> ([Float], [Int]) {
    
    var vertexData: [Float] = []
    var lineSizes: [Int] = []
    
    for (runIndex, sim) in simulations.enumerated() {
        let colorSwift = customPalette[runIndex % customPalette.count]
        let (r, g, b, a) = colorToFloats(colorSwift, opacity: 0.3)
        
        var vertexCount = 0
        for pt in sim.points {
            let rawX = convertPeriodToYears(pt.week, simSettings)
            let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
            
            // -1..+1 in X
            let nx = normalizedX(rawX, totalYears: totalYears)
            // -1..+1 in Y after log transform
            let ny = normalizedYLog(rawY, domainMin: domainMin, domainMax: domainMax)
            
            // position (x,y,z,w)
            vertexData.append(nx)
            vertexData.append(ny)
            vertexData.append(0.0)
            vertexData.append(1.0)
            
            // color (r,g,b,a)
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
    // Copy your big palette from ChartBuilders.swift
    // Example subset:
    .white, .yellow, .red, .blue, .green,
    // etc...
]

func colorToFloats(_ swiftColor: Color, opacity: Double) -> (Float, Float, Float, Float) {
    let uiColor = UIColor(swiftColor)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    alpha *= CGFloat(opacity)
    
    return (Float(red), Float(green), Float(blue), Float(alpha))
}

/// Convert the `week` index to years,
/// just like `convertPeriodToYears(pt.week, simSettings)` in your old code
func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
    if simSettings.periodUnit == .weeks {
        return Double(week) / 52.0
    } else {
        return Double(week) / 12.0
    }
}

/// Normalise X from [0..totalYears] -> [-1..+1].
func normalizedX(_ rawYear: Double, totalYears: Double) -> Float {
    let ratio = rawYear / totalYears // 0..1
    return Float(ratio * 2.0 - 1.0) // -> -1..+1
}

/// Normalise Y in log scale from [domainMin..domainMax] -> [-1..+1].
func normalizedYLog(_ value: Double, domainMin: Double, domainMax: Double) -> Float {
    let valLog = log10(value)
    let minLog = log10(domainMin)
    let maxLog = log10(domainMax)
    let ratio = (valLog - minLog) / (maxLog - minLog)  // 0..1
    return Float(ratio * 2.0 - 1.0)                   // -> -1..+1
}

// MARK: - Wrapper for the MTKView

struct MTKViewWrapper: UIViewRepresentable {
    let metalChart: MetalChartRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = metalChart.device ?? MTLCreateSystemDefaultDevice()
        mtkView.delegate = metalChart
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // If SwiftUI state changes, handle if needed
    }
}
