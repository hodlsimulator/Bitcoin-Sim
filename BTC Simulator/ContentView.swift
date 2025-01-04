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

// MARK: - Snapshot Debugging Extension
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
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        
        // Debug print: log the snapshot size
        print("// DEBUG: snapshot() -> image size = \(image.size)")
        
        return image
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
}

// MARK: - ContentView
struct ContentView: View {

    @StateObject var inputManager: PersistentInputManager
    @StateObject var simSettings: SimulationSettings
    @StateObject var chartDataCache: ChartDataCache
    @StateObject var coordinator: SimulationCoordinator

    init() {
        let manager = PersistentInputManager()
        let settings = SimulationSettings()
        let cache = ChartDataCache()
        
        let simCoord = SimulationCoordinator(
            chartDataCache: cache,
            simSettings: settings,
            inputManager: manager
        )
        
        _inputManager = StateObject(wrappedValue: manager)
        _simSettings = StateObject(wrappedValue: settings)
        _chartDataCache = StateObject(wrappedValue: cache)
        _coordinator = StateObject(wrappedValue: simCoord)
    }

    // Various states
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
    
    @State private var showSettings = false
    @State private var showAbout = false
    @State private var showHistograms = false  // We'll present a .sheet now.
    @State private var showGraphics = false
    
    @State private var tenthPercentileResults: [SimulationData] = []
    @State private var medianResults: [SimulationData] = []
    @State private var ninetiethPercentileResults: [SimulationData] = []
    @State private var selectedPercentile: PercentileChoice = .median
    
    @State private var allSimData: [[SimulationData]] = []
    
    @State private var chartLoadingState: ChartLoadingState = .none
    
    @State private var oldIterationsValue: String = ""
    @State private var oldAnnualCAGRValue: String = ""
    @State private var oldAnnualVolatilityValue: String = ""
    
    @State private var showSnapshotView = false
    @State private var showSnapshotsDebug = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !coordinator.isSimulationRun {
                    parametersScreen
                    if !coordinator.isLoading && activeField == nil {
                        bottomIcons
                    }
                } else {
                    simulationResultsView
                }
                
                // Hide forward button if chart is building
                if !coordinator.isSimulationRun &&
                    !coordinator.monteCarloResults.isEmpty &&
                    !coordinator.isChartBuilding {
                    transitionToResultsButton
                }
                
                if coordinator.isLoading || coordinator.isChartBuilding {
                    loadingOverlayCombined
                }
            }
            // Keep these two navigation destinations if you like:
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(simSettings)
            }
            .navigationDestination(isPresented: $showAbout) {
                AboutView()
            }
            // Keep the debug navigation if needed:
            .navigationDestination(isPresented: $showSnapshotsDebug) {
                SnapshotsDebugView()
                    .environmentObject(coordinator.chartDataCache)
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
        // 2) Present the chart as a navigation destination using ForceReflowView:
        .navigationDestination(isPresented: $showHistograms) {
            ForceReflowView {
                if let existingChartData = coordinator.chartDataCache.allRuns {
                    MonteCarloResultsView(simulations: existingChartData)
                        .environmentObject(coordinator.chartDataCache)
                        .environmentObject(simSettings)
                } else {
                    Text("Loading chart…")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Overlay that shows simulation + chart generation phases
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
                    
                } else if coordinator.isChartBuilding {
                    VStack(spacing: 12) {
                        Text("Generating Chart…")
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
    
    private func invalidateChartIfInputChanged() {
        print("DEBUG: invalidateChartIfInputChanged() => clearing chartDataCache.")
        coordinator.chartDataCache.allRuns = nil
        coordinator.chartDataCache.storedInputsHash = nil
    }
    
    // MARK: - UI
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
        } else {
            EmptyView()
        }
    }
    
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
                
                if !coordinator.isLoading && !coordinator.isChartBuilding {
                    Button {
                        activeField = nil
                        coordinator.isLoading = true
                        coordinator.isChartBuilding = false
                        coordinator.runSimulation()
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
        .onTapGesture {
            activeField = nil
        }
    }
    
    private var simulationResultsView: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                Color(white: 0.12)
                    .edgesIgnoringSafeArea(.bottom)
                
                VStack(spacing: 0) {
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
                        
                        Button(action: {
                            print("// DEBUG: Chart button pressed.")
                            print("// DEBUG: chartDataCache.chartSnapshot == \(coordinator.chartDataCache.chartSnapshot == nil ? "nil" : "non-nil")")
                            
                            if let allRuns = coordinator.chartDataCache.allRuns {
                                print("// DEBUG: chartDataCache.allRuns has \(allRuns.count) runs.")
                            } else {
                                print("// DEBUG: chartDataCache.allRuns is nil.")
                            }
                            
                            // Instead of a navigation, show the sheet
                            showHistograms = true
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                    }
                    .padding(.horizontal, 55)
                    .padding(.vertical, 10)
                    .background(Color(white: 0.12))
                    
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
                    
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                        HStack(spacing: 0) {
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
                            
                            TabView(selection: $currentPage) {
                                ForEach(0..<columns.count, id: \.self) { index in
                                    ZStack {
                                        VStack(spacing: 0) {
                                            ForEach(coordinator.monteCarloResults.indices, id: \.self) { rowIndex in
                                                let rowResult = coordinator.monteCarloResults[rowIndex]
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
    
    // MARK: - Forward (transitionToResultsButton)
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
