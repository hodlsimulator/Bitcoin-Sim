//
//  BTC_SimulatorApp.swift
//  BTC Simulator
//
//  Created by . . on 28/11/2024.
//

import SwiftUI

@main
struct BTCMonteCarloApp: App {
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false

    @StateObject private var simSettings = SimulationSettings()
    @StateObject private var chartDataCache = ChartDataCache() // Keep chart data & input hash
    @StateObject private var appViewModel = AppViewModel()      // Observe and publish window size changes

    init() {
        print("// DEBUG: BTCMonteCarloApp init - chartDataCache created!")
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // A clear GeometryReader to detect window size changes.
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            appViewModel.windowSize = geo.size
                        }
                        .onChange(of: geo.size) { newSize in
                            appViewModel.windowSize = newSize
                            print("// DEBUG: windowSize updated to \(newSize)")
                        }
                }

                // Normal app flow.
                if didFinishOnboarding {
                    NavigationStack {
                        ContentView()
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(appViewModel)
                    }
                } else {
                    NavigationStack {
                        OnboardingView(didFinishOnboarding: $didFinishOnboarding)
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(appViewModel)
                    }
                }
            }
        }
    }
}

// NEW: Simple ObservableObject to store and publish the window size.
@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
