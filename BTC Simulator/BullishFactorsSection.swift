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
    
    // Called when a toggle changes (if you still want an animation/log)
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
                        simSettings.useHalvingWeekly = newValue
                        simSettings.useHalvingMonthly = newValue
                        
                        if newValue {
                            // Calculate fraction from current numeric
                            let fraction = simSettings.fractionFromValue(
                                "Halving",
                                value: simSettings.halvingBumpUnified,
                                isWeekly: simSettings.periodUnit == .weeks
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
                        simSettings.halvingBumpUnified = newVal
                        if simSettings.useHalvingWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "Halving",
                                value: newVal,
                                isWeekly: simSettings.periodUnit == .weeks
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
                        simSettings.useInstitutionalDemandWeekly = newValue
                        simSettings.useInstitutionalDemandMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "InstitutionalDemand",
                                value: simSettings.maxDemandBoostUnified,
                                isWeekly: simSettings.periodUnit == .weeks
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
                        simSettings.maxDemandBoostUnified = newVal
                        if simSettings.useInstitutionalDemandWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "InstitutionalDemand",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useCountryAdoptionWeekly = newValue
                        simSettings.useCountryAdoptionMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "CountryAdoption",
                                value: simSettings.maxCountryAdBoostUnified,
                                isWeekly: simSettings.periodUnit == .weeks
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
                        simSettings.maxCountryAdBoostUnified = newVal
                        if simSettings.useCountryAdoptionWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "CountryAdoption",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useRegulatoryClarityWeekly = newValue
                        simSettings.useRegulatoryClarityMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "RegulatoryClarity",
                                value: simSettings.maxClarityBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxClarityBoostUnified = newVal
                        if simSettings.useRegulatoryClarityWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "RegulatoryClarity",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useEtfApprovalWeekly = newValue
                        simSettings.useEtfApprovalMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "EtfApproval",
                                value: simSettings.maxEtfBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxEtfBoostUnified = newVal
                        if simSettings.useEtfApprovalWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "EtfApproval",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useTechBreakthroughWeekly = newValue
                        simSettings.useTechBreakthroughMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "TechBreakthrough",
                                value: simSettings.maxTechBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxTechBoostUnified = newVal
                        if simSettings.useTechBreakthroughWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "TechBreakthrough",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useScarcityEventsWeekly = newValue
                        simSettings.useScarcityEventsMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "ScarcityEvents",
                                value: simSettings.maxScarcityBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxScarcityBoostUnified = newVal
                        if simSettings.useScarcityEventsWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "ScarcityEvents",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useGlobalMacroHedgeWeekly = newValue
                        simSettings.useGlobalMacroHedgeMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "GlobalMacroHedge",
                                value: simSettings.maxMacroBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxMacroBoostUnified = newVal
                        if simSettings.useGlobalMacroHedgeWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "GlobalMacroHedge",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useStablecoinShiftWeekly = newValue
                        simSettings.useStablecoinShiftMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "StablecoinShift",
                                value: simSettings.maxStablecoinBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxStablecoinBoostUnified = newVal
                        if simSettings.useStablecoinShiftWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "StablecoinShift",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useDemographicAdoptionWeekly = newValue
                        simSettings.useDemographicAdoptionMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "DemographicAdoption",
                                value: simSettings.maxDemoBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxDemoBoostUnified = newVal
                        if simSettings.useDemographicAdoptionWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "DemographicAdoption",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useAltcoinFlightWeekly = newValue
                        simSettings.useAltcoinFlightMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "AltcoinFlight",
                                value: simSettings.maxAltcoinBoostUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.maxAltcoinBoostUnified = newVal
                        if simSettings.useAltcoinFlightWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "AltcoinFlight",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.useAdoptionFactorWeekly = newValue
                        simSettings.useAdoptionFactorMonthly = newValue
                        
                        if newValue {
                            let fraction = simSettings.fractionFromValue(
                                "AdoptionFactor",
                                value: simSettings.adoptionBaseFactorUnified,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
                        simSettings.adoptionBaseFactorUnified = newVal
                        if simSettings.useAdoptionFactorWeekly {
                            let fraction = simSettings.fractionFromValue(
                                "AdoptionFactor",
                                value: newVal,
                                isWeekly: (simSettings.periodUnit == .weeks)
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
