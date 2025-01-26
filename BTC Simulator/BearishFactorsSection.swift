//
//  BearishFactorsSection.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import SwiftUI

struct BearishFactorsSection: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    // Pass in the currently active tooltip factor
    @Binding var activeFactor: String?
    
    // Pass in a function to toggle the tooltip
    let toggleFactor: (String) -> Void
    
    var body: some View {
        Section("Bearish Factors") {
            
            // REGULATORY CLAMPDOWN
            FactorToggleRow(
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                isOn: $simSettings.useRegClampdownUnified,
                sliderValue: $simSettings.maxClampDownUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0014273392243542672 ... -0.0008449512243542672     // ~1/5 original weekly
                    : -0.023 ... -0.017                                      // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useCompetitorCoinUnified,
                sliderValue: $simSettings.maxCompetitorBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0011842141746411323 ... -0.0008454221746411323    // ~1/5 original weekly
                    : -0.0092 ... -0.0068                                  // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useSecurityBreachUnified,
                sliderValue: $simSettings.breachImpactUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0012819675168380737 ... -0.0009009755168380737    // ~1/5 original weekly
                    : -0.00805 ... -0.00595                                // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useBubblePopUnified,
                sliderValue: $simSettings.maxPopDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.002244817890762329 ... -0.001280529890762329   // ~1/5 original weekly
                    : -0.0115 ... -0.0085                               // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useStablecoinMeltdownUnified,
                sliderValue: $simSettings.maxMeltdownDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0009681346159477233 ... -0.0004600706159477233  // ~1/5 original weekly
                    : -0.013 ... -0.007                                 // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useBlackSwanUnified,
                sliderValue: $simSettings.blackSwanDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.478662 ... -0.319108   // ~1/5 original weekly
                    : -0.48 ... -0.32          // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useBearMarketUnified,
                sliderValue: $simSettings.bearWeeklyDriftUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0010278802752494812 ... -0.0007278802752494812  // ~1/5 original weekly
                    : -0.013 ... -0.007                                  // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useMaturingMarketUnified,
                sliderValue: $simSettings.maxMaturingDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0020343461055486196 ... -0.0010537001055486196   // ~1/5 original weekly
                    : -0.013 ... -0.007                                  // ~1/5 original monthly
                ,
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
                isOn: $simSettings.useRecessionUnified,
                sliderValue: $simSettings.maxRecessionDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0010516462467487811 ... -0.0007494520467487811  // ~1/5 original weekly
                    : -0.0015958890 ... -0.0013057270                    // ~1/5 original monthly
                ,
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
