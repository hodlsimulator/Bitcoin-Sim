//
//  BullishFactorsSection.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import SwiftUI

struct BullishFactorsSection: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    // Pass in the currently active tooltip factor
    @Binding var activeFactor: String?
    
    // Pass in a function to toggle the tooltip
    let toggleFactor: (String) -> Void
    
    var body: some View {
        Section("Bullish Factors") {
            // HALVING
            FactorToggleRow(
                iconName: "globe.europe.africa",
                title: "Halving",
                isOn: $simSettings.useHalvingUnified,
                sliderValue: $simSettings.halvingBumpUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0673386887 ... 0.5923386887
                    : 0.0875 ... 0.6125,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.3298386887
                    : 0.35,
                parameterDescription: """
                    Occurs roughly every four years, reducing the block reward in half.
                    Historically associated with strong BTC price increases.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // INSTITUTIONAL DEMAND
            FactorToggleRow(
                iconName: "building.columns.fill",
                title: "Institutional Demand",
                isOn: $simSettings.useInstitutionalDemandUnified,
                sliderValue: $simSettings.maxDemandBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00030975 ... 0.00216825
                    : 0.00141475 ... 0.00990322,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.001239
                    : 0.0056589855,
                parameterDescription: """
                    Entry by large financial institutions & treasuries can drive significant BTC price appreciation.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // COUNTRY ADOPTION
            FactorToggleRow(
                iconName: "flag.fill",
                title: "Country Adoption",
                isOn: $simSettings.useCountryAdoptionUnified,
                sliderValue: $simSettings.maxCountryAdBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0003910479977 ... 0.0018841279977
                    : 0.00137888 ... 0.00965215,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0011375879977
                    : 0.005515515952320099,
                parameterDescription: """
                    Nations adopting BTC as legal tender or in their reserves create surges in demand and legitimacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // REGULATORY CLARITY
            FactorToggleRow(
                iconName: "checkmark.shield",
                title: "Regulatory Clarity",
                isOn: $simSettings.useRegulatoryClarityUnified,
                sliderValue: $simSettings.maxClarityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0001216354861605167 ... 0.0013124154861605167
                    : 0.00101843 ... 0.00712903,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0007170254861605167
                    : 0.0040737327,
                parameterDescription: """
                    Clear, favourable regulations can reduce uncertainty and risk, drawing more capital into BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // ETF APPROVAL
            FactorToggleRow(
                iconName: "building.2.crop.circle",
                title: "ETF Approval",
                isOn: $simSettings.useEtfApprovalUnified,
                sliderValue: $simSettings.maxEtfBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0002880183160305023 ... 0.0032880183160305023
                    : 0.00142857 ... 0.01,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0017880183160305023
                    : 0.0057142851,
                parameterDescription: """
                    Spot BTC ETFs allow traditional investors to gain exposure without custody, broadening the market.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // TECH BREAKTHROUGH
            FactorToggleRow(
                iconName: "sparkles",
                title: "Tech Breakthrough",
                isOn: $simSettings.useTechBreakthroughUnified,
                sliderValue: $simSettings.maxTechBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000745993579173088 ... 0.0011420393579173088
                    : 0.00070968 ... 0.00496739,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0006083193579173088
                    : 0.0028387091,
                parameterDescription: """
                    Major protocol/L2 improvements can generate optimism, e.g. better scalability or privacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // SCARCITY EVENTS
            FactorToggleRow(
                iconName: "scalemass",
                title: "Scarcity Events",
                isOn: $simSettings.useScarcityEventsUnified,
                sliderValue: $simSettings.maxScarcityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00010326753681182863 ... 0.00072290753681182863
                    : 0.00082322 ... 0.00576252,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.00041308753681182863
                    : 0.0032928705475521085,
                parameterDescription: """
                    Unusual supply reductions (e.g. large holders removing coins from exchanges) can elevate price.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // GLOBAL MACRO HEDGE
            FactorToggleRow(
                iconName: "globe.americas.fill",
                title: "Global Macro Hedge",
                isOn: $simSettings.useGlobalMacroHedgeUnified,
                sliderValue: $simSettings.maxMacroBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000352709724932909 ... 0.0006642909724932909
                    : 0.00081106 ... 0.00567742,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0003497809724932909
                    : 0.0032442397,
                parameterDescription: """
                    During macro uncertainty, BTC’s “digital gold” narrative can attract investors seeking a hedge.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // STABLECOIN SHIFT
            FactorToggleRow(
                iconName: "dollarsign.arrow.circlepath",
                title: "Stablecoin Shift",
                isOn: $simSettings.useStablecoinShiftUnified,
                sliderValue: $simSettings.maxStablecoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000275209116327763 ... 0.0006349209116327763
                    : 0.00057604 ... 0.00403226,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0003312209116327763
                    : 0.0023041475,
                parameterDescription: """
                    Sudden inflows from stablecoins into BTC can push prices up quickly.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // DEMOGRAPHIC ADOPTION
            FactorToggleRow(
                iconName: "person.3.fill",
                title: "Demographic Adoption",
                isOn: $simSettings.useDemographicAdoptionUnified,
                sliderValue: $simSettings.maxDemoBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000827332036626339 ... 0.0020412532036626339
                    : 0.00182278 ... 0.01275947,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0010619932036626339
                    : 0.007291124714649915,
                parameterDescription: """
                    Younger, tech-savvy generations often drive steady BTC adoption over time.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // ALTCOIN FLIGHT
            FactorToggleRow(
                iconName: "bitcoinsign.circle.fill",
                title: "Altcoin Flight",
                isOn: $simSettings.useAltcoinFlightUnified,
                sliderValue: $simSettings.maxAltcoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000700544461803342 ... 0.0004903844461803342
                    : 0.00053917 ... 0.00377419,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0002802194461803342
                    : 0.0021566817,
                parameterDescription: """
                    During altcoin uncertainty, capital may rotate into BTC as the ‘blue-chip’ crypto.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // ADOPTION FACTOR
            FactorToggleRow(
                iconName: "arrow.up.right.circle.fill",
                title: "Adoption Factor (Incremental Drift)",
                isOn: $simSettings.useAdoptionFactorUnified,
                sliderValue: $simSettings.adoptionBaseFactorUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0004011309088897705 ... 0.0028078909088897705
                    : 0.00366524 ... 0.02565668,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0016045109088897705
                    : 0.014660959934071304,
                parameterDescription: """
                    A slow, steady upward drift in BTC price from ongoing adoption growth.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
        }
        .listRowBackground(Color(white: 0.15))
    }
}
