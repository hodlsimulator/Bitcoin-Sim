//
//  BTCMonteCarloApp.swift
//  BTC Simulator
//
//  Created by ... on 20/11/2024.
//

import SwiftUI
import Sentry

class SimChartSelection: ObservableObject {
    @Published var selectedChart: ChartType = .btcPrice
}

@main
struct BTCMonteCarloApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false

    // 1) Remove @EnvironmentObject from the App struct — we want to *provide*, not consume, these objects
    // 2) Convert all objects to @StateObject, then initialize them in init()

    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var weeklySimSettings: SimulationSettings
    @StateObject private var monthlySimSettings: MonthlySimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    // MARK: - Init
    init() {
        // ---- Sentry Startup
        SentrySDK.start { options in
            options.dsn = "https://3ca36373246f91c44a0733a5d9489f52@o4508788421623808.ingest.de.sentry.io/4508788424376400"
            options.attachViewHierarchy = false
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
            options.enableAppLaunchProfiling = true
        }

        // ---- Default toggles
        let defaultToggles: [String: Any] = [
            "useLockRandomSeed": false,
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

        // ---- Create local instances
        let appViewModelInstance = AppViewModel()
        let inputManagerInstance = PersistentInputManager()
        let weeklySimSettingsInstance = SimulationSettings(loadDefaults: true)
        let monthlySimSettingsInstance = MonthlySimulationSettings()
        let chartDataCacheInstance = ChartDataCache()
        let simChartSelectionInstance = SimChartSelection()

        // Create the coordinator using the local instances above
        let coordinatorInstance = SimulationCoordinator(
            chartDataCache: chartDataCacheInstance,
            simSettings: weeklySimSettingsInstance,  // weekly by default
            inputManager: inputManagerInstance,
            simChartSelection: simChartSelectionInstance
        )

        // ---- Assign them to @StateObject wrappers
        _appViewModel        = StateObject(wrappedValue: appViewModelInstance)
        _inputManager        = StateObject(wrappedValue: inputManagerInstance)
        _weeklySimSettings   = StateObject(wrappedValue: weeklySimSettingsInstance)
        _monthlySimSettings  = StateObject(wrappedValue: monthlySimSettingsInstance)
        _chartDataCache      = StateObject(wrappedValue: chartDataCacheInstance)
        _simChartSelection   = StateObject(wrappedValue: simChartSelectionInstance)
        _coordinator         = StateObject(wrappedValue: coordinatorInstance)

        // **Don't** do anything else here that calls self.coordinator or other properties;
        // just finish init.
    }

    // MARK: - body
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            appViewModel.windowSize = geo.size
                        }
                        .onChange(of: geo.size) { _, newSize in
                            appViewModel.windowSize = newSize
                        }
                }

                // Switch between main ContentView and Onboarding
                if didFinishOnboarding {
                    NavigationStack {
                        ContentView()
                            // Provide these objects so child views can consume them
                            .environmentObject(inputManager)
                            .environmentObject(weeklySimSettings)
                            .environmentObject(monthlySimSettings)
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
                            .environmentObject(weeklySimSettings)
                            .environmentObject(monthlySimSettings)
                            .environmentObject(chartDataCache)
                            .environmentObject(simChartSelection)
                            .environmentObject(coordinator)
                            .environmentObject(appViewModel)
                    }
                    .preferredColorScheme(.dark)
                }
            }
            .onAppear {
                // Now we can safely call stuff on weeklySimSettings or monthlySimSettings
                weeklySimSettings.isOnboarding = !didFinishOnboarding

                // e.g. load historical data
                historicalBTCWeeklyReturns = loadAndAlignWeeklyData()
                extendedWeeklyReturns = historicalBTCWeeklyReturns

                historicalBTCMonthlyReturns = loadAndAlignMonthlyData()
                extendedMonthlyReturns = historicalBTCMonthlyReturns
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    // Save weekly & monthly user defaults
                    weeklySimSettings.saveToUserDefaults()
                    monthlySimSettings.saveToUserDefaultsMonthly()
                }
            }
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
