//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {

    init() {
        // No UserDefaults loading here; handled in SimulationSettingsInit.swift
        isUpdating = false
        isInitialized = false
    }
    
    @Published var userIsActuallyTogglingAll = false
    
    // Inside SimulationSettings class:
    @Published var toggleAll: Bool = false {
        didSet {
            // Minimal guard checks
            guard isInitialized, toggleAll != oldValue else { return }

            // Call extension logic
            handleToggleAllChange()
        }
    }

    var inputManager: PersistentInputManager? = nil

    // MARK: - Weekly vs. Monthly
    @Published var periodUnit: PeriodUnit = .weeks
    @Published var userPeriods: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0

    // Onboarding
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0

    // CHANGED: Add a currencyPreference
    @Published var currencyPreference: PreferredCurrency = .eur {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(currencyPreference.rawValue, forKey: "currencyPreference")
            }
        }
    }

    @Published var contributionCurrencyWhenBoth: PreferredCurrency = .eur
    @Published var startingBalanceCurrencyWhenBoth: PreferredCurrency = .usd

    // Results
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []

    var isInitialized = false
    var isUpdating = false

    // Lognormal Growth
    @Published var useLognormalGrowth: Bool = true {
        didSet {
            UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        }
    }

    // Random Seed
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
            }
        }
    }

    @Published var seedValue: UInt64 = 0 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(seedValue, forKey: "seedValue")
            }
        }
    }

    @Published var useRandomSeed: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
            }
        }
    }

    @Published var useHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
            }
        }
    }

    @Published var useVolShocks: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
            }
        }
    }

    @Published var useGarchVolatility: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useGarchVolatility, forKey: "useGarchVolatility")
            }
        }
    }

    @Published var useAutoCorrelation: Bool = false {
        didSet {
            print("didSet: useAutoCorrelation = \(useAutoCorrelation)")
            UserDefaults.standard.set(useAutoCorrelation, forKey: "useAutoCorrelation")
        }
    }

    @Published var autoCorrelationStrength: Double = 0.2 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
            }
        }
    }

    @Published var meanReversionTarget: Double = 0.0 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(meanReversionTarget, forKey: "meanReversionTarget")
            }
        }
    }

    @Published var lastUsedSeed: UInt64 = 0

    // =============================
    // MARK: - BULLISH FACTORS
    // =============================

    // Halving
    @Published var useHalving: Bool = true {
        didSet {
            guard isInitialized, oldValue != useHalving else { return }
            UserDefaults.standard.set(useHalving, forKey: "useHalving")
            syncToggleAllState()
        }
    }

    @Published var useHalvingWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingWeekly else { return }
            UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
            syncToggleAllState()
        }
    }

    @Published var halvingBumpWeekly: Double = SimulationSettings.defaultHalvingBumpWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpWeekly {
                UserDefaults.standard.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
            }
        }
    }

    @Published var useHalvingMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingMonthly else { return }
            UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")
            syncToggleAllState()
        }
    }

    @Published var halvingBumpMonthly: Double = SimulationSettings.defaultHalvingBumpMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpMonthly {
                UserDefaults.standard.set(halvingBumpMonthly, forKey: "halvingBumpMonthly")
            }
        }
    }

    // Institutional Demand
    @Published var useInstitutionalDemand: Bool = true {
        didSet {
            guard isInitialized, oldValue != useInstitutionalDemand else { return }
            UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
            syncToggleAllState()
        }
    }

    @Published var useInstitutionalDemandWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandWeekly else { return }
            UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxDemandBoostWeekly: Double = SimulationSettings.defaultMaxDemandBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostWeekly {
                UserDefaults.standard.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
            }
        }
    }

    @Published var useInstitutionalDemandMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandMonthly else { return }
            UserDefaults.standard.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxDemandBoostMonthly: Double = SimulationSettings.defaultMaxDemandBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostMonthly {
                UserDefaults.standard.set(maxDemandBoostMonthly, forKey: "maxDemandBoostMonthly")
            }
        }
    }

    // Country Adoption
    @Published var useCountryAdoption: Bool = true {
        didSet {
            guard isInitialized, oldValue != useCountryAdoption else { return }
            UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
            syncToggleAllState()
        }
    }

    @Published var useCountryAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionWeekly else { return }
            UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxCountryAdBoostWeekly: Double = SimulationSettings.defaultMaxCountryAdBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostWeekly {
                UserDefaults.standard.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
            }
        }
    }

    @Published var useCountryAdoptionMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionMonthly else { return }
            UserDefaults.standard.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxCountryAdBoostMonthly: Double = SimulationSettings.defaultMaxCountryAdBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostMonthly {
                UserDefaults.standard.set(maxCountryAdBoostMonthly, forKey: "maxCountryAdBoostMonthly")
            }
        }
    }

    // Regulatory Clarity
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRegulatoryClarity else { return }
            UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
            syncToggleAllState()
        }
    }

    @Published var useRegulatoryClarityWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityWeekly else { return }
            UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxClarityBoostWeekly: Double = SimulationSettings.defaultMaxClarityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostWeekly {
                UserDefaults.standard.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
            }
        }
    }

    @Published var useRegulatoryClarityMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityMonthly else { return }
            UserDefaults.standard.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxClarityBoostMonthly: Double = SimulationSettings.defaultMaxClarityBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostMonthly {
                UserDefaults.standard.set(maxClarityBoostMonthly, forKey: "maxClarityBoostMonthly")
            }
        }
    }

    // ETF Approval
    @Published var useEtfApproval: Bool = true {
        didSet {
            guard isInitialized, oldValue != useEtfApproval else { return }
            UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
            syncToggleAllState()
        }
    }

    @Published var useEtfApprovalWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalWeekly else { return }
            UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxEtfBoostWeekly: Double = SimulationSettings.defaultMaxEtfBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostWeekly {
                UserDefaults.standard.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
            }
        }
    }

    @Published var useEtfApprovalMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalMonthly else { return }
            UserDefaults.standard.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxEtfBoostMonthly: Double = SimulationSettings.defaultMaxEtfBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostMonthly {
                UserDefaults.standard.set(maxEtfBoostMonthly, forKey: "maxEtfBoostMonthly")
            }
        }
    }

    // Tech Breakthrough
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            guard isInitialized, oldValue != useTechBreakthrough else { return }
            UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
            syncToggleAllState()
        }
    }

    @Published var useTechBreakthroughWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughWeekly else { return }
            UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxTechBoostWeekly: Double = SimulationSettings.defaultMaxTechBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostWeekly {
                UserDefaults.standard.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
            }
        }
    }

    @Published var useTechBreakthroughMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughMonthly else { return }
            UserDefaults.standard.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxTechBoostMonthly: Double = SimulationSettings.defaultMaxTechBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostMonthly {
                UserDefaults.standard.set(maxTechBoostMonthly, forKey: "maxTechBoostMonthly")
            }
        }
    }

    // Scarcity Events
    @Published var useScarcityEvents: Bool = true {
        didSet {
            guard isInitialized, oldValue != useScarcityEvents else { return }
            UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
            syncToggleAllState()
        }
    }

    @Published var useScarcityEventsWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsWeekly else { return }
            UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxScarcityBoostWeekly: Double = SimulationSettings.defaultMaxScarcityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostWeekly {
                UserDefaults.standard.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
            }
        }
    }

    @Published var useScarcityEventsMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsMonthly else { return }
            UserDefaults.standard.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxScarcityBoostMonthly: Double = SimulationSettings.defaultMaxScarcityBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostMonthly {
                UserDefaults.standard.set(maxScarcityBoostMonthly, forKey: "maxScarcityBoostMonthly")
            }
        }
    }

    // Global Macro Hedge
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            guard isInitialized, oldValue != useGlobalMacroHedge else { return }
            UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
            syncToggleAllState()
        }
    }

    @Published var useGlobalMacroHedgeWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeWeekly else { return }
            UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxMacroBoostWeekly: Double = SimulationSettings.defaultMaxMacroBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostWeekly {
                UserDefaults.standard.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
            }
        }
    }

    @Published var useGlobalMacroHedgeMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeMonthly else { return }
            UserDefaults.standard.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxMacroBoostMonthly: Double = SimulationSettings.defaultMaxMacroBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostMonthly {
                UserDefaults.standard.set(maxMacroBoostMonthly, forKey: "maxMacroBoostMonthly")
            }
        }
    }

    // Stablecoin Shift
    @Published var useStablecoinShift: Bool = true {
        didSet {
            guard isInitialized, oldValue != useStablecoinShift else { return }
            UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
            syncToggleAllState()
        }
    }

    @Published var useStablecoinShiftWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftWeekly else { return }
            UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxStablecoinBoostWeekly: Double = SimulationSettings.defaultMaxStablecoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostWeekly {
                UserDefaults.standard.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
            }
        }
    }

    @Published var useStablecoinShiftMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftMonthly else { return }
            UserDefaults.standard.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxStablecoinBoostMonthly: Double = SimulationSettings.defaultMaxStablecoinBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostMonthly {
                UserDefaults.standard.set(maxStablecoinBoostMonthly, forKey: "maxStablecoinBoostMonthly")
            }
        }
    }

    // Demographic Adoption
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            guard isInitialized, oldValue != useDemographicAdoption else { return }
            UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
            syncToggleAllState()
        }
    }

    @Published var useDemographicAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionWeekly else { return }
            UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxDemoBoostWeekly: Double = SimulationSettings.defaultMaxDemoBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostWeekly {
                UserDefaults.standard.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
            }
        }
    }

    @Published var useDemographicAdoptionMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionMonthly else { return }
            UserDefaults.standard.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxDemoBoostMonthly: Double = SimulationSettings.defaultMaxDemoBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostMonthly {
                UserDefaults.standard.set(maxDemoBoostMonthly, forKey: "maxDemoBoostMonthly")
            }
        }
    }

    // Altcoin Flight
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            guard isInitialized, oldValue != useAltcoinFlight else { return }
            UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
            syncToggleAllState()
        }
    }

    @Published var useAltcoinFlightWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightWeekly else { return }
            UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxAltcoinBoostWeekly: Double = SimulationSettings.defaultMaxAltcoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostWeekly {
                UserDefaults.standard.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
            }
        }
    }

    @Published var useAltcoinFlightMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightMonthly else { return }
            UserDefaults.standard.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxAltcoinBoostMonthly: Double = SimulationSettings.defaultMaxAltcoinBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostMonthly {
                UserDefaults.standard.set(maxAltcoinBoostMonthly, forKey: "maxAltcoinBoostMonthly")
            }
        }
    }

    // Adoption Factor
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            guard isInitialized, oldValue != useAdoptionFactor else { return }
            UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
            syncToggleAllState()
        }
    }

    @Published var useAdoptionFactorWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorWeekly else { return }
            UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
            syncToggleAllState()
        }
    }

    @Published var adoptionBaseFactorWeekly: Double = SimulationSettings.defaultAdoptionBaseFactorWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorWeekly {
                UserDefaults.standard.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
            }
        }
    }

    @Published var useAdoptionFactorMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorMonthly else { return }
            UserDefaults.standard.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
            syncToggleAllState()
        }
    }

    @Published var adoptionBaseFactorMonthly: Double = SimulationSettings.defaultAdoptionBaseFactorMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorMonthly {
                UserDefaults.standard.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")
            }
        }
    }

    // =============================
    // MARK: - BEARISH FACTORS
    // =============================

    // Regulatory Clampdown
    @Published var useRegClampdown: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRegClampdown else { return }
            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")
            syncToggleAllState()
        }
    }

    @Published var useRegClampdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownWeekly else { return }
            UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxClampDownWeekly: Double = SimulationSettings.defaultMaxClampDownWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClampDownWeekly {
                UserDefaults.standard.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
            }
        }
    }

    @Published var useRegClampdownMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownMonthly else { return }
            UserDefaults.standard.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxClampDownMonthly: Double = SimulationSettings.defaultMaxClampDownMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClampDownMonthly {
                UserDefaults.standard.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")
            }
        }
    }

    // Competitor Coin
    @Published var useCompetitorCoin: Bool = true {
        didSet {
            guard isInitialized, oldValue != useCompetitorCoin else { return }
            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")
            syncToggleAllState()
        }
    }

    @Published var useCompetitorCoinWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinWeekly else { return }
            UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxCompetitorBoostWeekly: Double = SimulationSettings.defaultMaxCompetitorBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostWeekly {
                UserDefaults.standard.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
            }
        }
    }

    @Published var useCompetitorCoinMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinMonthly else { return }
            UserDefaults.standard.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxCompetitorBoostMonthly: Double = SimulationSettings.defaultMaxCompetitorBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostMonthly {
                UserDefaults.standard.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")
            }
        }
    }

    // Security Breach
    @Published var useSecurityBreach: Bool = true {
        didSet {
            guard isInitialized, oldValue != useSecurityBreach else { return }
            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")
            syncToggleAllState()
        }
    }

    @Published var useSecurityBreachWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachWeekly else { return }
            UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
            syncToggleAllState()
        }
    }

    @Published var breachImpactWeekly: Double = SimulationSettings.defaultBreachImpactWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != breachImpactWeekly {
                UserDefaults.standard.set(breachImpactWeekly, forKey: "breachImpactWeekly")
            }
        }
    }

    @Published var useSecurityBreachMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachMonthly else { return }
            UserDefaults.standard.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
            syncToggleAllState()
        }
    }

    @Published var breachImpactMonthly: Double = SimulationSettings.defaultBreachImpactMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != breachImpactMonthly {
                UserDefaults.standard.set(breachImpactMonthly, forKey: "breachImpactMonthly")
            }
        }
    }

    // Bubble Pop
    @Published var useBubblePop: Bool = true {
        didSet {
            guard isInitialized, oldValue != useBubblePop else { return }
            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")
            syncToggleAllState()
        }
    }

    @Published var useBubblePopWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopWeekly else { return }
            UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxPopDropWeekly: Double = SimulationSettings.defaultMaxPopDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxPopDropWeekly {
                UserDefaults.standard.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
            }
        }
    }

    @Published var useBubblePopMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopMonthly else { return }
            UserDefaults.standard.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxPopDropMonthly: Double = SimulationSettings.defaultMaxPopDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxPopDropMonthly {
                UserDefaults.standard.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")
            }
        }
    }

    // Stablecoin Meltdown
    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            guard isInitialized, oldValue != useStablecoinMeltdown else { return }
            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")
            syncToggleAllState()
        }
    }

    @Published var useStablecoinMeltdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownWeekly else { return }
            UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxMeltdownDropWeekly: Double = SimulationSettings.defaultMaxMeltdownDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropWeekly {
                UserDefaults.standard.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
            }
        }
    }

    @Published var useStablecoinMeltdownMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownMonthly else { return }
            UserDefaults.standard.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxMeltdownDropMonthly: Double = SimulationSettings.defaultMaxMeltdownDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropMonthly {
                UserDefaults.standard.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")
            }
        }
    }

    // Black Swan
    @Published var useBlackSwan: Bool = false {
        didSet {
            guard isInitialized, oldValue != useBlackSwan else { return }
            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")
            syncToggleAllState()
        }
    }

    @Published var useBlackSwanWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanWeekly else { return }
            UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
            syncToggleAllState()
        }
    }

    @Published var blackSwanDropWeekly: Double = SimulationSettings.defaultBlackSwanDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != blackSwanDropWeekly {
                UserDefaults.standard.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
            }
        }
    }

    @Published var useBlackSwanMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanMonthly else { return }
            UserDefaults.standard.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
            syncToggleAllState()
        }
    }

    @Published var blackSwanDropMonthly: Double = SimulationSettings.defaultBlackSwanDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != blackSwanDropMonthly {
                UserDefaults.standard.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")
            }
        }
    }

    // Bear Market
    @Published var useBearMarket: Bool = true {
        didSet {
            guard isInitialized, oldValue != useBearMarket else { return }
            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")
            syncToggleAllState()
        }
    }

    @Published var useBearMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketWeekly else { return }
            UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
            syncToggleAllState()
        }
    }

    @Published var bearWeeklyDriftWeekly: Double = SimulationSettings.defaultBearWeeklyDriftWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftWeekly {
                UserDefaults.standard.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
            }
        }
    }

    @Published var useBearMarketMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketMonthly else { return }
            UserDefaults.standard.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
            syncToggleAllState()
        }
    }

    @Published var bearWeeklyDriftMonthly: Double = SimulationSettings.defaultBearWeeklyDriftMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftMonthly {
                UserDefaults.standard.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")
            }
        }
    }

    // Maturing Market
    @Published var useMaturingMarket: Bool = true {
        didSet {
            guard isInitialized, oldValue != useMaturingMarket else { return }
            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")
            syncToggleAllState()
        }
    }

    @Published var useMaturingMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketWeekly else { return }
            UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxMaturingDropWeekly: Double = SimulationSettings.defaultMaxMaturingDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMaturingDropWeekly {
                UserDefaults.standard.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
            }
        }
    }

    @Published var useMaturingMarketMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketMonthly else { return }
            UserDefaults.standard.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxMaturingDropMonthly: Double = SimulationSettings.defaultMaxMaturingDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMaturingDropMonthly {
                UserDefaults.standard.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")
            }
        }
    }

    // Recession
    @Published var useRecession: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRecession else { return }
            UserDefaults.standard.set(useRecession, forKey: "useRecession")
            syncToggleAllState()
        }
    }

    @Published var useRecessionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionWeekly else { return }
            UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
            syncToggleAllState()
        }
    }

    @Published var maxRecessionDropWeekly: Double = SimulationSettings.defaultMaxRecessionDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxRecessionDropWeekly {
                UserDefaults.standard.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
            }
        }
    }

    @Published var useRecessionMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionMonthly else { return }
            UserDefaults.standard.set(useRecessionMonthly, forKey: "useRecessionMonthly")
            syncToggleAllState()
        }
    }

    @Published var maxRecessionDropMonthly: Double = SimulationSettings.defaultMaxRecessionDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxRecessionDropMonthly {
                UserDefaults.standard.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")
            }
        }
    }

    // NEW TOGGLE: LOCK HISTORICAL SAMPLING
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }

    private func finalizeToggleStateAfterLoad() {
        // Temporarily disable the chain-reaction logic
        isUpdating = true

        // BULLISH
        useHalving = (useHalvingWeekly || useHalvingMonthly)
        useInstitutionalDemand = (useInstitutionalDemandWeekly || useInstitutionalDemandMonthly)
        useCountryAdoption = (useCountryAdoptionWeekly || useCountryAdoptionMonthly)
        useRegulatoryClarity = (useRegulatoryClarityWeekly || useRegulatoryClarityMonthly)
        useEtfApproval = (useEtfApprovalWeekly || useEtfApprovalMonthly)
        useTechBreakthrough = (useTechBreakthroughWeekly || useTechBreakthroughMonthly)
        useScarcityEvents = (useScarcityEventsWeekly || useScarcityEventsMonthly)
        useGlobalMacroHedge = (useGlobalMacroHedgeWeekly || useGlobalMacroHedgeMonthly)
        useStablecoinShift = (useStablecoinShiftWeekly || useStablecoinShiftMonthly)
        useDemographicAdoption = (useDemographicAdoptionWeekly || useDemographicAdoptionMonthly)
        useAltcoinFlight = (useAltcoinFlightWeekly || useAltcoinFlightMonthly)
        useAdoptionFactor = (useAdoptionFactorWeekly || useAdoptionFactorMonthly)

        // BEARISH
        useRegClampdown = (useRegClampdownWeekly || useRegClampdownMonthly)
        useCompetitorCoin = (useCompetitorCoinWeekly || useCompetitorCoinMonthly)
        useSecurityBreach = (useSecurityBreachWeekly || useSecurityBreachMonthly)
        useBubblePop = (useBubblePopWeekly || useBubblePopMonthly)
        useStablecoinMeltdown = (useStablecoinMeltdownWeekly || useStablecoinMeltdownMonthly)
        useBlackSwan = (useBlackSwanWeekly || useBlackSwanMonthly)
        useBearMarket = (useBearMarketWeekly || useBearMarketMonthly)
        useMaturingMarket = (useMaturingMarketWeekly || useMaturingMarketMonthly)
        useRecession = (useRecessionWeekly || useRecessionMonthly)

        isUpdating = false

        // Now sync with the new toggleAll extension
        syncToggleAllState()
    }
}
