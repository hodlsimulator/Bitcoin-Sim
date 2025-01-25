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
            
            FactorToggleRow(
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                isOn: $simSettings.useRegClampdownUnified,
                sliderValue: $simSettings.maxClampDownUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0025921152243542672 ... 0.0003198247756457328
                    : -0.035 ... -0.005,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0011361452243542672
                    : -0.02,
                parameterDescription: """
                    Strict government bans/regulations can curb adoption and reduce demand.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "bitcoinsign.circle",
                title: "Competitor Coin",
                isOn: $simSettings.useCompetitorCoinUnified,
                sliderValue: $simSettings.maxCompetitorBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0018617981746411323 ... -0.0001678381746411323
                    : -0.014 ... -0.002,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010148181746411323
                    : -0.008,
                parameterDescription: """
                    A rival crypto with better tech or speed may siphon market share from BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "lock.shield",
                title: "Security Breach",
                isOn: $simSettings.useSecurityBreachUnified,
                sliderValue: $simSettings.breachImpactUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0020439515168380737 ... -0.0001389915168380737
                    : -0.01225 ... -0.00175,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010914715168380737
                    : -0.007,
                parameterDescription: """
                    Major hacks or protocol exploits can damage confidence and spark selloffs.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "bubble.left.and.bubble.right.fill",
                title: "Bubble Pop",
                isOn: $simSettings.useBubblePopUnified,
                sliderValue: $simSettings.maxPopDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.004173393890762329 ... 0.000648046109237671
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.001762673890762329
                    : -0.01,
                parameterDescription: """
                    Speculative manias can end abruptly, causing prices to crash.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "exclamationmark.triangle.fill",
                title: "Stablecoin Meltdown",
                isOn: $simSettings.useStablecoinMeltdownUnified,
                sliderValue: $simSettings.maxMeltdownDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0019842626159477233 ... 0.0005560573840522763
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0007141026159477233
                    : -0.01,
                parameterDescription: """
                    If major stablecoins collapse or de-peg, confidence can erode across all crypto, including BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "tornado",
                title: "Black Swan Events",
                isOn: $simSettings.useBlackSwanUnified,
                sliderValue: $simSettings.blackSwanDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.79777 ... 0.0
                    : -0.8 ... 0.0,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.398885
                    : -0.4,
                parameterDescription: """
                    Extreme, unforeseen disasters or wars can slam all markets, including BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "chart.bar.xaxis",
                title: "Bear Market Conditions",
                isOn: $simSettings.useBearMarketUnified,
                sliderValue: $simSettings.bearWeeklyDriftUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0016278802752494812 ... -0.0001278802752494812
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0008778802752494812
                    : -0.01,
                parameterDescription: """
                    Prolonged negativity leads to gradual price declines and capitulation.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis",
                title: "Declining ARR / Maturing Market",
                isOn: $simSettings.useMaturingMarketUnified,
                sliderValue: $simSettings.maxMaturingDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0039956381055486196 ... 0.0009075918944513804
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0015440231055486196
                    : -0.01,
                parameterDescription: """
                    As BTC matures, growth slows, diminishing speculative returns over time.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis.circle.fill",
                title: "Recession / Macro Crash",
                isOn: $simSettings.useRecessionUnified,
                sliderValue: $simSettings.maxRecessionDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0016560341467487811 ... -0.0001450641467487811
                    : -0.00217621 ... -0.00072540,
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
