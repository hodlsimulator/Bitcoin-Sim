//
//  InteractivePortfolioChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 07/03/2025.
//

import SwiftUI
import UIKit
import MetalKit
import simd

/// A SwiftUI view that renders the Portfolio chart using Metal.
/// No orientation observer or snapshot logic needed.
struct InteractivePortfolioChartView: View {
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var idleManager: IdleManager

    // *** add coordinator here, too:
    @EnvironmentObject var coordinator: SimulationCoordinator   // ***
    
    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isMetalChartReady {
                    MetalChartContainerView(metalChart: metalChart)
                        .environmentObject(idleManager)
                        .onChange(of: geo.size) { _, newSize in
                            // If the view size changes (e.g. rotation),
                            // update the renderer’s viewport.
                            metalChart.viewportSize = newSize
                            metalChart.updateViewport(to: newSize)
                        }
                } else {
                    Text("Loading portfolio chart...")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                // Reset the IdleManager timer
                idleManager.resetIdleTimer()
                
                DispatchQueue.main.async {
                    // 1) Provide the actual size to the renderer
                    metalChart.viewportSize = geo.size

                    // 2) Call setupMetal ONCE, indicating "portfolio" data
                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings,
                        isPortfolioChart: true
                    )

                    // *** Tie simulationCoordinator updates => rebuild line buffers
                    coordinator.onChartDataUpdated = {
                        DispatchQueue.main.async {
                            self.metalChart.buildLineBuffers()
                        }
                    }

                    // 3) Mark it ready
                    isMetalChartReady = true
                }
            }
        }
        // Optional: put a title in the nav bar
        .navigationBarTitle("Portfolio Chart", displayMode: .inline)
    }
}
