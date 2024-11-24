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
    
    // Define grid column layout for the table
    let gridColumns = [
        GridItem(.fixed(100)), // Week column
        GridItem(.fixed(150)), // Cycle Phase column
        GridItem(.fixed(150)), // Starting BTC column
        GridItem(.fixed(150)), // BTC Growth column
        GridItem(.fixed(150)), // Net BTC Holdings column
        GridItem(.fixed(150)), // BTC Price USD column
        GridItem(.fixed(150)), // BTC Price EUR column
        GridItem(.fixed(200)), // Portfolio Value EUR column
        GridItem(.fixed(150)), // Contribution EUR column
        GridItem(.fixed(150)), // Contribution Fee EUR column
        GridItem(.fixed(150)), // Net Contribution BTC column
        GridItem(.fixed(150)), // Withdrawal EUR column
        GridItem(.fixed(200))  // Portfolio Pre-Withdrawal EUR column
    ]
    
    var body: some View {
        VStack(spacing: 20) { // Add spacing between sections
            // BTC Growth Rate Input
            HStack {
                Text("BTC Growth Rate (%):")
                TextField("Enter Growth Rate", text: realTimeFormattedBinding(for: \.btcGrowthRate))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 150)
            }

            // Simulation Parameters Input
            VStack(spacing: 10) { // Group all inputs together
                HStack {
                    Group {
                        Text("Week Number:")
                        TextField("Enter Week Number", text: realTimeFormattedBinding(for: \.selectedWeek))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }

                    Group {
                        Text("BTC Price Min:")
                        TextField("Enter Min Price", text: realTimeFormattedBinding(for: \.btcPriceMinInput))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }

                    Group {
                        Text("BTC Price Max:")
                        TextField("Enter Max Price", text: realTimeFormattedBinding(for: \.btcPriceMaxInput))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }
                }

                HStack {
                    Group {
                        Text("Portfolio Min:")
                        TextField("Enter Portfolio Min", text: realTimeFormattedBinding(for: \.portfolioValueMinInput))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }

                    Group {
                        Text("Portfolio Max:")
                        TextField("Enter Portfolio Max", text: realTimeFormattedBinding(for: \.portfolioValueMaxInput))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }

                    Group {
                        Text("BTC Holdings Min:")
                        TextField("Enter Holdings Min", text: realTimeFormattedBinding(for: \.btcHoldingsMinInput))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }
                }

                HStack {
                    Group {
                        Text("BTC Holdings Max:")
                        TextField("Enter Holdings Max", text: realTimeFormattedBinding(for: \.btcHoldingsMaxInput))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }

                    Group {
                        Text("Number of Iterations:")
                        TextField("Enter Iterations", text: realTimeFormattedBinding(for: \.iterations))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 150)
                    }
                }
            }

            // Run Simulation Button
            Button("Run Simulation") {
                runSimulation()
            }
            .padding()

            // Loading Indicator
            if isLoading {
                ProgressView()
                    .padding()
            }

            // Results Display
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(monteCarloResults, id: \.id) { result in
                        VStack {
                            Text("Week \(result.week)")
                            Text("BTC Price USD: \(result.btcPriceUSD.formattedWithSeparator())")
                            Text("Portfolio Value EUR: \(result.portfolioValueEUR.formattedWithSeparator())")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .padding()
    }
    
    private func runSimulation() {
        isLoading = true
        monteCarloResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            let spreadsheetData = loadCSV() // Replace with actual data loading function
            guard let totalIterations = Int(inputManager.iterations.replacingOccurrences(of: ",", with: "")) else {
                print("Error: Invalid number of iterations: \(inputManager.iterations)")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            // Validate BTC Growth Rate as yearly CAGR and convert to weekly growth rate
            guard let btcGrowthRateCAGR = Double(inputManager.btcGrowthRate.replacingOccurrences(of: ",", with: "")) else {
                print("Error: Invalid BTC Growth Rate (CAGR): \(inputManager.btcGrowthRate)")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }
            let weeklyGrowthRate = pow(1 + btcGrowthRateCAGR / 100.0, 1.0 / 52.0) - 1.0
            print("Yearly CAGR: \(btcGrowthRateCAGR)% -> Weekly Growth Rate: \(weeklyGrowthRate * 100)%")

            // Run the Monte Carlo simulation
            let (bestIteration, allIterations) = runMonteCarloSimulationsWithSpreadsheetData(
                spreadsheetData: spreadsheetData,
                initialBTCPriceUSD: 1000.0,
                iterations: totalIterations,
                btcGrowthRate: weeklyGrowthRate
            )

            DispatchQueue.main.async {
                monteCarloResults = bestIteration
                isLoading = false
                print("Simulation completed with \(bestIteration.count) rows")
                
                // Call generateGraphs after simulation
                generateGraphs(allIterations: allIterations)
            }
        }
    }
    
    private func generateGraphs(allIterations: [[SimulationData]]) {
        guard let week = Int(inputManager.selectedWeek.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid week number: \(inputManager.selectedWeek)")
            return
        }

        guard let btcPriceMin = Double(inputManager.btcPriceMinInput.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid BTC Price Min: \(inputManager.btcPriceMinInput)")
            return
        }

        guard let btcPriceMax = Double(inputManager.btcPriceMaxInput.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid BTC Price Max: \(inputManager.btcPriceMaxInput)")
            return
        }

        guard let portfolioValueMin = Double(inputManager.portfolioValueMinInput.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid Portfolio Value Min: \(inputManager.portfolioValueMinInput)")
            return
        }

        guard let portfolioValueMax = Double(inputManager.portfolioValueMaxInput.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid Portfolio Value Max: \(inputManager.portfolioValueMaxInput)")
            return
        }

        guard let btcHoldingsMin = Double(inputManager.btcHoldingsMinInput.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid BTC Holdings Min: \(inputManager.btcHoldingsMinInput)")
            return
        }

        guard let btcHoldingsMax = Double(inputManager.btcHoldingsMaxInput.replacingOccurrences(of: ",", with: "")) else {
            print("Error: Invalid BTC Holdings Max: \(inputManager.btcHoldingsMaxInput)")
            return
        }

        print("Generating graphs for Week \(week) with parameters:")
        print("""
        BTC Price Min: \(btcPriceMin), BTC Price Max: \(btcPriceMax),
        Portfolio Min: \(portfolioValueMin), Portfolio Max: \(portfolioValueMax),
        BTC Holdings Min: \(btcHoldingsMin), BTC Holdings Max: \(btcHoldingsMax)
        """)

        let directoryPath = "/Users/conor/Desktop/PS Batch/"
        let directoryURL = URL(fileURLWithPath: directoryPath)

        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                print("Created directory at \(directoryPath)")
            } catch {
                print("Error: Failed to create directory: \(error)")
            }
        }

        createRefinedHistogramWithFilters(
            data: allIterations.flatMap { $0.map { $0.btcPriceUSD } },
            title: "BTC Price Distribution - Week \(week)",
            fileName: "\(directoryPath)Week\(week)_BTCPrice.png",
            minThreshold: btcPriceMin,
            maxThreshold: btcPriceMax,
            discardPercentile: 0.01,
            rotateLabels: true
        )

        createRefinedHistogramWithFilters(
            data: allIterations.flatMap { $0.map { $0.portfolioValueEUR } },
            title: "Portfolio Value Distribution - Week \(week)",
            fileName: "\(directoryPath)Week\(week)_PortfolioValue.png",
            minThreshold: portfolioValueMin,
            maxThreshold: portfolioValueMax,
            discardPercentile: 0.01,
            rotateLabels: true
        )

        createRefinedHistogramWithFilters(
            data: allIterations.flatMap { $0.map { $0.netBTCHoldings } },
            title: "BTC Holdings Distribution - Week \(week)",
            fileName: "\(directoryPath)Week\(week)_BTCHoldings.png",
            minThreshold: btcHoldingsMin,
            maxThreshold: btcHoldingsMax,
            discardPercentile: 0.01,
            rotateLabels: true
        )

        print("Graphs generated successfully in \(directoryPath)")
    }
    
    func formattedBinding(for keyPath: ReferenceWritableKeyPath<PersistentInputManager, String>) -> Binding<String> {
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
                if Double(cleanedValue) != nil || cleanedValue.isEmpty {
                    inputManager.updateValue(keyPath, to: cleanedValue)
                }
            }
        )
    }
    
    struct NumberFormatterWithSeparator {
        static let shared: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.usesGroupingSeparator = true
            formatter.groupingSize = 3
            formatter.maximumFractionDigits = 2 // Allows up to two decimal places
            formatter.minimumFractionDigits = 0 // No unnecessary decimals
            return formatter
        }()
    }
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
    rotateLabels: Bool = false
) {
    let width: CGFloat = 1000
    let height: CGFloat = 700
    let margin: CGFloat = 100

    print("Generating histogram: \(title)")
    print("Output file: \(fileName)")
    print("Data count before filtering: \(data.count)")

    // Filter data by user-defined thresholds
    let filteredData = data.filter { $0 >= minThreshold && $0 <= maxThreshold }
    print("Data count after applying thresholds (\(minThreshold), \(maxThreshold)): \(filteredData.count)")

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
        print("No data left after percentile filtering for \(title). Skipping graph.")
        return
    }

    // Create bins for the histogram
    let minValue = minThreshold
    let maxValue = maxThreshold
    let binCount = 15
    let binWidth = (maxValue - minValue) / Double(binCount)
    var bins = [Int](repeating: 0, count: binCount)

    for value in finalData {
        let binIndex = min(Int((value - minValue) / binWidth), binCount - 1)
        bins[binIndex] += 1
    }

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

    // Format x-axis labels with thousands separators
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
