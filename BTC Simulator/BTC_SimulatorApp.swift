//
//  BTC_SimulatorApp.swift
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

    // Show the consent alert if no decision has been recorded.
    @State private var showConsent: Bool = UserDefaults.standard.object(forKey: "SentryConsentGiven") == nil

    @StateObject private var appViewModel: AppViewModel
    @StateObject private var inputManager: PersistentInputManager
    @StateObject private var simSettings: SimulationSettings
    @StateObject private var chartDataCache: ChartDataCache
    @StateObject private var simChartSelection: SimChartSelection
    @StateObject private var coordinator: SimulationCoordinator

    init() {
        // Initialise Sentry SDK
        SentrySDK.start { options in
            options.dsn = "https://3ca36373246f91c44a0733a5d9489f52@o4508788421623808.ingest.de.sentry.io/4508788424376400"
            options.attachViewHierarchy = false
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
            options.enableAppLaunchProfiling = true
        }
        
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
        
        // Create local instances first
        let appViewModelInstance = AppViewModel()
        let inputManagerInstance = PersistentInputManager()
        let simSettingsInstance = SimulationSettings(loadDefaults: true)
        let chartDataCacheInstance = ChartDataCache()
        let simChartSelectionInstance = SimChartSelection()
        let coordinatorInstance = SimulationCoordinator(
            chartDataCache: chartDataCacheInstance,
            simSettings: simSettingsInstance,
            inputManager: inputManagerInstance,
            simChartSelection: simChartSelectionInstance
        )

        // Then assign to the StateObjects
        _appViewModel = StateObject(wrappedValue: appViewModelInstance)
        _inputManager = StateObject(wrappedValue: inputManagerInstance)
        _simSettings = StateObject(wrappedValue: simSettingsInstance)
        _chartDataCache = StateObject(wrappedValue: chartDataCacheInstance)
        _simChartSelection = StateObject(wrappedValue: simChartSelectionInstance)
        _coordinator = StateObject(wrappedValue: coordinatorInstance)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.black.ignoresSafeArea()

                GeometryReader { geo in
                    Color.clear
                        .onAppear { appViewModel.windowSize = geo.size }
                        .onChange(of: geo.size) { _, newSize in appViewModel.windowSize = newSize }
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
            .alert("Data Collection Consent", isPresented: $showConsent) {
                Button("No", role: .cancel) {
                    UserDefaults.standard.set(false, forKey: "SentryConsentGiven")
                    showConsent = false
                }
                Button("Yes") {
                    UserDefaults.standard.set(true, forKey: "SentryConsentGiven")
                    SentrySDK.start { options in
                        options.dsn = "https://3ca36373246f91c44a0733a5d9489f52@o4508788421623808.ingest.de.sentry.io/4508788424376400"
                        options.attachViewHierarchy = false
                        options.enableMetricKit = true
                        options.enableTimeToFullDisplayTracing = true
                        options.swiftAsyncStacktraces = true
                        options.enableAppLaunchProfiling = true
                    }
                    showConsent = false
                }
            } message: {
                Text("We collect error logs and usage data to improve the app. Do you consent to share this data?")
            }
            .onAppear {
                simSettings.isOnboarding = !didFinishOnboarding

                historicalBTCWeeklyReturns = loadAndAlignWeeklyData()
                extendedWeeklyReturns = historicalBTCWeeklyReturns

                historicalBTCMonthlyReturns = loadAndAlignMonthlyData()
                extendedMonthlyReturns = historicalBTCMonthlyReturns
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    simSettings.saveToUserDefaults()
                }
            }
        }
    }
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var windowSize: CGSize = .zero
}
