//
//  FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 31/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// Called whenever factorIntensity changes. Maps t in [0..1] so:
    ///  - t = 0.5 => factor = default (the "mid" value, typically from your static defaults)
    ///  - t < 0.5 => factor < default (toward minVal)
    ///  - t > 0.5 => factor > default (toward maxVal)
    ///
    /// For now, we assume you're using WEEKLY defaults. If you switch to monthly,
    /// just replace each `defaultXYZWeekly` with `defaultXYZMonthly` or use a flag.
    func syncAllFactorsToIntensity(_ t: Double) {
        
        // -----------------------------
        // BULLISH FACTORS
        // -----------------------------
        
        // Halving
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultHalvingBumpWeekly,  // ~0.3298386887
            minVal: 0.2773386887,
            maxVal: 0.3823386887
        ) { newVal in
            halvingBumpUnified = newVal
        }
        
        // Institutional Demand
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxDemandBoostWeekly, // ~0.001239
            minVal: 0.00105315,
            maxVal: 0.00142485
        ) { newVal in
            maxDemandBoostUnified = newVal
        }
        
        // Country Adoption
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxCountryAdBoostWeekly, // ~0.001137588
            minVal: 0.0009882799977,
            maxVal: 0.0012868959977
        ) { newVal in
            maxCountryAdBoostUnified = newVal
        }
        
        // Regulatory Clarity
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxClarityBoostWeekly, // ~0.0007170255
            minVal: 0.0005979474861605167,
            maxVal: 0.0008361034861605167
        ) { newVal in
            maxClarityBoostUnified = newVal
        }
        
        // ETF Approval
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxEtfBoostWeekly, // ~0.0017880183
            minVal: 0.0014880183160305023,
            maxVal: 0.0020880183160305023
        ) { newVal in
            maxEtfBoostUnified = newVal
        }
        
        // Tech Breakthrough
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxTechBoostWeekly, // ~0.00060831936
            minVal: 0.0005015753579173088,
            maxVal: 0.0007150633579173088
        ) { newVal in
            maxTechBoostUnified = newVal
        }
        
        // Scarcity Events
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxScarcityBoostWeekly, // ~0.0004130875
            minVal: 0.00035112353681182863,
            maxVal: 0.00047505153681182863
        ) { newVal in
            maxScarcityBoostUnified = newVal
        }
        
        // Global Macro Hedge
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxMacroBoostWeekly, // ~0.00034978097
            minVal: 0.0002868789724932909,
            maxVal: 0.0004126829724932909
        ) { newVal in
            maxMacroBoostUnified = newVal
        }
        
        // Stablecoin Shift
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxStablecoinBoostWeekly, // ~0.0003312209
            minVal: 0.0002704809116327763,
            maxVal: 0.0003919609116327763
        ) { newVal in
            maxStablecoinBoostUnified = newVal
        }
        
        // Demographic Adoption
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxDemoBoostWeekly, // ~0.0010619932
            minVal: 0.0008661432036626339,
            maxVal: 0.0012578432036626339
        ) { newVal in
            maxDemoBoostUnified = newVal
        }
        
        // Altcoin Flight
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxAltcoinBoostWeekly, // ~0.00028021945
            minVal: 0.0002381864461803342,
            maxVal: 0.0003222524461803342
        ) { newVal in
            maxAltcoinBoostUnified = newVal
        }
        
        // Adoption Factor
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultAdoptionBaseFactorWeekly, // ~0.0016045109
            minVal: 0.0013638349088897705,
            maxVal: 0.0018451869088897705
        ) { newVal in
            adoptionBaseFactorUnified = newVal
        }
        
        
        // -----------------------------
        // BEARISH FACTORS
        // -----------------------------
        
        // Regulatory Clampdown
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxClampDownWeekly, // ~-0.0011361452
            minVal: -0.0014273392243542672,
            maxVal: -0.0008449512243542672
        ) { newVal in
            maxClampDownUnified = newVal
        }
        
        // Competitor Coin
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxCompetitorBoostWeekly, // ~-0.0010148182
            minVal: -0.0011842141746411323,
            maxVal: -0.0008454221746411323
        ) { newVal in
            maxCompetitorBoostUnified = newVal
        }
        
        // Security Breach
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultBreachImpactWeekly, // ~-0.0010914715
            minVal: -0.0012819675168380737,
            maxVal: -0.0009009755168380737
        ) { newVal in
            breachImpactUnified = newVal
        }
        
        // Bubble Pop
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxPopDropWeekly, // ~-0.0017626739
            minVal: -0.002244817890762329,
            maxVal: -0.001280529890762329
        ) { newVal in
            maxPopDropUnified = newVal
        }
        
        // Stablecoin Meltdown
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxMeltdownDropWeekly, // ~-0.0007141026
            minVal: -0.0009681346159477233,
            maxVal: -0.0004600706159477233
        ) { newVal in
            maxMeltdownDropUnified = newVal
        }
        
        // Black Swan
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultBlackSwanDropWeekly, // ~-0.398885
            minVal: -0.478662,
            maxVal: -0.319108
        ) { newVal in
            blackSwanDropUnified = newVal
        }
        
        // Bear Market
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultBearWeeklyDriftWeekly, // ~-0.0008778803
            minVal: -0.0010278802752494812,
            maxVal: -0.0007278802752494812
        ) { newVal in
            bearWeeklyDriftUnified = newVal
        }
        
        // Maturing Market
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxMaturingDropWeekly, // ~-0.0015440231
            minVal: -0.0020343461055486196,
            maxVal: -0.0010537001055486196
        ) { newVal in
            maxMaturingDropUnified = newVal
        }
        
        // Recession
        syncOneFactor(
            t: t,
            midVal: SimulationSettings.defaultMaxRecessionDropWeekly, // ~-0.00090054915
            minVal: -0.0010516462467487811,
            maxVal: -0.0007494520467487811
        ) { newVal in
            maxRecessionDropUnified = newVal
        }
    }
    
    
    /// Helper that maps `t` in [0..1] to a range around a 'neutral' midVal:
    ///  - t = 0.5 => midVal
    ///  - t < 0.5 => from midVal down to minVal
    ///  - t > 0.5 => from midVal up to maxVal
    private func syncOneFactor(
        t: Double,
        midVal: Double,
        minVal: Double,
        maxVal: Double,
        assign: (Double) -> Void
    ) {
        if t < 0.5 {
            // Slide from midVal down to minVal
            let ratio = t / 0.5 // ratio in [0..1]
            let newVal = midVal - (midVal - minVal) * (1.0 - ratio)
            assign(newVal)
        } else {
            // Slide from midVal up to maxVal
            let ratio = (t - 0.5) / 0.5 // ratio in [0..1]
            let newVal = midVal + (maxVal - midVal) * ratio
            assign(newVal)
        }
    }
}
