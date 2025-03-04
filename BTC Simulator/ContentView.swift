//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/11/2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import PocketSVG
import UIKit

// MARK: - PersistentInputManager
class PersistentInputManager: ObservableObject {
    @Published var generateGraphs: Bool {
        didSet {
            UserDefaults.standard.set(generateGraphs, forKey: "generateGraphs")
        }
    }
    
    @Published var firstYearContribution: String { didSet {
        UserDefaults.standard.set(firstYearContribution, forKey: "firstYearContribution")
    }}
    @Published var iterations: String { didSet {
        UserDefaults.standard.set(iterations, forKey: "iterations")
    }}
    @Published var annualCAGR: String { didSet {
        UserDefaults.standard.set(annualCAGR, forKey: "annualCAGR")
    }}
    @Published var annualVolatility: String { didSet {
        UserDefaults.standard.set(annualVolatility, forKey: "annualVolatility")
    }}
    @Published var standardDeviation: String { didSet {
        UserDefaults.standard.set(standardDeviation, forKey: "standardDeviation")
    }}
    @Published var selectedWeek: String { didSet {
        UserDefaults.standard.set(selectedWeek, forKey: "selectedWeek")
    }}
    @Published var btcPriceMinInput: String { didSet {
        UserDefaults.standard.set(btcPriceMinInput, forKey: "btcPriceMinInput")
    }}
    @Published var btcPriceMaxInput: String { didSet {
        UserDefaults.standard.set(btcPriceMaxInput, forKey: "btcPriceMaxInput")
    }}
    @Published var portfolioValueMinInput: String { didSet {
        UserDefaults.standard.set(portfolioValueMinInput, forKey: "portfolioValueMinInput")
    }}
    @Published var portfolioValueMaxInput: String { didSet {
        UserDefaults.standard.set(portfolioValueMaxInput, forKey: "portfolioValueMaxInput")
    }}
    @Published var btcHoldingsMinInput: String { didSet {
        UserDefaults.standard.set(btcHoldingsMinInput, forKey: "btcHoldingsMinInput")
    }}
    @Published var btcHoldingsMaxInput: String { didSet {
        UserDefaults.standard.set(btcHoldingsMaxInput, forKey: "btcHoldingsMaxInput")
    }}
    @Published var btcGrowthRate: String { didSet {
        UserDefaults.standard.set(btcGrowthRate, forKey: "btcGrowthRate")
    }}
    
    // Doubles
    @Published var threshold1: Double { didSet {
        UserDefaults.standard.set(threshold1, forKey: "threshold1")
    }}
    @Published var withdrawAmount1: Double { didSet {
        UserDefaults.standard.set(withdrawAmount1, forKey: "withdrawAmount1")
    }}
    @Published var threshold2: Double { didSet {
        UserDefaults.standard.set(threshold2, forKey: "threshold2")
    }}
    @Published var withdrawAmount2: Double { didSet {
        UserDefaults.standard.set(withdrawAmount2, forKey: "withdrawAmount2")
    }}
    
    init() {
        if UserDefaults.standard.object(forKey: "generateGraphs") == nil {
            self.generateGraphs = true
        } else {
            self.generateGraphs = UserDefaults.standard.bool(forKey: "generateGraphs")
        }
        
        self.firstYearContribution    = UserDefaults.standard.string(forKey: "firstYearContribution") ?? "100"
        self.iterations              = UserDefaults.standard.string(forKey: "iterations") ?? "50"
        self.annualCAGR              = UserDefaults.standard.string(forKey: "annualCAGR") ?? "30"
        self.annualVolatility        = UserDefaults.standard.string(forKey: "annualVolatility") ?? "80"
        self.standardDeviation       = UserDefaults.standard.string(forKey: "standardDeviation") ?? "150"
        self.selectedWeek            = UserDefaults.standard.string(forKey: "selectedWeek") ?? "1"
        self.btcPriceMinInput        = UserDefaults.standard.string(forKey: "btcPriceMinInput") ?? ""
        self.btcPriceMaxInput        = UserDefaults.standard.string(forKey: "btcPriceMaxInput") ?? ""
        self.portfolioValueMinInput  = UserDefaults.standard.string(forKey: "portfolioValueMinInput") ?? ""
        self.portfolioValueMaxInput  = UserDefaults.standard.string(forKey: "portfolioValueMaxInput") ?? ""
        self.btcHoldingsMinInput     = UserDefaults.standard.string(forKey: "btcHoldingsMinInput") ?? ""
        self.btcHoldingsMaxInput     = UserDefaults.standard.string(forKey: "btcHoldingsMaxInput") ?? ""
        self.btcGrowthRate           = UserDefaults.standard.string(forKey: "btcGrowthRate") ?? "0.005"
        
        let storedT1 = UserDefaults.standard.double(forKey: "threshold1")
        self.threshold1 = (storedT1 != 0.0) ? storedT1 : 30000.0
        
        let storedW1 = UserDefaults.standard.double(forKey: "withdrawAmount1")
        self.withdrawAmount1 = (storedW1 != 0.0) ? storedW1 : 0.0
        
        let storedT2 = UserDefaults.standard.double(forKey: "threshold2")
        self.threshold2 = (storedT2 != 0.0) ? storedT2 : 60000.0
        
        let storedW2 = UserDefaults.standard.double(forKey: "withdrawAmount2")
        self.withdrawAmount2 = (storedW2 != 0.0) ? storedW2 : 0.0
    }

    func saveToDefaults() {
        UserDefaults.standard.set(firstYearContribution, forKey: "firstYearContribution")
        UserDefaults.standard.set(iterations, forKey: "iterations")
        UserDefaults.standard.set(annualCAGR, forKey: "annualCAGR")
        UserDefaults.standard.set(annualVolatility, forKey: "annualVolatility")
        UserDefaults.standard.set(standardDeviation, forKey: "standardDeviation")
        UserDefaults.standard.set(selectedWeek, forKey: "selectedWeek")
        UserDefaults.standard.set(btcPriceMinInput, forKey: "btcPriceMinInput")
        UserDefaults.standard.set(btcPriceMaxInput, forKey: "btcPriceMaxInput")
        UserDefaults.standard.set(portfolioValueMinInput, forKey: "portfolioValueMinInput")
        UserDefaults.standard.set(portfolioValueMaxInput, forKey: "portfolioValueMaxInput")
        UserDefaults.standard.set(btcHoldingsMinInput, forKey: "btcHoldingsMinInput")
        UserDefaults.standard.set(btcHoldingsMaxInput, forKey: "btcHoldingsMaxInput")
        UserDefaults.standard.set(btcGrowthRate, forKey: "btcGrowthRate")
        UserDefaults.standard.set(threshold1, forKey: "threshold1")
        UserDefaults.standard.set(withdrawAmount1, forKey: "withdrawAmount1")
        UserDefaults.standard.set(threshold2, forKey: "threshold2")
        UserDefaults.standard.set(withdrawAmount2, forKey: "withdrawAmount2")
    }

    func updateValue<T>(_ keyPath: ReferenceWritableKeyPath<PersistentInputManager, T>, to newValue: T) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self[keyPath: keyPath] = newValue
            self.saveToDefaults()
        }
    }

    func getParsedIterations() -> Int? {
        Int(iterations.replacingOccurrences(of: ",", with: ""))
    }

    func getParsedAnnualCAGR() -> Double {
        let rawValue = annualCAGR.replacingOccurrences(of: ",", with: "")
        guard let parsedValue = Double(rawValue) else {
            return 0.0
        }
        return min(parsedValue, 1000.0)
    }
}

// MARK: - Formatters
extension Double {
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    func formattedBTC() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// MARK: - Suffix Logic
extension Double {
    func formattedWithPowerOfTenSuffix() -> String {
        guard self != 0 else { return "0" }
        let sign = self < 0 ? "-" : ""
        let absVal = abs(self)
        let exponent = Int(floor(log10(absVal)))
        if exponent < 3 {
            return sign + normalNumberFormat(absVal)
        }
        if exponent > 30 {
            return "\(sign)\(String(format: "%.2f", absVal))"
        }
        let leadingNumber = absVal / pow(10, Double(exponent))
        let suffix = formatPowerOfTenLabel(exponent)
        return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
    }
}

fileprivate func normalNumberFormat(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    formatter.usesGroupingSeparator = true
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

// MARK: - ChartLoadingState
fileprivate enum ChartLoadingState {
    case none, loading, cancelled
}

// MARK: - ChartDataCache
class ChartDataCache: ObservableObject {
    let id = UUID()
    
    // These let you store your x-range directly
    @Published var minX: Float = 0
    @Published var maxX: Float = 0

    @Published var allRuns: [SimulationRun]? = nil
    @Published var portfolioRuns: [SimulationRun]? = nil
    @Published var bestFitRun: [SimulationRun]? = nil
    @Published var bestFitPortfolioRun: [SimulationRun]? = nil
    @Published var storedInputsHash: Int? = nil

    @Published var chartSnapshot: UIImage? = nil
    @Published var chartSnapshotLandscape: UIImage? = nil
    @Published var portfolioChartSnapshot: UIImage? = nil
    @Published var portfolioChartSnapshotLandscape: UIImage? = nil
    @Published var chartSnapshotPortfolio: UIImage? = nil
    @Published var chartSnapshotPortfolioLandscape: UIImage? = nil
    
    init() {}
}

// MARK: - ContentView
struct ContentView: View {

    // Some local states for text, etc.
    @State private var oldIterationsValue: String = ""
    @State private var oldAnnualCAGRValue: String = ""
    @State private var oldAnnualVolatilityValue: String = ""
    @State private var oldStandardDevValue: String = ""

    @State private var localIterations: String = ""
    @State private var localAnnualCAGR: String = ""
    @State private var localAnnualVolatility: String = ""
    @State private var localStandardDev: String = ""

    @FocusState private var activeField: ActiveField?

    @State private var lastViewedWeek: Int = 0
    @State private var scrollToBottom: Bool = false
    @State private var lastScrollTime = Date()
    @State private var contentScrollProxy: ScrollViewProxy?

    @State private var currentPage: Int = 0
    @State private var lastViewedPage: Int = 0

    @State private var currentTip: String = ""
    @State private var showTip: Bool = false
    @State private var tipTimer: Timer? = nil

    @State private var hideScrollIndicators = true
    @State private var isKeyboardVisible: Bool = false

    @AppStorage("advancedSettingsUnlocked") private var advancedSettingsUnlocked: Bool = false

    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showHistograms = false
    @State private var showGraphics = false

    @State private var tenthPercentileResults: [SimulationData] = []
    @State private var medianResults: [SimulationData] = []
    @State private var ninetiethPercentileResults: [SimulationData] = []
    @State private var selectedPercentile: PercentileChoice = .median

    @State private var allSimData: [[SimulationData]] = []

    @State private var chartLoadingState: ChartLoadingState = .none
    @State private var showSnapshotView = false
    @State private var showSnapshotsDebug = false

    @State private var showPinnedColumns = false
    @State private var lastViewedRow: Int = 0

    @State private var lastViewedColumnIndex: Int = {
        let stored = UserDefaults.standard.object(forKey: "LastViewedColumnIndex") as? Int
        return stored ?? 2  // If no stored value, default to 2
    }()
    
    @State private var showTestHarness = false

    // MARK: - Environment Objects
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var coordinator: SimulationCoordinator
    @EnvironmentObject var simChartSelection: SimChartSelection
    @EnvironmentObject var textRendererManager: TextRendererManager // Add this line for text rendering
    @EnvironmentObject var idleManager: IdleManager
    
    // IdleManager to manage idle state
    // @StateObject private var idleManager = IdleManager()

    var body: some View {
        NavigationStack {
            ZStack {
                // -----------------
                // 1) Main parameter screen
                // -----------------
                parametersScreen

                // 2) Bottom icons bar (only if not loading/keyboard)
                if !coordinator.isLoading && !coordinator.isChartBuilding && !isKeyboardVisible {
                    bottomIcons
                }

                // 3) Loading overlay if coordinator is busy
                if coordinator.isLoading || coordinator.isChartBuilding {
                    LoadingOverlayView()
                        .environmentObject(coordinator)
                        .environmentObject(simSettings)
                }
                
                // 4) **Add a debug button** to navigate to TestHarnessView
                VStack {
                    Spacer()
                    Button("Go to Test Harness") {
                        showTestHarness = true
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            
            // Existing navigation destinations
            .navigationDestination(isPresented: $showPinnedColumns) {
                PinnedColumnBridgeRepresentable(
                    isPresented: $showPinnedColumns,
                    lastViewedRow: $lastViewedRow,
                    lastViewedColumnIndex: $lastViewedColumnIndex,
                    coordinator: coordinator,
                    inputManager: inputManager,
                    monthlySimSettings: monthlySimSettings,
                    simSettings: simSettings,
                    simChartSelection: simChartSelection,
                    chartDataCache: chartDataCache
                )
                .environmentObject(idleManager)
                .fullBleedStyle()
                .onAppear {
                    removeNavBarHairline()
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(simSettings)
                    .environmentObject(monthlySimSettings)
                    .environmentObject(coordinator)
                    .onAppear {
                        removeNavBarHairline()
                    }
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
                    .onAppear {
                        removeNavBarHairline()
                    }
            }

            // 5) **New** navigation destination for the test harness
            .navigationDestination(isPresented: $showTestHarness) {
                TestHarnessView()  // <--- Provide your harness here
                    .onAppear {
                        removeNavBarHairline()
                    }
            }
        }
        .onAppear {
            // Generate font atlas when content view appears
            textRendererManager.generateFontAtlasAndRenderer(device: MTLCreateSystemDefaultDevice()!)
            
            // Shift back button title off-screen globally
            UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(
                UIOffset(horizontal: -1000, vertical: 0),
                for: .default
            )
            removeNavBarHairline()
            
            // If you want to reset idle time here:
            // idleManager.resetIdleTimer()
        }
        .onChange(of: coordinator.isLoading) { oldValue, newValue in
            if newValue {
                lastViewedColumnIndex = 2
                lastViewedRow = 0
                print("DEBUG: Forcing lastViewedColumnIndex to default (2) and lastViewedRow to default (0) on new simulation start.")
            }
        }
        .onChange(of: coordinator.isChartBuilding) { oldValue, newValue in
            checkNavigationState()
        }
        .onTapGesture {
            // If you want to reset idle time on taps:
            // idleManager.resetIdleTimer()
        }
    }

    // MARK: - Parameter Screen
    private var parametersScreen: some View {
        ParameterEntryView(
            inputManager: inputManager,
            simSettings: simSettings,
            coordinator: coordinator,
            isKeyboardVisible: $isKeyboardVisible,
            showPinnedColumns: $showPinnedColumns
        )
        // .environmentObject(idleManager)
    }

    // MARK: - Bottom Icons
    private var bottomIcons: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: { showAbout = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding()
                }
                .padding(.leading, 15)

                Spacer()

                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding()
                }
                .padding(.trailing, 15)
            }
            .padding(.bottom, 30)
        }
    }

    // MARK: - Logic for Navigation
    private func checkNavigationState() {
        // Example logic that auto-navigates to pinned columns after simulation
        if !coordinator.isLoading,
           !coordinator.isChartBuilding,
           !coordinator.monteCarloResults.isEmpty
        {
            showPinnedColumns = true
        }
    }

    private func navigateIfNeeded() {
        if !coordinator.isLoading && !coordinator.isChartBuilding {
            showPinnedColumns = true
        }
    }

    // MARK: - Remove Nav Bar Hairline
    private func removeNavBarHairline() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    /*
    // If you still want references to old transitions or overrides:
    private var transitionToResultsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    coordinator.isSimulationRun = true
                    currentPage = lastViewedPage
                    // old pinned columns logic
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .padding()
                }
            }
            Spacer()
        }
    }
    */

    // MARK: - Example Columns
    // If needed for something else, you can pass this to the bridging representable
    private var columns: [(String, PartialKeyPath<SimulationData>)] {
        switch simSettings.currencyPreference {
        case .usd:
            return [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (USD)", \SimulationData.btcPriceUSD),
                ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
                ("Contrib (USD)", \SimulationData.contributionUSD),
                ("Fee (USD)", \SimulationData.transactionFeeUSD),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw (USD)", \SimulationData.withdrawalUSD)
            ]
        case .eur:
            return [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (EUR)", \SimulationData.btcPriceEUR),
                ("Portfolio (EUR)", \SimulationData.portfolioValueEUR),
                ("Contrib (EUR)", \SimulationData.contributionEUR),
                ("Fee (EUR)", \SimulationData.transactionFeeEUR),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw (EUR)", \SimulationData.withdrawalEUR)
            ]
        case .both:
            return [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price USD", \SimulationData.btcPriceUSD),
                ("BTC Price EUR", \SimulationData.btcPriceEUR),
                ("Portfolio USD", \SimulationData.portfolioValueUSD),
                ("Portfolio EUR", \SimulationData.portfolioValueEUR),
                ("Contrib USD", \SimulationData.contributionUSD),
                ("Contrib EUR", \SimulationData.contributionEUR),
                ("Fee USD", \SimulationData.transactionFeeUSD),
                ("Fee EUR", \SimulationData.transactionFeeEUR),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw USD", \SimulationData.withdrawalUSD),
                ("Withdraw EUR", \SimulationData.withdrawalEUR)
            ]
        }
    }
}

extension View {
    @ViewBuilder
    func fullBleedStyle() -> some View {
        if #available(iOS 16.0, *) {
            // iOS 16 style – e.g. hide the nav bar using .toolbarBackground
            self
                .toolbarBackground(.hidden, for: .navigationBar)
                .ignoresSafeArea(.all, edges: .top)
        } else {
            // Older iOS fallback – use .navigationBarHidden instead
            self
                .navigationBarHidden(true)
                .navigationBarBackButtonHidden(true)
                .ignoresSafeArea(.all, edges: .top)
        }
    }
}
