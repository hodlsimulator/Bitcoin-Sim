//
//  AboutView.swift
//  BTCMonteCarlo
//
//  Created by Conor on ...
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Title
                Text("About HODL Simulator")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)

                // Short Overview
                Text("""
HODL Simulator is a forward-looking modelling tool for exploring Bitcoin’s potential price paths over about 20 years. It draws on historical BTC returns, applies various factors (both bullish and bearish), and uses a log-scale approach to model realistic price changes.
""")

                // Brief Explanation
                Text("""
In each run, the simulator randomly samples past BTC performance, adjusts for your configured volatility, and factors in optional events (like institutional demand or macro downturns). Instead of a single outcome, it generates multiple trials to show a range of possibilities.
""")

                // Best-Fit Highlight
                Text("""
To help you see an “average” trajectory, HODL Simulator highlights a best-fit run in orange. This line grows thicker and darker as you increase the total number of simulations, so it stands out even when the chart is crowded.
""")

                // Personalised Portfolio
                Text("""
You can also track a hypothetical portfolio by adding an initial balance and periodic contributions. Each simulation shows how your holdings might grow (or shrink) under the randomised price paths.
""")

                // Wrap Up
                Text("""
With its straightforward interface and flexible settings, HODL Simulator offers an intuitive way to explore how Bitcoin’s future might unfold, letting you test different scenarios in a controlled, data-driven environment.
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
