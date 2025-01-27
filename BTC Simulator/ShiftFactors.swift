//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    /// Shift all factors based on `delta` only, ignoring the factorEnableFrac toggles.
    /// Clamps each factor to its allowed [minVal...maxVal] range.
    func shiftAllFactors(by delta: Double) {
        
        func clamp(_ x: Double, minVal: Double, maxVal: Double) -> Double {
            let lower = min(minVal, maxVal)
            let upper = max(minVal, maxVal)
            return max(lower, min(upper, x))
        }
        
        /// Moves `oldValue` by `delta * (maxVal - minVal)`.
        /// No fraction-based toggle scaling here; toggles are handled in net tilt.
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
        
        // ---------------- BULLISH FACTORS ----------------
        shiftFactor(oldValue: &simSettings.halvingBumpUnified,
                    minVal: 0.2773386887,
                    maxVal: 0.3823386887)
        
        shiftFactor(oldValue: &simSettings.maxDemandBoostUnified,
                    minVal: 0.00105315,
                    maxVal: 0.00142485)
        
        shiftFactor(oldValue: &simSettings.maxCountryAdBoostUnified,
                    minVal: 0.0009882799977,
                    maxVal: 0.0012868959977)
        
        shiftFactor(oldValue: &simSettings.maxClarityBoostUnified,
                    minVal: 0.0005979474861605167,
                    maxVal: 0.0008361034861605167)
        
        shiftFactor(oldValue: &simSettings.maxEtfBoostUnified,
                    minVal: 0.0014880183160305023,
                    maxVal: 0.0020880183160305023)
        
        shiftFactor(oldValue: &simSettings.maxTechBoostUnified,
                    minVal: 0.0005015753579173088,
                    maxVal: 0.0007150633579173088)
        
        shiftFactor(oldValue: &simSettings.maxScarcityBoostUnified,
                    minVal: 0.00035112353681182863,
                    maxVal: 0.00047505153681182863)
        
        shiftFactor(oldValue: &simSettings.maxMacroBoostUnified,
                    minVal: 0.0002868789724932909,
                    maxVal: 0.0004126829724932909)
        
        shiftFactor(oldValue: &simSettings.maxStablecoinBoostUnified,
                    minVal: 0.0002704809116327763,
                    maxVal: 0.0003919609116327763)
        
        shiftFactor(oldValue: &simSettings.maxDemoBoostUnified,
                    minVal: 0.0008661432036626339,
                    maxVal: 0.0012578432036626339)
        
        shiftFactor(oldValue: &simSettings.maxAltcoinBoostUnified,
                    minVal: 0.0002381864461803342,
                    maxVal: 0.0003222524461803342)
        
        shiftFactor(oldValue: &simSettings.adoptionBaseFactorUnified,
                    minVal: 0.0013638349088897705,
                    maxVal: 0.0018451869088897705)
        
        // ---------------- BEARISH FACTORS ----------------
        shiftFactor(oldValue: &simSettings.maxClampDownUnified,
                    minVal: -0.0014273392243542672,
                    maxVal: -0.0008449512243542672)
        
        shiftFactor(oldValue: &simSettings.maxCompetitorBoostUnified,
                    minVal: -0.0011842141746411323,
                    maxVal: -0.0008454221746411323)
        
        shiftFactor(oldValue: &simSettings.breachImpactUnified,
                    minVal: -0.0012819675168380737,
                    maxVal: -0.0009009755168380737)
        
        shiftFactor(oldValue: &simSettings.maxPopDropUnified,
                    minVal: -0.002244817890762329,
                    maxVal: -0.001280529890762329)
        
        shiftFactor(oldValue: &simSettings.maxMeltdownDropUnified,
                    minVal: -0.0009681346159477233,
                    maxVal: -0.0004600706159477233)
        
        shiftFactor(oldValue: &simSettings.blackSwanDropUnified,
                    minVal: -0.478662,
                    maxVal: -0.319108)
        
        shiftFactor(oldValue: &simSettings.bearWeeklyDriftUnified,
                    minVal: -0.0010278802752494812,
                    maxVal: -0.0007278802752494812)
        
        shiftFactor(oldValue: &simSettings.maxMaturingDropUnified,
                    minVal: -0.0020343461055486196,
                    maxVal: -0.0010537001055486196)
        
        shiftFactor(oldValue: &simSettings.maxRecessionDropUnified,
                    minVal: -0.0010516462467487811,
                    maxVal: -0.0007494520467487811)
    }
    
    /// Recompute the universal slider from each factor’s normalised position.
    /// (Note: This still checks booleans in `simSettings.useXxxUnified`.
    ///  If you’ve fully moved to fraction-based toggles, adapt accordingly.)
    func updateUniversalFactorIntensity() {
        var totalNormalised = 0.0
        var count = 0
        
        func normaliseBull(_ value: Double, _ minVal: Double, _ maxVal: Double) -> Double {
            (value - minVal) / (maxVal - minVal)
        }
        func normaliseBear(_ value: Double, _ minVal: Double, _ maxVal: Double) -> Double {
            (value - minVal) / (maxVal - minVal)
        }
        
        // --------------- BULLISH ---------------
        if simSettings.useHalvingUnified {
            totalNormalised += normaliseBull(
                simSettings.halvingBumpUnified,
                0.2773386887,
                0.3823386887
            )
            count += 1
        }
        if simSettings.useInstitutionalDemandUnified {
            totalNormalised += normaliseBull(
                simSettings.maxDemandBoostUnified,
                0.00105315,
                0.00142485
            )
            count += 1
        }
        if simSettings.useCountryAdoptionUnified {
            totalNormalised += normaliseBull(
                simSettings.maxCountryAdBoostUnified,
                0.0009882799977,
                0.0012868959977
            )
            count += 1
        }
        if simSettings.useRegulatoryClarityUnified {
            totalNormalised += normaliseBull(
                simSettings.maxClarityBoostUnified,
                0.0005979474861605167,
                0.0008361034861605167
            )
            count += 1
        }
        if simSettings.useEtfApprovalUnified {
            totalNormalised += normaliseBull(
                simSettings.maxEtfBoostUnified,
                0.0014880183160305023,
                0.0020880183160305023
            )
            count += 1
        }
        if simSettings.useTechBreakthroughUnified {
            totalNormalised += normaliseBull(
                simSettings.maxTechBoostUnified,
                0.0005015753579173088,
                0.0007150633579173088
            )
            count += 1
        }
        if simSettings.useScarcityEventsUnified {
            totalNormalised += normaliseBull(
                simSettings.maxScarcityBoostUnified,
                0.00035112353681182863,
                0.00047505153681182863
            )
            count += 1
        }
        if simSettings.useGlobalMacroHedgeUnified {
            totalNormalised += normaliseBull(
                simSettings.maxMacroBoostUnified,
                0.0002868789724932909,
                0.0004126829724932909
            )
            count += 1
        }
        if simSettings.useStablecoinShiftUnified {
            totalNormalised += normaliseBull(
                simSettings.maxStablecoinBoostUnified,
                0.0002704809116327763,
                0.0003919609116327763
            )
            count += 1
        }
        if simSettings.useDemographicAdoptionUnified {
            totalNormalised += normaliseBull(
                simSettings.maxDemoBoostUnified,
                0.0008661432036626339,
                0.0012578432036626339
            )
            count += 1
        }
        if simSettings.useAltcoinFlightUnified {
            totalNormalised += normaliseBull(
                simSettings.maxAltcoinBoostUnified,
                0.0002381864461803342,
                0.0003222524461803342
            )
            count += 1
        }
        if simSettings.useAdoptionFactorUnified {
            totalNormalised += normaliseBull(
                simSettings.adoptionBaseFactorUnified,
                0.0013638349088897705,
                0.0018451869088897705
            )
            count += 1
        }

        
        // --------------- BEARISH ---------------
        if simSettings.useRegClampdownUnified {
            totalNormalised += normaliseBear(
                simSettings.maxClampDownUnified,
                -0.0014273392243542672,
                -0.0008449512243542672
            )
            count += 1
        }
        if simSettings.useCompetitorCoinUnified {
            totalNormalised += normaliseBear(
                simSettings.maxCompetitorBoostUnified,
                -0.0011842141746411323,
                -0.0008454221746411323
            )
            count += 1
        }
        if simSettings.useSecurityBreachUnified {
            totalNormalised += normaliseBear(
                simSettings.breachImpactUnified,
                -0.0012819675168380737,
                -0.0009009755168380737
            )
            count += 1
        }
        if simSettings.useBubblePopUnified {
            totalNormalised += normaliseBear(
                simSettings.maxPopDropUnified,
                -0.002244817890762329,
                -0.001280529890762329
            )
            count += 1
        }
        if simSettings.useStablecoinMeltdownUnified {
            totalNormalised += normaliseBear(
                simSettings.maxMeltdownDropUnified,
                -0.0009681346159477233,
                -0.0004600706159477233
            )
            count += 1
        }
        if simSettings.useBlackSwanUnified {
            totalNormalised += normaliseBear(
                simSettings.blackSwanDropUnified,
                -0.478662,
                -0.319108
            )
            count += 1
        }
        if simSettings.useBearMarketUnified {
            totalNormalised += normaliseBear(
                simSettings.bearWeeklyDriftUnified,
                -0.0010278802752494812,
                -0.0007278802752494812
            )
            count += 1
        }
        if simSettings.useMaturingMarketUnified {
            totalNormalised += normaliseBear(
                simSettings.maxMaturingDropUnified,
                -0.0020343461055486196,
                -0.0010537001055486196
            )
            count += 1
        }
        if simSettings.useRecessionUnified {
            totalNormalised += normaliseBear(
                simSettings.maxRecessionDropUnified,
                -0.0010516462467487811,
                -0.0007494520467487811
            )
            count += 1
        }

        
        guard count > 0 else { return }
        let average = totalNormalised / Double(count)
        
        factorIntensity = average
        oldFactorIntensity = average
    }
    
    /// Sync a single factor to the current universal slider (avoiding jumps).
    /// This sets the factor’s underlying value based on the global `factorIntensity`
    /// so it lines up with the same proportion [minVal...maxVal].
    private func syncSingleFactorWithSlider(_ key: String) {
        switch key {
            
        // ------------------ BULLISH FACTORS ------------------
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
            
        // ------------------ BEARISH FACTORS ------------------
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
    
    /// Helper used in syncSingleFactorWithSlider
    private func syncFactorToSlider(_ currentValue: inout Double,
                                    minVal: Double,
                                    maxVal: Double) {
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
                factorEnableFrac[key] = 0
            }
        }
        // Now animate from 0..1 or 1..0
        withAnimation(.easeInOut(duration: 0.6)) {
            factorEnableFrac[key] = isOn ? 1 : 0
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
