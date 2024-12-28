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
    @Published var iterations: String {
        didSet { UserDefaults.standard.set(iterations, forKey: "iterations") }
    }
    @Published var annualCAGR: String {
        didSet { UserDefaults.standard.set(annualCAGR, forKey: "annualCAGR") }
    }
    @Published var annualVolatility: String {
        didSet { UserDefaults.standard.set(annualVolatility, forKey: "annualVolatility") }
    }
    @Published var selectedWeek: String
    @Published var btcPriceMinInput: String
    @Published var btcPriceMaxInput: String
    @Published var portfolioValueMinInput: String
    @Published var portfolioValueMaxInput: String
    @Published var btcHoldingsMinInput: String
    @Published var btcHoldingsMaxInput: String
    @Published var btcGrowthRate: String

    init() {
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
    }

    func saveToDefaults() {
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

// MARK: - 3D Spinner (loading overlay)
// MARK: - 3D Spinner (loading overlay)
// We now rely on OfficialBitcoinLogo from BitcoinShapes.swift (no redeclaration needed here).

struct InteractiveBitcoinSymbol3DSpinner: View {
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = -90
    @State private var rotationZ: Double = 0
    @State private var spinSpeed: Double = 10
    @State private var lastUpdate = Date()
    
    var body: some View {
        ZStack {
            // Use OfficialBitcoinLogo (defined in BitcoinShapes.swift)
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

// MARK: - ContentView
struct ContentView: View {
    
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
    
    let loadingTips = [
        // Existing "technical simulation" messages:
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
        
        // New "tips on how to use the app" messages:
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
    
    var body: some View {
        ZStack {
            // *** Use Color(white: 0.14) instead of 0.10 for the simulation background. ***
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
            
            Color.clear
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture()
                        .onEnded {
                            activeField = nil
                        }
                )
            
            if !isSimulationRun {
                parametersScreen
                if !isLoading {
                    if activeField == nil {
                        bottomIcons
                    }
                }
            } else {
                simulationResultsView
            }
            
            if !isSimulationRun && !monteCarloResults.isEmpty {
                transitionToResultsButton
            }
            
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
    
    // MARK: - Bottom icons (About + Settings)
    private var bottomIcons: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    showAbout = true
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .padding()
                }
                .padding(.leading, 15)
                
                Spacer()
                
                Button(action: {
                    showSettings = true
                }) {
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
                VStack {
                    Spacer().frame(height: 40)
                    
                    VStack(spacing: 0) {
                        // Title row
                        HStack(spacing: 0) {
                            Text("Week")
                                .frame(width: 60, alignment: .leading)
                                .font(.headline)
                                .padding(.leading, 50)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .foregroundColor(.white)
                            
                            ZStack {
                                Text(columns[currentPage].0)
                                    .font(.headline)
                                    .padding(.leading, 100)
                                    .padding(.vertical, 8)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
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
                        .background(Color.orange)
                        
                        // Data table
                        ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                            HStack(spacing: 0) {
                                // Left column (Week numbers)
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
                                            
                                            // Tap areas for horizontal scroll
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
                }
                .onAppear {
                    contentScrollProxy = scrollProxy
                }
                .onDisappear {
                    UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                // “Back” button top-left
                VStack {
                    HStack {
                        Button(action: {
                            UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                            UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                            lastViewedPage = currentPage
                            isSimulationRun = false
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding(.leading, 50)
                                .padding(.vertical, 8)
                        }
                        Spacer()
                    }
                    Spacer()
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
        // Load CSV arrays
        historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
        sp500WeeklyReturns = loadSP500WeeklyReturns()
        
        isCancelled = false
        isLoading = true
        monteCarloResults = []
        completedIterations = 0
        
        // Decide which seed to use.
        let finalSeed: UInt64?
        if simSettings.lockedRandomSeed {
            // If locked, use the locked seed.
            finalSeed = simSettings.seedValue
            simSettings.lastUsedSeed = simSettings.seedValue
        } else if simSettings.useRandomSeed {
            // If unlocked with "use random seed," generate a fresh random for each run.
            let newRandomSeed = UInt64.random(in: 0..<UInt64.max)
            finalSeed = newRandomSeed
            simSettings.lastUsedSeed = newRandomSeed
        } else {
            // If unlocked but "useRandomSeed" is false, pass nil => let the sim pick internally
            finalSeed = nil
            simSettings.lastUsedSeed = 0 // or leave as-is if you prefer
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
            
            let (medianRun, allIterations) = runMonteCarloSimulationsWithProgress(
                settings: simSettings,
                annualCAGR: userInputCAGR,
                annualVolatility: userInputVolatility,
                correlationWithSP500: 0.0,
                exchangeRateEURUSD: 1.06,
                totalWeeks: 1040,
                iterations: total,
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
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.monteCarloResults = medianRun
                self.isSimulationRun = true
            }
            
            DispatchQueue.global(qos: .background).async {
                self.processAllResults(allIterations)
            }
        }
    }
    
    private func startTipCycle() {
        showTip = false
        tipTimer?.invalidate()
        tipTimer = nil
        
        // Show the first tip after 4s (instead of 5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            currentTip = loadingTips.randomElement() ?? ""
            withAnimation(.easeInOut(duration: 2)) {
                showTip = true
            }
        }
        
        // Then switch tips every 20s (instead of 25s)
        tipTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                showTip = false
            }
            // Hide for 4s (instead of 7s), then show the next tip
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
