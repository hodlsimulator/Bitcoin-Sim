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
    
    // Keep if you still want fractional weighting logic
    // but NOT for toggling the factor on/off!
    @Binding var factorEnableFrac: [String: Double]
    
    // Called when a toggle changes (if you still want an animation/log)
    let animateFactor: (String, Bool) -> Void
    
    var body: some View {
        Section("Bullish Factors") {
            
            // HALVING
            FactorToggleRow(
                iconName: "globe.europe.africa",
                title: "Halving",
                // Now purely uses simSettings.useHalvingWeekly for on/off
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useHalvingWeekly
                    },
                    set: { newValue in
                        simSettings.useHalvingWeekly  = newValue
                        simSettings.useHalvingMonthly = newValue
                        
                        // If you want to keep factorEnableFrac in sync, do:
                        factorEnableFrac["Halving"] = newValue
                            ? (factorEnableFrac["Halving"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("Halving", newValue)
                    }
                ),
                sliderValue: $simSettings.halvingBumpUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.2773386887 ... 0.3823386887
                    : 0.2975 ... 0.4025,
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
                iconName: "bitcoinsign.bank.building",
                title: "Institutional Demand",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useInstitutionalDemandWeekly
                    },
                    set: { newValue in
                        simSettings.useInstitutionalDemandWeekly  = newValue
                        simSettings.useInstitutionalDemandMonthly = newValue
                        
                        factorEnableFrac["InstitutionalDemand"] = newValue
                            ? (factorEnableFrac["InstitutionalDemand"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("InstitutionalDemand", newValue)
                    }
                ),
                sliderValue: $simSettings.maxDemandBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00105315 ... 0.00142485
                    : 0.0048101384 ... 0.0065078326,
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
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useCountryAdoptionWeekly
                    },
                    set: { newValue in
                        simSettings.useCountryAdoptionWeekly  = newValue
                        simSettings.useCountryAdoptionMonthly = newValue
                        
                        factorEnableFrac["CountryAdoption"] = newValue
                            ? (factorEnableFrac["CountryAdoption"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("CountryAdoption", newValue)
                    }
                ),
                sliderValue: $simSettings.maxCountryAdBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0009882799977 ... 0.0012868959977
                    : 0.004688188952320099 ... 0.006342842952320099,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0011375879977
                    : 0.005515515952320099,
                parameterDescription: """
                    Nations adopting BTC as legal tender or in their reserves
                    create surges in demand and legitimacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // REGULATORY CLARITY
            FactorToggleRow(
                iconName: "checkmark.shield",
                title: "Regulatory Clarity",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useRegulatoryClarityWeekly
                    },
                    set: { newValue in
                        simSettings.useRegulatoryClarityWeekly  = newValue
                        simSettings.useRegulatoryClarityMonthly = newValue
                        
                        factorEnableFrac["RegulatoryClarity"] = newValue
                            ? (factorEnableFrac["RegulatoryClarity"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("RegulatoryClarity", newValue)
                    }
                ),
                sliderValue: $simSettings.maxClarityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0005979474861605167 ... 0.0008361034861605167
                    : 0.0034626727 ... 0.0046847927,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0007170254861605167
                    : 0.0040737327,
                parameterDescription: """
                    Clear, favourable regulations can reduce uncertainty and risk,
                    drawing more capital into BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // ETF APPROVAL
            FactorToggleRow(
                iconName: "building.2.crop.circle",
                title: "ETF Approval",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useEtfApprovalWeekly
                    },
                    set: { newValue in
                        simSettings.useEtfApprovalWeekly  = newValue
                        simSettings.useEtfApprovalMonthly = newValue
                        
                        factorEnableFrac["EtfApproval"] = newValue
                            ? (factorEnableFrac["EtfApproval"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("EtfApproval", newValue)
                    }
                ),
                sliderValue: $simSettings.maxEtfBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0014880183160305023 ... 0.0020880183160305023
                    : 0.0048571421 ... 0.0065714281,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0017880183160305023
                    : 0.0057142851,
                parameterDescription: """
                    Spot BTC ETFs allow traditional investors to gain exposure
                    without custody, broadening the market.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // TECH BREAKTHROUGH
            FactorToggleRow(
                iconName: "sparkles",
                title: "Tech Breakthrough",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useTechBreakthroughWeekly
                    },
                    set: { newValue in
                        simSettings.useTechBreakthroughWeekly  = newValue
                        simSettings.useTechBreakthroughMonthly = newValue
                        
                        factorEnableFrac["TechBreakthrough"] = newValue
                            ? (factorEnableFrac["TechBreakthrough"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("TechBreakthrough", newValue)
                    }
                ),
                sliderValue: $simSettings.maxTechBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0005015753579173088 ... 0.0007150633579173088
                    : 0.0024129091 ... 0.0032645091,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0006083193579173088
                    : 0.0028387091,
                parameterDescription: """
                    Major protocol/L2 improvements can generate optimism,
                    e.g. better scalability or privacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // SCARCITY EVENTS
            FactorToggleRow(
                iconName: "scalemass",
                title: "Scarcity Events",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useScarcityEventsWeekly
                    },
                    set: { newValue in
                        simSettings.useScarcityEventsWeekly  = newValue
                        simSettings.useScarcityEventsMonthly = newValue
                        
                        factorEnableFrac["ScarcityEvents"] = newValue
                            ? (factorEnableFrac["ScarcityEvents"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("ScarcityEvents", newValue)
                    }
                ),
                sliderValue: $simSettings.maxScarcityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00035112353681182863 ... 0.00047505153681182863
                    : 0.0027989405475521085 ... 0.0037868005475521085,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.00041308753681182863
                    : 0.0032928705475521085,
                parameterDescription: """
                    Unusual supply reductions (e.g. large holders removing coins
                    from exchanges) can elevate price.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // GLOBAL MACRO HEDGE
            FactorToggleRow(
                iconName: "globe.americas.fill",
                title: "Global Macro Hedge",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useGlobalMacroHedgeWeekly
                    },
                    set: { newValue in
                        simSettings.useGlobalMacroHedgeWeekly  = newValue
                        simSettings.useGlobalMacroHedgeMonthly = newValue
                        
                        factorEnableFrac["GlobalMacroHedge"] = newValue
                            ? (factorEnableFrac["GlobalMacroHedge"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("GlobalMacroHedge", newValue)
                    }
                ),
                sliderValue: $simSettings.maxMacroBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0002868789724932909 ... 0.0004126829724932909
                    : 0.0027576037 ... 0.0037308757,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0003497809724932909
                    : 0.0032442397,
                parameterDescription: """
                    During macro uncertainty, BTC’s “digital gold” narrative
                    can attract investors seeking a hedge.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            
            // STABLECOIN SHIFT
            FactorToggleRow(
                iconName: "dollarsign.arrow.circlepath",
                title: "Stablecoin Shift",
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useStablecoinShiftWeekly
                    },
                    set: { newValue in
                        simSettings.useStablecoinShiftWeekly  = newValue
                        simSettings.useStablecoinShiftMonthly = newValue
                        
                        factorEnableFrac["StablecoinShift"] = newValue
                            ? (factorEnableFrac["StablecoinShift"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("StablecoinShift", newValue)
                    }
                ),
                sliderValue: $simSettings.maxStablecoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0002704809116327763 ... 0.0003919609116327763
                    : 0.0019585255 ... 0.0026497695,
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
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useDemographicAdoptionWeekly
                    },
                    set: { newValue in
                        simSettings.useDemographicAdoptionWeekly  = newValue
                        simSettings.useDemographicAdoptionMonthly = newValue
                        
                        factorEnableFrac["DemographicAdoption"] = newValue
                            ? (factorEnableFrac["DemographicAdoption"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("DemographicAdoption", newValue)
                    }
                ),
                sliderValue: $simSettings.maxDemoBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0008661432036626339 ... 0.0012578432036626339
                    : 0.006197455714649915 ... 0.008384793714649915,
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
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useAltcoinFlightWeekly
                    },
                    set: { newValue in
                        simSettings.useAltcoinFlightWeekly  = newValue
                        simSettings.useAltcoinFlightMonthly = newValue
                        
                        factorEnableFrac["AltcoinFlight"] = newValue
                            ? (factorEnableFrac["AltcoinFlight"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("AltcoinFlight", newValue)
                    }
                ),
                sliderValue: $simSettings.maxAltcoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0002381864461803342 ... 0.0003222524461803342
                    : 0.0018331797 ... 0.0024801837,
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
                isOn: Binding<Bool>(
                    get: {
                        simSettings.useAdoptionFactorWeekly
                    },
                    set: { newValue in
                        simSettings.useAdoptionFactorWeekly  = newValue
                        simSettings.useAdoptionFactorMonthly = newValue
                        
                        factorEnableFrac["AdoptionFactor"] = newValue
                            ? (factorEnableFrac["AdoptionFactor"] ?? 1.0)
                            : 0.0
                        
                        animateFactor("AdoptionFactor", newValue)
                    }
                ),
                sliderValue: $simSettings.adoptionBaseFactorUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0013638349088897705 ... 0.0018451869088897705
                    : 0.012461815934071304 ... 0.016860103934071304,
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
