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
    
    // We store the “base” scale/translation from previous gestures,
    // plus an anchor for pinch (approx midpoint of the two touch points).
    @State private var baseScale: Float = 1.0
    @State private var baseTranslation = SIMD2<Float>(0, 0)
    
    @State private var pinchAnchor: CGPoint = .zero
    
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
                    // Use SimultaneousGesture to track pinch (for scale) + drag (for anchor).
                    .gesture(
                        SimultaneousGesture(
                            pinchGesture(geoSize: geo.size),
                            dragGesture(geoSize: geo.size)
                        )
                    )
            }
        }
    }
    
    // MARK: - Pinch Gesture
    func pinchGesture(geoSize: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { currentMagnification in
                // currentMagnification is how much the user is pinching at this moment.
                // We'll interpret pinchAnchor as the "focus point" for the scaling.
                
                // The new scale is baseScale * current pinch factor.
                // Then we figure out how much we’ve changed from the old scale
                // so we can anchor around pinchAnchor in NDC.
                let oldScale = metalChart.scale
                let newScale = baseScale * Float(currentMagnification)
                let scaleRatio = newScale / oldScale
                
                // Convert pinchAnchor from view coords to Normalised Device Coords
                let anchorNDC = metalChart.convertPointToNDC(pinchAnchor, geoSize: geoSize)
                
                // Shift translation so that anchorNDC remains in the same place
                // while scaling around it.
                metalChart.translation.x -= anchorNDC.x * (scaleRatio - 1)
                metalChart.translation.y -= anchorNDC.y * (scaleRatio - 1)
                
                metalChart.scale = newScale
                metalChart.updateTransform()
            }
            .onEnded { finalMagnification in
                // Lock in the new base scale.
                baseScale *= Float(finalMagnification)
            }
    }
    
    // MARK: - Drag Gesture
    func dragGesture(geoSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { drag in
                // If user is pinching, this roughly tracks two-finger midpoint.
                // Even a one-finger drag also sets pinchAnchor,
                // so consider ignoring single-finger drags if you want.
                pinchAnchor = drag.location
                
                // For normal dragging (panning), we also want to move the chart.
                // The difference from baseTranslation is how far we drag in NDC.
                let dx = Float(drag.translation.width) / Float(geoSize.width) * 2.0
                let dy = Float(drag.translation.height) / Float(geoSize.height) * 2.0
                
                metalChart.translation.x = baseTranslation.x + dx
                metalChart.translation.y = baseTranslation.y - dy  // invert Y
                metalChart.updateTransform()
            }
            .onEnded { final in
                // Finalise the pan movement.
                let dx = Float(final.translation.width) / Float(geoSize.width) * 2.0
                let dy = Float(final.translation.height) / Float(geoSize.height) * 2.0
                baseTranslation.x += dx
                baseTranslation.y -= dy
            }
    }
}

// MARK: - Metal Renderer

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
        let (vertexData, lineSizes) = buildLineVertexData(
            simulations: simulations,
            simSettings: simSettings,
            xMin: 0.0,
            xMax: (simSettings.periodUnit == .weeks)
                ? Double(simSettings.userPeriods)/52.0
                : Double(simSettings.userPeriods)/12.0,
            yMin: 1.0,
            yMax: 1000000000000.0,
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
    
    // We need a helper to convert a tap/pinch location from view coords
    // to Normalised Device Coords ([-1,1] range in X/Y).
    func convertPointToNDC(_ point: CGPoint, geoSize: CGSize) -> SIMD2<Float> {
        let ndx = Float(point.x / geoSize.width) * 2.0 - 1.0
        // Flip y because in Metal’s NDC, +1 is top
        let ndy = Float((geoSize.height - point.y) / geoSize.height) * 2.0 - 1.0
        return SIMD2<Float>(ndx, ndy)
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
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd) else {
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
        let chosenColor: Color = isBestFit ? .orange : customPalette[runIndex % customPalette.count]
        let chosenOpacity: Float = isBestFit ? 1.0 : 0.2
        let (r, g, b, a) = colorToFloats(chosenColor, opacity: Double(chosenOpacity))
        
        var vertexCount = 0
        for pt in sim.points {
            let rawX = convertPeriodToYears(pt.week, simSettings)
            let rawY = NSDecimalNumber(decimal: pt.value).doubleValue
            
            let ratioX = (rawX - xMin) / (xMax - xMin)
            let nx = Float(ratioX * 2.0 - 1.0)
            
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
    if simSettings.periodUnit == .weeks {
        return Double(week) / 52.0
    } else {
        return Double(week) / 12.0
    }
}

// MARK: - Wrapper for the MTKView

struct MTKViewWrapper: UIViewRepresentable {
    let metalChart: MetalChartRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = metalChart.device ?? MTLCreateSystemDefaultDevice()
        mtkView.delegate = metalChart
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.preferredFramesPerSecond = 60
        mtkView.sampleCount = 4  // MSAA
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // No update needed
    }
}
