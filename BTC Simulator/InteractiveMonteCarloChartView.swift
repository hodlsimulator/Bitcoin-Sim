//
//  InteractiveMonteCarloChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
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
                        print(">> onAppear() - Setting up Metal")
                        metalChart.setupMetal(
                            in: geo.size,
                            chartDataCache: chartDataCache,
                            simSettings: simSettings
                        )
                    }
                    // iOS 17 approach: (oldValue, newValue)
                    .onChange(of: geo.size) { oldSize, newSize in
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
    
    var vertexBuffer: MTLBuffer?
    var lineSizes: [Int] = []
    
    var chartDataCache: ChartDataCache?
    var simSettings: SimulationSettings?
    
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
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        vertexDescriptor.attributes[1].format = .float4
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
        
        // Enable alpha blending:
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print(">> Pipeline state created successfully.")
        } catch {
            print("Error creating pipeline state: \(error)")
            pipelineState = nil
        }
        
        // 4) Prepare the domain
        setupDomainValues()
        
        // 5) Build the GPU buffer
        buildLineBuffer()
    }
    
    func buildLineBuffer() {
        guard let cache = chartDataCache,
              let simSettings = simSettings else {
            print(">> buildLineBuffer() - No chartDataCache or simSettings.")
            return
        }
        
        let simulations = cache.allRuns ?? []
        print(">> buildLineBuffer() - simulations.count = \(simulations.count)")
        
        if simulations.isEmpty {
            print(">> Warning: No simulations => No data to draw => Black screen likely.")
        }
        
        // Create vertex data
        let (vertexData, lineSizes) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            domainMin: domainMin,
            domainMax: domainMax,
            totalYears: totalYears,
            customPalette: customPalette,
            chartDataCache: cache
        )
        
        print(">> buildLineBuffer() - vertexData.count = \(vertexData.count), lineSizes.count = \(lineSizes.count)")
        
        if vertexData.isEmpty {
            print(">> Warning: Vertex data is empty => No lines will be drawn.")
        }
        
        // Make buffer
        let byteCount = vertexData.count * MemoryLayout<Float>.size
        if byteCount > 0 {
            vertexBuffer = device.makeBuffer(bytes: vertexData,
                                             length: byteCount,
                                             options: .storageModeShared)
            print(">> buildLineBuffer() - vertexBuffer created, length = \(byteCount)")
        } else {
            vertexBuffer = nil
            print(">> buildLineBuffer() - vertexBuffer is nil (no data).")
        }
        
        self.lineSizes = lineSizes
    }
    
    func setupDomainValues() {
        guard let cache = chartDataCache,
              let settings = simSettings else {
            print(">> setupDomainValues() - chartDataCache or simSettings is nil.")
            return
        }
        
        let simulations = cache.allRuns ?? []
        let allPoints = simulations.flatMap { $0.points }
        let decimalValues = allPoints.map { $0.value }
        
        if decimalValues.isEmpty {
            print(">> setupDomainValues() - No data points found.")
        }
        
        let minVal = decimalValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        let maxVal = decimalValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        // Log-scale domain logic
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
        
        let totalPeriods = Double(settings.userPeriods)
        let yrs = (settings.periodUnit == .weeks)
            ? totalPeriods / 52.0
            : totalPeriods / 12.0
        totalYears = (yrs < 1e-9) ? 1.0 : yrs
        
        print(">> setupDomainValues() - domainMin = \(domainMin), domainMax = \(domainMax), totalYears = \(totalYears)")
    }
    
    func updateViewport(to size: CGSize) {
        print(">> updateViewport() - new size: \(size)")
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print(">> drawableSizeWillChange() - new drawableSize: \(size)")
    }
    
    func draw(in view: MTKView) {
        guard let pipelineState = pipelineState else {
            print(">> draw() - pipelineState is nil => nothing to draw.")
            return
        }
        guard let drawable = view.currentDrawable else { return }
        guard let rpd = view.currentRenderPassDescriptor else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else { return }
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        if let vb = vertexBuffer {
            renderEncoder.setVertexBuffer(vb, offset: 0, index: 0)
            
            // Draw each line strip
            var offsetIndex = 0
            for (i, count) in lineSizes.enumerated() {
                if count == 0 {
                    print(">> draw() - lineSizes[\(i)] is 0 => skipping.")
                    continue
                }
                renderEncoder.drawPrimitives(type: .lineStrip,
                                             vertexStart: offsetIndex,
                                             vertexCount: count)
                offsetIndex += count
            }
        } else {
            print(">> draw() - vertexBuffer is nil => no data to draw.")
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
    domainMin: Double,
    domainMax: Double,
    totalYears: Double,
    customPalette: [Color],
    chartDataCache: ChartDataCache // only if you need to check bestFit
) -> ([Float], [Int]) {
    
    var vertexData: [Float] = []
    var lineSizes: [Int] = []
    
    // Grab the ID of your best-fit run, if it exists
    let bestFitId = chartDataCache.bestFitRun?.first?.id
    
    for (runIndex, sim) in simulations.enumerated() {
        // Check if this simulation is the best-fit
        let isBestFit = (sim.id == bestFitId)
        
        // Default to multi-colour from the palette
        var chosenColor = customPalette[runIndex % customPalette.count]
        var chosenOpacity: Float = 0.3
        
        if isBestFit {
            // Make best fit line orange & more opaque
            chosenColor = .orange
            chosenOpacity = 1.0
        }
        
        // Convert SwiftUI Color to RGBA floats
        let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
        
        var vertexCount = 0
        for pt in sim.points {
            let rawX = convertPeriodToYears(pt.week, simSettings)
            let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
            
            // Normalise X, Y
            let nx = normalizedX(rawX, totalYears: totalYears)
            let ny = normalizedYLog(rawY, domainMin: domainMin, domainMax: domainMax)
            
            // Position (x,y,z,w)
            vertexData.append(nx)
            vertexData.append(ny)
            vertexData.append(0.0)
            vertexData.append(1.0)
            
            // Colour (r,g,b,a)
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

func convertPeriodToYears(_ week: Int, _ simSettings: SimulationSettings) -> Double {
    if simSettings.periodUnit == .weeks {
        return Double(week) / 52.0
    } else {
        return Double(week) / 12.0
    }
}

func normalizedX(_ rawYear: Double, totalYears: Double) -> Float {
    let ratio = rawYear / totalYears
    return Float(ratio * 2.0 - 1.0)
}

func normalizedYLog(_ value: Double, domainMin: Double, domainMax: Double) -> Float {
    let valLog = log10(value)
    let minLog = log10(domainMin)
    let maxLog = log10(domainMax)
    
    guard maxLog > minLog else {
        return 0
    }
    let ratio = (valLog - minLog) / (maxLog - minLog)
    return Float(ratio * 2.0 - 1.0)
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
