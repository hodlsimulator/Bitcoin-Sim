//
//  SettingsWatchers.swift
//  BTCMonteCarlo
//
//  Created by YourName on 27/01/2025.
//

import SwiftUI

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS A (Weekly)
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
            .onChange(of: simSettings.halvingBumpUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("Halving", newVal,
                             minVal: 0.2773386887,
                             maxVal: 0.3823386887)
            }
            .onChange(of: simSettings.maxDemandBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("InstitutionalDemand", newVal,
                             minVal: 0.00105315,
                             maxVal: 0.00142485)
            }
            .onChange(of: simSettings.maxCountryAdBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("CountryAdoption", newVal,
                             minVal: 0.0009882799977,
                             maxVal: 0.0012868959977)
            }
    }
    
    private var watchersA2: some View {
        EmptyView()
            .onChange(of: simSettings.maxClarityBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("RegulatoryClarity", newVal,
                             minVal: 0.0005979474861605167,
                             maxVal: 0.0008361034861605167)
            }
            .onChange(of: simSettings.maxEtfBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("EtfApproval", newVal,
                             minVal: 0.0014880183160305023,
                             maxVal: 0.0020880183160305023)
            }
            .onChange(of: simSettings.maxTechBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("TechBreakthrough", newVal,
                             minVal: 0.0005015753579173088,
                             maxVal: 0.0007150633579173088)
            }
            .onChange(of: simSettings.maxScarcityBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("ScarcityEvents", newVal,
                             minVal: 0.00035112353681182863,
                             maxVal: 0.00047505153681182863)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        // Weekly watchers skip update if a weekly restore is in progress.
        if simSettings.isRestoringDefaults {
            print("[UnifiedValueWatchersA] Skipping update for \(name) because weekly restore defaults is in progress")
            return
        }
        
        print("[UnifiedValueWatchersA] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        guard var factor = simSettings.factors[name] else {
            print("  -> Factor '\(name)' not found!")
            return
        }
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        factor.currentValue = clamped
        
        let base = simSettings.globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        simSettings.factors[name] = factor
    }
}

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS B (Weekly)
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
            .onChange(of: simSettings.maxMacroBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("GlobalMacroHedge", newVal,
                             minVal: 0.0002868789724932909,
                             maxVal: 0.0004126829724932909)
            }
            .onChange(of: simSettings.maxStablecoinBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("StablecoinShift", newVal,
                             minVal: 0.0002704809116327763,
                             maxVal: 0.0003919609116327763)
            }
    }
    
    private var watchersB1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxDemoBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("DemographicAdoption", newVal,
                             minVal: 0.0008661432036626339,
                             maxVal: 0.0012578432036626339)
            }
            .onChange(of: simSettings.maxAltcoinBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("AltcoinFlight", newVal,
                             minVal: 0.0002381864461803342,
                             maxVal: 0.0003222524461803342)
            }
    }
    
    private var watchersB2: some View {
        EmptyView()
            .onChange(of: simSettings.adoptionBaseFactorUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("AdoptionFactor", newVal,
                             minVal: 0.0013638349088897705,
                             maxVal: 0.0018451869088897705)
            }
            .onChange(of: simSettings.maxClampDownUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("RegClampdown", newVal,
                             minVal: -0.0014273392243542672,
                             maxVal: -0.0008449512243542672)
            }
            .onChange(of: simSettings.maxCompetitorBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("CompetitorCoin", newVal,
                             minVal: -0.0011842141746411323,
                             maxVal: -0.0008454221746411323)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        // Weekly watchers skip update if weekly restore is in progress.
        if simSettings.isRestoringDefaults {
            print("[UnifiedValueWatchersB] Skipping update for \(name) because weekly restore defaults is in progress")
            return
        }
        
        print("[UnifiedValueWatchersB] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        guard var factor = simSettings.factors[name] else {
            print("  -> Factor '\(name)' not found!")
            return
        }
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        factor.currentValue = clamped
        
        let base = simSettings.globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        simSettings.factors[name] = factor
    }
}

// ----------------------------------------------------------
// MARK: - UNIFIED VALUE WATCHERS C (Weekly)
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
            .onChange(of: simSettings.breachImpactUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("SecurityBreach", newVal,
                             minVal: -0.0012819675168380737,
                             maxVal: -0.0009009755168380737)
            }
            .onChange(of: simSettings.maxPopDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("BubblePop", newVal,
                             minVal: -0.002244817890762329,
                             maxVal: -0.001280529890762329)
            }
    }
    
    private var watchersC1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxMeltdownDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("StablecoinMeltdown", newVal,
                             minVal: -0.0009681346159477233,
                             maxVal: -0.0004600706159477233)
            }
            .onChange(of: simSettings.blackSwanDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("BlackSwan", newVal,
                             minVal: -0.478662,
                             maxVal: -0.319108)
            }
    }
    
    private var watchersC2: some View {
        EmptyView()
            .onChange(of: simSettings.bearWeeklyDriftUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("BearMarket", newVal,
                             minVal: -0.0010278802752494812,
                             maxVal: -0.0007278802752494812)
            }
            .onChange(of: simSettings.maxMaturingDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("MaturingMarket", newVal,
                             minVal: -0.0020343461055486196,
                             maxVal: -0.0010537001055486196)
            }
            .onChange(of: simSettings.maxRecessionDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .weeks else { return }
                updateFactor("Recession", newVal,
                             minVal: -0.0010516462467487811,
                             maxVal: -0.0007494520467487811)
            }
    }
    
    private func updateFactor(_ name: String,
                              _ rawValue: Double,
                              minVal: Double,
                              maxVal: Double) {
        // Weekly watchers skip update if weekly restore is in progress.
        if simSettings.isRestoringDefaults {
            print("[UnifiedValueWatchersC] Skipping update for \(name) because weekly restore defaults is in progress")
            return
        }
        
        print("[UnifiedValueWatchersC] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        guard var factor = simSettings.factors[name] else {
            print("  -> Factor '\(name)' not found!")
            return
        }
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        factor.currentValue = clamped
        
        let base = simSettings.globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        simSettings.factors[name] = factor
    }
}

// ----------------------------------------------------------
// MARK: - MONTHLY VALUE WATCHERS
// ----------------------------------------------------------
struct MonthlyValueWatchers: View {
    @ObservedObject var simSettings: SimulationSettings  // Your unified factor properties are here
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings

    var body: some View {
        Group {
            monthlyWatchersA
            monthlyWatchersB
            monthlyWatchersC
        }
    }
    
    // Group A
    private var monthlyWatchersA: some View {
        Group {
            monthlyWatchersA1
            monthlyWatchersA2
        }
    }
    
    private var monthlyWatchersA1: some View {
        EmptyView()
            .onChange(of: simSettings.halvingBumpUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("Halving", newVal,
                             minVal: 0.2975,
                             maxVal: 0.4025)
            }
            .onChange(of: simSettings.maxDemandBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("InstitutionalDemand", newVal,
                             minVal: 0.0048101384,
                             maxVal: 0.0065078326)
            }
            .onChange(of: simSettings.maxCountryAdBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("CountryAdoption", newVal,
                             minVal: 0.004688188952320099,
                             maxVal: 0.006342842952320099)
            }
    }
    
    private var monthlyWatchersA2: some View {
        EmptyView()
            .onChange(of: simSettings.maxClarityBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("RegulatoryClarity", newVal,
                             minVal: 0.0034626727,
                             maxVal: 0.0046847927)
            }
            .onChange(of: simSettings.maxEtfBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("EtfApproval", newVal,
                             minVal: 0.0048571421,
                             maxVal: 0.0065714281)
            }
            .onChange(of: simSettings.maxTechBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("TechBreakthrough", newVal,
                             minVal: 0.0024129091,
                             maxVal: 0.0032645091)
            }
            .onChange(of: simSettings.maxScarcityBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("ScarcityEvents", newVal,
                             minVal: 0.0027989405475521085,
                             maxVal: 0.0037868005475521085)
            }
    }
    
    // Group B
    private var monthlyWatchersB: some View {
        Group {
            monthlyWatchersB1
            monthlyWatchersB2
        }
    }
    
    private var monthlyWatchersB1: some View {
        EmptyView()
            .onChange(of: simSettings.maxMacroBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("GlobalMacroHedge", newVal,
                             minVal: 0.0027576037,
                             maxVal: 0.0037308757)
            }
            .onChange(of: simSettings.maxStablecoinBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("StablecoinShift", newVal,
                             minVal: 0.0019585255,
                             maxVal: 0.0026497695)
            }
    }
    
    private var monthlyWatchersB2: some View {
        EmptyView()
            .onChange(of: simSettings.maxDemoBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("DemographicAdoption", newVal,
                             minVal: 0.006197455714649915,
                             maxVal: 0.008384793714649915)
            }
            .onChange(of: simSettings.maxAltcoinBoostUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("AltcoinFlight", newVal,
                             minVal: 0.0018331797,
                             maxVal: 0.0024801837)
            }
    }
    
    // Group C
    private var monthlyWatchersC: some View {
        Group {
            monthlyWatchersC1
            monthlyWatchersC2
        }
    }
    
    private var monthlyWatchersC1: some View {
        EmptyView()
            .onChange(of: simSettings.breachImpactUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("SecurityBreach", newVal,
                             minVal: -0.00805,
                             maxVal: -0.00595)
            }
            .onChange(of: simSettings.maxPopDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("BubblePop", newVal,
                             minVal: -0.0115,
                             maxVal: -0.0085)
            }
    }
    
    private var monthlyWatchersC2: some View {
        EmptyView()
            .onChange(of: simSettings.maxMeltdownDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("StablecoinMeltdown", newVal,
                             minVal: -0.013,
                             maxVal: -0.007)
            }
            .onChange(of: simSettings.blackSwanDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("BlackSwan", newVal,
                             minVal: -0.48,
                             maxVal: -0.32)
            }
            .onChange(of: simSettings.bearWeeklyDriftUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("BearMarket", newVal,
                             minVal: -0.013,
                             maxVal: -0.007)
            }
            .onChange(of: simSettings.maxMaturingDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("MaturingMarket", newVal,
                             minVal: -0.013,
                             maxVal: -0.007)
            }
            .onChange(of: simSettings.maxRecessionDropUnified) { newVal, _ in
                guard simSettings.periodUnit == .months else { return }
                updateFactor("Recession", newVal,
                             minVal: -0.0015958890,
                             maxVal: -0.0013057270)
            }
    }
    
    private func updateFactor(
        _ name: String,
        _ rawValue: Double,
        minVal: Double,
        maxVal: Double
    ) {
        // Skip update if monthly restore is in progress.
        if monthlySimSettings.isRestoringDefaultsMonthly {
            print("[MonthlyValueWatchers] Skipping update for \(name) because monthly restore is in progress")
            return
        }

        // Also skip if factorsMonthly is still empty, so we don't get "Factor X not found"
        guard !monthlySimSettings.factorsMonthly.isEmpty else {
            print("[MonthlyValueWatchers] factorsMonthly is empty; skipping \(name)")
            return
        }
        
        print("[MonthlyValueWatchers] updateFactor(\(name)) rawValue=\(rawValue), range=[\(minVal), \(maxVal)]")
        guard var factor = monthlySimSettings.factorsMonthly[name] else {
            print("  -> Factor '\(name)' not found in monthly dictionary!")
            return
        }
        guard factor.isEnabled, !factor.isLocked else {
            print("  -> Factor '\(name)' is disabled or locked; skipping update.")
            return
        }
        
        let clamped = max(minVal, min(rawValue, maxVal))
        print("  -> Clamped=\(clamped)")
        factor.currentValue = clamped
        
        let base = monthlySimSettings.globalBaselineMonthly(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (clamped - base) / range
        print("  -> base=\(base), new offset=\(factor.internalOffset)")
        
        monthlySimSettings.factorsMonthly[name] = factor
    }
}
