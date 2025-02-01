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
    
    // 0..1 fractions (or 0 for off), used by the tilt bar
    @Binding var factorEnableFrac: [String: Double]
    
    // For optional on/off animation/log
    let animateFactor: (String, Bool) -> Void
    
    var body: some View {
        Section("Bearish Factors") {
            
            // MARK: - REGULATORY CLAMPDOWN
            FactorToggleRow(
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                isOn: Binding<Bool>(
                    get: { simSettings.useRegClampdownWeekly },
                    set: { newValue in
                        simSettings.useRegClampdownWeekly = newValue
                        simSettings.useRegClampdownMonthly = newValue
                        
                        if newValue {
                            // Recalculate fraction from the current numeric
                            let frac = simSettings.fractionFromValue(
                                "RegClampdown",
                                value: simSettings.maxClampDownUnified,
                                isWeekly: simSettings.periodUnit == .weeks
                            )
                            factorEnableFrac["RegClampdown"] = frac
                        } else {
                            factorEnableFrac["RegClampdown"] = 0.0
                        }
                        animateFactor("RegClampdown", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxClampDownUnified },
                    set: { newVal in
                        simSettings.maxClampDownUnified = newVal
                        if simSettings.useRegClampdownWeekly {
                            let frac = simSettings.fractionFromValue(
                                "RegClampdown",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["RegClampdown"] = frac
                        } else {
                            factorEnableFrac["RegClampdown"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - COMPETITOR COIN
            FactorToggleRow(
                iconName: "bitcoinsign.circle",
                title: "Competitor Coin",
                isOn: Binding<Bool>(
                    get: { simSettings.useCompetitorCoinWeekly },
                    set: { newValue in
                        simSettings.useCompetitorCoinWeekly = newValue
                        simSettings.useCompetitorCoinMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "CompetitorCoin",
                                value: simSettings.maxCompetitorBoostUnified,
                                isWeekly: simSettings.periodUnit == .weeks
                            )
                            factorEnableFrac["CompetitorCoin"] = frac
                        } else {
                            factorEnableFrac["CompetitorCoin"] = 0.0
                        }
                        animateFactor("CompetitorCoin", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxCompetitorBoostUnified },
                    set: { newVal in
                        simSettings.maxCompetitorBoostUnified = newVal
                        if simSettings.useCompetitorCoinWeekly {
                            let frac = simSettings.fractionFromValue(
                                "CompetitorCoin",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["CompetitorCoin"] = frac
                        } else {
                            factorEnableFrac["CompetitorCoin"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - SECURITY BREACH
            FactorToggleRow(
                iconName: "lock.shield",
                title: "Security Breach",
                isOn: Binding<Bool>(
                    get: { simSettings.useSecurityBreachWeekly },
                    set: { newValue in
                        simSettings.useSecurityBreachWeekly = newValue
                        simSettings.useSecurityBreachMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "SecurityBreach",
                                value: simSettings.breachImpactUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["SecurityBreach"] = frac
                        } else {
                            factorEnableFrac["SecurityBreach"] = 0.0
                        }
                        animateFactor("SecurityBreach", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.breachImpactUnified },
                    set: { newVal in
                        simSettings.breachImpactUnified = newVal
                        if simSettings.useSecurityBreachWeekly {
                            let frac = simSettings.fractionFromValue(
                                "SecurityBreach",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["SecurityBreach"] = frac
                        } else {
                            factorEnableFrac["SecurityBreach"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - BUBBLE POP
            FactorToggleRow(
                iconName: "bubble.left.and.bubble.right.fill",
                title: "Bubble Pop",
                isOn: Binding<Bool>(
                    get: { simSettings.useBubblePopWeekly },
                    set: { newValue in
                        simSettings.useBubblePopWeekly = newValue
                        simSettings.useBubblePopMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "BubblePop",
                                value: simSettings.maxPopDropUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["BubblePop"] = frac
                        } else {
                            factorEnableFrac["BubblePop"] = 0.0
                        }
                        animateFactor("BubblePop", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxPopDropUnified },
                    set: { newVal in
                        simSettings.maxPopDropUnified = newVal
                        if simSettings.useBubblePopWeekly {
                            let frac = simSettings.fractionFromValue(
                                "BubblePop",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["BubblePop"] = frac
                        } else {
                            factorEnableFrac["BubblePop"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - STABLECOIN MELTDOWN
            FactorToggleRow(
                iconName: "exclamationmark.triangle.fill",
                title: "Stablecoin Meltdown",
                isOn: Binding<Bool>(
                    get: { simSettings.useStablecoinMeltdownWeekly },
                    set: { newValue in
                        simSettings.useStablecoinMeltdownWeekly = newValue
                        simSettings.useStablecoinMeltdownMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "StablecoinMeltdown",
                                value: simSettings.maxMeltdownDropUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["StablecoinMeltdown"] = frac
                        } else {
                            factorEnableFrac["StablecoinMeltdown"] = 0.0
                        }
                        animateFactor("StablecoinMeltdown", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxMeltdownDropUnified },
                    set: { newVal in
                        simSettings.maxMeltdownDropUnified = newVal
                        if simSettings.useStablecoinMeltdownWeekly {
                            let frac = simSettings.fractionFromValue(
                                "StablecoinMeltdown",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["StablecoinMeltdown"] = frac
                        } else {
                            factorEnableFrac["StablecoinMeltdown"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - BLACK SWAN EVENTS
            FactorToggleRow(
                iconName: "tornado",
                title: "Black Swan Events",
                isOn: Binding<Bool>(
                    get: { simSettings.useBlackSwanWeekly },
                    set: { newValue in
                        simSettings.useBlackSwanWeekly = newValue
                        simSettings.useBlackSwanMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "BlackSwan",
                                value: simSettings.blackSwanDropUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["BlackSwan"] = frac
                        } else {
                            factorEnableFrac["BlackSwan"] = 0.0
                        }
                        animateFactor("BlackSwan", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.blackSwanDropUnified },
                    set: { newVal in
                        simSettings.blackSwanDropUnified = newVal
                        if simSettings.useBlackSwanWeekly {
                            let frac = simSettings.fractionFromValue(
                                "BlackSwan",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["BlackSwan"] = frac
                        } else {
                            factorEnableFrac["BlackSwan"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - BEAR MARKET CONDITIONS
            FactorToggleRow(
                iconName: "chart.bar.xaxis",
                title: "Bear Market Conditions",
                isOn: Binding<Bool>(
                    get: { simSettings.useBearMarketWeekly },
                    set: { newValue in
                        simSettings.useBearMarketWeekly = newValue
                        simSettings.useBearMarketMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "BearMarket",
                                value: simSettings.bearWeeklyDriftUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["BearMarket"] = frac
                        } else {
                            factorEnableFrac["BearMarket"] = 0.0
                        }
                        animateFactor("BearMarket", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.bearWeeklyDriftUnified },
                    set: { newVal in
                        simSettings.bearWeeklyDriftUnified = newVal
                        if simSettings.useBearMarketWeekly {
                            let frac = simSettings.fractionFromValue(
                                "BearMarket",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["BearMarket"] = frac
                        } else {
                            factorEnableFrac["BearMarket"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - DECLINING ARR / MATURING MARKET
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis",
                title: "Declining ARR / Maturing Market",
                isOn: Binding<Bool>(
                    get: { simSettings.useMaturingMarketWeekly },
                    set: { newValue in
                        simSettings.useMaturingMarketWeekly = newValue
                        simSettings.useMaturingMarketMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "MaturingMarket",
                                value: simSettings.maxMaturingDropUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["MaturingMarket"] = frac
                        } else {
                            factorEnableFrac["MaturingMarket"] = 0.0
                        }
                        animateFactor("MaturingMarket", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxMaturingDropUnified },
                    set: { newVal in
                        simSettings.maxMaturingDropUnified = newVal
                        if simSettings.useMaturingMarketWeekly {
                            let frac = simSettings.fractionFromValue(
                                "MaturingMarket",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["MaturingMarket"] = frac
                        } else {
                            factorEnableFrac["MaturingMarket"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - RECESSION / MACRO CRASH
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis.circle.fill",
                title: "Recession / Macro Crash",
                isOn: Binding<Bool>(
                    get: { simSettings.useRecessionWeekly },
                    set: { newValue in
                        simSettings.useRecessionWeekly = newValue
                        simSettings.useRecessionMonthly = newValue
                        
                        if newValue {
                            let frac = simSettings.fractionFromValue(
                                "Recession",
                                value: simSettings.maxRecessionDropUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["Recession"] = frac
                        } else {
                            factorEnableFrac["Recession"] = 0.0
                        }
                        animateFactor("Recession", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxRecessionDropUnified },
                    set: { newVal in
                        simSettings.maxRecessionDropUnified = newVal
                        if simSettings.useRecessionWeekly {
                            let frac = simSettings.fractionFromValue(
                                "Recession",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
                            )
                            factorEnableFrac["Recession"] = frac
                        } else {
                            factorEnableFrac["Recession"] = 0.0
                        }
                    }
                ),
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
