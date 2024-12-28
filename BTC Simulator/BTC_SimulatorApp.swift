//
//  BTC_SimulatorApp.swift
//  BTC Simulator
//
//  Created by . . on 28/11/2024.
//

import SwiftUI

@main
struct BTCMoteCarloApp: App {
    @StateObject private var simSettings = SimulationSettings()

    // Track whether onboarding is done.
    @State private var didFinishOnboarding: Bool

    init() {
        // Check a UserDefaults key to see if onboarding was completed.
        let hasOnboarded = UserDefaults.standard.bool(forKey: "hasOnboarded")
        print(">>> hasOnboarded in init is:", hasOnboarded)
        _didFinishOnboarding = State(initialValue: hasOnboarded)
    }

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
                    .onDisappear {
                        print("OnboardingView disappeared, switching to main content.")
                        UserDefaults.standard.set(true, forKey: "hasOnboarded")
                    }
            }
        }
    }
}
