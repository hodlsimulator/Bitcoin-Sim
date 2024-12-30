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

    var body: some Scene {
        WindowGroup {
            if didFinishOnboarding {
                NavigationStack {
                    ContentView()
                }
                .environmentObject(simSettings)
            } else {
                OnboardingView(didFinishOnboarding: $didFinishOnboarding)
                    .environmentObject(simSettings)
            }
        }
    }
}
