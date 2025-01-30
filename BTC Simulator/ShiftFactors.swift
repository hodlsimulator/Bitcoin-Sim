//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    /// Shift all factors by `delta`, but only if that factor is toggled on
    /// (via simSettings.useXYZWeekly). The fraction influences the *speed* at which it moves,
    /// but we no longer skip if fraction == 0. (If the user explicitly toggles the factor off,
    /// then `isOn` will be false, which also skips the shift.)
    func shiftAllFactors(by delta: Double) {
        print("DEBUG: shiftAllFactors called with delta: \(delta)") // Log when it's being called
        
        // Clamp x into [minVal, maxVal].
        func clamp(_ x: Double, minVal: Double, maxVal: Double) -> Double {
            let lower = min(minVal, maxVal)
            let upper = max(minVal, maxVal)
            return max(lower, min(upper, x))
        }

        /// Shifts `oldValue` by `delta * range * fraction`, if factor is toggled on.
        func maybeShift(
            key: String,
            isOn: Bool,
            oldValue: inout Double,
            minVal: Double,
            maxVal: Double
        ) {
            guard isOn else { return }
            
            let frac = simSettings.factorEnableFrac[key] ?? 0.0
            let range = maxVal - minVal
            
            // Scale the shift by fraction
            let scaledDelta = delta * range * frac
            
            let newValue = clamp(oldValue + scaledDelta, minVal: minVal, maxVal: maxVal)
            
            // Print debug info
            print("DEBUG: Shifting \(key):")
            print("  isOn: \(isOn), frac: \(frac), oldValue: \(oldValue), delta: \(delta), scaledDelta: \(scaledDelta), newValue: \(newValue)")
            
            if abs(newValue - oldValue) > 1e-7 {
                oldValue = newValue
            }
        }
        
        // Apply the maybeShift function to each factor
        for key in bullishKeys {
            // Unwrap the optional value for isOn and oldValue before passing to maybeShift
            if let oldValue = simSettings.factorEnableFrac[key] {
                maybeShift(
                    key: key,
                    isOn: oldValue > 0.0, // Determine if the factor is "on"
                    oldValue: &simSettings.factorEnableFrac[key]!,
                    minVal: 0.0,
                    maxVal: 1.0
                )
            }
        }
        
        for key in bearishKeys {
            // Unwrap the optional value for isOn and oldValue before passing to maybeShift
            if let oldValue = simSettings.factorEnableFrac[key] {
                maybeShift(
                    key: key,
                    isOn: oldValue > 0.0, // Determine if the factor is "on"
                    oldValue: &simSettings.factorEnableFrac[key]!,
                    minVal: -1.0,
                    maxVal: 0.0
                )
            }
        }
        
        // Additional code to ensure any other necessary state changes happen
        print("DEBUG: Completed shifting all factors")
        
        // ---------------- BULLISH FACTORS ----------------
        maybeShift(key: "Halving",
                   isOn: simSettings.useHalvingWeekly,
                   oldValue: &simSettings.halvingBumpUnified,
                   minVal: 0.2773386887,
                   maxVal: 0.3823386887)
        
        maybeShift(key: "InstitutionalDemand",
                   isOn: simSettings.useInstitutionalDemandWeekly,
                   oldValue: &simSettings.maxDemandBoostUnified,
                   minVal: 0.00105315,
                   maxVal: 0.00142485)
        
        maybeShift(key: "CountryAdoption",
                   isOn: simSettings.useCountryAdoptionWeekly,
                   oldValue: &simSettings.maxCountryAdBoostUnified,
                   minVal: 0.0009882799977,
                   maxVal: 0.0012868959977)
        
        maybeShift(key: "RegulatoryClarity",
                   isOn: simSettings.useRegulatoryClarityWeekly,
                   oldValue: &simSettings.maxClarityBoostUnified,
                   minVal: 0.0005979474861605167,
                   maxVal: 0.0008361034861605167)
        
        maybeShift(key: "EtfApproval",
                   isOn: simSettings.useEtfApprovalWeekly,
                   oldValue: &simSettings.maxEtfBoostUnified,
                   minVal: 0.0014880183160305023,
                   maxVal: 0.0020880183160305023)
        
        maybeShift(key: "TechBreakthrough",
                   isOn: simSettings.useTechBreakthroughWeekly,
                   oldValue: &simSettings.maxTechBoostUnified,
                   minVal: 0.0005015753579173088,
                   maxVal: 0.0007150633579173088)
        
        maybeShift(key: "ScarcityEvents",
                   isOn: simSettings.useScarcityEventsWeekly,
                   oldValue: &simSettings.maxScarcityBoostUnified,
                   minVal: 0.00035112353681182863,
                   maxVal: 0.00047505153681182863)
        
        maybeShift(key: "GlobalMacroHedge",
                   isOn: simSettings.useGlobalMacroHedgeWeekly,
                   oldValue: &simSettings.maxMacroBoostUnified,
                   minVal: 0.0002868789724932909,
                   maxVal: 0.0004126829724932909)
        
        maybeShift(key: "StablecoinShift",
                   isOn: simSettings.useStablecoinShiftWeekly,
                   oldValue: &simSettings.maxStablecoinBoostUnified,
                   minVal: 0.0002704809116327763,
                   maxVal: 0.0003919609116327763)
        
        maybeShift(key: "DemographicAdoption",
                   isOn: simSettings.useDemographicAdoptionWeekly,
                   oldValue: &simSettings.maxDemoBoostUnified,
                   minVal: 0.0008661432036626339,
                   maxVal: 0.0012578432036626339)
        
        maybeShift(key: "AltcoinFlight",
                   isOn: simSettings.useAltcoinFlightWeekly,
                   oldValue: &simSettings.maxAltcoinBoostUnified,
                   minVal: 0.0002381864461803342,
                   maxVal: 0.0003222524461803342)
        
        maybeShift(key: "AdoptionFactor",
                   isOn: simSettings.useAdoptionFactorWeekly,
                   oldValue: &simSettings.adoptionBaseFactorUnified,
                   minVal: 0.0013638349088897705,
                   maxVal: 0.0018451869088897705)
        
        // ---------------- BEARISH FACTORS ----------------
        maybeShift(key: "RegClampdown",
                   isOn: simSettings.useRegClampdownWeekly,
                   oldValue: &simSettings.maxClampDownUnified,
                   minVal: -0.0014273392243542672,
                   maxVal: -0.0008449512243542672)
        
        maybeShift(key: "CompetitorCoin",
                   isOn: simSettings.useCompetitorCoinWeekly,
                   oldValue: &simSettings.maxCompetitorBoostUnified,
                   minVal: -0.0011842141746411323,
                   maxVal: -0.0008454221746411323)
        
        maybeShift(key: "SecurityBreach",
                   isOn: simSettings.useSecurityBreachWeekly,
                   oldValue: &simSettings.breachImpactUnified,
                   minVal: -0.0012819675168380737,
                   maxVal: -0.0009009755168380737)
        
        maybeShift(key: "BubblePop",
                   isOn: simSettings.useBubblePopWeekly,
                   oldValue: &simSettings.maxPopDropUnified,
                   minVal: -0.002244817890762329,
                   maxVal: -0.001280529890762329)
        
        maybeShift(key: "StablecoinMeltdown",
                   isOn: simSettings.useStablecoinMeltdownWeekly,
                   oldValue: &simSettings.maxMeltdownDropUnified,
                   minVal: -0.0009681346159477233,
                   maxVal: -0.0004600706159477233)
        
        maybeShift(key: "BlackSwan",
                   isOn: simSettings.useBlackSwanWeekly,
                   oldValue: &simSettings.blackSwanDropUnified,
                   minVal: -0.478662,
                   maxVal: -0.319108)
        
        maybeShift(key: "BearMarket",
                   isOn: simSettings.useBearMarketWeekly,
                   oldValue: &simSettings.bearWeeklyDriftUnified,
                   minVal: -0.0010278802752494812,
                   maxVal: -0.0007278802752494812)
        
        maybeShift(key: "MaturingMarket",
                   isOn: simSettings.useMaturingMarketWeekly,
                   oldValue: &simSettings.maxMaturingDropUnified,
                   minVal: -0.0020343461055486196,
                   maxVal: -0.0010537001055486196)
        
        maybeShift(key: "Recession",
                   isOn: simSettings.useRecessionWeekly,
                   oldValue: &simSettings.maxRecessionDropUnified,
                   minVal: -0.0010516462467487811,
                   maxVal: -0.0007494520467487811)
    }
    
    /// Same as before, but now every toggled-on factor can truly reach min or max.
    func updateUniversalFactorIntensity() {
        
        var totalWeightedNorm = 0.0
        var totalFrac = 0.0
        
        func accumulateFactor(
            key: String,
            isOn: Bool,
            value: Double,
            minVal: Double,
            maxVal: Double
        ) {
            guard isOn else { return }
            let frac = simSettings.factorEnableFrac[key] ?? 0.0
            guard frac > 0 else { return }
            
            let norm = (value - minVal) / (maxVal - minVal)  // 0..1
            totalWeightedNorm += norm * frac
            totalFrac += frac
        }
        
        // --- BULLISH ---
        accumulateFactor(key: "Halving",
                         isOn: simSettings.useHalvingWeekly,
                         value: simSettings.halvingBumpUnified,
                         minVal: 0.2773386887,
                         maxVal: 0.3823386887)
        
        accumulateFactor(key: "InstitutionalDemand",
                         isOn: simSettings.useInstitutionalDemandWeekly,
                         value: simSettings.maxDemandBoostUnified,
                         minVal: 0.00105315,
                         maxVal: 0.00142485)
        
        accumulateFactor(key: "CountryAdoption",
                         isOn: simSettings.useCountryAdoptionWeekly,
                         value: simSettings.maxCountryAdBoostUnified,
                         minVal: 0.0009882799977,
                         maxVal: 0.0012868959977)
        
        accumulateFactor(key: "RegulatoryClarity",
                         isOn: simSettings.useRegulatoryClarityWeekly,
                         value: simSettings.maxClarityBoostUnified,
                         minVal: 0.0005979474861605167,
                         maxVal: 0.0008361034861605167)
        
        accumulateFactor(key: "EtfApproval",
                         isOn: simSettings.useEtfApprovalWeekly,
                         value: simSettings.maxEtfBoostUnified,
                         minVal: 0.0014880183160305023,
                         maxVal: 0.0020880183160305023)
        
        accumulateFactor(key: "TechBreakthrough",
                         isOn: simSettings.useTechBreakthroughWeekly,
                         value: simSettings.maxTechBoostUnified,
                         minVal: 0.0005015753579173088,
                         maxVal: 0.0007150633579173088)
        
        accumulateFactor(key: "ScarcityEvents",
                         isOn: simSettings.useScarcityEventsWeekly,
                         value: simSettings.maxScarcityBoostUnified,
                         minVal: 0.00035112353681182863,
                         maxVal: 0.00047505153681182863)
        
        accumulateFactor(key: "GlobalMacroHedge",
                         isOn: simSettings.useGlobalMacroHedgeWeekly,
                         value: simSettings.maxMacroBoostUnified,
                         minVal: 0.0002868789724932909,
                         maxVal: 0.0004126829724932909)
        
        accumulateFactor(key: "StablecoinShift",
                         isOn: simSettings.useStablecoinShiftWeekly,
                         value: simSettings.maxStablecoinBoostUnified,
                         minVal: 0.0002704809116327763,
                         maxVal: 0.0003919609116327763)
        
        accumulateFactor(key: "DemographicAdoption",
                         isOn: simSettings.useDemographicAdoptionWeekly,
                         value: simSettings.maxDemoBoostUnified,
                         minVal: 0.0008661432036626339,
                         maxVal: 0.0012578432036626339)
        
        accumulateFactor(key: "AltcoinFlight",
                         isOn: simSettings.useAltcoinFlightWeekly,
                         value: simSettings.maxAltcoinBoostUnified,
                         minVal: 0.0002381864461803342,
                         maxVal: 0.0003222524461803342)
        
        accumulateFactor(key: "AdoptionFactor",
                         isOn: simSettings.useAdoptionFactorWeekly,
                         value: simSettings.adoptionBaseFactorUnified,
                         minVal: 0.0013638349088897705,
                         maxVal: 0.0018451869088897705)
        
        // --- BEARISH ---
        accumulateFactor(key: "RegClampdown",
                         isOn: simSettings.useRegClampdownWeekly,
                         value: simSettings.maxClampDownUnified,
                         minVal: -0.0014273392243542672,
                         maxVal: -0.0008449512243542672)
        
        accumulateFactor(key: "CompetitorCoin",
                         isOn: simSettings.useCompetitorCoinWeekly,
                         value: simSettings.maxCompetitorBoostUnified,
                         minVal: -0.0011842141746411323,
                         maxVal: -0.0008454221746411323)
        
        accumulateFactor(key: "SecurityBreach",
                         isOn: simSettings.useSecurityBreachWeekly,
                         value: simSettings.breachImpactUnified,
                         minVal: -0.0012819675168380737,
                         maxVal: -0.0009009755168380737)
        
        accumulateFactor(key: "BubblePop",
                         isOn: simSettings.useBubblePopWeekly,
                         value: simSettings.maxPopDropUnified,
                         minVal: -0.002244817890762329,
                         maxVal: -0.001280529890762329)
        
        accumulateFactor(key: "StablecoinMeltdown",
                         isOn: simSettings.useStablecoinMeltdownWeekly,
                         value: simSettings.maxMeltdownDropUnified,
                         minVal: -0.0009681346159477233,
                         maxVal: -0.0004600706159477233)
        
        accumulateFactor(key: "BlackSwan",
                         isOn: simSettings.useBlackSwanWeekly,
                         value: simSettings.blackSwanDropUnified,
                         minVal: -0.478662,
                         maxVal: -0.319108)
        
        accumulateFactor(key: "BearMarket",
                         isOn: simSettings.useBearMarketWeekly,
                         value: simSettings.bearWeeklyDriftUnified,
                         minVal: -0.0010278802752494812,
                         maxVal: -0.0007278802752494812)
        
        accumulateFactor(key: "MaturingMarket",
                         isOn: simSettings.useMaturingMarketWeekly,
                         value: simSettings.maxMaturingDropUnified,
                         minVal: -0.0020343461055486196,
                         maxVal: -0.0010537001055486196)
        
        accumulateFactor(key: "Recession",
                         isOn: simSettings.useRecessionWeekly,
                         value: simSettings.maxRecessionDropUnified,
                         minVal: -0.0010516462467487811,
                         maxVal: -0.0007494520467487811)
        
        // If none are on, do nothing
        guard totalFrac > 0 else { return }
        
        // Weighted average in 0..1
        let newIntensity = totalWeightedNorm / totalFrac
        simSettings.factorIntensity = newIntensity
    }
    
    /// Animate factor on/off (unchanged).
    func animateFactor(_ key: String, isOn: Bool) {
        if isOn {
            withAnimation(.easeInOut(duration: 0.6)) {
                simSettings.factorEnableFrac[key] = lastFactorFrac[key] ?? 1.0
            }
        } else {
            lastFactorFrac[key] = simSettings.factorEnableFrac[key] ?? 1.0
            withAnimation(.easeInOut(duration: 0.6)) {
                simSettings.factorEnableFrac[key] = 0
            }
        }
    }
    
    /// Sync factor’s value to `simSettings.factorIntensity` (unchanged).
    private func syncSingleFactorWithSlider(_ factorKey: String) {
        switch factorKey {
        // BULLISH
        case "Halving":
            syncFactorToSlider(&simSettings.halvingBumpUnified,
                               minVal: 0.2773386887,
                               maxVal: 0.3823386887,
                               simSettings: simSettings)
        case "InstitutionalDemand":
            syncFactorToSlider(&simSettings.maxDemandBoostUnified,
                               minVal: 0.00105315,
                               maxVal: 0.00142485,
                               simSettings: simSettings)
        case "CountryAdoption":
            syncFactorToSlider(&simSettings.maxCountryAdBoostUnified,
                               minVal: 0.0009882799977,
                               maxVal: 0.0012868959977,
                               simSettings: simSettings)
        case "RegulatoryClarity":
            syncFactorToSlider(&simSettings.maxClarityBoostUnified,
                               minVal: 0.0005979474861605167,
                               maxVal: 0.0008361034861605167,
                               simSettings: simSettings)
        case "EtfApproval":
            syncFactorToSlider(&simSettings.maxEtfBoostUnified,
                               minVal: 0.0014880183160305023,
                               maxVal: 0.0020880183160305023,
                               simSettings: simSettings)
        case "TechBreakthrough":
            syncFactorToSlider(&simSettings.maxTechBoostUnified,
                               minVal: 0.0005015753579173088,
                               maxVal: 0.0007150633579173088,
                               simSettings: simSettings)
        case "ScarcityEvents":
            syncFactorToSlider(&simSettings.maxScarcityBoostUnified,
                               minVal: 0.00035112353681182863,
                               maxVal: 0.00047505153681182863,
                               simSettings: simSettings)
        case "GlobalMacroHedge":
            syncFactorToSlider(&simSettings.maxMacroBoostUnified,
                               minVal: 0.0002868789724932909,
                               maxVal: 0.0004126829724932909,
                               simSettings: simSettings)
        case "StablecoinShift":
            syncFactorToSlider(&simSettings.maxStablecoinBoostUnified,
                               minVal: 0.0002704809116327763,
                               maxVal: 0.0003919609116327763,
                               simSettings: simSettings)
        case "DemographicAdoption":
            syncFactorToSlider(&simSettings.maxDemoBoostUnified,
                               minVal: 0.0008661432036626339,
                               maxVal: 0.0012578432036626339,
                               simSettings: simSettings)
        case "AltcoinFlight":
            syncFactorToSlider(&simSettings.maxAltcoinBoostUnified,
                               minVal: 0.0002381864461803342,
                               maxVal: 0.0003222524461803342,
                               simSettings: simSettings)
        case "AdoptionFactor":
            syncFactorToSlider(&simSettings.adoptionBaseFactorUnified,
                               minVal: 0.0013638349088897705,
                               maxVal: 0.0018451869088897705,
                               simSettings: simSettings)
        
        // BEARISH
        case "RegClampdown":
            syncFactorToSlider(&simSettings.maxClampDownUnified,
                               minVal: -0.0014273392243542672,
                               maxVal: -0.0008449512243542672,
                               simSettings: simSettings)
        case "CompetitorCoin":
            syncFactorToSlider(&simSettings.maxCompetitorBoostUnified,
                               minVal: -0.0011842141746411323,
                               maxVal: -0.0008454221746411323,
                               simSettings: simSettings)
        case "SecurityBreach":
            syncFactorToSlider(&simSettings.breachImpactUnified,
                               minVal: -0.0012819675168380737,
                               maxVal: -0.0009009755168380737,
                               simSettings: simSettings)
        case "BubblePop":
            syncFactorToSlider(&simSettings.maxPopDropUnified,
                               minVal: -0.002244817890762329,
                               maxVal: -0.001280529890762329,
                               simSettings: simSettings)
        case "StablecoinMeltdown":
            syncFactorToSlider(&simSettings.maxMeltdownDropUnified,
                               minVal: -0.0009681346159477233,
                               maxVal: -0.0004600706159477233,
                               simSettings: simSettings)
        case "BlackSwan":
            syncFactorToSlider(&simSettings.blackSwanDropUnified,
                               minVal: -0.478662,
                               maxVal: -0.319108,
                               simSettings: simSettings)
        case "BearMarket":
            syncFactorToSlider(&simSettings.bearWeeklyDriftUnified,
                               minVal: -0.0010278802752494812,
                               maxVal: -0.0007278802752494812,
                               simSettings: simSettings)
        case "MaturingMarket":
            syncFactorToSlider(&simSettings.maxMaturingDropUnified,
                               minVal: -0.0020343461055486196,
                               maxVal: -0.0010537001055486196,
                               simSettings: simSettings)
        case "Recession":
            syncFactorToSlider(&simSettings.maxRecessionDropUnified,
                               minVal: -0.0010516462467487811,
                               maxVal: -0.0007494520467487811,
                               simSettings: simSettings)
        default:
            break
        }
    }
}

/// Unchanged helper that sets `currentValue` in [minVal, maxVal]
/// based on `simSettings.factorIntensity`.
func syncFactorToSlider(
    _ currentValue: inout Double,
    minVal: Double,
    maxVal: Double,
    simSettings: SimulationSettings
) {
    let t = simSettings.factorIntensity
    currentValue = minVal + t * (maxVal - minVal)
}
    
