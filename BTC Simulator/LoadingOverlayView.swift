//
//  LoadingOverlayView.swift
//  BTCMonteCarlo
//
//  Created by . . on 08/01/2025.
//

import SwiftUI

struct LoadingOverlayView: View {
    @EnvironmentObject var coordinator: SimulationCoordinator
    @EnvironmentObject var simSettings: SimulationSettings

    @State private var tipTimer: Timer? = nil
    @State private var currentTip: String = ""
    @State private var showTip: Bool = false
    @State private var filteredTips: [String] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer().frame(height: 250)
                
                // Cancel button (only shown while simulating, not chart-building)
                HStack {
                    Spacer()
                    if coordinator.isLoading && !coordinator.isChartBuilding {
                        Button(action: {
                            coordinator.isCancelled = true
                            coordinator.isLoading = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding()
                        }
                        .padding(.trailing, 20)
                    }
                }
                .offset(y: 220)
                
                // Simulation in progress
                if coordinator.isLoading {
                    InteractiveBitcoinSymbol3DSpinner()
                        .padding(.bottom, 30)

                    VStack(spacing: 17) {
                        Text("Simulating: \(coordinator.completedIterations) / \(coordinator.totalIterations)")
                            .font(.body.monospacedDigit())
                            .foregroundColor(.white)

                        ProgressView(value: Double(coordinator.completedIterations),
                                     total: Double(coordinator.totalIterations))
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .frame(width: 200)
                    }
                    .padding(.bottom, 20)
                
                // Chart building in progress
                } else if coordinator.isChartBuilding {
                    VStack(spacing: 12) {
                        Text("Generating Charts…")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)

                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(
                                tint: Color(red: 189/255, green: 213/255, blue: 234/255)
                            ))
                            .scaleEffect(2.0)
                    }
                    .offset(y: 270)

                    Spacer().frame(height: 30)
                }

                // Show tips near the bottom
                if showTip && (coordinator.isLoading || coordinator.isChartBuilding) {
                    Text(currentTip)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .transition(.opacity)
                        .padding(.bottom, 40)
                }

                Spacer()
            }
        }
        .onAppear {
            // Filter tips up front
            filteredTips = TipsData.filteredLoadingTips(for: simSettings)
            startTipCycle()
        }
        .onDisappear {
            stopTipCycle()
        }
    }

    // MARK: - Timer logic to match original timing exactly
    private func startTipCycle() {
        // Clear any old timers
        tipTimer?.invalidate()
        tipTimer = nil
        showTip = false
        
        // If no tips, just skip
        guard !filteredTips.isEmpty else { return }
        
        // After 4s, pick a tip & fade in over 2s
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            currentTip = filteredTips.randomElement() ?? ""
            withAnimation(.easeInOut(duration: 2)) {
                showTip = true
            }
        }
        
        // Every 20s, fade out for 2s, then wait 4s, then pick a new tip & fade in for 2s
        tipTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            // Fade out (2 seconds)
            withAnimation(.easeInOut(duration: 2)) {
                showTip = false
            }
            // After fading out, wait 4 seconds, then fade in a new tip
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                currentTip = filteredTips.randomElement() ?? ""
                withAnimation(.easeInOut(duration: 2)) {
                    showTip = true
                }
            }
        }
    }
    
    private func stopTipCycle() {
        tipTimer?.invalidate()
        tipTimer = nil
        showTip = false
    }
}
