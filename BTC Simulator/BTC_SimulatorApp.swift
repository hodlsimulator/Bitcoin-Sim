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
    // Keep the @AppStorage for reading/writing mode elsewhere,
    // but do NOT reference it in init(). We’ll manually read from UserDefaults below.
    @AppStorage("isMonthlyMode") private var isMonthlyMode = false

    // Just declare these; don’t initialise them yet.
    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var weeklySimSettings: SimulationSettings
    @StateObject private var monthlySimSettings: MonthlySimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    // MARK: - Init
    init() {
        // 1) Read the mode from UserDefaults (instead of referencing self.isMonthlyMode).
        let localIsMonthlyMode = UserDefaults.standard.bool(forKey: "isMonthlyMode")

        // 2) Create local objects.
        let localAppViewModel       = AppViewModel()
        let localInputManager       = PersistentInputManager()
        let localWeeklySimSettings  = SimulationSettings(loadDefaults: true)

        // Conditionally init monthlySimSettings.
        let localMonthlySimSettings: MonthlySimulationSettings
        if localIsMonthlyMode {
            localMonthlySimSettings = MonthlySimulationSettings(loadDefaults: true)
        } else {
            localMonthlySimSettings = MonthlySimulationSettings(loadDefaults: false)
        }

        let localChartDataCache     = ChartDataCache()
        let localSimChartSelection  = SimChartSelection()

        // 3) Start Sentry (optional).
        SentrySDK.start { options in
            options.dsn = "https://3ca36373246f91c44a0733a5d9489f52@o4508788421623808.ingest.de.sentry.io/4508788424376400"
            options.attachViewHierarchy = false
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
            options.enableAppLaunchProfiling = true
        }

        // 4) Register any default toggles.
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

        // 5) Create the coordinator with local objects.
        let localCoordinator = SimulationCoordinator(
            chartDataCache: localChartDataCache,
            simSettings: localWeeklySimSettings,
            inputManager: localInputManager,
            simChartSelection: localSimChartSelection
        )

        // 6) Assign locals to @StateObject wrappers — last step in init().
        _appViewModel        = StateObject(wrappedValue: localAppViewModel)
        _inputManager        = StateObject(wrappedValue: localInputManager)
        _weeklySimSettings   = StateObject(wrappedValue: localWeeklySimSettings)
        _monthlySimSettings  = StateObject(wrappedValue: localMonthlySimSettings)
        _chartDataCache      = StateObject(wrappedValue: localChartDataCache)
        _simChartSelection   = StateObject(wrappedValue: localSimChartSelection)
        _coordinator         = StateObject(wrappedValue: localCoordinator)
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
                weeklySimSettings.isOnboarding = !didFinishOnboarding

                // Load your historical data here.
                historicalBTCWeeklyReturns = loadAndAlignWeeklyData()
                extendedWeeklyReturns      = historicalBTCWeeklyReturns

                historicalBTCMonthlyReturns = loadAndAlignMonthlyData()
                extendedMonthlyReturns      = historicalBTCMonthlyReturns
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
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
