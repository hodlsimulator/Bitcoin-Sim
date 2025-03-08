import SwiftUI
import UIKit
import MetalKit
import simd

/// A SwiftUI view that renders the Portfolio chart using Metal.
struct InteractivePortfolioChartView: View {
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var idleManager: IdleManager
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    /// Closure that the parent will pass in, used to navigate back to Bitcoin chart.
    let onSwitchToBitcoin: () -> Void

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

                // Dropdown menu for switching back to Bitcoin
                if showMenu {
                    VStack(spacing: 10) {
                        Button {
                            onSwitchToBitcoin()
                            showMenu = false
                        } label: {
                            HStack {
                                Spacer()
                                Text("Bitcoin Price")
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

                    // Set up the Portfolio chart
                    metalChart.setupMetal(
                        in: geo.size,
                        chartDataCache: chartDataCache,
                        simSettings: simSettings,
                        isPortfolioChart: true
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
            .navigationBarTitle("Portfolio", displayMode: .inline)
            // If you need a dark nav bar:
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
}
