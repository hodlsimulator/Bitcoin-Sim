//
//  AboutView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MAIN TITLE
                Text("About HODL Simulator")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)

                // INTRODUCTION
                Text("""
HODL Simulator is your tool for exploring Bitcoin’s potential future. Whether you’re curious about long-term price trends, the effects of macro events, or Bitcoin-specific milestones like halvings, this app lets you simulate scenarios and visualise outcomes. Dive into the numbers and discover what could shape Bitcoin over the next 20 years.
""")

                // WHAT THE APP DOES
                Text("What Does It Do?")
                    .font(.title2)
                    .bold()
                Text("""
HODL Simulator models Bitcoin’s price over 20 years (~1,040 weeks) by combining historical price patterns with adjustable bullish and bearish factors. From Halvings to Global Recessions, you control the assumptions. The app runs hundreds or thousands of simulations to show a range of potential outcomes, helping you explore how your BTC holdings might grow—or shrink—under different conditions.
""")

                // KEY FEATURES
                Text("Key Features")
                    .font(.title2)
                    .bold()
                Text("""
- **Bullish and Bearish Factors**: Adjust events like Institutional Demand, ETF Approval, Recessions, or Black Swan events to see their impact on Bitcoin’s price.
- **Monte Carlo Simulations**: Run randomised scenarios to understand the range of possible futures.
- **Customised Parameters**: Set annual growth rates, volatility, and contribution amounts to match your personal outlook.
- **Portfolio Insights**: See how your contributions, withdrawals, and Bitcoin holdings evolve over time.
- **Factor Explanations**: Each factor includes a detailed description to help you understand its role in the simulation.
""")

                // SETTINGS PAGE
                Text("Customising Simulations")
                    .font(.title2)
                    .bold()
                Text("""
Head to the Settings page to tailor your simulation. Each factor has a toggle to turn it on or off and a slider to adjust its strength. For example:
- **Halving**: Models Bitcoin’s supply cuts, historically linked to price rallies.
- **Regulatory Clarity**: Adds positive effects from clear and favourable crypto regulations.
- **Scarcity Events**: Reflects reduced BTC supply on exchanges, leading to price increases.
Whether you’re bullish, bearish, or somewhere in between, you can customise your settings to match your view of Bitcoin’s future.
""")

                // RANDOM SEED
                Text("Consistent Results with Random Seed")
                    .font(.title2)
                    .bold()
                Text("""
By default, each simulation is random, producing unique results. If you want consistent outcomes to compare scenarios, turn on “Lock Random Seed.” This feature ensures that random elements—like weekly returns—stay the same across runs. It’s perfect for testing individual factors, such as “Institutional Demand On vs. Off.”
""")

                // HOW IT WORKS
                Text("How It Works")
                    .font(.title2)
                    .bold()
                Text("""
The simulator starts with historical BTC price data and runs week-by-week for 20 years. Each week, it applies randomised returns adjusted by the factors you’ve selected. Contributions and withdrawals are tracked as your portfolio evolves, showing how your BTC holdings might grow—or contract—over time. After completing the simulations, you’ll see a range of possible outcomes, including a median scenario.
""")

                // EXPERIMENTATION
                Text("Experiment and Explore")
                    .font(.title2)
                    .bold()
                Text("""
HODL Simulator is designed to help you think about Bitcoin’s long-term potential. While no tool can predict the future, this app lets you explore different scenarios and better understand the forces that could shape Bitcoin in the years ahead. Tweak settings, test assumptions, and see how the future could unfold.
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
