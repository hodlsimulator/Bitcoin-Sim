//
//  BigNumberExtensions.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import Foundation

// MARK: - Big Number Suffix in 3-exponent groups
extension Double {
    
    /// Formats a raw number using K, M, B, T, Q, Qn, Se, etc.
    /// - If abs < 1_000, shows normal decimal with two places (e.g. "999.99").
    /// - Above that, groups exponent in multiples of 3:
    ///   - 1,234 => "1.23K", 1,234,567 => "1.23M", etc.
    ///   - 1.1067e19 => "11.07Qn".
    /// - If the exponent > 21, just show 2 decimal places with no suffix (to avoid going beyond 'Se').
    func formattedGroupedSuffix() -> String {
        if self == 0 {
            return "0.00"
        }
        let sign = (self < 0) ? "-" : ""
        let absVal = abs(self)
        
        // If it's under 1K, just show "999.99" style
        if absVal < 1000 {
            return sign + String(format: "%.2f", absVal)
        }
        
        // Find exponent (log base 10)
        let exponent = Int(floor(log10(absVal)))
        // If exponent is beyond 21, just show it as a raw decimal with 2 places
        guard exponent <= 21 else {
            return sign + String(format: "%.2f", absVal)
        }
        
        // Group exponent in multiples of 3. e.g. 19 => 18, 10 => 9, 7 => 6, etc.
        let groupedExponent = exponent - (exponent % 3)
        // leadingNumber is absVal / 10^(groupedExponent)
        let leadingNumber = absVal / pow(10, Double(groupedExponent))
        
        // Suffix depends on groupedExponent
        let suffix = suffixForGroupedExponent(groupedExponent)
        
        // e.g. "1.23M"
        return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
    }
    
    /// Like `formattedGroupedSuffix()` but appends '%' at the end,
    /// used for large percentages. e.g. 1.234e6 => "1.23M%".
    func formattedGroupedSuffixPercent() -> String {
        if self == 0 {
            return "0%"
        }
        let sign = (self < 0) ? "-" : ""
        let absVal = abs(self)
        
        // If < 1000%, show something like "123.45%"
        if absVal < 1000 {
            return "\(sign)\(String(format: "%.2f", absVal))%"
        }
        
        // For bigger, do the same grouping
        let exponent = Int(floor(log10(absVal)))
        guard exponent <= 21 else {
            return "\(sign)\(String(format: "%.2f", absVal))%"
        }
        let groupedExponent = exponent - (exponent % 3)
        let leadingNumber = absVal / pow(10, Double(groupedExponent))
        
        let suffix = suffixForGroupedExponent(groupedExponent)
        // e.g. "1.23K%"
        return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)%"
    }
}

// MARK: - Mapping grouped exponent to suffix
fileprivate func suffixForGroupedExponent(_ groupedExponent: Int) -> String {
    switch groupedExponent {
    case 0: return ""
    case 3: return "K"
    case 6: return "M"
    case 9: return "B"
    case 12: return "T"
    case 15: return "Q"
    case 18: return "Qn"
    case 21: return "Se"  // for 10^21
    default:
        // If we get a weird exponent not in this switch,
        // just show "eX" or fallback to no suffix
        return ""
    }
}
