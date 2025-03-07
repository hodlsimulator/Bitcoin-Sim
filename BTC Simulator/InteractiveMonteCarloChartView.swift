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
    
    // Tracks whether the drop-down menu is visible
    @State private var showMenu = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) {
                // The chart background
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

                // Our custom drop-down menu that appears under the chevron
                if showMenu {
                    VStack(alignment: .leading, spacing: 10) {
                        Button("Switch to Portfolio Chart") {
                            // Put your code to switch to the portfolio chart here
                            showMenu.toggle()
                        }
                        // Add more buttons if needed...
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    // Adjust top padding so it's higher under the nav bar
                    .padding(.trailing, 16)
                    .padding(.top, 0) 
                    .transition(.move(edge: .top)) // or .opacity
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
            // Use inline nav title so that our custom chevron is on the right
            .navigationBarTitle("Bitcoin Price", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    // The chevron button
                    Button(action: {
                        withAnimation {
                            showMenu.toggle()
                        }
                    }) {
                        Image(systemName: showMenu ? "chevron.up" : "chevron.down")
                    }
                }
            }
        }
    }
}
