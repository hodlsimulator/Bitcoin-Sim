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
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                
                if !isLandscape {
                    // Render your original portrait code exactly
                    portraitOverlay
                } else {
                    // Render a custom landscape layout that pins to the bottom
                    landscapeOverlay
                }
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
    
    // MARK: - Portrait Overlay (Unchanged from your original)
    private var portraitOverlay: some View {
        VStack(spacing: 0) {
            // Original top spacer
            Spacer().frame(height: 250)
            
            // Original HStack with offset
            HStack {
                Spacer()
                if coordinator.isLoading && !coordinator.isChartBuilding {
                    Button {
                        coordinator.isCancelled = true
                        coordinator.isLoading = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                    }
                    .offset(y: 220)
                }
            }
            
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
                
            } else if coordinator.isChartBuilding {
                VStack(spacing: 12) {
                    Text("Generating Charts…")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: Color(red: 189/255, green: 213/255, blue: 234/255))
                        )
                        .scaleEffect(2.0)
                }
                .offset(y: 270)
                
                Spacer().frame(height: 30)
            }
            
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
    
    // MARK: - Landscape Overlay (Pinned to bottom, no spinner if desired)
    private var landscapeOverlay: some View {
        VStack(spacing: 16) {
            
            // Cancel button at top
            HStack {
                Spacer()
                if coordinator.isLoading && !coordinator.isChartBuilding {
                    Button {
                        coordinator.isCancelled = true
                        coordinator.isLoading = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
            
            Spacer()  // push content to bottom
            
            // If a simulation is running
            if coordinator.isLoading {
                // Hide the spinner in landscape (or remove this check if you do want it)
                // InteractiveBitcoinSymbol3DSpinner()
                
                VStack(spacing: 10) {
                    Text("Simulating: \(coordinator.completedIterations) / \(coordinator.totalIterations)")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.white)
                    
                    ProgressView(value: Double(coordinator.completedIterations),
                                 total: Double(coordinator.totalIterations))
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(width: 200)
                }
                
            // If charts are being built
            } else if coordinator.isChartBuilding {
                VStack(spacing: 12) {
                    Text("Generating Charts…")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: Color(red: 189/255, green: 213/255, blue: 234/255)
                        ))
                        .scaleEffect(2.0)
                }
            }
            
            // Show tips if we have them
            if showTip && (coordinator.isLoading || coordinator.isChartBuilding) {
                Text(currentTip)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .transition(.opacity)
                    .padding(.top, 16)
            }
            
            Spacer().frame(height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    // MARK: - Timer logic (same as before)
    private func startTipCycle() {
        tipTimer?.invalidate()
        tipTimer = nil
        showTip = false
        
        guard !filteredTips.isEmpty else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            currentTip = filteredTips.randomElement() ?? ""
            withAnimation(.easeInOut(duration: 2)) {
                showTip = true
            }
        }
        
        tipTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                showTip = false
            }
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
