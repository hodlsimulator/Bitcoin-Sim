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

    // Stored as Double:
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

// MARK: - ContentView
struct ContentView: View {
    
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
    
    // Updated tips array
    @State private var loadingTips: [String] = [
        // (existing technical simulation messages)
        "Gathering historical data from CSV files...",
        "Spinning up random seeds...",
        "Projecting future halving cycles...",
        "Scrutinising all bullish and bearish factors...",
        "Checking correlation with SP500...",
        "Crunching thousands of Monte Carlo draws...",
        "Spotting potential bubble pops...",
        "Tracking demographic adoption trends...",
        "Stirring volatility data...",
        "Estimating random risk parameters...",
        "Parsing user inputs for CAGR & volatility...",
        "Calibrating institutional demand factor...",
        "Waiting for whales to move off exchanges...",
        "Probing competitor coin dominance...",
        "Balancing stablecoin meltdown scenarios...",
        "Analysing correlation with macro markets...",
        "Synthesising historical BTC returns...",
        "Focusing on supply shock events...",
        "Examining next-generation adoption curves...",
        "Running a quick fear-and-greed check...",
        "Scanning for black swan catalysts...",
        "Aligning user settings for final run...",
        "Inflating or deflating the bubble?",
        "Combining multi-year data into forecasts...",
        "Hooking in country adoption boosts...",
        "Filtering out short-term noise...",
        "Compiling scenario stress tests...",
        "Fine-tuning scale for weekly returns...",
        "Cross-referencing stablecoin shifts...",
        "Probing raw data for hidden signals...",
        "Summoning lightning speed calculations...",
        "Twisting code knobs for final results...",
        
        // (new "tips on how to use the app" messages)
        "Tip: Drag the 3D spinner to change its speed.",
        "Tip: Double-tap the spinner to flip its rotation angle.",
        "Tip: Scroll horizontally in the table to see extra columns.",
        "Tip: Lock the random seed in Settings for repeatable results.",
        "Tip: Check ‘About’ for more details on simulation methodology.",
        "Tip: Toggle bull/bear factors in Settings to reflect your outlook.",
        "Tip: Increase annual CAGR to simulate a more bullish scenario.",
        "Tip: Lower annual volatility to reduce big swings in outcomes.",
        "Tip: Swipe left or right on the results table to reveal hidden columns.",
        "Tip: If the random seed is unlocked, you’ll get a fresh run each time.",
        "Tip: Slow the spinner by dragging it in the opposite direction.",
        "Tip: Simulate Tether depegs with the ‘Stablecoin Meltdown’ factor.",
        "Tip: Press the back arrow anytime to modify parameters mid-sim.",
        "Tip: Tap factor titles in Settings for a quick explanation bubble.",
        "Tip: ‘Maturing Market’ can limit growth in later stages of adoption.",
        "Tip: ‘Bubble Pop’ adds a risk of rapid correction after a big rally.",
        "Tip: Snap screenshots of results to share or compare runs later.",
        "Tip: ‘Halving’ typically occurs every 210k blocks—about four years.",
        "Tip: El Salvador style? Enable ‘Country Adoption’ for big demand bumps.",
        "Tip: ‘Global Macro Hedge’ imagines BTC as ‘digital gold’ in crises.",
        "Tip: Return to Parameters to tweak your inputs before the next run.",
        "Tip: Explore the ‘About’ screen to learn how each factor is simulated.",
        "Tip: Try fewer or more iterations to see stable vs. scattered results.",
        "Tip: Turn on ‘Scarcity Events’ to replicate supply shocks and FOMO.",
        "Tip: You can do multiple runs without losing previous results—experiment!",
        "Tip: Flip your device orientation for a wider table view.",
        "Tip: Check ‘Security Breach’ factor for catastrophic hack scenarios.",
        "Tip: ‘Bear Market’ factor simulates persistent negative sentiment.",
        "Tip: The spinner is purely for fun—drag, poke or fling at will!",
        "Tip: Keep track of your real-world BTC holdings separately—this is a sim.",
        "Tip: Combine bullish and bearish toggles to mirror your market view.",
        "Tip: Remember, all factors can be toggled off for a simpler baseline."
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
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showHistograms = false
    @State private var showGraphics = false
    
    // Three arrays for each percentile
    @State private var tenthPercentileResults: [SimulationData] = []
    @State private var medianResults: [SimulationData] = []
    @State private var ninetiethPercentileResults: [SimulationData] = []
    
    // Track the currently chosen percentile
    @State private var selectedPercentile: PercentileChoice = .median
    
    @State private var medianSimData: [SimulationData] = []
    @State private var allSimData: [[SimulationData]] = []
    
    // 1) Converts your “original” run (e.g. medianSimData) into [WeekPoint].
    func convertOriginalToWeekPoints() -> [WeekPoint] {
        // For instance, if you have an array `medianSimData: [SimulationData]`
        // accessible in this scope, do something like:
        medianSimData.map { row in
            WeekPoint(week: row.week, value: row.portfolioValueEUR)
        }
    }

    // 2) Converts all simulation runs (e.g. allSimData: [[SimulationData]]) into [SimulationRun].
    func convertAllSimsToWeekPoints() -> [SimulationRun] {
        // e.g. if you have `allSimData: [[SimulationData]]` accessible:
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                WeekPoint(week: row.week, value: row.btcPriceUSD)
            }
            return SimulationRun(points: wpoints)
        }
    }

    // MARK: - BODY
    var body: some View {
        NavigationStack {
            ZStack {
                if isSimulationRun {
                    Color(white: 0.14).ignoresSafeArea()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // Transparent overlay for dismissing keyboard if tapped
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded {
                                activeField = nil
                            }
                    )
                
                // Show either parameter setup or simulation results
                if !isSimulationRun {
                    parametersScreen
                    if !isLoading && activeField == nil {
                        bottomIcons
                    }
                } else {
                    simulationResultsView
                }
                
                // Jump arrow if results exist
                if !isSimulationRun && !monteCarloResults.isEmpty {
                    transitionToResultsButton
                }
                
                // Loading overlay
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(simSettings)
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            // Hook up the chart-based view with real data
            .navigationDestination(isPresented: $showHistograms) {
                MonteCarloResultsView(
                    simulations: convertAllSimsToWeekPoints()
                )
            }
            .onAppear {
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
    
    // MARK: - Convert to Yearly Data
    /// The function that turns your final tenth/median/ninetieth arrays into [YearlyPercentileData] for the chart.
    func convertMonteCarloResultsToYearlyData() -> [YearlyPercentileData] {
        // We assume each array has 20 "years" worth of data (or you adapt as needed).
        // We'll grab the final BTC Price from each year's last weekly data for each percentile
        // Then build a YearlyPercentileData record.
        
        let years = 20
        var resultArray: [YearlyPercentileData] = []
        
        // For demonstration, let's say you have 52 weeks/year => yearIndex * 52 to find weekly offsets
        // or adapt if your data structure differs.
        
        for y in 1...years {
            // We'll define a helper to extract the last weekly item for each percentile's array for that "year."
            let finalWeekIndex = y * 52 - 1 // e.g. year 1 => 51, year 2 => 103, etc.
            
            // Safety check to avoid out-of-range
            let tenthIdx      = min(finalWeekIndex, tenthPercentileResults.count - 1)
            let medianIdx     = min(finalWeekIndex, medianResults.count - 1)
            let ninetiethIdx  = min(finalWeekIndex, ninetiethPercentileResults.count - 1)
            
            let tenthPrice      = tenthPercentileResults.isEmpty ? 0.0  : tenthPercentileResults[tenthIdx].btcPriceUSD
            let medianPrice     = medianResults.isEmpty ? 0.0          : medianResults[medianIdx].btcPriceUSD
            let ninetiethPrice  = ninetiethPercentileResults.isEmpty ? 0.0 : ninetiethPercentileResults[ninetiethIdx].btcPriceUSD
            
            resultArray.append(
                YearlyPercentileData(
                    year: y,
                    tenth: tenthPrice,
                    median: medianPrice,
                    ninetieth: ninetiethPrice
                )
            )
        }
        
        return resultArray
    }
    
    // MARK: - Bottom icons
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
    
    // MARK: - Parameters screen
    private var parametersScreen: some View {
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
                }
                
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
                }
                
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
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.1).opacity(0.8))
            )
            .padding(.horizontal, 30)
            
            if !isLoading {
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
    
    // MARK: - The simulation screen
    private var simulationResultsView: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                // Same grey background
                Color(white: 0.12)
                    .edgesIgnoringSafeArea(.top)
                
                VStack(spacing: 0) {
                    
                    // Navigation bar area
                    HStack {
                        // Back button
                        Button(action: {
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
                        
                        // Percentile menu (icon only)
                        Menu {
                            // 10th Percentile
                            Button {
                                selectedPercentile = .tenth
                                self.monteCarloResults = self.tenthPercentileResults
                            } label: {
                                if selectedPercentile == .tenth {
                                    Label("10th Percentile", systemImage: "checkmark")
                                        .foregroundColor(.orange)
                                } else {
                                    Text("10th Percentile")
                                }
                            }
                            
                            // Median
                            Button {
                                selectedPercentile = .median
                                self.monteCarloResults = self.medianResults
                            } label: {
                                if selectedPercentile == .median {
                                    Label("Median", systemImage: "checkmark")
                                        .foregroundColor(.orange)
                                } else {
                                    Text("Median")
                                }
                            }
                            
                            // 90th Percentile
                            Button {
                                selectedPercentile = .ninetieth
                                self.monteCarloResults = self.ninetiethPercentileResults
                            } label: {
                                if selectedPercentile == .ninetieth {
                                    Label("90th Percentile", systemImage: "checkmark")
                                        .foregroundColor(.orange)
                                } else {
                                    Text("90th Percentile")
                                }
                            }
                            
                            // "View Graphics" => line chart with error band
                            Button {
                                // This line triggers the chart navigation
                                showHistograms = true
                            } label: {
                                Text("View Graphics")
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3.decrease.circle")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        .preferredColorScheme(.dark)
                    }
                    .padding(.horizontal, 55)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.12))
                    
                    // Title row (black)
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
                            
                            // Tap zones for changing columns
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
                    
                    // Data table
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                        HStack(spacing: 0) {
                            // Left column (Week #)
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
                            
                            // Main columns in a TabView
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
                                        
                                        // Tap zones for nav left/right
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
                                    if atBottom != self.isAtBottom {
                                        self.isAtBottom = atBottom
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
    
    // MARK: - Jump to results button
    private var transitionToResultsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
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
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 250)
                HStack {
                    Spacer()
                    Button(action: {
                        isCancelled = true
                        isLoading = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                    }
                    .padding(.trailing, 20)
                }
                .offset(y: 220)
                
                InteractiveBitcoinSymbol3DSpinner()
                    .padding(.bottom, 30)
                
                VStack(spacing: 17) {
                    Text("Simulating: \(completedIterations) / \(totalIterations)")
                        .font(.body.monospacedDigit())
                        .foregroundColor(.white)
                    
                    ProgressView(value: Double(completedIterations), total: Double(totalIterations))
                        .tint(.blue)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .frame(width: 200)
                }
                .padding(.bottom, 20)
                
                if showTip {
                    Text(currentTip)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)
                        .lineLimit(nil)
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
        // Load CSV arrays (in your real code)
        historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
        sp500WeeklyReturns = loadSP500WeeklyReturns()
        
        isCancelled = false
        isLoading = true
        monteCarloResults = []
        completedIterations = 0
        
        // Decide which seed to use
        let finalSeed: UInt64?
        if simSettings.lockedRandomSeed {
            finalSeed = simSettings.seedValue
            simSettings.lastUsedSeed = simSettings.seedValue
        } else if simSettings.useRandomSeed {
            let newRandomSeed = UInt64.random(in: 0..<UInt64.max)
            finalSeed = newRandomSeed
            simSettings.lastUsedSeed = newRandomSeed
        } else {
            finalSeed = nil
            simSettings.lastUsedSeed = 0
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let total = inputManager.getParsedIterations(), total > 0 else {
                DispatchQueue.main.async { isLoading = false }
                return
            }
            DispatchQueue.main.async {
                totalIterations = total
            }
            
            let userInputCAGR = inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(inputManager.annualVolatility) ?? 1.0) / 100.0
            
            let userWeeks = simSettings.userWeeks
            let userPriceUSD = simSettings.initialBTCPriceUSD
            
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
            
            // (Optional) Local formatter
            func formatNumber(_ value: Double) -> String {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.groupingSeparator = ","
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
                return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
            }
            
            let medianFinalPrice = medianRun.last?.btcPriceUSD ?? -999
            print("[DEBUG] Median run final price = \(formatNumber(medianFinalPrice))")
            
            // Prepare to compute full percentile runs
            let finalRuns = allIterations.map { ($0.last?.btcPriceUSD ?? 0.0, $0) }
            var sortedRuns = finalRuns.sorted { $0.0 < $1.0 }
            
            let finalPrices = allIterations.compactMap { $0.last?.btcPriceUSD }
            let sortedPrices = finalPrices.sorted()
            if sortedPrices.count > 1 {
                let tenthIndex = Int(Double(sortedPrices.count - 1) * 0.1)
                let ninetiethIndex = Int(Double(sortedPrices.count - 1) * 0.9)
                
                let tenthValue = sortedPrices[tenthIndex]
                let ninetiethValue = sortedPrices[ninetiethIndex]
                
                print("[DEBUG] 10th percentile final price = \(formatNumber(tenthValue))")
                print("[DEBUG] 90th percentile final price = \(formatNumber(ninetiethValue))")
            } else {
                print("[DEBUG] Not enough runs to compute percentiles.")
            }
            
            // If user cancelled, bail out
            if self.isCancelled {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Sort runs by final portfolio value and pick 10th / median / 90th runs
            if !sortedRuns.isEmpty {
                let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex    = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                
                let tenthRun       = sortedRuns[tenthIndex].1
                let medianRun      = sortedRuns[medianIndex].1
                let ninetiethRun   = sortedRuns[ninetiethIndex].1
                
                DispatchQueue.main.async {
                    // Store each percentile in separate arrays
                    self.tenthPercentileResults     = tenthRun
                    self.medianResults              = medianRun
                    self.ninetiethPercentileResults = ninetiethRun
                    
                    // Default: show median
                    self.monteCarloResults   = medianRun
                    self.selectedPercentile  = .median
                    
                    // Update UI
                    self.isSimulationRun     = true
                    self.isLoading           = false
                    
                    // -------------------------------------
                    // Assign medianSimData / allSimData here
                    // so we can reference them later (e.g. for charts)
                    self.medianSimData = medianRun
                    self.allSimData    = allIterations
                    // -------------------------------------
                }
            } else {
                // Fallback if no runs
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            
            // (Optional) post-processing
            DispatchQueue.global(qos: .background).async {
                self.processAllResults(allIterations)
            }
        }
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

// MARK: - HistogramView (Placeholder)
struct HistogramView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text("Histograms Coming Soon!")
                .foregroundColor(.white)
                .font(.title)
        }
        .navigationTitle("Histograms")
    }
}
