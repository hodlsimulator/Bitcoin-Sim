//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 20/11/2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var monteCarloResults: [SimulationData] = [] // Holds simulation results
    @State private var iterations: String = "1000" // Number of iterations
    @State private var isLoading: Bool = false // Loading state for simulations
    @State private var pdfData: Data? // Holds generated PDF data
    @State private var showFileExporter = false // Controls file exporter visibility
    
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
        VStack {
            // Simulation Parameters Input
            HStack {
                TextField("Enter number of simulations", text: $iterations)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                Button("Run Simulation") {
                    runSimulation()
                }
                .padding()
                
                // Show a ProgressView when loading
                if isLoading {
                    ProgressView()
                        .padding(.leading, 10)
                }
            }
            
            // Main Horizontal ScrollView
            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    // Fixed Header Section
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        Text("Week").bold()
                        Text("Cycle Phase").bold()
                        Text("Starting BTC").bold()
                        Text("BTC Growth").bold()
                        Text("Net BTC Holdings").bold()
                        Text("BTC Price USD").bold()
                        Text("BTC Price EUR").bold()
                        Text("Portfolio Value EUR").bold()
                        Text("Contribution EUR").bold()
                        Text("Contribution Fee EUR").bold()
                        Text("Net Contribution BTC").bold()
                        Text("Withdrawal EUR").bold()
                        Text("Portfolio Pre-Withdrawal EUR").bold()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2)) // Header background
                    
                    // Divider between header and data rows
                    Divider()
                    
                    // Data Rows with Vertical ScrollView
                    ScrollView(.vertical) {
                        LazyVGrid(columns: gridColumns, spacing: 10) {
                            ForEach(monteCarloResults, id: \.id) { record in
                                Text("\(record.week)")
                                Text(record.cyclePhase)
                                Text(record.startingBTC.formattedBTC())
                                Text(record.btcGrowth.formattedBTC())
                                Text(record.netBTCHoldings.formattedBTC())
                                Text(record.btcPriceUSD.formattedWithSeparator())
                                Text(record.btcPriceEUR.formattedWithSeparator())
                                Text(record.portfolioValueEUR.formattedWithSeparator())
                                Text(record.contributionEUR.formattedWithSeparator())
                                Text(record.contributionFeeEUR.formattedWithSeparator())
                                Text(record.netContributionBTC.formattedBTC())
                                Text(record.withdrawalEUR.formattedWithSeparator())
                                Text(record.portfolioPreWithdrawalEUR.formattedWithSeparator())
                            }
                        }
                        .padding()
                    }
                    // Set a frame height to enable vertical scrolling
                    .frame(height: 600)
                }
            }
            // Show horizontal and vertical scroll indicators
            .scrollIndicators(.visible)
            .border(Color.gray) // Optional border for the scrollable area
        }
        .padding()
        .fileExporter(
            isPresented: $showFileExporter,
            document: pdfData != nil ? PDFDocumentData(data: pdfData!, fileName: "BTCMonteCarloResults.pdf") : nil,
            contentType: .pdf
        ) { result in
            switch result {
            case .success(let url):
                print("PDF saved to \(url)")
            case .failure(let error):
                print("Failed to save PDF: \(error.localizedDescription)")
            }
        }
    }
    
    private func runSimulation() {
        isLoading = true
        monteCarloResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            let spreadsheetData = loadCSV()
            guard let totalIterations = Int(iterations) else {
                print("Invalid number of iterations")
                DispatchQueue.main.async {
                    isLoading = false
                }
                return
            }

            print("Starting \(totalIterations) iterations...")
            let results = runMonteCarloSimulationsWithSpreadsheetData(
                spreadsheetData: spreadsheetData,
                initialBTCPriceUSD: 1000.0,
                iterations: totalIterations
            )

            DispatchQueue.main.async {
                monteCarloResults = results
                isLoading = false
                print("Simulation completed with \(results.count) rows")
            }

            let resultsCopy = Array(results) // Safely copy the results array

            DispatchQueue.global(qos: .background).async {
                print("Generating PDF...")
                
                // Call `generatePDFData` safely in the background thread
                let generatedData = generatePDFData(results: resultsCopy)
                
                DispatchQueue.main.async {
                    if let data = generatedData {
                        pdfData = data
                        showFileExporter = true
                        print("PDF data generated successfully")
                    } else {
                        print("Failed to generate PDF data")
                    }
                }
            }
        }
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
