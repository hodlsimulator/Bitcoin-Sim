//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    
    init() {
        // No heavy loading here; see SimulationSettingsInit.swift
        isUpdating = false
        isInitialized = false
    }
    
    var inputManager: PersistentInputManager?
    
    @Published var userIsActuallyTogglingAll = false
    @Published var isOnboarding: Bool = false  // used to allow periodUnit changes
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet {
            print("didSet: periodUnit changed to \(periodUnit). isInitialized=\(isInitialized)")
            guard isInitialized else { return }
            
            // (Removed calls that forced toggles off for the non-active period)
        }
    }
    
    @Published var userPeriods: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
    
    // Onboarding
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0
    
    @Published var currencyPreference: PreferredCurrency = .eur {
        didSet {
            print("didSet: currencyPreference changed to \(currencyPreference). isInitialized=\(isInitialized)")
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
            print("didSet: useLognormalGrowth changed to \(useLognormalGrowth).")
            UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        }
    }
    
    // Random Seed
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            print("didSet: lockedRandomSeed changed to \(lockedRandomSeed). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
            }
        }
    }
    
    @Published var seedValue: UInt64 = 0 {
        didSet {
            print("didSet: seedValue changed to \(seedValue). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(seedValue, forKey: "seedValue")
            }
        }
    }
    
    @Published var useRandomSeed: Bool = true {
        didSet {
            print("didSet: useRandomSeed changed to \(useRandomSeed). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
            }
        }
    }
    
    @Published var useHistoricalSampling: Bool = true {
        didSet {
            print("didSet: useHistoricalSampling changed to \(useHistoricalSampling). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
            }
        }
    }
    
    @Published var useVolShocks: Bool = true {
        didSet {
            print("didSet: useVolShocks changed to \(useVolShocks). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
            }
        }
    }
    
    @Published var useGarchVolatility: Bool = true {
        didSet {
            print("didSet: useGarchVolatility changed to \(useGarchVolatility). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useGarchVolatility, forKey: "useGarchVolatility")
            }
        }
    }
    
    @Published var useAutoCorrelation: Bool = false {
        didSet {
            print("didSet: useAutoCorrelation changed to \(useAutoCorrelation).")
            UserDefaults.standard.set(useAutoCorrelation, forKey: "useAutoCorrelation")
        }
    }
    
    @Published var autoCorrelationStrength: Double = 0.2 {
        didSet {
            print("didSet: autoCorrelationStrength changed to \(autoCorrelationStrength). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
            }
        }
    }
    
    @Published var meanReversionTarget: Double = 0.0 {
        didSet {
            print("didSet: meanReversionTarget changed to \(meanReversionTarget). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(meanReversionTarget, forKey: "meanReversionTarget")
            }
        }
    }
    
    @Published var lastUsedSeed: UInt64 = 0
    
    // =============================
    // MARK: BULLISH FACTORS (weekly/monthly)
    // =============================
    
    @Published var useHalvingWeekly: Bool = true {
        didSet {
            print("didSet: useHalvingWeekly changed to \(useHalvingWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useHalvingWeekly else { return }
            UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
        }
    }
    @Published var halvingBumpWeekly: Double = SimulationSettings.defaultHalvingBumpWeekly {
        didSet {
            print("didSet: halvingBumpWeekly changed to \(halvingBumpWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != halvingBumpWeekly {
                UserDefaults.standard.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
            }
        }
    }
    @Published var useHalvingMonthly: Bool = true {
        didSet {
            print("didSet: useHalvingMonthly changed to \(useHalvingMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useHalvingMonthly else { return }
            UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")
        }
    }
    @Published var halvingBumpMonthly: Double = SimulationSettings.defaultHalvingBumpMonthly {
        didSet {
            print("didSet: halvingBumpMonthly changed to \(halvingBumpMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != halvingBumpMonthly {
                UserDefaults.standard.set(halvingBumpMonthly, forKey: "halvingBumpMonthly")
            }
        }
    }
    
    @Published var useInstitutionalDemandWeekly: Bool = true {
        didSet {
            print("didSet: useInstitutionalDemandWeekly changed to \(useInstitutionalDemandWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandWeekly else { return }
            UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
        }
    }
    @Published var maxDemandBoostWeekly: Double = SimulationSettings.defaultMaxDemandBoostWeekly {
        didSet {
            print("didSet: maxDemandBoostWeekly changed to \(maxDemandBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxDemandBoostWeekly {
                UserDefaults.standard.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
            }
        }
    }
    @Published var useInstitutionalDemandMonthly: Bool = true {
        didSet {
            print("didSet: useInstitutionalDemandMonthly changed to \(useInstitutionalDemandMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandMonthly else { return }
            UserDefaults.standard.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
        }
    }
    @Published var maxDemandBoostMonthly: Double = SimulationSettings.defaultMaxDemandBoostMonthly {
        didSet {
            print("didSet: maxDemandBoostMonthly changed to \(maxDemandBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxDemandBoostMonthly {
                UserDefaults.standard.set(maxDemandBoostMonthly, forKey: "maxDemandBoostMonthly")
            }
        }
    }
    
    @Published var useCountryAdoptionWeekly: Bool = true {
        didSet {
            print("didSet: useCountryAdoptionWeekly changed to \(useCountryAdoptionWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionWeekly else { return }
            UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
        }
    }
    @Published var maxCountryAdBoostWeekly: Double = SimulationSettings.defaultMaxCountryAdBoostWeekly {
        didSet {
            print("didSet: maxCountryAdBoostWeekly changed to \(maxCountryAdBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostWeekly {
                UserDefaults.standard.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
            }
        }
    }
    @Published var useCountryAdoptionMonthly: Bool = true {
        didSet {
            print("didSet: useCountryAdoptionMonthly changed to \(useCountryAdoptionMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionMonthly else { return }
            UserDefaults.standard.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
        }
    }
    @Published var maxCountryAdBoostMonthly: Double = SimulationSettings.defaultMaxCountryAdBoostMonthly {
        didSet {
            print("didSet: maxCountryAdBoostMonthly changed to \(maxCountryAdBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostMonthly {
                UserDefaults.standard.set(maxCountryAdBoostMonthly, forKey: "maxCountryAdBoostMonthly")
            }
        }
    }
    
    @Published var useRegulatoryClarityWeekly: Bool = true {
        didSet {
            print("didSet: useRegulatoryClarityWeekly changed to \(useRegulatoryClarityWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityWeekly else { return }
            UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
        }
    }
    @Published var maxClarityBoostWeekly: Double = SimulationSettings.defaultMaxClarityBoostWeekly {
        didSet {
            print("didSet: maxClarityBoostWeekly changed to \(maxClarityBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxClarityBoostWeekly {
                UserDefaults.standard.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
            }
        }
    }
    @Published var useRegulatoryClarityMonthly: Bool = true {
        didSet {
            print("didSet: useRegulatoryClarityMonthly changed to \(useRegulatoryClarityMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityMonthly else { return }
            UserDefaults.standard.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
        }
    }
    @Published var maxClarityBoostMonthly: Double = SimulationSettings.defaultMaxClarityBoostMonthly {
        didSet {
            print("didSet: maxClarityBoostMonthly changed to \(maxClarityBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxClarityBoostMonthly {
                UserDefaults.standard.set(maxClarityBoostMonthly, forKey: "maxClarityBoostMonthly")
            }
        }
    }
    
    @Published var useEtfApprovalWeekly: Bool = true {
        didSet {
            print("didSet: useEtfApprovalWeekly changed to \(useEtfApprovalWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalWeekly else { return }
            UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
        }
    }
    @Published var maxEtfBoostWeekly: Double = SimulationSettings.defaultMaxEtfBoostWeekly {
        didSet {
            print("didSet: maxEtfBoostWeekly changed to \(maxEtfBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxEtfBoostWeekly {
                UserDefaults.standard.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
            }
        }
    }
    @Published var useEtfApprovalMonthly: Bool = true {
        didSet {
            print("didSet: useEtfApprovalMonthly changed to \(useEtfApprovalMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalMonthly else { return }
            UserDefaults.standard.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
        }
    }
    @Published var maxEtfBoostMonthly: Double = SimulationSettings.defaultMaxEtfBoostMonthly {
        didSet {
            print("didSet: maxEtfBoostMonthly changed to \(maxEtfBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxEtfBoostMonthly {
                UserDefaults.standard.set(maxEtfBoostMonthly, forKey: "maxEtfBoostMonthly")
            }
        }
    }
    
    @Published var useTechBreakthroughWeekly: Bool = true {
        didSet {
            print("didSet: useTechBreakthroughWeekly changed to \(useTechBreakthroughWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughWeekly else { return }
            UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
        }
    }
    @Published var maxTechBoostWeekly: Double = SimulationSettings.defaultMaxTechBoostWeekly {
        didSet {
            print("didSet: maxTechBoostWeekly changed to \(maxTechBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxTechBoostWeekly {
                UserDefaults.standard.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
            }
        }
    }
    @Published var useTechBreakthroughMonthly: Bool = true {
        didSet {
            print("didSet: useTechBreakthroughMonthly changed to \(useTechBreakthroughMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughMonthly else { return }
            UserDefaults.standard.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
        }
    }
    @Published var maxTechBoostMonthly: Double = SimulationSettings.defaultMaxTechBoostMonthly {
        didSet {
            print("didSet: maxTechBoostMonthly changed to \(maxTechBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxTechBoostMonthly {
                UserDefaults.standard.set(maxTechBoostMonthly, forKey: "maxTechBoostMonthly")
            }
        }
    }
    
    @Published var useScarcityEventsWeekly: Bool = true {
        didSet {
            print("didSet: useScarcityEventsWeekly changed to \(useScarcityEventsWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsWeekly else { return }
            UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
        }
    }
    @Published var maxScarcityBoostWeekly: Double = SimulationSettings.defaultMaxScarcityBoostWeekly {
        didSet {
            print("didSet: maxScarcityBoostWeekly changed to \(maxScarcityBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostWeekly {
                UserDefaults.standard.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
            }
        }
    }
    @Published var useScarcityEventsMonthly: Bool = true {
        didSet {
            print("didSet: useScarcityEventsMonthly changed to \(useScarcityEventsMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsMonthly else { return }
            UserDefaults.standard.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
        }
    }
    @Published var maxScarcityBoostMonthly: Double = SimulationSettings.defaultMaxScarcityBoostMonthly {
        didSet {
            print("didSet: maxScarcityBoostMonthly changed to \(maxScarcityBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostMonthly {
                UserDefaults.standard.set(maxScarcityBoostMonthly, forKey: "maxScarcityBoostMonthly")
            }
        }
    }
    
    @Published var useGlobalMacroHedgeWeekly: Bool = true {
        didSet {
            print("didSet: useGlobalMacroHedgeWeekly changed to \(useGlobalMacroHedgeWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeWeekly else { return }
            UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
        }
    }
    @Published var maxMacroBoostWeekly: Double = SimulationSettings.defaultMaxMacroBoostWeekly {
        didSet {
            print("didSet: maxMacroBoostWeekly changed to \(maxMacroBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxMacroBoostWeekly {
                UserDefaults.standard.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
            }
        }
    }
    @Published var useGlobalMacroHedgeMonthly: Bool = true {
        didSet {
            print("didSet: useGlobalMacroHedgeMonthly changed to \(useGlobalMacroHedgeMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeMonthly else { return }
            UserDefaults.standard.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
        }
    }
    @Published var maxMacroBoostMonthly: Double = SimulationSettings.defaultMaxMacroBoostMonthly {
        didSet {
            print("didSet: maxMacroBoostMonthly changed to \(maxMacroBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxMacroBoostMonthly {
                UserDefaults.standard.set(maxMacroBoostMonthly, forKey: "maxMacroBoostMonthly")
            }
        }
    }
    
    @Published var useStablecoinShiftWeekly: Bool = true {
        didSet {
            print("didSet: useStablecoinShiftWeekly changed to \(useStablecoinShiftWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftWeekly else { return }
            UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
        }
    }
    @Published var maxStablecoinBoostWeekly: Double = SimulationSettings.defaultMaxStablecoinBoostWeekly {
        didSet {
            print("didSet: maxStablecoinBoostWeekly changed to \(maxStablecoinBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostWeekly {
                UserDefaults.standard.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
            }
        }
    }
    @Published var useStablecoinShiftMonthly: Bool = true {
        didSet {
            print("didSet: useStablecoinShiftMonthly changed to \(useStablecoinShiftMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftMonthly else { return }
            UserDefaults.standard.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
        }
    }
    @Published var maxStablecoinBoostMonthly: Double = SimulationSettings.defaultMaxStablecoinBoostMonthly {
        didSet {
            print("didSet: maxStablecoinBoostMonthly changed to \(maxStablecoinBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostMonthly {
                UserDefaults.standard.set(maxStablecoinBoostMonthly, forKey: "maxStablecoinBoostMonthly")
            }
        }
    }
    
    @Published var useDemographicAdoptionWeekly: Bool = true {
        didSet {
            print("didSet: useDemographicAdoptionWeekly changed to \(useDemographicAdoptionWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionWeekly else { return }
            UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
        }
    }
    @Published var maxDemoBoostWeekly: Double = SimulationSettings.defaultMaxDemoBoostWeekly {
        didSet {
            print("didSet: maxDemoBoostWeekly changed to \(maxDemoBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxDemoBoostWeekly {
                UserDefaults.standard.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
            }
        }
    }
    @Published var useDemographicAdoptionMonthly: Bool = true {
        didSet {
            print("didSet: useDemographicAdoptionMonthly changed to \(useDemographicAdoptionMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionMonthly else { return }
            UserDefaults.standard.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
        }
    }
    @Published var maxDemoBoostMonthly: Double = SimulationSettings.defaultMaxDemoBoostMonthly {
        didSet {
            print("didSet: maxDemoBoostMonthly changed to \(maxDemoBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxDemoBoostMonthly {
                UserDefaults.standard.set(maxDemoBoostMonthly, forKey: "maxDemoBoostMonthly")
            }
        }
    }
    
    @Published var useAltcoinFlightWeekly: Bool = true {
        didSet {
            print("didSet: useAltcoinFlightWeekly changed to \(useAltcoinFlightWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightWeekly else { return }
            UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
        }
    }
    @Published var maxAltcoinBoostWeekly: Double = SimulationSettings.defaultMaxAltcoinBoostWeekly {
        didSet {
            print("didSet: maxAltcoinBoostWeekly changed to \(maxAltcoinBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostWeekly {
                UserDefaults.standard.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
            }
        }
    }
    @Published var useAltcoinFlightMonthly: Bool = true {
        didSet {
            print("didSet: useAltcoinFlightMonthly changed to \(useAltcoinFlightMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightMonthly else { return }
            UserDefaults.standard.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
        }
    }
    @Published var maxAltcoinBoostMonthly: Double = SimulationSettings.defaultMaxAltcoinBoostMonthly {
        didSet {
            print("didSet: maxAltcoinBoostMonthly changed to \(maxAltcoinBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostMonthly {
                UserDefaults.standard.set(maxAltcoinBoostMonthly, forKey: "maxAltcoinBoostMonthly")
            }
        }
    }
    
    @Published var useAdoptionFactorWeekly: Bool = true {
        didSet {
            print("didSet: useAdoptionFactorWeekly changed to \(useAdoptionFactorWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorWeekly else { return }
            UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
        }
    }
    @Published var adoptionBaseFactorWeekly: Double = SimulationSettings.defaultAdoptionBaseFactorWeekly {
        didSet {
            print("didSet: adoptionBaseFactorWeekly changed to \(adoptionBaseFactorWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorWeekly {
                UserDefaults.standard.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
            }
        }
    }
    @Published var useAdoptionFactorMonthly: Bool = true {
        didSet {
            print("didSet: useAdoptionFactorMonthly changed to \(useAdoptionFactorMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorMonthly else { return }
            UserDefaults.standard.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
        }
    }
    @Published var adoptionBaseFactorMonthly: Double = SimulationSettings.defaultAdoptionBaseFactorMonthly {
        didSet {
            print("didSet: adoptionBaseFactorMonthly changed to \(adoptionBaseFactorMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorMonthly {
                UserDefaults.standard.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")
            }
        }
    }
    
    // =============================
    // MARK: BEARISH FACTORS (weekly/monthly)
    // =============================
    
    @Published var useRegClampdownWeekly: Bool = true {
        didSet {
            print("didSet: useRegClampdownWeekly changed to \(useRegClampdownWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useRegClampdownWeekly else { return }
            UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
        }
    }
    @Published var maxClampDownWeekly: Double = SimulationSettings.defaultMaxClampDownWeekly {
        didSet {
            print("didSet: maxClampDownWeekly changed to \(maxClampDownWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxClampDownWeekly {
                UserDefaults.standard.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
            }
        }
    }
    @Published var useRegClampdownMonthly: Bool = true {
        didSet {
            print("didSet: useRegClampdownMonthly changed to \(useRegClampdownMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useRegClampdownMonthly else { return }
            UserDefaults.standard.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
        }
    }
    @Published var maxClampDownMonthly: Double = SimulationSettings.defaultMaxClampDownMonthly {
        didSet {
            print("didSet: maxClampDownMonthly changed to \(maxClampDownMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxClampDownMonthly {
                UserDefaults.standard.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")
            }
        }
    }
    
    @Published var useCompetitorCoinWeekly: Bool = true {
        didSet {
            print("didSet: useCompetitorCoinWeekly changed to \(useCompetitorCoinWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinWeekly else { return }
            UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
        }
    }
    @Published var maxCompetitorBoostWeekly: Double = SimulationSettings.defaultMaxCompetitorBoostWeekly {
        didSet {
            print("didSet: maxCompetitorBoostWeekly changed to \(maxCompetitorBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostWeekly {
                UserDefaults.standard.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
            }
        }
    }
    @Published var useCompetitorCoinMonthly: Bool = true {
        didSet {
            print("didSet: useCompetitorCoinMonthly changed to \(useCompetitorCoinMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinMonthly else { return }
            UserDefaults.standard.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
        }
    }
    @Published var maxCompetitorBoostMonthly: Double = SimulationSettings.defaultMaxCompetitorBoostMonthly {
        didSet {
            print("didSet: maxCompetitorBoostMonthly changed to \(maxCompetitorBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostMonthly {
                UserDefaults.standard.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")
            }
        }
    }
    
    @Published var useSecurityBreachWeekly: Bool = true {
        didSet {
            print("didSet: useSecurityBreachWeekly changed to \(useSecurityBreachWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachWeekly else { return }
            UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
        }
    }
    @Published var breachImpactWeekly: Double = SimulationSettings.defaultBreachImpactWeekly {
        didSet {
            print("didSet: breachImpactWeekly changed to \(breachImpactWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != breachImpactWeekly {
                UserDefaults.standard.set(breachImpactWeekly, forKey: "breachImpactWeekly")
            }
        }
    }
    @Published var useSecurityBreachMonthly: Bool = true {
        didSet {
            print("didSet: useSecurityBreachMonthly changed to \(useSecurityBreachMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachMonthly else { return }
            UserDefaults.standard.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
        }
    }
    @Published var breachImpactMonthly: Double = SimulationSettings.defaultBreachImpactMonthly {
        didSet {
            print("didSet: breachImpactMonthly changed to \(breachImpactMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != breachImpactMonthly {
                UserDefaults.standard.set(breachImpactMonthly, forKey: "breachImpactMonthly")
            }
        }
    }
    
    @Published var useBubblePopWeekly: Bool = true {
        didSet {
            print("didSet: useBubblePopWeekly changed to \(useBubblePopWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useBubblePopWeekly else { return }
            UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
        }
    }
    @Published var maxPopDropWeekly: Double = SimulationSettings.defaultMaxPopDropWeekly {
        didSet {
            print("didSet: maxPopDropWeekly changed to \(maxPopDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxPopDropWeekly {
                UserDefaults.standard.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
            }
        }
    }
    @Published var useBubblePopMonthly: Bool = true {
        didSet {
            print("didSet: useBubblePopMonthly changed to \(useBubblePopMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useBubblePopMonthly else { return }
            UserDefaults.standard.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
        }
    }
    @Published var maxPopDropMonthly: Double = SimulationSettings.defaultMaxPopDropMonthly {
        didSet {
            print("didSet: maxPopDropMonthly changed to \(maxPopDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxPopDropMonthly {
                UserDefaults.standard.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")
            }
        }
    }
    
    @Published var useStablecoinMeltdownWeekly: Bool = true {
        didSet {
            print("didSet: useStablecoinMeltdownWeekly changed to \(useStablecoinMeltdownWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownWeekly else { return }
            UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
        }
    }
    @Published var maxMeltdownDropWeekly: Double = SimulationSettings.defaultMaxMeltdownDropWeekly {
        didSet {
            print("didSet: maxMeltdownDropWeekly changed to \(maxMeltdownDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropWeekly {
                UserDefaults.standard.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
            }
        }
    }
    @Published var useStablecoinMeltdownMonthly: Bool = true {
        didSet {
            print("didSet: useStablecoinMeltdownMonthly changed to \(useStablecoinMeltdownMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownMonthly else { return }
            UserDefaults.standard.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
        }
    }
    @Published var maxMeltdownDropMonthly: Double = SimulationSettings.defaultMaxMeltdownDropMonthly {
        didSet {
            print("didSet: maxMeltdownDropMonthly changed to \(maxMeltdownDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropMonthly {
                UserDefaults.standard.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")
            }
        }
    }
    
    @Published var useBlackSwanWeekly: Bool = true {
        didSet {
            print("didSet: useBlackSwanWeekly changed to \(useBlackSwanWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useBlackSwanWeekly else { return }
            UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
        }
    }
    @Published var blackSwanDropWeekly: Double = SimulationSettings.defaultBlackSwanDropWeekly {
        didSet {
            print("didSet: blackSwanDropWeekly changed to \(blackSwanDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != blackSwanDropWeekly {
                UserDefaults.standard.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
            }
        }
    }
    @Published var useBlackSwanMonthly: Bool = true {
        didSet {
            print("didSet: useBlackSwanMonthly changed to \(useBlackSwanMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useBlackSwanMonthly else { return }
            UserDefaults.standard.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
        }
    }
    @Published var blackSwanDropMonthly: Double = SimulationSettings.defaultBlackSwanDropMonthly {
        didSet {
            print("didSet: blackSwanDropMonthly changed to \(blackSwanDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != blackSwanDropMonthly {
                UserDefaults.standard.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")
            }
        }
    }
    
    @Published var useBearMarketWeekly: Bool = true {
        didSet {
            print("didSet: useBearMarketWeekly changed to \(useBearMarketWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useBearMarketWeekly else { return }
            UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
        }
    }
    @Published var bearWeeklyDriftWeekly: Double = SimulationSettings.defaultBearWeeklyDriftWeekly {
        didSet {
            print("didSet: bearWeeklyDriftWeekly changed to \(bearWeeklyDriftWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftWeekly {
                UserDefaults.standard.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
            }
        }
    }
    @Published var useBearMarketMonthly: Bool = true {
        didSet {
            print("didSet: useBearMarketMonthly changed to \(useBearMarketMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useBearMarketMonthly else { return }
            UserDefaults.standard.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
        }
    }
    @Published var bearWeeklyDriftMonthly: Double = SimulationSettings.defaultBearWeeklyDriftMonthly {
        didSet {
            print("didSet: bearWeeklyDriftMonthly changed to \(bearWeeklyDriftMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftMonthly {
                UserDefaults.standard.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")
            }
        }
    }
    
    @Published var useMaturingMarketWeekly: Bool = true {
        didSet {
            print("didSet: useMaturingMarketWeekly changed to \(useMaturingMarketWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketWeekly else { return }
            UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
        }
    }
    @Published var maxMaturingDropWeekly: Double = SimulationSettings.defaultMaxMaturingDropWeekly {
        didSet {
            print("didSet: maxMaturingDropWeekly changed to \(maxMaturingDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxMaturingDropWeekly {
                UserDefaults.standard.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
            }
        }
    }
    @Published var useMaturingMarketMonthly: Bool = true {
        didSet {
            print("didSet: useMaturingMarketMonthly changed to \(useMaturingMarketMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketMonthly else { return }
            UserDefaults.standard.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
        }
    }
    @Published var maxMaturingDropMonthly: Double = SimulationSettings.defaultMaxMaturingDropMonthly {
        didSet {
            print("didSet: maxMaturingDropMonthly changed to \(maxMaturingDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxMaturingDropMonthly {
                UserDefaults.standard.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")
            }
        }
    }
    
    @Published var useRecessionWeekly: Bool = true {
        didSet {
            print("didSet: useRecessionWeekly changed to \(useRecessionWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useRecessionWeekly else { return }
            UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
        }
    }
    @Published var maxRecessionDropWeekly: Double = SimulationSettings.defaultMaxRecessionDropWeekly {
        didSet {
            print("didSet: maxRecessionDropWeekly changed to \(maxRecessionDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxRecessionDropWeekly {
                UserDefaults.standard.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
            }
        }
    }
    @Published var useRecessionMonthly: Bool = true {
        didSet {
            print("didSet: useRecessionMonthly changed to \(useRecessionMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, !isUpdating, oldValue != useRecessionMonthly else { return }
            UserDefaults.standard.set(useRecessionMonthly, forKey: "useRecessionMonthly")
        }
    }
    @Published var maxRecessionDropMonthly: Double = SimulationSettings.defaultMaxRecessionDropMonthly {
        didSet {
            print("didSet: maxRecessionDropMonthly changed to \(maxRecessionDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && !isUpdating && oldValue != maxRecessionDropMonthly {
                UserDefaults.standard.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")
            }
        }
    }
    
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            print("didSet: lockHistoricalSampling changed to \(lockHistoricalSampling). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }

    func finalizeToggleStateAfterLoad() {
        // Currently no forced changes here
        isUpdating = false
    }
    
    // We won't call these from periodUnit.didSet anymore, since we no longer forcibly turn off toggles.
    // But we'll leave the methods here in case they're needed in some other context.
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

    // The big combined check:
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
            print("toggleAll set to \(newValue) for \(periodUnit). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
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
}
