//
//  AboutView.swift
//  BTCMonteCarloSimulator
//
//   Created by . . on 20/11/2024.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text("About Bitcoin Sim")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)
                
                // Short Overview
                Text("""
Bitcoin Sim is a forward-looking modelling tool for exploring Bitcoin’s potential price paths over a user-defined timeframe (20 years by default). It draws on historical BTC returns, applies a range of bullish and bearish factors, and uses a unique tilt bar to visually summarise the net market sentiment.
""")
                
                // Tilt Bar Explanation
                Text("""
The tilt bar is a key feature of the simulator. It displays a green hue when bullish factors dominate and red when bearish factors take over. This real-time indicator helps you quickly gauge the overall market bias based on your selected settings.
""")
                
                // Brief Explanation
                Text("""
In each run, the simulator randomly samples past BTC performance, adjusts for your configured volatility, and factors in optional events—like institutional demand or macro downturns. Rather than a single outcome, it produces multiple trials to show a range of possibilities.
""")
                
                // Best-Fit Highlight
                Text("""
A best-fit run is highlighted in orange to indicate the ‘average’ trajectory. This line thickens and darkens as the number of simulations increases, ensuring it stands out even on a busy chart.
""")
                
                // Personalised Portfolio
                Text("""
You can also track a hypothetical portfolio by setting an initial balance and periodic contributions. Each simulation demonstrates how your holdings might grow or contract under different scenarios.
""")
                
                // Wrap Up
                Text("""
With its simple interface, flexible settings, and the intuitive tilt bar, Bitcoin Sim offers a data-driven way to explore how Bitcoin’s future might unfold—whether for 20 years or any timeframe you prefer.
""")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .background(Color(white: 0.12).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
