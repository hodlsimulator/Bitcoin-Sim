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

                // INTRO SECTION
                Text("""
HODL Simulator is a forward-looking modelling tool for anyone seeking to understand Bitcoin’s potential price paths over the next 20 years. By weaving together historical BTC returns, market volatility, and a wide array of bullish and bearish factors, it provides a comprehensive picture of how Bitcoin’s future might unfold. Whether you're studying halving cycles, technological breakthroughs, or recession risks, the app’s Monte Carlo approach lets you spin up thousands of “what if” scenarios.
""")
                
                // HOW IT WORKS
                Text("How It Works")
                    .font(.title2)
                    .bold()
                Text("""
1. **Historical Data Foundation**  
   We use real BTC weekly returns as a baseline, sampling them at random to preserve market realism. Over 1,040 weeks (~20 years), the simulator adjusts these returns with your chosen settings.  

2. **Bullish and Bearish Factors**  
   Each factor represents a plausible event or trend—think new institutional demand, breakthroughs in Bitcoin technology, or macroeconomic turmoil. Toggle these factors on or off, setting their strengths to see how events might stack up.

3. **Monte Carlo Simulation**  
   Rather than producing one deterministic path, HODL Simulator runs many randomised trials. In each trial, weekly BTC returns are drawn from historical data, shaped by your factor settings. This process is repeated hundreds or thousands of times, painting a full distribution of possible outcomes.

4. **Portfolio Evolution**  
   You can configure personal contributions, initial balances, and cost bases. Each simulation tracks your hypothetical BTC holdings, adjusted weekly by performance and contributions. This shows how your portfolio’s value might shift under various conditions.

5. **Week-by-Week Median**  
   After all runs complete, the app computes a *median line*—a realistic midpoint at each week. On the chart, it’s rendered in orange, so you can see how the “middle ground” compares to the many individual paths.
""")

                // THE CHART
                Text("Visualising the Future")
                    .font(.title2)
                    .bold()
                Text("""
The simulator’s chart displays each run as a faint line on a **log-scale** y-axis, capturing Bitcoin’s capacity for large moves. The orange line indicates the median BTC price at every week, offering a single “most typical” reference curve. This visualisation makes it straightforward to grasp how varied Bitcoin’s trajectory could be, spanning moderate price growth, explosive rallies, or marked downturns.
""")

                // SETTINGS & TOGGLES
                Text("Settings & Toggles")
                    .font(.title2)
                    .bold()
                Text("""
- **Toggle All**: Flip all bullish and bearish factors on or off instantly, to create fully bear or bull scenarios.  
- **Annual CAGR & Volatility**: Adjust the broader growth rate and price swings to align with your expectations.  
- **Random Seed**: Lock the seed for reproducible runs, or leave it random for fresh outcomes.  
- **Factors**: Incorporate halving bumps, scarcity events, black swans, regulatory clampdowns, and more—each factor is customisable to match your outlook.
""")

                // WHO ITS FOR
                Text("Who Is It For?")
                    .font(.title2)
                    .bold()
                Text("""
HODL Simulator serves those keen to experiment with data-driven, long-term Bitcoin scenarios. If you’re interested in how supply shocks, market psychology, and global economic conditions might affect Bitcoin’s journey, this tool can help you test your theories in a structured, scenario-based environment.
""")

                // CLOSING
                Text("""
By configuring different assumptions, you can see just how dramatically Bitcoin’s outlook might change with shifts in demand, regulatory stances, or major technological developments. We hope HODL Simulator offers a nuanced perspective on Bitcoin’s evolution, helping you refine your projections and cultivate a deeper understanding of the market’s potential.
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
