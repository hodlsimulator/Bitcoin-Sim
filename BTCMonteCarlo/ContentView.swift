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
    
    // Define column headers and keys for dynamic access
    let columns: [(String, PartialKeyPath<SimulationData>)] = [
        ("Week", \SimulationData.week),
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
        VStack(spacing: 10) {
            HStack {
                Text("BTC Annual CAGR (%):")
                TextField("Enter CAGR", text: formattedBinding(for: \.annualCAGR))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
            }

            HStack {
                Text("BTC Annual Volatility (%):")
                TextField("Enter Volatility", text: formattedBinding(for: \.annualVolatility))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
            }

            HStack {
                Text("Number of Iterations:")
                TextField("Enter Iterations", text: formattedBinding(for: \.iterations))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
            }

            // Run Simulation Button
            Button("Run Simulation") {
                runSimulation()
            }
            .padding()

            // Loading Indicator
            if isLoading {
                ProgressView("Simulating...")
                    .padding()
            }

            // Results Section
            if !monteCarloResults.isEmpty {
                Text("Monte Carlo Simulation Results")
                    .font(.headline)
                    .padding()

                // Sticky Header with Scrollable Rows
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Sticky Header
                        HStack(spacing: 0) {
                            ForEach(columns, id: \.0) { column in
                                Text(column.0) // Access column name
                                    .bold()
                                    .frame(width: 147.5, height: 50, alignment: .center) // Fixed width
                                    .background(Color.gray.opacity(0.2))
                                    .border(Color.black)
                                    .padding(.leading, -1.2) // Adjust header alignment
                            }
                        }
                        .background(Color.gray.opacity(0.3))

                        // Scrollable Rows
                        ScrollView([.vertical, .horizontal]) {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                // Inside your SwiftUI view, replace the rendering logic for the Contribution EUR column
                                ForEach(monteCarloResults.indices, id: \.self) { index in
                                    HStack(spacing: 0) {
                                        ForEach(columns.indices, id: \.self) { colIndex in
                                            let column = columns[colIndex]
                                            
                                            // Check if it's the last row and the Contribution EUR column
                                            if index == monteCarloResults.count - 1 && column.0 == "Contribution EUR" {
                                                // Calculate the total contributions
                                                let totalContributions = monteCarloResults.reduce(0.0) { total, row in
                                                    total + row.contributionEUR
                                                }

                                                // Display the total contributions
                                                Text(totalContributions.formattedWithSeparator())
                                                    .frame(width: 147.5, alignment: .center)
                                                    .border(Color.black)
                                                    .padding(.leading, -0.8)
                                                    .padding(.vertical, 8)
                                            } else {
                                                // Regular data rows
                                                let value = getValue(item: monteCarloResults[index], keyPath: column.1)
                                                Text(value)
                                                    .frame(width: 147.5, alignment: .center)
                                                    .border(Color.black)
                                                    .padding(.leading, -0.8)
                                                    .padding(.vertical, 8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: geometry.size.height - 40)
                    }
                }
                .frame(maxHeight: 500)
            }
        }
        .padding()
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
                }
                print("Invalid number of iterations.")
                return
            }
            
            // Store all results
            var allResults: [[SimulationData]] = []
            
            // Run simulation for the specified number of iterations
            for iteration in 1...totalIterations {
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
                
                // Cumulative trackers
                var cumulativeBTC: Double = 0.00530474 // Starting BTC for week 2
                var cumulativeContributionsEUR: Double = 438.00
                
                // Simulation loop (week 3 onwards)
                // Simulation loop (week 3 onwards)
                for week in 3...totalWeeks {
                    let previous = results[week - 2] // Reference to the previous week's data
                    
                    // Generate random shock
                    let randomShock = randomNormal(mean: 0, standardDeviation: weeklyVolatility)
                    let adjustedGrowthFactor = 1 + weeklyDeterministicGrowth + randomShock
                    
                    // Update BTC price
                    var btcPriceUSD = previous.btcPriceUSD * adjustedGrowthFactor
                    
                    // Rare crash simulation
                    if Double.random(in: 0..<1) < 0.005 { // 0.5% crash probability
                        btcPriceUSD *= (1 - Double.random(in: 0.1...0.3)) // Moderate crash severity
                    }
                    
                    // Apply price floor (adjust as needed)
                    btcPriceUSD = max(btcPriceUSD, 1_000.0)
                    let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD
                    
                    // Contribution logic
                    let contributionEUR: Double = week <= 52 ? 60.0 : 100.0
                    let contributionFeeEUR = contributionEUR * 0.0035
                    let netContributionBTC = (contributionEUR - contributionFeeEUR) / btcPriceEUR
                    cumulativeBTC += netContributionBTC
                    cumulativeContributionsEUR += contributionEUR
                    
                    // Withdrawal logic
                    let withdrawalEUR: Double = previous.portfolioValueEUR > 30_000 ? 100.0 : 0.0
                    let withdrawalBTC = withdrawalEUR / btcPriceEUR
                    cumulativeBTC -= withdrawalBTC
                    
                    // Update net BTC holdings and portfolio value
                    let netBTCHoldings = max(0, previous.netBTCHoldings + netContributionBTC - withdrawalBTC)
                    let portfolioValueEUR = netBTCHoldings * btcPriceEUR
                    
                    // Append simulation data for the current week
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
            
            // Update UI
            DispatchQueue.main.async {
                self.isLoading = false
                self.monteCarloResults = allResults.last ?? []
                
                // Process and generate histogram
                self.processAllResults(allResults) // Optional if you process stats here
                self.generateHistogramForResults(
                    results: self.monteCarloResults,
                    filePath: "/Users/conor/Desktop/portfolio_growth_histogram.png"
                )
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
        print("Histogram Generation Started: \(title)")
        print("Initial Data Count: \(data.count)")

        let validData = data.filter { $0 > 0 }
        guard !validData.isEmpty else {
            print("Error: No valid data to generate histogram.")
            return
        }

        let sortedData = validData.sorted()
        let lowerIndex = Int(Double(sortedData.count) * lowerPercentile)
        let upperIndex = Int(Double(sortedData.count) * upperPercentile)
        let filteredData = Array(sortedData[lowerIndex..<upperIndex])

        guard let minValue = filteredData.min(), let maxValue = filteredData.max(), minValue > 0 else {
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
        let image = NSImage(size: NSSize(width: 1000, height: 700))
        image.lockFocus()

        let context = NSGraphicsContext.current!.cgContext
        context.setFillColor(NSColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1000, height: 700))

        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        NSString(string: title).draw(at: CGPoint(x: 100, y: 650), withAttributes: titleAttributes)

        // Draw X-axis and Y-axis
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(1.5)

        // X-axis
        context.move(to: CGPoint(x: 100, y: 100))
        context.addLine(to: CGPoint(x: 900, y: 100))
        context.strokePath()

        // Y-axis
        context.move(to: CGPoint(x: 100, y: 100))
        context.addLine(to: CGPoint(x: 100, y: 600))
        context.strokePath()

        // Add Y-axis labels (Percentages)
        let maxFrequency = bins.max() ?? 1
        for i in 0...5 {
            let percentage = Double(i) * 100 / 5.0
            let yPosition = 100 + CGFloat(i) * 100
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white
            ]
            NSString(string: "\(Int(percentage))%").draw(at: CGPoint(x: 60, y: yPosition - 8), withAttributes: labelAttributes)
            context.setStrokeColor(NSColor.gray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: 100, y: yPosition))
            context.addLine(to: CGPoint(x: 900, y: yPosition))
            context.strokePath()
        }

        // Add X-axis labels (Thousands Separator)
        let barWidth = (900 - 100) / CGFloat(binCount)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        for i in 0...binCount {
            let logLabelValue = logMinValue + Double(i) * binWidth
            let labelValue = pow(10, logLabelValue)
            let formattedLabel = numberFormatter.string(from: NSNumber(value: labelValue)) ?? "\(labelValue)"
            let xPosition = 100 + CGFloat(i) * barWidth
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.white
            ]
            if rotateLabels {
                context.saveGState()
                let labelPosition = CGPoint(x: xPosition - 10, y: 80)
                context.translateBy(x: labelPosition.x, y: labelPosition.y)
                context.rotate(by: -CGFloat.pi / 4) // Rotate 45 degrees
                NSString(string: formattedLabel).draw(at: .zero, withAttributes: labelAttributes)
                context.restoreGState()
            } else {
                NSString(string: formattedLabel).draw(at: CGPoint(x: xPosition - 15, y: 80), withAttributes: labelAttributes)
            }
        }

        // Draw histogram bars
        for (index, frequency) in bins.enumerated() {
            let percentage = Double(frequency) / Double(totalDataCount) * 100
            let barHeight = CGFloat(percentage / 100.0) * 500
            let barRect = CGRect(x: 100 + CGFloat(index) * barWidth, y: 100, width: barWidth - 2, height: barHeight)
            context.setFillColor(NSColor.systemBlue.cgColor)
            context.fill(barRect)
        }

        image.unlockFocus()

        if let imageData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: imageData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: URL(fileURLWithPath: fileName))
                print("Histogram saved successfully at \(fileName)")
            } catch {
                print("Error saving histogram: \(error)")
            }
        } else {
            print("Error: Failed to generate image data.")
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
    
    // Helper function to get value from keyPath and format it as String
    private func getValue(item: SimulationData, keyPath: PartialKeyPath<SimulationData>) -> String {
        if let value = item[keyPath: keyPath] as? Int {
            return "\(value)"
        } else if let value = item[keyPath: keyPath] as? Double {
            // Format doubles appropriately
            if keyPath == \SimulationData.startingBTC ||
                keyPath == \SimulationData.netBTCHoldings ||
                keyPath == \SimulationData.netContributionBTC {
                return value.formattedBTC()
            } else {
                return value.formattedWithSeparator()
            }
        } else if let value = item[keyPath: keyPath] as? String {
            return value
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
        formatter.maximumFractionDigits = 8 // Allows up to 8 decimal places
        formatter.minimumFractionDigits = 0 // Allows flexibility for no unnecessary decimals
        return formatter
    }()
}

private func createHistogramCoreGraphics(
    data: [Double],
    title: String,
    fileName: String,
    rotateLabels: Bool = false
) {
    let width: CGFloat = 1000
    let height: CGFloat = 700
    let margin: CGFloat = 100

    let minValue = data.min() ?? 0
    let maxValue = data.max() ?? 1
    let binCount = 15
    let binWidth = (maxValue - minValue) / Double(binCount)
    var bins = [Int](repeating: 0, count: binCount)
    for value in data {
        let binIndex = min(Int((value - minValue) / binWidth), binCount - 1)
        bins[binIndex] += 1
    }

    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.setFillColor(NSColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Title
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 16),
        .foregroundColor: NSColor.white
    ]
    NSString(string: title).draw(
        at: CGPoint(x: margin, y: height - margin + 20),
        withAttributes: titleAttributes
    )

    // Axes
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(1.5)

    // X-Axis
    context.move(to: CGPoint(x: margin, y: margin))
    context.addLine(to: CGPoint(x: width - margin, y: margin))
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
            y: margin,
            width: barWidth - 2,
            height: barHeight
        )
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(barRect)
    }

    // Draw x-axis labels
    let axisAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12),
        .foregroundColor: NSColor.white
    ]
    for i in 0...binCount {
        let x = margin + CGFloat(i) * barWidth
        let labelValue = minValue + Double(i) * binWidth
        let label = String(format: "%.2f", labelValue)

        if rotateLabels {
            let labelPosition = CGPoint(x: x - 15, y: margin / 2 - 10)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let rotatedAttributes = axisAttributes.merging([.paragraphStyle: paragraphStyle]) { _, new in new }

            context.saveGState()
            context.translateBy(x: labelPosition.x, y: labelPosition.y)
            context.rotate(by: -CGFloat.pi / 4)
            NSString(string: label).draw(at: .zero, withAttributes: rotatedAttributes)
            context.restoreGState()
        } else {
            NSString(string: label).draw(
                at: CGPoint(x: x - 15, y: margin / 2 - 10),
                withAttributes: axisAttributes
            )
        }
    }

    image.unlockFocus()

    if let imageData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: imageData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        do {
            try pngData.write(to: URL(fileURLWithPath: fileName))
            print("Histogram saved to \(fileName)")
        } catch {
            print("Failed to save histogram: \(error)")
        }
    } else {
        print("Failed to generate image data")
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
    lowerDiscardPercentile: Double = 0.10, // Discard lower 10%
    upperDiscardPercentile: Double = 0.05, // Discard upper 5%
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

    let minValue = filteredData.min() ?? 0
    let maxValue = filteredData.max() ?? 1
    let binCount = 15
    let binWidth = (maxValue - minValue) / Double(binCount)
    var bins = [Int](repeating: 0, count: binCount)
    for value in filteredData {
        let binIndex = min(Int((value - minValue) / binWidth), binCount - 1)
        bins[binIndex] += 1
    }

    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.setFillColor(NSColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Title
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 16),
        .foregroundColor: NSColor.white
    ]
    NSString(string: title).draw(
        at: CGPoint(x: margin, y: height - margin + 30),
        withAttributes: titleAttributes
    )

    // Axes
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(1.5)

    // X-Axis
    context.move(to: CGPoint(x: margin, y: margin))
    context.addLine(to: CGPoint(x: width - margin, y: margin))
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
            y: margin,
            width: barWidth - 2,
            height: barHeight
        )
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(barRect)
    }

    // Draw x-axis labels
    let axisAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 12),
        .foregroundColor: NSColor.white
    ]
    for i in 0...binCount {
        let x = margin + CGFloat(i) * barWidth
        let labelValue = minValue + Double(i) * binWidth
        let formattedLabel = NumberFormatter.localizedString(
            from: NSNumber(value: labelValue),
            number: .decimal
        )

        if rotateLabels {
            let labelPosition = CGPoint(x: x - 10, y: margin - 40) // Adjust position upward
            context.saveGState()
            context.translateBy(x: labelPosition.x, y: labelPosition.y)
            context.rotate(by: -CGFloat.pi / 4) // Rotate 45°
            NSString(string: formattedLabel).draw(at: .zero, withAttributes: axisAttributes)
            context.restoreGState()
        } else {
            NSString(string: formattedLabel).draw(
                at: CGPoint(x: x - 15, y: margin / 2),
                withAttributes: axisAttributes
            )
        }
    }

    image.unlockFocus()

    if let imageData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: imageData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        do {
            try pngData.write(to: URL(fileURLWithPath: fileName))
            print("Histogram saved to \(fileName)")
        } catch {
            print("Failed to save histogram: \(error)")
        }
    } else {
        print("Failed to generate image data")
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

    // Generate the histogram
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()

    let context = NSGraphicsContext.current!.cgContext
    context.setFillColor(NSColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    // Title
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 16),
        .foregroundColor: NSColor.white
    ]
    NSString(string: title).draw(
        at: CGPoint(x: margin, y: height - margin + 20),
        withAttributes: titleAttributes
    )

    // Draw axes
    context.setStrokeColor(NSColor.white.cgColor)
    context.setLineWidth(1.5)
    context.move(to: CGPoint(x: margin, y: margin))
    context.addLine(to: CGPoint(x: width - margin, y: margin)) // X-axis
    context.strokePath()
    context.move(to: CGPoint(x: margin, y: margin))
    context.addLine(to: CGPoint(x: margin, y: height - margin)) // Y-axis
    context.strokePath()

    // Draw y-axis percentage labels
    let yAxisStep = 10 // Steps in percentages (e.g., 0%, 10%, 20%)
    let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 10),
        .foregroundColor: NSColor.white
    ]
    for percentage in stride(from: 0, through: Int(maxPercentage), by: yAxisStep) {
        let yPosition = margin + CGFloat(percentage) / 100.0 * (height - 2 * margin)
        let label = "\(percentage)%"
        NSString(string: label).draw(
            at: CGPoint(x: margin - 40, y: yPosition - 8), // Align labels with the ticks
            withAttributes: labelAttributes
        )

        // Draw gridline
        context.setStrokeColor(NSColor.gray.cgColor)
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
        let barRect = CGRect(x: margin + CGFloat(index) * barWidth, y: margin, width: barWidth - 2, height: barHeight)
        context.setFillColor(NSColor.systemBlue.cgColor)
        context.fill(barRect)
    }

    // Rotate and format x-axis labels with thousands separators
    for i in 0...binCount {
        let x = margin + CGFloat(i) * barWidth
        let labelValue = minValue + Double(i) * binWidth
        let label = NumberFormatter.localizedString(from: NSNumber(value: labelValue), number: .decimal)

        context.saveGState()
        let labelPosition = CGPoint(x: x - 10, y: margin - 30) // Adjust label position
        context.translateBy(x: labelPosition.x, y: labelPosition.y)
        context.rotate(by: -CGFloat.pi / 4) // Rotate by 45°
        NSString(string: label).draw(at: .zero, withAttributes: [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.white
        ])
        context.restoreGState()
    }

    image.unlockFocus()

    if let imageData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: imageData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        do {
            try pngData.write(to: URL(fileURLWithPath: fileName))
            print("Histogram saved to \(fileName)")
        } catch {
            print("Failed to save histogram: \(error)")
        }
    } else {
        print("Failed to generate image data for \(title).")
    }
}
 
private func generatePDFData(results: [SimulationData]) -> Data? {
    print("Starting PDF generation...")

    let pdfData = NSMutableData()
    let pageWidth: CGFloat = 1400
    let pageHeight: CGFloat = 792
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
    var mediaBox = pageRect

    guard let consumer = CGDataConsumer(data: pdfData),
          let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        print("Error creating PDF context")
        return nil
    }

    pdfContext.beginPDFPage(nil)

    NSGraphicsContext.saveGraphicsState()
    let graphicsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
    NSGraphicsContext.current = graphicsContext

    // Headers
    let headers = ["Week", "Cycle Phase", "Starting BTC", "BTC Growth", "Net BTC Holdings",
                   "BTC Price USD", "BTC Price EUR", "Portfolio Value EUR", "Contribution EUR",
                   "Contribution Fee EUR", "Net Contribution BTC", "Withdrawal EUR",
                   "Portfolio Pre-Withdrawal EUR"]

    let headerFont = NSFont.boldSystemFont(ofSize: 10)
    let headerAttributes: [NSAttributedString.Key: Any] = [
        .font: headerFont,
        .foregroundColor: NSColor.black
    ]

    let rowFont = NSFont.systemFont(ofSize: 10)
    let rowAttributes: [NSAttributedString.Key: Any] = [
        .font: rowFont,
        .foregroundColor: NSColor.black
    ]

    // Layout dimensions
    let initialX: CGFloat = 50
    let initialY: CGFloat = 750
    let rowHeight: CGFloat = 25 // Increased from 20 to 25 for more space
    let columnWidth: CGFloat = 100
    let columnPadding: CGFloat = 10
    var currentY = initialY

    print("Drawing headers...")
    for (index, header) in headers.enumerated() {
        let xPosition = initialX + CGFloat(index) * (columnWidth + columnPadding)
        let headerRect = CGRect(x: xPosition, y: currentY, width: columnWidth, height: rowHeight)
        let headerText = NSString(string: header)

        // Draw header text centered in its column
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        var centeredAttributes = headerAttributes
        centeredAttributes[.paragraphStyle] = paragraphStyle

        headerText.draw(in: headerRect, withAttributes: centeredAttributes)
    }

    // Add space between the headers and the first row
    currentY -= rowHeight + 15

    print("Drawing rows...")
    for result in results {
        let rowData = [
            "\(result.week)",
            result.startingBTC.formattedBTC(),
            result.netBTCHoldings.formattedBTC(),
            result.btcPriceUSD.formattedWithSeparator(),
            result.btcPriceEUR.formattedWithSeparator(),
            result.portfolioValueEUR.formattedWithSeparator(),
            result.contributionEUR.formattedWithSeparator(),
            result.contributionFeeEUR.formattedWithSeparator(),
            result.netContributionBTC.formattedBTC(),
            result.withdrawalEUR.formattedWithSeparator()
        ]

        for (index, columnData) in rowData.enumerated() {
            let xPosition = initialX + CGFloat(index) * (columnWidth + columnPadding)
            let rowRect = CGRect(x: xPosition, y: currentY, width: columnWidth, height: rowHeight)
            let rowText = NSString(string: columnData)

            // Draw row data centered in its column
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            var centeredAttributes = rowAttributes
            centeredAttributes[.paragraphStyle] = paragraphStyle

            rowText.draw(in: rowRect, withAttributes: centeredAttributes)
        }

        currentY -= rowHeight

        if currentY < 50 {
            print("Adding new page...")
            pdfContext.endPDFPage()
            pdfContext.beginPDFPage(nil)
            currentY = initialY
        }
    }

    NSGraphicsContext.restoreGraphicsState()
    pdfContext.endPDFPage()
    pdfContext.closePDF()

    print("PDF generation complete.")
    return pdfData as Data
}

private func createPDFPage(content: NSAttributedString, pageRect: CGRect, margin: CGFloat) -> PDFPage? {
    let pdfData = NSMutableData()
    var mediaBox = pageRect // Define the page size
    guard let consumer = CGDataConsumer(data: pdfData),
          let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        print("Error: Could not create PDF context")
        return nil
    }

    pdfContext.beginPDFPage(nil)

    // Create the drawing area with proper margins
    let textBounds = CGRect(
        x: margin,
        y: margin,
        width: pageRect.width - 2 * margin,
        height: pageRect.height - 2 * margin
    )

    // Set the context for proper text rendering
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: pdfContext, flipped: false)

    // Draw the content in the specified area
    content.draw(with: textBounds, options: .usesLineFragmentOrigin)

    // Restore graphics state
    NSGraphicsContext.restoreGraphicsState()
    pdfContext.endPDFPage()
    pdfContext.closePDF()

    return PDFDocument(data: pdfData as Data)?.page(at: 0)
}
