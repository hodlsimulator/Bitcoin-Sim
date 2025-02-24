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
                    portraitOverlay
                } else {
                    landscapeOverlay
                }
            }
        }
        .onAppear {
            filteredTips = TipsData.filteredLoadingTips(for: simSettings)
            startTipCycle()
        }
        .onDisappear {
            stopTipCycle()
        }
    }
    
    // MARK: - Portrait Overlay
    private var portraitOverlay: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 250)
            
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
            
            // Only show tips if actually simulating (not while chart-building)
            if showTip && coordinator.isLoading {
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
    
    // MARK: - Landscape Overlay
    private var landscapeOverlay: some View {
        ZStack(alignment: .bottom) {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 16) {
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
                
                Spacer()
                
                if coordinator.isLoading {
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
                } else if coordinator.isChartBuilding {
                    VStack(spacing: 12) {
                        Text("Generating Charts…")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 10)

                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: Color(red: 189/255, green: 213/255, blue: 234/255))
                            )
                            .scaleEffect(2.0)
                    }
                }
                
                Spacer().frame(height: 50)
            }
            .padding()

            // Again, only show tips during simulation
            if showTip && coordinator.isLoading {
                Text(currentTip)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                    .transition(.opacity)
                    .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Timer logic
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
