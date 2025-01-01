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
    @StateObject private var chartDataCache = ChartDataCache() // <-- Keep chart data & input hash
    
    init() {
        print("// DEBUG: BTCMonteCarloApp init - chartDataCache created!")
    }

    var body: some Scene {
        WindowGroup {
            if didFinishOnboarding {
                NavigationStack {
                    ContentView()
                        .environmentObject(simSettings)
                        .environmentObject(chartDataCache)
                }
            } else {
                // Also embed onboarding in a NavigationStack if you need it
                NavigationStack {
                    OnboardingView(didFinishOnboarding: $didFinishOnboarding)
                        .environmentObject(simSettings)
                        .environmentObject(chartDataCache)
                }
            }
        }
    }
}
