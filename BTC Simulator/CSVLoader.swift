//
//  CSVLoader.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
/*
func loadCSV() -> [SimulationData] {
    guard let filePath = Bundle.main.path(forResource: "BTC20YearProjection", ofType: "csv") else {
        print("Error: CSV file not found in app bundle.")
        return []
    }

    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var result: [SimulationData] = []

        for (index, row) in rows.enumerated() {
            // Skip the header row
            if index == 0 { continue }

            let columns = parseCSVRow(row)
            if columns.count < 13 { continue }

            let week = Int(columns[0]) ?? 0
            let startingBTC = Double(columns[2]) ?? 0.0
            var btcPriceUSDAsDouble = Double(columns[5].replacingOccurrences(of: ",", with: "")) ?? 0.0
            var portfolioValueEURAsDouble = Double(columns[7]) ?? 0.0

            // Hardcode specific values for the first two weeks
            if week == 1 {
                btcPriceUSDAsDouble = 76532.03
                portfolioValueEURAsDouble = 333.83
            } else if week == 2 {
                btcPriceUSDAsDouble = 93600.91
                portfolioValueEURAsDouble = 475.67
            }

            let data = SimulationData(
                week: week,
                startingBTC: startingBTC,
                netBTCHoldings: Double(columns[4]) ?? 0.0,

                // Convert `Double` → `Decimal` for these three
                btcPriceUSD: Decimal(btcPriceUSDAsDouble),
                btcPriceEUR: Decimal(Double(columns[6].replacingOccurrences(of: ",", with: "")) ?? 0.0),
                portfolioValueEUR: Decimal(portfolioValueEURAsDouble),

                // The rest remain `Double`
                contributionEUR: Double(columns[8]) ?? 0.0,
                transactionFeeEUR: Double(columns[9]) ?? 0.0,
                netContributionBTC: Double(columns[10]) ?? 0.0,
                withdrawalEUR: Double(columns[11]) ?? 0.0
            )

            result.append(data)
        }

        print("Loaded \(result.count) rows from CSV.")
        return result
    } catch {
        print("Error reading CSV file: \(error.localizedDescription)")
        return []
    }
}

/// Helper to parse a CSV row, accounting for quoted values and commas
func parseCSVRow(_ row: String) -> [String] {
    var columns: [String] = []
    var current = ""
    var inQuotes = false

    for char in row {
        if char == "\"" {
            inQuotes.toggle()
        } else if char == "," && !inQuotes {
            columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
            current = ""
        } else {
            current.append(char)
        }
    }

    if !current.isEmpty {
        columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // Ensure at least 13 columns exist
    while columns.count < 13 {
        columns.append("")
    }

    return columns
}
*/
