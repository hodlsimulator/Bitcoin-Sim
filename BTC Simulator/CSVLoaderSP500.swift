//
//  CSVLoaderSP500.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

func loadSP500WeeklyReturns() -> [Double] {
    // 1) Check if the file is in the bundle
    guard let filePath = Bundle.main.path(forResource: "SP500 Historical Data", ofType: "csv") else {
        print("DEBUG: SP500 Historical Data.csv NOT FOUND in the main bundle.")
        return []
    }
    print("DEBUG: Found SP500 Historical Data.csv at \(filePath)")

    do {
        // 2) Read file content
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        print("DEBUG: Read SP500 CSV content with length \(content.count) characters.")

        // 3) Split into lines
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        print("DEBUG: SP500 CSV has \(rows.count) lines (including header).")

        var weeklyReturns: [Double] = []

        // 4) Iterate over each row, skipping the header
        for (index, row) in rows.enumerated() {
            if index == 0 {
                print("DEBUG: Skipping SP500 CSV header row: \(row)")
                continue
            }

            // 5) Parse columns
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 {
                print("DEBUG: Not enough columns in SP500 row: \(row)")
                continue
            }

            // 6) “Change %” column is typically at index 6
            let changeStr = cols[6]
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // 7) Convert to double
            if let val = parseDouble(changeStr) {
                weeklyReturns.append(val / 100.0)
            } else {
                print("DEBUG: Could not parse changeStr \(changeStr) in row: \(row)")
            }
        }

        print("DEBUG: Returning SP500 weekly returns array of size \(weeklyReturns.count).")
        return weeklyReturns

    } catch {
        print("DEBUG: Error reading SP500 CSV - \(error)")
        return []
    }
}
