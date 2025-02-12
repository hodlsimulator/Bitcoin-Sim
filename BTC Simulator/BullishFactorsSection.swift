//
//  BullishFactorsSection.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import SwiftUI

struct BullishFactorsSection: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    // Currently active tooltip factor
    @Binding var activeFactor: String?
    
    // For tooltips on title tap
    let toggleFactor: (String) -> Void
    
    // This closure is called by FactorToggleRow so we can recalc tilt bar
    let onFactorChange: () -> Void
    
    // The weekly dictionary you shared:
    private let bullishTiltValuesWeekly: [String: Double] = [
        "halving":            25.41,
        "institutionaldemand": 8.30,
        "countryadoption":     8.19,
        "regulatoryclarity":   7.46,
        "etfapproval":         8.94,
        "techbreakthrough":    7.20,
        "scarcityevents":      6.66,
        "globalmacrohedge":    6.43,
        "stablecoinshift":     6.37,
        "demographicadoption": 8.06,
        "altcoinflight":       6.19,
        "adoptionfactor":      8.75
    ]
    
    // Here are the tilt-bar weights you mentioned:
    private let bullishTiltValuesMonthly: [String: Double] = [
        "halving": 20.15,
        "institutionaldemand": 8.69,
        "countryadoption": 8.47,
        "regulatoryclarity": 7.55,
        "etfapproval": 8.24,
        "techbreakthrough": 7.09,
        "scarcityevents": 7.55,
        "globalmacrohedge": 7.32,
        "stablecoinshift": 6.86,
        "demographicadoption": 9.39,
        "altcoinflight": 6.40,
        "adoptionfactor": 10.29
    ]
    
    private func tiltBarValue(for factorName: String) -> Double {
        // Lowercase factor name so dictionary lookup is case-insensitive:
        let key = factorName.lowercased()
        
        // Decide which dictionary to use based on simSettings.periodUnit
        if simSettings.periodUnit == .months {
            return bullishTiltValuesMonthly[key] ?? 0.0
        } else {
            return bullishTiltValuesWeekly[key] ?? 0.0
        }
    }
    
    var body: some View {
        Section("Bullish Factors") {
            
            // Halving
            FactorToggleRow(
                factorName: "Halving",
                iconName: "globe.europe.africa",
                title: "Halving",
                parameterDescription: """
                    Occurs roughly every four years, reducing the block reward in half.
                    Historically associated with strong BTC price increases.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.2773386887 ... 0.3823386887
                    : 0.2975 ... 0.4025,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.3298386887
                    : 0.35,
                tiltBarValue: tiltBarValue(for: "Halving"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Institutional Demand
            FactorToggleRow(
                factorName: "InstitutionalDemand",
                iconName: "bitcoinsign.bank.building",
                title: "Institutional Demand",
                parameterDescription: """
                    Entry by large financial institutions & treasuries can drive significant BTC price appreciation.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.00105315 ... 0.00142485
                    : 0.0048101384 ... 0.0065078326,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.001239
                    : 0.0056589855,
                tiltBarValue: tiltBarValue(for: "InstitutionalDemand"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Country Adoption
            FactorToggleRow(
                factorName: "CountryAdoption",
                iconName: "flag.fill",
                title: "Country Adoption",
                parameterDescription: """
                    Nations adopting BTC as legal tender or in their reserves
                    create surges in demand and legitimacy.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0009882799977 ... 0.0012868959977
                    : 0.004688188952320099 ... 0.006342842952320099,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0011375879977
                    : 0.005515515952320099,
                tiltBarValue: tiltBarValue(for: "CountryAdoption"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Regulatory Clarity
            FactorToggleRow(
                factorName: "RegulatoryClarity",
                iconName: "checkmark.shield",
                title: "Regulatory Clarity",
                parameterDescription: """
                    Clear, favourable regulations can reduce uncertainty and risk,
                    drawing more capital into BTC.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0005979474861605167 ... 0.0008361034861605167
                    : 0.0034626727 ... 0.0046847927,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0007170254861605167
                    : 0.0040737327,
                tiltBarValue: tiltBarValue(for: "RegulatoryClarity"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // ETF Approval
            FactorToggleRow(
                factorName: "EtfApproval",
                iconName: "building.2.crop.circle",
                title: "ETF Approval",
                parameterDescription: """
                    Spot BTC ETFs allow traditional investors to gain exposure
                    without custody, broadening the market.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0014880183160305023 ... 0.0020880183160305023
                    : 0.0048571421 ... 0.0065714281,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0017880183160305023
                    : 0.0057142851,
                tiltBarValue: tiltBarValue(for: "EtfApproval"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Tech Breakthrough
            FactorToggleRow(
                factorName: "TechBreakthrough",
                iconName: "sparkles",
                title: "Tech Breakthrough",
                parameterDescription: """
                    Major protocol/L2 improvements can generate optimism,
                    e.g. better scalability or privacy.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0005015753579173088 ... 0.0007150633579173088
                    : 0.0024129091 ... 0.0032645091,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0006083193579173088
                    : 0.0028387091,
                tiltBarValue: tiltBarValue(for: "TechBreakthrough"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Scarcity Events
            FactorToggleRow(
                factorName: "ScarcityEvents",
                iconName: "scalemass",
                title: "Scarcity Events",
                parameterDescription: """
                    Unusual supply reductions (e.g. large holders removing coins
                    from exchanges) can elevate price.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.00035112353681182863 ... 0.00047505153681182863
                    : 0.0027989405475521085 ... 0.0037868005475521085,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.00041308753681182863
                    : 0.0032928705475521085,
                tiltBarValue: tiltBarValue(for: "ScarcityEvents"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Global Macro Hedge
            FactorToggleRow(
                factorName: "GlobalMacroHedge",
                iconName: "globe.americas.fill",
                title: "Global Macro Hedge",
                parameterDescription: """
                    During macro uncertainty, BTC’s “digital gold” narrative
                    can attract investors seeking a hedge.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0002868789724932909 ... 0.0004126829724932909
                    : 0.0027576037 ... 0.0037308757,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0003497809724932909
                    : 0.0032442397,
                tiltBarValue: tiltBarValue(for: "GlobalMacroHedge"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Stablecoin Shift
            FactorToggleRow(
                factorName: "StablecoinShift",
                iconName: "dollarsign.arrow.circlepath",
                title: "Stablecoin Shift",
                parameterDescription: """
                    Sudden inflows from stablecoins into BTC can push prices up quickly.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0002704809116327763 ... 0.0003919609116327763
                    : 0.0019585255 ... 0.0026497695,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0003312209116327763
                    : 0.0023041475,
                tiltBarValue: tiltBarValue(for: "StablecoinShift"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Demographic Adoption
            FactorToggleRow(
                factorName: "DemographicAdoption",
                iconName: "person.3.fill",
                title: "Demographic Adoption",
                parameterDescription: """
                    Younger, tech-savvy generations often drive steady BTC adoption over time.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0008661432036626339 ... 0.0012578432036626339
                    : 0.006197455714649915 ... 0.008384793714649915,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0010619932036626339
                    : 0.007291124714649915,
                tiltBarValue: tiltBarValue(for: "DemographicAdoption"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Altcoin Flight
            FactorToggleRow(
                factorName: "AltcoinFlight",
                iconName: "bitcoinsign.circle.fill",
                title: "Altcoin Flight",
                parameterDescription: """
                    During altcoin uncertainty, capital may rotate into BTC as the ‘blue-chip’ crypto.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0002381864461803342 ... 0.0003222524461803342
                    : 0.0018331797 ... 0.0024801837,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0002802194461803342
                    : 0.0021566817,
                tiltBarValue: tiltBarValue(for: "AltcoinFlight"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
            
            // Adoption Factor (Incremental Drift)
            FactorToggleRow(
                factorName: "AdoptionFactor",
                iconName: "arrow.up.right.circle.fill",
                title: "Adoption Factor (Incremental Drift)",
                parameterDescription: """
                    A slow, steady upward drift in BTC price from ongoing adoption growth.
                    """,
                sliderRange: (simSettings.periodUnit == .weeks)
                    ? 0.0013638349088897705 ... 0.0018451869088897705
                    : 0.012461815934071304 ... 0.016860103934071304,
                defaultValue: (simSettings.periodUnit == .weeks)
                    ? 0.0016045109088897705
                    : 0.014660959934071304,
                tiltBarValue: tiltBarValue(for: "AdoptionFactor"),
                displayAsPercent: false,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor,
                onFactorChange: onFactorChange
            )
        }
        .listRowBackground(Color(white: 0.15))
    }
}
