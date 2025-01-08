//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by ... on 20/11/2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import PocketSVG
import UIKit

// MARK: - PersistentInputManager
class PersistentInputManager: ObservableObject {

    // ADDED:
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
    @Published var standardDeviation: String {  // new field
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
        // ADDED:
        self.generateGraphs = UserDefaults.standard.bool(forKey: "generateGraphs")

        // Strings
        self.firstYearContribution = UserDefaults.standard.string(forKey: "firstYearContribution") ?? "60"
        self.subsequentContribution = UserDefaults.standard.string(forKey: "subsequentContribution") ?? "100"
        self.iterations = UserDefaults.standard.string(forKey: "iterations") ?? "1000"
        self.annualCAGR = UserDefaults.standard.string(forKey: "annualCAGR") ?? "40.0"
        self.annualVolatility = UserDefaults.standard.string(forKey: "annualVolatility") ?? "80.0"
        self.standardDeviation = UserDefaults.standard.string(forKey: "standardDeviation") ?? "15.0"
        self.selectedWeek = UserDefaults.standard.string(forKey: "selectedWeek") ?? "1"
        self.btcPriceMinInput = UserDefaults.standard.string(forKey: "btcPriceMinInput") ?? ""
        self.btcPriceMaxInput = UserDefaults.standard.string(forKey: "btcPriceMaxInput") ?? ""
        self.portfolioValueMinInput = UserDefaults.standard.string(forKey: "portfolioValueMinInput") ?? ""
        self.portfolioValueMaxInput = UserDefaults.standard.string(forKey: "portfolioValueMaxInput") ?? ""
        self.btcHoldingsMinInput = UserDefaults.standard.string(forKey: "btcHoldingsMinInput") ?? ""
        self.btcHoldingsMaxInput = UserDefaults.standard.string(forKey: "btcHoldingsMaxInput") ?? ""
        self.btcGrowthRate = UserDefaults.standard.string(forKey: "btcGrowthRate") ?? "0.005"

        // Doubles
        let storedT1 = UserDefaults.standard.double(forKey: "threshold1")
        self.threshold1 = (storedT1 != 0.0) ? storedT1 : 30000.0

        let storedW1 = UserDefaults.standard.double(forKey: "withdrawAmount1")
        self.withdrawAmount1 = (storedW1 != 0.0) ? storedW1 : 100.0

        let storedT2 = UserDefaults.standard.double(forKey: "threshold2")
        self.threshold2 = (storedT2 != 0.0) ? storedT2 : 60000.0

        let storedW2 = UserDefaults.standard.double(forKey: "withdrawAmount2")
        self.withdrawAmount2 = (storedW2 != 0.0) ? storedW2 : 200.0
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
            return 40.0
        }
        return min(parsedValue, 1000.0) // clamp at 1000
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

fileprivate enum ChartLoadingState {
    case none, loading, cancelled
}

// MARK: - ChartDataCache
class ChartDataCache: ObservableObject {
    let id = UUID()  // Track the identity
    
    @Published var allRuns: [SimulationRun]? = nil
    @Published var storedInputsHash: Int? = nil
    
    // For iOS, store a snapshot as UIImage
    @Published var chartSnapshot: UIImage?
    @Published var chartSnapshotLandscape: UIImage?
    
    @Published var portfolioChartSnapshot: UIImage?
    @Published var portfolioChartSnapshotLandscape: UIImage?
    @Published var portfolioRuns: [SimulationRun]?
    
    // Add these two for portfolio:
    @Published var chartSnapshotPortfolio: UIImage? = nil
    @Published var chartSnapshotPortfolioLandscape: UIImage? = nil
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject var inputManager: PersistentInputManager
    @StateObject var simSettings: SimulationSettings
    @StateObject var chartDataCache: ChartDataCache
    @StateObject var coordinator: SimulationCoordinator
    
    // Track old values so we can invalidate the chart if changed
    @State private var oldIterationsValue: String = ""
    @State private var oldAnnualCAGRValue: String = ""
    @State private var oldAnnualVolatilityValue: String = ""
    @State private var oldStandardDevValue: String = ""

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
    
    // No more local arrays. Use the new file’s data:
    private var loadingTips: [String] { TipsData.loadingTips }
    private var usageTips: [String] { TipsData.usageTips }
    
    // Columns in the table view (depending on the user’s currency preference):
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
    
    init() {
            let manager = PersistentInputManager()
            let settings = SimulationSettings()
            settings.inputManager = manager
            let cache = ChartDataCache()

            let chartSel = ChartSelection()
            let simCoord = SimulationCoordinator(
                chartDataCache: cache,
                simSettings: settings,
                inputManager: manager,
                chartSelection: chartSel
            )

            _inputManager = StateObject(wrappedValue: manager)
            _simSettings = StateObject(wrappedValue: settings)
            _chartDataCache = StateObject(wrappedValue: cache)
            _coordinator = StateObject(wrappedValue: simCoord)
        }

    var body: some View {
        NavigationStack {
            ZStack {
                if !coordinator.isSimulationRun {
                    parametersScreen
                    // Bottom icons only if not loading & keyboard not active
                    if !coordinator.isLoading && activeField == nil {
                        bottomIcons
                    }
                } else {
                    simulationResultsView
                }
                
                // Show the “→” button if we have results + chart built
                if !coordinator.isSimulationRun &&
                    !coordinator.monteCarloResults.isEmpty &&
                    !coordinator.isChartBuilding {
                    transitionToResultsButton
                }
                
                // Loading / Chart-building overlay
                if coordinator.isLoading || coordinator.isChartBuilding {
                    loadingOverlayCombined
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(simSettings)
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            .navigationDestination(isPresented: $showSnapshotsDebug) {
                SnapshotsDebugView()
                    .environmentObject(coordinator.chartDataCache)
            }
            .onAppear {
                // Load last viewed row + page
                let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
                if savedWeek != 0 {
                    lastViewedWeek = savedWeek
                }
                
                let savedPage = UserDefaults.standard.integer(forKey: "lastViewedPage")
                if savedPage < columns.count {
                    lastViewedPage = savedPage
                    currentPage = savedPage
                } else if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                    currentPage = usdIndex
                    lastViewedPage = usdIndex
                }
            }
        }
        .navigationDestination(isPresented: $showHistograms) {
            ForceReflowView {
                if let existingChartData = coordinator.chartDataCache.allRuns {
                    MonteCarloResultsView()
                        .environmentObject(coordinator.chartDataCache)
                        .environmentObject(simSettings)
                        .environmentObject(coordinator.chartSelection)
                } else {
                    Text("Loading chart…")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Parameter Screen
    private var parametersScreen: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer().frame(height: 60)
                
                Text("HODL Simulator")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Set your simulation parameters")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                // Parameter card
                VStack(spacing: 20) {
                    
                    // Row 1: Iterations & CAGR
                    HStack(spacing: 24) {
                        // Iterations
                        VStack(spacing: 4) {
                            Text("Iterations")
                                .foregroundColor(.white)
                            TextField("1000", text: $inputManager.iterations)
                                .keyboardType(.numberPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .iterations)
                                .onChange(of: inputManager.iterations) { newVal in
                                    if newVal != oldIterationsValue {
                                        oldIterationsValue = newVal
                                        invalidateChartIfInputChanged()
                                    }
                                }
                        }
                        
                        // CAGR
                        VStack(spacing: 4) {
                            Text("CAGR (%)")
                                .foregroundColor(.white)
                            TextField("40.0", text: $inputManager.annualCAGR)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .annualCAGR)
                                .onChange(of: inputManager.annualCAGR) { newVal in
                                    if newVal != oldAnnualCAGRValue {
                                        oldAnnualCAGRValue = newVal
                                        invalidateChartIfInputChanged()
                                    }
                                }
                        }
                    }
                    
                    // Row 2: Vol & StdDev
                    HStack(spacing: 24) {
                        // Vol
                        VStack(spacing: 4) {
                            Text("Vol (%)")
                                .foregroundColor(.white)
                            TextField("80.0", text: $inputManager.annualVolatility)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .annualVolatility)
                                .onChange(of: inputManager.annualVolatility) { newVal in
                                    if newVal != oldAnnualVolatilityValue {
                                        oldAnnualVolatilityValue = newVal
                                        invalidateChartIfInputChanged()
                                    }
                                }
                        }
                        
                        // StdDev
                        VStack(spacing: 4) {
                            Text("StdDev")
                                .foregroundColor(.white)
                            TextField("15.0", text: $inputManager.standardDeviation)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .standardDeviation)
                                .onChange(of: inputManager.standardDeviation) { newVal in
                                    if newVal != oldStandardDevValue {
                                        oldStandardDevValue = newVal
                                        invalidateChartIfInputChanged()
                                    }
                                }
                        }
                    }
                    
                    // Row 3: Toggles
                    HStack(spacing: 32) {
                        Toggle("Charts", isOn: $inputManager.generateGraphs)
                            .toggleStyle(CheckboxToggleStyle())
                            .foregroundColor(.white)
                        
                        Toggle("Lock Seed", isOn: $simSettings.lockedRandomSeed)
                            .toggleStyle(CheckboxToggleStyle())
                            .foregroundColor(.white)
                            .onChange(of: simSettings.lockedRandomSeed) { locked in
                                if locked {
                                    let newSeed = UInt64.random(in: 0..<UInt64.max)
                                    simSettings.seedValue = newSeed
                                    simSettings.useRandomSeed = false
                                } else {
                                    simSettings.seedValue = 0
                                    simSettings.useRandomSeed = true
                                }
                            }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1).opacity(0.8))
                )
                .padding(.horizontal, 30)
                
                // Run Simulation
                if coordinator.isLoading || coordinator.isChartBuilding {
                    // Invisible placeholder so layout stays put
                    Text(" ")
                        .font(.callout)
                        .foregroundColor(.clear)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .cornerRadius(8)
                        .padding(.top, 6)
                    
                    Spacer()
                } else {
                    Button {
                        activeField = nil
                        coordinator.isLoading = true
                        coordinator.isChartBuilding = false
                        
                        coordinator.runSimulation(
                            generateGraphs: inputManager.generateGraphs,
                            lockRandomSeed: simSettings.lockedRandomSeed
                        )
                    } label: {
                        Text("RUN SIMULATION")
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    .padding(.top, 6)
                    
                    Spacer()
                }
            }
        }
        .onTapGesture {
            // Dismiss keyboard
            activeField = nil
        }
    }
    
    // MARK: - If inputs change, clear cached chart
    
    private func invalidateChartIfInputChanged() {
        coordinator.chartDataCache.allRuns = nil
        coordinator.chartDataCache.storedInputsHash = nil
        print("// DEBUG: invalidateChartIfInputChanged => cleared chart cache.")
    }
    
    // MARK: - Bottom icons (gear, info)
    
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
                    // Top bar
                    HStack {
                        Button(action: {
                            print("// DEBUG: Back button tapped in simulationResultsView.")
                            UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                            UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                            lastViewedPage = currentPage
                            coordinator.isSimulationRun = false
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        
                        Spacer()
                        
                        // ADDED OR MODIFIED:
                        // We grey out (disable) the Charts button if inputManager.generateGraphs == false
                        Button(action: {
                            print("// DEBUG: Chart button pressed.")
                            showHistograms = true
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                // If generateGraphs is false, we use .gray so it looks disabled
                                .foregroundColor(inputManager.generateGraphs ? .white : .gray)
                                .imageScale(.large)
                        }
                        .disabled(!inputManager.generateGraphs) // Actually disables the button
                    }
                    .padding(.horizontal, 55)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.12))
                    
                    // Column headers
                    HStack(spacing: 0) {
                        Text("Week")
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
                            
                            // Invisible left-right areas to swipe columns
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
                    
                    // Main data scroll
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                        HStack(spacing: 0) {
                            // Left column: Week numbers
                            VStack(spacing: 0) {
                                ForEach(coordinator.monteCarloResults.indices, id: \.self) { index in
                                    let result = coordinator.monteCarloResults[index]
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
                            
                            // Right column: Data in pages
                            TabView(selection: $currentPage) {
                                ForEach(0..<columns.count, id: \.self) { idx in
                                    ZStack {
                                        VStack(spacing: 0) {
                                            ForEach(coordinator.monteCarloResults.indices, id: \.self) { rowIndex in
                                                let rowResult = coordinator.monteCarloResults[rowIndex]
                                                let rowBackground = rowIndex.isMultiple(of: 2)
                                                    ? Color(white: 0.10)
                                                    : Color(white: 0.14)
                                                
                                                Text(getValue(rowResult, columns[idx].1))
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
                                        // Invisible left-right “swipe” areas
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
                            let targetY: CGFloat = 160
                            let filtered = offsets.filter { (week, _) in week != 1040 }
                            let mapped = filtered.mapValues { abs($0 - targetY) }
                            if let (closestWeek, _) = mapped.min(by: { $0.value < $1.value }) {
                                lastViewedWeek = closestWeek
                            }
                        }
                        .onChange(of: scrollToBottom) { value in
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
                        // Detect dragging to show/hide scroll indicators
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
                    // Re-hide indicators after a bit
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
                    print("// DEBUG: simulationResultsView onDisappear => saving lastViewedWeek=\(lastViewedWeek), lastViewedPage=\(currentPage)")
                    UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                // A button to jump to bottom if needed
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
    
    // MARK: - Next arrow to show results
    
    private var transitionToResultsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    print("// DEBUG: transitionToResultsButton tapped => showing simulation screen.")
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
    
    // MARK: - Loading Overlay
    private var loadingOverlayCombined: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 250)
                
                HStack {
                    Spacer()
                    if coordinator.isLoading && !coordinator.isChartBuilding {
                        Button(action: {
                            print("// DEBUG: Cancel button tapped in combined overlay.")
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
    
    // MARK: - Tip cycle
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
    
    // MARK: - Data Formatting
    private func getValue(_ item: SimulationData, _ keyPath: PartialKeyPath<SimulationData>) -> String {
        // 1) If the field is a Decimal:
        if let decimalVal = item[keyPath: keyPath] as? Decimal {
            let doubleValue = NSDecimalNumber(decimal: decimalVal).doubleValue
            return doubleValue.formattedCurrency()
            
        // 2) If the field is a Double:
        } else if let doubleVal = item[keyPath: keyPath] as? Double {
            switch keyPath {
            case \SimulationData.startingBTC,
                 \SimulationData.netBTCHoldings,
                 \SimulationData.netContributionBTC:
                return doubleVal.formattedBTC()
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.portfolioValueUSD,
                 \SimulationData.contributionEUR,
                 \SimulationData.transactionFeeEUR,
                 \SimulationData.withdrawalEUR:
                return doubleVal.formattedCurrency()
            default:
                return String(format: "%.2f", doubleVal)
            }
            
        // 3) If the field is an Int:
        } else if let intVal = item[keyPath: keyPath] as? Int {
            return "\(intVal)"
            
        // 4) Otherwise (e.g. a String?), return empty or handle differently
        } else {
            return ""
        }
    }
}
