//
//  BTCMonteCarloApp.swift
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
    @AppStorage("isMonthlyMode") private var isMonthlyMode = false

    // MARK: - StateObjects
    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var weeklySimSettings: SimulationSettings
    @StateObject private var monthlySimSettings: MonthlySimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    init() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        navBarAppearance.shadowColor = .clear
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance   = navBarAppearance
        UINavigationBar.appearance().compactAppearance    = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = .white
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().compactScrollEdgeAppearance = navBarAppearance
        }
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)

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

        let localAppViewModel       = AppViewModel()
        let localInputManager       = PersistentInputManager()
        let localWeeklySimSettings  = SimulationSettings(loadDefaults: true)
        let localMonthlySimSettings = MonthlySimulationSettings(loadDefaults: true)
        let localChartDataCache     = ChartDataCache()
        let localSimChartSelection  = SimChartSelection()

        let localCoordinator = SimulationCoordinator(
            chartDataCache: localChartDataCache,
            simSettings: localWeeklySimSettings,
            monthlySimSettings: localMonthlySimSettings,
            inputManager: localInputManager,
            simChartSelection: localSimChartSelection               
        )

        _appViewModel       = StateObject(wrappedValue: localAppViewModel)
        _inputManager       = StateObject(wrappedValue: localInputManager)
        _weeklySimSettings  = StateObject(wrappedValue: localWeeklySimSettings)
        _monthlySimSettings = StateObject(wrappedValue: localMonthlySimSettings)
        _chartDataCache     = StateObject(wrappedValue: localChartDataCache)
        _simChartSelection  = StateObject(wrappedValue: localSimChartSelection)
        _coordinator        = StateObject(wrappedValue: localCoordinator)
        
        #if DEBUG
        // Wipe monthly keys only while running in Debug mode from Xcode
        UserDefaults.standard.removeObject(forKey: "savedUserPeriodsMonthly")
        UserDefaults.standard.removeObject(forKey: "savedInitialBTCPriceUSDMonthly")
        UserDefaults.standard.removeObject(forKey: "savedStartingBalanceMonthly")
        UserDefaults.standard.removeObject(forKey: "savedAverageCostBasisMonthly")
        UserDefaults.standard.synchronize()
        #endif
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
                    .tint(.white)
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

                monthlySimSettings.loadFromUserDefaultsMonthly()
                coordinator.useMonthly = (monthlySimSettings.periodUnitMonthly == .months)
                weeklySimSettings.isOnboarding = !didFinishOnboarding

                historicalBTCWeeklyReturns   = loadAndAlignWeeklyData()
                extendedWeeklyReturns        = historicalBTCWeeklyReturns
                historicalBTCMonthlyReturns  = loadAndAlignMonthlyData()
                extendedMonthlyReturns       = historicalBTCMonthlyReturns
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
