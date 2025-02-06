//
//  SettingsWatchers.swift
//  BTCMonteCarlo
//
//  Created by YourName on 27/01/2025.
//

import SwiftUI

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS A
// ----------------------------------------------------------
struct UnifiedValueWatchersA: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            watchersA1
            watchersA2
        }
        .onAppear {
            print("UnifiedValueWatchersA onAppear -> I'm in the hierarchy!")
        }
    }
    
    private var watchersA1: some View {
        EmptyView()
            .onChange(of: simSettings.halvingBumpUnified, initial: false) { _, newVal in
                updateFactor("Halving", newVal,
                             minVal: 0.2773386887,
                             maxVal: 0.3823386887)
            }
            .onChange(of: simSettings.maxDemandBoostUnified, initial: false) { _, newVal in
                updateFactor("InstitutionalDemand", newVal,
                             minVal: 0.00105315,
                             maxVal: 0.00142485)
            }
            .onChange(of: simSettings.maxCountryAdBoostUnified, initial: false) { _, newVal in
                updateFactor("CountryAdoption", newVal,
                             minVal: 0.0009882799977,
                             maxVal: 0.0012868959977)
            }
    }
    
    private var watchersA2: some View {
        EmptyView()
            .onChange(of: simSettings.maxClarityBoostUnified, initial: false) { _, newVal in
                updateFactor("RegulatoryClarity", newVal,
                             minVal: 0.0005979474861605167,
                             maxVal: 0.0008361034861605167)
            }
            .onChange(of: simSettings.maxEtfBoostUnified, initial: false) { _, newVal in
                updateFactor("EtfApproval", newVal,
                             minVal: 0.0014880183160305023,
                             maxVal: 0.0020880183160305023)
            }
            .onChange(of: simSettings.maxTechBoostUnified, initial: false) { _, newVal in
                updateFactor("TechBreakthrough", newVal,
                             minVal: 0.0005015753579173088,
                             maxVal: 0.0007150633579173088)
            }
            .onChange(of: simSettings.maxScarcityBoostUnified, initial: false) { _, newVal in
                updateFactor("ScarcityEvents", newVal,
                             minVal: 0.00035112353681182863,
                             maxVal: 0.00047505153681182863)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        print("[UnifiedValueWatchersA] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        
        guard var factor = simSettings.factors[name] else {
            print("  -> Factor '\(name)' not found!")
            return
        }
        
        // CHANGED HERE: Skip if factor is disabled or locked
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        
        factor.currentValue = clamped
        
        // Recalc offset to stay consistent with global slider
        let base = simSettings.globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        
        simSettings.factors[name] = factor
    }
}

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS B
// ----------------------------------------------------------
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
                updateFactor("GlobalMacroHedge", newVal,
                             minVal: 0.0002868789724932909,
                             maxVal: 0.0004126829724932909)
            }
            .onChange(of: simSettings.maxStablecoinBoostUnified, initial: false) { _, newVal in
                updateFactor("StablecoinShift", newVal,
                             minVal: 0.0002704809116327763,
                             maxVal: 0.0003919609116327763)
            }
    }
    
    private var watchersB1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxDemoBoostUnified, initial: false) { _, newVal in
                updateFactor("DemographicAdoption", newVal,
                             minVal: 0.0008661432036626339,
                             maxVal: 0.0012578432036626339)
            }
            .onChange(of: simSettings.maxAltcoinBoostUnified, initial: false) { _, newVal in
                updateFactor("AltcoinFlight", newVal,
                             minVal: 0.0002381864461803342,
                             maxVal: 0.0003222524461803342)
            }
    }
    
    private var watchersB2: some View {
        EmptyView()
            .onChange(of: simSettings.adoptionBaseFactorUnified, initial: false) { _, newVal in
                updateFactor("AdoptionFactor", newVal,
                             minVal: 0.0013638349088897705,
                             maxVal: 0.0018451869088897705)
            }
            .onChange(of: simSettings.maxClampDownUnified, initial: false) { _, newVal in
                updateFactor("RegClampdown", newVal,
                             minVal: -0.0014273392243542672,
                             maxVal: -0.0008449512243542672)
            }
            .onChange(of: simSettings.maxCompetitorBoostUnified, initial: false) { _, newVal in
                updateFactor("CompetitorCoin", newVal,
                             minVal: -0.0011842141746411323,
                             maxVal: -0.0008454221746411323)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        print("[UnifiedValueWatchersB] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        
        guard var factor = simSettings.factors[name] else {
            print("  -> Factor '\(name)' not found!")
            return
        }
        
        // CHANGED HERE
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        
        factor.currentValue = clamped
        
        // Recalc offset
        let base = simSettings.globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        
        simSettings.factors[name] = factor
    }
}

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS C
// ----------------------------------------------------------
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
                updateFactor("SecurityBreach", newVal,
                             minVal: -0.0012819675168380737,
                             maxVal: -0.0009009755168380737)
            }
            .onChange(of: simSettings.maxPopDropUnified, initial: false) { _, newVal in
                updateFactor("BubblePop", newVal,
                             minVal: -0.002244817890762329,
                             maxVal: -0.001280529890762329)
            }
    }
    
    private var watchersC1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxMeltdownDropUnified, initial: false) { _, newVal in
                updateFactor("StablecoinMeltdown", newVal,
                             minVal: -0.0009681346159477233,
                             maxVal: -0.0004600706159477233)
            }
            .onChange(of: simSettings.blackSwanDropUnified, initial: false) { _, newVal in
                updateFactor("BlackSwan", newVal,
                             minVal: -0.478662,
                             maxVal: -0.319108)
            }
    }
    
    private var watchersC2: some View {
        EmptyView()
            .onChange(of: simSettings.bearWeeklyDriftUnified, initial: false) { _, newVal in
                updateFactor("BearMarket", newVal,
                             minVal: -0.0010278802752494812,
                             maxVal: -0.0007278802752494812)
            }
            .onChange(of: simSettings.maxMaturingDropUnified, initial: false) { _, newVal in
                updateFactor("MaturingMarket", newVal,
                             minVal: -0.0020343461055486196,
                             maxVal: -0.0010537001055486196)
            }
            .onChange(of: simSettings.maxRecessionDropUnified, initial: false) { _, newVal in
                updateFactor("Recession", newVal,
                             minVal: -0.0010516462467487811,
                             maxVal: -0.0007494520467487811)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        print("[UnifiedValueWatchersC] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        
        guard var factor = simSettings.factors[name] else {
            print("  -> Factor '\(name)' not found!")
            return
        }
        
        // CHANGED HERE
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        
        factor.currentValue = clamped
        
        // Recalc offset
        let base = simSettings.globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        
        simSettings.factors[name] = factor
    }
}
