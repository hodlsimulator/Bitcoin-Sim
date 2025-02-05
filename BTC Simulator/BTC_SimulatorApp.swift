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
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasOnboarded") private var didFinishOnboarding = false

    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var simSettings: SimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    init() {
        // Register a few general toggles in UserDefaults.
        // These are *not* per-factor toggles — they are global simulation settings.
        let defaultToggles: [String: Any] = [
            "useLognormalGrowth": true,
            "useHistoricalSampling": true,
            "useVolShocks": true,
            "useGarchVolatility": true,
            "useRegimeSwitching": true,
            "useAutoCorrelation": true,
            "autoCorrelationStrength": 0.05,
            "meanReversionTarget": 0.03
        ]
        UserDefaults.standard.register(defaults: defaultToggles)
        
        print("** Creating SimulationSettings with loadDefaults = true")
        
        let newAppViewModel      = AppViewModel()
        let newInputManager      = PersistentInputManager()
        let newSimSettings       = SimulationSettings(loadDefaults: true) // uses factor dictionary now
        let newChartDataCache    = ChartDataCache()
        let newSimChartSelection = SimChartSelection()
        
        let newCoordinator = SimulationCoordinator(
            chartDataCache: newChartDataCache,
            simSettings: newSimSettings,
            inputManager: newInputManager,
            simChartSelection: newSimChartSelection
        )

        // Wrap in StateObjects
        _appViewModel      = StateObject(wrappedValue: newAppViewModel)
        _inputManager      = StateObject(wrappedValue: newInputManager)
        _simSettings       = StateObject(wrappedValue: newSimSettings)
        _chartDataCache    = StateObject(wrappedValue: newChartDataCache)
        _simChartSelection = StateObject(wrappedValue: newSimChartSelection)
        _coordinator       = StateObject(wrappedValue: newCoordinator)
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
                        .onChange(of: geo.size, initial: false) { _, newSize in
                            appViewModel.windowSize = newSize
                        }
                }

                if didFinishOnboarding {
                    NavigationStack {
                        ContentView()
                            .environmentObject(inputManager)
                            .environmentObject(simSettings)        // <-- new dictionary-based settings
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
                // Sync onboarding state
                simSettings.isOnboarding = !didFinishOnboarding

                // 1. Load weekly data
                historicalBTCWeeklyReturns = loadAndAlignWeeklyData()
                print("Loaded \(historicalBTCWeeklyReturns.count) weekly BTC return entries.")

                // 1a. If using extended sampling, copy them
                extendedWeeklyReturns = historicalBTCWeeklyReturns
                print("extendedWeeklyReturns count = \(extendedWeeklyReturns.count)")

                // 2. Load monthly data
                historicalBTCMonthlyReturns = loadAndAlignMonthlyData()
                print("Loaded \(historicalBTCMonthlyReturns.count) monthly BTC return entries.")

                // 2a. If using extended sampling, copy them
                extendedMonthlyReturns = historicalBTCMonthlyReturns
                print("extendedMonthlyReturns count = \(extendedMonthlyReturns.count)")
            }
            .onChange(of: scenePhase, initial: false) { _, newPhase in
                switch newPhase {
                case .inactive, .background:
                    // Save our new factor states + other toggles
                    simSettings.saveToUserDefaults()
                default:
                    break
                }
            }
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
