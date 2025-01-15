//
//  TipsData.swift
//  BTCMonteCarlo
//
//  Created by . . on 08/01/2025.
//

import Foundation

struct TipsData {
    // ~32 original, now +32 more => ~64 total
    static let loadingTips: [String] = [
        // Original 32:
        "Gathering BTC historical returns…",
        "Spinning up random seeds for each run…",
        "Factoring in future halving events…",
        "Accounting for bullish and bearish signals…",
        "Checking correlation with the S&P 500…",
        "Cranking through thousands of Monte Carlo iterations…",
        "Assessing bubble risk from speculative mania…",
        "Observing generational adoption shifts…",
        "Monitoring sudden volatility changes…",
        "Randomising risk parameters…",
        "Reading user inputs for CAGR & price swings…",
        "Weighing institutional demand probabilities…",
        "Waiting to see if whales move coins around…",
        "Analysing competitor coins’ impact…",
        "Simulating potential stablecoin collapses…",
        "Comparing macro market influences…",
        "Reviewing historic BTC performance data…",
        "Highlighting supply constraint factors…",
        "Estimating next-gen adoption curves…",
        "Checking short-term fear-and-greed conditions…",
        "Watching out for black swan events…",
        "Applying user settings for final run…",
        "Evaluating bubble inflation or deflation…",
        "Merging multi-year data into forecasts…",
        "Integrating possible country-level adoption surges…",
        "Filtering short-term market noise…",
        "Running stress tests for worst-case scenarios…",
        "Tuning weekly returns for consistency…",
        "Tracking stablecoin inflows and outflows…",
        "Mining raw data for hidden signals…",
        "Boosting calculation speeds…",
        "Tinkering with code knobs for final outputs…",
        
        // New ~32:
        "Cashing in big gains from institutional FOMO…",
        "Staying watchful for forks or chain splits…",
        "Checking if Tether might depeg at any moment…",
        "Fuelled by rumours of upcoming ETF approvals…",
        "Preparing a table of final results…",
        "Cross-referencing LTC correlation metrics…",
        "Evaluating user’s monthly vs. weekly preference…",
        "Sweeping out backtest data for a fresh slate…",
        "Factoring in negative interest rate scenarios…",
        "Comparing the current hype cycle to 2017…",
        "Watching sentiment from major media outlets…",
        "Building sub-simulations with or without halving…",
        "Projecting if a competitor coin can overshadow BTC…",
        "Enabling or disabling stablecoin meltdown triggers…",
        "Inspecting maturing market conditions for slower growth…",
        "Crunching possibilities if a recession strikes…",
        "Accounting for LTC bull runs (though not guaranteed)…",
        "Measuring demographic switchover effect…",
        "Adding a dash of volatility spike…",
        "Observing local currency exchange rates…",
        "Substituting stablecoin shift with direct fiat inflows…",
        "Examining altcoin flight as capital rotates back to BTC…",
        "Testing multiple black swan triggers in one run…",
        "Scouring past data for hidden anomalies…",
        "Ingesting user’s threshold-based withdrawal criteria…",
        "Evaluating meltdown risk if stablecoins freeze redemptions…",
        "Reading simulation toggles for the next iteration…",
        "Simulating multi-year bull/bear cycles…",
        "Applying advanced arctan dampening…",
        "Pinning final distribution to the results table…",
        "Bracing for unexpected margin calls…",
        "Quietly crossing fingers for a good outcome…"
    ]
    
    // ~32 original, now +32 more => ~64 total
    static let usageTips: [String] = [
        // Original 32:
        "Tip: Drag the 3D spinner to adjust its speed. Give it a fling!",
        "Tip: Double-tap the spinner to flip its rotation direction.",
        "Tip: Scroll sideways in the results table to reveal extra columns.",
        "Tip: Lock the seed in Settings for repeatable outcomes.",
        "Tip: See ‘About’ for a peek at the simulation’s logic.",
        "Tip: Toggle bullish or bearish factors to match your market outlook.",
        "Tip: Raise annual CAGR to imagine a more optimistic scenario.",
        "Tip: Lower volatility for milder price swings in your results.",
        "Tip: Swipe left or right on the table to see hidden data columns.",
        "Tip: Unlock the seed to get a fresh random run each time.",
        "Tip: Slow the BTC spinner by dragging in the opposite direction.",
        "Tip: Test Tether collapse by enabling the ‘Stablecoin Meltdown’ factor.",
        "Tip: Press the back arrow any time to update parameters mid-sim.",
        "Tip: Tap factor titles in Settings for a quick explanation bubble.",
        "Tip: ‘Maturing Market’ dials down growth in later phases.",
        "Tip: ‘Bubble Pop’ adds a risk of sudden crash after a big rally.",
        "Tip: Screenshot your results to share or compare runs later on.",
        "Tip: Halving usually occurs every 210k blocks (~4 years).",
        "Tip: Want an El Salvador moment? Turn on ‘Country Adoption’.",
        "Tip: ‘Global Macro Hedge’ sees BTC as ‘digital gold’ in market crises.",
        "Tip: Reset your inputs any time to try different configurations.",
        "Tip: ‘About’ explains how each factor influences your outcomes.",
        "Tip: Use fewer or more iterations to see stable vs. scattered results.",
        "Tip: ‘Scarcity Events’ can cause supply-driven price leaps.",
        "Tip: Experiment with multiple runs to compare different scenarios.",
        "Tip: Flip your device sideways for a wider table layout.",
        "Tip: The ‘Security Breach’ factor simulates big hacking scares.",
        "Tip: ‘Bear Market’ simulates a slow, ongoing price decline.",
        "Tip: The spinner is purely for fun—spin or poke it freely!",
        "Tip: Keep your real BTC safe—this is just a simulator.",
        "Tip: Mix bullish and bearish toggles to mirror the market you expect.",
        "Tip: Turn all factors off for a plain baseline simulation.",
        
        // New ~32:
        "Tip: Triple-tap the spinner to pause its rotation entirely.",
        "Tip: Swipe quickly on the results table to skip 10 rows at a time.",
        "Tip: Increase threshold 2 for fewer partial cash-outs.",
        "Tip: For an extreme bull scenario, turn on every bullish factor at once.",
        "Tip: Switch from monthly to weekly for finer detail in your forecasts.",
        "Tip: Want random madness? Unlock the seed each run.",
        "Tip: If you suspect USDC concerns, try ‘Stablecoin Meltdown’.",
        "Tip: Reg clampdowns can be tested by turning that factor on and off.",
        "Tip: Combine meltdown + shift toggles for stablecoin drama.",
        "Tip: ‘Maturing Market’ can make BTC behave like a large-cap stock.",
        "Tip: ‘Bear Market’ toggle can replicate 2018’s drawdowns.",
        "Tip: Use fewer iterations for speed, more for stable averages.",
        "Tip: Look at final results thoroughly to see how toggles combine.",
        "Tip: Zoom in on tail risk by checking the 10th percentile run.",
        "Tip: Focus on best-case scenario by examining the 90th percentile run.",
        "Tip: Flip from weekly to monthly in Settings to reduce steps.",
        "Tip: If you’re short-term, reduce user periods for fewer data rows.",
        "Tip: Press and hold the back arrow to quickly switch toggles.",
        "Tip: Halving default bump is 0.48—change it if you have another guess.",
        "Tip: If random seed is locked, you’ll see the same run each time.",
        "Tip: Consider black swan events if you fear big market shocks.",
        "Tip: Scarcity events can replicate exchange outflows or lost wallets.",
        "Tip: Bubble Pop simulates mania that suddenly disappears.",
        "Tip: Bubbles can keep rising until they violently reverse.",
        "Tip: Watch threshold-based sells in your results table.",
        "Tip: Security Breach can simulate Mt. Gox-like catastrophes.",
        "Tip: If you trust stablecoins, turn meltdown off.",
        "Tip: Recession + Bear Market = ultra-bear scenario.",
        "Tip: Tech Breakthrough might replicate Lightning expansions or Taproot.",
        "Tip: Press the gear to tweak toggles mid-sim if new ideas come up.",
        "Tip: Tap the chart to see percentile lines after each run.",
        "Tip: ‘Adoption Factor’ adds a slow, constant tailwind to BTC prices."
    ]
    
    // Filter out tips referencing factors that are turned OFF
    static func filteredLoadingTips(for settings: SimulationSettings) -> [String] {
        var tips = loadingTips
        
        // (1) stablecoin meltdown references
        if !settings.useStablecoinMeltdown {
            tips.removeAll { tip in
                tip.lowercased().contains("stablecoin meltdown") ||
                tip.lowercased().contains("tether collapse") ||
                tip.lowercased().contains("stablecoin collapses")
            }
        } else {
            // (1B) If meltdown is ON, remove “turn on stablecoin meltdown” references (if any)
            tips.removeAll { tip in
                tip.lowercased().contains("test tether collapse by enabling")
            }
        }
        
        // (2) stablecoin shift references
        if !settings.useStablecoinShift {
            tips.removeAll { tip in
                tip.lowercased().contains("stablecoin shift") ||
                tip.lowercased().contains("stablecoin inflows") ||
                tip.lowercased().contains("stablecoin collapses")
            }
        }
        
        // (3) halving references
        if !settings.useHalving {
            tips.removeAll { tip in
                tip.lowercased().contains("halving")
            }
        }
        
        // (4) bubble pop references
        if !settings.useBubblePop {
            tips.removeAll { tip in
                tip.lowercased().contains("bubble") ||
                tip.lowercased().contains("mania")
            }
        }
        
        // (5) black swan references
        if !settings.useBlackSwan {
            tips.removeAll { tip in
                tip.lowercased().contains("black swan")
            }
        }
        
        // (6) country adoption references
        if !settings.useCountryAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("country-level adoption") ||
                tip.lowercased().contains("el salvador") ||
                tip.lowercased().contains("country adoption")
            }
        } else {
            // (6B) If it's ON, remove “turn on” tips
            tips.removeAll { tip in
                tip.lowercased().contains("want an el salvador moment") ||
                tip.lowercased().contains("turn on ‘country adoption’")
            }
        }
        
        // (7) competitor coin references
        if !settings.useCompetitorCoin {
            tips.removeAll { tip in
                tip.lowercased().contains("competitor coin") ||
                tip.lowercased().contains("competitor coins")
            }
        }
        
        // (8) security breach references
        if !settings.useSecurityBreach {
            tips.removeAll { tip in
                tip.lowercased().contains("security breach") ||
                tip.lowercased().contains("hacking scare") ||
                tip.lowercased().contains("mt. gox")
            }
        }
        
        // (9) institutional demand references
        if !settings.useInstitutionalDemand {
            tips.removeAll { tip in
                tip.lowercased().contains("institutional demand") ||
                tip.lowercased().contains("fomo")
            }
        }
        
        // (10) reg clampdown references
        if !settings.useRegClampdown {
            tips.removeAll { tip in
                tip.lowercased().contains("regulatory clampdown") ||
                tip.lowercased().contains("reg clampdown")
            }
        }
        
        // (11) altcoin flight references
        if !settings.useAltcoinFlight {
            tips.removeAll { tip in
                tip.lowercased().contains("altcoin flight") ||
                tip.lowercased().contains("capital rotates back to btc")
            }
        }
        
        // (12) global macro hedge references
        if !settings.useGlobalMacroHedge {
            tips.removeAll { tip in
                tip.lowercased().contains("macro hedge")
            }
        }
        
        // (13) scarcity events references
        if !settings.useScarcityEvents {
            tips.removeAll { tip in
                tip.lowercased().contains("scarcity")
            }
        }
        
        // (14) maturing market references
        if !settings.useMaturingMarket {
            tips.removeAll { tip in
                tip.lowercased().contains("maturing market") ||
                tip.lowercased().contains("slower growth")
            }
        }
        
        // (15) bear market references
        if !settings.useBearMarket {
            tips.removeAll { tip in
                tip.lowercased().contains("bear market")
            }
        }
        
        // (16) adoption factor references
        if !settings.useAdoptionFactor && !settings.useDemographicAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("adoption") ||
                tip.lowercased().contains("generational adoption") ||
                tip.lowercased().contains("demographic switchover")
            }
        }
        
        // (17) recession references
        if !settings.useRecession {
            tips.removeAll { tip in
                tip.lowercased().contains("recession")
            }
        }
        
        // (18) random seed references
        if settings.lockedRandomSeed {
            tips.removeAll { tip in
                tip.lowercased().contains("random seed")
            }
        }
        
        // (19) vol shocks references
        if !settings.useVolShocks {
            tips.removeAll { tip in
                tip.lowercased().contains("volatility changes") ||
                tip.lowercased().contains("volatility change") ||
                tip.lowercased().contains("randomising risk parameters") ||
                tip.lowercased().contains("volatility spike")
            }
        }
        
        // (20) historical sampling references
        if !settings.useHistoricalSampling {
            tips.removeAll { tip in
                tip.lowercased().contains("gathering btc historical returns") ||
                tip.lowercased().contains("reviewing historic btc performance data") ||
                tip.lowercased().contains("past data for hidden anomalies") ||
                tip.lowercased().contains("backtest data for a fresh slate")
            }
        }
        
        // (21) regulatory clarity references
        if !settings.useRegulatoryClarity {
            tips.removeAll { tip in
                tip.lowercased().contains("regulatory clarity")
            }
        }
        
        // (22) etf approval references
        if !settings.useEtfApproval {
            tips.removeAll { tip in
                tip.lowercased().contains("etf approval") ||
                tip.lowercased().contains("etf approvals")
            }
        }
        
        // (23) tech breakthroughs references
        if !settings.useTechBreakthrough {
            tips.removeAll { tip in
                tip.lowercased().contains("tech breakthrough") ||
                tip.lowercased().contains("lightning expansions") ||
                tip.lowercased().contains("taproot")
            }
        }
        
        return tips
    }
    
    static func filteredUsageTips(for settings: SimulationSettings) -> [String] {
        var tips = usageTips
        
        // (1) stablecoin meltdown references
        if !settings.useStablecoinMeltdown {
            tips.removeAll { tip in
                tip.lowercased().contains("stablecoin meltdown") ||
                tip.lowercased().contains("tether collapse")
            }
        } else {
            // (1B) If meltdown is ON, remove “turn on meltdown” references (if any)
            tips.removeAll { tip in
                tip.lowercased().contains("test tether collapse by enabling")
            }
        }
        
        // (2) stablecoin shift references
        if !settings.useStablecoinShift {
            tips.removeAll { tip in
                tip.lowercased().contains("stablecoin shift") ||
                tip.lowercased().contains("meltdown + shift toggles")
            }
        }
        
        // (3) halving references
        if !settings.useHalving {
            tips.removeAll { tip in
                tip.lowercased().contains("halving")
            }
        }
        
        // (4) bubble pop references
        if !settings.useBubblePop {
            tips.removeAll { tip in
                tip.lowercased().contains("bubble pop") ||
                tip.lowercased().contains("bubble can keep rising") ||
                tip.lowercased().contains("mania that suddenly disappears")
            }
        }
        
        // (5) black swan references
        if !settings.useBlackSwan {
            tips.removeAll { tip in
                tip.lowercased().contains("black swan")
            }
        }
        
        // (6) country adoption references
        if !settings.useCountryAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("country adoption") ||
                tip.lowercased().contains("el salvador")
            }
        } else {
            // (6B) If it's ON, remove “turn on” tips
            tips.removeAll { tip in
                tip.lowercased().contains("want an el salvador moment") ||
                tip.lowercased().contains("turn on ‘country adoption’")
            }
        }
        
        // (7) competitor coin references
        if !settings.useCompetitorCoin {
            tips.removeAll { tip in
                tip.lowercased().contains("competitor coin")
            }
        }
        
        // (8) security breach references
        if !settings.useSecurityBreach {
            tips.removeAll { tip in
                tip.lowercased().contains("security breach") ||
                tip.lowercased().contains("hacking scare") ||
                tip.lowercased().contains("mt. gox")
            }
        }
        
        // (9) institutional demand references
        if !settings.useInstitutionalDemand {
            tips.removeAll { tip in
                tip.lowercased().contains("institutional demand")
            }
        }
        
        // (10) reg clampdown references
        if !settings.useRegClampdown {
            tips.removeAll { tip in
                tip.lowercased().contains("reg clampdown") ||
                tip.lowercased().contains("regulatory clampdown")
            }
        }
        
        // (11) altcoin flight references
        if !settings.useAltcoinFlight {
            tips.removeAll { tip in
                tip.lowercased().contains("altcoin flight")
            }
        }
        
        // (12) global macro hedge references
        if !settings.useGlobalMacroHedge {
            tips.removeAll { tip in
                tip.lowercased().contains("macro hedge")
            }
        }
        
        // (13) scarcity events references
        if !settings.useScarcityEvents {
            tips.removeAll { tip in
                tip.lowercased().contains("scarcity event")
            }
        }
        
        // (14) maturing market references
        if !settings.useMaturingMarket {
            tips.removeAll { tip in
                tip.lowercased().contains("maturing market")
            }
        }
        
        // (15) bear market references
        if !settings.useBearMarket {
            tips.removeAll { tip in
                tip.lowercased().contains("bear market") ||
                tip.lowercased().contains("2018’s drawdowns")
            }
        }
        
        // (16) adoption factor references
        if !settings.useAdoptionFactor && !settings.useDemographicAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("adoption factor") ||
                tip.lowercased().contains("demographic switchover") ||
                tip.lowercased().contains("adoption")  // covers references to 'adoption' generally
            }
        }
        
        // (17) recession references
        if !settings.useRecession {
            tips.removeAll { tip in
                tip.lowercased().contains("recession")
            }
        }
        
        // (18) random seed references
        if settings.lockedRandomSeed {
            tips.removeAll { tip in
                tip.lowercased().contains("random seed") ||
                tip.lowercased().contains("unlock the seed each run")
            }
        }
        
        // (19) vol shocks references
        if !settings.useVolShocks {
            tips.removeAll { tip in
                tip.lowercased().contains("volatility")
            }
        }
        
        // (20) if needed, remove historical references here (not shown, but you could do similar):
        // e.g. if !settings.useHistoricalSampling { ... }
        
        // (21) regulatory clarity references
        if !settings.useRegulatoryClarity {
            tips.removeAll { tip in
                tip.lowercased().contains("regulatory clarity")
            }
        }
        
        // (22) etf approval references
        if !settings.useEtfApproval {
            tips.removeAll { tip in
                tip.lowercased().contains("etf approval") ||
                tip.lowercased().contains("etf approvals")
            }
        }
        
        // (23) tech breakthroughs references
        if !settings.useTechBreakthrough {
            tips.removeAll { tip in
                tip.lowercased().contains("tech breakthrough") ||
                tip.lowercased().contains("lightning expansions") ||
                tip.lowercased().contains("taproot")
            }
        }
        
        return tips
    }
}
