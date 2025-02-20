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
    
    // Add this closure for the back button
    let onBackTapped: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                
                // Existing HStack with price/portfolio/growth
                let horizontalPadding: CGFloat = 16
                let totalWidth = geometry.size.width - (horizontalPadding * 2)
                let columnWidth = totalWidth / 3

                HStack(spacing: 0) {
                    // 1) BTC Price
                    VStack(spacing: 4) {
                        Text("BTC Price")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text("\(currencySymbol)\(abbreviateForCardV2(finalBTCPrice))")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .frame(width: columnWidth, alignment: .trailing)
                    
                    // 2) Portfolio
                    VStack(spacing: 4) {
                        Text("Portfolio")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text("\(currencySymbol)\(abbreviateForCardV2(finalPortfolioValue))")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .frame(width: columnWidth, alignment: .center)
                    
                    // 3) Growth
                    VStack(spacing: 4) {
                        Text("Growth")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text(abbreviateGrowthV2(growthPercent))
                            .foregroundColor(growthPercent >= 0 ? .green : .red)
                            .font(.title2)
                    }
                    .frame(width: columnWidth, alignment: .leading)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 8)
                
                // NEW: A simple back button at top-left
                Button(action: onBackTapped) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(8)
                }
                .padding(.leading, 12)
                .padding(.top, 8)
                
            }
        }
        .frame(height: 80)
    }
}

// MARK: - 1) BTC & Portfolio
/// Now abbreviates as soon as it's ≥ 1000 => "1.23K", "4.56M", "7.89B", etc.
/// If < 1000 => shows e.g. "999.99" with two decimals.
private func abbreviateForCardV2(_ value: Double) -> String {
    let sign = (value < 0) ? "-" : ""
    let absVal = abs(value)
    
    // For values under 1000, just show two decimals
    if absVal < 1000 {
        return sign + String(format: "%.2f", absVal)
    }
    
    let exponent = Int(floor(log10(absVal)))
    
    // Over e+30 => fallback to plain decimal
    if exponent > 30 {
        return sign + String(format: "%.2f", absVal)
    }
    
    // Group exponent in multiples of 3 (e.g. 5 -> 3 for "K"; 6 -> 6 for "M")
    let groupedExponent = exponent - (exponent % 3)
    let leadingNumber = absVal / pow(10, Double(groupedExponent))
    
    let suffix = suffixForGroupedExponentV2(groupedExponent)
    return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
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
        return ""
    }
}
