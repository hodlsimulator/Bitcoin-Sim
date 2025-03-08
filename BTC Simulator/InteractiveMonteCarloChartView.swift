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
    
    // *** Hook up chart data updates
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false
    @State private var showMenu = false  // Tracks whether the drop-down menu is visible

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {  // <-- Use .top, not .topTrailing
                // The chart background
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
                    Text("Loading chart...")
                        .foregroundColor(.white)
                }

                // Our custom drop-down menu
                if showMenu {
                    VStack(spacing: 10) {
                        NavigationLink(
                            destination: InteractivePortfolioChartView()
                                .environmentObject(chartDataCache)
                                .environmentObject(simSettings)
                                .environmentObject(idleManager)
                                .environmentObject(coordinator)
                        ) {
                            // HStack with spacers to centre
                            HStack {
                                Spacer()
                                Text("Portfolio")
                                Spacer()
                            }
                        }
                        // Hide the dropdown once tapped
                        .simultaneousGesture(TapGesture().onEnded {
                            showMenu = false
                        })
                    }
                    .frame(maxWidth: .infinity)                // Fill the full width
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.horizontal, 16)                 // Equal horizontal padding
                    .transition(.move(edge: .top))
                }
            }
            .onAppear {
                // Reset idle timer
                idleManager.resetIdleTimer()
                
                DispatchQueue.main.async {
                    // 1) Provide the actual size to the renderer
                    metalChart.viewportSize = geo.size

                    // 2) Set up the Metal chart (BTC price)
                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings,
                        isPortfolioChart: false // This is the BTC chart
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
            .navigationBarTitle("Bitcoin Price", displayMode: .inline)
            .navigationBarBackButtonDisplayMode(NavigationBarItem.TitleDisplayMode.minimal)
            .toolbarBackground(Color.black, for: ToolbarBackgroundPlacement.navigationBar)
            .toolbarBackground(ToolbarBackgroundVisibility.visible, for: ToolbarBackgroundPlacement.navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // The chevron button
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
