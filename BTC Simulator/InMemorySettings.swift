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
    
    // MARK: - Injected reference to SimulationSettings (so we can disable factors there)
    // CHANGED HERE: We store a reference to your main simSettings, so we can call
    // simSettings?.setFactorEnabled(...) whenever these toggles change.
    weak var simSettings: SimulationSettings?
    
    // Optionally, you can add an init that sets up this reference:
    init(simSettings: SimulationSettings? = nil) {
        self.simSettings = simSettings
    }
    
    // =============================
    // MARK: - Weekly Halving
    // =============================
    @Published var useHalvingWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingWeekly)
        }
    }
    @Published var halvingBumpWeekly: Double = 0.35

    // =============================
    // MARK: - Monthly Halving
    // =============================
    @Published var useHalvingMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingMonthly)
        }
    }
    @Published var halvingBumpMonthly: Double = 0.35

    // =============================
    // MARK: - Institutional Demand
    // =============================
    @Published var useInstitutionalDemandWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandWeekly)
        }
    }
    @Published var maxDemandBoostWeekly: Double = 0.001239

    @Published var useInstitutionalDemandMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandMonthly)
        }
    }
    @Published var maxDemandBoostMonthly: Double = 0.0056589855

    // =============================
    // MARK: - Country Adoption
    // =============================
    @Published var useCountryAdoptionWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionWeekly)
        }
    }
    @Published var maxCountryAdBoostWeekly: Double = 0.0009953916

    @Published var useCountryAdoptionMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionMonthly)
        }
    }
    @Published var maxCountryAdBoostMonthly: Double = 0.00551551595

    // =============================
    // MARK: - Regulatory Clarity
    // =============================
    @Published var useRegulatoryClarityWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityWeekly)
        }
    }
    @Published var maxClarityBoostWeekly: Double = 0.0007938497

    @Published var useRegulatoryClarityMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityMonthly)
        }
    }
    @Published var maxClarityBoostMonthly: Double = 0.0040737327

    // =============================
    // MARK: - ETF Approval
    // =============================
    @Published var useEtfApprovalWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalWeekly)
        }
    }
    @Published var maxEtfBoostWeekly: Double = 0.002

    @Published var useEtfApprovalMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalMonthly)
        }
    }
    @Published var maxEtfBoostMonthly: Double = 0.0057142851

    // =============================
    // MARK: - Tech Breakthrough
    // =============================
    @Published var useTechBreakthroughWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughWeekly)
        }
    }
    @Published var maxTechBoostWeekly: Double = 0.00071162

    @Published var useTechBreakthroughMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughMonthly)
        }
    }
    @Published var maxTechBoostMonthly: Double = 0.0028387091

    // =============================
    // MARK: - Scarcity Events
    // =============================
    @Published var useScarcityEventsWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsWeekly)
        }
    }
    @Published var maxScarcityBoostWeekly: Double = 0.00041308753

    @Published var useScarcityEventsMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsMonthly)
        }
    }
    @Published var maxScarcityBoostMonthly: Double = 0.00329287055

    // =============================
    // MARK: - Global Macro Hedge
    // =============================
    @Published var useGlobalMacroHedgeWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeWeekly)
        }
    }
    @Published var maxMacroBoostWeekly: Double = 0.00041935

    @Published var useGlobalMacroHedgeMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeMonthly)
        }
    }
    @Published var maxMacroBoostMonthly: Double = 0.0032442397

    // =============================
    // MARK: - Stablecoin Shift
    // =============================
    @Published var useStablecoinShiftWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftWeekly)
        }
    }
    @Published var maxStablecoinBoostWeekly: Double = 0.00040493

    @Published var useStablecoinShiftMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftMonthly)
        }
    }
    @Published var maxStablecoinBoostMonthly: Double = 0.0023041475

    // =============================
    // MARK: - Demographic Adoption
    // =============================
    @Published var useDemographicAdoptionWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionWeekly)
        }
    }
    @Published var maxDemoBoostWeekly: Double = 0.00130568

    @Published var useDemographicAdoptionMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionMonthly)
        }
    }
    @Published var maxDemoBoostMonthly: Double = 0.00729112471

    // =============================
    // MARK: - Altcoin Flight
    // =============================
    @Published var useAltcoinFlightWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightWeekly)
        }
    }
    @Published var maxAltcoinBoostWeekly: Double = 0.00028021945

    @Published var useAltcoinFlightMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightMonthly)
        }
    }
    @Published var maxAltcoinBoostMonthly: Double = 0.0021566817

    // =============================
    // MARK: - Adoption Factor
    // =============================
    @Published var useAdoptionFactorWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorWeekly)
        }
    }
    @Published var adoptionBaseFactorWeekly: Double = 0.0016045109

    @Published var useAdoptionFactorMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorMonthly)
        }
    }
    @Published var adoptionBaseFactorMonthly: Double = 0.01466095993

    // =============================
    // MARK: - Regulatory Clampdown
    // =============================
    @Published var useRegClampdownWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownWeekly)
        }
    }
    @Published var maxClampDownWeekly: Double = -0.00194128856

    @Published var useRegClampdownMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownMonthly)
        }
    }
    @Published var maxClampDownMonthly: Double = -0.02

    // =============================
    // MARK: - Competitor Coin
    // =============================
    @Published var useCompetitorCoinWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinWeekly)
        }
    }
    @Published var maxCompetitorBoostWeekly: Double = -0.0011293145

    @Published var useCompetitorCoinMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinMonthly)
        }
    }
    @Published var maxCompetitorBoostMonthly: Double = -0.008

    // =============================
    // MARK: - Security Breach
    // =============================
    @Published var useSecurityBreachWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachWeekly)
        }
    }
    @Published var breachImpactWeekly: Double = -0.0012699694

    @Published var useSecurityBreachMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachMonthly)
        }
    }
    @Published var breachImpactMonthly: Double = -0.007

    // =============================
    // MARK: - Bubble Pop
    // =============================
    @Published var useBubblePopWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopWeekly)
        }
    }
    @Published var maxPopDropWeekly: Double = -0.00321428597

    @Published var useBubblePopMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopMonthly)
        }
    }
    @Published var maxPopDropMonthly: Double = -0.01

    // =============================
    // MARK: - Stablecoin Meltdown
    // =============================
    @Published var useStablecoinMeltdownWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownWeekly)
        }
    }
    @Published var maxMeltdownDropWeekly: Double = -0.00169354829

    @Published var useStablecoinMeltdownMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownMonthly)
        }
    }
    @Published var maxMeltdownDropMonthly: Double = -0.01

    // =============================
    // MARK: - Black Swan
    // =============================
    @Published var useBlackSwanWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanWeekly)
        }
    }
    @Published var blackSwanDropWeekly: Double = -0.7977726936

    @Published var useBlackSwanMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanMonthly)
        }
    }
    @Published var blackSwanDropMonthly: Double = -0.4

    // =============================
    // MARK: - Bear Market
    // =============================
    @Published var useBearMarketWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketWeekly)
        }
    }
    @Published var bearWeeklyDriftWeekly: Double = -0.001

    @Published var useBearMarketMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketMonthly)
        }
    }
    @Published var bearWeeklyDriftMonthly: Double = -0.01

    // =============================
    // MARK: - Maturing Market
    // =============================
    @Published var useMaturingMarketWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketWeekly)
        }
    }
    @Published var maxMaturingDropWeekly: Double = -0.00326881742

    @Published var useMaturingMarketMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketMonthly)
        }
    }
    @Published var maxMaturingDropMonthly: Double = -0.01

    // =============================
    // MARK: - Recession
    // =============================
    @Published var useRecessionWeekly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionWeekly)
        }
    }
    @Published var maxRecessionDropWeekly: Double = -0.00100731624

    @Published var useRecessionMonthly: Bool = true {
        didSet {
            simSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionMonthly)
        }
    }
    @Published var maxRecessionDropMonthly: Double = -0.00145080805

    // Simple init with no direct reading from UserDefaults in the constructor.
    // We rely on 'loadFromUserDefaults()' if needed.
    
    // =============================
    // MARK: - Toggling All Off
    // =============================
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
    
    // MARK: - Load & Save to UserDefaults (batch approach)
    // (Unchanged except for your usual reading/writing; omitted for brevity)

    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // ... same as before ...
        
        // After loading, you could do a single call to apply these toggles to simSettings if you want:
        applyAllTogglesToSimulation()
    }
    
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        
        // ... same as before ...
        
        defaults.synchronize()
    }
    
    /// CHANGED HERE: optional convenience method to push all toggles to simSettings at once
    func applyAllTogglesToSimulation() {
        simSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingWeekly || useHalvingMonthly)
        simSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandWeekly || useInstitutionalDemandMonthly)
        simSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionWeekly || useCountryAdoptionMonthly)
        simSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityWeekly || useRegulatoryClarityMonthly)
        simSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalWeekly || useEtfApprovalMonthly)
        simSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughWeekly || useTechBreakthroughMonthly)
        simSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsWeekly || useScarcityEventsMonthly)
        simSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeWeekly || useGlobalMacroHedgeMonthly)
        simSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftWeekly || useStablecoinShiftMonthly)
        simSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionWeekly || useDemographicAdoptionMonthly)
        simSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightWeekly || useAltcoinFlightMonthly)
        simSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorWeekly || useAdoptionFactorMonthly)
        simSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownWeekly || useRegClampdownMonthly)
        simSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinWeekly || useCompetitorCoinMonthly)
        simSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachWeekly || useSecurityBreachMonthly)
        simSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopWeekly || useBubblePopMonthly)
        simSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownWeekly || useStablecoinMeltdownMonthly)
        simSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanWeekly || useBlackSwanMonthly)
        simSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketWeekly || useBearMarketMonthly)
        simSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketWeekly || useMaturingMarketMonthly)
        simSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionWeekly || useRecessionMonthly)
    }
}
