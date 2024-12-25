//
//  CSVLoaderHistorical.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/12/2024.
//

import Foundation

func loadHistoricalCSV() -> [BitcoinHistoricalData] {
    // Make sure the file name matches exactly what you have in the project!
    // For example, if your CSV is named "Bitcoin Historical Data.csv",
    // the resource name is "Bitcoin Historical Data" (without the .csv extension).
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data", ofType: "csv") else {
        print("Error: 'Bitcoin Historical Data.csv' not found in app bundle.")
        return []
    }

    do {
        // 1) Read the file contents
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        
        // 2) Split into lines, ignoring empty lines
        let rows = content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var result: [BitcoinHistoricalData] = []
        
        // 3) For each row...
        for (index, row) in rows.enumerated() {
            // Skip the header row if your CSV has a header:
            // e.g. "Date,Price,Open,High,Low,Vol.,Change %"
            if index == 0 {
                continue
            }
            
            // 4) Split columns by commas, taking quotes into account
            let columns = parseCSVRowNoPadding(row)
            
            // We expect at least 7 columns
            if columns.count < 7 {
                print("Warning: row has fewer than 7 columns: \(row)")
                continue
            }
            
            // Columns:
            // 0 = Date
            // 1 = Price
            // 2 = Open
            // 3 = High
            // 4 = Low
            // 5 = Vol.
            // 6 = Change %
            
            let dateString   = columns[0]
            let priceString  = columns[1]
            let openString   = columns[2]
            let highString   = columns[3]
            let lowString    = columns[4]
            let volumeString = columns[5]
            let changeString = columns[6]
            
            // 5) Convert numeric columns to Double
            guard let price = parseDouble(priceString),
                  let open  = parseDouble(openString),
                  let high  = parseDouble(highString),
                  let low   = parseDouble(lowString)
            else {
                print("Warning: Could not parse numeric columns in row: \(row)")
                continue
            }
            
            // 6) Convert the "Change %" column to a numeric double
            //     e.g. "+1.50%" => 1.50
            //          "-0.75%" => -0.75
            let cleanedChangeString = changeString
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let changePercent = parseDouble(cleanedChangeString) ?? 0.0
            
            // 7) Create the struct
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
        
        print("Loaded \(result.count) rows from 'Bitcoin Historical Data.csv'.")
        return result

    } catch {
        print("Error reading 'Bitcoin Historical Data.csv': \(error.localizedDescription)")
        return []
    }
}

