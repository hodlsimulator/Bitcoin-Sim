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
            ZStack {
                let horizontalPadding: CGFloat = 16
                let totalWidth = geometry.size.width - (horizontalPadding * 2)
                let columnWidth = totalWidth / 3

                HStack(spacing: 0) {
                    // (1) BTC Price
                    VStack(spacing: 4) {
                        Text("BTC Price")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("\(currencySymbol)\(abbreviateForCardV2(finalBTCPrice))")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .frame(width: columnWidth, alignment: .trailing)
                    
                    // (2) Portfolio
                    VStack(spacing: 4) {
                        Text("Portfolio")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("\(currencySymbol)\(abbreviateForCardV2(finalPortfolioValue))")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .frame(width: columnWidth, alignment: .center)
                    
                    // (3) Growth
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
                .padding(.vertical, 16)
                // The 'x: -2.5' moves everything left by 2.5 points,
                // 'y: -5' moves it up by 5 points.
                .offset(x: -2.5, y: -5)
            }
        }
        .frame(height: 80)
    }
}

// MARK: - 1) BTC & Portfolio
private func abbreviateForCardV2(_ value: Double) -> String {
    let sign = (value < 0) ? "-" : ""
    let absVal = abs(value)
    
    if absVal < 1000 {
        return sign + String(format: "%.2f", absVal)
    }
    
    let exponent = Int(floor(log10(absVal)))
    if exponent > 30 {
        return sign + String(format: "%.2f", absVal)
    }
    
    let groupedExponent = exponent - (exponent % 3)
    let leadingNumber = absVal / pow(10, Double(groupedExponent))
    let suffix = suffixForGroupedExponentV2(groupedExponent)
    return "\(sign)\(String(format: "%.2f", leadingNumber))\(suffix)"
}

// MARK: - 2) Growth
private func abbreviateGrowthV2(_ value: Double) -> String {
    let sign = (value < 0) ? "-" : ""
    let absVal = abs(value)
    
    if absVal < 1000 {
        return "\(sign)\(String(format: "%.2f", absVal))%"
    }
    
    let exponent = Int(floor(log10(absVal)))
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
    case 12: return "T"
    case 15: return "Q"
    case 18: return "Qn"
    case 21: return "Se"
    case 24: return "O"
    case 27: return "N"
    case 30: return "D"
    default:
        return ""
    }
}
