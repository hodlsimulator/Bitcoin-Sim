//
//  BTC_SimulatorApp.swift
//  BTC Simulator
//
//  Created by . . on 28/11/2024.
//

import SwiftUI

class ChartSelection: ObservableObject {
    @Published var selectedChart: MonteCarloResultsView.ChartType = .btcPrice
}

@main
struct BTCMonteCarloApp: App {
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false

    @StateObject private var inputManager = PersistentInputManager()
    @StateObject private var simSettings = SimulationSettings()
    @StateObject private var chartDataCache = ChartDataCache()
    @StateObject private var appViewModel = AppViewModel()

    // NEW: This holds the currently selected chart
    @StateObject private var chartSelection = ChartSelection()

    init() {
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
                Color.black.ignoresSafeArea()

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

                if didFinishOnboarding {
                    NavigationStack {
                        ContentView()
                            .environmentObject(inputManager)
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(appViewModel)
                            // Provide the chartSelection environment object here:
                            .environmentObject(chartSelection)
                    }
                    .preferredColorScheme(.dark)
                } else {
                    NavigationStack {
                        OnboardingView(didFinishOnboarding: $didFinishOnboarding)
                            .environmentObject(inputManager)
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(appViewModel)
                            .environmentObject(chartSelection)
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
