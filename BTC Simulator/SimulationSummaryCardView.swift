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
                // 1) BTC Price - right aligned
                VStack(spacing: 4) {
                    Text("BTC Price")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("\(currencySymbol)\(abbreviateValue(finalBTCPrice))")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .frame(width: columnWidth, alignment: .trailing)
                
                // 2) Portfolio - centre aligned
                VStack(spacing: 4) {
                    Text("Portfolio")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text("\(currencySymbol)\(abbreviateValue(finalPortfolioValue))")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .frame(width: columnWidth, alignment: .center)
                
                // 3) Growth - left aligned
                VStack(spacing: 4) {
                    Text("Growth")
                        .font(.title3)
                        .foregroundColor(.gray)
                    Text(formatGrowth(growthPercent))
                        .foregroundColor(.green)
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

// MARK: - Helper functions
private func abbreviateValue(_ value: Double) -> String {
    let absVal = abs(value)
    let sign = (value < 0) ? "-" : ""
    
    switch absVal {
    case 1_000_000_000_000...:
        let trillions = absVal / 1_000_000_000_000
        return "\(sign)\(formatDecimalNoTrailingZeros(trillions))T"
    case 1_000_000_000...:
        let billions = absVal / 1_000_000_000
        return "\(sign)\(formatDecimalNoTrailingZeros(billions))B"
    case 1_000_000...:
        let millions = absVal / 1_000_000
        return "\(sign)\(formatDecimalNoTrailingZeros(millions))M"
    case 1_000...:
        let thousands = absVal / 1_000
        return "\(sign)\(formatDecimalNoTrailingZeros(thousands))K"
    default:
        return "\(sign)\(formatDecimalNoTrailingZeros(absVal))"
    }
}

private func formatDecimalNoTrailingZeros(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    // e.g. 17.0 -> "17", 15.5 -> "15.5"
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

private func formatGrowth(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0
    if let str = formatter.string(from: NSNumber(value: value)) {
        return str + "%"
    } else {
        return "\(Int(value))%"
    }
}
