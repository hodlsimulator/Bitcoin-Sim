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

extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // Force layout so SwiftUI knows its size
        controller.view.layoutIfNeeded()
        
        // Create a suitable size
        let targetSize = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        
        // Render into UIImage
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// MARK: - RowOffset Helpers
struct RowOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        for (week, offset) in nextValue() {
            value[week] = offset
        }
    }
}

struct RowOffsetReporter: View {
    let week: Int
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: RowOffsetPreferenceKey.self,
                    value: [week: geo.frame(in: .named("scrollArea")).midY]
                )
        }
    }
}

// MARK: - PersistentInputManager
class PersistentInputManager: ObservableObject {
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
        // Strings
        self.firstYearContribution = UserDefaults.standard.string(forKey: "firstYearContribution") ?? "60"
        self.subsequentContribution = UserDefaults.standard.string(forKey: "subsequentContribution") ?? "100"
        self.iterations = UserDefaults.standard.string(forKey: "iterations") ?? "1000"
        self.annualCAGR = UserDefaults.standard.string(forKey: "annualCAGR") ?? "40.0"
        self.annualVolatility = UserDefaults.standard.string(forKey: "annualVolatility") ?? "80.0"
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
            return 40.0
        }
        return parsedValue
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

// MARK: - 3D Spinner
struct InteractiveBitcoinSymbol3DSpinner: View {
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = -90
    @State private var rotationZ: Double = 0
    @State private var spinSpeed: Double = 10
    @State private var lastUpdate = Date()
    
    var body: some View {
        ZStack {
            OfficialBitcoinLogo()
                .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.degrees(rotationZ), axis: (x: 0, y: 0, z: 1))
        }
        .frame(width: 300, height: 300)
        .offset(x: 0, y: 95)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy) {
                        spinSpeed = 10 + (dx / 5.0)
                    } else {
                        if dy < 0 {
                            rotationZ = 180
                        } else {
                            rotationX = 180
                        }
                    }
                }
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    if abs(dx) > abs(dy) {
                        let flingFactor = value.predictedEndTranslation.width / 5.0
                        spinSpeed = Double(10 + flingFactor)
                    } else {
                        withAnimation(.easeOut(duration: 0.5)) {
                            rotationX = 0
                            rotationZ = 0
                        }
                    }
                }
        )
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
                let now = Date()
                let delta = now.timeIntervalSince(lastUpdate)
                lastUpdate = now
                rotationY += spinSpeed * delta
            }
        }
    }
}

// MARK: - PercentileChoice
enum PercentileChoice {
    case tenth, median, ninetieth
}

// For chart loading overlay
fileprivate enum ChartLoadingState {
    case none, loading, cancelled
}

// MARK: - ChartDataCache
class ChartDataCache: ObservableObject {
    let id = UUID()  // Track the identity
    
    @Published var allRuns: [SimulationRun]? = nil
    @Published var storedInputsHash: Int? = nil
    
    // For iOS, store a snapshot as UIImage
    @Published var chartSnapshot: UIImage? = nil
}

// MARK: - ContentView
struct ContentView: View {
    
    // We keep your existing isLoading, but let's add a second flag
    // to differentiate the "building chart" phase from "running simulation".
    @State private var isChartBuilding: Bool = false
    
    // State variables
    @State private var monteCarloResults: [SimulationData] = []
    @State private var isLoading: Bool = false
    @FocusState private var activeField: ActiveField?
    @StateObject var inputManager = PersistentInputManager()
    @State private var isSimulationRun: Bool = false
    @State private var isCancelled = false
    
    @State private var scrollToBottom: Bool = false
    @State private var isAtBottom: Bool = false
    @State private var lastViewedWeek: Int = 0
    
    @State private var contentScrollProxy: ScrollViewProxy?
    
    @State private var currentPage: Int = 0
    @State private var lastViewedPage: Int = 0
    
    @State private var currentTip: String = ""
    @State private var showTip: Bool = false
    @State private var tipTimer: Timer? = nil
    @State private var completedIterations: Int = 0
    @State private var totalIterations: Int = 1000
    
    @State private var hideScrollIndicators = true
    @State private var lastScrollTime = Date()
    
    @State private var loadingTips: [String] = [
        "Gathering historical data from CSV files...",
        "Spinning up random seeds...",
        "Projecting future halving cycles...",
        "Scrutinising all bullish and bearish factors...",
        "Checking correlation with SP500...",
        "Tip: ‘Halving’ typically occurs every four years or so."
    ]
    
    let columns: [(String, PartialKeyPath<SimulationData>)] = [
        ("Starting BTC (BTC)", \SimulationData.startingBTC),
        ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
        ("BTC Price USD", \SimulationData.btcPriceUSD),
        ("BTC Price EUR", \SimulationData.btcPriceEUR),
        ("Portfolio Value EUR", \SimulationData.portfolioValueEUR),
        ("Contribution EUR", \SimulationData.contributionEUR),
        ("Transaction Fee EUR", \SimulationData.transactionFeeEUR),
        ("Net Contribution BTC", \SimulationData.netContributionBTC),
        ("Withdrawal EUR", \SimulationData.withdrawalEUR)
    ]
    
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var chartDataCache: ChartDataCache
    
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showHistograms = false
    @State private var showGraphics = false
    
    // Keep arrays and logic for each percentile
    @State private var tenthPercentileResults: [SimulationData] = []
    @State private var medianResults: [SimulationData] = []
    @State private var ninetiethPercentileResults: [SimulationData] = []
    @State private var selectedPercentile: PercentileChoice = .median
    
    // We'll store the raw runs for the chart
    @State private var medianSimData: [SimulationData] = []
    @State private var allSimData: [[SimulationData]] = []
    
    // Track chart loading state
    @State private var chartLoadingState: ChartLoadingState = .none
    
    @State private var oldIterationsValue: String = ""
    @State private var oldAnnualCAGRValue: String = ""
    @State private var oldAnnualVolatilityValue: String = ""
    
    @State private var showSnapshotView = false
    
    // MARK: - Convert single run to [WeekPoint]
    func convertOriginalToWeekPoints() -> [WeekPoint] {
        medianSimData.map { row in
            WeekPoint(week: row.week, value: row.portfolioValueEUR)
        }
    }

    // MARK: - Convert all runs to [SimulationRun]
    func convertAllSimsToWeekPoints() -> [SimulationRun] {
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                WeekPoint(week: row.week, value: row.btcPriceUSD)
            }
            return SimulationRun(points: wpoints)
        }
    }
    
    // MARK: - Median logic
    private func computeMedianSimulationData(allIterations: [[SimulationData]]) -> [SimulationData] {
        guard let firstRun = allIterations.first else { return [] }
        let totalWeeks = firstRun.count
        
        var medianResult: [SimulationData] = []
        
        for w in 0..<totalWeeks {
            let allAtWeek = allIterations.compactMap { run -> SimulationData? in
                guard w < run.count else { return nil }
                return run[w]
            }
            if allAtWeek.isEmpty { continue }
            
            let sortedStartingBTC = allAtWeek.map { $0.startingBTC }.sorted()
            let sortedNetBTCHoldings = allAtWeek.map { $0.netBTCHoldings }.sorted()
            let sortedBtcPriceUSD = allAtWeek.map { $0.btcPriceUSD }.sorted()
            let sortedBtcPriceEUR = allAtWeek.map { $0.btcPriceEUR }.sorted()
            let sortedPortfolioValueEUR = allAtWeek.map { $0.portfolioValueEUR }.sorted()
            let sortedContributionEUR = allAtWeek.map { $0.contributionEUR }.sorted()
            let sortedFeeEUR = allAtWeek.map { $0.transactionFeeEUR }.sorted()
            let sortedNetContribBTC = allAtWeek.map { $0.netContributionBTC }.sorted()
            let sortedWithdrawalEUR = allAtWeek.map { $0.withdrawalEUR }.sorted()
            
            func medianOfSorted(_ arr: [Double]) -> Double {
                if arr.isEmpty { return 0.0 }
                let mid = arr.count / 2
                if arr.count.isMultiple(of: 2) {
                    return (arr[mid] + arr[mid - 1]) / 2.0
                } else {
                    return arr[mid]
                }
            }
            
            let medianSimData = SimulationData(
                week: allAtWeek[0].week,
                startingBTC: medianOfSorted(sortedStartingBTC),
                netBTCHoldings: medianOfSorted(sortedNetBTCHoldings),
                btcPriceUSD: medianOfSorted(sortedBtcPriceUSD),
                btcPriceEUR: medianOfSorted(sortedBtcPriceEUR),
                portfolioValueEUR: medianOfSorted(sortedPortfolioValueEUR),
                contributionEUR: medianOfSorted(sortedContributionEUR),
                transactionFeeEUR: medianOfSorted(sortedFeeEUR),
                netContributionBTC: medianOfSorted(sortedNetContribBTC),
                withdrawalEUR: medianOfSorted(sortedWithdrawalEUR)
            )
            medianResult.append(medianSimData)
        }
        return medianResult
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // If the user hasn't pressed "Run Simulation" or it's done,
                // we show the main content. If it's running or building the chart,
                // we display the overlay.
                
                if !isSimulationRun {
                    // If user hasn't run the sim yet, show param screen + icons
                    parametersScreen
                    if !isLoading && activeField == nil {
                        bottomIcons
                    }
                } else {
                    // Show the table
                    simulationResultsView
                }
                
                // If we already have results from a previous run:
                if !isSimulationRun && !monteCarloResults.isEmpty {
                    transitionToResultsButton
                }
                
                // The combined overlay for both "Running simulation" and "Building chart"
                if isLoading || isChartBuilding {
                    loadingOverlayCombined
                }
            }
            // Keep your existing destinations
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(simSettings)
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            .navigationDestination(isPresented: $showHistograms) {
                if let snapshot = chartDataCache.chartSnapshot {
                    ChartSnapshotView(snapshot: snapshot)
                        .environmentObject(chartDataCache)
                } else if let existingChartData = chartDataCache.allRuns {
                    MonteCarloResultsView(simulations: existingChartData)
                        .environmentObject(chartDataCache)
                        .environmentObject(simSettings)
                } else {
                    Text("Loading chart…")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                print("// DEBUG: ContentView onAppear called.")
                
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
    }
    
    // MARK: - Overlay that shows both states
    private var loadingOverlayCombined: some View {
        // Same style as your loadingOverlay, but show different text
        // depending on whether isLoading or isChartBuilding is true.
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 250)
                
                // The top-right X button
                HStack {
                    Spacer()
                    Button(action: {
                        print("// DEBUG: Cancel button tapped in combined overlay.")
                        isCancelled = true
                        // If they cancel at chart building stage, just hide overlay.
                        if isChartBuilding {
                            isChartBuilding = false
                        }
                        // If they cancel at simulation stage:
                        if isLoading {
                            isLoading = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding(.trailing, 20)
                }
                .offset(y: 220)
                
                // The spinner
                InteractiveBitcoinSymbol3DSpinner()
                    .padding(.bottom, 30)
                
                // The text / progress area
                VStack(spacing: 17) {
                    if isLoading {
                        // Simulation is running
                        Text("Simulating: \(completedIterations) / \(totalIterations)")
                            .font(.body.monospacedDigit())
                            .foregroundColor(.white)
                        
                        ProgressView(value: Double(completedIterations), total: Double(totalIterations))
                            .tint(.blue)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .frame(width: 200)
                    }
                    else if isChartBuilding {
                        // Chart building is happening
                        Text("Generating Chart…")
                            .font(.headline)
                            .foregroundColor(.white)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(2.0)
                    }
                }
                .padding(.bottom, 20)
                
                // Same tips logic
                if showTip {
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
    
    // MARK: - Run Simulation
    private func runSimulation() {
        let newHash = computeInputsHash()
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = \(String(describing: chartDataCache.storedInputsHash))")
        
        // CSV loads
        historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
        sp500WeeklyReturns = loadSP500WeeklyReturns()
        
        print("// DEBUG: Setting up for new simulation run. isLoading=true.")
        isCancelled = false
        isLoading = true
        isChartBuilding = false
        monteCarloResults = []
        completedIterations = 0
        
        let finalSeed: UInt64?
        if simSettings.lockedRandomSeed {
            finalSeed = simSettings.seedValue
            simSettings.lastUsedSeed = simSettings.seedValue
            print("// DEBUG: Using lockedRandomSeed: \(finalSeed ?? 0)")
        } else if simSettings.useRandomSeed {
            let newRandomSeed = UInt64.random(in: 0..<UInt64.max)
            finalSeed = newRandomSeed
            simSettings.lastUsedSeed = newRandomSeed
            print("// DEBUG: Using a fresh random seed: \(finalSeed ?? 0)")
        } else {
            finalSeed = nil
            simSettings.lastUsedSeed = 0
            print("// DEBUG: No seed locked or random => finalSeed is nil.")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let total = inputManager.getParsedIterations(), total > 0 else {
                print("// DEBUG: No valid iteration => bailing out.")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            DispatchQueue.main.async {
                totalIterations = total
            }
            
            let userInputCAGR = inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(inputManager.annualVolatility) ?? 1.0) / 100.0
            let userWeeks = simSettings.userWeeks
            let userPriceUSD = simSettings.initialBTCPriceUSD
            
            print("// DEBUG: runMonteCarloSimulationsWithProgress(...)")
            let (medianRun, allIterations) = runMonteCarloSimulationsWithProgress(
                settings: simSettings,
                annualCAGR: userInputCAGR,
                annualVolatility: userInputVolatility,
                correlationWithSP500: 0.0,
                exchangeRateEURUSD: 1.06,
                userWeeks: userWeeks,
                iterations: total,
                initialBTCPriceUSD: userPriceUSD,
                isCancelled: { self.isCancelled },
                progressCallback: { completed in
                    if !self.isCancelled {
                        DispatchQueue.main.async {
                            self.completedIterations = completed
                        }
                    }
                },
                seed: finalSeed
            )
            
            if self.isCancelled {
                print("// DEBUG: user cancelled => stopping.")
                DispatchQueue.main.async { isLoading = false }
                return
            }
            
            // Sort final runs by last week's BTC price
            let finalRuns = allIterations.map { ($0.last?.btcPriceUSD ?? 0.0, $0) }
            let sortedRuns = finalRuns.sorted { $0.0 < $1.0 }
            
            if !sortedRuns.isEmpty {
                let tenthIndex = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                
                let tenthRun = sortedRuns[tenthIndex].1
                let singleMedianRun = sortedRuns[medianIndex].1
                let ninetiethRun = sortedRuns[ninetiethIndex].1
                let medianLineData = computeMedianSimulationData(allIterations: allIterations)
                
                DispatchQueue.main.async {
                    // Simulation done => turn off isLoading
                    isLoading = false
                    // Start building chart
                    isChartBuilding = true
                    print("// DEBUG: Simulation finished => isChartBuilding=true now.")
                    
                    // Assign results
                    self.tenthPercentileResults = tenthRun
                    self.medianResults = singleMedianRun
                    self.ninetiethPercentileResults = ninetiethRun
                    self.monteCarloResults = medianLineData
                    self.selectedPercentile = .median
                    self.medianResults = medianLineData
                    self.allSimData = allIterations
                    let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                    
                    // Clear old snapshot
                    if chartDataCache.chartSnapshot != nil {
                        print("// DEBUG: clearing old chartSnapshot.")
                    }
                    chartDataCache.chartSnapshot = nil
                    chartDataCache.allRuns = allSimsAsWeekPoints
                    chartDataCache.storedInputsHash = newHash
                    self.medianSimData = medianLineData
                    
                    // Build the snapshot after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if self.isCancelled {
                            isChartBuilding = false
                            return
                        }
                        let chartView = MonteCarloResultsView(simulations: allSimsAsWeekPoints)
                            .environmentObject(self.chartDataCache)
                            .environmentObject(self.simSettings)
                        
                        let snapshot = chartView.snapshot()
                        print("// DEBUG: snapshot built => setting chartDataCache.chartSnapshot.")
                        chartDataCache.chartSnapshot = snapshot
                        
                        // Done building => user can see results
                        isChartBuilding = false
                        isSimulationRun = true
                    }
                }
            } else {
                print("// DEBUG: No runs => done.")
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
            
            DispatchQueue.global(qos: .background).async {
                self.processAllResults(allIterations)
            }
        }
    }
    
    // MARK: - Invalidate chart if inputs change
    private func invalidateChartIfInputChanged() {
        print("DEBUG: invalidateChartIfInputChanged() => clearing chartDataCache.")
        chartDataCache.allRuns = nil
        chartDataCache.storedInputsHash = nil
    }
    
    private func computeInputsHash() -> Int {
        let combinedString = """
        \(inputManager.iterations)_\(inputManager.annualCAGR)_\(inputManager.annualVolatility)_\
        \(simSettings.userWeeks)_\(simSettings.initialBTCPriceUSD)
        """
        return combinedString.hashValue
    }
    
    // MARK: - UI
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
    
    private var parametersScreen: some View {
        ZStack {
            // Black/gradient background, like before:
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
                    .padding(.top, 10)
                
                Text("Set your simulation parameters")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Iterations Field
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Iterations")
                            .foregroundColor(.white)
                        TextField("e.g. 1000", text: $inputManager.iterations)
                            .keyboardType(.numberPad)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(6)
                            .foregroundColor(.black)
                            .focused($activeField, equals: .iterations)
                            .onChange(of: inputManager.iterations) { newValue in
                                if newValue != oldIterationsValue {
                                    oldIterationsValue = newValue
                                    invalidateChartIfInputChanged()
                                }
                            }
                    }
                    
                    // Annual CAGR Field
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Annual CAGR (%)")
                            .foregroundColor(.white)
                        TextField("e.g. 40.0", text: $inputManager.annualCAGR)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(6)
                            .foregroundColor(.black)
                            .focused($activeField, equals: .annualCAGR)
                            .onChange(of: inputManager.annualCAGR) { newValue in
                                if newValue != oldAnnualCAGRValue {
                                    oldAnnualCAGRValue = newValue
                                    invalidateChartIfInputChanged()
                                }
                            }
                    }
                    
                    // Annual Volatility Field
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Annual Volatility (%)")
                            .foregroundColor(.white)
                        TextField("e.g. 80.0", text: $inputManager.annualVolatility)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(6)
                            .foregroundColor(.black)
                            .focused($activeField, equals: .annualVolatility)
                            .onChange(of: inputManager.annualVolatility) { newValue in
                                if newValue != oldAnnualVolatilityValue {
                                    oldAnnualVolatilityValue = newValue
                                    invalidateChartIfInputChanged()
                                }
                            }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1).opacity(0.8))
                )
                .padding(.horizontal, 30)
                
                // Run Simulation Button
                if !isLoading && !isChartBuilding {
                    Button {
                        activeField = nil
                        runSimulation()
                    } label: {
                        Text("RUN SIMULATION")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(8)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                    }
                    .padding(.top, 6)
                }
                
                Spacer()
            }
        }
    }
    
    private var simulationResultsView: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                // Remove extra white space at bottom:
                // edgesIgnoringSafeArea if needed:
                Color(white: 0.12)
                    .edgesIgnoringSafeArea(.bottom)
                
                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        // Chevron-only back button in white
                        Button(action: {
                            print("// DEBUG: Back button tapped in simulationResultsView.")
                            UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                            UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                            lastViewedPage = currentPage
                            isSimulationRun = false
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        
                        Spacer()
                        
                        // The chart button
                        Button(action: {
                            print("// DEBUG: Chart button pressed.")
                            print("// DEBUG: chartDataCache.chartSnapshot == \(chartDataCache.chartSnapshot == nil ? "nil" : "non-nil")")
                            if let allRuns = chartDataCache.allRuns {
                                print("// DEBUG: chartDataCache.allRuns has \(allRuns.count) runs.")
                            } else {
                                print("// DEBUG: chartDataCache.allRuns is nil.")
                            }
                            
                            if let snapshot = chartDataCache.chartSnapshot {
                                showSnapshotView = true
                            }
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        .navigationDestination(isPresented: $showSnapshotView) {
                            if let snapshot = chartDataCache.chartSnapshot {
                                ChartSnapshotView(snapshot: snapshot)
                            } else {
                                Text("No snapshot available")
                                    .foregroundColor(.white)
                            }
                        }
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
                            
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.2)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            TapGesture()
                                                .onEnded {
                                                    if currentPage > 0 {
                                                        withAnimation {
                                                            currentPage -= 1
                                                        }
                                                    }
                                                }
                                        )
                                    Spacer()
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.2)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            TapGesture()
                                                .onEnded {
                                                    if currentPage < columns.count - 1 {
                                                        withAnimation {
                                                            currentPage += 1
                                                        }
                                                    }
                                                }
                                        )
                                }
                            }
                        }
                        .frame(height: 50)
                    }
                    .background(Color.black)
                    
                    // Main table
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ForEach(monteCarloResults.indices, id: \.self) { index in
                                    let result = monteCarloResults[index]
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
                                ForEach(0..<columns.count, id: \.self) { index in
                                    ZStack {
                                        VStack(spacing: 0) {
                                            ForEach(monteCarloResults.indices, id: \.self) { rowIndex in
                                                let rowResult = monteCarloResults[rowIndex]
                                                let rowBackground = rowIndex.isMultiple(of: 2)
                                                    ? Color(white: 0.10)
                                                    : Color(white: 0.14)
                                                
                                                Text(getValue(rowResult, columns[index].1))
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
                                                    .gesture(
                                                        TapGesture()
                                                            .onEnded {
                                                                if currentPage > 0 {
                                                                    withAnimation {
                                                                        currentPage -= 1
                                                                    }
                                                                }
                                                            }
                                                    )
                                                Spacer()
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .gesture(
                                                        TapGesture()
                                                            .onEnded {
                                                                if currentPage < columns.count - 1 {
                                                                    withAnimation {
                                                                        currentPage += 1
                                                                    }
                                                                }
                                                            }
                                                    )
                                            }
                                        }
                                    }
                                    .tag(index)
                                }
                            }
                            // This helps remove any extra space:
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
                            if value, let lastResult = monteCarloResults.last {
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
                    print("// DEBUG: simulationResultsView onDisappear => saving lastViewedWeek, lastViewedPage.")
                    UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                // Scroll-to-bottom button
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
    
    private var transitionToResultsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    print("// DEBUG: transitionToResultsButton tapped => showing simulation screen.")
                    isSimulationRun = true
                    currentPage = lastViewedPage
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let scrollProxy = contentScrollProxy {
                            let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
                            if savedWeek != 0 {
                                lastViewedWeek = savedWeek
                            }
                            if let target = monteCarloResults.first(where: { $0.week == lastViewedWeek }) {
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
    
    // (Removed old loadingOverlay and chartLoadingOverlay, replaced with loadingOverlayCombined.)
    
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
    
    private func processAllResults(_ allResults: [[SimulationData]]) {
        // ...
    }
    
    private func getValue(_ item: SimulationData, _ keyPath: PartialKeyPath<SimulationData>) -> String {
        if let value = item[keyPath: keyPath] as? Double {
            switch keyPath {
            case \SimulationData.startingBTC,
                 \SimulationData.netBTCHoldings,
                 \SimulationData.netContributionBTC:
                return value.formattedBTC()
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.contributionEUR,
                 \SimulationData.transactionFeeEUR,
                 \SimulationData.withdrawalEUR:
                return value.formattedCurrency()
            default:
                return String(format: "%.2f", value)
            }
        } else if let value = item[keyPath: keyPath] as? Int {
            return "\(value)"
        } else {
            return ""
        }
    }
}
