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
                    MetalChartContainerView(metalChart: metalChart)
                        .environmentObject(idleManager)
                        .onChange(of: geo.size) { _, newSize in
                            metalChart.viewportSize = newSize
                            metalChart.updateViewport(to: newSize)
                        }
                } else {
                    Text("Loading chart...")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                idleManager.resetIdleTimer()
                
                DispatchQueue.main.async {
                    metalChart.viewportSize = geo.size
                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings
                    )
                    isMetalChartReady = true
                }
            }
        }
        // Remove NavigationView here, but keep just the title:
        .navigationTitle("Bitcoin Price")
    }
}
