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
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Now Swift should resolve MetalChartContainer
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
            }
        }
    }
}
