//
//  BearishFactorsSection.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import SwiftUI

struct BearishFactorsSection: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    // Currently active tooltip factor
    @Binding var activeFactor: String?
    
    // For tooltips on title tap
    let toggleFactor: (String) -> Void
    
    // Fraction toggles (just for slider intensity)
    @Binding var factorEnableFrac: [String: Double]
    
    // A closure for your optional on/off animation
    let animateFactor: (String, Bool) -> Void
    
    var body: some View {
        Section("Bearish Factors") {
            
            // REGULATORY CLAMPDOWN
            FactorToggleRow(
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useRegClampdownWeekly
                    },
                    set: { newValue in
                        simSettings.useRegClampdownWeekly  = newValue
                        simSettings.useRegClampdownMonthly = newValue
                        
                        factorEnableFrac["RegClampdown"] = newValue
                            ? (factorEnableFrac["RegClampdown"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("RegClampdown", newValue)
                    }
                ),
                sliderValue: $simSettings.maxClampDownUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0014273392243542672 ... -0.0008449512243542672
                    : -0.023 ... -0.017,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0011361452243542672
                    : -0.02,
                parameterDescription: """
                    Strict government bans/regulations can curb adoption and reduce demand.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // COMPETITOR COIN
            FactorToggleRow(
                iconName: "bitcoinsign.circle",
                title: "Competitor Coin",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useCompetitorCoinWeekly
                    },
                    set: { newValue in
                        simSettings.useCompetitorCoinWeekly  = newValue
                        simSettings.useCompetitorCoinMonthly = newValue
                        
                        factorEnableFrac["CompetitorCoin"] = newValue
                            ? (factorEnableFrac["CompetitorCoin"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("CompetitorCoin", newValue)
                    }
                ),
                sliderValue: $simSettings.maxCompetitorBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0011842141746411323 ... -0.0008454221746411323
                    : -0.0092 ... -0.0068,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010148181746411323
                    : -0.008,
                parameterDescription: """
                    A rival crypto with better tech or speed may siphon market share from BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // SECURITY BREACH
            FactorToggleRow(
                iconName: "lock.shield",
                title: "Security Breach",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useSecurityBreachWeekly
                    },
                    set: { newValue in
                        simSettings.useSecurityBreachWeekly  = newValue
                        simSettings.useSecurityBreachMonthly = newValue
                        
                        factorEnableFrac["SecurityBreach"] = newValue
                            ? (factorEnableFrac["SecurityBreach"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("SecurityBreach", newValue)
                    }
                ),
                sliderValue: $simSettings.breachImpactUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0012819675168380737 ... -0.0009009755168380737
                    : -0.00805 ... -0.00595,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010914715168380737
                    : -0.007,
                parameterDescription: """
                    Major hacks or protocol exploits can damage confidence and spark selloffs.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // BUBBLE POP
            FactorToggleRow(
                iconName: "bubble.left.and.bubble.right.fill",
                title: "Bubble Pop",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useBubblePopWeekly
                    },
                    set: { newValue in
                        simSettings.useBubblePopWeekly  = newValue
                        simSettings.useBubblePopMonthly = newValue
                        
                        factorEnableFrac["BubblePop"] = newValue
                            ? (factorEnableFrac["BubblePop"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("BubblePop", newValue)
                    }
                ),
                sliderValue: $simSettings.maxPopDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.002244817890762329 ... -0.001280529890762329
                    : -0.0115 ... -0.0085,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.001762673890762329
                    : -0.01,
                parameterDescription: """
                    Speculative manias can end abruptly, causing prices to crash.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // STABLECOIN MELTDOWN
            FactorToggleRow(
                iconName: "exclamationmark.triangle.fill",
                title: "Stablecoin Meltdown",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useStablecoinMeltdownWeekly
                    },
                    set: { newValue in
                        simSettings.useStablecoinMeltdownWeekly  = newValue
                        simSettings.useStablecoinMeltdownMonthly = newValue
                        
                        factorEnableFrac["StablecoinMeltdown"] = newValue
                            ? (factorEnableFrac["StablecoinMeltdown"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("StablecoinMeltdown", newValue)
                    }
                ),
                sliderValue: $simSettings.maxMeltdownDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0009681346159477233 ... -0.0004600706159477233
                    : -0.013 ... -0.007,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0007141026159477233
                    : -0.01,
                parameterDescription: """
                    If major stablecoins collapse or de-peg, confidence can erode across all crypto, including BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // BLACK SWAN EVENTS
            FactorToggleRow(
                iconName: "tornado",
                title: "Black Swan Events",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useBlackSwanWeekly
                    },
                    set: { newValue in
                        simSettings.useBlackSwanWeekly  = newValue
                        simSettings.useBlackSwanMonthly = newValue
                        
                        factorEnableFrac["BlackSwan"] = newValue
                            ? (factorEnableFrac["BlackSwan"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("BlackSwan", newValue)
                    }
                ),
                sliderValue: $simSettings.blackSwanDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.478662 ... -0.319108
                    : -0.48 ... -0.32,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.398885
                    : -0.4,
                parameterDescription: """
                    Extreme, unforeseen disasters or wars can slam all markets, including BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // BEAR MARKET CONDITIONS
            FactorToggleRow(
                iconName: "chart.bar.xaxis",
                title: "Bear Market Conditions",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useBearMarketWeekly
                    },
                    set: { newValue in
                        simSettings.useBearMarketWeekly  = newValue
                        simSettings.useBearMarketMonthly = newValue
                        
                        factorEnableFrac["BearMarket"] = newValue
                            ? (factorEnableFrac["BearMarket"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("BearMarket", newValue)
                    }
                ),
                sliderValue: $simSettings.bearWeeklyDriftUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0010278802752494812 ... -0.0007278802752494812
                    : -0.013 ... -0.007,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0008778802752494812
                    : -0.01,
                parameterDescription: """
                    Prolonged negativity leads to gradual price declines and capitulation.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // DECLINING ARR / MATURING MARKET
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis",
                title: "Declining ARR / Maturing Market",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useMaturingMarketWeekly
                    },
                    set: { newValue in
                        simSettings.useMaturingMarketWeekly  = newValue
                        simSettings.useMaturingMarketMonthly = newValue
                        
                        factorEnableFrac["MaturingMarket"] = newValue
                            ? (factorEnableFrac["MaturingMarket"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("MaturingMarket", newValue)
                    }
                ),
                sliderValue: $simSettings.maxMaturingDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0020343461055486196 ... -0.0010537001055486196
                    : -0.013 ... -0.007,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0015440231055486196
                    : -0.01,
                parameterDescription: """
                    As BTC matures, growth slows, diminishing speculative returns over time.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // RECESSION / MACRO CRASH
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis.circle.fill",
                title: "Recession / Macro Crash",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useRecessionWeekly
                    },
                    set: { newValue in
                        simSettings.useRecessionWeekly  = newValue
                        simSettings.useRecessionMonthly = newValue
                        
                        factorEnableFrac["Recession"] = newValue
                            ? (factorEnableFrac["Recession"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("Recession", newValue)
                    }
                ),
                sliderValue: $simSettings.maxRecessionDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0010516462467487811 ... -0.0007494520467487811
                    : -0.0015958890 ... -0.0013057270,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0009005491467487811
                    : -0.0014508080482482913,
                parameterDescription: """
                    A broader economic downturn reduces risk appetite, pulling capital from BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
        }
        .listRowBackground(Color(white: 0.15))
    }
}
