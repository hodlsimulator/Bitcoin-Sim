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
            // Horizontal padding
            let horizontalPadding: CGFloat = 16
            
            // Total width (minus left + right padding)
            let totalWidth = geometry.size.width - (horizontalPadding * 2)
            
            // Each column is exactly 1/3 of total width
            let columnWidth = totalWidth / 3
            
            HStack(spacing: 0) {
                // 1) BTC Price - right aligned
                VStack(spacing: 4) {
                    Text("BTC Price")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("\(currencySymbol)\(abbreviateValue(finalBTCPrice))")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                .frame(width: columnWidth, alignment: .trailing)
                
                // 2) Portfolio - centre aligned
                VStack(spacing: 4) {
                    Text("Portfolio")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("\(currencySymbol)\(abbreviateValue(finalPortfolioValue))")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                .frame(width: columnWidth, alignment: .center)
                
                // 3) Growth - left aligned
                VStack(spacing: 4) {
                    Text("Growth")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(formatGrowth(growthPercent))
                        .foregroundColor(.green)
                        .font(.title3)
                }
                .frame(width: columnWidth, alignment: .leading)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8) // Minimal vertical padding
        }
        .frame(height: 80) // Fix height so GeometryReader doesn’t expand
    }
}

// MARK: - Helper functions
private func abbreviateValue(_ value: Double) -> String {
    let absVal = abs(value)
    let sign = (value < 0) ? "-" : ""
    
    switch absVal {
    case 1_000_000_000_000...:
        let trillions = absVal / 1_000_000_000_000
        return "\(sign)\(String(format: "%.1f", trillions))T"
    case 1_000_000_000...:
        let billions = absVal / 1_000_000_000
        return "\(sign)\(String(format: "%.1f", billions))B"
    case 1_000_000...:
        let millions = absVal / 1_000_000
        return "\(sign)\(String(format: "%.1f", millions))M"
    case 1_000...:
        let thousands = absVal / 1_000
        return "\(sign)\(String(format: "%.1f", thousands))K"
    default:
        return "\(sign)\(String(format: "%.0f", absVal))"
    }
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
