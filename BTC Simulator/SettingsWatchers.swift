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
// We have 21+ numeric watchers. We split them among
// UnifiedValueWatchersA/B/C, and then further split each
// struct into subgroups to avoid the giant chain problem.

struct UnifiedValueWatchersA: View {
    @ObservedObject var simSettings: SimulationSettings
    let updateUniversalFactorIntensity: () -> Void
    
    var body: some View {
        Group {
            watchersA1
            watchersA2
        }
    }
    
    // For the first 3 watchers
    private var watchersA1: some View {
        EmptyView()
            .onChange(of: simSettings.halvingBumpUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxDemandBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxCountryAdBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
    
    // For the next 4 watchers
    private var watchersA2: some View {
        EmptyView()
            .onChange(of: simSettings.maxClarityBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxEtfBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxTechBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxScarcityBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
}

struct UnifiedValueWatchersB: View {
    @ObservedObject var simSettings: SimulationSettings
    let updateUniversalFactorIntensity: () -> Void
    
    var body: some View {
        Group {
            watchersB1
            watchersB2
        }
    }
    
    // Split the first 4 watchers into two sets of 2 each
    private var watchersB1: some View {
        Group {
            watchersB1a
            watchersB1b
        }
    }
    
    private var watchersB1a: some View {
        EmptyView()
            .onChange(of: simSettings.maxMacroBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxStablecoinBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
    
    private var watchersB1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxDemoBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxAltcoinBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
    
    // Next 3 watchers
    private var watchersB2: some View {
        EmptyView()
            .onChange(of: simSettings.adoptionBaseFactorUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxClampDownUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxCompetitorBoostUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
}

struct UnifiedValueWatchersC: View {
    @ObservedObject var simSettings: SimulationSettings
    let updateUniversalFactorIntensity: () -> Void
    
    var body: some View {
        Group {
            watchersC1
            watchersC2
        }
    }
    
    // We have 7 watchers left. We'll break them into 4 + 3
    private var watchersC1: some View {
        Group {
            watchersC1a
            watchersC1b
        }
    }
    
    private var watchersC1a: some View {
        EmptyView()
            .onChange(of: simSettings.breachImpactUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxPopDropUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
    
    private var watchersC1b: some View {
        EmptyView()
            .onChange(of: simSettings.maxMeltdownDropUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.blackSwanDropUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
    
    private var watchersC2: some View {
        EmptyView()
            .onChange(of: simSettings.bearWeeklyDriftUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxMaturingDropUnified) { _ in
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.maxRecessionDropUnified) { _ in
                updateUniversalFactorIntensity()
            }
    }
}

// ----------------------------------------------------------
// MARK: - FACTOR TOGGLE WATCHERS - BULLISH
// ----------------------------------------------------------

struct FactorToggleBullishA: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            bullishA1
            bullishA2
        }
    }
    
    // We had 6 watchers in FactorToggleBullishA; split into 3 and 3
    private var bullishA1: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["Halving"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useHalvingWeekly  = isOn
                simSettings.useHalvingMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["InstitutionalDemand"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useInstitutionalDemandWeekly  = isOn
                simSettings.useInstitutionalDemandMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["CountryAdoption"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useCountryAdoptionWeekly  = isOn
                simSettings.useCountryAdoptionMonthly = isOn
            }
    }
    
    private var bullishA2: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["RegulatoryClarity"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useRegulatoryClarityWeekly  = isOn
                simSettings.useRegulatoryClarityMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["EtfApproval"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useEtfApprovalWeekly  = isOn
                simSettings.useEtfApprovalMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["TechBreakthrough"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useTechBreakthroughWeekly  = isOn
                simSettings.useTechBreakthroughMonthly = isOn
            }
    }
}

struct FactorToggleBullishB: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            bullishB1
            bullishB2
        }
    }
    
    // 6 watchers again. We'll split them 3 + 3
    private var bullishB1: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["ScarcityEvents"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useScarcityEventsWeekly  = isOn
                simSettings.useScarcityEventsMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["GlobalMacroHedge"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useGlobalMacroHedgeWeekly  = isOn
                simSettings.useGlobalMacroHedgeMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["StablecoinShift"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useStablecoinShiftWeekly  = isOn
                simSettings.useStablecoinShiftMonthly = isOn
            }
    }
    
    private var bullishB2: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["DemographicAdoption"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useDemographicAdoptionWeekly  = isOn
                simSettings.useDemographicAdoptionMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["AltcoinFlight"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useAltcoinFlightWeekly  = isOn
                simSettings.useAltcoinFlightMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["AdoptionFactor"] ?? 0) { newVal in
                let isOn = newVal > 0.5
                simSettings.useAdoptionFactorWeekly  = isOn
                simSettings.useAdoptionFactorMonthly = isOn
            }
    }
}

// ----------------------------------------------------------
// MARK: - FACTOR TOGGLE WATCHERS - BEARISH
// ----------------------------------------------------------

struct FactorToggleBearishA: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            bearishA1
            bearishA2
        }
    }
    
    // We had 5 watchers in FactorToggleBearishA
    // Let's split them 3 + 2
    private var bearishA1: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["RegClampdown"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useRegClampdownWeekly  = isOn
                simSettings.useRegClampdownMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["CompetitorCoin"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useCompetitorCoinWeekly  = isOn
                simSettings.useCompetitorCoinMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["SecurityBreach"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useSecurityBreachWeekly  = isOn
                simSettings.useSecurityBreachMonthly = isOn
            }
    }
    
    private var bearishA2: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["BubblePop"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useBubblePopWeekly  = isOn
                simSettings.useBubblePopMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["StablecoinMeltdown"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useStablecoinMeltdownWeekly  = isOn
                simSettings.useStablecoinMeltdownMonthly = isOn
            }
    }
}

struct FactorToggleBearishB: View {
    @ObservedObject var simSettings: SimulationSettings
    
    var body: some View {
        Group {
            bearishB1
            bearishB2
        }
    }
    
    // We had 4 watchers in FactorToggleBearishB
    // We'll split them 2 + 2
    private var bearishB1: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["BlackSwan"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useBlackSwanWeekly  = isOn
                simSettings.useBlackSwanMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["BearMarket"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useBearMarketWeekly  = isOn
                simSettings.useBearMarketMonthly = isOn
            }
    }
    
    private var bearishB2: some View {
        EmptyView()
            .onChange(of: simSettings.factorEnableFrac["MaturingMarket"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useMaturingMarketWeekly  = isOn
                simSettings.useMaturingMarketMonthly = isOn
            }
            .onChange(of: simSettings.factorEnableFrac["Recession"] ?? 0) { newVal in
                let isOn = (newVal > 0.5)
                simSettings.useRecessionWeekly  = isOn
                simSettings.useRecessionMonthly = isOn
            }
    }
}
