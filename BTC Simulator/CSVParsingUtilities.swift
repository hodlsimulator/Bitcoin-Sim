//
//  CSVParsingUtilities.swift
//  BTCMonteCarlo
//
//  Created by Conor on 20/11/2024.
//

import Foundation

func parseCSVRowNoPadding(_ row: String) -> [String] {
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
    return columns
}

func parseDouble(_ s: String) -> Double? {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    return formatter.number(from: s)?.doubleValue
}
