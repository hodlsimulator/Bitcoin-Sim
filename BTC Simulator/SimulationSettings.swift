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
    // REPLACE THE OLD STORED toggleAll WITH A COMPUTED PROPERTY:
    // -----------------------------
    /// Derived property that returns true only if *all* factors are on.
    /// Setting it true/false will enable/disable *all* factors, respectively.
    var toggleAll: Bool {
        get {
            // Check whichever toggles you want to count.
            // For brevity, here’s an example that includes the major parent toggles:
            return useHalving
                && useInstitutionalDemand
                && useCountryAdoption
                && useRegulatoryClarity
                && useEtfApproval
                && useTechBreakthrough
                && useScarcityEvents
                && useGlobalMacroHedge
                && useStablecoinShift
                && useDemographicAdoption
                && useAltcoinFlight
                && useAdoptionFactor
                && useRegClampdown
                && useCompetitorCoin
                && useSecurityBreach
                && useBubblePop
                && useStablecoinMeltdown
                && useBlackSwan
                && useBearMarket
                && useMaturingMarket
                && useRecession
        }
        set {
            // Turning them all on/off
            isUpdating = true
            useHalving = newValue
            useInstitutionalDemand = newValue
            useCountryAdoption = newValue
            useRegulatoryClarity = newValue
            useEtfApproval = newValue
            useTechBreakthrough = newValue
            useScarcityEvents = newValue
            useGlobalMacroHedge = newValue
            useStablecoinShift = newValue
            useDemographicAdoption = newValue
            useAltcoinFlight = newValue
            useAdoptionFactor = newValue
            useRegClampdown = newValue
            useCompetitorCoin = newValue
            useSecurityBreach = newValue
            useBubblePop = newValue
            useStablecoinMeltdown = newValue
            useBlackSwan = newValue
            useBearMarket = newValue
            useMaturingMarket = newValue
            useRecession = newValue
            isUpdating = false
            // Optionally call // syncToggleAllState() so everything remains consistent:
            // syncToggleAllState()
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
                // Revert asynchronously so didSet finishes before we set again
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
    
    @Published var useHalving: Bool = true {
        didSet {
            guard isInitialized, oldValue != useHalving else { return }
            print("didSet: useHalving changed to \(useHalving)")
            UserDefaults.standard.set(useHalving, forKey: "useHalving")
            // syncToggleAllState()
        }
    }
    
    @Published var useHalvingWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingWeekly else { return }
            print("didSet: useHalvingWeekly changed to \(useHalvingWeekly)")
            UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useInstitutionalDemand: Bool = true {
        didSet {
            guard isInitialized, oldValue != useInstitutionalDemand else { return }
            print("didSet: useInstitutionalDemand changed to \(useInstitutionalDemand)")
            UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
            // syncToggleAllState()
        }
    }
    
    @Published var useInstitutionalDemandWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandWeekly else { return }
            print("didSet: useInstitutionalDemandWeekly changed to \(useInstitutionalDemandWeekly)")
            UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useCountryAdoption: Bool = true {
        didSet {
            guard isInitialized, oldValue != useCountryAdoption else { return }
            print("didSet: useCountryAdoption changed to \(useCountryAdoption)")
            UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
            // syncToggleAllState()
        }
    }
    
    @Published var useCountryAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionWeekly else { return }
            print("didSet: useCountryAdoptionWeekly changed to \(useCountryAdoptionWeekly)")
            UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRegulatoryClarity else { return }
            print("didSet: useRegulatoryClarity changed to \(useRegulatoryClarity)")
            UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
            // syncToggleAllState()
        }
    }
    
    @Published var useRegulatoryClarityWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityWeekly else { return }
            print("didSet: useRegulatoryClarityWeekly changed to \(useRegulatoryClarityWeekly)")
            UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useEtfApproval: Bool = true {
        didSet {
            guard isInitialized, oldValue != useEtfApproval else { return }
            print("didSet: useEtfApproval changed to \(useEtfApproval)")
            UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
            // syncToggleAllState()
        }
    }
    
    @Published var useEtfApprovalWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalWeekly else { return }
            print("didSet: useEtfApprovalWeekly changed to \(useEtfApprovalWeekly)")
            UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            guard isInitialized, oldValue != useTechBreakthrough else { return }
            print("didSet: useTechBreakthrough changed to \(useTechBreakthrough)")
            UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
            // syncToggleAllState()
        }
    }
    
    @Published var useTechBreakthroughWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughWeekly else { return }
            print("didSet: useTechBreakthroughWeekly changed to \(useTechBreakthroughWeekly)")
            UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useScarcityEvents: Bool = true {
        didSet {
            guard isInitialized, oldValue != useScarcityEvents else { return }
            print("didSet: useScarcityEvents changed to \(useScarcityEvents)")
            UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
            // syncToggleAllState()
        }
    }
    
    @Published var useScarcityEventsWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsWeekly else { return }
            print("didSet: useScarcityEventsWeekly changed to \(useScarcityEventsWeekly)")
            UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            guard isInitialized, oldValue != useGlobalMacroHedge else { return }
            print("didSet: useGlobalMacroHedge changed to \(useGlobalMacroHedge)")
            UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
            // syncToggleAllState()
        }
    }
    
    @Published var useGlobalMacroHedgeWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeWeekly else { return }
            print("didSet: useGlobalMacroHedgeWeekly changed to \(useGlobalMacroHedgeWeekly)")
            UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useStablecoinShift: Bool = true {
        didSet {
            guard isInitialized, oldValue != useStablecoinShift else { return }
            print("didSet: useStablecoinShift changed to \(useStablecoinShift)")
            UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
            // syncToggleAllState()
        }
    }
    
    @Published var useStablecoinShiftWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftWeekly else { return }
            print("didSet: useStablecoinShiftWeekly changed to \(useStablecoinShiftWeekly)")
            UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            guard isInitialized, oldValue != useDemographicAdoption else { return }
            print("didSet: useDemographicAdoption changed to \(useDemographicAdoption)")
            UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
            // syncToggleAllState()
        }
    }
    
    @Published var useDemographicAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionWeekly else { return }
            print("didSet: useDemographicAdoptionWeekly changed to \(useDemographicAdoptionWeekly)")
            UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            guard isInitialized, oldValue != useAltcoinFlight else { return }
            print("didSet: useAltcoinFlight changed to \(useAltcoinFlight)")
            UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
            // syncToggleAllState()
        }
    }
    
    @Published var useAltcoinFlightWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightWeekly else { return }
            print("didSet: useAltcoinFlightWeekly changed to \(useAltcoinFlightWeekly)")
            UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            guard isInitialized, oldValue != useAdoptionFactor else { return }
            print("didSet: useAdoptionFactor changed to \(useAdoptionFactor)")
            UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
            // syncToggleAllState()
        }
    }
    
    @Published var useAdoptionFactorWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorWeekly else { return }
            print("didSet: useAdoptionFactorWeekly changed to \(useAdoptionFactorWeekly)")
            UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useRegClampdown: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRegClampdown else { return }
            print("didSet: useRegClampdown changed to \(useRegClampdown)")
            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")
            // syncToggleAllState()
        }
    }
    
    @Published var useRegClampdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownWeekly else { return }
            print("didSet: useRegClampdownWeekly changed to \(useRegClampdownWeekly)")
            UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useCompetitorCoin: Bool = true {
        didSet {
            guard isInitialized, oldValue != useCompetitorCoin else { return }
            print("didSet: useCompetitorCoin changed to \(useCompetitorCoin)")
            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")
            // syncToggleAllState()
        }
    }
    
    @Published var useCompetitorCoinWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinWeekly else { return }
            print("didSet: useCompetitorCoinWeekly changed to \(useCompetitorCoinWeekly)")
            UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useSecurityBreach: Bool = true {
        didSet {
            guard isInitialized, oldValue != useSecurityBreach else { return }
            print("didSet: useSecurityBreach changed to \(useSecurityBreach)")
            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")
            // syncToggleAllState()
        }
    }
    
    @Published var useSecurityBreachWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachWeekly else { return }
            print("didSet: useSecurityBreachWeekly changed to \(useSecurityBreachWeekly)")
            UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useBubblePop: Bool = true {
        didSet {
            guard isInitialized, oldValue != useBubblePop else { return }
            print("didSet: useBubblePop changed to \(useBubblePop)")
            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")
            // syncToggleAllState()
        }
    }
    
    @Published var useBubblePopWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopWeekly else { return }
            print("didSet: useBubblePopWeekly changed to \(useBubblePopWeekly)")
            UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            guard isInitialized, oldValue != useStablecoinMeltdown else { return }
            print("didSet: useStablecoinMeltdown changed to \(useStablecoinMeltdown)")
            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")
            // syncToggleAllState()
        }
    }
    
    @Published var useStablecoinMeltdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownWeekly else { return }
            print("didSet: useStablecoinMeltdownWeekly changed to \(useStablecoinMeltdownWeekly)")
            UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useBlackSwan: Bool = false {
        didSet {
            guard isInitialized, oldValue != useBlackSwan else { return }
            print("didSet: useBlackSwan changed to \(useBlackSwan)")
            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")
            // syncToggleAllState()
        }
    }
    
    @Published var useBlackSwanWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanWeekly else { return }
            print("didSet: useBlackSwanWeekly changed to \(useBlackSwanWeekly)")
            UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useBearMarket: Bool = true {
        didSet {
            guard isInitialized, oldValue != useBearMarket else { return }
            print("didSet: useBearMarket changed to \(useBearMarket)")
            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")
            // syncToggleAllState()
        }
    }
    
    @Published var useBearMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketWeekly else { return }
            print("didSet: useBearMarketWeekly changed to \(useBearMarketWeekly)")
            UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useMaturingMarket: Bool = true {
        didSet {
            guard isInitialized, oldValue != useMaturingMarket else { return }
            print("didSet: useMaturingMarket changed to \(useMaturingMarket)")
            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")
            // syncToggleAllState()
        }
    }
    
    @Published var useMaturingMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketWeekly else { return }
            print("didSet: useMaturingMarketWeekly changed to \(useMaturingMarketWeekly)")
            UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
    
    @Published var useRecession: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRecession else { return }
            print("didSet: useRecession changed to \(useRecession)")
            UserDefaults.standard.set(useRecession, forKey: "useRecession")
            // syncToggleAllState()
        }
    }
    
    @Published var useRecessionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionWeekly else { return }
            print("didSet: useRecessionWeekly changed to \(useRecessionWeekly)")
            UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
            // syncToggleAllState()
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
            // syncToggleAllState()
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
        // Any older logic that forced parent toggles off/on can be removed or commented out
        isUpdating = false
        // // syncToggleAllState()
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
