//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 20/11/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var monteCarloResults: [SimulationData] = [] // Holds simulation results
    @State private var iterations: String = "100" // Number of iterations
    @State private var isLoading: Bool = false // Loading state for simulations

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
    }

    private func runSimulation() {
        isLoading = true // Start loading
        monteCarloResults = [] // Clear previous results

        let spreadsheetData = loadCSV() // Load CSV data
        let initialBTCPriceUSD: Double = 1000.0 // Set initial BTC price
        guard let iterations = Int(iterations) else {
            print("Invalid number of iterations")
            isLoading = false
            return
        }

        let batchSize = 10_000 // Number of simulations per batch
        let numberOfBatches = (iterations + batchSize - 1) / batchSize // Calculate number of batches

        DispatchQueue.global().async {
            var allResults: [SimulationData] = []

            for batch in 0..<numberOfBatches {
                let batchStart = batch * batchSize
                let batchEnd = min((batch + 1) * batchSize, iterations)
                print("Processing batch \(batch + 1) of \(numberOfBatches)")

                let batchResults = runMonteCarloSimulationsWithSpreadsheetData(
                    spreadsheetData: spreadsheetData,
                    initialBTCPriceUSD: initialBTCPriceUSD,
                    iterations: batchEnd - batchStart
                )

                allResults.append(contentsOf: batchResults)
                print("Batch \(batch + 1) complete.")
            }

            DispatchQueue.main.async {
                monteCarloResults = allResults
                print("Total records generated: \(allResults.count)")
                isLoading = false // Stop loading
                calculateMostProbableOutcome()
            }
        }
    }

    private func calculateMostProbableOutcome() {
        // Example: Calculate the average Portfolio Value EUR
        guard !monteCarloResults.isEmpty else { return }

        let averagePortfolioValue = monteCarloResults
            .map { $0.portfolioValueEUR }
            .reduce(0, +) / Double(monteCarloResults.count)

        print("Most Probable Outcome (Average Portfolio Value EUR): \(averagePortfolioValue.formattedWithSeparator())")
    }
}
