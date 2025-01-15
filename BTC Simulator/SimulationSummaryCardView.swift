//
//  SimulationSummaryCardView.swift
//  BTCMonteCarlo
//
//  Created by . . on 15/01/2025.
//

import SwiftUI

struct SimulationSummaryCardView: View {
    
    /// We expect to get the final numbers from ContentView (or a coordinator).
    /// You can either pass them directly or pass a coordinator.
    /// Here, I'm just passing in three final numeric values:
    let finalBTCPrice: Double
    let finalPortfolioValue: Double
    let growthPercent: Double
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading) {
                Text("BTC Final Price")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("$\(abbreviateValue(finalBTCPrice))")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            Divider()
                .frame(height: 40)
                .background(Color.gray)
            
            VStack(alignment: .leading) {
                Text("Portfolio")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("$\(abbreviateValue(finalPortfolioValue))")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            Divider()
                .frame(height: 40)
                .background(Color.gray)
            
            VStack(alignment: .leading) {
                Text("Growth")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(formatGrowth(growthPercent))
                    .foregroundColor(.green)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(white: 0.20))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Helper functions
private func abbreviateValue(_ value: Double) -> String {
    // e.g. 1,234 => "1.2K", 1,234,567 => "1.2M", etc
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
    // e.g. 135,330 => "135,330%"
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
