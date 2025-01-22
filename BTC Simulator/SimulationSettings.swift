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
    
    // Mark when we’re in onboarding mode (to allow changing periodUnit)
    @Published var isOnboarding: Bool = false
    
    // -----------------------------
    // toggleAll now only checks/sets weekly/monthly factors:
    // -----------------------------
    var toggleAll: Bool {
        get {
            if periodUnit == .weeks {
                return useHalvingWeekly
                    && useInstitutionalDemandWeekly
                    && useCountryAdoptionWeekly
                    && useRegulatoryClarityWeekly
                    && useEtfApprovalWeekly
                    && useTechBreakthroughWeekly
                    && useScarcityEventsWeekly
                    && useGlobalMacroHedgeWeekly
                    && useStablecoinShiftWeekly
                    && useDemographicAdoptionWeekly
                    && useAltcoinFlightWeekly
                    && useAdoptionFactorWeekly
                    && useRegClampdownWeekly
                    && useCompetitorCoinWeekly
                    && useSecurityBreachWeekly
                    && useBubblePopWeekly
                    && useStablecoinMeltdownWeekly
                    && useBlackSwanWeekly
                    && useBearMarketWeekly
                    && useMaturingMarketWeekly
                    && useRecessionWeekly
            } else {
                return useHalvingMonthly
                    && useInstitutionalDemandMonthly
                    && useCountryAdoptionMonthly
                    && useRegulatoryClarityMonthly
                    && useEtfApprovalMonthly
                    && useTechBreakthroughMonthly
                    && useScarcityEventsMonthly
                    && useGlobalMacroHedgeMonthly
                    && useStablecoinShiftMonthly
                    && useDemographicAdoptionMonthly
                    && useAltcoinFlightMonthly
                    && useAdoptionFactorMonthly
                    && useRegClampdownMonthly
                    && useCompetitorCoinMonthly
                    && useSecurityBreachMonthly
                    && useBubblePopMonthly
                    && useStablecoinMeltdownMonthly
                    && useBlackSwanMonthly
                    && useBearMarketMonthly
                    && useMaturingMarketMonthly
                    && useRecessionMonthly
            }
        }
        set {
            isUpdating = true
            if periodUnit == .weeks {
                useHalvingWeekly = newValue
                useInstitutionalDemandWeekly = newValue
                useCountryAdoptionWeekly = newValue
                useRegulatoryClarityWeekly = newValue
                useEtfApprovalWeekly = newValue
                useTechBreakthroughWeekly = newValue
                useScarcityEventsWeekly = newValue
                useGlobalMacroHedgeWeekly = newValue
                useStablecoinShiftWeekly = newValue
                useDemographicAdoptionWeekly = newValue
                useAltcoinFlightWeekly = newValue
                useAdoptionFactorWeekly = newValue
                useRegClampdownWeekly = newValue
                useCompetitorCoinWeekly = newValue
                useSecurityBreachWeekly = newValue
                useBubblePopWeekly = newValue
                useStablecoinMeltdownWeekly = newValue
                useBlackSwanWeekly = newValue
                useBearMarketWeekly = newValue
                useMaturingMarketWeekly = newValue
                useRecessionWeekly = newValue
            } else {
                useHalvingMonthly = newValue
                useInstitutionalDemandMonthly = newValue
                useCountryAdoptionMonthly = newValue
                useRegulatoryClarityMonthly = newValue
                useEtfApprovalMonthly = newValue
                useTechBreakthroughMonthly = newValue
                useScarcityEventsMonthly = newValue
                useGlobalMacroHedgeMonthly = newValue
                useStablecoinShiftMonthly = newValue
                useDemographicAdoptionMonthly = newValue
                useAltcoinFlightMonthly = newValue
                useAdoptionFactorMonthly = newValue
                useRegClampdownMonthly = newValue
                useCompetitorCoinMonthly = newValue
                useSecurityBreachMonthly = newValue
                useBubblePopMonthly = newValue
                useStablecoinMeltdownMonthly = newValue
                useBlackSwanMonthly = newValue
                useBearMarketMonthly = newValue
                useMaturingMarketMonthly = newValue
                useRecessionMonthly = newValue
            }
            isUpdating = false
        }
    }
    // ------------------------------------------------------------
    
    var inputManager: PersistentInputManager? = nil
    
    // MARK: - Weekly vs. Monthly
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet {
            guard isInitialized else { return }

            // If user tries changing periodUnit outside of onboarding, revert it
            if !isOnboarding && periodUnit != oldValue {
                let revertValue = oldValue
                DispatchQueue.main.async {
                    self.periodUnit = revertValue
                }
                return
            }

            // Otherwise, if changed properly (or in onboarding), switch off toggles
            if periodUnit == .weeks {
                turnOffMonthlyToggles()
            } else {
                turnOffWeeklyToggles()
            }
        }
    }
    
    @Published var userPeriods: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
    
    // Onboarding
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0
    
    @Published var currencyPreference: PreferredCurrency = .eur {
        didSet {
            if isInitialized {
                print("didSet: currencyPreference changed to \(currencyPreference)")
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
            print("didSet: useLognormalGrowth changed to \(useLognormalGrowth)")
            UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        }
    }
    
    // Random Seed
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: lockedRandomSeed changed to \(lockedRandomSeed)")
                UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
            }
        }
    }
    
    @Published var seedValue: UInt64 = 0 {
        didSet {
            if isInitialized {
                print("didSet: seedValue changed to \(seedValue)")
                UserDefaults.standard.set(seedValue, forKey: "seedValue")
            }
        }
    }
    
    @Published var useRandomSeed: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useRandomSeed changed to \(useRandomSeed)")
                UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
            }
        }
    }
    
    @Published var useHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useHistoricalSampling changed to \(useHistoricalSampling)")
                UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
            }
        }
    }
    
    @Published var useVolShocks: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useVolShocks changed to \(useVolShocks)")
                UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
            }
        }
    }
    
    @Published var useGarchVolatility: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useGarchVolatility changed to \(useGarchVolatility)")
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
                print("didSet: autoCorrelationStrength changed to \(autoCorrelationStrength)")
                UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
            }
        }
    }
    
    @Published var meanReversionTarget: Double = 0.0 {
        didSet {
            if isInitialized {
                print("didSet: meanReversionTarget changed to \(meanReversionTarget)")
                UserDefaults.standard.set(meanReversionTarget, forKey: "meanReversionTarget")
            }
        }
    }
    
    @Published var lastUsedSeed: UInt64 = 0
    
    // =============================
    // MARK: - BULLISH FACTORS
    // =============================
    
    // -- Parent toggles removed/commented out --
    // @Published var useHalving: Bool = true { ... }
    // @Published var useInstitutionalDemand: Bool = true { ... }
    // @Published var useCountryAdoption: Bool = true { ... }
    // @Published var useRegulatoryClarity: Bool = true { ... }
    // @Published var useEtfApproval: Bool = true { ... }
    // @Published var useTechBreakthrough: Bool = true { ... }
    // @Published var useScarcityEvents: Bool = true { ... }
    // @Published var useGlobalMacroHedge: Bool = true { ... }
    // @Published var useStablecoinShift: Bool = true { ... }
    // @Published var useDemographicAdoption: Bool = true { ... }
    // @Published var useAltcoinFlight: Bool = true { ... }
    // @Published var useAdoptionFactor: Bool = true { ... }
    
    @Published var useHalvingWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingWeekly else { return }
            print("didSet: useHalvingWeekly changed to \(useHalvingWeekly)")
            UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
        }
    }
    
    @Published var halvingBumpWeekly: Double = SimulationSettings.defaultHalvingBumpWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpWeekly {
                print("didSet: halvingBumpWeekly changed to \(halvingBumpWeekly)")
                UserDefaults.standard.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
            }
        }
    }
    
    @Published var useHalvingMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingMonthly else { return }
            print("didSet: useHalvingMonthly changed to \(useHalvingMonthly)")
            UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")
        }
    }
    
    @Published var halvingBumpMonthly: Double = SimulationSettings.defaultHalvingBumpMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpMonthly {
                print("didSet: halvingBumpMonthly changed to \(halvingBumpMonthly)")
                UserDefaults.standard.set(halvingBumpMonthly, forKey: "halvingBumpMonthly")
            }
        }
    }
    
    @Published var useInstitutionalDemandWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandWeekly else { return }
            print("didSet: useInstitutionalDemandWeekly changed to \(useInstitutionalDemandWeekly)")
            UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
        }
    }
    
    @Published var maxDemandBoostWeekly: Double = SimulationSettings.defaultMaxDemandBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostWeekly {
                print("didSet: maxDemandBoostWeekly changed to \(maxDemandBoostWeekly)")
                UserDefaults.standard.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
            }
        }
    }
    
    @Published var useInstitutionalDemandMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandMonthly else { return }
            print("didSet: useInstitutionalDemandMonthly changed to \(useInstitutionalDemandMonthly)")
            UserDefaults.standard.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
        }
    }
    
    @Published var maxDemandBoostMonthly: Double = SimulationSettings.defaultMaxDemandBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostMonthly {
                print("didSet: maxDemandBoostMonthly changed to \(maxDemandBoostMonthly)")
                UserDefaults.standard.set(maxDemandBoostMonthly, forKey: "maxDemandBoostMonthly")
            }
        }
    }
    
    @Published var useCountryAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionWeekly else { return }
            print("didSet: useCountryAdoptionWeekly changed to \(useCountryAdoptionWeekly)")
            UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
        }
    }
    
    @Published var maxCountryAdBoostWeekly: Double = SimulationSettings.defaultMaxCountryAdBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostWeekly {
                print("didSet: maxCountryAdBoostWeekly changed to \(maxCountryAdBoostWeekly)")
                UserDefaults.standard.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
            }
        }
    }
    
    @Published var useCountryAdoptionMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionMonthly else { return }
            print("didSet: useCountryAdoptionMonthly changed to \(useCountryAdoptionMonthly)")
            UserDefaults.standard.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
        }
    }
    
    @Published var maxCountryAdBoostMonthly: Double = SimulationSettings.defaultMaxCountryAdBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostMonthly {
                print("didSet: maxCountryAdBoostMonthly changed to \(maxCountryAdBoostMonthly)")
                UserDefaults.standard.set(maxCountryAdBoostMonthly, forKey: "maxCountryAdBoostMonthly")
            }
        }
    }
    
    @Published var useRegulatoryClarityWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityWeekly else { return }
            print("didSet: useRegulatoryClarityWeekly changed to \(useRegulatoryClarityWeekly)")
            UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
        }
    }
    
    @Published var maxClarityBoostWeekly: Double = SimulationSettings.defaultMaxClarityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostWeekly {
                print("didSet: maxClarityBoostWeekly changed to \(maxClarityBoostWeekly)")
                UserDefaults.standard.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
            }
        }
    }
    
    @Published var useRegulatoryClarityMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityMonthly else { return }
            print("didSet: useRegulatoryClarityMonthly changed to \(useRegulatoryClarityMonthly)")
            UserDefaults.standard.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
        }
    }
    
    @Published var maxClarityBoostMonthly: Double = SimulationSettings.defaultMaxClarityBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostMonthly {
                print("didSet: maxClarityBoostMonthly changed to \(maxClarityBoostMonthly)")
                UserDefaults.standard.set(maxClarityBoostMonthly, forKey: "maxClarityBoostMonthly")
            }
        }
    }
    
    @Published var useEtfApprovalWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalWeekly else { return }
            print("didSet: useEtfApprovalWeekly changed to \(useEtfApprovalWeekly)")
            UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
        }
    }
    
    @Published var maxEtfBoostWeekly: Double = SimulationSettings.defaultMaxEtfBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostWeekly {
                print("didSet: maxEtfBoostWeekly changed to \(maxEtfBoostWeekly)")
                UserDefaults.standard.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
            }
        }
    }
    
    @Published var useEtfApprovalMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalMonthly else { return }
            print("didSet: useEtfApprovalMonthly changed to \(useEtfApprovalMonthly)")
            UserDefaults.standard.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
        }
    }
    
    @Published var maxEtfBoostMonthly: Double = SimulationSettings.defaultMaxEtfBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostMonthly {
                print("didSet: maxEtfBoostMonthly changed to \(maxEtfBoostMonthly)")
                UserDefaults.standard.set(maxEtfBoostMonthly, forKey: "maxEtfBoostMonthly")
            }
        }
    }
    
    @Published var useTechBreakthroughWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughWeekly else { return }
            print("didSet: useTechBreakthroughWeekly changed to \(useTechBreakthroughWeekly)")
            UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
        }
    }
    
    @Published var maxTechBoostWeekly: Double = SimulationSettings.defaultMaxTechBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostWeekly {
                print("didSet: maxTechBoostWeekly changed to \(maxTechBoostWeekly)")
                UserDefaults.standard.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
            }
        }
    }
    
    @Published var useTechBreakthroughMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughMonthly else { return }
            print("didSet: useTechBreakthroughMonthly changed to \(useTechBreakthroughMonthly)")
            UserDefaults.standard.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
        }
    }
    
    @Published var maxTechBoostMonthly: Double = SimulationSettings.defaultMaxTechBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostMonthly {
                print("didSet: maxTechBoostMonthly changed to \(maxTechBoostMonthly)")
                UserDefaults.standard.set(maxTechBoostMonthly, forKey: "maxTechBoostMonthly")
            }
        }
    }
    
    @Published var useScarcityEventsWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsWeekly else { return }
            print("didSet: useScarcityEventsWeekly changed to \(useScarcityEventsWeekly)")
            UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
        }
    }
    
    @Published var maxScarcityBoostWeekly: Double = SimulationSettings.defaultMaxScarcityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostWeekly {
                print("didSet: maxScarcityBoostWeekly changed to \(maxScarcityBoostWeekly)")
                UserDefaults.standard.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
            }
        }
    }
    
    @Published var useScarcityEventsMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsMonthly else { return }
            print("didSet: useScarcityEventsMonthly changed to \(useScarcityEventsMonthly)")
            UserDefaults.standard.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
        }
    }
    
    @Published var maxScarcityBoostMonthly: Double = SimulationSettings.defaultMaxScarcityBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostMonthly {
                print("didSet: maxScarcityBoostMonthly changed to \(maxScarcityBoostMonthly)")
                UserDefaults.standard.set(maxScarcityBoostMonthly, forKey: "maxScarcityBoostMonthly")
            }
        }
    }
    
    @Published var useGlobalMacroHedgeWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeWeekly else { return }
            print("didSet: useGlobalMacroHedgeWeekly changed to \(useGlobalMacroHedgeWeekly)")
            UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
        }
    }
    
    @Published var maxMacroBoostWeekly: Double = SimulationSettings.defaultMaxMacroBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostWeekly {
                print("didSet: maxMacroBoostWeekly changed to \(maxMacroBoostWeekly)")
                UserDefaults.standard.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
            }
        }
    }
    
    @Published var useGlobalMacroHedgeMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeMonthly else { return }
            print("didSet: useGlobalMacroHedgeMonthly changed to \(useGlobalMacroHedgeMonthly)")
            UserDefaults.standard.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
        }
    }
    
    @Published var maxMacroBoostMonthly: Double = SimulationSettings.defaultMaxMacroBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostMonthly {
                print("didSet: maxMacroBoostMonthly changed to \(maxMacroBoostMonthly)")
                UserDefaults.standard.set(maxMacroBoostMonthly, forKey: "maxMacroBoostMonthly")
            }
        }
    }
    
    @Published var useStablecoinShiftWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftWeekly else { return }
            print("didSet: useStablecoinShiftWeekly changed to \(useStablecoinShiftWeekly)")
            UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
        }
    }
    
    @Published var maxStablecoinBoostWeekly: Double = SimulationSettings.defaultMaxStablecoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostWeekly {
                print("didSet: maxStablecoinBoostWeekly changed to \(maxStablecoinBoostWeekly)")
                UserDefaults.standard.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
            }
        }
    }
    
    @Published var useStablecoinShiftMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftMonthly else { return }
            print("didSet: useStablecoinShiftMonthly changed to \(useStablecoinShiftMonthly)")
            UserDefaults.standard.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
        }
    }
    
    @Published var maxStablecoinBoostMonthly: Double = SimulationSettings.defaultMaxStablecoinBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostMonthly {
                print("didSet: maxStablecoinBoostMonthly changed to \(maxStablecoinBoostMonthly)")
                UserDefaults.standard.set(maxStablecoinBoostMonthly, forKey: "maxStablecoinBoostMonthly")
            }
        }
    }
    
    @Published var useDemographicAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionWeekly else { return }
            print("didSet: useDemographicAdoptionWeekly changed to \(useDemographicAdoptionWeekly)")
            UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
        }
    }
    
    @Published var maxDemoBoostWeekly: Double = SimulationSettings.defaultMaxDemoBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostWeekly {
                print("didSet: maxDemoBoostWeekly changed to \(maxDemoBoostWeekly)")
                UserDefaults.standard.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
            }
        }
    }
    
    @Published var useDemographicAdoptionMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionMonthly else { return }
            print("didSet: useDemographicAdoptionMonthly changed to \(useDemographicAdoptionMonthly)")
            UserDefaults.standard.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
        }
    }
    
    @Published var maxDemoBoostMonthly: Double = SimulationSettings.defaultMaxDemoBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostMonthly {
                print("didSet: maxDemoBoostMonthly changed to \(maxDemoBoostMonthly)")
                UserDefaults.standard.set(maxDemoBoostMonthly, forKey: "maxDemoBoostMonthly")
            }
        }
    }
    
    @Published var useAltcoinFlightWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightWeekly else { return }
            print("didSet: useAltcoinFlightWeekly changed to \(useAltcoinFlightWeekly)")
            UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
        }
    }
    
    @Published var maxAltcoinBoostWeekly: Double = SimulationSettings.defaultMaxAltcoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostWeekly {
                print("didSet: maxAltcoinBoostWeekly changed to \(maxAltcoinBoostWeekly)")
                UserDefaults.standard.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
            }
        }
    }
    
    @Published var useAltcoinFlightMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightMonthly else { return }
            print("didSet: useAltcoinFlightMonthly changed to \(useAltcoinFlightMonthly)")
            UserDefaults.standard.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
        }
    }
    
    @Published var maxAltcoinBoostMonthly: Double = SimulationSettings.defaultMaxAltcoinBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostMonthly {
                print("didSet: maxAltcoinBoostMonthly changed to \(maxAltcoinBoostMonthly)")
                UserDefaults.standard.set(maxAltcoinBoostMonthly, forKey: "maxAltcoinBoostMonthly")
            }
        }
    }
    
    @Published var useAdoptionFactorWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorWeekly else { return }
            print("didSet: useAdoptionFactorWeekly changed to \(useAdoptionFactorWeekly)")
            UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
        }
    }
    
    @Published var adoptionBaseFactorWeekly: Double = SimulationSettings.defaultAdoptionBaseFactorWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorWeekly {
                print("didSet: adoptionBaseFactorWeekly changed to \(adoptionBaseFactorWeekly)")
                UserDefaults.standard.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
            }
        }
    }
    
    @Published var useAdoptionFactorMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorMonthly else { return }
            print("didSet: useAdoptionFactorMonthly changed to \(useAdoptionFactorMonthly)")
            UserDefaults.standard.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
        }
    }
    
    @Published var adoptionBaseFactorMonthly: Double = SimulationSettings.defaultAdoptionBaseFactorMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorMonthly {
                print("didSet: adoptionBaseFactorMonthly changed to \(adoptionBaseFactorMonthly)")
                UserDefaults.standard.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")
            }
        }
    }
    
    // =============================
    // MARK: - BEARISH FACTORS
    // =============================
    
    // -- Parent toggles removed/commented out --
    // @Published var useRegClampdown: Bool = true { ... }
    // @Published var useCompetitorCoin: Bool = true { ... }
    // @Published var useSecurityBreach: Bool = true { ... }
    // @Published var useBubblePop: Bool = true { ... }
    // @Published var useStablecoinMeltdown: Bool = true { ... }
    // @Published var useBlackSwan: Bool = false { ... }
    // @Published var useBearMarket: Bool = true { ... }
    // @Published var useMaturingMarket: Bool = true { ... }
    // @Published var useRecession: Bool = true { ... }
    
    @Published var useRegClampdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownWeekly else { return }
            print("didSet: useRegClampdownWeekly changed to \(useRegClampdownWeekly)")
            UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
        }
    }
    
    @Published var maxClampDownWeekly: Double = SimulationSettings.defaultMaxClampDownWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClampDownWeekly {
                print("didSet: maxClampDownWeekly changed to \(maxClampDownWeekly)")
                UserDefaults.standard.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
            }
        }
    }
    
    @Published var useRegClampdownMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownMonthly else { return }
            print("didSet: useRegClampdownMonthly changed to \(useRegClampdownMonthly)")
            UserDefaults.standard.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
        }
    }
    
    @Published var maxClampDownMonthly: Double = SimulationSettings.defaultMaxClampDownMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClampDownMonthly {
                print("didSet: maxClampDownMonthly changed to \(maxClampDownMonthly)")
                UserDefaults.standard.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")
            }
        }
    }
    
    @Published var useCompetitorCoinWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinWeekly else { return }
            print("didSet: useCompetitorCoinWeekly changed to \(useCompetitorCoinWeekly)")
            UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
        }
    }
    
    @Published var maxCompetitorBoostWeekly: Double = SimulationSettings.defaultMaxCompetitorBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostWeekly {
                print("didSet: maxCompetitorBoostWeekly changed to \(maxCompetitorBoostWeekly)")
                UserDefaults.standard.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
            }
        }
    }
    
    @Published var useCompetitorCoinMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinMonthly else { return }
            print("didSet: useCompetitorCoinMonthly changed to \(useCompetitorCoinMonthly)")
            UserDefaults.standard.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
        }
    }
    
    @Published var maxCompetitorBoostMonthly: Double = SimulationSettings.defaultMaxCompetitorBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostMonthly {
                print("didSet: maxCompetitorBoostMonthly changed to \(maxCompetitorBoostMonthly)")
                UserDefaults.standard.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")
            }
        }
    }
    
    @Published var useSecurityBreachWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachWeekly else { return }
            print("didSet: useSecurityBreachWeekly changed to \(useSecurityBreachWeekly)")
            UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
        }
    }
    
    @Published var breachImpactWeekly: Double = SimulationSettings.defaultBreachImpactWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != breachImpactWeekly {
                print("didSet: breachImpactWeekly changed to \(breachImpactWeekly)")
                UserDefaults.standard.set(breachImpactWeekly, forKey: "breachImpactWeekly")
            }
        }
    }
    
    @Published var useSecurityBreachMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachMonthly else { return }
            print("didSet: useSecurityBreachMonthly changed to \(useSecurityBreachMonthly)")
            UserDefaults.standard.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
        }
    }
    
    @Published var breachImpactMonthly: Double = SimulationSettings.defaultBreachImpactMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != breachImpactMonthly {
                print("didSet: breachImpactMonthly changed to \(breachImpactMonthly)")
                UserDefaults.standard.set(breachImpactMonthly, forKey: "breachImpactMonthly")
            }
        }
    }
    
    @Published var useBubblePopWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopWeekly else { return }
            print("didSet: useBubblePopWeekly changed to \(useBubblePopWeekly)")
            UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
        }
    }
    
    @Published var maxPopDropWeekly: Double = SimulationSettings.defaultMaxPopDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxPopDropWeekly {
                print("didSet: maxPopDropWeekly changed to \(maxPopDropWeekly)")
                UserDefaults.standard.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
            }
        }
    }
    
    @Published var useBubblePopMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopMonthly else { return }
            print("didSet: useBubblePopMonthly changed to \(useBubblePopMonthly)")
            UserDefaults.standard.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
        }
    }
    
    @Published var maxPopDropMonthly: Double = SimulationSettings.defaultMaxPopDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxPopDropMonthly {
                print("didSet: maxPopDropMonthly changed to \(maxPopDropMonthly)")
                UserDefaults.standard.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")
            }
        }
    }
    
    @Published var useStablecoinMeltdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownWeekly else { return }
            print("didSet: useStablecoinMeltdownWeekly changed to \(useStablecoinMeltdownWeekly)")
            UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
        }
    }
    
    @Published var maxMeltdownDropWeekly: Double = SimulationSettings.defaultMaxMeltdownDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropWeekly {
                print("didSet: maxMeltdownDropWeekly changed to \(maxMeltdownDropWeekly)")
                UserDefaults.standard.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
            }
        }
    }
    
    @Published var useStablecoinMeltdownMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownMonthly else { return }
            print("didSet: useStablecoinMeltdownMonthly changed to \(useStablecoinMeltdownMonthly)")
            UserDefaults.standard.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
        }
    }
    
    @Published var maxMeltdownDropMonthly: Double = SimulationSettings.defaultMaxMeltdownDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropMonthly {
                print("didSet: maxMeltdownDropMonthly changed to \(maxMeltdownDropMonthly)")
                UserDefaults.standard.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")
            }
        }
    }
    
    @Published var useBlackSwanWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanWeekly else { return }
            print("didSet: useBlackSwanWeekly changed to \(useBlackSwanWeekly)")
            UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
        }
    }
    
    @Published var blackSwanDropWeekly: Double = SimulationSettings.defaultBlackSwanDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != blackSwanDropWeekly {
                print("didSet: blackSwanDropWeekly changed to \(blackSwanDropWeekly)")
                UserDefaults.standard.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
            }
        }
    }
    
    @Published var useBlackSwanMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanMonthly else { return }
            print("didSet: useBlackSwanMonthly changed to \(useBlackSwanMonthly)")
            UserDefaults.standard.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
        }
    }
    
    @Published var blackSwanDropMonthly: Double = SimulationSettings.defaultBlackSwanDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != blackSwanDropMonthly {
                print("didSet: blackSwanDropMonthly changed to \(blackSwanDropMonthly)")
                UserDefaults.standard.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")
            }
        }
    }
    
    @Published var useBearMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketWeekly else { return }
            print("didSet: useBearMarketWeekly changed to \(useBearMarketWeekly)")
            UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
        }
    }
    
    @Published var bearWeeklyDriftWeekly: Double = SimulationSettings.defaultBearWeeklyDriftWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftWeekly {
                print("didSet: bearWeeklyDriftWeekly changed to \(bearWeeklyDriftWeekly)")
                UserDefaults.standard.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
            }
        }
    }
    
    @Published var useBearMarketMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketMonthly else { return }
            print("didSet: useBearMarketMonthly changed to \(useBearMarketMonthly)")
            UserDefaults.standard.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
        }
    }
    
    @Published var bearWeeklyDriftMonthly: Double = SimulationSettings.defaultBearWeeklyDriftMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftMonthly {
                print("didSet: bearWeeklyDriftMonthly changed to \(bearWeeklyDriftMonthly)")
                UserDefaults.standard.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")
            }
        }
    }
    
    @Published var useMaturingMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketWeekly else { return }
            print("didSet: useMaturingMarketWeekly changed to \(useMaturingMarketWeekly)")
            UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
        }
    }
    
    @Published var maxMaturingDropWeekly: Double = SimulationSettings.defaultMaxMaturingDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMaturingDropWeekly {
                print("didSet: maxMaturingDropWeekly changed to \(maxMaturingDropWeekly)")
                UserDefaults.standard.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
            }
        }
    }
    
    @Published var useMaturingMarketMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketMonthly else { return }
            print("didSet: useMaturingMarketMonthly changed to \(useMaturingMarketMonthly)")
            UserDefaults.standard.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
        }
    }
    
    @Published var maxMaturingDropMonthly: Double = SimulationSettings.defaultMaxMaturingDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMaturingDropMonthly {
                print("didSet: maxMaturingDropMonthly changed to \(maxMaturingDropMonthly)")
                UserDefaults.standard.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")
            }
        }
    }
    
    @Published var useRecessionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionWeekly else { return }
            print("didSet: useRecessionWeekly changed to \(useRecessionWeekly)")
            UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
        }
    }
    
    @Published var maxRecessionDropWeekly: Double = SimulationSettings.defaultMaxRecessionDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxRecessionDropWeekly {
                print("didSet: maxRecessionDropWeekly changed to \(maxRecessionDropWeekly)")
                UserDefaults.standard.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
            }
        }
    }
    
    @Published var useRecessionMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionMonthly else { return }
            print("didSet: useRecessionMonthly changed to \(useRecessionMonthly)")
            UserDefaults.standard.set(useRecessionMonthly, forKey: "useRecessionMonthly")
        }
    }
    
    @Published var maxRecessionDropMonthly: Double = SimulationSettings.defaultMaxRecessionDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxRecessionDropMonthly {
                print("didSet: maxRecessionDropMonthly changed to \(maxRecessionDropMonthly)")
                UserDefaults.standard.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")
            }
        }
    }
    
    // NEW TOGGLE: LOCK HISTORICAL SAMPLING
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: lockHistoricalSampling changed to \(lockHistoricalSampling)")
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }
    
    func finalizeToggleStateAfterLoad() {
        isUpdating = true
        // Any older logic that forced parent toggles off/on is removed.
        isUpdating = false
    }
    
    // Turn off all monthly toggles
    private func turnOffMonthlyToggles() {
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
    
    // Turn off all weekly toggles
    private func turnOffWeeklyToggles() {
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
