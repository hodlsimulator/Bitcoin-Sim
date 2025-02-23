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
    @AppStorage("isMonthlyMode") private var isMonthlyMode = false

    // MARK: - StateObjects (so they live for the life of the app)
    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var weeklySimSettings: SimulationSettings
    @StateObject private var monthlySimSettings: MonthlySimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    init() {
        // 1) Global navigation bar styling
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        navBarAppearance.shadowColor = .clear // remove the thin hairline
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance   = navBarAppearance
        UINavigationBar.appearance().compactAppearance    = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Make arrows and bar buttons white.
        UINavigationBar.appearance().tintColor = .white
            
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = navBarAppearance
        }

        // Old style approach (extra measure to remove hairline):
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)

        // 2) Register any default toggles/values
        let defaultToggles: [String: Any] = [
            // Weekly toggles
            "lockedRandomSeed": false,
            "useLognormalGrowth": true,
            "useHistoricalSampling": true,
            "useVolShocks": true,
            "useGarchVolatility": true,
            "useRegimeSwitching": true,
            "useAutoCorrelation": true,
            "autoCorrelationStrength": 0.05,
            "meanReversionTarget": 0.03,
            "useMeanReversion": true,
            "useAnnualStep": false,
            "useRandomSeed": true,
            "seedValue": 0,

            // Monthly toggles
            "useLognormalGrowthMonthly": true,
            "lockedRandomSeedMonthly": false,
            "useRandomSeedMonthly": true,
            "useHistoricalSamplingMonthly": true,
            "useVolShocksMonthly": true,
            "useGarchVolatilityMonthly": true,
            "useRegimeSwitchingMonthly": true,
            "useExtendedHistoricalSamplingMonthly": true,
            "useAutoCorrelationMonthly": true,
            "autoCorrelationStrengthMonthly": 0.05,
            "meanReversionTargetMonthly": 0.03,
            "useMeanReversionMonthly": true,
            "lockHistoricalSamplingMonthly": false
        ]
        UserDefaults.standard.register(defaults: defaultToggles)

        // 3) Create local objects
        let localAppViewModel       = AppViewModel()
        let localInputManager       = PersistentInputManager()
        let localWeeklySimSettings  = SimulationSettings(loadDefaults: true)
        let localMonthlySimSettings = MonthlySimulationSettings(loadDefaults: true)
        let localChartDataCache     = ChartDataCache()
        let localSimChartSelection  = SimChartSelection()

        // 4) Initialize Sentry
        SentrySDK.start { options in
            options.dsn                            = "https://examplePublicKey.ingest.sentry.io/exampleProjectID"
            options.attachViewHierarchy            = false
            options.enableMetricKit                = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces          = true
            options.enableAppLaunchProfiling       = true
        }

        // 5) Create the SimulationCoordinator
        let localCoordinator = SimulationCoordinator(
            chartDataCache: localChartDataCache,
            simSettings: localWeeklySimSettings,
            monthlySimSettings: localMonthlySimSettings,
            inputManager: localInputManager,
            simChartSelection: localSimChartSelection
        )

        // 6) Assign objects to @StateObject wrappers
        _appViewModel       = StateObject(wrappedValue: localAppViewModel)
        _inputManager       = StateObject(wrappedValue: localInputManager)
        _weeklySimSettings  = StateObject(wrappedValue: localWeeklySimSettings)
        _monthlySimSettings = StateObject(wrappedValue: localMonthlySimSettings)
        _chartDataCache     = StateObject(wrappedValue: localChartDataCache)
        _simChartSelection  = StateObject(wrappedValue: localSimChartSelection)
        _coordinator        = StateObject(wrappedValue: localCoordinator)
    }

    // MARK: - Main Scene
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

                // If user already onboarded, go straight to ContentView; else OnboardingView
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
                    .tint(.white) // <–– SwiftUI override so the arrow is never blue.
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
                let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
                if !hasLaunchedBefore {
                    print("🚀 First Launch, restoring defaults.")
                    weeklySimSettings.restoreDefaults()
                    weeklySimSettings.saveToUserDefaults()
                    monthlySimSettings.restoreDefaultsMonthly(whenIn: .months)
                    monthlySimSettings.saveToUserDefaultsMonthly()
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }

                // Check if monthly or weekly mode is in use
                monthlySimSettings.loadFromUserDefaultsMonthly()
                coordinator.useMonthly = (monthlySimSettings.periodUnitMonthly == .months)

                // Onboarding
                weeklySimSettings.isOnboarding = !didFinishOnboarding

                // Load historical data
                historicalBTCWeeklyReturns = loadAndAlignWeeklyData()
                extendedWeeklyReturns      = historicalBTCWeeklyReturns
                historicalBTCMonthlyReturns = loadAndAlignMonthlyData()
                extendedMonthlyReturns      = historicalBTCMonthlyReturns
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    // Save sim settings on background
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
