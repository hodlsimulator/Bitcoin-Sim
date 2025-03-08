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

/// This SwiftUI View hosts a UIKit-based Metal chart + gestures for Bitcoin.
struct InteractiveMonteCarloChartView: View {
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var idleManager: IdleManager
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    /// Closure that the parent will pass in, used to navigate to the Portfolio chart.
    let onSwitchToPortfolio: () -> Void

    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false
    @State private var showMenu = false  // Tracks whether the drop-down menu is visible

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
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

                // Our custom drop-down menu
                if showMenu {
                    VStack(spacing: 10) {
                        Button {
                            print("Portfolio button tapped")
                            onSwitchToPortfolio()
                            showMenu = false
                        } label: {
                            HStack {
                                Spacer()
                                Text("Portfolio")
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top))
                }
            }
            .onAppear {
                // Reset idle timer
                idleManager.resetIdleTimer()
                
                DispatchQueue.main.async {
                    // Provide size to the renderer
                    metalChart.viewportSize = geo.size

                    // Set up the BTC chart
                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings,
                        isPortfolioChart: false
                    )

                    // Build GPU buffers whenever data updates
                    coordinator.onChartDataUpdated = {
                        DispatchQueue.main.async {
                            self.metalChart.buildLineBuffers()
                        }
                    }
                    
                    isMetalChartReady = true
                }
            }
            .navigationBarTitle("Bitcoin Price", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showMenu.toggle()
                        }
                    } label: {
                        Image(systemName: showMenu ? "chevron.up" : "chevron.down")
                    }
                }
            }
        }
    }
}
