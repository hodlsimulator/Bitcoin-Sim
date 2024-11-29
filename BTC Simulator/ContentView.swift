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
    @Published var iterations: String = "1000" // Default value
    @Published var annualCAGR: String // BTC Annual CAGR (%)
    @Published var annualVolatility: String // BTC Annual Volatility (%)
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
        self.annualVolatility = UserDefaults.standard.string(forKey: "annualVolatility") ?? "80.0" // Default: 80%
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
    @State private var iterations: String = "1000" // Number of iterations
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
    @State private var dataColumnsOffset: CGPoint = .zero // Add this state variable
    
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
                    // Results Table
                    ResultsTable(
                        monteCarloResults: monteCarloResults,
                        columns: columns,
                        scrollToBottom: $scrollToBottom,
                        getValue: getValue
                    )
                }
            }
        }
    }
    
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
    
    struct WeeksColumn: View {
        let monteCarloResults: [SimulationData]
        let getValue: (SimulationData, PartialKeyPath<SimulationData>) -> String // Pass getValue
        let columns: [(String, PartialKeyPath<SimulationData>)] // Pass columns
        @Binding var sharedScrollOffset: CGFloat

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Sticky Week Header
                        Text("Week")
                            .font(.headline)
                            .frame(width: 60)
                            .padding()
                            .background(Color.black.opacity(0.9))
                            .foregroundColor(.white)

                        // Week Data
                        ForEach(monteCarloResults, id: \.id) { result in
                            Text("\(result.week)")
                                .frame(width: 60)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .id(result.id)
                        }
                    }
                }
            }
        }
    }

    struct DataColumn: View {
        let columnTitle: String
        let monteCarloResults: [SimulationData]
        let keyPath: PartialKeyPath<SimulationData>
        let getValue: (SimulationData, PartialKeyPath<SimulationData>) -> String // Pass getValue
        @Binding var sharedScrollOffset: CGFloat

        var body: some View {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Sticky Column Header
                        Text(columnTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.9))
                            .foregroundColor(.white)

                        // Column Data
                        ForEach(monteCarloResults, id: \.id) { result in
                            Text(getValue(result, keyPath)) // Use getValue here
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .id(result.id)
                        }
                    }
                }
            }
        }
    }

    struct ResultsTable: View {
        let monteCarloResults: [SimulationData]
        let columns: [(String, PartialKeyPath<SimulationData>)]
        @Binding var scrollToBottom: Bool
        @State private var selectedColumnIndex: Int = 0
        let getValue: (SimulationData, PartialKeyPath<SimulationData>) -> String

        var body: some View {
            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    // Weeks Header
                    Text("Week")
                        .frame(width: 60)
                        .font(.headline)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)

                    // Main Column Header (updates based on selected column)
                    Text(columns[selectedColumnIndex].0)
                        .font(.headline)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // Content Rows
                ScrollView(.vertical, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 0) {
                        // Weeks Column
                        VStack(spacing: 0) {
                            ForEach(monteCarloResults, id: \.id) { result in
                                Text("\(result.week)")
                                    .frame(width: 60)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                            }
                        }

                        // Main Data Columns (swipeable)
                        TabView(selection: $selectedColumnIndex) {
                            ForEach(columns.indices, id: \.self) { index in
                                VStack(spacing: 0) {
                                    ForEach(monteCarloResults, id: \.id) { result in
                                        Text(getValue(result, columns[index].1))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding()
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                    }
                                }
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(width: UIScreen.main.bounds.width - 60) // Adjust the width as needed
                    }
                }
            }
        }
    }
    
    // Enum to track active ScrollView
    enum ScrollViewType {
        case week
        case main
        case none
    }

    private func synchronizeScroll(
        weekProxy: ScrollViewProxy,
        dataProxy: ScrollViewProxy,
        visibleID: UUID
    ) {
        withAnimation {
            weekProxy.scrollTo(visibleID, anchor: .top)
            dataProxy.scrollTo(visibleID, anchor: .top)
        }
    }
    
    // PreferenceKey for tracking vertical scroll offset
    struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0.0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
    
    struct StickyHeader<Content: View>: View {
        let content: Content

        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            VStack(spacing: 0) {
                content
                    .background(Color.black.opacity(0.9))
                    .foregroundColor(.white)
                    .zIndex(1) // Ensure header stays on top
                Spacer()
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

    private func calculate90thPercentile(allResults: [[SimulationData]]) -> [Double] {
        var percentileResults: [Double] = []
        let totalWeeks = allResults.first?.count ?? 0

        for week in 0..<totalWeeks {
            let portfolioValues = allResults.map { $0[week].portfolioValueEUR }
            let sortedValues = portfolioValues.sorted()
            let percentileIndex = Int(Double(sortedValues.count - 1) * 0.9)
            percentileResults.append(sortedValues[percentileIndex])
        }

        return percentileResults
    }

    private func processAllIterations(_ allResults: [[SimulationData]]) -> [String: [String: Double]] {
        var statistics: [String: [String: Double]] = [:]

        let totalIterations = allResults.count
        guard totalIterations > 0 else { return statistics }

        let weeks = allResults[0].count

        for weekIndex in 0..<weeks {
            var portfolioValues: [Double] = []

            for iteration in allResults {
                portfolioValues.append(iteration[weekIndex].portfolioValueEUR)
            }

            let mean = portfolioValues.reduce(0, +) / Double(totalIterations)
            let median = calculateMedian(values: portfolioValues)
            let standardDeviation = calculateStandardDeviation(values: portfolioValues, mean: mean)
            let percentile90 = calculatePercentile(values: portfolioValues, percentile: 90)
            let percentile10 = calculatePercentile(values: portfolioValues, percentile: 10)

            statistics["Week \(weekIndex + 1)"] = [
                "Mean": mean,
                "Median": median,
                "Standard Deviation": standardDeviation,
                "90th Percentile": percentile90,
                "10th Percentile": percentile10
            ]
        }

        return statistics
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
        // Validate data
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

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.white
            ]
            NSString(string: title).draw(at: CGPoint(x: 100, y: height - 50), withAttributes: titleAttributes)

            // Draw X-axis and Y-axis
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(1.5)

            // X-axis
            cgContext.move(to: CGPoint(x: 100, y: height - 100))
            cgContext.addLine(to: CGPoint(x: width - 100, y: height - 100))
            cgContext.strokePath()

            // Y-axis
            cgContext.move(to: CGPoint(x: 100, y: 100))
            cgContext.addLine(to: CGPoint(x: 100, y: height - 100))
            cgContext.strokePath()

            // Add Y-axis labels
            for i in 0...5 {
                let percentage = Double(i) * 100 / 5.0
                let yPosition = height - 100 - CGFloat(i) * 100
                let labelAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.white
                ]
                NSString(string: "\(Int(percentage))%").draw(at: CGPoint(x: 60, y: yPosition - 8), withAttributes: labelAttributes)
            }

            // Draw histogram bars
            let barWidth = (width - 200) / CGFloat(binCount)
            for (index, frequency) in bins.enumerated() {
                let percentage = Double(frequency) / Double(totalDataCount) * 100
                let barHeight = CGFloat(percentage / 100.0) * (height - 200)
                let barRect = CGRect(x: 100 + CGFloat(index) * barWidth, y: height - 100 - barHeight, width: barWidth - 2, height: barHeight)
                cgContext.setFillColor(UIColor.systemBlue.cgColor)
                cgContext.fill(barRect)
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
    
    struct CurrencyFormatter {
        static let shared: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2
            formatter.currencySymbol = "" // Set to empty if you don't want the currency symbol
            return formatter
        }()
    }
    
    private func formattedBinding(for keyPath: ReferenceWritableKeyPath<PersistentInputManager, String>) -> Binding<String> {
            Binding<String>(
                get: {
                    let rawValue = inputManager[keyPath: keyPath]
                    guard let number = Double(rawValue) else { return rawValue } // Return raw if invalid
                    return NumberFormatterWithSeparator.shared.string(from: NSNumber(value: number)) ?? rawValue
                },
                set: { newValue in
                    let cleanedValue = newValue.replacingOccurrences(of: ",", with: "") // Remove separators
                    if Double(cleanedValue) != nil || cleanedValue.isEmpty {
                        inputManager.updateValue(keyPath, to: cleanedValue) // Update if valid or empty
                    }
                }
            )
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
    
    func realTimeFormattedBinding(for keyPath: ReferenceWritableKeyPath<PersistentInputManager, String>) -> Binding<String> {
        Binding<String>(
            get: {
                // Display with separator
                let rawValue = inputManager[keyPath: keyPath]
                guard let number = Double(rawValue.replacingOccurrences(of: ",", with: "")) else { return rawValue }
                return NumberFormatterWithSeparator.shared.string(from: NSNumber(value: number)) ?? rawValue
            },
            set: { newValue in
                // Remove separator for storage
                let cleanedValue = newValue.replacingOccurrences(of: ",", with: "")
                if let doubleValue = Double(cleanedValue), doubleValue >= 0 {
                    inputManager.updateValue(keyPath, to: cleanedValue)
                } else if cleanedValue.isEmpty {
                    inputManager.updateValue(keyPath, to: "")
                }
            }
        )
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
            let yPosition = height - margin - CGFloat(i) * 100
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
            NSString(string: "\(Int(percentage))%").draw(at: CGPoint(x: margin - 40, y: yPosition - 8), withAttributes: labelAttributes)
        }

        // Draw histogram bars
        let barWidth = (width - 2 * margin) / CGFloat(binCount)
        for (index, frequency) in bins.enumerated() {
            let percentage = Double(frequency) / Double(totalDataCount) * 100
            let barHeight = CGFloat(percentage / 100.0) * (height - 2 * margin)
            let barRect = CGRect(x: margin + CGFloat(index) * barWidth, y: height - margin - barHeight, width: barWidth - 2, height: barHeight)
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

// Place this struct outside the ContentView struct but within the same file
struct PDFDocumentData: FileDocument {
    static var readableContentTypes = [UTType.pdf]

    var data: Data
    var fileName: String

    init(data: Data, fileName: String) {
        self.data = data
        self.fileName = fileName
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        fileName = "BTCMonteCarloResults.pdf"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

private func createRefinedHistogram(
    data: [Double],
    title: String,
    fileName: String,
    lowerDiscardPercentile: Double = 0.10,
    upperDiscardPercentile: Double = 0.05,
    rotateLabels: Bool = true
) {
    let width: CGFloat = 1000
    let height: CGFloat = 700
    let margin: CGFloat = 100

    // Filter data to remove outliers
    let sortedData = data.sorted()
    let totalCount = sortedData.count
    let lowerIndex = Int(Double(totalCount) * lowerDiscardPercentile)
    let upperIndex = Int(Double(totalCount) * (1.0 - upperDiscardPercentile))
    let filteredData = Array(sortedData[lowerIndex..<upperIndex])

    guard let minValue = filteredData.min(), let maxValue = filteredData.max() else {
        print("No data available for histogram.")
        return
    }

    let binCount = 15
    let binWidth = (maxValue - minValue) / Double(binCount)
    var bins = [Int](repeating: 0, count: binCount)
    for value in filteredData {
        let binIndex = min(Int((value - minValue) / binWidth), binCount - 1)
        bins[binIndex] += 1
    }

    // Use UIGraphicsImageRenderer for drawing
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
    let image = renderer.image { rendererContext in
        let context = rendererContext.cgContext

        // Background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.white
        ]
        NSString(string: title).draw(at: CGPoint(x: margin, y: margin - 40), withAttributes: titleAttributes)

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

        // Draw bars
        let barWidth = (width - 2 * margin) / CGFloat(binCount)
        let maxFrequency = bins.max() ?? 1
        for (index, frequency) in bins.enumerated() {
            let barHeight = CGFloat(frequency) / CGFloat(maxFrequency) * (height - 2 * margin)
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

    // Save the image
    if let pngData = image.pngData() {
        do {
            try pngData.write(to: URL(fileURLWithPath: fileName))
            print("Histogram saved to \(fileName)")
        } catch {
            print("Error saving histogram: \(error)")
        }
    } else {
        print("Failed to generate PNG data.")
    }
}
 
private func createRefinedHistogramWithFilters(
    data: [Double],
    title: String,
    fileName: String,
    minThreshold: Double,
    maxThreshold: Double,
    discardPercentile: Double,
    rotateLabels: Bool = true
) {
    let width: CGFloat = 1000
    let height: CGFloat = 700
    let margin: CGFloat = 100

    print("Generating histogram: \(title)")
    print("Output file: \(fileName)")
    print("Data count before filtering: \(data.count)")

    // Filter data by user-defined thresholds
    let filteredData = data.filter { $0 >= minThreshold && $0 <= maxThreshold }
    print("Filtered data for \(title): \(filteredData.count) values within range \(minThreshold)-\(maxThreshold)")

    // Check if data exists after filtering
    guard !filteredData.isEmpty else {
        print("No data to create histogram for \(title). Skipping graph.")
        return
    }

    // Discard extreme values (percentiles)
    let sortedData = filteredData.sorted()
    let totalCount = sortedData.count
    let lowerIndex = Int(Double(totalCount) * discardPercentile)
    let upperIndex = Int(Double(totalCount) * (1.0 - discardPercentile))
    let finalData = Array(sortedData[lowerIndex..<upperIndex])
    print("Data count after discarding outliers: \(finalData.count)")

    guard !finalData.isEmpty else {
        print("No data left after percentile filtering for \(title).")
        return
    }

    // Create bins for the histogram
    let minValue = finalData.min() ?? minThreshold
    let maxValue = finalData.max() ?? maxThreshold
    let binCount = 15
    let binWidth = (maxValue - minValue) / Double(binCount)
    var bins = [Int](repeating: 0, count: binCount)

    for value in finalData {
        let binIndex = min(Int((value - minValue) / binWidth), binCount - 1)
        bins[binIndex] += 1
    }

    print("Bins for \(title): \(bins)")
    print("Bin Width: \(binWidth), Min: \(minValue), Max: \(maxValue)")

    // Calculate the maximum frequency percentage for y-axis scaling
    let maxFrequency = bins.max() ?? 1
    let maxPercentage = Double(maxFrequency) / Double(finalData.count) * 100.0

    // Use UIGraphicsImageRenderer for drawing
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
    let image = renderer.image { rendererContext in
        let context = rendererContext.cgContext

        // Background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.white
        ]
        NSString(string: title).draw(
            at: CGPoint(x: margin, y: margin - 40),
            withAttributes: titleAttributes
        )

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

        // Draw y-axis percentage labels
        let yAxisStep = 10 // Steps in percentages (e.g., 0%, 10%, 20%)
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.white
        ]
        for percentage in stride(from: 0, through: Int(maxPercentage), by: yAxisStep) {
            let yPosition = height - margin - CGFloat(percentage) / 100.0 * (height - 2 * margin)
            let label = "\(percentage)%"
            NSString(string: label).draw(
                at: CGPoint(x: margin - 50, y: yPosition - 8), // Align labels with the ticks
                withAttributes: labelAttributes
            )

            // Draw gridline
            context.setStrokeColor(UIColor.gray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: margin, y: yPosition))
            context.addLine(to: CGPoint(x: width - margin, y: yPosition))
            context.strokePath()
        }

        // Draw bars
        let barWidth = (width - 2 * margin) / CGFloat(binCount)
        for (index, frequency) in bins.enumerated() {
            let percentage = Double(frequency) / Double(finalData.count) * 100.0
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

        // Draw x-axis labels
        for i in 0...binCount {
            let x = margin + CGFloat(i) * barWidth
            let labelValue = minValue + Double(i) * binWidth
            let formattedLabel = String(format: "%.2f", labelValue)

            if rotateLabels {
                let labelPosition = CGPoint(x: x - 15, y: height - margin + 20)
                context.saveGState()
                context.translateBy(x: labelPosition.x, y: labelPosition.y)
                context.rotate(by: -CGFloat.pi / 4)
                NSString(string: formattedLabel).draw(at: .zero, withAttributes: labelAttributes)
                context.restoreGState()
            } else {
                NSString(string: formattedLabel).draw(
                    at: CGPoint(x: x - 20, y: height - margin + 10),
                    withAttributes: labelAttributes
                )
            }
        }
    }

    // Save the image
    if let pngData = image.pngData() {
        do {
            try pngData.write(to: URL(fileURLWithPath: fileName))
            print("Histogram saved to \(fileName)")
        } catch {
            print("Error saving histogram: \(error)")
        }
    } else {
        print("Failed to generate PNG data.")
    }
}
 
private func generatePDFData(results: [SimulationData]) -> Data? {
    print("Starting PDF generation...")

    // PDF page size
    let pageWidth: CGFloat = 1400
    let pageHeight: CGFloat = 792
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

    // Create a UIGraphicsPDFRenderer
    let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let pdfData = pdfRenderer.pdfData { context in
        var currentY: CGFloat = 50
        let headerFont = UIFont.boldSystemFont(ofSize: 10)
        let rowFont = UIFont.systemFont(ofSize: 10)

        // Headers
        let headers = ["Week", "Starting BTC", "Net BTC Holdings", "BTC Price USD",
                       "BTC Price EUR", "Portfolio Value EUR", "Contribution EUR",
                       "Contribution Fee EUR", "Net Contribution BTC", "Withdrawal EUR"]

        let columnWidth: CGFloat = 120
        let columnPadding: CGFloat = 10
        let rowHeight: CGFloat = 25
        let initialX: CGFloat = 50

        // Function to draw headers
        func drawHeader() {
            for (index, header) in headers.enumerated() {
                let xPosition = initialX + CGFloat(index) * (columnWidth + columnPadding)
                let headerRect = CGRect(x: xPosition, y: currentY, width: columnWidth, height: rowHeight)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let headerAttributes: [NSAttributedString.Key: Any] = [
                    .font: headerFont,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]
                NSString(string: header).draw(in: headerRect, withAttributes: headerAttributes)
            }
            currentY += rowHeight + 5
        }

        // Function to draw a single row
        func drawRow(for result: SimulationData) {
            let rowData = [
                "\(result.week)", // Week as integer
                result.startingBTC.formattedBTC(),
                result.netBTCHoldings.formattedBTC(),
                result.btcPriceUSD.formattedCurrency(),
                result.btcPriceEUR.formattedCurrency(),
                result.portfolioValueEUR.formattedCurrency(),
                result.contributionEUR.formattedCurrency(),
                result.contributionFeeEUR.formattedCurrency(),
                result.netContributionBTC.formattedBTC(),
                result.withdrawalEUR.formattedCurrency()
            ]
            for (index, columnData) in rowData.enumerated() {
                let xPosition = initialX + CGFloat(index) * (columnWidth + columnPadding)
                let rowRect = CGRect(x: xPosition, y: currentY, width: columnWidth, height: rowHeight)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let rowAttributes: [NSAttributedString.Key: Any] = [
                    .font: rowFont,
                    .foregroundColor: UIColor.black,
                    .paragraphStyle: paragraphStyle
                ]
                NSString(string: columnData).draw(in: rowRect, withAttributes: rowAttributes)
            }
            currentY += rowHeight
        }

        // Start rendering the PDF
        context.beginPage()
        drawHeader() // Draw the table header

        for result in results {
            if currentY + rowHeight > pageHeight - 50 {
                // Start a new page if we run out of space
                context.beginPage()
                currentY = 50
                drawHeader() // Redraw the header on the new page
            }
            drawRow(for: result) // Draw each row
        }
    }

    print("PDF generation complete.")
    return pdfData
}

private func createPDFPage(content: NSAttributedString, pageRect: CGRect, margin: CGFloat) -> Data? {
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let pdfData = renderer.pdfData { context in
        context.beginPage()

        // Define the drawing area with proper margins
        let textBounds = CGRect(
            x: margin,
            y: margin,
            width: pageRect.width - 2 * margin,
            height: pageRect.height - 2 * margin
        )

        // Draw the content in the specified area
        content.draw(with: textBounds, options: .usesLineFragmentOrigin, context: nil)
    }

    return pdfData
}
