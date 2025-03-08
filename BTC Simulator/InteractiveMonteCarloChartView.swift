//
//  InteractiveMonteCarloChartView.swift
//  BTCMonteCarlo
//

import SwiftUI
import UIKit
import MetalKit
import simd

struct InteractiveMonteCarloChartView: View {
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var idleManager: IdleManager
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    // Give it a default so calls that don't specify navBarBlack won't break
    let navBarBlack: Bool
    
    init(navBarBlack: Bool = false) {
        self.navBarBlack = navBarBlack
    }
    
    @State private var metalChart = MetalChartRenderer()
    @State private var isMetalChartReady = false
    @State private var showMenu = false  // Tracks drop-down visibility

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

                if showMenu {
                    VStack(spacing: 10) {
                        NavigationLink(
                            destination: InteractivePortfolioChartView()
                                .environmentObject(chartDataCache)
                                .environmentObject(simSettings)
                                .environmentObject(idleManager)
                                .environmentObject(coordinator)
                        ) {
                            HStack {
                                Spacer()
                                Text("Portfolio")
                                Spacer()
                            }
                        }
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
                idleManager.resetIdleTimer()
                
                DispatchQueue.main.async {
                    metalChart.viewportSize = geo.size

                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings,
                        isPortfolioChart: false
                    )

                    coordinator.onChartDataUpdated = {
                        DispatchQueue.main.async {
                            self.metalChart.buildLineBuffers()
                        }
                    }
                    
                    isMetalChartReady = true
                }
            }
            .navigationBarTitle("Bitcoin Price", displayMode: .inline)
            .toolbarBackground(navBarBlack ? Color.black : Color(UIColor.systemBackground), for: .navigationBar)
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
}
        