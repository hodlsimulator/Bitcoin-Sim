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
    @StateObject private var chartDataCache = ChartDataCache()
    @StateObject private var appViewModel = AppViewModel()

    init() {
        // Force dark navigation so it doesn't momentarily flash white.
        // Also forced the keyboard to a dark theme:
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Force a dark background behind everything to kill white flashes on rotation.
                Color.black.ignoresSafeArea()

                // Track window size changes.
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

                // Normal app flow
                if didFinishOnboarding {
                    NavigationStack {
                        ContentView()
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(appViewModel)
                    }
                    .preferredColorScheme(.dark)  // maintain a dark style
                } else {
                    NavigationStack {
                        OnboardingView(didFinishOnboarding: $didFinishOnboarding)
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(appViewModel)
                    }
                    .preferredColorScheme(.dark)
                }
            }
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
