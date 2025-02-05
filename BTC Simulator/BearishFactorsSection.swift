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
    
    var body: some View {
        Section("Bearish Factors") {
            
            // MARK: - REGULATORY CLAMPDOWN
            FactorToggleRow(
                factorName: "RegClampdown",
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                parameterDescription: """
                    Strict government bans/regulations can curb adoption and reduce demand.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0014273392243542672 ... -0.0008449512243542672
                    : -0.023 ... -0.017,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0011361452243542672
                    : -0.02,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - COMPETITOR COIN
            FactorToggleRow(
                factorName: "CompetitorCoin",
                iconName: "bitcoinsign.circle",
                title: "Competitor Coin",
                parameterDescription: """
                    A rival crypto with better tech or speed may siphon market share from BTC.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0011842141746411323 ... -0.0008454221746411323
                    : -0.0092 ... -0.0068,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010148181746411323
                    : -0.008,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - SECURITY BREACH
            FactorToggleRow(
                factorName: "SecurityBreach",
                iconName: "lock.shield",
                title: "Security Breach",
                parameterDescription: """
                    Major hacks or protocol exploits can damage confidence and spark selloffs.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0012819675168380737 ... -0.0009009755168380737
                    : -0.00805 ... -0.00595,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010914715168380737
                    : -0.007,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - BUBBLE POP
            FactorToggleRow(
                factorName: "BubblePop",
                iconName: "bubble.left.and.bubble.right.fill",
                title: "Bubble Pop",
                parameterDescription: """
                    Speculative manias can end abruptly, causing prices to crash.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.002244817890762329 ... -0.001280529890762329
                    : -0.0115 ... -0.0085,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.001762673890762329
                    : -0.01,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - STABLECOIN MELTDOWN
            FactorToggleRow(
                factorName: "StablecoinMeltdown",
                iconName: "exclamationmark.triangle.fill",
                title: "Stablecoin Meltdown",
                parameterDescription: """
                    If major stablecoins collapse or de-peg, confidence erodes across all crypto, including BTC.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0009681346159477233 ... -0.0004600706159477233
                    : -0.013 ... -0.007,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0007141026159477233
                    : -0.01,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - BLACK SWAN
            FactorToggleRow(
                factorName: "BlackSwan",
                iconName: "tornado",
                title: "Black Swan Events",
                parameterDescription: """
                    Extreme, unforeseen disasters or wars can slam all markets, including BTC.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.478662 ... -0.319108
                    : -0.48 ... -0.32,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.398885
                    : -0.4,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - BEAR MARKET
            FactorToggleRow(
                factorName: "BearMarket",
                iconName: "chart.bar.xaxis",
                title: "Bear Market Conditions",
                parameterDescription: """
                    Prolonged negativity leads to gradual price declines and capitulation.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0010278802752494812 ... -0.0007278802752494812
                    : -0.013 ... -0.007,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0008778802752494812
                    : -0.01,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - DECLINING ARR / MATURING MARKET
            FactorToggleRow(
                factorName: "MaturingMarket",
                iconName: "chart.line.downtrend.xyaxis",
                title: "Declining ARR / Maturing Market",
                parameterDescription: """
                    As BTC matures, growth slows, diminishing speculative returns over time.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0020343461055486196 ... -0.0010537001055486196
                    : -0.013 ... -0.007,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0015440231055486196
                    : -0.01,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
            
            // MARK: - RECESSION
            FactorToggleRow(
                factorName: "Recession",
                iconName: "chart.line.downtrend.xyaxis.circle.fill",
                title: "Recession / Macro Crash",
                parameterDescription: """
                    A broader economic downturn reduces risk appetite, pulling capital from BTC.
                    """,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0010516462467487811 ... -0.0007494520467487811
                    : -0.0015958890 ... -0.0013057270,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0009005491467487811
                    : -0.0014508080482482913,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                displayAsPercent: false
            )
        }
        .listRowBackground(Color(white: 0.15))
    }
}
