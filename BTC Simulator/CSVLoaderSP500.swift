//
//  CSVLoaderSP500.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

func loadSP500WeeklyReturns() -> [Double] {
    guard let filePath = Bundle.main.path(forResource: "S&P 500 Historical Data Weekly", ofType: "csv") else {
        return []
    }
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var weeklyReturns: [Double] = []

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
                weeklyReturns.append(val / 100.0)
            }
        }
        return weeklyReturns

    } catch {
        return []
    }
}

func loadSP500MonthlyReturns() -> [Double] {
    guard let filePath = Bundle.main.path(forResource: "S&P 500 Historical Data Monthly", ofType: "csv") else {
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
