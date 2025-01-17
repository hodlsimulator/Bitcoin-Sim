//
//  CSVLoaderBTC.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

func loadBTCWeeklyReturns() -> [Double] {
    // 1) Check if the file is in the bundle
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data Weekly", ofType: "csv") else {
        return []
    }
    
    do {
        // 2) Read the entire file content
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        
        // 3) Split into lines
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
    
        var weeklyReturns: [Double] = []

        // 4) Iterate over each row, skipping header
        for (index, row) in rows.enumerated() {
            if index == 0 {
                continue
            }

            // 5) Parse columns
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 {
                continue
            }

            // 6) “Change %” column is typically index 6
            let changeStr = cols[6]
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // 7) Convert to double
            if let val = parseDouble(changeStr) {
                weeklyReturns.append(val / 100.0) // e.g. “2.0” => 0.02
            }
        }

        return weeklyReturns

    } catch {
        return []
    }
}

func loadBTCMonthlyReturns() -> [Double] {
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data Monthly", ofType: "csv") else {
        return []
    }
    
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var monthlyReturns: [Double] = []

        for (index, row) in rows.enumerated() {
            if index == 0 {
                continue
            }
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 {
                continue
            }

            let changeStr = cols[6]
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let val = parseDouble(changeStr) {
                monthlyReturns.append(val / 100.0)
            }
        }
        return monthlyReturns

    } catch {
        return []
    }
}
