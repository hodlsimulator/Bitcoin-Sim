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
    
    // Fraction dict for tilt weighting
    @Binding var factorEnableFrac: [String: Double]
    
    // Called when a toggle changes
    let animateFactor: (String, Bool) -> Void
    
    var body: some View {
        Section("Bullish Factors") {
            
            // MARK: - HALVING
            FactorToggleRow(
                iconName: "globe.europe.africa",
                title: "Halving",
                isOn: Binding<Bool>(
                    get: { simSettings.useHalvingWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useHalvingWeekly = newValue
                        s.useHalvingMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "Halving",
                                value: s.halvingBumpUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["Halving"] = fraction
                        } else {
                            factorEnableFrac["Halving"] = 0.0
                        }
                        animateFactor("Halving", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.halvingBumpUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "Halving", to: newVal)
                        s.updateManualOffset(factorName: "Halving", actualValue: newVal)
                        
                        if s.useHalvingWeekly {
                            let fraction = s.fractionFromValue(
                                "Halving",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["Halving"] = fraction
                        } else {
                            factorEnableFrac["Halving"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - INSTITUTIONAL DEMAND
            FactorToggleRow(
                iconName: "bitcoinsign.bank.building",
                title: "Institutional Demand",
                isOn: Binding<Bool>(
                    get: { simSettings.useInstitutionalDemandWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useInstitutionalDemandWeekly = newValue
                        s.useInstitutionalDemandMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "InstitutionalDemand",
                                value: s.maxDemandBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["InstitutionalDemand"] = fraction
                        } else {
                            factorEnableFrac["InstitutionalDemand"] = 0.0
                        }
                        animateFactor("InstitutionalDemand", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxDemandBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "InstitutionalDemand", to: newVal)
                        s.updateManualOffset(factorName: "InstitutionalDemand", actualValue: newVal)
                        
                        if s.useInstitutionalDemandWeekly {
                            let fraction = s.fractionFromValue(
                                "InstitutionalDemand",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["InstitutionalDemand"] = fraction
                        } else {
                            factorEnableFrac["InstitutionalDemand"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - COUNTRY ADOPTION
            FactorToggleRow(
                iconName: "flag.fill",
                title: "Country Adoption",
                isOn: Binding<Bool>(
                    get: { simSettings.useCountryAdoptionWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useCountryAdoptionWeekly = newValue
                        s.useCountryAdoptionMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "CountryAdoption",
                                value: s.maxCountryAdBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["CountryAdoption"] = fraction
                        } else {
                            factorEnableFrac["CountryAdoption"] = 0.0
                        }
                        animateFactor("CountryAdoption", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxCountryAdBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "CountryAdoption", to: newVal)
                        s.updateManualOffset(factorName: "CountryAdoption", actualValue: newVal)
                        
                        if s.useCountryAdoptionWeekly {
                            let fraction = s.fractionFromValue(
                                "CountryAdoption",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["CountryAdoption"] = fraction
                        } else {
                            factorEnableFrac["CountryAdoption"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - REGULATORY CLARITY
            FactorToggleRow(
                iconName: "checkmark.shield",
                title: "Regulatory Clarity",
                isOn: Binding<Bool>(
                    get: { simSettings.useRegulatoryClarityWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useRegulatoryClarityWeekly = newValue
                        s.useRegulatoryClarityMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "RegulatoryClarity",
                                value: s.maxClarityBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["RegulatoryClarity"] = fraction
                        } else {
                            factorEnableFrac["RegulatoryClarity"] = 0.0
                        }
                        animateFactor("RegulatoryClarity", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxClarityBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "RegulatoryClarity", to: newVal)
                        s.updateManualOffset(factorName: "RegulatoryClarity", actualValue: newVal)
                        
                        if s.useRegulatoryClarityWeekly {
                            let fraction = s.fractionFromValue(
                                "RegulatoryClarity",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["RegulatoryClarity"] = fraction
                        } else {
                            factorEnableFrac["RegulatoryClarity"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - ETF APPROVAL
            FactorToggleRow(
                iconName: "building.2.crop.circle",
                title: "ETF Approval",
                isOn: Binding<Bool>(
                    get: { simSettings.useEtfApprovalWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useEtfApprovalWeekly = newValue
                        s.useEtfApprovalMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "EtfApproval",
                                value: s.maxEtfBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["EtfApproval"] = fraction
                        } else {
                            factorEnableFrac["EtfApproval"] = 0.0
                        }
                        animateFactor("EtfApproval", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxEtfBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "EtfApproval", to: newVal)
                        s.updateManualOffset(factorName: "EtfApproval", actualValue: newVal)
                        
                        if s.useEtfApprovalWeekly {
                            let fraction = s.fractionFromValue(
                                "EtfApproval",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["EtfApproval"] = fraction
                        } else {
                            factorEnableFrac["EtfApproval"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - TECH BREAKTHROUGH
            FactorToggleRow(
                iconName: "sparkles",
                title: "Tech Breakthrough",
                isOn: Binding<Bool>(
                    get: { simSettings.useTechBreakthroughWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useTechBreakthroughWeekly = newValue
                        s.useTechBreakthroughMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "TechBreakthrough",
                                value: s.maxTechBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["TechBreakthrough"] = fraction
                        } else {
                            factorEnableFrac["TechBreakthrough"] = 0.0
                        }
                        animateFactor("TechBreakthrough", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxTechBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "TechBreakthrough", to: newVal)
                        s.updateManualOffset(factorName: "TechBreakthrough", actualValue: newVal)
                        
                        if s.useTechBreakthroughWeekly {
                            let fraction = s.fractionFromValue(
                                "TechBreakthrough",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["TechBreakthrough"] = fraction
                        } else {
                            factorEnableFrac["TechBreakthrough"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - SCARCITY EVENTS
            FactorToggleRow(
                iconName: "scalemass",
                title: "Scarcity Events",
                isOn: Binding<Bool>(
                    get: { simSettings.useScarcityEventsWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useScarcityEventsWeekly = newValue
                        s.useScarcityEventsMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "ScarcityEvents",
                                value: s.maxScarcityBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["ScarcityEvents"] = fraction
                        } else {
                            factorEnableFrac["ScarcityEvents"] = 0.0
                        }
                        animateFactor("ScarcityEvents", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxScarcityBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "ScarcityEvents", to: newVal)
                        s.updateManualOffset(factorName: "ScarcityEvents", actualValue: newVal)
                        
                        if s.useScarcityEventsWeekly {
                            let fraction = s.fractionFromValue(
                                "ScarcityEvents",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["ScarcityEvents"] = fraction
                        } else {
                            factorEnableFrac["ScarcityEvents"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - GLOBAL MACRO HEDGE
            FactorToggleRow(
                iconName: "globe.americas.fill",
                title: "Global Macro Hedge",
                isOn: Binding<Bool>(
                    get: { simSettings.useGlobalMacroHedgeWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useGlobalMacroHedgeWeekly = newValue
                        s.useGlobalMacroHedgeMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "GlobalMacroHedge",
                                value: s.maxMacroBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["GlobalMacroHedge"] = fraction
                        } else {
                            factorEnableFrac["GlobalMacroHedge"] = 0.0
                        }
                        animateFactor("GlobalMacroHedge", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxMacroBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "GlobalMacroHedge", to: newVal)
                        s.updateManualOffset(factorName: "GlobalMacroHedge", actualValue: newVal)
                        
                        if s.useGlobalMacroHedgeWeekly {
                            let fraction = s.fractionFromValue(
                                "GlobalMacroHedge",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["GlobalMacroHedge"] = fraction
                        } else {
                            factorEnableFrac["GlobalMacroHedge"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - STABLECOIN SHIFT
            FactorToggleRow(
                iconName: "dollarsign.arrow.circlepath",
                title: "Stablecoin Shift",
                isOn: Binding<Bool>(
                    get: { simSettings.useStablecoinShiftWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useStablecoinShiftWeekly = newValue
                        s.useStablecoinShiftMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "StablecoinShift",
                                value: s.maxStablecoinBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["StablecoinShift"] = fraction
                        } else {
                            factorEnableFrac["StablecoinShift"] = 0.0
                        }
                        animateFactor("StablecoinShift", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxStablecoinBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "StablecoinShift", to: newVal)
                        s.updateManualOffset(factorName: "StablecoinShift", actualValue: newVal)
                        
                        if s.useStablecoinShiftWeekly {
                            let fraction = s.fractionFromValue(
                                "StablecoinShift",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["StablecoinShift"] = fraction
                        } else {
                            factorEnableFrac["StablecoinShift"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - DEMOGRAPHIC ADOPTION
            FactorToggleRow(
                iconName: "person.3.fill",
                title: "Demographic Adoption",
                isOn: Binding<Bool>(
                    get: { simSettings.useDemographicAdoptionWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useDemographicAdoptionWeekly = newValue
                        s.useDemographicAdoptionMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "DemographicAdoption",
                                value: s.maxDemoBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["DemographicAdoption"] = fraction
                        } else {
                            factorEnableFrac["DemographicAdoption"] = 0.0
                        }
                        animateFactor("DemographicAdoption", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxDemoBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "DemographicAdoption", to: newVal)
                        s.updateManualOffset(factorName: "DemographicAdoption", actualValue: newVal)
                        
                        if s.useDemographicAdoptionWeekly {
                            let fraction = s.fractionFromValue(
                                "DemographicAdoption",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["DemographicAdoption"] = fraction
                        } else {
                            factorEnableFrac["DemographicAdoption"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - ALTCOIN FLIGHT
            FactorToggleRow(
                iconName: "bitcoinsign.circle.fill",
                title: "Altcoin Flight",
                isOn: Binding<Bool>(
                    get: { simSettings.useAltcoinFlightWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useAltcoinFlightWeekly = newValue
                        s.useAltcoinFlightMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "AltcoinFlight",
                                value: s.maxAltcoinBoostUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["AltcoinFlight"] = fraction
                        } else {
                            factorEnableFrac["AltcoinFlight"] = 0.0
                        }
                        animateFactor("AltcoinFlight", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.maxAltcoinBoostUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "AltcoinFlight", to: newVal)
                        s.updateManualOffset(factorName: "AltcoinFlight", actualValue: newVal)
                        
                        if s.useAltcoinFlightWeekly {
                            let fraction = s.fractionFromValue(
                                "AltcoinFlight",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["AltcoinFlight"] = fraction
                        } else {
                            factorEnableFrac["AltcoinFlight"] = 0.0
                        }
                    }
                ),
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
            
            // MARK: - ADOPTION FACTOR (Incremental Drift)
            FactorToggleRow(
                iconName: "arrow.up.right.circle.fill",
                title: "Adoption Factor (Incremental Drift)",
                isOn: Binding<Bool>(
                    get: { simSettings.useAdoptionFactorWeekly },
                    set: { newValue in
                        let s = simSettings
                        s.useAdoptionFactorWeekly = newValue
                        s.useAdoptionFactorMonthly = newValue
                        
                        if newValue {
                            let fraction = s.fractionFromValue(
                                "AdoptionFactor",
                                value: s.adoptionBaseFactorUnified,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["AdoptionFactor"] = fraction
                        } else {
                            factorEnableFrac["AdoptionFactor"] = 0.0
                        }
                        animateFactor("AdoptionFactor", newValue)
                    }
                ),
                sliderValue: Binding<Double>(
                    get: { simSettings.adoptionBaseFactorUnified },
                    set: { newVal in
                        let s = simSettings
                        s.setNumericValue(for: "AdoptionFactor", to: newVal)
                        s.updateManualOffset(factorName: "AdoptionFactor", actualValue: newVal)
                        
                        if s.useAdoptionFactorWeekly {
                            let fraction = s.fractionFromValue(
                                "AdoptionFactor",
                                value: newVal,
                                isWeekly: s.periodUnit == .weeks
                            )
                            factorEnableFrac["AdoptionFactor"] = fraction
                        } else {
                            factorEnableFrac["AdoptionFactor"] = 0.0
                        }
                    }
                ),
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
