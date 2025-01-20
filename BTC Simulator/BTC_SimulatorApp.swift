//
//  BTC_SimulatorApp.swift
//  BTC Simulator
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
        // 1) Create all objects
        let newAppViewModel = AppViewModel()
        let newInputManager = PersistentInputManager()
        let newSimSettings = SimulationSettings(loadDefaults: true)
        let newChartDataCache = ChartDataCache()
        
        // Rename from ChartSelection => SimChartSelection
        let newSimChartSelection = SimChartSelection()
        
        // Coordinator must now accept simChartSelection
        let newCoordinator = SimulationCoordinator(
            chartDataCache: newChartDataCache,
            simSettings: newSimSettings,
            inputManager: newInputManager,
            simChartSelection: newSimChartSelection
        )

        // 2) Ensure simSettings has a reference to the same inputManager
        newSimSettings.inputManager = newInputManager

        // 3) Assign them to @StateObject wrappers
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
                            // Pass simChartSelection instead of chartSelection
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
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
