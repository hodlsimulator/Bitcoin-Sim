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
    @Published var annualCAGR: String = "40.0" // Default annual growth rate in %
    @Published var selectedWeek: String
    @Published var btcPriceMinInput: String
    @Published var btcPriceMaxInput: String
    @Published var portfolioValueMinInput: String
    @Published var portfolioValueMaxInput: String
    @Published var btcHoldingsMinInput: String
    @Published var btcHoldingsMaxInput: String
    @Published var btcGrowthRate: String

    init() {
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
        return Double(annualCAGR.replacingOccurrences(of: ",", with: "")) ?? 40.0 // Default to 40%
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
    
    // Define column headers and keys for dynamic access
    let columns: [(String, PartialKeyPath<SimulationData>)] = [
        ("Week", \SimulationData.week),
        ("Cycle Phase", \SimulationData.cyclePhase),
        ("Starting BTC (BTC)", \SimulationData.startingBTC),
        ("BTC Growth (BTC)", \SimulationData.btcGrowth),
        ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
        ("BTC Price USD", \SimulationData.btcPriceUSD),
        ("BTC Price EUR", \SimulationData.btcPriceEUR),
        ("Portfolio Value EUR", \SimulationData.portfolioValueEUR),
        ("Contribution EUR", \SimulationData.contributionEUR),
        ("Contribution Fee EUR", \SimulationData.contributionFeeEUR),
        ("Net Contribution BTC", \SimulationData.netContributionBTC),
        ("Withdrawal EUR", \SimulationData.withdrawalEUR),
        ("Portfolio (Pre-Withdrawal) EUR", \SimulationData.portfolioPreWithdrawalEUR)
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Input Section
            VStack(spacing: 10) {
                HStack {
                    Text("BTC Annual CAGR (%):")
                    TextField("Enter CAGR", text: formattedBinding(for: \.btcGrowthRate))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                }

                HStack {
                    Text("Number of Iterations:")
                    TextField("Enter Iterations", text: formattedBinding(for: \.iterations))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                }
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

                // Scrollable Results with Sticky Header
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Sticky Header
                        HStack(spacing: 0) {
                            ForEach(columns, id: \.0) { column in
                                Text(column.0)
                                    .bold()
                                    .frame(width: 130, alignment: .center) // Column width remains the same
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.2))
                                    .border(Color.black)
                                    .offset(x: 20) // Move headings 2 pixels to the right
                            }
                        }
                        .frame(width: geometry.size.width) // Match the width of the scrollable content

                        // Scrollable Rows
                        ScrollView([.vertical, .horizontal]) {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(monteCarloResults) { item in
                                    HStack(spacing: 0) {
                                        ForEach(columns, id: \.0) { column in
                                            let value = getValue(item: item, keyPath: column.1)
                                            Text(value)
                                                .lineLimit(1)
                                                .frame(width: 130, alignment: .center)
                                                .padding(.vertical, 8)
                                                .border(Color.black)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: geometry.size.height - 40)
                    }
                }
                .frame(maxHeight: 500) // Limit the total height of the results
            }
        }
        .padding()
    }

    // MARK: - Functions

    private func runSimulation() {
        isLoading = true
        monteCarloResults = [] // Clear previous results

        DispatchQueue.global(qos: .userInitiated).async {
            // Fetch parameters
            let annualCAGR = inputManager.getParsedAnnualCAGR() / 100.0 // Convert % to decimal
            let weeklyDeterministicGrowth = pow(1 + annualCAGR, 1.0 / 52.0) - 1.0
            let weeklyVolatility = 0.15 // Weekly standard deviation
            let rareEventProbability = 0.01 // 1% chance per week
            let exchangeRateEURUSD = 1.06
            let totalSimulations = inputManager.getParsedIterations() ?? 1000 // Number of simulations
            let batchSize = 100 // Number of simulations per batch

            print("Starting \(totalSimulations) simulations in batches of \(batchSize)...")

            var allResults: [[SimulationData]] = [] // Store results of all simulations
            let resultQueue = DispatchQueue(label: "com.conor.BTCMonteCarlo.resultQueue") // Synchronisation queue
            let totalBatches = (totalSimulations + batchSize - 1) / batchSize

            // Helper functions
            func randomNormal(mean: Double, standardDeviation: Double) -> Double {
                let u1 = Double.random(in: 0..<1)
                let u2 = Double.random(in: 0..<1)
                let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
                return z0 * standardDeviation + mean
            }

            // Run simulations in batches
            let group = DispatchGroup()

            for batchIndex in 0..<totalBatches {
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    print("Starting batch \(batchIndex + 1) of \(totalBatches)...")

                    var batchResults: [[SimulationData]] = []

                    // Perform simulations for this batch
                    let batchStart = batchIndex * batchSize
                    let batchEnd = min(batchStart + batchSize, totalSimulations)

                    for simulationIndex in batchStart..<batchEnd {
                        var results: [SimulationData] = [
                            SimulationData(
                                id: UUID(),
                                week: 1,
                                cyclePhase: "Bull",
                                startingBTC: 0.0,
                                btcGrowth: 0.00469014,
                                netBTCHoldings: 0.00469014,
                                btcPriceUSD: 76_532.03,
                                btcPriceEUR: 76_532.03 / exchangeRateEURUSD,
                                portfolioValueEUR: 333.83,
                                contributionEUR: 378.00,
                                contributionFeeEUR: 2.46,
                                netContributionBTC: 0.00527613,
                                withdrawalEUR: 0.0,
                                portfolioPreWithdrawalEUR: 0.0
                            ),
                            SimulationData(
                                id: UUID(),
                                week: 2,
                                cyclePhase: "Bull",
                                startingBTC: 0.00469014,
                                btcGrowth: 0.00001802,
                                netBTCHoldings: 0.00534888,
                                btcPriceUSD: 98_000.00,
                                btcPriceEUR: 98_000.00 / exchangeRateEURUSD,
                                portfolioValueEUR: 495.00,
                                contributionEUR: 60.00,
                                contributionFeeEUR: 0.21,
                                netContributionBTC: 0.00064048,
                                withdrawalEUR: 0.0,
                                portfolioPreWithdrawalEUR: 439.37
                            )
                        ]

                        // Simulate for remaining weeks
                        for i in 2..<1040 {
                            let previous = results[i - 1]

                            let week = i + 1
                            let cyclePhase = (i % 208) < 60 ? "Bull" : "Bear"
                            let rareEventImpact = Double.random(in: 1.2...1.5)
                            let rareEventAdjustment = Double.random(in: 0..<1) < rareEventProbability ? rareEventImpact : 1.0
                            let randomShock = max(randomNormal(mean: 0, standardDeviation: weeklyVolatility), -0.30)
                            let btcPriceUSD = max(previous.btcPriceUSD * (1 + weeklyDeterministicGrowth + randomShock) * rareEventAdjustment, 1_000.0)
                            let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD
                            let growthMultiplier = (cyclePhase == "Bull" ? 1.5 : 0.5)
                            let btcGrowth = growthMultiplier * previous.netBTCHoldings * weeklyDeterministicGrowth
                            let contributionEUR = i < 52 ? 60.0 : 100.0
                            let contributionFeeEUR = contributionEUR * (previous.portfolioValueEUR >= 100_000 ? 0.0007 : 0.0035)
                            let netContributionBTC = (contributionEUR - contributionFeeEUR) / btcPriceEUR
                            let withdrawalEUR = previous.portfolioValueEUR > 60_000 ? 200.0 : 0.0
                            let netBTCHoldings = previous.netBTCHoldings + btcGrowth + netContributionBTC - (withdrawalEUR / btcPriceEUR)
                            let portfolioValueEUR = netBTCHoldings * btcPriceEUR
                            let portfolioPreWithdrawalEUR = previous.netBTCHoldings * btcPriceEUR

                            results.append(
                                SimulationData(
                                    id: UUID(),
                                    week: week,
                                    cyclePhase: cyclePhase,
                                    startingBTC: previous.netBTCHoldings,
                                    btcGrowth: btcGrowth,
                                    netBTCHoldings: netBTCHoldings,
                                    btcPriceUSD: btcPriceUSD,
                                    btcPriceEUR: btcPriceEUR,
                                    portfolioValueEUR: portfolioValueEUR,
                                    contributionEUR: contributionEUR,
                                    contributionFeeEUR: contributionFeeEUR,
                                    netContributionBTC: netContributionBTC,
                                    withdrawalEUR: withdrawalEUR,
                                    portfolioPreWithdrawalEUR: portfolioPreWithdrawalEUR
                                )
                            )
                        }

                        batchResults.append(results)
                    }

                    // Append batch results to allResults safely
                    resultQueue.sync {
                        allResults.append(contentsOf: batchResults)
                    }

                    print("Batch \(batchIndex + 1) completed. Total simulations so far: \(allResults.flatMap { $0 }.count)")
                    group.leave()
                }
            }

            // Wait for all batches to complete
            group.notify(queue: .main) {
                monteCarloResults = allResults.flatMap { $0 } // Combine all batches into a single array
                print("Final monteCarloResults count: \(monteCarloResults.count)")
                isLoading = false
                print("All simulations completed. Final results assigned to UI.")
            }
        }
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
                keyPath == \SimulationData.btcGrowth ||
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
            result.cyclePhase,
            result.startingBTC.formattedBTC(),
            result.btcGrowth.formattedBTC(),
            result.netBTCHoldings.formattedBTC(),
            result.btcPriceUSD.formattedWithSeparator(),
            result.btcPriceEUR.formattedWithSeparator(),
            result.portfolioValueEUR.formattedWithSeparator(),
            result.contributionEUR.formattedWithSeparator(),
            result.contributionFeeEUR.formattedWithSeparator(),
            result.netContributionBTC.formattedBTC(),
            result.withdrawalEUR.formattedWithSeparator(),
            result.portfolioPreWithdrawalEUR.formattedWithSeparator()
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
