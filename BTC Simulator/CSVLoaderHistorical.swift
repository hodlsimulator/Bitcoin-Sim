//
//  CSVLoaderHistorical.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/12/2024.
//

import Foundation

func loadBTCMonthlyData() -> [BitcoinHistoricalData] {
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data Monthly", ofType: "csv") else {
        print("Error: 'Bitcoin Historical Data Monthly.csv' not found in app bundle.")
        return []
    }

    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        var result: [BitcoinHistoricalData] = []

        for (index, row) in rows.enumerated() {
            if index == 0 {
                continue
            }
            
            let columns = parseCSVRowNoPadding(row)
            if columns.count < 7 {
                continue
            }
            
            let dateString   = columns[0]
            let priceString  = columns[1]
            let openString   = columns[2]
            let highString   = columns[3]
            let lowString    = columns[4]
            let volumeString = columns[5]
            let changeString = columns[6]
            
            guard let price = parseDouble(priceString),
                  let open  = parseDouble(openString),
                  let high  = parseDouble(highString),
                  let low   = parseDouble(lowString) else {
                continue
            }
            
            let cleanedChangeString = changeString
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let changePercent = parseDouble(cleanedChangeString) ?? 0.0
            
            let rowData = BitcoinHistoricalData(
                date: dateString,
                price: price,
                open: open,
                high: high,
                low: low,
                volume: volumeString,
                changePercent: changePercent
            )
            
            result.append(rowData)
        }
        
        print("Loaded \(result.count) rows from 'Bitcoin Historical Data Monthly.csv'.")
        return result

    } catch {
        print("Error reading 'Bitcoin Historical Data Monthly.csv': \(error.localizedDescription)")
        return []
    }
}
