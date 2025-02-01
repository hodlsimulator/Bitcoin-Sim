//
//  FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 31/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// Called whenever factorIntensity changes.
    /// Maps t in [0..1] so:
    /// - t = 0.5 => factor = default (the "mid" value, from your static defaults)
    /// - t < 0.5 => factor < default (toward minVal)
    /// - t > 0.5 => factor > default (toward maxVal)
    ///
    /// We check `periodUnit == .weeks` or `.months` to pick which min/max/defaults to use.
    ///
    /// **Added**: we skip adjusting any factor whose `factorEnableFrac["FactorName"]` == 0,
    /// so that "turned off" factors remain off even when the global slider moves.
    func syncAllFactorsToIntensity(_ t: Double) {
        
        if periodUnit == .weeks {
            
            // --------------------------------
            // BULLISH FACTORS (WEEKLY)
            // --------------------------------
            
            // Halving
            syncOneFactor(
                factorName: "Halving",
                t: t,
                midVal: SimulationSettings.defaultHalvingBumpWeekly,
                minVal: 0.2773386887,
                maxVal: 0.3823386887
            ) { newVal in
                halvingBumpUnified = newVal
            }
            
            // Institutional Demand
            syncOneFactor(
                factorName: "InstitutionalDemand",
                t: t,
                midVal: SimulationSettings.defaultMaxDemandBoostWeekly,
                minVal: 0.00105315,
                maxVal: 0.00142485
            ) { newVal in
                maxDemandBoostUnified = newVal
            }
            
            // Country Adoption
            syncOneFactor(
                factorName: "CountryAdoption",
                t: t,
                midVal: SimulationSettings.defaultMaxCountryAdBoostWeekly,
                minVal: 0.0009882799977,
                maxVal: 0.0012868959977
            ) { newVal in
                maxCountryAdBoostUnified = newVal
            }
            
            // Regulatory Clarity
            syncOneFactor(
                factorName: "RegulatoryClarity",
                t: t,
                midVal: SimulationSettings.defaultMaxClarityBoostWeekly,
                minVal: 0.0005979474861605167,
                maxVal: 0.0008361034861605167
            ) { newVal in
                maxClarityBoostUnified = newVal
            }
            
            // ETF Approval
            syncOneFactor(
                factorName: "EtfApproval",
                t: t,
                midVal: SimulationSettings.defaultMaxEtfBoostWeekly,
                minVal: 0.0014880183160305023,
                maxVal: 0.0020880183160305023
            ) { newVal in
                maxEtfBoostUnified = newVal
            }
            
            // Tech Breakthrough
            syncOneFactor(
                factorName: "TechBreakthrough",
                t: t,
                midVal: SimulationSettings.defaultMaxTechBoostWeekly,
                minVal: 0.0005015753579173088,
                maxVal: 0.0007150633579173088
            ) { newVal in
                maxTechBoostUnified = newVal
            }
            
            // Scarcity Events
            syncOneFactor(
                factorName: "ScarcityEvents",
                t: t,
                midVal: SimulationSettings.defaultMaxScarcityBoostWeekly,
                minVal: 0.00035112353681182863,
                maxVal: 0.00047505153681182863
            ) { newVal in
                maxScarcityBoostUnified = newVal
            }
            
            // Global Macro Hedge
            syncOneFactor(
                factorName: "GlobalMacroHedge",
                t: t,
                midVal: SimulationSettings.defaultMaxMacroBoostWeekly,
                minVal: 0.0002868789724932909,
                maxVal: 0.0004126829724932909
            ) { newVal in
                maxMacroBoostUnified = newVal
            }
            
            // Stablecoin Shift
            syncOneFactor(
                factorName: "StablecoinShift",
                t: t,
                midVal: SimulationSettings.defaultMaxStablecoinBoostWeekly,
                minVal: 0.0002704809116327763,
                maxVal: 0.0003919609116327763
            ) { newVal in
                maxStablecoinBoostUnified = newVal
            }
            
            // Demographic Adoption
            syncOneFactor(
                factorName: "DemographicAdoption",
                t: t,
                midVal: SimulationSettings.defaultMaxDemoBoostWeekly,
                minVal: 0.0008661432036626339,
                maxVal: 0.0012578432036626339
            ) { newVal in
                maxDemoBoostUnified = newVal
            }
            
            // Altcoin Flight
            syncOneFactor(
                factorName: "AltcoinFlight",
                t: t,
                midVal: SimulationSettings.defaultMaxAltcoinBoostWeekly,
                minVal: 0.0002381864461803342,
                maxVal: 0.0003222524461803342
            ) { newVal in
                maxAltcoinBoostUnified = newVal
            }
            
            // AdoptionFactor
            syncOneFactor(
                factorName: "AdoptionFactor",
                t: t,
                midVal: SimulationSettings.defaultAdoptionBaseFactorWeekly,
                minVal: 0.0013638349088897705,
                maxVal: 0.0018451869088897705
            ) { newVal in
                adoptionBaseFactorUnified = newVal
            }
            
            // --------------------------------
            // BEARISH FACTORS (WEEKLY)
            // --------------------------------
            
            // Reg Clampdown
            syncOneFactor(
                factorName: "RegClampdown",
                t: t,
                midVal: SimulationSettings.defaultMaxClampDownWeekly,
                minVal: -0.0014273392243542672,
                maxVal: -0.0008449512243542672
            ) { newVal in
                maxClampDownUnified = newVal
            }
            
            // Competitor Coin
            syncOneFactor(
                factorName: "CompetitorCoin",
                t: t,
                midVal: SimulationSettings.defaultMaxCompetitorBoostWeekly,
                minVal: -0.0011842141746411323,
                maxVal: -0.0008454221746411323
            ) { newVal in
                maxCompetitorBoostUnified = newVal
            }
            
            // Security Breach
            syncOneFactor(
                factorName: "SecurityBreach",
                t: t,
                midVal: SimulationSettings.defaultBreachImpactWeekly,
                minVal: -0.0012819675168380737,
                maxVal: -0.0009009755168380737
            ) { newVal in
                breachImpactUnified = newVal
            }
            
            // Bubble Pop
            syncOneFactor(
                factorName: "BubblePop",
                t: t,
                midVal: SimulationSettings.defaultMaxPopDropWeekly,
                minVal: -0.002244817890762329,
                maxVal: -0.001280529890762329
            ) { newVal in
                maxPopDropUnified = newVal
            }
            
            // Stablecoin Meltdown
            syncOneFactor(
                factorName: "StablecoinMeltdown",
                t: t,
                midVal: SimulationSettings.defaultMaxMeltdownDropWeekly,
                minVal: -0.0009681346159477233,
                maxVal: -0.0004600706159477233
            ) { newVal in
                maxMeltdownDropUnified = newVal
            }
            
            // Black Swan
            syncOneFactor(
                factorName: "BlackSwan",
                t: t,
                midVal: SimulationSettings.defaultBlackSwanDropWeekly,
                minVal: -0.478662,
                maxVal: -0.319108
            ) { newVal in
                blackSwanDropUnified = newVal
            }
            
            // Bear Market
            syncOneFactor(
                factorName: "BearMarket",
                t: t,
                midVal: SimulationSettings.defaultBearWeeklyDriftWeekly,
                minVal: -0.0010278802752494812,
                maxVal: -0.0007278802752494812
            ) { newVal in
                bearWeeklyDriftUnified = newVal
            }
            
            // Maturing Market
            syncOneFactor(
                factorName: "MaturingMarket",
                t: t,
                midVal: SimulationSettings.defaultMaxMaturingDropWeekly,
                minVal: -0.0020343461055486196,
                maxVal: -0.0010537001055486196
            ) { newVal in
                maxMaturingDropUnified = newVal
            }
            
            // Recession
            syncOneFactor(
                factorName: "Recession",
                t: t,
                midVal: SimulationSettings.defaultMaxRecessionDropWeekly,
                minVal: -0.0010516462467487811,
                maxVal: -0.0007494520467487811
            ) { newVal in
                maxRecessionDropUnified = newVal
            }
            
        } else {
            // --------------------------------
            // BULLISH FACTORS (MONTHLY)
            // --------------------------------
            
            // Halving
            syncOneFactor(
                factorName: "Halving",
                t: t,
                midVal: SimulationSettings.defaultHalvingBumpMonthly, // e.g. 0.35
                minVal: 0.2975,
                maxVal: 0.4025
            ) { newVal in
                halvingBumpUnified = newVal
            }
            
            // Institutional Demand
            syncOneFactor(
                factorName: "InstitutionalDemand",
                t: t,
                midVal: SimulationSettings.defaultMaxDemandBoostMonthly,
                minVal: 0.0048101384,
                maxVal: 0.0065078326
            ) { newVal in
                maxDemandBoostUnified = newVal
            }
            
            // Country Adoption
            syncOneFactor(
                factorName: "CountryAdoption",
                t: t,
                midVal: SimulationSettings.defaultMaxCountryAdBoostMonthly,
                minVal: 0.004688188952320099,
                maxVal: 0.006342842952320099
            ) { newVal in
                maxCountryAdBoostUnified = newVal
            }
            
            // Regulatory Clarity
            syncOneFactor(
                factorName: "RegulatoryClarity",
                t: t,
                midVal: SimulationSettings.defaultMaxClarityBoostMonthly,
                minVal: 0.0034626727,
                maxVal: 0.0046847927
            ) { newVal in
                maxClarityBoostUnified = newVal
            }
            
            // ETF Approval
            syncOneFactor(
                factorName: "EtfApproval",
                t: t,
                midVal: SimulationSettings.defaultMaxEtfBoostMonthly,
                minVal: 0.0048571421,
                maxVal: 0.0065714281
            ) { newVal in
                maxEtfBoostUnified = newVal
            }
            
            // Tech Breakthrough
            syncOneFactor(
                factorName: "TechBreakthrough",
                t: t,
                midVal: SimulationSettings.defaultMaxTechBoostMonthly,
                minVal: 0.0024129091,
                maxVal: 0.0032645091
            ) { newVal in
                maxTechBoostUnified = newVal
            }
            
            // Scarcity Events
            syncOneFactor(
                factorName: "ScarcityEvents",
                t: t,
                midVal: SimulationSettings.defaultMaxScarcityBoostMonthly,
                minVal: 0.0027989405475521085,
                maxVal: 0.0037868005475521085
            ) { newVal in
                maxScarcityBoostUnified = newVal
            }
            
            // Global Macro Hedge
            syncOneFactor(
                factorName: "GlobalMacroHedge",
                t: t,
                midVal: SimulationSettings.defaultMaxMacroBoostMonthly,
                minVal: 0.0027576037,
                maxVal: 0.0037308757
            ) { newVal in
                maxMacroBoostUnified = newVal
            }
            
            // Stablecoin Shift
            syncOneFactor(
                factorName: "StablecoinShift",
                t: t,
                midVal: SimulationSettings.defaultMaxStablecoinBoostMonthly,
                minVal: 0.0019585255,
                maxVal: 0.0026497695
            ) { newVal in
                maxStablecoinBoostUnified = newVal
            }
            
            // Demographic Adoption
            syncOneFactor(
                factorName: "DemographicAdoption",
                t: t,
                midVal: SimulationSettings.defaultMaxDemoBoostMonthly,
                minVal: 0.006197455714649915,
                maxVal: 0.008384793714649915
            ) { newVal in
                maxDemoBoostUnified = newVal
            }
            
            // Altcoin Flight
            syncOneFactor(
                factorName: "AltcoinFlight",
                t: t,
                midVal: SimulationSettings.defaultMaxAltcoinBoostMonthly,
                minVal: 0.0018331797,
                maxVal: 0.0024801837
            ) { newVal in
                maxAltcoinBoostUnified = newVal
            }
            
            // Adoption Factor
            syncOneFactor(
                factorName: "AdoptionFactor",
                t: t,
                midVal: SimulationSettings.defaultAdoptionBaseFactorMonthly,
                minVal: 0.012461815934071304,
                maxVal: 0.016860103934071304
            ) { newVal in
                adoptionBaseFactorUnified = newVal
            }
            
            // --------------------------------
            // BEARISH FACTORS (MONTHLY)
            // --------------------------------
            
            // Reg Clampdown
            syncOneFactor(
                factorName: "RegClampdown",
                t: t,
                midVal: SimulationSettings.defaultMaxClampDownMonthly,
                minVal: -0.023,
                maxVal: -0.017
            ) { newVal in
                maxClampDownUnified = newVal
            }
            
            // Competitor Coin
            syncOneFactor(
                factorName: "CompetitorCoin",
                t: t,
                midVal: SimulationSettings.defaultMaxCompetitorBoostMonthly,
                minVal: -0.0092,
                maxVal: -0.0068
            ) { newVal in
                maxCompetitorBoostUnified = newVal
            }
            
            // Security Breach
            syncOneFactor(
                factorName: "SecurityBreach",
                t: t,
                midVal: SimulationSettings.defaultBreachImpactMonthly,
                minVal: -0.00805,
                maxVal: -0.00595
            ) { newVal in
                breachImpactUnified = newVal
            }
            
            // Bubble Pop
            syncOneFactor(
                factorName: "BubblePop",
                t: t,
                midVal: SimulationSettings.defaultMaxPopDropMonthly,
                minVal: -0.0115,
                maxVal: -0.0085
            ) { newVal in
                maxPopDropUnified = newVal
            }
            
            // Stablecoin Meltdown
            syncOneFactor(
                factorName: "StablecoinMeltdown",
                t: t,
                midVal: SimulationSettings.defaultMaxMeltdownDropMonthly,
                minVal: -0.013,
                maxVal: -0.007
            ) { newVal in
                maxMeltdownDropUnified = newVal
            }
            
            // Black Swan
            syncOneFactor(
                factorName: "BlackSwan",
                t: t,
                midVal: SimulationSettings.defaultBlackSwanDropMonthly,
                minVal: -0.48,
                maxVal: -0.32
            ) { newVal in
                blackSwanDropUnified = newVal
            }
            
            // Bear Market
            syncOneFactor(
                factorName: "BearMarket",
                t: t,
                midVal: SimulationSettings.defaultBearWeeklyDriftMonthly,
                minVal: -0.013,
                maxVal: -0.007
            ) { newVal in
                bearWeeklyDriftUnified = newVal
            }
            
            // Maturing Market
            syncOneFactor(
                factorName: "MaturingMarket",
                t: t,
                midVal: SimulationSettings.defaultMaxMaturingDropMonthly,
                minVal: -0.013,
                maxVal: -0.007
            ) { newVal in
                maxMaturingDropUnified = newVal
            }
            
            // Recession
            syncOneFactor(
                factorName: "Recession",
                t: t,
                midVal: SimulationSettings.defaultMaxRecessionDropMonthly,
                minVal: -0.0015958890,
                maxVal: -0.0013057270
            ) { newVal in
                maxRecessionDropUnified = newVal
            }
        }
    }
    
    /// Maps t in [0..1] to a range around a 'neutral' midVal:
    ///  - t = 0.5 => midVal
    ///  - t < 0.5 => from midVal down to minVal
    ///  - t > 0.5 => from midVal up to maxVal
    ///
    /// **Added**: Skips changing any factor whose `factorEnableFrac[factorName] == 0` (completely off).
    private func syncOneFactor(
        factorName: String,
        t: Double,
        midVal: Double,
        minVal: Double,
        maxVal: Double,
        assign: (Double) -> Void
    ) {
        // If factor is off (fraction == 0), skip syncing.
        if let frac = factorEnableFrac[factorName], frac == 0.0 {
            return
        }
        
        // Compute the base value from t.
        var baseVal: Double = 0.0
        if t < 0.5 {
            let ratio = t / 0.5
            baseVal = midVal - (midVal - minVal) * (1.0 - ratio)
        } else {
            let ratio = (t - 0.5) / 0.5
            baseVal = midVal + (maxVal - midVal) * ratio
        }
        
        // Retrieve the manual offset.
        let currentOffset = manualOffsets[factorName] ?? 0.0
        var computedVal = baseVal + currentOffset
        
        // If computed value goes outside the allowed range, clamp it and update the offset.
        if computedVal > maxVal {
            computedVal = maxVal
            manualOffsets[factorName] = computedVal - baseVal  // update offset to new difference
        } else if computedVal < minVal {
            computedVal = minVal
            manualOffsets[factorName] = computedVal - baseVal
        }
        
        assign(computedVal)
    }
}
