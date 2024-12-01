//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 20/11/2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

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
    @Published var btcGrowthRate: String // Unused, can be removed if not needed

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
        self.btcGrowthRate = UserDefaults.standard.string(forKey: "btcGrowthRate") ?? "0.005" // Default: 0.5% weekly growth
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
        return Int(iterations.replacingOccurrences(of: ",", with: ""))
    }

    func getParsedAnnualCAGR() -> Double {
        let rawValue = annualCAGR.replacingOccurrences(of: ",", with: "")
        print("Debug: Raw Annual CAGR String = \(rawValue)") // Debug log
        guard let parsedValue = Double(rawValue) else {
            print("Debug: Parsing failed, returning default value.")
            return 40.0 // Default to 40% if parsing fails
        }
        return parsedValue // Don't divide by 100 here; handle that in the calculation
    }
}

extension Double {
    /// Formats the number as currency with thousands separator and 2 decimal places
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2 // Limit to 2 decimal places
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true // Use thousands separator
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    /// Formats the number for BTC with up to 8 decimal places
    func formattedBTC() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8 // Limit to 8 decimal places for BTC
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension View {
    @ViewBuilder
    func syncWithScroll<T>(of value: T, perform action: @escaping (T) -> Void) -> some View where T: Equatable {
        if #available(iOS 17, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}

struct ContentView: View {
    @State private var monteCarloResults: [SimulationData] = [] // Holds simulation results
    @State private var isLoading: Bool = false // Loading state for simulations
    @State private var pdfData: Data? // Holds generated PDF data
    @State private var showFileExporter = false // Controls file exporter visibility
    @State private var selectedWeek: String = "1" // Week number input
    @State private var btcPriceInput: String = "" // BTC price input
    @State private var portfolioValueInput: String = "" // Portfolio value input
    @State private var btcPriceMinInput: String = ""
    @State private var btcPriceMaxInput: String = ""
    @State private var portfolioValueMinInput: String = ""
    @State private var portfolioValueMaxInput: String = ""
    @State private var btcHoldingsMinInput: String = ""
    @State private var btcHoldingsMaxInput: String = ""
    @State private var btcHoldingsInput: String = "" // BTC holdings input
    @StateObject var inputManager = PersistentInputManager() // Use @StateObject to manage state
    @State private var isHeaderWidened: Bool = false // State to toggle header width
    @State private var volatilityEnabled: Bool = false // Default to enabled
    @State private var finalWeek90thPercentile: Double = 0.0
    @State private var isSimulationRun: Bool = false // Tracks if simulation has been run
    @State private var scrollToBottom: Bool = false // Triggers scroll to bottom
    @State private var isAtBottom: Bool = false // Tracks if at the bottom of the scroll

    // Define column headers and keys for dynamic access
    let columns: [(String, PartialKeyPath<SimulationData>)] = [
        ("Starting BTC (BTC)", \SimulationData.startingBTC),
        ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
        ("BTC Price USD", \SimulationData.btcPriceUSD),
        ("BTC Price EUR", \SimulationData.btcPriceEUR),
        ("Portfolio Value EUR", \SimulationData.portfolioValueEUR),
        ("Contribution EUR", \SimulationData.contributionEUR),
        ("Contribution Fee EUR", \SimulationData.contributionFeeEUR),
        ("Net Contribution BTC", \SimulationData.netContributionBTC),
        ("Withdrawal EUR", \SimulationData.withdrawalEUR)
    ]

    var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 10) {
                    if !isSimulationRun {
                        // Input fields and Run Simulation button
                        VStack(spacing: 10) {
                            InputField(title: "Iterations", text: $inputManager.iterations)
                            InputField(title: "Annual CAGR (%)", text: $inputManager.annualCAGR)
                            InputField(title: "Annual Volatility (%)", text: $inputManager.annualVolatility)

                            Button(action: {
                                // Reset to default column when running simulation
                                if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                                    currentPage = usdIndex
                                }
                                runSimulation()
                            }) {
                                Text("Run Simulation")
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                    } else {
                        ZStack {
                            // Results Table with added top padding
                            VStack {
                                Spacer().frame(height: 40) // Add space above the table
                                ResultsTable(
                                    monteCarloResults: monteCarloResults,
                                    columns: columns,
                                    currentPage: $currentPage, // Bind currentPage
                                    scrollToBottom: $scrollToBottom,
                                    isAtBottomParent: $isAtBottom, // Correct the argument label
                                    getValue: getValue
                                )
                            }

                            // Back button at top-left corner
                            VStack {
                                HStack {
                                    Button(action: {
                                        isSimulationRun = false
                                        lastViewedPage = currentPage // Save the last viewed column
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.white)
                                            .imageScale(.large)
                                            .padding()
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }

                            // Go-to-bottom button at bottom center
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
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    .padding()
                                }
                            }
                        }
                        .onAppear {
                            // Ensure data appears correctly
                            if monteCarloResults.isEmpty {
                                runSimulation() // Ensure simulation runs if data is missing
                            }
                        }
                    }
                }

                // Forward button overlay in the top-right corner
                if !isSimulationRun && !monteCarloResults.isEmpty {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                isSimulationRun = true
                                currentPage = lastViewedPage // Restore the last viewed column
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
            }
            .onAppear {
                // Ensure default column view on app load
                if isSimulationRun, monteCarloResults.isEmpty {
                    runSimulation()
                } else if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                    currentPage = usdIndex
                }
            }
        }

    // MARK: - State Variables
    @State private var lastViewedPage: Int = 0 // Tracks the last viewed column

    // MARK: - Page Navigation
    @State private var currentPage: Int = 0 // Tracks the current page
    let totalPages = 10 // Total number of pages (adjust as needed)

    // MARK: - Safeguards for NaN Errors
    private func validateValue(_ value: Double?) -> Double {
        guard let value = value, !value.isNaN, !value.isInfinite else {
            return 0.0 // Replace invalid values with a safe default
        }
        return value
    }

    // Use `validateValue` in your ResultsTable logic and simulation calculations:
    // Example: `let safeValue = validateValue(possibleNaNValue)`

    // Input Field Component
    struct InputField: View {
        let title: String
        @Binding var text: String

        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .frame(width: 200, alignment: .leading)
                TextField("Enter \(title)", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(width: 150)
            }
        }
    }

    struct ResultsTable: View {
        let monteCarloResults: [SimulationData]
        let columns: [(String, PartialKeyPath<SimulationData>)]
        @Binding var currentPage: Int
        @Binding var scrollToBottom: Bool
        @Binding var isAtBottomParent: Bool
        let getValue: (SimulationData, PartialKeyPath<SimulationData>) -> String

        var body: some View {
            VStack(spacing: 0) {
                // Header Row with Tap Gesture
                HStack(spacing: 0) {
                    // Weeks Header
                    Text("Week")
                        .frame(width: 60)
                        .font(.headline)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                    
                    // Main Column Header with Tap Gesture
                    ZStack {
                        // Main Column Header Text
                        Text(columns[currentPage].0)
                            .font(.headline)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Invisible Layer to Detect Taps Near Edges
                        GeometryReader { geometry in
                            // Define tap areas as narrow regions near the edges
                            HStack(spacing: 0) {
                                // Left Tap Area (Near Weeks Column)
                                Color.clear
                                    .frame(width: geometry.size.width * 0.2) // 20% width
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { value in
                                                let drag = value.translation
                                                let threshold: CGFloat = 10
                                                if abs(drag.width) < threshold && abs(drag.height) < threshold {
                                                    // Treat as tap
                                                    let tapX = value.location.x
                                                    if tapX < geometry.size.width * 0.2 {
                                                        // Left tap: Navigate to Previous Page
                                                        if currentPage > 0 {
                                                            withAnimation {
                                                                currentPage -= 1
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                    )
                                
                                Spacer() // Middle 60% where taps are ignored
                                
                                // Right Tap Area (Near Screen Edge)
                                Color.clear
                                    .frame(width: geometry.size.width * 0.2) // 20% width
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { value in
                                                let drag = value.translation
                                                let threshold: CGFloat = 10
                                                if abs(drag.width) < threshold && abs(drag.height) < threshold {
                                                    // Treat as tap
                                                    let tapX = value.location.x
                                                    if tapX > geometry.size.width * 0.8 {
                                                        // Right tap: Navigate to Next Page
                                                        if currentPage < columns.count - 1 {
                                                            withAnimation {
                                                                currentPage += 1
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                    )
                            }
                        }
                    }
                    .frame(height: 50) // Adjust height as needed
                }
                .background(Color.black)
                
                // Content Rows inside a single ScrollView
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        HStack(spacing: 0) {
                            // Fixed Weeks Column
                            VStack(spacing: 0) {
                                ForEach(monteCarloResults) { result in
                                    Text("\(result.week)")
                                        .frame(width: 60)
                                        .padding()
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .id("week-\(result.id)")
                                }
                            }
                            
                            // Data Column with TabView for Sliding Animation and Tap Gesture
                            TabView(selection: $currentPage) {
                                ForEach(0..<columns.count, id: \.self) { index in
                                    ZStack {
                                        // Data Content
                                        VStack(spacing: 0) {
                                            ForEach(monteCarloResults) { result in
                                                Text(getValue(result, columns[index].1))
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .padding()
                                                    .background(Color.black)
                                                    .foregroundColor(.white)
                                                    .id("data-\(result.id)")
                                            }
                                        }
                                        
                                        // Invisible Layer to Detect Taps Near Edges
                                        GeometryReader { geometry in
                                            HStack(spacing: 0) {
                                                // Left Tap Area (Near Weeks Column)
                                                // Color.red.opacity(0.3) // Debug: Red for left tap area
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2) // 20% width
                                                    .contentShape(Rectangle())
                                                    .gesture(
                                                        DragGesture(minimumDistance: 0)
                                                            .onEnded { value in
                                                                let drag = value.translation
                                                                let threshold: CGFloat = 10
                                                                if abs(drag.width) < threshold && abs(drag.height) < threshold {
                                                                    // Treat as tap
                                                                    if currentPage > 0 {
                                                                        withAnimation {
                                                                            currentPage -= 1
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                    )
                                                
                                                Spacer() // Middle 60% where taps are ignored
                                                
                                                // Right Tap Area (Near Screen Edge)
                                                // Color.blue.opacity(0.3) // Debug: Blue for right tap area
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2) // 20% width
                                                    .contentShape(Rectangle())
                                                    .gesture(
                                                        DragGesture(minimumDistance: 0)
                                                            .onEnded { value in
                                                                let drag = value.translation
                                                                let threshold: CGFloat = 10
                                                                if abs(drag.width) < threshold && abs(drag.height) < threshold {
                                                                    // Treat as tap
                                                                    if currentPage < columns.count - 1 {
                                                                        withAnimation {
                                                                            currentPage += 1
                                                                        }
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
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Disable page indicators
                            .frame(width: UIScreen.main.bounds.width - 60) // Adjust width to account for weeks column
                        }
                        .onChange(of: scrollToBottom) { value in
                            if value {
                                // Scroll to the last item
                                if let lastResult = monteCarloResults.last {
                                    withAnimation {
                                        scrollProxy.scrollTo("week-\(lastResult.id)", anchor: .bottom)
                                    }
                                    scrollToBottom = false // Reset the trigger
                                }
                            }
                        }
                        .onAppear {
                            // Automatically scroll to bottom when results appear
                            if scrollToBottom, let lastResult = monteCarloResults.last {
                                withAnimation {
                                    scrollProxy.scrollTo("week-\(lastResult.id)", anchor: .bottom)
                                }
                                scrollToBottom = false
                            }
                        }
                        .background(GeometryReader { geometry -> Color in
                            // Detect if user is at the bottom
                            DispatchQueue.main.async {
                                let isAtBottom = geometry.frame(in: .global).maxY <= UIScreen.main.bounds.height
                                if isAtBottom != isAtBottomParent {
                                    isAtBottomParent = isAtBottom
                                }
                            }
                            return Color.clear
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - Functions

    private func runSimulation() {
        isLoading = true
        monteCarloResults = [] // Clear previous results

        DispatchQueue.global(qos: .userInitiated).async {
            // Historical data
            let annualCAGR = inputManager.getParsedAnnualCAGR() / 100.0
            let annualVolatility = (Double(inputManager.annualVolatility) ?? 1.0) / 100.0
            let weeklyDeterministicGrowth = pow(1 + annualCAGR, 1.0 / 52.0) - 1.0
            let weeklyVolatility = annualVolatility / sqrt(52.0)
            let exchangeRateEURUSD = 1.06
            let totalWeeks = 1040

            guard let totalIterations = inputManager.getParsedIterations(), totalIterations > 0 else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Invalid number of iterations.")
                }
                return
            }

            // Store all results
            var allResults: [[SimulationData]] = []

            // Run simulation for the specified number of iterations
            for _ in 1...totalIterations {
                var results: [SimulationData] = []

                // Week 1 (Hardcoded)
                results.append(SimulationData(
                    id: UUID(),
                    week: 1,
                    startingBTC: 0.0,
                    netBTCHoldings: 0.00469014,
                    btcPriceUSD: 76_532.03,
                    btcPriceEUR: 71_177.69,
                    portfolioValueEUR: 333.83,
                    contributionEUR: 378.00,
                    contributionFeeEUR: 2.46,
                    netContributionBTC: 0.00527613,
                    withdrawalEUR: 0.0
                ))

                // Week 2 (Hardcoded)
                results.append(SimulationData(
                    id: UUID(),
                    week: 2,
                    startingBTC: 0.00469014,
                    netBTCHoldings: 0.00530474,
                    btcPriceUSD: 92_000.00,
                    btcPriceEUR: 86_792.45,
                    portfolioValueEUR: 465.00,
                    contributionEUR: 60.00,
                    contributionFeeEUR: 0.21,
                    netContributionBTC: 0.00069130,
                    withdrawalEUR: 0.0
                ))

                // Week 3 (Hardcoded)
                results.append(SimulationData(
                    id: UUID(),
                    week: 3,
                    startingBTC: 0.00530474,
                    netBTCHoldings: 0.00608283,
                    btcPriceUSD: 95_000.00,
                    btcPriceEUR: 89_622.64,
                    portfolioValueEUR: 547.00,
                    contributionEUR: 70.00,
                    contributionFeeEUR: 0.25,
                    netContributionBTC: 0.00078105,
                    withdrawalEUR: 0.0
                ))

                // Simulation loop (week 4 onwards)
                for week in 4...totalWeeks {
                    let previous = results[week - 2]

                    // Generate random shock
                    let randomShock = randomNormal(mean: 0, standardDeviation: weeklyVolatility)
                    let adjustedGrowthFactor = 1 + weeklyDeterministicGrowth + randomShock

                    // Update BTC price
                    var btcPriceUSD = previous.btcPriceUSD * adjustedGrowthFactor
                    if Double.random(in: 0..<1) < 0.005 { // Rare crash simulation
                        btcPriceUSD *= (1 - Double.random(in: 0.1...0.3))
                    }
                    btcPriceUSD = max(btcPriceUSD, 1_000.0) // Apply price floor

                    let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD

                    // Contribution logic
                    let contributionEUR = week <= 52 ? 60.0 : 100.0
                    let contributionFeeEUR = contributionEUR * 0.0035
                    let netContributionBTC = (contributionEUR - contributionFeeEUR) / btcPriceEUR

                    // Withdrawal logic
                    let withdrawalEUR = previous.portfolioValueEUR > 30_000 ? 100.0 : 0.0
                    let withdrawalBTC = withdrawalEUR / btcPriceEUR

                    // Update net BTC holdings and portfolio value
                    let netBTCHoldings = max(0, previous.netBTCHoldings + netContributionBTC - withdrawalBTC)
                    let portfolioValueEUR = netBTCHoldings * btcPriceEUR

                    results.append(SimulationData(
                        id: UUID(),
                        week: week,
                        startingBTC: previous.netBTCHoldings,
                        netBTCHoldings: netBTCHoldings,
                        btcPriceUSD: btcPriceUSD,
                        btcPriceEUR: btcPriceEUR,
                        portfolioValueEUR: portfolioValueEUR,
                        contributionEUR: contributionEUR,
                        contributionFeeEUR: contributionFeeEUR,
                        netContributionBTC: netContributionBTC,
                        withdrawalEUR: withdrawalEUR
                    ))
                }
                allResults.append(results)
            }

            // Update UI on main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.monteCarloResults = allResults.last ?? []
                self.isSimulationRun = true

                print("Simulation complete. Total iterations: \(allResults.count)")
                print("Example result: \(self.monteCarloResults.first ?? SimulationData.placeholder)")

                // Process histograms on a background thread
                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allResults)
                    self.generateHistogramForResults(
                        results: self.monteCarloResults,
                        filePath: "/Users/conor/Desktop/PS Batch/portfolio_growth_histogram.png"
                    )
                }
            }
        }
    }

    /// Generate a random value from a normal distribution
    func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
        return z0 * standardDeviation + mean
    }

    // Optional: Process all results for further analysis
    private func processAllResults(_ allResults: [[SimulationData]]) {
        let portfolioValues = allResults.flatMap { $0.map { $0.portfolioValueEUR } }
        createHistogramWithLogBins(
            data: portfolioValues,
            title: "Portfolio Growth",
            fileName: "/Users/conor/Desktop/PS Batch/portfolio_growth_histogram.png"
        )
    }

    func generateHistogramForResults(results: [SimulationData], filePath: String) {
        // Extract the portfolio values for all weeks
        let portfolioValues = results.map { $0.portfolioValueEUR }

        // Call the refined histogram generation function
        createHistogramWithLogBins(
            data: portfolioValues,
            title: "Portfolio Value Distribution",
            fileName: filePath,
            lowerPercentile: 0.01,  // Discard the bottom 1%
            upperPercentile: 0.99,  // Discard the top 1%
            binCount: 20,          // Number of bins for the histogram
            rotateLabels: true      // Rotate x-axis labels for better readability
        )
    }

    private func createHistogramWithLogBins(
        data: [Double],
        title: String,
        fileName: String,
        lowerPercentile: Double = 0.01,
        upperPercentile: Double = 0.99,
        binCount: Int = 20,
        rotateLabels: Bool = true
    ) {
        // Ensure data is valid
        guard let minValue = data.min(), let maxValue = data.max(), minValue > 0 else {
            print("Error: No valid data to generate histogram.")
            return
        }

        let filteredData = data.filter { $0 > minValue && $0 < maxValue }
        guard !filteredData.isEmpty else {
            print("Error: No valid data after filtering.")
            return
        }

        let logMinValue = log10(minValue)
        let logMaxValue = log10(maxValue)
        let binWidth = (logMaxValue - logMinValue) / Double(binCount)
        var bins = [Int](repeating: 0, count: binCount)

        for value in filteredData {
            let logValue = log10(value)
            let binIndex = min(Int((logValue - logMinValue) / binWidth), binCount - 1)
            bins[binIndex] += 1
        }

        let totalDataCount = filteredData.count
        let width: CGFloat = 1000
        let height: CGFloat = 700
        let margin: CGFloat = 100

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext

            // Background
            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Axes
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(1.5)

            // X-Axis
            context.move(to: CGPoint(x: margin, y: height - margin))
            context.addLine(to: CGPoint(x: width - margin, y: height - margin))
            context.strokePath()

            // Y-Axis
            context.move(to: CGPoint(x: margin, y: margin))
            context.addLine(to: CGPoint(x: margin, y: height - margin))
            context.strokePath()

            // Add Y-axis labels
            for i in 0...5 {
                let percentage = Double(i) * 100 / 5.0
                let yPosition = height - margin - CGFloat(i) * (height - 2 * margin) / 5
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.white
                ]
                NSString(string: "\(Int(percentage))%").draw(at: CGPoint(x: margin - 50, y: yPosition - 8), withAttributes: labelAttributes)
            }

            // Draw histogram bars
            let barWidth = (width - 2 * margin) / CGFloat(binCount)
            for (index, frequency) in bins.enumerated() {
                let percentage = Double(frequency) / Double(totalDataCount) * 100
                let barHeight = CGFloat(percentage / 100.0) * (height - 2 * margin)
                let barRect = CGRect(
                    x: margin + CGFloat(index) * barWidth,
                    y: height - margin - barHeight,
                    width: barWidth - 2,
                    height: barHeight
                )
                context.setFillColor(UIColor.systemBlue.cgColor)
                context.fill(barRect)
            }
        }

        // Save the image as PNG
        if let pngData = image.pngData() {
            do {
                try pngData.write(to: URL(fileURLWithPath: fileName))
                print("Histogram saved successfully at \(fileName)")
            } catch {
                print("Error saving histogram: \(error)")
            }
        } else {
            print("Error: Failed to generate PNG data.")
        }
    }

    // Helper for formatting numbers with separators
    struct NumberFormatterWithSeparator {
        static let shared: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = true
            formatter.groupingSize = 3
            formatter.maximumFractionDigits = 2 // Allows up to 2 decimal places
            formatter.minimumFractionDigits = 2
            return formatter
        }()
    }

    // Redefine getValue inside ContentView
    private func getValue(_ item: SimulationData, _ keyPath: PartialKeyPath<SimulationData>) -> String {
        if let value = item[keyPath: keyPath] as? Double {
            // Decide the formatting based on keyPath
            switch keyPath {
            case \SimulationData.startingBTC,
                 \SimulationData.netBTCHoldings,
                 \SimulationData.netContributionBTC:
                // Format as BTC with up to 8 decimal places
                return value.formattedBTC()
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.contributionEUR,
                 \SimulationData.contributionFeeEUR,
                 \SimulationData.withdrawalEUR:
                // Format as currency with thousands separators and 2 decimal places
                return value.formattedCurrency()
            default:
                // Default formatting
                return String(format: "%.2f", value)
            }
        } else if let value = item[keyPath: keyPath] as? Int {
            return "\(value)"
        } else {
            return ""
        }
    }
}
