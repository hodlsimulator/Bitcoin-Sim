//
//  TipsData.swift
//  BTCMonteCarlo
//
//  Created by . . on 08/01/2025.
//

import Foundation

struct TipsData {
    static let loadingTips: [String] = [
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
        "Tinkering with code knobs for final outputs…"
    ]
    
    static let usageTips: [String] = [
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
        "Tip: Turn all factors off for a plain baseline simulation."
    ]
    
    // Filter out tips referencing factors that are turned OFF
    static func filteredLoadingTips(for settings: SimulationSettings) -> [String] {
        var tips = loadingTips
        
        // (1) stablecoin meltdown references if it's OFF
            if !settings.useStablecoinMeltdown {
                tips.removeAll { tip in
                    tip.lowercased().contains("stablecoin meltdown") ||
                    tip.lowercased().contains("tether collapse")
                }
            } else {
                // (1B) If meltdown is ON, remove “turn on stablecoin meltdown” references
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
        // (6) country adoption references if it's OFF
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
                tip.lowercased().contains("competitor coins")
            }
        }
        // (8) security breach references
        if !settings.useSecurityBreach {
            tips.removeAll { tip in
                tip.lowercased().contains("security breach") ||
                tip.lowercased().contains("hacking scare")
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
                tip.lowercased().contains("scarcity")
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
                tip.lowercased().contains("bear market")
            }
        }
        // (16) adoption factor references
        if !settings.useAdoptionFactor && !settings.useDemographicAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("adoption")
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
                tip.lowercased().contains("randomising risk parameters")
            }
        }
        // (20) demographic adoption references
        if !settings.useDemographicAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("generational adoption")
            }
        }
        // (21) historical sampling references
        if !settings.useHistoricalSampling {
            tips.removeAll { tip in
                tip.lowercased().contains("gathering btc historical returns") ||
                tip.lowercased().contains("reviewing historic btc performance data")
            }
        }
        
        return tips
    }
    
    static func filteredUsageTips(for settings: SimulationSettings) -> [String] {
        var tips = usageTips
        
        // (1) stablecoin meltdown references if it's OFF
            if !settings.useStablecoinMeltdown {
                tips.removeAll { tip in
                    tip.lowercased().contains("stablecoin meltdown") ||
                    tip.lowercased().contains("tether collapse")
                }
            } else {
                // (1B) If meltdown is ON, remove “turn on stablecoin meltdown” references
                tips.removeAll { tip in
                    tip.lowercased().contains("test tether collapse by enabling")
                }
            }
        // (2) stablecoin shift references
        if !settings.useStablecoinShift {
            tips.removeAll { tip in
                tip.lowercased().contains("stablecoin shift")
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
                tip.lowercased().contains("bubble pop")
            }
        }
        // (5) black swan references
        if !settings.useBlackSwan {
            tips.removeAll { tip in
                tip.lowercased().contains("black swan")
            }
        }
        // (6) country adoption references if it's OFF
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
                tip.lowercased().contains("hacking scare")
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
                tip.lowercased().contains("bear market")
            }
        }
        // (16) adoption factor references
        if !settings.useAdoptionFactor && !settings.useDemographicAdoption {
            tips.removeAll { tip in
                tip.lowercased().contains("adoption")
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
        // (19) vol shocks references (optional)
        if !settings.useVolShocks {
            tips.removeAll { tip in
                tip.lowercased().contains("volatility")
            }
        }
        // (20) same idea if needed for demographic adoption
        // e.g. remove tips referencing generational shifts, if they exist in usage tips
        
        return tips
    }
}
