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
    @EnvironmentObject var coordinator: SimulationCoordinator
    
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
                    Text("Loading portfolio chart...")
                        .foregroundColor(.white)
                }

                // Dropdown menu for switching back to Bitcoin view
                if showMenu {
                    VStack(spacing: 10) {
                        NavigationLink(
                            destination: InteractiveMonteCarloChartView()
                                .environmentObject(chartDataCache)
                                .environmentObject(simSettings)
                                .environmentObject(idleManager)
                                .environmentObject(coordinator)
                        ) {
                            HStack {
                                Spacer()
                                Text("Bitcoin Price")
                                Spacer()
                            }
                        }
                        // Hide the dropdown once tapped
                        .simultaneousGesture(TapGesture().onEnded {
                            showMenu = false
                        })
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

                    // Rebuild GPU buffers whenever coordinator’s data changes
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
        .navigationBarTitle("Portfolio", displayMode: .inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
