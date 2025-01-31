//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    // Helper to check if a given factor is toggled ON in simSettings.
    // (Matches your useXYZWeekly booleans.)
    private func isFactorEnabled(_ key: String) -> Bool {
        switch key {
            
            // BULLISH
        case "Halving":               return simSettings.useHalvingWeekly
        case "InstitutionalDemand":   return simSettings.useInstitutionalDemandWeekly
        case "CountryAdoption":       return simSettings.useCountryAdoptionWeekly
        case "RegulatoryClarity":     return simSettings.useRegulatoryClarityWeekly
        case "EtfApproval":           return simSettings.useEtfApprovalWeekly
        case "TechBreakthrough":      return simSettings.useTechBreakthroughWeekly
        case "ScarcityEvents":        return simSettings.useScarcityEventsWeekly
        case "GlobalMacroHedge":      return simSettings.useGlobalMacroHedgeWeekly
        case "StablecoinShift":       return simSettings.useStablecoinShiftWeekly
        case "DemographicAdoption":   return simSettings.useDemographicAdoptionWeekly
        case "AltcoinFlight":         return simSettings.useAltcoinFlightWeekly
        case "AdoptionFactor":        return simSettings.useAdoptionFactorWeekly
            
            // BEARISH
        case "RegClampdown":          return simSettings.useRegClampdownWeekly
        case "CompetitorCoin":        return simSettings.useCompetitorCoinWeekly
        case "SecurityBreach":        return simSettings.useSecurityBreachWeekly
        case "BubblePop":             return simSettings.useBubblePopWeekly
        case "StablecoinMeltdown":    return simSettings.useStablecoinMeltdownWeekly
        case "BlackSwan":             return simSettings.useBlackSwanWeekly
        case "BearMarket":            return simSettings.useBearMarketWeekly
        case "MaturingMarket":        return simSettings.useMaturingMarketWeekly
        case "Recession":             return simSettings.useRecessionWeekly
            
        default:
            return false
        }
    }
    
    /// Shift all factors by `delta`, but only if that factor is toggled on
    /// (via e.g. simSettings.useXYZWeekly). The fraction influences the *speed* at which it moves,
    /// but we no longer skip if fraction == 0. If the user explicitly toggles the factor off,
    /// then `isOn` will be false, which also skips the shift.
    func shiftAllFactors(by delta: Double) {
        
        // For convenience, clamp x into [minVal, maxVal].
        func clamp(_ x: Double, minVal: Double, maxVal: Double) -> Double {
            let lower = min(minVal, maxVal)
            let upper = max(minVal, maxVal)
            return max(lower, min(upper, x))
        }

        /// Shifts `oldValue` by `delta * range * fraction`, if factor is toggled on.
        /// `key` is the factor name, `isOn` is the real toggle, `oldValue` is mutated.
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
            
            if abs(newValue - oldValue) > 1e-7 {
                oldValue = newValue
            }
        }
        
        // ---------------- 1) SHIFT FRACTION VALUES IN factorEnableFrac ----------------
        // Bullish fraction range is 0..1
        for key in bullishKeys {
            if let oldFrac = simSettings.factorEnableFrac[key] {
                let toggledOn = isFactorEnabled(key)
                var mutableFrac = oldFrac
                maybeShift(key: key,
                           isOn: toggledOn,
                           oldValue: &mutableFrac,
                           minVal: 0.0,
                           maxVal: 1.0)
                simSettings.factorEnableFrac[key] = mutableFrac
            }
        }
        
        // Bearish fraction also stored in 0..1, even though the real numeric is negative
        for key in bearishKeys {
            if let oldFrac = simSettings.factorEnableFrac[key] {
                let toggledOn = isFactorEnabled(key)
                var mutableFrac = oldFrac
                maybeShift(key: key,
                           isOn: toggledOn,
                           oldValue: &mutableFrac,
                           minVal: 0.0,
                           maxVal: 1.0)
                simSettings.factorEnableFrac[key] = mutableFrac
            }
        }
        
        // ---------------- 2) SHIFT REAL NUMERIC VALUES (BULLISH) ----------------
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
        
        // ---------------- 3) SHIFT REAL NUMERIC VALUES (BEARISH) ----------------
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
    
    /// Update factorIntensity by scanning all toggled-on factors, computing a weighted average of their normalised positions.
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
            
            // Normalise value into 0..1
            let norm = (value - minVal) / (maxVal - minVal)
            totalWeightedNorm += norm * frac
            totalFrac += frac
        }
        
        // ---------- BULLISH ----------
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
        
        // ---------- BEARISH ----------
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
    
    /// Sync factor’s value to `simSettings.factorIntensity`.
    /// Provide it here so the compiler can see it.
    func syncFactorToSlider(
        _ currentValue: inout Double,
        minVal: Double,
        maxVal: Double,
        simSettings: SimulationSettings
    ) {
        let t = simSettings.factorIntensity
        currentValue = minVal + t * (maxVal - minVal)
    }
}
