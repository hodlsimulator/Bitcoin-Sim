//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    // Adds `delta * range * fraction` to each toggled-on factor, clamped to [minVal ... maxVal].
    func shiftAllFactors(by delta: Double) {
        func clamp(_ x: Double, minVal: Double, maxVal: Double) -> Double {
            let lower = min(minVal, maxVal)
            let upper = max(minVal, maxVal)
            return max(lower, min(upper, x))
        }
        
        func frac(_ key: String) -> Double {
            factorEnableFrac[key] ?? 0.0
        }

        func shiftFactor(oldValue: inout Double,
                         key: String,
                         useFactor: Bool,
                         minVal: Double,
                         maxVal: Double)
        {
            guard useFactor else { return }
            let range = maxVal - minVal
            let newValue = clamp(oldValue + delta * range * frac(key), minVal: minVal, maxVal: maxVal)
            // If the difference is tiny, skip reassign to avoid spamming updates
            guard abs(newValue - oldValue) > 1e-7 else { return }
            oldValue = newValue
        }

        // ---------- BULLISH FACTORS ----------
        shiftFactor(oldValue: &simSettings.halvingBumpUnified,
                    key: "Halving",
                    useFactor: simSettings.useHalvingUnified,
                    minVal: 0.2773386887,
                    maxVal: 0.3823386887)

        shiftFactor(oldValue: &simSettings.maxDemandBoostUnified,
                    key: "InstitutionalDemand",
                    useFactor: simSettings.useInstitutionalDemandUnified,
                    minVal: 0.00105315,
                    maxVal: 0.00142485)

        shiftFactor(oldValue: &simSettings.maxCountryAdBoostUnified,
                    key: "CountryAdoption",
                    useFactor: simSettings.useCountryAdoptionUnified,
                    minVal: 0.0009882799977,
                    maxVal: 0.0012868959977)

        shiftFactor(oldValue: &simSettings.maxClarityBoostUnified,
                    key: "RegulatoryClarity",
                    useFactor: simSettings.useRegulatoryClarityUnified,
                    minVal: 0.0005979474861605167,
                    maxVal: 0.0008361034861605167)

        shiftFactor(oldValue: &simSettings.maxEtfBoostUnified,
                    key: "EtfApproval",
                    useFactor: simSettings.useEtfApprovalUnified,
                    minVal: 0.0014880183160305023,
                    maxVal: 0.0020880183160305023)

        shiftFactor(oldValue: &simSettings.maxTechBoostUnified,
                    key: "TechBreakthrough",
                    useFactor: simSettings.useTechBreakthroughUnified,
                    minVal: 0.0005015753579173088,
                    maxVal: 0.0007150633579173088)

        shiftFactor(oldValue: &simSettings.maxScarcityBoostUnified,
                    key: "ScarcityEvents",
                    useFactor: simSettings.useScarcityEventsUnified,
                    minVal: 0.00035112353681182863,
                    maxVal: 0.00047505153681182863)

        shiftFactor(oldValue: &simSettings.maxMacroBoostUnified,
                    key: "GlobalMacroHedge",
                    useFactor: simSettings.useGlobalMacroHedgeUnified,
                    minVal: 0.0002868789724932909,
                    maxVal: 0.0004126829724932909)

        shiftFactor(oldValue: &simSettings.maxStablecoinBoostUnified,
                    key: "StablecoinShift",
                    useFactor: simSettings.useStablecoinShiftUnified,
                    minVal: 0.0002704809116327763,
                    maxVal: 0.0003919609116327763)

        shiftFactor(oldValue: &simSettings.maxDemoBoostUnified,
                    key: "DemographicAdoption",
                    useFactor: simSettings.useDemographicAdoptionUnified,
                    minVal: 0.0008661432036626339,
                    maxVal: 0.0012578432036626339)

        shiftFactor(oldValue: &simSettings.maxAltcoinBoostUnified,
                    key: "AltcoinFlight",
                    useFactor: simSettings.useAltcoinFlightUnified,
                    minVal: 0.0002381864461803342,
                    maxVal: 0.0003222524461803342)

        shiftFactor(oldValue: &simSettings.adoptionBaseFactorUnified,
                    key: "AdoptionFactor",
                    useFactor: simSettings.useAdoptionFactorUnified,
                    minVal: 0.0013638349088897705,
                    maxVal: 0.0018451869088897705)

        // ---------- BEARISH FACTORS ----------
        shiftFactor(oldValue: &simSettings.maxClampDownUnified,
                    key: "RegClampdown",
                    useFactor: simSettings.useRegClampdownUnified,
                    minVal: -0.0014273392243542672,
                    maxVal: -0.0008449512243542672)

        shiftFactor(oldValue: &simSettings.maxCompetitorBoostUnified,
                    key: "CompetitorCoin",
                    useFactor: simSettings.useCompetitorCoinUnified,
                    minVal: -0.0011842141746411323,
                    maxVal: -0.0008454221746411323)

        shiftFactor(oldValue: &simSettings.breachImpactUnified,
                    key: "SecurityBreach",
                    useFactor: simSettings.useSecurityBreachUnified,
                    minVal: -0.0012819675168380737,
                    maxVal: -0.0009009755168380737)

        shiftFactor(oldValue: &simSettings.maxPopDropUnified,
                    key: "BubblePop",
                    useFactor: simSettings.useBubblePopUnified,
                    minVal: -0.002244817890762329,
                    maxVal: -0.001280529890762329)

        shiftFactor(oldValue: &simSettings.maxMeltdownDropUnified,
                    key: "StablecoinMeltdown",
                    useFactor: simSettings.useStablecoinMeltdownUnified,
                    minVal: -0.0009681346159477233,
                    maxVal: -0.0004600706159477233)

        shiftFactor(oldValue: &simSettings.blackSwanDropUnified,
                    key: "BlackSwan",
                    useFactor: simSettings.useBlackSwanUnified,
                    minVal: -0.478662,
                    maxVal: -0.319108)

        shiftFactor(oldValue: &simSettings.bearWeeklyDriftUnified,
                    key: "BearMarket",
                    useFactor: simSettings.useBearMarketUnified,
                    minVal: -0.0010278802752494812,
                    maxVal: -0.0007278802752494812)

        shiftFactor(oldValue: &simSettings.maxMaturingDropUnified,
                    key: "MaturingMarket",
                    useFactor: simSettings.useMaturingMarketUnified,
                    minVal: -0.0020343461055486196,
                    maxVal: -0.0010537001055486196)

        shiftFactor(oldValue: &simSettings.maxRecessionDropUnified,
                    key: "Recession",
                    useFactor: simSettings.useRecessionUnified,
                    minVal: -0.0010516462467487811,
                    maxVal: -0.0007494520467487811)
    }

    // Recomputes the universal slider value from each factor's normalised position.
    func updateUniversalFactorIntensity() {
        var totalNormalised = 0.0
        var count = 0

        func normaliseBull(_ value: Double, _ minVal: Double, _ maxVal: Double) -> Double {
            (value - minVal) / (maxVal - minVal)
        }

        func normaliseBear(_ value: Double, _ minVal: Double, _ maxVal: Double) -> Double {
            (value - minVal) / (maxVal - minVal)
        }

        // ---------- BULLISH ----------
        if simSettings.useHalvingUnified {
            totalNormalised += normaliseBull(simSettings.halvingBumpUnified, 0.2773386887, 0.3823386887)
            count += 1
        }
        if simSettings.useInstitutionalDemandUnified {
            totalNormalised += normaliseBull(simSettings.maxDemandBoostUnified, 0.00105315, 0.00142485)
            count += 1
        }
        if simSettings.useCountryAdoptionUnified {
            totalNormalised += normaliseBull(simSettings.maxCountryAdBoostUnified, 0.0009882799977, 0.0012868959977)
            count += 1
        }
        if simSettings.useRegulatoryClarityUnified {
            totalNormalised += normaliseBull(simSettings.maxClarityBoostUnified, 0.0005979474861605167, 0.0008361034861605167)
            count += 1
        }
        if simSettings.useEtfApprovalUnified {
            totalNormalised += normaliseBull(simSettings.maxEtfBoostUnified, 0.0014880183160305023, 0.0020880183160305023)
            count += 1
        }
        if simSettings.useTechBreakthroughUnified {
            totalNormalised += normaliseBull(simSettings.maxTechBoostUnified, 0.0005015753579173088, 0.0007150633579173088)
            count += 1
        }
        if simSettings.useScarcityEventsUnified {
            totalNormalised += normaliseBull(simSettings.maxScarcityBoostUnified, 0.00035112353681182863, 0.00047505153681182863)
            count += 1
        }
        if simSettings.useGlobalMacroHedgeUnified {
            totalNormalised += normaliseBull(simSettings.maxMacroBoostUnified, 0.0002868789724932909, 0.0004126829724932909)
            count += 1
        }
        if simSettings.useStablecoinShiftUnified {
            totalNormalised += normaliseBull(simSettings.maxStablecoinBoostUnified, 0.0002704809116327763, 0.0003919609116327763)
            count += 1
        }
        if simSettings.useDemographicAdoptionUnified {
            totalNormalised += normaliseBull(simSettings.maxDemoBoostUnified, 0.0008661432036626339, 0.0012578432036626339)
            count += 1
        }
        if simSettings.useAltcoinFlightUnified {
            totalNormalised += normaliseBull(simSettings.maxAltcoinBoostUnified, 0.0002381864461803342, 0.0003222524461803342)
            count += 1
        }
        if simSettings.useAdoptionFactorUnified {
            totalNormalised += normaliseBull(simSettings.adoptionBaseFactorUnified, 0.0013638349088897705, 0.0018451869088897705)
            count += 1
        }

        // ---------- BEARISH ----------
        if simSettings.useRegClampdownUnified {
            totalNormalised += normaliseBear(simSettings.maxClampDownUnified, -0.0014273392243542672, -0.0008449512243542672)
            count += 1
        }
        if simSettings.useCompetitorCoinUnified {
            totalNormalised += normaliseBear(simSettings.maxCompetitorBoostUnified, -0.0011842141746411323, -0.0008454221746411323)
            count += 1
        }
        if simSettings.useSecurityBreachUnified {
            totalNormalised += normaliseBear(simSettings.breachImpactUnified, -0.0012819675168380737, -0.0009009755168380737)
            count += 1
        }
        if simSettings.useBubblePopUnified {
            totalNormalised += normaliseBear(simSettings.maxPopDropUnified, -0.002244817890762329, -0.001280529890762329)
            count += 1
        }
        if simSettings.useStablecoinMeltdownUnified {
            totalNormalised += normaliseBear(simSettings.maxMeltdownDropUnified, -0.0009681346159477233, -0.0004600706159477233)
            count += 1
        }
        if simSettings.useBlackSwanUnified {
            totalNormalised += normaliseBear(simSettings.blackSwanDropUnified, -0.478662, -0.319108)
            count += 1
        }
        if simSettings.useBearMarketUnified {
            totalNormalised += normaliseBear(simSettings.bearWeeklyDriftUnified, -0.0010278802752494812, -0.0007278802752494812)
            count += 1
        }
        if simSettings.useMaturingMarketUnified {
            totalNormalised += normaliseBear(simSettings.maxMaturingDropUnified, -0.0020343461055486196, -0.0010537001055486196)
            count += 1
        }
        if simSettings.useRecessionUnified {
            totalNormalised += normaliseBear(simSettings.maxRecessionDropUnified, -0.0010516462467487811, -0.0007494520467487811)
            count += 1
        }

        guard count > 0 else { return }
        let average = totalNormalised / Double(count)
        
        // Keep the main file’s factorIntensity in sync
        factorIntensity = average
        oldFactorIntensity = average
    }

    func animateFactor(_ key: String, isOn: Bool) {
        withAnimation(.easeInOut(duration: 0.6)) {
            factorEnableFrac[key] = isOn ? 1.0 : 0.0
        }
    }

    // Moved out of animateFactor.
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
