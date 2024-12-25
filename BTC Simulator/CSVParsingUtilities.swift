//
//  CSVParsingUtilities.swift
//  BTCMonteCarlo
//
//  Created by Conor on 20/11/2024.
//

import Foundation

/// A simpler parse function (no padding). Handles quoted values and commas.
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

/// Parse a string into a Double, handling locale and decimal separators.
func parseDouble(_ string: String) -> Double? {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    formatter.groupingSeparator = ""
    return formatter.number(from: string)?.doubleValue
}
