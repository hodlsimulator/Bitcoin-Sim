//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    /// Shift all factors based on `delta`, **but only if** their fraction > 0.
    /// That way, factors turned off remain at their last value.
    func shiftAllFactors(by delta: Double) {
        
        func clamp(_ x: Double, minVal: Double, maxVal: Double) -> Double {
            let lower = min(minVal, maxVal)
            let upper = max(minVal, maxVal)
            return max(lower, min(upper, x))
        }
        
        /// Moves `oldValue` by `delta * (maxVal - minVal)`.
        /// Ignores fraction-based scaling — toggles are handled separately.
        func shiftFactor(
            oldValue: inout Double,
            minVal: Double,
            maxVal: Double
        ) {
            let range = maxVal - minVal
            let newValue = clamp(oldValue + delta * range,
                                 minVal: minVal,
                                 maxVal: maxVal)
            // Update only if the difference is significant
            if abs(newValue - oldValue) > 1e-7 {
                oldValue = newValue
            }
        }
        
        // A helper: only shift the factor if fraction > 0
        func maybeShift(key: String,
                        oldValue: inout Double,
                        minVal: Double,
                        maxVal: Double) {
            let frac = simSettings.factorEnableFrac[key] ?? 0.0
            // If toggled off (fraction=0), skip shifting so it stays at last value
            if frac > 0 {
                shiftFactor(oldValue: &oldValue, minVal: minVal, maxVal: maxVal)
            }
        }
        
        // ---------------- BULLISH FACTORS ----------------
        maybeShift(key: "Halving",
                   oldValue: &simSettings.halvingBumpUnified,
                   minVal: 0.2773386887,
                   maxVal: 0.3823386887)
        
        maybeShift(key: "InstitutionalDemand",
                   oldValue: &simSettings.maxDemandBoostUnified,
                   minVal: 0.00105315,
                   maxVal: 0.00142485)
        
        maybeShift(key: "CountryAdoption",
                   oldValue: &simSettings.maxCountryAdBoostUnified,
                   minVal: 0.0009882799977,
                   maxVal: 0.0012868959977)
        
        maybeShift(key: "RegulatoryClarity",
                   oldValue: &simSettings.maxClarityBoostUnified,
                   minVal: 0.0005979474861605167,
                   maxVal: 0.0008361034861605167)
        
        maybeShift(key: "EtfApproval",
                   oldValue: &simSettings.maxEtfBoostUnified,
                   minVal: 0.0014880183160305023,
                   maxVal: 0.0020880183160305023)
        
        maybeShift(key: "TechBreakthrough",
                   oldValue: &simSettings.maxTechBoostUnified,
                   minVal: 0.0005015753579173088,
                   maxVal: 0.0007150633579173088)
        
        maybeShift(key: "ScarcityEvents",
                   oldValue: &simSettings.maxScarcityBoostUnified,
                   minVal: 0.00035112353681182863,
                   maxVal: 0.00047505153681182863)
        
        maybeShift(key: "GlobalMacroHedge",
                   oldValue: &simSettings.maxMacroBoostUnified,
                   minVal: 0.0002868789724932909,
                   maxVal: 0.0004126829724932909)
        
        maybeShift(key: "StablecoinShift",
                   oldValue: &simSettings.maxStablecoinBoostUnified,
                   minVal: 0.0002704809116327763,
                   maxVal: 0.0003919609116327763)
        
        maybeShift(key: "DemographicAdoption",
                   oldValue: &simSettings.maxDemoBoostUnified,
                   minVal: 0.0008661432036626339,
                   maxVal: 0.0012578432036626339)
        
        maybeShift(key: "AltcoinFlight",
                   oldValue: &simSettings.maxAltcoinBoostUnified,
                   minVal: 0.0002381864461803342,
                   maxVal: 0.0003222524461803342)
        
        maybeShift(key: "AdoptionFactor",
                   oldValue: &simSettings.adoptionBaseFactorUnified,
                   minVal: 0.0013638349088897705,
                   maxVal: 0.0018451869088897705)
        
        // ---------------- BEARISH FACTORS ----------------
        maybeShift(key: "RegClampdown",
                   oldValue: &simSettings.maxClampDownUnified,
                   minVal: -0.0014273392243542672,
                   maxVal: -0.0008449512243542672)
        
        maybeShift(key: "CompetitorCoin",
                   oldValue: &simSettings.maxCompetitorBoostUnified,
                   minVal: -0.0011842141746411323,
                   maxVal: -0.0008454221746411323)
        
        maybeShift(key: "SecurityBreach",
                   oldValue: &simSettings.breachImpactUnified,
                   minVal: -0.0012819675168380737,
                   maxVal: -0.0009009755168380737)
        
        maybeShift(key: "BubblePop",
                   oldValue: &simSettings.maxPopDropUnified,
                   minVal: -0.002244817890762329,
                   maxVal: -0.001280529890762329)
        
        maybeShift(key: "StablecoinMeltdown",
                   oldValue: &simSettings.maxMeltdownDropUnified,
                   minVal: -0.0009681346159477233,
                   maxVal: -0.0004600706159477233)
        
        maybeShift(key: "BlackSwan",
                   oldValue: &simSettings.blackSwanDropUnified,
                   minVal: -0.478662,
                   maxVal: -0.319108)
        
        maybeShift(key: "BearMarket",
                   oldValue: &simSettings.bearWeeklyDriftUnified,
                   minVal: -0.0010278802752494812,
                   maxVal: -0.0007278802752494812)
        
        maybeShift(key: "MaturingMarket",
                   oldValue: &simSettings.maxMaturingDropUnified,
                   minVal: -0.0020343461055486196,
                   maxVal: -0.0010537001055486196)
        
        maybeShift(key: "Recession",
                   oldValue: &simSettings.maxRecessionDropUnified,
                   minVal: -0.0010516462467487811,
                   maxVal: -0.0007494520467487811)
    }
    
    /// Recompute the universal slider from the active factors only,
    /// using their fraction (0..1). If fraction=0, that factor is ignored.
    /// This yields an average "intensity" across all toggled-on factors.
    func updateUniversalFactorIntensity() {
        
        var totalWeightedNorm = 0.0  // sum of (normalised * fraction)
        var totalFrac = 0.0         // sum of fractions
        
        // Helper to normalise and add partial fraction
        func accumulateFactor(factorKey: String,
                              value: Double,
                              minVal: Double,
                              maxVal: Double)
        {
            let frac = simSettings.factorEnableFrac[factorKey] ?? 0.0
            if frac > 0 {
                // normalise factor's current value to 0..1
                let norm = (value - minVal) / (maxVal - minVal)
                totalWeightedNorm += norm * frac
                totalFrac += frac
            }
        }
        
        // --- BULLISH FACTORS ---
        accumulateFactor(factorKey: "Halving",
                         value: simSettings.halvingBumpUnified,
                         minVal: 0.2773386887,
                         maxVal: 0.3823386887)
        
        accumulateFactor(factorKey: "InstitutionalDemand",
                         value: simSettings.maxDemandBoostUnified,
                         minVal: 0.00105315,
                         maxVal: 0.00142485)
        
        accumulateFactor(factorKey: "CountryAdoption",
                         value: simSettings.maxCountryAdBoostUnified,
                         minVal: 0.0009882799977,
                         maxVal: 0.0012868959977)
        
        accumulateFactor(factorKey: "RegulatoryClarity",
                         value: simSettings.maxClarityBoostUnified,
                         minVal: 0.0005979474861605167,
                         maxVal: 0.0008361034861605167)
        
        accumulateFactor(factorKey: "EtfApproval",
                         value: simSettings.maxEtfBoostUnified,
                         minVal: 0.0014880183160305023,
                         maxVal: 0.0020880183160305023)
        
        accumulateFactor(factorKey: "TechBreakthrough",
                         value: simSettings.maxTechBoostUnified,
                         minVal: 0.0005015753579173088,
                         maxVal: 0.0007150633579173088)
        
        accumulateFactor(factorKey: "ScarcityEvents",
                         value: simSettings.maxScarcityBoostUnified,
                         minVal: 0.00035112353681182863,
                         maxVal: 0.00047505153681182863)
        
        accumulateFactor(factorKey: "GlobalMacroHedge",
                         value: simSettings.maxMacroBoostUnified,
                         minVal: 0.0002868789724932909,
                         maxVal: 0.0004126829724932909)
        
        accumulateFactor(factorKey: "StablecoinShift",
                         value: simSettings.maxStablecoinBoostUnified,
                         minVal: 0.0002704809116327763,
                         maxVal: 0.0003919609116327763)
        
        accumulateFactor(factorKey: "DemographicAdoption",
                         value: simSettings.maxDemoBoostUnified,
                         minVal: 0.0008661432036626339,
                         maxVal: 0.0012578432036626339)
        
        accumulateFactor(factorKey: "AltcoinFlight",
                         value: simSettings.maxAltcoinBoostUnified,
                         minVal: 0.0002381864461803342,
                         maxVal: 0.0003222524461803342)
        
        accumulateFactor(factorKey: "AdoptionFactor",
                         value: simSettings.adoptionBaseFactorUnified,
                         minVal: 0.0013638349088897705,
                         maxVal: 0.0018451869088897705)
        
        // --- BEARISH FACTORS ---
        accumulateFactor(factorKey: "RegClampdown",
                         value: simSettings.maxClampDownUnified,
                         minVal: -0.0014273392243542672,
                         maxVal: -0.0008449512243542672)
        
        accumulateFactor(factorKey: "CompetitorCoin",
                         value: simSettings.maxCompetitorBoostUnified,
                         minVal: -0.0011842141746411323,
                         maxVal: -0.0008454221746411323)
        
        accumulateFactor(factorKey: "SecurityBreach",
                         value: simSettings.breachImpactUnified,
                         minVal: -0.0012819675168380737,
                         maxVal: -0.0009009755168380737)
        
        accumulateFactor(factorKey: "BubblePop",
                         value: simSettings.maxPopDropUnified,
                         minVal: -0.002244817890762329,
                         maxVal: -0.001280529890762329)
        
        accumulateFactor(factorKey: "StablecoinMeltdown",
                         value: simSettings.maxMeltdownDropUnified,
                         minVal: -0.0009681346159477233,
                         maxVal: -0.0004600706159477233)
        
        accumulateFactor(factorKey: "BlackSwan",
                         value: simSettings.blackSwanDropUnified,
                         minVal: -0.478662,
                         maxVal: -0.319108)
        
        accumulateFactor(factorKey: "BearMarket",
                         value: simSettings.bearWeeklyDriftUnified,
                         minVal: -0.0010278802752494812,
                         maxVal: -0.0007278802752494812)
        
        accumulateFactor(factorKey: "MaturingMarket",
                         value: simSettings.maxMaturingDropUnified,
                         minVal: -0.0020343461055486196,
                         maxVal: -0.0010537001055486196)
        
        accumulateFactor(factorKey: "Recession",
                         value: simSettings.maxRecessionDropUnified,
                         minVal: -0.0010516462467487811,
                         maxVal: -0.0007494520467487811)
        
        // If nothing is toggled on, do nothing
        guard totalFrac > 0 else { return }
        
        // Weighted average of 0..1 across toggled-on factors
        let newIntensity = totalWeightedNorm / totalFrac
        
        factorIntensity = newIntensity
        oldFactorIntensity = newIntensity
    }
    
    /// Sync a single factor to the current universal slider (avoiding jumps).
    /// This sets the factor’s underlying value based on the global `factorIntensity`
    /// so it lines up with the same proportion [minVal...maxVal].
    private func syncSingleFactorWithSlider(_ currentValue: inout Double,
                                            minVal: Double,
                                            maxVal: Double)
    {
        let t = factorIntensity
        currentValue = minVal + t * (maxVal - minVal)
    }
    
    /// Animate turning a factor on/off. (For partial S-curve transitions, you might adapt.)
    func animateFactor(_ key: String, isOn: Bool) {
        withAnimation(.none) {
            if isOn {
                // Re-sync factor’s internal value to the universal slider
                syncSingleFactorWithSlider(key)
                // Force fraction to zero momentarily, no animation
                simSettings.factorEnableFrac[key] = 0
            }
        }
        // Now animate from 0..1 or 1..0
        withAnimation(.easeInOut(duration: 0.6)) {
            simSettings.factorEnableFrac[key] = isOn ? 1 : 0
        }
    }
    
    /// Actually sync that factor's numeric "unified" value:
    private func syncSingleFactorWithSlider(_ factorKey: String) {
        // Dispatch to the same logic above, but pick correct min/max
        switch factorKey {
            
        // BULLISH
        case "Halving":
            syncFactorToSlider(&simSettings.halvingBumpUnified,
                               minVal: 0.2773386887,
                               maxVal: 0.3823386887)
        case "InstitutionalDemand":
            syncFactorToSlider(&simSettings.maxDemandBoostUnified,
                               minVal: 0.00105315,
                               maxVal: 0.00142485)
        case "CountryAdoption":
            syncFactorToSlider(&simSettings.maxCountryAdBoostUnified,
                               minVal: 0.0009882799977,
                               maxVal: 0.0012868959977)
        case "RegulatoryClarity":
            syncFactorToSlider(&simSettings.maxClarityBoostUnified,
                               minVal: 0.0005979474861605167,
                               maxVal: 0.0008361034861605167)
        case "EtfApproval":
            syncFactorToSlider(&simSettings.maxEtfBoostUnified,
                               minVal: 0.0014880183160305023,
                               maxVal: 0.0020880183160305023)
        case "TechBreakthrough":
            syncFactorToSlider(&simSettings.maxTechBoostUnified,
                               minVal: 0.0005015753579173088,
                               maxVal: 0.0007150633579173088)
        case "ScarcityEvents":
            syncFactorToSlider(&simSettings.maxScarcityBoostUnified,
                               minVal: 0.00035112353681182863,
                               maxVal: 0.00047505153681182863)
        case "GlobalMacroHedge":
            syncFactorToSlider(&simSettings.maxMacroBoostUnified,
                               minVal: 0.0002868789724932909,
                               maxVal: 0.0004126829724932909)
        case "StablecoinShift":
            syncFactorToSlider(&simSettings.maxStablecoinBoostUnified,
                               minVal: 0.0002704809116327763,
                               maxVal: 0.0003919609116327763)
        case "DemographicAdoption":
            syncFactorToSlider(&simSettings.maxDemoBoostUnified,
                               minVal: 0.0008661432036626339,
                               maxVal: 0.0012578432036626339)
        case "AltcoinFlight":
            syncFactorToSlider(&simSettings.maxAltcoinBoostUnified,
                               minVal: 0.0002381864461803342,
                               maxVal: 0.0003222524461803342)
        case "AdoptionFactor":
            syncFactorToSlider(&simSettings.adoptionBaseFactorUnified,
                               minVal: 0.0013638349088897705,
                               maxVal: 0.0018451869088897705)
            
        // BEARISH
        case "RegClampdown":
            syncFactorToSlider(&simSettings.maxClampDownUnified,
                               minVal: -0.0014273392243542672,
                               maxVal: -0.0008449512243542672)
        case "CompetitorCoin":
            syncFactorToSlider(&simSettings.maxCompetitorBoostUnified,
                               minVal: -0.0011842141746411323,
                               maxVal: -0.0008454221746411323)
        case "SecurityBreach":
            syncFactorToSlider(&simSettings.breachImpactUnified,
                               minVal: -0.0012819675168380737,
                               maxVal: -0.0009009755168380737)
        case "BubblePop":
            syncFactorToSlider(&simSettings.maxPopDropUnified,
                               minVal: -0.002244817890762329,
                               maxVal: -0.001280529890762329)
        case "StablecoinMeltdown":
            syncFactorToSlider(&simSettings.maxMeltdownDropUnified,
                               minVal: -0.0009681346159477233,
                               maxVal: -0.0004600706159477233)
        case "BlackSwan":
            syncFactorToSlider(&simSettings.blackSwanDropUnified,
                               minVal: -0.478662,
                               maxVal: -0.319108)
        case "BearMarket":
            syncFactorToSlider(&simSettings.bearWeeklyDriftUnified,
                               minVal: -0.0010278802752494812,
                               maxVal: -0.0007278802752494812)
        case "MaturingMarket":
            syncFactorToSlider(&simSettings.maxMaturingDropUnified,
                               minVal: -0.0020343461055486196,
                               maxVal: -0.0010537001055486196)
        case "Recession":
            syncFactorToSlider(&simSettings.maxRecessionDropUnified,
                               minVal: -0.0010516462467487811,
                               maxVal: -0.0007494520467487811)
        default:
            break
        }
    }
    
    /// Toggle the tooltip for a factor
    func toggleFactor(_ tappedTitle: String) {
        withAnimation {
            if activeFactor == tappedTitle {
                activeFactor = nil
            } else {
                activeFactor = tappedTitle
            }
        }
    }
}
