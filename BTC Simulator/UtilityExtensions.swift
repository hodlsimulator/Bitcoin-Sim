//
//  UtilityExtensions.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation

// MARK: - Utility Extension
extension Double {
    func withThousandsSeparator(decimalPlaces: Int = 8) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
