//
//  CSVLoaderBTC.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

func loadBTCWeeklyReturns() -> [Double] {
    // 1) Check if the file is in the bundle
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data", ofType: "csv") else {
        print("DEBUG: Bitcoin Historical Data.csv NOT FOUND in the main bundle.")
        return []
    }
    print("DEBUG: Found Bitcoin Historical Data.csv at \(filePath)")

    do {
        // 2) Read the entire file content
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        print("DEBUG: Read BTC CSV content with length \(content.count) characters.")

        // 3) Split into lines
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        print("DEBUG: BTC CSV has \(rows.count) lines (including header).")

        var weeklyReturns: [Double] = []

        // 4) Iterate over each row, skipping header
        for (index, row) in rows.enumerated() {
            if index == 0 {
                print("DEBUG: Skipping BTC CSV header row: \(row)")
                continue
            }

            // 5) Parse columns
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 {
                print("DEBUG: Not enough columns in BTC row: \(row)")
                continue
            }

            // 6) “Change %” column is typically index 6
            let changeStr = cols[6]
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // 7) Convert to double
            if let val = parseDouble(changeStr) {
                // Convert e.g. +2.0% into 0.02
                weeklyReturns.append(val / 100.0)
            } else {
                print("DEBUG: Could not parse changeStr \(changeStr) in row: \(row)")
            }
        }

        print("DEBUG: Returning BTC weekly returns array of size \(weeklyReturns.count).")
        return weeklyReturns

    } catch {
        print("DEBUG: Error reading BTC CSV - \(error)")
        return []
    }
}
