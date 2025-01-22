//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    
    init() {
        // Initialization
        isUpdating = false
        isInitialized = false
    }

    var inputManager: PersistentInputManager?
    
    @Published var userIsActuallyTogglingAll = false
    @Published var isOnboarding: Bool = false
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet {
            print("didSet: periodUnit changed to \(periodUnit). isInitialized=\(isInitialized)")
            guard isInitialized else { return }
        }
    }
    
    @Published var userPeriods: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
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
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    var isInitialized = false
    var isUpdating = false
    
    // MARK: Settings Toggles
    @Published var useLognormalGrowth: Bool = true {
        didSet {
            print("didSet: useLognormalGrowth changed to \(useLognormalGrowth).")
            UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        }
    }
    
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
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            print("didSet: lockHistoricalSampling changed to \(lockHistoricalSampling). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }
    
    func finalizeToggleStateAfterLoad() {
        isUpdating = false
    }
    
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

    // MARK: - UserDefaults Handling

    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        seedValue = defaults.object(forKey: "seedValue") as? UInt64 ?? 0
        useRandomSeed = defaults.bool(forKey: "useRandomSeed")
        useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        useVolShocks = defaults.bool(forKey: "useVolShocks")
        useGarchVolatility = defaults.bool(forKey: "useGarchVolatility")
        useAutoCorrelation = defaults.bool(forKey: "useAutoCorrelation")
        autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        lockHistoricalSampling = defaults.bool(forKey: "lockHistoricalSampling")
    }

    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        defaults.set(lockedRandomSeed, forKey: "lockedRandomSeed")
        defaults.set(seedValue, forKey: "seedValue")
        defaults.set(useRandomSeed, forKey: "useRandomSeed")
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks, forKey: "useVolShocks")
        defaults.set(useGarchVolatility, forKey: "useGarchVolatility")
        defaults.set(useAutoCorrelation, forKey: "useAutoCorrelation")
        defaults.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
        defaults.set(meanReversionTarget, forKey: "meanReversionTarget")
        defaults.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
        defaults.synchronize()
    }
}
