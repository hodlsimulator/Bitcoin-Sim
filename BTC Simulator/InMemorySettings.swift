//
//  InMemorySettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/01/2025.
//

import SwiftUI

/// A pure in‐memory model for all your bullish/bearish factor toggles.
/// We load/save from UserDefaults only when we decide to (batching).
class InMemorySettings: ObservableObject {
    
    // MARK: - References to both weekly & monthly objects
    weak var weeklySimSettings: SimulationSettings?
    weak var monthlySimSettings: MonthlySimulationSettings?
    
    // Optionally, you can add an init that sets up these references:
    init(weekly: SimulationSettings? = nil, monthly: MonthlySimulationSettings? = nil) {
        self.weeklySimSettings = weekly
        self.monthlySimSettings = monthly
        print("[InMemorySettings] Initialized with weeklySimSettings: \(weekly != nil), monthlySimSettings: \(monthly != nil)")
    }
    
    // =============================
    // MARK: - Weekly Halving
    // =============================
    @Published var useHalvingWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useHalvingWeekly changed to \(useHalvingWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingWeekly)
        }
    }
    @Published var halvingBumpWeekly: Double = 0.35 {
        didSet {
            print("[InMemorySettings] halvingBumpWeekly changed to \(halvingBumpWeekly)")
        }
    }
    
    // =============================
    // MARK: - Monthly Halving
    // =============================
    @Published var useHalvingMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useHalvingMonthly changed to \(useHalvingMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingMonthly)
        }
    }
    @Published var halvingBumpMonthly: Double = 0.35 {
        didSet {
            print("[InMemorySettings] halvingBumpMonthly changed to \(halvingBumpMonthly)")
        }
    }
    
    // =============================
    // MARK: - Institutional Demand
    // =============================
    @Published var useInstitutionalDemandWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useInstitutionalDemandWeekly changed to \(useInstitutionalDemandWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandWeekly)
        }
    }
    @Published var maxDemandBoostWeekly: Double = 0.001239 {
        didSet {
            print("[InMemorySettings] maxDemandBoostWeekly changed to \(maxDemandBoostWeekly)")
        }
    }
    
    @Published var useInstitutionalDemandMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useInstitutionalDemandMonthly changed to \(useInstitutionalDemandMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandMonthly)
        }
    }
    @Published var maxDemandBoostMonthly: Double = 0.0056589855 {
        didSet {
            print("[InMemorySettings] maxDemandBoostMonthly changed to \(maxDemandBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Country Adoption
    // =============================
    @Published var useCountryAdoptionWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useCountryAdoptionWeekly changed to \(useCountryAdoptionWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionWeekly)
        }
    }
    @Published var maxCountryAdBoostWeekly: Double = 0.0009953916 {
        didSet {
            print("[InMemorySettings] maxCountryAdBoostWeekly changed to \(maxCountryAdBoostWeekly)")
        }
    }
    
    @Published var useCountryAdoptionMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useCountryAdoptionMonthly changed to \(useCountryAdoptionMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionMonthly)
        }
    }
    @Published var maxCountryAdBoostMonthly: Double = 0.00551551595 {
        didSet {
            print("[InMemorySettings] maxCountryAdBoostMonthly changed to \(maxCountryAdBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Regulatory Clarity
    // =============================
    @Published var useRegulatoryClarityWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useRegulatoryClarityWeekly changed to \(useRegulatoryClarityWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityWeekly)
        }
    }
    @Published var maxClarityBoostWeekly: Double = 0.0007938497 {
        didSet {
            print("[InMemorySettings] maxClarityBoostWeekly changed to \(maxClarityBoostWeekly)")
        }
    }
    
    @Published var useRegulatoryClarityMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useRegulatoryClarityMonthly changed to \(useRegulatoryClarityMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityMonthly)
        }
    }
    @Published var maxClarityBoostMonthly: Double = 0.0040737327 {
        didSet {
            print("[InMemorySettings] maxClarityBoostMonthly changed to \(maxClarityBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - ETF Approval
    // =============================
    @Published var useEtfApprovalWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useEtfApprovalWeekly changed to \(useEtfApprovalWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalWeekly)
        }
    }
    @Published var maxEtfBoostWeekly: Double = 0.002 {
        didSet {
            print("[InMemorySettings] maxEtfBoostWeekly changed to \(maxEtfBoostWeekly)")
        }
    }
    
    @Published var useEtfApprovalMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useEtfApprovalMonthly changed to \(useEtfApprovalMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalMonthly)
        }
    }
    @Published var maxEtfBoostMonthly: Double = 0.0057142851 {
        didSet {
            print("[InMemorySettings] maxEtfBoostMonthly changed to \(maxEtfBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Tech Breakthrough
    // =============================
    @Published var useTechBreakthroughWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useTechBreakthroughWeekly changed to \(useTechBreakthroughWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughWeekly)
        }
    }
    @Published var maxTechBoostWeekly: Double = 0.00071162 {
        didSet {
            print("[InMemorySettings] maxTechBoostWeekly changed to \(maxTechBoostWeekly)")
        }
    }
    
    @Published var useTechBreakthroughMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useTechBreakthroughMonthly changed to \(useTechBreakthroughMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughMonthly)
        }
    }
    @Published var maxTechBoostMonthly: Double = 0.0028387091 {
        didSet {
            print("[InMemorySettings] maxTechBoostMonthly changed to \(maxTechBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Scarcity Events
    // =============================
    @Published var useScarcityEventsWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useScarcityEventsWeekly changed to \(useScarcityEventsWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsWeekly)
        }
    }
    @Published var maxScarcityBoostWeekly: Double = 0.00041308753 {
        didSet {
            print("[InMemorySettings] maxScarcityBoostWeekly changed to \(maxScarcityBoostWeekly)")
        }
    }
    
    @Published var useScarcityEventsMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useScarcityEventsMonthly changed to \(useScarcityEventsMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsMonthly)
        }
    }
    @Published var maxScarcityBoostMonthly: Double = 0.00329287055 {
        didSet {
            print("[InMemorySettings] maxScarcityBoostMonthly changed to \(maxScarcityBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Global Macro Hedge
    // =============================
    @Published var useGlobalMacroHedgeWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useGlobalMacroHedgeWeekly changed to \(useGlobalMacroHedgeWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeWeekly)
        }
    }
    @Published var maxMacroBoostWeekly: Double = 0.00041935 {
        didSet {
            print("[InMemorySettings] maxMacroBoostWeekly changed to \(maxMacroBoostWeekly)")
        }
    }
    
    @Published var useGlobalMacroHedgeMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useGlobalMacroHedgeMonthly changed to \(useGlobalMacroHedgeMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeMonthly)
        }
    }
    @Published var maxMacroBoostMonthly: Double = 0.0032442397 {
        didSet {
            print("[InMemorySettings] maxMacroBoostMonthly changed to \(maxMacroBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Stablecoin Shift
    // =============================
    @Published var useStablecoinShiftWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useStablecoinShiftWeekly changed to \(useStablecoinShiftWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftWeekly)
        }
    }
    @Published var maxStablecoinBoostWeekly: Double = 0.00040493 {
        didSet {
            print("[InMemorySettings] maxStablecoinBoostWeekly changed to \(maxStablecoinBoostWeekly)")
        }
    }
    
    @Published var useStablecoinShiftMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useStablecoinShiftMonthly changed to \(useStablecoinShiftMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftMonthly)
        }
    }
    @Published var maxStablecoinBoostMonthly: Double = 0.0023041475 {
        didSet {
            print("[InMemorySettings] maxStablecoinBoostMonthly changed to \(maxStablecoinBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Demographic Adoption
    // =============================
    @Published var useDemographicAdoptionWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useDemographicAdoptionWeekly changed to \(useDemographicAdoptionWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionWeekly)
        }
    }
    @Published var maxDemoBoostWeekly: Double = 0.00130568 {
        didSet {
            print("[InMemorySettings] maxDemoBoostWeekly changed to \(maxDemoBoostWeekly)")
        }
    }
    
    @Published var useDemographicAdoptionMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useDemographicAdoptionMonthly changed to \(useDemographicAdoptionMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionMonthly)
        }
    }
    @Published var maxDemoBoostMonthly: Double = 0.00729112471 {
        didSet {
            print("[InMemorySettings] maxDemoBoostMonthly changed to \(maxDemoBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Altcoin Flight
    // =============================
    @Published var useAltcoinFlightWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useAltcoinFlightWeekly changed to \(useAltcoinFlightWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightWeekly)
        }
    }
    @Published var maxAltcoinBoostWeekly: Double = 0.00028021945 {
        didSet {
            print("[InMemorySettings] maxAltcoinBoostWeekly changed to \(maxAltcoinBoostWeekly)")
        }
    }
    
    @Published var useAltcoinFlightMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useAltcoinFlightMonthly changed to \(useAltcoinFlightMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightMonthly)
        }
    }
    @Published var maxAltcoinBoostMonthly: Double = 0.0021566817 {
        didSet {
            print("[InMemorySettings] maxAltcoinBoostMonthly changed to \(maxAltcoinBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Adoption Factor
    // =============================
    @Published var useAdoptionFactorWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useAdoptionFactorWeekly changed to \(useAdoptionFactorWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorWeekly)
        }
    }
    @Published var adoptionBaseFactorWeekly: Double = 0.0016045109 {
        didSet {
            print("[InMemorySettings] adoptionBaseFactorWeekly changed to \(adoptionBaseFactorWeekly)")
        }
    }
    
    @Published var useAdoptionFactorMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useAdoptionFactorMonthly changed to \(useAdoptionFactorMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorMonthly)
        }
    }
    @Published var adoptionBaseFactorMonthly: Double = 0.01466095993 {
        didSet {
            print("[InMemorySettings] adoptionBaseFactorMonthly changed to \(adoptionBaseFactorMonthly)")
        }
    }
    
    // =============================
    // MARK: - Regulatory Clampdown
    // =============================
    @Published var useRegClampdownWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useRegClampdownWeekly changed to \(useRegClampdownWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownWeekly)
        }
    }
    @Published var maxClampDownWeekly: Double = -0.00194128856 {
        didSet {
            print("[InMemorySettings] maxClampDownWeekly changed to \(maxClampDownWeekly)")
        }
    }
    
    @Published var useRegClampdownMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useRegClampdownMonthly changed to \(useRegClampdownMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownMonthly)
        }
    }
    @Published var maxClampDownMonthly: Double = -0.02 {
        didSet {
            print("[InMemorySettings] maxClampDownMonthly changed to \(maxClampDownMonthly)")
        }
    }
    
    // =============================
    // MARK: - Competitor Coin
    // =============================
    @Published var useCompetitorCoinWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useCompetitorCoinWeekly changed to \(useCompetitorCoinWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinWeekly)
        }
    }
    @Published var maxCompetitorBoostWeekly: Double = -0.0011293145 {
        didSet {
            print("[InMemorySettings] maxCompetitorBoostWeekly changed to \(maxCompetitorBoostWeekly)")
        }
    }
    
    @Published var useCompetitorCoinMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useCompetitorCoinMonthly changed to \(useCompetitorCoinMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinMonthly)
        }
    }
    @Published var maxCompetitorBoostMonthly: Double = -0.008 {
        didSet {
            print("[InMemorySettings] maxCompetitorBoostMonthly changed to \(maxCompetitorBoostMonthly)")
        }
    }
    
    // =============================
    // MARK: - Security Breach
    // =============================
    @Published var useSecurityBreachWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useSecurityBreachWeekly changed to \(useSecurityBreachWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachWeekly)
        }
    }
    @Published var breachImpactWeekly: Double = -0.0012699694 {
        didSet {
            print("[InMemorySettings] breachImpactWeekly changed to \(breachImpactWeekly)")
        }
    }
    
    @Published var useSecurityBreachMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useSecurityBreachMonthly changed to \(useSecurityBreachMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachMonthly)
        }
    }
    @Published var breachImpactMonthly: Double = -0.007 {
        didSet {
            print("[InMemorySettings] breachImpactMonthly changed to \(breachImpactMonthly)")
        }
    }
    
    // =============================
    // MARK: - Bubble Pop
    // =============================
    @Published var useBubblePopWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useBubblePopWeekly changed to \(useBubblePopWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopWeekly)
        }
    }
    @Published var maxPopDropWeekly: Double = -0.00321428597 {
        didSet {
            print("[InMemorySettings] maxPopDropWeekly changed to \(maxPopDropWeekly)")
        }
    }
    
    @Published var useBubblePopMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useBubblePopMonthly changed to \(useBubblePopMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopMonthly)
        }
    }
    @Published var maxPopDropMonthly: Double = -0.01 {
        didSet {
            print("[InMemorySettings] maxPopDropMonthly changed to \(maxPopDropMonthly)")
        }
    }
    
    // =============================
    // MARK: - Stablecoin Meltdown
    // =============================
    @Published var useStablecoinMeltdownWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useStablecoinMeltdownWeekly changed to \(useStablecoinMeltdownWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownWeekly)
        }
    }
    @Published var maxMeltdownDropWeekly: Double = -0.00169354829 {
        didSet {
            print("[InMemorySettings] maxMeltdownDropWeekly changed to \(maxMeltdownDropWeekly)")
        }
    }
    
    @Published var useStablecoinMeltdownMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useStablecoinMeltdownMonthly changed to \(useStablecoinMeltdownMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownMonthly)
        }
    }
    @Published var maxMeltdownDropMonthly: Double = -0.01 {
        didSet {
            print("[InMemorySettings] maxMeltdownDropMonthly changed to \(maxMeltdownDropMonthly)")
        }
    }
    
    // =============================
    // MARK: - Black Swan
    // =============================
    @Published var useBlackSwanWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useBlackSwanWeekly changed to \(useBlackSwanWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanWeekly)
        }
    }
    @Published var blackSwanDropWeekly: Double = -0.7977726936 {
        didSet {
            print("[InMemorySettings] blackSwanDropWeekly changed to \(blackSwanDropWeekly)")
        }
    }
    
    @Published var useBlackSwanMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useBlackSwanMonthly changed to \(useBlackSwanMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanMonthly)
        }
    }
    @Published var blackSwanDropMonthly: Double = -0.4 {
        didSet {
            print("[InMemorySettings] blackSwanDropMonthly changed to \(blackSwanDropMonthly)")
        }
    }
    
    // =============================
    // MARK: - Bear Market
    // =============================
    @Published var useBearMarketWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useBearMarketWeekly changed to \(useBearMarketWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketWeekly)
        }
    }
    @Published var bearWeeklyDriftWeekly: Double = -0.001 {
        didSet {
            print("[InMemorySettings] bearWeeklyDriftWeekly changed to \(bearWeeklyDriftWeekly)")
        }
    }
    
    @Published var useBearMarketMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useBearMarketMonthly changed to \(useBearMarketMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketMonthly)
        }
    }
    @Published var bearWeeklyDriftMonthly: Double = -0.01 {
        didSet {
            print("[InMemorySettings] bearWeeklyDriftMonthly changed to \(bearWeeklyDriftMonthly)")
        }
    }
    
    // =============================
    // MARK: - Maturing Market
    // =============================
    @Published var useMaturingMarketWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useMaturingMarketWeekly changed to \(useMaturingMarketWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketWeekly)
        }
    }
    @Published var maxMaturingDropWeekly: Double = -0.00326881742 {
        didSet {
            print("[InMemorySettings] maxMaturingDropWeekly changed to \(maxMaturingDropWeekly)")
        }
    }
    
    @Published var useMaturingMarketMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useMaturingMarketMonthly changed to \(useMaturingMarketMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketMonthly)
        }
    }
    @Published var maxMaturingDropMonthly: Double = -0.01 {
        didSet {
            print("[InMemorySettings] maxMaturingDropMonthly changed to \(maxMaturingDropMonthly)")
        }
    }
    
    // =============================
    // MARK: - Recession
    // =============================
    @Published var useRecessionWeekly: Bool = true {
        didSet {
            print("[InMemorySettings] useRecessionWeekly changed to \(useRecessionWeekly)")
            weeklySimSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionWeekly)
        }
    }
    @Published var maxRecessionDropWeekly: Double = -0.00100731624 {
        didSet {
            print("[InMemorySettings] maxRecessionDropWeekly changed to \(maxRecessionDropWeekly)")
        }
    }
    
    @Published var useRecessionMonthly: Bool = true {
        didSet {
            print("[InMemorySettings] useRecessionMonthly changed to \(useRecessionMonthly)")
            monthlySimSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionMonthly)
        }
    }
    @Published var maxRecessionDropMonthly: Double = -0.00145080805 {
        didSet {
            print("[InMemorySettings] maxRecessionDropMonthly changed to \(maxRecessionDropMonthly)")
        }
    }
    
    // =============================
    // MARK: - Toggling All Off
    // =============================
    func turnOffMonthlyToggles() {
        print("[InMemorySettings] Turning off all monthly toggles")
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
        print("[InMemorySettings] Turning off all weekly toggles")
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
    
    // =============================
    // MARK: - Load & Save to UserDefaults (batch approach)
    // (Unchanged except for your usual reading/writing; omitted for brevity)
    func loadFromUserDefaults() {
        print("[InMemorySettings] Loading from UserDefaults")
        _ = UserDefaults.standard
        
        // ... load values for all properties here ...
        // For brevity, we assume these are similar to the ones in SimulationSettings.
        
        // After loading, push the toggles to the simulation objects.
        applyAllTogglesToSimulation()
    }
    
    func saveToUserDefaults() {
        print("[InMemorySettings] Saving to UserDefaults")
        let defaults = UserDefaults.standard
        
        // ... save values for all properties here ...
        
        defaults.synchronize()
    }
    
    /// Convenience method to push all toggles to both simulation settings objects.
    func applyAllTogglesToSimulation() {
        print("[InMemorySettings] Pushing all toggles to simulation settings")
        
        // For weekly toggles:
        weeklySimSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketWeekly)
        weeklySimSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionWeekly)
        
        // For monthly toggles:
        monthlySimSettings?.setFactorEnabled(factorName: "Halving", enabled: useHalvingMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "InstitutionalDemand", enabled: useInstitutionalDemandMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "CountryAdoption", enabled: useCountryAdoptionMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "RegulatoryClarity", enabled: useRegulatoryClarityMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "EtfApproval", enabled: useEtfApprovalMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "TechBreakthrough", enabled: useTechBreakthroughMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "ScarcityEvents", enabled: useScarcityEventsMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "GlobalMacroHedge", enabled: useGlobalMacroHedgeMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "StablecoinShift", enabled: useStablecoinShiftMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "DemographicAdoption", enabled: useDemographicAdoptionMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "AltcoinFlight", enabled: useAltcoinFlightMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "AdoptionFactor", enabled: useAdoptionFactorMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "RegClampdown", enabled: useRegClampdownMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "CompetitorCoin", enabled: useCompetitorCoinMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "SecurityBreach", enabled: useSecurityBreachMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "BubblePop", enabled: useBubblePopMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "StablecoinMeltdown", enabled: useStablecoinMeltdownMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "BlackSwan", enabled: useBlackSwanMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "BearMarket", enabled: useBearMarketMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "MaturingMarket", enabled: useMaturingMarketMonthly)
        monthlySimSettings?.setFactorEnabled(factorName: "Recession", enabled: useRecessionMonthly)
    }
}
