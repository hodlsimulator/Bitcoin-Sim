//
//  InMemorySettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/01/2025.
//

import SwiftUI

/// A pure in-memory model for all your bullish/bearish factor toggles.
/// We load/save from UserDefaults only when we decide to (batching).
class InMemorySettings: ObservableObject {
    // =============================
    // MARK: - Weekly Halving
    // =============================
    @Published var useHalvingWeekly: Bool = true
    @Published var halvingBumpWeekly: Double = 0.35

    // =============================
    // MARK: - Monthly Halving
    // =============================
    @Published var useHalvingMonthly: Bool = true
    @Published var halvingBumpMonthly: Double = 0.35

    // =============================
    // MARK: - Institutional Demand
    // =============================
    @Published var useInstitutionalDemandWeekly: Bool = true
    @Published var maxDemandBoostWeekly: Double = 0.001239
    @Published var useInstitutionalDemandMonthly: Bool = true
    @Published var maxDemandBoostMonthly: Double = 0.0056589855

    // =============================
    // MARK: - Country Adoption
    // =============================
    @Published var useCountryAdoptionWeekly: Bool = true
    @Published var maxCountryAdBoostWeekly: Double = 0.0009953916
    @Published var useCountryAdoptionMonthly: Bool = true
    @Published var maxCountryAdBoostMonthly: Double = 0.00551551595

    // =============================
    // MARK: - Regulatory Clarity
    // =============================
    @Published var useRegulatoryClarityWeekly: Bool = true
    @Published var maxClarityBoostWeekly: Double = 0.0007938497
    @Published var useRegulatoryClarityMonthly: Bool = true
    @Published var maxClarityBoostMonthly: Double = 0.0040737327

    // =============================
    // MARK: - ETF Approval
    // =============================
    @Published var useEtfApprovalWeekly: Bool = true
    @Published var maxEtfBoostWeekly: Double = 0.002
    @Published var useEtfApprovalMonthly: Bool = true
    @Published var maxEtfBoostMonthly: Double = 0.0057142851

    // =============================
    // MARK: - Tech Breakthrough
    // =============================
    @Published var useTechBreakthroughWeekly: Bool = true
    @Published var maxTechBoostWeekly: Double = 0.00071162
    @Published var useTechBreakthroughMonthly: Bool = true
    @Published var maxTechBoostMonthly: Double = 0.0028387091

    // =============================
    // MARK: - Scarcity Events
    // =============================
    @Published var useScarcityEventsWeekly: Bool = true
    @Published var maxScarcityBoostWeekly: Double = 0.00041308753
    @Published var useScarcityEventsMonthly: Bool = true
    @Published var maxScarcityBoostMonthly: Double = 0.00329287055

    // =============================
    // MARK: - Global Macro Hedge
    // =============================
    @Published var useGlobalMacroHedgeWeekly: Bool = true
    @Published var maxMacroBoostWeekly: Double = 0.00041935
    @Published var useGlobalMacroHedgeMonthly: Bool = true
    @Published var maxMacroBoostMonthly: Double = 0.0032442397

    // =============================
    // MARK: - Stablecoin Shift
    // =============================
    @Published var useStablecoinShiftWeekly: Bool = true
    @Published var maxStablecoinBoostWeekly: Double = 0.00040493
    @Published var useStablecoinShiftMonthly: Bool = true
    @Published var maxStablecoinBoostMonthly: Double = 0.0023041475

    // =============================
    // MARK: - Demographic Adoption
    // =============================
    @Published var useDemographicAdoptionWeekly: Bool = true
    @Published var maxDemoBoostWeekly: Double = 0.00130568
    @Published var useDemographicAdoptionMonthly: Bool = true
    @Published var maxDemoBoostMonthly: Double = 0.00729112471

    // =============================
    // MARK: - Altcoin Flight
    // =============================
    @Published var useAltcoinFlightWeekly: Bool = true
    @Published var maxAltcoinBoostWeekly: Double = 0.00028021945
    @Published var useAltcoinFlightMonthly: Bool = true
    @Published var maxAltcoinBoostMonthly: Double = 0.0021566817

    // =============================
    // MARK: - Adoption Factor
    // =============================
    @Published var useAdoptionFactorWeekly: Bool = true
    @Published var adoptionBaseFactorWeekly: Double = 0.0016045109
    @Published var useAdoptionFactorMonthly: Bool = true
    @Published var adoptionBaseFactorMonthly: Double = 0.01466095993

    // =============================
    // MARK: - Regulatory Clampdown
    // =============================
    @Published var useRegClampdownWeekly: Bool = true
    @Published var maxClampDownWeekly: Double = -0.00194128856
    @Published var useRegClampdownMonthly: Bool = true
    @Published var maxClampDownMonthly: Double = -0.02

    // =============================
    // MARK: - Competitor Coin
    // =============================
    @Published var useCompetitorCoinWeekly: Bool = true
    @Published var maxCompetitorBoostWeekly: Double = -0.0011293145
    @Published var useCompetitorCoinMonthly: Bool = true
    @Published var maxCompetitorBoostMonthly: Double = -0.008

    // =============================
    // MARK: - Security Breach
    // =============================
    @Published var useSecurityBreachWeekly: Bool = true
    @Published var breachImpactWeekly: Double = -0.0012699694
    @Published var useSecurityBreachMonthly: Bool = true
    @Published var breachImpactMonthly: Double = -0.007

    // =============================
    // MARK: - Bubble Pop
    // =============================
    @Published var useBubblePopWeekly: Bool = true
    @Published var maxPopDropWeekly: Double = -0.00321428597
    @Published var useBubblePopMonthly: Bool = true
    @Published var maxPopDropMonthly: Double = -0.01

    // =============================
    // MARK: - Stablecoin Meltdown
    // =============================
    @Published var useStablecoinMeltdownWeekly: Bool = true
    @Published var maxMeltdownDropWeekly: Double = -0.00169354829
    @Published var useStablecoinMeltdownMonthly: Bool = true
    @Published var maxMeltdownDropMonthly: Double = -0.01

    // =============================
    // MARK: - Black Swan
    // =============================
    @Published var useBlackSwanWeekly: Bool = true
    @Published var blackSwanDropWeekly: Double = -0.7977726936
    @Published var useBlackSwanMonthly: Bool = true
    @Published var blackSwanDropMonthly: Double = -0.4

    // =============================
    // MARK: - Bear Market
    // =============================
    @Published var useBearMarketWeekly: Bool = true
    @Published var bearWeeklyDriftWeekly: Double = -0.001
    @Published var useBearMarketMonthly: Bool = true
    @Published var bearWeeklyDriftMonthly: Double = -0.01

    // =============================
    // MARK: - Maturing Market
    // =============================
    @Published var useMaturingMarketWeekly: Bool = true
    @Published var maxMaturingDropWeekly: Double = -0.00326881742
    @Published var useMaturingMarketMonthly: Bool = true
    @Published var maxMaturingDropMonthly: Double = -0.01

    // =============================
    // MARK: - Recession
    // =============================
    @Published var useRecessionWeekly: Bool = true
    @Published var maxRecessionDropWeekly: Double = -0.00100731624
    @Published var useRecessionMonthly: Bool = true
    @Published var maxRecessionDropMonthly: Double = -0.00145080805

    // Simple init (no direct reading from UserDefaults).
    init() { }
}

// MARK: - Helpers for toggling everything off
extension InMemorySettings {
    func turnOffMonthlyToggles() {
        useHalvingMonthly = false
        useInstitutionalDemandMonthly = false
        useCountryAdoptionMonthly = false
        useRegulatoryClarityMonthly = false
        useEtfApprovalMonthly = false
        useTechBreakthroughMonthly = false
        useScarcityEventsMonthly = false
        useGlobalMacroHedgeMonthly = false
        useStablecoinShiftMonthly = false
        useDemographicAdoptionMonthly = false
        useAltcoinFlightMonthly = false
        useAdoptionFactorMonthly = false
        useRegClampdownMonthly = false
        useCompetitorCoinMonthly = false
        useSecurityBreachMonthly = false
        useBubblePopMonthly = false
        useStablecoinMeltdownMonthly = false
        useBlackSwanMonthly = false
        useBearMarketMonthly = false
        useMaturingMarketMonthly = false
        useRecessionMonthly = false
    }
    
    func turnOffWeeklyToggles() {
        useHalvingWeekly = false
        useInstitutionalDemandWeekly = false
        useCountryAdoptionWeekly = false
        useRegulatoryClarityWeekly = false
        useEtfApprovalWeekly = false
        useTechBreakthroughWeekly = false
        useScarcityEventsWeekly = false
        useGlobalMacroHedgeWeekly = false
        useStablecoinShiftWeekly = false
        useDemographicAdoptionWeekly = false
        useAltcoinFlightWeekly = false
        useAdoptionFactorWeekly = false
        useRegClampdownWeekly = false
        useCompetitorCoinWeekly = false
        useSecurityBreachWeekly = false
        useBubblePopWeekly = false
        useStablecoinMeltdownWeekly = false
        useBlackSwanWeekly = false
        useBearMarketWeekly = false
        useMaturingMarketWeekly = false
        useRecessionWeekly = false
    }
}

// MARK: - Load & Save to UserDefaults (batch approach)
extension InMemorySettings {
    
    /// Reads all toggles/factors from UserDefaults into this model.
    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        useHalvingWeekly = defaults.bool(forKey: "useHalvingWeekly")
        halvingBumpWeekly = defaults.double(forKey: "halvingBumpWeekly")
        useHalvingMonthly = defaults.bool(forKey: "useHalvingMonthly")
        halvingBumpMonthly = defaults.double(forKey: "halvingBumpMonthly")
        
        useInstitutionalDemandWeekly = defaults.bool(forKey: "useInstitutionalDemandWeekly")
        maxDemandBoostWeekly = defaults.double(forKey: "maxDemandBoostWeekly")
        useInstitutionalDemandMonthly = defaults.bool(forKey: "useInstitutionalDemandMonthly")
        maxDemandBoostMonthly = defaults.double(forKey: "maxDemandBoostMonthly")
        
        useCountryAdoptionWeekly = defaults.bool(forKey: "useCountryAdoptionWeekly")
        maxCountryAdBoostWeekly = defaults.double(forKey: "maxCountryAdBoostWeekly")
        useCountryAdoptionMonthly = defaults.bool(forKey: "useCountryAdoptionMonthly")
        maxCountryAdBoostMonthly = defaults.double(forKey: "maxCountryAdBoostMonthly")
        
        useRegulatoryClarityWeekly = defaults.bool(forKey: "useRegulatoryClarityWeekly")
        maxClarityBoostWeekly = defaults.double(forKey: "maxClarityBoostWeekly")
        useRegulatoryClarityMonthly = defaults.bool(forKey: "useRegulatoryClarityMonthly")
        maxClarityBoostMonthly = defaults.double(forKey: "maxClarityBoostMonthly")
        
        useEtfApprovalWeekly = defaults.bool(forKey: "useEtfApprovalWeekly")
        maxEtfBoostWeekly = defaults.double(forKey: "maxEtfBoostWeekly")
        useEtfApprovalMonthly = defaults.bool(forKey: "useEtfApprovalMonthly")
        maxEtfBoostMonthly = defaults.double(forKey: "maxEtfBoostMonthly")
        
        useTechBreakthroughWeekly = defaults.bool(forKey: "useTechBreakthroughWeekly")
        maxTechBoostWeekly = defaults.double(forKey: "maxTechBoostWeekly")
        useTechBreakthroughMonthly = defaults.bool(forKey: "useTechBreakthroughMonthly")
        maxTechBoostMonthly = defaults.double(forKey: "maxTechBoostMonthly")
        
        useScarcityEventsWeekly = defaults.bool(forKey: "useScarcityEventsWeekly")
        maxScarcityBoostWeekly = defaults.double(forKey: "maxScarcityBoostWeekly")
        useScarcityEventsMonthly = defaults.bool(forKey: "useScarcityEventsMonthly")
        maxScarcityBoostMonthly = defaults.double(forKey: "maxScarcityBoostMonthly")
        
        useGlobalMacroHedgeWeekly = defaults.bool(forKey: "useGlobalMacroHedgeWeekly")
        maxMacroBoostWeekly = defaults.double(forKey: "maxMacroBoostWeekly")
        useGlobalMacroHedgeMonthly = defaults.bool(forKey: "useGlobalMacroHedgeMonthly")
        maxMacroBoostMonthly = defaults.double(forKey: "maxMacroBoostMonthly")
        
        useStablecoinShiftWeekly = defaults.bool(forKey: "useStablecoinShiftWeekly")
        maxStablecoinBoostWeekly = defaults.double(forKey: "maxStablecoinBoostWeekly")
        useStablecoinShiftMonthly = defaults.bool(forKey: "useStablecoinShiftMonthly")
        maxStablecoinBoostMonthly = defaults.double(forKey: "maxStablecoinBoostMonthly")
        
        useDemographicAdoptionWeekly = defaults.bool(forKey: "useDemographicAdoptionWeekly")
        maxDemoBoostWeekly = defaults.double(forKey: "maxDemoBoostWeekly")
        useDemographicAdoptionMonthly = defaults.bool(forKey: "useDemographicAdoptionMonthly")
        maxDemoBoostMonthly = defaults.double(forKey: "maxDemoBoostMonthly")
        
        useAltcoinFlightWeekly = defaults.bool(forKey: "useAltcoinFlightWeekly")
        maxAltcoinBoostWeekly = defaults.double(forKey: "maxAltcoinBoostWeekly")
        useAltcoinFlightMonthly = defaults.bool(forKey: "useAltcoinFlightMonthly")
        maxAltcoinBoostMonthly = defaults.double(forKey: "maxAltcoinBoostMonthly")
        
        useAdoptionFactorWeekly = defaults.bool(forKey: "useAdoptionFactorWeekly")
        adoptionBaseFactorWeekly = defaults.double(forKey: "adoptionBaseFactorWeekly")
        useAdoptionFactorMonthly = defaults.bool(forKey: "useAdoptionFactorMonthly")
        adoptionBaseFactorMonthly = defaults.double(forKey: "adoptionBaseFactorMonthly")
        
        useRegClampdownWeekly = defaults.bool(forKey: "useRegClampdownWeekly")
        maxClampDownWeekly = defaults.double(forKey: "maxClampDownWeekly")
        useRegClampdownMonthly = defaults.bool(forKey: "useRegClampdownMonthly")
        maxClampDownMonthly = defaults.double(forKey: "maxClampDownMonthly")
        
        useCompetitorCoinWeekly = defaults.bool(forKey: "useCompetitorCoinWeekly")
        maxCompetitorBoostWeekly = defaults.double(forKey: "maxCompetitorBoostWeekly")
        useCompetitorCoinMonthly = defaults.bool(forKey: "useCompetitorCoinMonthly")
        maxCompetitorBoostMonthly = defaults.double(forKey: "maxCompetitorBoostMonthly")
        
        useSecurityBreachWeekly = defaults.bool(forKey: "useSecurityBreachWeekly")
        breachImpactWeekly = defaults.double(forKey: "breachImpactWeekly")
        useSecurityBreachMonthly = defaults.bool(forKey: "useSecurityBreachMonthly")
        breachImpactMonthly = defaults.double(forKey: "breachImpactMonthly")
        
        useBubblePopWeekly = defaults.bool(forKey: "useBubblePopWeekly")
        maxPopDropWeekly = defaults.double(forKey: "maxPopDropWeekly")
        useBubblePopMonthly = defaults.bool(forKey: "useBubblePopMonthly")
        maxPopDropMonthly = defaults.double(forKey: "maxPopDropMonthly")
        
        useStablecoinMeltdownWeekly = defaults.bool(forKey: "useStablecoinMeltdownWeekly")
        maxMeltdownDropWeekly = defaults.double(forKey: "maxMeltdownDropWeekly")
        useStablecoinMeltdownMonthly = defaults.bool(forKey: "useStablecoinMeltdownMonthly")
        maxMeltdownDropMonthly = defaults.double(forKey: "maxMeltdownDropMonthly")
        
        useBlackSwanWeekly = defaults.bool(forKey: "useBlackSwanWeekly")
        blackSwanDropWeekly = defaults.double(forKey: "blackSwanDropWeekly")
        useBlackSwanMonthly = defaults.bool(forKey: "useBlackSwanMonthly")
        blackSwanDropMonthly = defaults.double(forKey: "blackSwanDropMonthly")
        
        useBearMarketWeekly = defaults.bool(forKey: "useBearMarketWeekly")
        bearWeeklyDriftWeekly = defaults.double(forKey: "bearWeeklyDriftWeekly")
        useBearMarketMonthly = defaults.bool(forKey: "useBearMarketMonthly")
        bearWeeklyDriftMonthly = defaults.double(forKey: "bearWeeklyDriftMonthly")
        
        useMaturingMarketWeekly = defaults.bool(forKey: "useMaturingMarketWeekly")
        maxMaturingDropWeekly = defaults.double(forKey: "maxMaturingDropWeekly")
        useMaturingMarketMonthly = defaults.bool(forKey: "useMaturingMarketMonthly")
        maxMaturingDropMonthly = defaults.double(forKey: "maxMaturingDropMonthly")
        
        useRecessionWeekly = defaults.bool(forKey: "useRecessionWeekly")
        maxRecessionDropWeekly = defaults.double(forKey: "maxRecessionDropWeekly")
        useRecessionMonthly = defaults.bool(forKey: "useRecessionMonthly")
        maxRecessionDropMonthly = defaults.double(forKey: "maxRecessionDropMonthly")
    }
    
    /// Saves all toggles/factors into UserDefaults (in one shot).
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        
        defaults.set(useHalvingWeekly, forKey: "useHalvingWeekly")
        defaults.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
        defaults.set(useHalvingMonthly, forKey: "useHalvingMonthly")
        defaults.set(halvingBumpMonthly, forKey: "halvingBumpMonthly")

        defaults.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
        defaults.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
        defaults.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
        defaults.set(maxDemandBoostMonthly, forKey: "maxDemandBoostMonthly")

        defaults.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
        defaults.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
        defaults.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
        defaults.set(maxCountryAdBoostMonthly, forKey: "maxCountryAdBoostMonthly")

        defaults.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
        defaults.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
        defaults.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
        defaults.set(maxClarityBoostMonthly, forKey: "maxClarityBoostMonthly")

        defaults.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
        defaults.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
        defaults.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
        defaults.set(maxEtfBoostMonthly, forKey: "maxEtfBoostMonthly")

        defaults.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
        defaults.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
        defaults.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
        defaults.set(maxTechBoostMonthly, forKey: "maxTechBoostMonthly")

        defaults.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
        defaults.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
        defaults.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
        defaults.set(maxScarcityBoostMonthly, forKey: "maxScarcityBoostMonthly")

        defaults.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
        defaults.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
        defaults.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
        defaults.set(maxMacroBoostMonthly, forKey: "maxMacroBoostMonthly")

        defaults.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
        defaults.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
        defaults.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
        defaults.set(maxStablecoinBoostMonthly, forKey: "maxStablecoinBoostMonthly")

        defaults.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
        defaults.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
        defaults.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
        defaults.set(maxDemoBoostMonthly, forKey: "maxDemoBoostMonthly")

        defaults.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
        defaults.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
        defaults.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
        defaults.set(maxAltcoinBoostMonthly, forKey: "maxAltcoinBoostMonthly")

        defaults.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
        defaults.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
        defaults.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
        defaults.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")

        defaults.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
        defaults.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
        defaults.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
        defaults.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")

        defaults.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
        defaults.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
        defaults.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
        defaults.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")

        defaults.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
        defaults.set(breachImpactWeekly, forKey: "breachImpactWeekly")
        defaults.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
        defaults.set(breachImpactMonthly, forKey: "breachImpactMonthly")

        defaults.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
        defaults.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
        defaults.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
        defaults.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")

        defaults.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
        defaults.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
        defaults.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
        defaults.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")

        defaults.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
        defaults.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
        defaults.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
        defaults.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")

        defaults.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
        defaults.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
        defaults.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
        defaults.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")

        defaults.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
        defaults.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
        defaults.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
        defaults.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")

        defaults.set(useRecessionWeekly, forKey: "useRecessionWeekly")
        defaults.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
        defaults.set(useRecessionMonthly, forKey: "useRecessionMonthly")
        defaults.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")

        // Optional immediate flush to disk
        defaults.synchronize()
    }
}
