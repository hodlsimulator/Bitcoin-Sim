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
// Instead of factorEnableFrac, we clamp newVal to [minVal..maxVal]
// and store it into simSettings.factors["FactorName"]?.currentValue.
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
            .onChange(of: simSettings.halvingBumpUnified, initial: false) { _, newVal in
                // Halving range: 0.2773386887 .. 0.3823386887
                updateFactor("Halving", newVal, minVal: 0.2773386887, maxVal: 0.3823386887)
            }
            .onChange(of: simSettings.maxDemandBoostUnified, initial: false) { _, newVal in
                // InstitutionalDemand range: 0.00105315 .. 0.00142485
                updateFactor("InstitutionalDemand", newVal,
                             minVal: 0.00105315,
                             maxVal: 0.00142485)
            }
            .onChange(of: simSettings.maxCountryAdBoostUnified, initial: false) { _, newVal in
                // CountryAdoption range: 0.0009882799977 .. 0.0012868959977
                updateFactor("CountryAdoption", newVal,
                             minVal: 0.0009882799977,
                             maxVal: 0.0012868959977)
            }
    }
    
    private var watchersA2: some View {
        EmptyView()
            .onChange(of: simSettings.maxClarityBoostUnified, initial: false) { _, newVal in
                // RegulatoryClarity range: 0.0005979474861605167 .. 0.0008361034861605167
                updateFactor("RegulatoryClarity", newVal,
                             minVal: 0.0005979474861605167,
                             maxVal: 0.0008361034861605167)
            }
            .onChange(of: simSettings.maxEtfBoostUnified, initial: false) { _, newVal in
                // EtfApproval range: 0.0014880183160305023 .. 0.0020880183160305023
                updateFactor("EtfApproval", newVal,
                             minVal: 0.0014880183160305023,
                             maxVal: 0.0020880183160305023)
            }
            .onChange(of: simSettings.maxTechBoostUnified, initial: false) { _, newVal in
                // TechBreakthrough range: 0.0005015753579173088 .. 0.0007150633579173088
                updateFactor("TechBreakthrough", newVal,
                             minVal: 0.0005015753579173088,
                             maxVal: 0.0007150633579173088)
            }
            .onChange(of: simSettings.maxScarcityBoostUnified, initial: false) { _, newVal in
                // ScarcityEvents range: 0.00035112353681182863 .. 0.00047505153681182863
                updateFactor("ScarcityEvents", newVal,
                             minVal: 0.00035112353681182863,
                             maxVal: 0.00047505153681182863)
            }
    }
    
    /// Helper to clamp and set currentValue in simSettings.factors
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        guard var factor = simSettings.factors[name] else { return }
        let clamped = max(minVal, min(rawValue, maxVal))
        factor.currentValue = clamped
        simSettings.factors[name] = factor
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
            .onChange(of: simSettings.maxMacroBoostUnified, initial: false) { _, newVal in
                // GlobalMacroHedge range: 0.0002868789724932909 .. 0.0004126829724932909
                updateFactor("GlobalMacroHedge", newVal,
                             minVal: 0.0002868789724932909,
                             maxVal: 0.0004126829724932909)
            }
            .onChange(of: simSettings.maxStablecoinBoostUnified, initial: false) { _, newVal in
                // StablecoinShift range: 0.0002704809116327763 .. 0.0003919609116327763
                updateFactor("StablecoinShift", newVal,
                             minVal: 0.0002704809116327763,
                             maxVal: 0.0003919609116327763)
            }
    }
    
    private var watchersB1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxDemoBoostUnified, initial: false) { _, newVal in
                // DemographicAdoption range: 0.0008661432036626339 .. 0.0012578432036626339
                updateFactor("DemographicAdoption", newVal,
                             minVal: 0.0008661432036626339,
                             maxVal: 0.0012578432036626339)
            }
            .onChange(of: simSettings.maxAltcoinBoostUnified, initial: false) { _, newVal in
                // AltcoinFlight range: 0.0002381864461803342 .. 0.0003222524461803342
                updateFactor("AltcoinFlight", newVal,
                             minVal: 0.0002381864461803342,
                             maxVal: 0.0003222524461803342)
            }
    }
    
    private var watchersB2: some View {
        EmptyView()
            .onChange(of: simSettings.adoptionBaseFactorUnified, initial: false) { _, newVal in
                // AdoptionFactor range: 0.0013638349088897705 .. 0.0018451869088897705
                updateFactor("AdoptionFactor", newVal,
                             minVal: 0.0013638349088897705,
                             maxVal: 0.0018451869088897705)
            }
            .onChange(of: simSettings.maxClampDownUnified, initial: false) { _, newVal in
                // RegClampdown range: -0.0014273392243542672 .. -0.0008449512243542672
                updateFactor("RegClampdown", newVal,
                             minVal: -0.0014273392243542672,
                             maxVal: -0.0008449512243542672)
            }
            .onChange(of: simSettings.maxCompetitorBoostUnified, initial: false) { _, newVal in
                // CompetitorCoin range: -0.0011842141746411323 .. -0.0008454221746411323
                updateFactor("CompetitorCoin", newVal,
                             minVal: -0.0011842141746411323,
                             maxVal: -0.0008454221746411323)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        guard var factor = simSettings.factors[name] else { return }
        let clamped = max(minVal, min(rawValue, maxVal))
        factor.currentValue = clamped
        simSettings.factors[name] = factor
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
            .onChange(of: simSettings.breachImpactUnified, initial: false) { _, newVal in
                // SecurityBreach range: -0.0012819675168380737 .. -0.0009009755168380737
                updateFactor("SecurityBreach", newVal,
                             minVal: -0.0012819675168380737,
                             maxVal: -0.0009009755168380737)
            }
            .onChange(of: simSettings.maxPopDropUnified, initial: false) { _, newVal in
                // BubblePop range: -0.002244817890762329 .. -0.001280529890762329
                updateFactor("BubblePop", newVal,
                             minVal: -0.002244817890762329,
                             maxVal: -0.001280529890762329)
            }
    }
    
    private var watchersC1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxMeltdownDropUnified, initial: false) { _, newVal in
                // StablecoinMeltdown range: -0.0009681346159477233 .. -0.0004600706159477233
                updateFactor("StablecoinMeltdown", newVal,
                             minVal: -0.0009681346159477233,
                             maxVal: -0.0004600706159477233)
            }
            .onChange(of: simSettings.blackSwanDropUnified, initial: false) { _, newVal in
                // BlackSwan range: -0.478662 .. -0.319108
                updateFactor("BlackSwan", newVal,
                             minVal: -0.478662,
                             maxVal: -0.319108)
            }
    }
    
    private var watchersC2: some View {
        EmptyView()
            .onChange(of: simSettings.bearWeeklyDriftUnified, initial: false) { _, newVal in
                // BearMarket range: -0.0010278802752494812 .. -0.0007278802752494812
                updateFactor("BearMarket", newVal,
                             minVal: -0.0010278802752494812,
                             maxVal: -0.0007278802752494812)
            }
            .onChange(of: simSettings.maxMaturingDropUnified, initial: false) { _, newVal in
                // MaturingMarket range: -0.0020343461055486196 .. -0.0010537001055486196
                updateFactor("MaturingMarket", newVal,
                             minVal: -0.0020343461055486196,
                             maxVal: -0.0010537001055486196)
            }
            .onChange(of: simSettings.maxRecessionDropUnified, initial: false) { _, newVal in
                // Recession range: -0.0010516462467487811 .. -0.0007494520467487811
                updateFactor("Recession", newVal,
                             minVal: -0.0010516462467487811,
                             maxVal: -0.0007494520467487811)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        guard var factor = simSettings.factors[name] else { return }
        let clamped = max(minVal, min(rawValue, maxVal))
        factor.currentValue = clamped
        simSettings.factors[name] = factor
    }
}
