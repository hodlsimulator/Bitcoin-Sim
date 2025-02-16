//
//  BTCMonteCarloApp.swift
//  BTC Simulator
//
//  Created by ... on 20/11/2024.
//

import SwiftUI
import Sentry
import UIKit  // <-- Needed for orientation

// 1) Add an AppDelegate that locks orientation
class AppDelegate: NSObject, UIApplicationDelegate {
    // By default, allow all orientations
    static var orientationLock = UIInterfaceOrientationMask.all

    // This gets called whenever iOS decides which orientations are allowed
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

class SimChartSelection: ObservableObject {
    @Published var selectedChart: ChartType = .btcPrice
}

@main
struct BTCMonteCarloApp: App {
    // 2) Hook the AppDelegate in
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false
    @AppStorage("isMonthlyMode") private var isMonthlyMode = false

    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var weeklySimSettings: SimulationSettings
    @StateObject private var monthlySimSettings: MonthlySimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    init() {
        // 1) Register toggles first:
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

        // 2) Create local objects
        let localAppViewModel       = AppViewModel()
        let localInputManager       = PersistentInputManager()
        let localWeeklySimSettings  = SimulationSettings(loadDefaults: true)
        let localMonthlySimSettings = MonthlySimulationSettings(loadDefaults: true)
        
        let localChartDataCache     = ChartDataCache()
        let localSimChartSelection  = SimChartSelection()

        // 3) Start Sentry (optional).
        SentrySDK.start { options in
            options.dsn = "https://examplePublicKey.ingest.sentry.io/exampleProjectID"
            options.attachViewHierarchy = false
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
            options.enableAppLaunchProfiling = true
        }
        
        // 4) Create coordinator
        let localCoordinator = SimulationCoordinator(
            chartDataCache: localChartDataCache,
            simSettings: localWeeklySimSettings,
            monthlySimSettings: localMonthlySimSettings,
            inputManager: localInputManager,
            simChartSelection: localSimChartSelection
        )
        
        // 5) Assign to @StateObject
        _appViewModel        = StateObject(wrappedValue: localAppViewModel)
        _inputManager        = StateObject(wrappedValue: localInputManager)
        _weeklySimSettings   = StateObject(wrappedValue: localWeeklySimSettings)
        _monthlySimSettings  = StateObject(wrappedValue: localMonthlySimSettings)
        _chartDataCache      = StateObject(wrappedValue: localChartDataCache)
        _simChartSelection   = StateObject(wrappedValue: localSimChartSelection)
        _coordinator         = StateObject(wrappedValue: localCoordinator)
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
                        .onChange(of: geo.size) { _, newSize in
                            appViewModel.windowSize = newSize
                        }
                }

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
                
                // (A) Call them on *every* launch if you like:
                // weeklySimSettings.loadFromUserDefaults()
                // monthlySimSettings.loadFromUserDefaultsMonthly()

                // (B) Check if it's a fresh install (no "hasLaunchedBefore" set)
                let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
                if !hasLaunchedBefore {
                    // This is the very first time the app runs
                    print("🚀 First Launch detected — calling restoreDefaults() for weekly and monthly.")
                    
                    // If you only want to restore weekly by default:
                    weeklySimSettings.restoreDefaults()
                    weeklySimSettings.saveToUserDefaults()
                    
                    // If you also want monthly defaults set (in case user chooses monthly later):
                    monthlySimSettings.restoreDefaultsMonthly(whenIn: .months)
                    monthlySimSettings.saveToUserDefaultsMonthly()
                    
                    // Mark that we've now done first-launch setup
                    UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                }
                
                // Decide monthly vs weekly
                monthlySimSettings.loadFromUserDefaultsMonthly()
                if monthlySimSettings.periodUnitMonthly == .months {
                    coordinator.useMonthly = true
                } else {
                    coordinator.useMonthly = false
                }
                
                weeklySimSettings.isOnboarding = !didFinishOnboarding
                
                // Load historical data etc.
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
