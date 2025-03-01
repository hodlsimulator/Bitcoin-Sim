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
    
    // Provide or read the same idleManager from environment here
    // @EnvironmentObject var idleManager: IdleManager

    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isMetalChartReady {
                    MetalChartContainerView(metalChart: metalChart)
                        // .environmentObject(idleManager) // <– pass it down
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
                    Text("Loading chart...")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            // Initialize setupMetal and then mark as ready
            DispatchQueue.main.async {
                metalChart.setupMetal(
                    in: CGSize(width: 100, height: 100),
                    chartDataCache: chartDataCache,
                    simSettings: simSettings
                )
                isMetalChartReady = true
            }
        }
    }
}
