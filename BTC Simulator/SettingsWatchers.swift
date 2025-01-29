//
//  SettingsWatchers.swift
//  BTCMonteCarlo
//
//  Created by YourName on 27/01/2025.
//

import SwiftUI

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS
// ----------------------------------------------------------
//
// These watchers simply convert each "unified" slider value
// (like halvingBumpUnified) into a 0..1 fraction in factorEnableFrac.
// That fraction is used for intensity, NOT for on/off toggling.
//

struct UnifiedValueWatchersA: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            watchersA1
            watchersA2
        }
    }
    
    private var watchersA1: some View {
        EmptyView()
            .onChange(of: simSettings.halvingBumpUnified) { newVal in
                // Halving range: 0.2773386887 .. 0.3823386887
                simSettings.factorEnableFrac["Halving"] = normalise(
                    newVal,
                    minVal: 0.2773386887,
                    maxVal: 0.3823386887
                )
            }
            .onChange(of: simSettings.maxDemandBoostUnified) { newVal in
                // InstitutionalDemand range: 0.00105315 .. 0.00142485
                simSettings.factorEnableFrac["InstitutionalDemand"] = normalise(
                    newVal,
                    minVal: 0.00105315,
                    maxVal: 0.00142485
                )
            }
            .onChange(of: simSettings.maxCountryAdBoostUnified) { newVal in
                // CountryAdoption range: 0.0009882799977 .. 0.0012868959977
                simSettings.factorEnableFrac["CountryAdoption"] = normalise(
                    newVal,
                    minVal: 0.0009882799977,
                    maxVal: 0.0012868959977
                )
            }
    }
    
    private var watchersA2: some View {
        EmptyView()
            .onChange(of: simSettings.maxClarityBoostUnified) { newVal in
                // RegulatoryClarity range: 0.0005979474861605167 .. 0.0008361034861605167
                simSettings.factorEnableFrac["RegulatoryClarity"] = normalise(
                    newVal,
                    minVal: 0.0005979474861605167,
                    maxVal: 0.0008361034861605167
                )
            }
            .onChange(of: simSettings.maxEtfBoostUnified) { newVal in
                // EtfApproval range: 0.0014880183160305023 .. 0.0020880183160305023
                simSettings.factorEnableFrac["EtfApproval"] = normalise(
                    newVal,
                    minVal: 0.0014880183160305023,
                    maxVal: 0.0020880183160305023
                )
            }
            .onChange(of: simSettings.maxTechBoostUnified) { newVal in
                // TechBreakthrough range: 0.0005015753579173088 .. 0.0007150633579173088
                simSettings.factorEnableFrac["TechBreakthrough"] = normalise(
                    newVal,
                    minVal: 0.0005015753579173088,
                    maxVal: 0.0007150633579173088
                )
            }
            .onChange(of: simSettings.maxScarcityBoostUnified) { newVal in
                // ScarcityEvents range: 0.00035112353681182863 .. 0.00047505153681182863
                simSettings.factorEnableFrac["ScarcityEvents"] = normalise(
                    newVal,
                    minVal: 0.00035112353681182863,
                    maxVal: 0.00047505153681182863
                )
            }
    }
}

struct UnifiedValueWatchersB: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            watchersB1
            watchersB2
        }
    }
    
    private var watchersB1: some View {
        Group {
            watchersB1a
            watchersB1b
        }
    }
    
    private var watchersB1a: some View {
        EmptyView()
            .onChange(of: simSettings.maxMacroBoostUnified) { newVal in
                // GlobalMacroHedge range: 0.0002868789724932909 .. 0.0004126829724932909
                simSettings.factorEnableFrac["GlobalMacroHedge"] = normalise(
                    newVal,
                    minVal: 0.0002868789724932909,
                    maxVal: 0.0004126829724932909
                )
            }
            .onChange(of: simSettings.maxStablecoinBoostUnified) { newVal in
                // StablecoinShift range: 0.0002704809116327763 .. 0.0003919609116327763
                simSettings.factorEnableFrac["StablecoinShift"] = normalise(
                    newVal,
                    minVal: 0.0002704809116327763,
                    maxVal: 0.0003919609116327763
                )
            }
    }
    
    private var watchersB1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxDemoBoostUnified) { newVal in
                // DemographicAdoption range: 0.0008661432036626339 .. 0.0012578432036626339
                simSettings.factorEnableFrac["DemographicAdoption"] = normalise(
                    newVal,
                    minVal: 0.0008661432036626339,
                    maxVal: 0.0012578432036626339
                )
            }
            .onChange(of: simSettings.maxAltcoinBoostUnified) { newVal in
                // AltcoinFlight range: 0.0002381864461803342 .. 0.0003222524461803342
                simSettings.factorEnableFrac["AltcoinFlight"] = normalise(
                    newVal,
                    minVal: 0.0002381864461803342,
                    maxVal: 0.0003222524461803342
                )
            }
    }
    
    private var watchersB2: some View {
        EmptyView()
            .onChange(of: simSettings.adoptionBaseFactorUnified) { newVal in
                // AdoptionFactor range: 0.0013638349088897705 .. 0.0018451869088897705
                simSettings.factorEnableFrac["AdoptionFactor"] = normalise(
                    newVal,
                    minVal: 0.0013638349088897705,
                    maxVal: 0.0018451869088897705
                )
            }
            .onChange(of: simSettings.maxClampDownUnified) { newVal in
                // RegClampdown range: -0.0014273392243542672 .. -0.0008449512243542672
                simSettings.factorEnableFrac["RegClampdown"] = normalise(
                    newVal,
                    minVal: -0.0014273392243542672,
                    maxVal: -0.0008449512243542672
                )
            }
            .onChange(of: simSettings.maxCompetitorBoostUnified) { newVal in
                // CompetitorCoin range: -0.0011842141746411323 .. -0.0008454221746411323
                simSettings.factorEnableFrac["CompetitorCoin"] = normalise(
                    newVal,
                    minVal: -0.0011842141746411323,
                    maxVal: -0.0008454221746411323
                )
            }
    }
}

struct UnifiedValueWatchersC: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            watchersC1
            watchersC2
        }
    }
    
    private var watchersC1: some View {
        Group {
            watchersC1a
            watchersC1b
        }
    }
    
    private var watchersC1a: some View {
        EmptyView()
            .onChange(of: simSettings.breachImpactUnified) { newVal in
                // SecurityBreach range: -0.0012819675168380737 .. -0.0009009755168380737
                simSettings.factorEnableFrac["SecurityBreach"] = normalise(
                    newVal,
                    minVal: -0.0012819675168380737,
                    maxVal: -0.0009009755168380737
                )
            }
            .onChange(of: simSettings.maxPopDropUnified) { newVal in
                // BubblePop range: -0.002244817890762329 .. -0.001280529890762329
                simSettings.factorEnableFrac["BubblePop"] = normalise(
                    newVal,
                    minVal: -0.002244817890762329,
                    maxVal: -0.001280529890762329
                )
            }
    }
    
    private var watchersC1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxMeltdownDropUnified) { newVal in
                // StablecoinMeltdown range: -0.0009681346159477233 .. -0.0004600706159477233
                simSettings.factorEnableFrac["StablecoinMeltdown"] = normalise(
                    newVal,
                    minVal: -0.0009681346159477233,
                    maxVal: -0.0004600706159477233
                )
            }
            .onChange(of: simSettings.blackSwanDropUnified) { newVal in
                // BlackSwan range: -0.478662 .. -0.319108
                simSettings.factorEnableFrac["BlackSwan"] = normalise(
                    newVal,
                    minVal: -0.478662,
                    maxVal: -0.319108
                )
            }
    }
    
    private var watchersC2: some View {
        EmptyView()
            .onChange(of: simSettings.bearWeeklyDriftUnified) { newVal in
                // BearMarket range: -0.0010278802752494812 .. -0.0007278802752494812
                simSettings.factorEnableFrac["BearMarket"] = normalise(
                    newVal,
                    minVal: -0.0010278802752494812,
                    maxVal: -0.0007278802752494812
                )
            }
            .onChange(of: simSettings.maxMaturingDropUnified) { newVal in
                // MaturingMarket range: -0.0020343461055486196 .. -0.0010537001055486196
                simSettings.factorEnableFrac["MaturingMarket"] = normalise(
                    newVal,
                    minVal: -0.0020343461055486196,
                    maxVal: -0.0010537001055486196
                )
            }
            .onChange(of: simSettings.maxRecessionDropUnified) { newVal in
                // Recession range: -0.0010516462467487811 .. -0.0007494520467487811
                simSettings.factorEnableFrac["Recession"] = normalise(
                    newVal,
                    minVal: -0.0010516462467487811,
                    maxVal: -0.0007494520467487811
                )
            }
    }
}

// ----------------------------------------------------------
// HELPER: NORMALISE A UNIFIED VALUE TO [0..1]
// ----------------------------------------------------------

fileprivate func normalise(_ value: Double,
                           minVal: Double,
                           maxVal: Double) -> Double {
    // For negative or reversed ranges, handle carefully:
    let low = min(minVal, maxVal)
    let high = max(minVal, maxVal)
    let clipped = max(low, min(value, high))
    let fraction = (clipped - low) / (high - low)
    return fraction
}

// ----------------------------------------------------------------
// NO FACTOR-TOGGLE WATCHERS HERE
// We no longer automatically turn factors on/off based on fraction.
// Instead, the fraction is strictly for intensity. The toggle is
// controlled only by something like `simSettings.useHalvingWeekly`.
// ----------------------------------------------------------------

