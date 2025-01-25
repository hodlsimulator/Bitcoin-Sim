//
//  SimulationSummaryCardView.swift
//  BTCMonteCarlo
//
//  Created by . . on 15/01/2025.
//

import SwiftUI

struct SimulationSummaryCardView: View {
    let finalBTCPrice: Double
    let finalPortfolioValue: Double
    let growthPercent: Double
    let currencySymbol: String
    
    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 16
            let totalWidth = geometry.size.width - (horizontalPadding * 2)
            let columnWidth = totalWidth / 3
            
            HStack(spacing: 0) {
                // 1) BTC Price (right aligned)
                VStack(spacing: 4) {
                    Text("BTC Price")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    // e.g. "$1,234.00" or "$1.23T" or "$11.92Qn"
                    Text("\(currencySymbol)\(abbreviateForCardV2(finalBTCPrice))")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .frame(width: columnWidth, alignment: .trailing)
                
                // 2) Portfolio (centre aligned)
                VStack(spacing: 4) {
                    Text("Portfolio")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    // e.g. "$999,999.00" or "$2.34Qn"
                    Text("\(currencySymbol)\(abbreviateForCardV2(finalPortfolioValue))")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .frame(width: columnWidth, alignment: .center)
                
                // 3) Growth (left aligned)
                VStack(spacing: 4) {
                    Text("Growth")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    // e.g. "123%", "2.34M%", "11.07Qn%"
                    Text(abbreviateGrowthV2(growthPercent))
                        .foregroundColor(growthPercent >= 0 ? .green : .red)
                        .font(.title2)
                }
                .frame(width: columnWidth, alignment: .leading)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8)
        }
        .frame(height: 80)
    }
}

// MARK: - 1) BTC & Portfolio
/// If absVal < 1 trillion => normal comma format (1,234.56).
/// Else group exponent in multiples of 3 => T, Q, Qn, Se, O, etc.
private func abbreviateForCardV2(_ value: Double) -> String {
    let sign = (value < 0) ? "-" : ""
    let absVal = abs(value)
    
    // < 1 trillion => "999,999.99"
    if absVal < 1_000_000_000_000 {
        return sign + formatWithCommas(absVal)
    }
    
    // Compute exponent, e.g. 23 for e+23
    let exponent = Int(floor(log10(absVal)))
    
    // If exponent > 30 => fallback to plain decimal
    if exponent > 30 {
        return sign + String(format: "%.2f", absVal)
    }
    
    // Group exponent in multiples of 3 (23 => 21, 19 => 18, etc.)
    let groupedExponent = exponent - (exponent % 3)
    let leadingNumber = absVal / pow(10, Double(groupedExponent))
    
    let suffix = suffixForGroupedExponentV2(groupedExponent)
    return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
}

/// Comma formatting with 2 decimals
private func formatWithCommas(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 2
    formatter.minimumFractionDigits = 2
    return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
}

// MARK: - 2) Growth
/// If < 1000 => "123.45%".
/// Else group exponent => "11.92Qn%", etc.
private func abbreviateGrowthV2(_ value: Double) -> String {
    let sign = (value < 0) ? "-" : ""
    let absVal = abs(value)
    
    // Under 1K => e.g. "123.45%"
    if absVal < 1000 {
        return "\(sign)\(String(format: "%.2f", absVal))%"
    }
    
    let exponent = Int(floor(log10(absVal)))
    
    // Over e+30 => fallback
    if exponent > 30 {
        return "\(sign)\(String(format: "%.2f", absVal))%"
    }
    
    let groupedExponent = exponent - (exponent % 3)
    let leadingNumber = absVal / pow(10, Double(groupedExponent))
    let suffix = suffixForGroupedExponentV2(groupedExponent)
    
    return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)%"
}

// MARK: - Extended suffix logic
/// 12 => "T", 15 => "Q", 18 => "Qn", 21 => "Se", 24 => "O", 27 => "N", 30 => "D"
/// If it doesn't match exactly, we do the nearest lower multiple of 3 and that suffix.
fileprivate func suffixForGroupedExponentV2(_ groupedExponent: Int) -> String {
    switch groupedExponent {
    case 3:  return "K"
    case 6:  return "M"
    case 9:  return "B"
    case 12: return "T"   // trillion
    case 15: return "Q"   // quadrillion
    case 18: return "Qn"  // quintillion
    case 21: return "Se"  // sextillion
    case 24: return "O"   // octillion
    case 27: return "N"   // nonillion
    case 30: return "D"   // decillion
    default:
        return ""  // if 0 or something in between
    }
}
