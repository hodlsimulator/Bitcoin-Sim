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
HODL Simulator is a forward-looking modelling tool for anyone seeking to understand Bitcoin’s potential price paths over the next 20 years. By weaving together historical BTC returns, market volatility, and a wide array of bullish and bearish factors, it provides a comprehensive picture of how Bitcoin’s future might unfold.
""")
                
                // HOW IT WORKS
                Text("How It Works")
                    .font(.title2)
                    .bold()
                Text("""
1. **Historical Data Foundation**  
   We use real BTC weekly returns as a baseline, sampling them at random to preserve market realism. Over 1,040 weeks (~20 years), the simulator adjusts these returns with your chosen settings.  

2. **Lognormal Price Model & Standard Deviation**  
   The simulator now uses a lognormal approach to capture *multiplicative* changes in price. This means returns are modelled in log-space rather than additively, allowing more realistic growth paths (and avoiding instant wipeouts). We’ve also added a separate standard deviation setting for finer control over volatility.  

3. **Bullish and Bearish Factors**  
   Each factor represents a plausible event—think new institutional demand or macroeconomic turmoil. Toggle these factors on or off to see how events might stack up over time.

4. **Monte Carlo Simulation**  
   Instead of producing one deterministic path, HODL Simulator runs many randomised trials. This paints a distribution of possible outcomes.

5. **Portfolio Evolution**  
   You can configure personal contributions, initial balances, and cost bases. Each simulation tracks your hypothetical BTC holdings, adjusted weekly by performance and contributions.

6. **Week-by-Week Median**  
   After all runs complete, the app computes a *median line*—a midpoint at each week—so you can see the “middle ground” compared to the many individual paths.
""")

                // EXTREME PRICE SCENARIOS
                Text("Extreme Price Scenarios")
                    .font(.title2)
                    .bold()
                Text("""
Because some factors can be dialled up quite high, HODL Simulator supports extraordinarily large BTC prices. Behind the scenes, we store these prices in Decimal form to avoid precision loss, and the y-axis may include expanded suffixes for extremely large numbers. If you push every bullish factor to the max, the simulator can still handle it!
""")

                // THE CHART
                Text("Visualising the Future")
                    .font(.title2)
                    .bold()
                Text("""
The simulator’s chart displays each run on a **log-scale** y-axis, reflecting the multiplicative nature of BTC’s price moves. The orange line indicates the median BTC price at every week, revealing a single “most typical” reference curve. This approach makes it straightforward to grasp just how varied Bitcoin’s trajectory could be, from moderate growth to explosive rallies or marked downturns.
""")

                // SETTINGS & TOGGLES
                Text("Settings & Toggles")
                    .font(.title2)
                    .bold()
                Text("""
- **Toggle All**: Flip all bullish and bearish factors on or off for fully bear or bull scenarios.  
- **Annual CAGR & Volatility**: Adjust the broader growth rate and price swings to align with your outlook.  
- **Lognormal & Std Dev**: Fine-tune how aggressively or gently prices fluctuate.  
- **Random Seed**: Lock the seed for reproducible runs, or leave it random for fresh outcomes.
""")

                // WHO ITS FOR
                Text("Who Is It For?")
                    .font(.title2)
                    .bold()
                Text("""
HODL Simulator is ideal for anyone curious about long-term Bitcoin scenarios. If you’re interested in how supply shocks, market psychology, and global economic conditions might affect Bitcoin’s journey, this tool can help you test your theories in a structured, scenario-based environment.
""")

                // CLOSING
                Text("""
By configuring different assumptions, you can see how dramatically Bitcoin’s outlook could shift with changes in demand, regulation, or major technological developments. We hope HODL Simulator offers a nuanced perspective on Bitcoin’s evolution, helping you refine your projections and deepen your understanding of the market’s potential.
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
