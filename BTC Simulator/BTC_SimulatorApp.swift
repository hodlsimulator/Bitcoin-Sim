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
        // Register default values (toggles) for first launch
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
        
        let newAppViewModel    = AppViewModel()
        let newInputManager    = PersistentInputManager()
        let newSimSettings     = SimulationSettings(loadDefaults: true)
        let newChartDataCache  = ChartDataCache()
        let newSimChartSelection = SimChartSelection()
        
        let newCoordinator = SimulationCoordinator(
            chartDataCache: newChartDataCache,
            simSettings: newSimSettings,
            inputManager: newInputManager,
            simChartSelection: newSimChartSelection
        )

        newSimSettings.inputManager = newInputManager

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
                        .onChange(of: geo.size) { newSize in
                            appViewModel.windowSize = newSize
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
                // Load user defaults
                simSettings.loadFromUserDefaults()
                simSettings.isOnboarding = !didFinishOnboarding

                // 1. Load weekly data
                historicalBTCWeeklyReturns = loadAndAlignWeeklyData()
                print("Loaded \(historicalBTCWeeklyReturns.count) weekly BTC return entries.")

                // 1a. Also copy to extendedWeeklyReturns if you want the same data used for extended sampling
                extendedWeeklyReturns = historicalBTCWeeklyReturns
                print("extendedWeeklyReturns count = \(extendedWeeklyReturns.count)")

                // 2. Load monthly data
                historicalBTCMonthlyReturns = loadAndAlignMonthlyData()
                print("Loaded \(historicalBTCMonthlyReturns.count) monthly BTC return entries.")

                // 2a. Also copy to extendedMonthlyReturns
                extendedMonthlyReturns = historicalBTCMonthlyReturns
                print("extendedMonthlyReturns count = \(extendedMonthlyReturns.count)")
            }
            // Save to UserDefaults when the app goes inactive or background
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .inactive, .background:
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
