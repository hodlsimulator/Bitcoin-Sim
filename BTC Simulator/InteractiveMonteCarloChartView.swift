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
    
    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false // New state to track setup completion
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Only render MetalChartContainerView once textRendererManager is initialized
                if isMetalChartReady {
                    MetalChartContainerView(metalChart: metalChart)
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
                } else {
                    // Optionally show a loading indicator or some other view while waiting
                    Text("Loading chart...")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Initialize setupMetal and then mark as ready
            DispatchQueue.main.async {
                metalChart.setupMetal(
                    in: CGSize(width: 100, height: 100),  // Initial dummy size (will be updated)
                    chartDataCache: chartDataCache,
                    simSettings: simSettings
                )
                isMetalChartReady = true // Mark as ready after setup
            }
        }
    }
}
