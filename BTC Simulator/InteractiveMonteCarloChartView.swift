//
//  InteractiveMonteCarloChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import SwiftUI
import UIKit
import MetalKit
import simd

/// This SwiftUI View hosts a UIKit-based Metal chart + gestures.
struct InteractiveMonteCarloChartView: View {
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var idleManager: IdleManager

    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                if isMetalChartReady {
                    // Once true, we show the container with a valid textRendererManager
                    MetalChartContainerView(metalChart: metalChart)
                        .environmentObject(idleManager)
                        .onChange(of: geo.size) { _, newSize in
                            // If the view size changes (e.g., device rotation),
                            // update the renderer’s viewport.
                            metalChart.viewportSize = newSize
                            metalChart.updateViewport(to: newSize)
                            // Optionally call `metalChart.anchorEdges()` here if needed.
                        }
                } else {
                    Text("Loading chart...")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                // Reset the IdleManager timer so it starts counting right when we enter this view
                idleManager.resetIdleTimer()
                
                DispatchQueue.main.async {
                    // 1) Provide the actual size to the renderer
                    metalChart.viewportSize = geo.size

                    // 2) Call setupMetal ONCE
                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings
                    )

                    // 3) Mark it ready; triggers the 'if isMetalChartReady' block
                    isMetalChartReady = true
                }
            }
        }
    }
}
