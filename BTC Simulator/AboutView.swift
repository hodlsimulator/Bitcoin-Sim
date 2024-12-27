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
                Text("About BTC Monte Carlo")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)

                // OVERVIEW
                Text("Overview")
                    .font(.title2)
                    .bold()
                Text("""
This app simulates Bitcoin price growth (or decline) across many hypothetical futures. It uses a weekly random draw from historical BTC returns, then applies a series of “bullish” or “bearish” factors (like Halving, Tech Breakthrough, Recession, etc.) over a timeline of 1,040 weeks (~20 years). By running many such simulations (Monte Carlo), you get a range of outcomes and can see a possible median path.
""")

                // CODE INSIGHTS
                Text("How It Works Under the Hood")
                    .font(.title2)
                    .bold()
                Text("""
We rely on a file called MonteCarloSimulator.swift, which handles the core simulation logic. It pulls historical weekly returns from CSVs (not included here), picks random entries, and “dampens” extreme outliers using an arctan function. On top of that, it systematically checks whether each factor (bullish or bearish) is enabled in Settings and adjusts the weekly return accordingly.

For example, a “Halving” event might add a positive bump at weeks 210, 420, 630, and 840, whereas a “Regulatory Clampdown” might subtract a certain amount during weeks 200–220. When running the simulation, if a factor is toggled on, the code gradually adds or subtracts its effect over its time window. Some events, like a “Security Breach,” happen once at a specific week, while others (e.g. “Bear Market Conditions”) subtract every week during that window.
""")

                // RANDOM SEED SECTION
                Text("Random Seed Logic")
                    .font(.title2)
                    .bold()
                Text("""
By default, each run can be entirely random—meaning each new simulation might produce a different final outcome. The code includes a “lock random seed” feature, so you can fix the underlying random number generator (RNG) at a specific seed. This ensures every run, with the same factors, returns identical results. This is super handy if you want to isolate exactly how one factor changes the outcome without random fluctuations each time.

The simulator calls setRandomSeed(...) at the start of a run. If a seed is provided, it creates a custom SeededGenerator that repeats the same random draws. If the seed is nil, it uses Swift’s default random generator for fresh results every time.
""")

                // STEP-BY-STEP EXPLANATION
                Text("Step-by-Step Simulation")
                    .font(.title2)
                    .bold()
                Text("""
1. **Initial Data**: The simulator starts from some hard-coded or previously recorded “weeks 1..7” data, so that you can see continuity from an existing scenario.
2. **Weekly Loop**: From week 8 up to 1,040 (about 20 years), we:
   • Pick a random weekly return from historical data (with optional damping).
   • Add or subtract factor-based bumps (Bullish or Bearish).
   • Update the BTC price accordingly.
3. **Contributions & Withdrawals**: Each week, the user “contributes” some EUR to buy BTC (minus a small fee). If the portfolio grows large, we may withdraw EUR. 
4. **Final Results**: After all iterations, the simulator collects every “run” (e.g. 100 or 1,000 runs), sorts them by final portfolio value, and picks a median run to display. That helps you get a sense of the “middle” scenario.
""")

                // SETTINGS PAGE
                Text("Settings & Factors")
                    .font(.title2)
                    .bold()
                Text("""
The Settings page lists all bullish and bearish factors. Each has a slider controlling how strong the effect is and a toggle to enable/disable it. For instance, “Scarcity Events” can add up to a 0.025 return boost, ramping up between weeks 700–1040, while “Recession” might subtract -0.004 between weeks 250–400. Tweak these factors to reflect your personal macro assumptions.
""")

                // LOCK RANDOM SEED DETAILS
                Text("Lock Random Seed")
                    .font(.title2)
                    .bold()
                Text("""
Turn on “Lock Random Seed” if you want consistent randomness. When locked, the app sets a fixed seed number in the simulator, producing the same random weekly picks every run. That way, you can systematically compare “Halving On vs. Off” or “Regulatory Clarity On vs. Off” without worrying that random variation skewed the results.
""")

                // WRAP-UP
                Text("Enjoy Experimenting!")
                    .font(.title2)
                    .bold()
                Text("""
Ultimately, BTC Monte Carlo is a toy that helps you visualise scenarios, but it’s not a guarantee of future performance. Real markets are complex, and each factor is purely hypothetical! Still, it’s fun to experiment with toggles, see hypothetical long-term outcomes, and get a feel for how drastically the future can vary.
""")
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
        .background(Color(white: 0.12).ignoresSafeArea())
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        // Default SwiftUI back button keeps your custom nav styling
    }
}
