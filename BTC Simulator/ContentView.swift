/*
-----------------------------------------------------------
                CONTENT VIEW
                   BTC MONTE CARLO
                 (HODL SIMULATOR)
-----------------------------------------------------------
Description:
 This file implements the main user interface for the HODL Simulator. It combines multiple components to:
 • Allow users to configure simulation parameters via an interactive input form.
 • Manage and display simulation results, including detailed charts and summary views.
 • Coordinate navigation between settings, about, and histogram/chart detail screens.
 • Integrate persistent input management, chart data caching, and simulation coordination.
 • Provide custom data formatting (e.g., currency and power-of-ten suffixes) for numerical values.

Key Components:
 • PersistentInputManager:
   - Manages user inputs and persists simulation parameters using UserDefaults.
 • ChartDataCache:
   - Caches simulation run data and chart snapshots for efficient rendering.
 • ContentView:
   - Acts as the main entry point, toggling between the parameter input screen and the simulation
     results view based on the simulation state.
 • Navigation & Interaction:
   - Supports navigation to Settings, About, and additional views with bottom icons and transition buttons.
 • Data Formatting:
   - Provides extensions for formatting numeric values for display in the simulation results.

Usage:
 When the app launches, ContentView displays the configuration form for simulation parameters. After
 running a simulation, the view transitions to display the results along with interactive charts and
 detailed summaries, making it easy to explore various simulation outcomes.

-----------------------------------------------------------
Created on 20/11/2024.
-----------------------------------------------------------
*/

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

    @Published var firstYearContribution: String {
        didSet { UserDefaults.standard.set(firstYearContribution, forKey: "firstYearContribution") }
    }
    @Published var subsequentContribution: String {
        didSet { UserDefaults.standard.set(subsequentContribution, forKey: "subsequentContribution") }
    }
    @Published var iterations: String {
        didSet { UserDefaults.standard.set(iterations, forKey: "iterations") }
    }
    @Published var annualCAGR: String {
        didSet { UserDefaults.standard.set(annualCAGR, forKey: "annualCAGR") }
    }
    @Published var annualVolatility: String {
        didSet { UserDefaults.standard.set(annualVolatility, forKey: "annualVolatility") }
    }
    @Published var standardDeviation: String {
        didSet { UserDefaults.standard.set(standardDeviation, forKey: "standardDeviation") }
    }
    @Published var selectedWeek: String {
        didSet { UserDefaults.standard.set(selectedWeek, forKey: "selectedWeek") }
    }
    @Published var btcPriceMinInput: String {
        didSet { UserDefaults.standard.set(btcPriceMinInput, forKey: "btcPriceMinInput") }
    }
    @Published var btcPriceMaxInput: String {
        didSet { UserDefaults.standard.set(btcPriceMaxInput, forKey: "btcPriceMaxInput") }
    }
    @Published var portfolioValueMinInput: String {
        didSet { UserDefaults.standard.set(portfolioValueMinInput, forKey: "portfolioValueMinInput") }
    }
    @Published var portfolioValueMaxInput: String {
        didSet { UserDefaults.standard.set(portfolioValueMaxInput, forKey: "portfolioValueMaxInput") }
    }
    @Published var btcHoldingsMinInput: String {
        didSet { UserDefaults.standard.set(btcHoldingsMinInput, forKey: "btcHoldingsMinInput") }
    }
    @Published var btcHoldingsMaxInput: String {
        didSet { UserDefaults.standard.set(btcHoldingsMaxInput, forKey: "btcHoldingsMaxInput") }
    }
    @Published var btcGrowthRate: String {
        didSet { UserDefaults.standard.set(btcGrowthRate, forKey: "btcGrowthRate") }
    }

    // Doubles
    @Published var threshold1: Double {
        didSet { UserDefaults.standard.set(threshold1, forKey: "threshold1") }
    }
    @Published var withdrawAmount1: Double {
        didSet { UserDefaults.standard.set(withdrawAmount1, forKey: "withdrawAmount1") }
    }
    @Published var threshold2: Double {
        didSet { UserDefaults.standard.set(threshold2, forKey: "threshold2") }
    }
    @Published var withdrawAmount2: Double {
        didSet { UserDefaults.standard.set(withdrawAmount2, forKey: "withdrawAmount2") }
    }

    init() {
        // If "generateGraphs" doesn't exist yet, default to true
        if UserDefaults.standard.object(forKey: "generateGraphs") == nil {
            self.generateGraphs = true
        } else {
            self.generateGraphs = UserDefaults.standard.bool(forKey: "generateGraphs")
        }

        self.firstYearContribution = UserDefaults.standard.string(forKey: "firstYearContribution") ?? "100"
        self.subsequentContribution = UserDefaults.standard.string(forKey: "subsequentContribution") ?? "100"
        self.iterations = UserDefaults.standard.string(forKey: "iterations") ?? "100"
        self.annualCAGR = UserDefaults.standard.string(forKey: "annualCAGR") ?? "30"
        self.annualVolatility = UserDefaults.standard.string(forKey: "annualVolatility") ?? "80"
        self.standardDeviation = UserDefaults.standard.string(forKey: "standardDeviation") ?? "150"
        self.selectedWeek = UserDefaults.standard.string(forKey: "selectedWeek") ?? "1"
        self.btcPriceMinInput = UserDefaults.standard.string(forKey: "btcPriceMinInput") ?? ""
        self.btcPriceMaxInput = UserDefaults.standard.string(forKey: "btcPriceMaxInput") ?? ""
        self.portfolioValueMinInput = UserDefaults.standard.string(forKey: "portfolioValueMinInput") ?? ""
        self.portfolioValueMaxInput = UserDefaults.standard.string(forKey: "portfolioValueMaxInput") ?? ""
        self.btcHoldingsMinInput = UserDefaults.standard.string(forKey: "btcHoldingsMinInput") ?? ""
        self.btcHoldingsMaxInput = UserDefaults.standard.string(forKey: "btcHoldingsMaxInput") ?? ""
        self.btcGrowthRate = UserDefaults.standard.string(forKey: "btcGrowthRate") ?? "0.005"

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
        UserDefaults.standard.set(subsequentContribution, forKey: "subsequentContribution")
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

    /// Clamps annualCAGR to 1000 if user typed something above that.
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
    /// For large numeric values using the short scale up to 10^30 (nonillion):
    ///  - If exponent < 3 => just show normal comma formatting.
    ///  - If exponent is between 3 and 30 => show K, M, B, T, Q, Qi, Sx, Sp, Oc, No.
    ///  - If exponent > 30 => fallback to plain decimal with 2 decimals.
    func formattedWithPowerOfTenSuffix() -> String {
        guard self != 0 else { return "0" }

        let sign = self < 0 ? "-" : ""
        let absVal = abs(self)
        let exponent = Int(floor(log10(absVal)))

        // Under 1,000 => just format normally
        if exponent < 3 {
            return sign + normalNumberFormat(absVal)
        }

        // If exponent is above 30 => fallback
        if exponent > 30 {
            return "\(sign)\(String(format: "%.2f", absVal))"
        }

        // Otherwise, find the 'leading number' and suffix:
        let leadingNumber = absVal / pow(10, Double(exponent))
        let suffix = formatPowerOfTenLabel(exponent)
        return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
    }
}

/// Helper for standard comma formatting
private func normalNumberFormat(_ value: Double) -> String {
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
    let id = UUID()  // Track the identity

    /// All Monte Carlo runs (BTC price)
    @Published var allRuns: [SimulationRun]? = nil

    /// Additional (portfolio) runs
    @Published var portfolioRuns: [SimulationRun]? = nil

    /// The single best-fit run for BTC price (orange line)
    @Published var bestFitRun: [SimulationRun]? = nil

    /// The single best-fit run for portfolio (if needed)
    @Published var bestFitPortfolioRun: [SimulationRun]? = nil

    /// A hash of user inputs, used to see if the chart is stale or needs refreshing
    @Published var storedInputsHash: Int? = nil

    // For iOS, store a snapshot as UIImage
    @Published var chartSnapshot: UIImage? = nil
    @Published var chartSnapshotLandscape: UIImage? = nil

    @Published var portfolioChartSnapshot: UIImage? = nil
    @Published var portfolioChartSnapshotLandscape: UIImage? = nil

    // Alternatively named:
    @Published var chartSnapshotPortfolio: UIImage? = nil
    @Published var chartSnapshotPortfolioLandscape: UIImage? = nil

    init() { }
}

struct ContentView: View {
    // Track old values so we can invalidate the chart if needed
    @State private var oldIterationsValue: String = ""
    @State private var oldAnnualCAGRValue: String = ""
    @State private var oldAnnualVolatilityValue: String = ""
    @State private var oldStandardDevValue: String = ""
    
    // Instead of binding text fields directly to inputManager, we use local text states:
    @State private var localIterations: String = ""
    @State private var localAnnualCAGR: String = ""
    @State private var localAnnualVolatility: String = ""
    @State private var localStandardDev: String = ""
    
    // Focus for text fields
    @FocusState private var activeField: ActiveField?
    
    @State private var isAtBottom: Bool = false
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
    
    private var loadingTips: [String] { TipsData.filteredLoadingTips(for: simSettings) }
    private var usageTips: [String] { TipsData.filteredUsageTips(for: simSettings) }
    
    // Columns in the table view
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
    
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    // MARK: - Body
        var body: some View {
            NavigationStack {
                ZStack {
                    if !coordinator.isSimulationRun {
                        
                        // Embed ParameterEntryView directly
                        ParameterEntryView(
                            inputManager: inputManager,
                            simSettings: simSettings,
                            coordinator: coordinator,
                            isKeyboardVisible: $isKeyboardVisible
                        )
                        
                        // Hide bottom icons if loading or keyboard is up
                        if !coordinator.isLoading && !isKeyboardVisible {
                            bottomIcons
                        }
                    } else {
                        simulationResultsView
                    }
                    
                    if !coordinator.isSimulationRun &&
                        !coordinator.monteCarloResults.isEmpty &&
                        !coordinator.isChartBuilding {
                        transitionToResultsButton
                    }
                    
                    if coordinator.isLoading || coordinator.isChartBuilding {
                        loadingOverlayCombined
                    }
                }
                .navigationDestination(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(simSettings)
                        .environmentObject(monthlySimSettings)
                }
                .navigationDestination(isPresented: $showAbout) {
                    AboutView()
                }
                .onAppear {
                    // You can remove these lines if your ParameterEntryView
                    // now handles loading the persisted values.
                    localIterations = inputManager.iterations
                    localAnnualCAGR = inputManager.annualCAGR
                    localAnnualVolatility = inputManager.annualVolatility
                    localStandardDev = inputManager.standardDeviation
                    
                    // Keep the user-defaults logic for results table:
                    if UserDefaults.standard.object(forKey: "lastViewedPage") == nil {
                        if let btcPriceIndex = columns.firstIndex(where: { $0.0.contains("BTC Price") }) {
                            currentPage = btcPriceIndex
                            lastViewedPage = btcPriceIndex
                        }
                    } else {
                        let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
                        if savedWeek != 0 {
                            lastViewedWeek = savedWeek
                        }
                        let savedPage = UserDefaults.standard.integer(forKey: "lastViewedPage")
                        if savedPage < columns.count {
                            lastViewedPage = savedPage
                            currentPage = savedPage
                        } else if let usdIndex = columns.firstIndex(where: { $0.0.contains("BTC Price") }) {
                            currentPage = usdIndex
                            lastViewedPage = usdIndex
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showHistograms) {
                ForceReflowView {
                    if let existingChartData = coordinator.chartDataCache.allRuns {
                        MonteCarloResultsView()
                            .environmentObject(coordinator.chartDataCache)
                            .environmentObject(simSettings)
                            .environmentObject(coordinator.simChartSelection)
                    } else {
                        Text("Loading chart…")
                            .foregroundColor(.white)
                    }
                }
            }
        }

    // MARK: - Parameter Screen
    private var parametersScreen: some View {
        // Simply embed the new ParameterEntryView here:
        ParameterEntryView(
            inputManager: inputManager,
            simSettings: simSettings,
            coordinator: coordinator,
            isKeyboardVisible: $isKeyboardVisible
        )
    }
    
    // MARK: - Bottom icons
    @ViewBuilder
    private var bottomIcons: some View {
        if !coordinator.isLoading && !coordinator.isChartBuilding {
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
    }
    
    // MARK: - Simulation Results Screen
    private var simulationResultsView: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                Color(white: 0.12)
                    .edgesIgnoringSafeArea(.bottom)
                
                VStack(spacing: 0) {
                    
                    HStack {
                        Button(action: {
                            UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                            UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                            lastViewedPage = currentPage
                            coordinator.isSimulationRun = false
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .frame(width: 40, height: 40)
                        }
                        .padding(.leading, 42)
                        
                        Spacer()
                        
                        Text("Simulation Results")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            showHistograms = true
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(inputManager.generateGraphs ? .white : .gray)
                                .imageScale(.large)
                                .frame(width: 40, height: 40)
                        }
                        .disabled(!inputManager.generateGraphs)
                        .padding(.trailing, 42)
                    }
                    .padding(.vertical, 10)
                    .background(Color(white: 0.12))
                    
                    let (finalBTCPrice, finalPortfolioValue, growthPercent, currencySymbol) = calculateSummaryValues()
                    
                    SimulationSummaryCardView(
                        finalBTCPrice: finalBTCPrice,
                        finalPortfolioValue: finalPortfolioValue,
                        growthPercent: growthPercent,
                        currencySymbol: currencySymbol
                    )
                    
                    HStack(spacing: 0) {
                        Text(simSettings.periodUnit == .weeks ? "Week" : "Month")
                            .frame(width: 60, alignment: .leading)
                            .font(.headline)
                            .padding(.leading, 50)
                            .padding(.vertical, 8)
                            .background(Color.black)
                            .foregroundColor(.orange)
                        
                        ZStack {
                            Text(columns[currentPage].0)
                                .font(.headline)
                                .padding(.leading, 100)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.2)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if currentPage > 0 {
                                                withAnimation { currentPage -= 1 }
                                            }
                                        }
                                    Spacer()
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.2)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if currentPage < columns.count - 1 {
                                                withAnimation { currentPage += 1 }
                                            }
                                        }
                                }
                            }
                        }
                        .frame(height: 50)
                    }
                    .background(Color.black)
                    
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                        
                        let displayedResults = coordinator.monteCarloResults
                        
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ForEach(displayedResults.indices, id: \.self) { index in
                                    let result = displayedResults[index]
                                    let rowBackground = index.isMultiple(of: 2)
                                        ? Color(white: 0.10)
                                        : Color(white: 0.14)
                                    
                                    Text("\(result.week)")
                                        .frame(width: 70, alignment: .leading)
                                        .padding(.leading, 50)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(rowBackground)
                                        .foregroundColor(.white)
                                        .id("week-\(result.week)")
                                        .background(RowOffsetReporter(week: result.week))
                                }
                            }
                            
                            TabView(selection: $currentPage) {
                                ForEach(0..<columns.count, id: \.self) { idx in
                                    ZStack {
                                        VStack(spacing: 0) {
                                            ForEach(displayedResults.indices, id: \.self) { rowIndex in
                                                let rowResult = displayedResults[rowIndex]
                                                let rowBackground = rowIndex.isMultiple(of: 2)
                                                    ? Color(white: 0.10)
                                                    : Color(white: 0.14)
                                                
                                                Text(getValueForTable(rowResult, columns[idx].1))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.leading, 80)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 8)
                                                    .background(rowBackground)
                                                    .foregroundColor(.white)
                                                    .id("data-week-\(rowResult.week)")
                                                    .background(RowOffsetReporter(week: rowResult.week))
                                            }
                                        }
                                        GeometryReader { geometry in
                                            HStack(spacing: 0) {
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        if currentPage > 0 {
                                                            withAnimation { currentPage -= 1 }
                                                        }
                                                    }
                                                Spacer()
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        if currentPage < columns.count - 1 {
                                                            withAnimation { currentPage += 1 }
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                    .tag(idx)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(width: UIScreen.main.bounds.width - 60)
                        }
                        .coordinateSpace(name: "scrollArea")
                        .onPreferenceChange(RowOffsetPreferenceKey.self) { offsets in
                            let targetY: CGFloat = 160 + 120
                            let finalWeeks = simSettings.userPeriods
                            
                            let filtered = offsets.filter { (week, _) in
                                week >= 0 && week <= finalWeeks
                            }
                            let mapped = filtered.mapValues { abs($0 - targetY) }
                            
                            if let (closestWeek, _) = mapped.min(by: { $0.value < $1.value }) {
                                lastViewedWeek = closestWeek
                            }
                        }
                        .onChange(of: scrollToBottom, initial: false) { _, value in
                            if value, let lastResult = coordinator.monteCarloResults.last {
                                withAnimation {
                                    scrollProxy.scrollTo("week-\(lastResult.week)", anchor: .bottom)
                                }
                                scrollToBottom = false
                            }
                        }
                        .background(
                            GeometryReader { geometry -> Color in
                                DispatchQueue.main.async {
                                    let atBottom = geometry.frame(in: .global).maxY <= UIScreen.main.bounds.height
                                    if atBottom != isAtBottom {
                                        isAtBottom = atBottom
                                    }
                                }
                                return Color(white: 0.12)
                            }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    hideScrollIndicators = false
                                    lastScrollTime = Date()
                                }
                                .onEnded { _ in
                                    lastScrollTime = Date()
                                }
                        )
                    }
                    .onReceive(
                        Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
                    ) { _ in
                        if Date().timeIntervalSince(lastScrollTime) > 1.5 {
                            hideScrollIndicators = true
                        }
                    }
                }
                .onAppear {
                    contentScrollProxy = scrollProxy
                }
                .onDisappear {
                    UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                if !isAtBottom {
                    VStack {
                        Spacer()
                        Button(action: {
                            scrollToBottom = true
                        }) {
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding()
                                .background(Color(white: 0.2).opacity(0.9))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private func calculateSummaryValues() -> (Double, Double, Double, String) {
        guard let lastRow = coordinator.monteCarloResults.last else {
            return (0, 0, 0, "$")
        }
        
        let finalBTC = simSettings.currencyPreference == .eur
            ? NSDecimalNumber(decimal: lastRow.btcPriceEUR).doubleValue
            : NSDecimalNumber(decimal: lastRow.btcPriceUSD).doubleValue
        
        let finalPortfolio: Double
        if simSettings.currencyPreference == .eur {
            finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueEUR).doubleValue
        } else {
            finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueUSD).doubleValue
        }
        
        let totalContributions = coordinator.monteCarloResults.reduce(0.0) { partialSum, row in
            partialSum + row.contributionUSD
        }
        
        var growth = 0.0
        if totalContributions > 0 {
            growth = (finalPortfolio - totalContributions) / totalContributions * 100.0
        }
        
        let symbol = (simSettings.currencyPreference == .eur) ? "€" : "$"
        
        return (finalBTC, finalPortfolio, growth, symbol)
    }
    
    private var transitionToResultsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    coordinator.isSimulationRun = true
                    currentPage = lastViewedPage
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let scrollProxy = contentScrollProxy {
                            let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
                            if savedWeek != 0 {
                                lastViewedWeek = savedWeek
                            }
                            if let target = coordinator.monteCarloResults.first(where: { $0.week == lastViewedWeek }) {
                                withAnimation {
                                    scrollProxy.scrollTo("week-\(target.week)", anchor: .top)
                                }
                            }
                        }
                    }
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
    
    private var loadingOverlayCombined: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 250)
                
                HStack {
                    Spacer()
                    if coordinator.isLoading && !coordinator.isChartBuilding {
                        Button(action: {
                            coordinator.isCancelled = true
                            coordinator.isLoading = false
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding()
                        }
                        .padding(.trailing, 20)
                    }
                }
                .offset(y: 220)
                
                if coordinator.isLoading {
                    InteractiveBitcoinSymbol3DSpinner()
                        .padding(.bottom, 30)
                    
                    VStack(spacing: 17) {
                        Text("Simulating: \(coordinator.completedIterations) / \(coordinator.totalIterations)")
                            .font(.body.monospacedDigit())
                            .foregroundColor(.white)
                        
                        ProgressView(value: Double(coordinator.completedIterations),
                                     total: Double(coordinator.totalIterations))
                        .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .frame(width: 200)
                    }
                    .padding(.bottom, 20)
                }
                else if coordinator.isChartBuilding {
                    VStack(spacing: 12) {
                        Text("Generating Charts…")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(
                                    tint: Color(red: 189/255, green: 213/255, blue: 234/255)
                                )
                            )
                            .scaleEffect(2.0)
                    }
                    .offset(y: 270)
                    
                    Spacer().frame(height: 30)
                }
                
                if showTip && coordinator.isLoading {
                    Text(currentTip)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                        .padding(.bottom, 30)
                }
                
                Spacer()
            }
        }
        .onAppear { startTipCycle() }
        .onDisappear { stopTipCycle() }
    }
    
    private func startTipCycle() {
        showTip = false
        tipTimer?.invalidate()
        tipTimer = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            currentTip = loadingTips.randomElement() ?? ""
            withAnimation(.easeInOut(duration: 2)) {
                showTip = true
            }
        }
        
        tipTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                showTip = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                currentTip = loadingTips.randomElement() ?? ""
                withAnimation(.easeInOut(duration: 2)) {
                    showTip = true
                }
            }
        }
    }
    
    private func stopTipCycle() {
        tipTimer?.invalidate()
        tipTimer = nil
        showTip = false
    }
    
    // MARK: - Displaying table data
    private func getValueForTable(_ item: SimulationData, _ keyPath: PartialKeyPath<SimulationData>) -> String {
        if let decimalVal = item[keyPath: keyPath] as? Decimal {
            let doubleValue = NSDecimalNumber(decimal: decimalVal).doubleValue
            
            switch keyPath {
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.portfolioValueUSD:
                if abs(doubleValue) < 1_000_000_000_000_000 {
                    return doubleValue.formattedCurrency()
                } else {
                    return doubleValue.formattedWithPowerOfTenSuffix()
                }
                
            default:
                // For other decimals, do normal currency
                return doubleValue.formattedCurrency()
            }
            
        } else if let doubleVal = item[keyPath: keyPath] as? Double {
            switch keyPath {
            case \SimulationData.startingBTC,
                 \SimulationData.netBTCHoldings,
                 \SimulationData.netContributionBTC:
                return doubleVal.formattedBTC()
                
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.portfolioValueUSD:
                if abs(doubleVal) < 1_000_000_000_000_000 {
                    return doubleVal.formattedCurrency()
                } else {
                    return doubleVal.formattedWithPowerOfTenSuffix()
                }
                
            case \SimulationData.contributionEUR,
                 \SimulationData.contributionUSD,
                 \SimulationData.transactionFeeEUR,
                 \SimulationData.transactionFeeUSD,
                 \SimulationData.withdrawalEUR,
                 \SimulationData.withdrawalUSD:
                return doubleVal.formattedCurrency()
                
            default:
                return String(format: "%.2f", doubleVal)
            }
            
        } else if let intVal = item[keyPath: keyPath] as? Int {
            return "\(intVal)"
        } else {
            return ""
        }
    }
}
