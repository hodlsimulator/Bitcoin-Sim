//
//  CSVLoader.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

func loadCSV() -> [SimulationData] {
    guard let filePath = Bundle.main.path(forResource: "BTC20YearProjection", ofType: "csv") else {
        print("Error: CSV file not found in app bundle.")
        return []
    }

    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var result: [SimulationData] = []

        for (index, row) in rows.enumerated() {
            if index == 0 { continue } // Skip header row

            let columns = parseCSVRow(row)
            if columns.count < 13 { continue }

            let week = Int(columns[0]) ?? 0
            let startingBTC = Double(columns[2]) ?? 0.0
            var btcPriceUSD = Double(columns[5].replacingOccurrences(of: ",", with: "")) ?? 0.0
            var portfolioValueEUR = Double(columns[7]) ?? 0.0

            // Hardcode specific values for the first two weeks
            if week == 1 {
                btcPriceUSD = 76532.03
                portfolioValueEUR = 333.83
            } else if week == 2 {
                btcPriceUSD = 93600.91
                portfolioValueEUR = 475.67
            }

            let data = SimulationData(
                week: week,
                startingBTC: startingBTC,
                netBTCHoldings: Double(columns[4]) ?? 0.0,
                btcPriceUSD: btcPriceUSD,
                btcPriceEUR: Double(columns[6].replacingOccurrences(of: ",", with: "")) ?? 0.0,
                portfolioValueEUR: portfolioValueEUR,
                contributionEUR: Double(columns[8]) ?? 0.0,
                transactionFeeEUR: Double(columns[9]) ?? 0.0, // Renamed here too
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

func parseDouble(_ string: String) -> Double? {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    formatter.groupingSeparator = ""
    return formatter.number(from: string)?.doubleValue
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

    while columns.count < 13 {
        columns.append("")
    }

    return columns
}
