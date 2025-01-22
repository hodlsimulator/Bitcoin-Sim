//
//  BTC_SimulatorApp.swift
//  BTC Simulator
//
//  Created by ... on 20/11/2024.
//

import SwiftUI

class SimChartSelection: ObservableObject {
    @Published var selectedChart: ChartType = .btcPrice
}

@main
struct BTCMonteCarloApp: App {
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false

    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var simSettings: SimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    init() {
        print("** Creating SimulationSettings with loadDefaults = true")
        let newAppViewModel = AppViewModel()
        let newInputManager = PersistentInputManager()
        let newSimSettings = SimulationSettings(loadDefaults: true)  // custom init
        let newChartDataCache = ChartDataCache()
        let newSimChartSelection = SimChartSelection()
        
        let newCoordinator = SimulationCoordinator(
            chartDataCache: newChartDataCache,
            simSettings: newSimSettings,
            inputManager: newInputManager,
            simChartSelection: newSimChartSelection
        )

        newSimSettings.inputManager = newInputManager

        _appViewModel = StateObject(wrappedValue: newAppViewModel)
        _inputManager = StateObject(wrappedValue: newInputManager)
        _simSettings = StateObject(wrappedValue: newSimSettings)
        _chartDataCache = StateObject(wrappedValue: newChartDataCache)
        _simChartSelection = StateObject(wrappedValue: newSimChartSelection)
        _coordinator = StateObject(wrappedValue: newCoordinator)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            appViewModel.windowSize = geo.size
                            print("// DEBUG: windowSize initial \(geo.size)")
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
                            .environmentObject(simChartSelection)
                            .environmentObject(coordinator)
                            .environmentObject(appViewModel)
                    }
                    .preferredColorScheme(.dark)
                } else {
                    NavigationStack {
                        OnboardingView(didFinishOnboarding: $didFinishOnboarding)
                            .environmentObject(inputManager)
                            .environmentObject(simSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(simChartSelection)
                            .environmentObject(coordinator)
                            .environmentObject(appViewModel)
                    }
                    .preferredColorScheme(.dark)
                }
            }
            .onAppear {
                simSettings.isOnboarding = !didFinishOnboarding
            }
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
