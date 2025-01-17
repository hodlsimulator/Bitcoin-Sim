//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {
    
    // Hardcoded default constants (instance level)
    private static let defaultHalvingBumpWeekly = 0.48
    private static let defaultHalvingBumpMonthly = 0.58
    private static let defaultMaxDemandBoostWeekly = 0.0012392541338671777
    private static let defaultMaxDemandBoostMonthly = 0.0012392541338671777
    private static let defaultMaxCountryAdBoostWeekly = 0.00047095964199831683
    private static let defaultMaxCountryAdBoostMonthly = 0.00047095964199831683

    init() {
    }
    
    var inputManager: PersistentInputManager? = nil
    
    // @AppStorage("useLognormalGrowth") var useLognormalGrowth: Bool = true

    // MARK: - Weekly vs. Monthly
    /// The user’s chosen period unit (weeks or months)
    @Published var periodUnit: PeriodUnit = .weeks
    
    /// The total number of periods, e.g. 1040 for weeks, 240 for months
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

    @Published var toggleAll = false {
        didSet {
            print(">> toggleAll changed to \(toggleAll). isInitialized=\(isInitialized)")
            if isInitialized {
                if isUpdating { return }
                isUpdating = true
                if toggleAll {
                    // Turn ON all factors
                    useHalving = true
                    useInstitutionalDemand = true
                    useCountryAdoption = true
                    useRegulatoryClarity = true
                    useEtfApproval = true
                    useTechBreakthrough = true
                    useScarcityEvents = true
                    useGlobalMacroHedge = true
                    useStablecoinShift = true
                    useDemographicAdoption = true
                    useAltcoinFlight = true
                    useAdoptionFactor = true
                    useRegClampdown = true
                    useCompetitorCoin = true
                    useSecurityBreach = true
                    useBubblePop = true
                    useStablecoinMeltdown = true
                    useBlackSwan = true
                    useBearMarket = true
                    useMaturingMarket = true
                    useRecession = true
                } else {
                    // Turn OFF all factors
                    useHalving = false
                    useInstitutionalDemand = false
                    useCountryAdoption = false
                    useRegulatoryClarity = false
                    useEtfApproval = false
                    useTechBreakthrough = false
                    useScarcityEvents = false
                    useGlobalMacroHedge = false
                    useStablecoinShift = false
                    useDemographicAdoption = false
                    useAltcoinFlight = false
                    useAdoptionFactor = false
                    useRegClampdown = false
                    useCompetitorCoin = false
                    useSecurityBreach = false
                    useBubblePop = false
                    useStablecoinMeltdown = false
                    useBlackSwan = false
                    useBearMarket = false
                    useMaturingMarket = false
                    useRecession = false
                }
                isUpdating = false
            }
        }
    }

    func syncToggleAllState() {
        if !isUpdating {
            isUpdating = true
            let allFactorsEnabled =
                useHalving &&
                useInstitutionalDemand &&
                useCountryAdoption &&
                useRegulatoryClarity &&
                useEtfApproval &&
                useTechBreakthrough &&
                useScarcityEvents &&
                useGlobalMacroHedge &&
                useStablecoinShift &&
                useDemographicAdoption &&
                useAltcoinFlight &&
                useAdoptionFactor &&
                useRegClampdown &&
                useCompetitorCoin &&
                useSecurityBreach &&
                useBubblePop &&
                useStablecoinMeltdown &&
                useBlackSwan &&
                useBearMarket &&
                useMaturingMarket &&
                useRecession

            if toggleAll != allFactorsEnabled {
                toggleAll = allFactorsEnabled
            }
            isUpdating = false
        }
    }

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
    @Published var lastUsedSeed: UInt64 = 0

    var isUpdating = false

    // -----------------------------
    // MARK: - BULLISH FACTORS
    // -----------------------------

    // Halving
        @Published var useHalving: Bool = true {
            didSet {
                if isInitialized {
                    UserDefaults.standard.set(useHalving, forKey: "useHalving")
                    syncToggleAllState()
                }
            }
        }

        // WEEKLY
        @Published var useHalvingWeekly: Bool = true {
            didSet {
                if isInitialized {
                    UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
                }
            }
        }
        @Published var halvingBumpWeekly: Double = SimulationSettings.defaultHalvingBumpWeekly {
            didSet {
                if isInitialized {
                    UserDefaults.standard.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
                }
            }
        }

        // MONTHLY
        @Published var useHalvingMonthly: Bool = true {
            didSet {
                if isInitialized {
                    UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")
                }
            }
        }
        @Published var halvingBumpMonthly: Double = SimulationSettings.defaultHalvingBumpMonthly {
            didSet {
                if isInitialized {
                    UserDefaults.standard.set(halvingBumpMonthly, forKey: "halvingBumpMonthly")
                }
            }
        }

    // Institutional Demand
    @Published var useInstitutionalDemand: Bool = true {
        didSet {
            print(">> useInstitutionalDemand changed to \(useInstitutionalDemand). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useInstitutionalDemandWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
            }
        }
    }
    @Published var maxDemandBoostWeekly: Double = SimulationSettings.defaultMaxDemandBoostWeekly {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useInstitutionalDemandMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
            }
        }
    }
    @Published var maxDemandBoostMonthly: Double = SimulationSettings.defaultMaxDemandBoostMonthly {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemandBoostMonthly, forKey: "maxDemandBoostMonthly")
            }
        }
    }

    // Country Adoption
    @Published var useCountryAdoption: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useCountryAdoptionWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
            }
        }
    }
    @Published var maxCountryAdBoostWeekly: Double = SimulationSettings.defaultMaxCountryAdBoostWeekly {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useCountryAdoptionMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
            }
        }
    }
    @Published var maxCountryAdBoostMonthly: Double = SimulationSettings.defaultMaxCountryAdBoostMonthly {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCountryAdBoostMonthly, forKey: "maxCountryAdBoostMonthly")
            }
        }
    }

    // Regulatory Clarity
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClarityBoost: Double = 0.0016644023749474966 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClarityBoost, forKey: "maxClarityBoost")
            }
        }
    }
    // Weekly
    @Published var useRegulatoryClarityWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
            }
        }
    }
    @Published var maxClarityBoostWeekly: Double = 0.0016644023749474966 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useRegulatoryClarityMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
            }
        }
    }
    @Published var maxClarityBoostMonthly: Double = 0.0016644023749474966 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClarityBoostMonthly, forKey: "maxClarityBoostMonthly")
            }
        }
    }

    // ETF Approval
    @Published var useEtfApproval: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
                syncToggleAllState()
            }
        }
    }
    @Published var maxEtfBoost: Double = 0.0004546850204467774 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxEtfBoost, forKey: "maxEtfBoost")
            }
        }
    }
    // Weekly
    @Published var useEtfApprovalWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
            }
        }
    }
    @Published var maxEtfBoostWeekly: Double = 0.0004546850204467774 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useEtfApprovalMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
            }
        }
    }
    @Published var maxEtfBoostMonthly: Double = 0.0004546850204467774 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxEtfBoostMonthly, forKey: "maxEtfBoostMonthly")
            }
        }
    }

    // Tech Breakthrough
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
                syncToggleAllState()
            }
        }
    }
    @Published var maxTechBoost: Double = 0.00040663959745637255 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxTechBoost, forKey: "maxTechBoost")
            }
        }
    }
    // Weekly
    @Published var useTechBreakthroughWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
            }
        }
    }
    @Published var maxTechBoostWeekly: Double = 0.00040663959745637255 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useTechBreakthroughMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
            }
        }
    }
    @Published var maxTechBoostMonthly: Double = 0.00040663959745637255 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxTechBoostMonthly, forKey: "maxTechBoostMonthly")
            }
        }
    }

    // Scarcity Events
    @Published var useScarcityEvents: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
                syncToggleAllState()
            }
        }
    }
    @Published var maxScarcityBoost: Double = 0.0007968083934443039 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxScarcityBoost, forKey: "maxScarcityBoost")
            }
        }
    }
    // Weekly
    @Published var useScarcityEventsWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
            }
        }
    }
    @Published var maxScarcityBoostWeekly: Double = 0.0007968083934443039 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useScarcityEventsMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
            }
        }
    }
    @Published var maxScarcityBoostMonthly: Double = 0.0007968083934443039 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxScarcityBoostMonthly, forKey: "maxScarcityBoostMonthly")
            }
        }
    }

    // Global Macro Hedge
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMacroBoost: Double = 0.000419354572892189 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMacroBoost, forKey: "maxMacroBoost")
            }
        }
    }
    // Weekly
    @Published var useGlobalMacroHedgeWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
            }
        }
    }
    @Published var maxMacroBoostWeekly: Double = 0.000419354572892189 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useGlobalMacroHedgeMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
            }
        }
    }
    @Published var maxMacroBoostMonthly: Double = 0.000419354572892189 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMacroBoostMonthly, forKey: "maxMacroBoostMonthly")
            }
        }
    }

    // Stablecoin Shift
    @Published var useStablecoinShift: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
                syncToggleAllState()
            }
        }
    }
    @Published var maxStablecoinBoost: Double = 0.0004049262363101775 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxStablecoinBoost, forKey: "maxStablecoinBoost")
            }
        }
    }
    // Weekly
    @Published var useStablecoinShiftWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
            }
        }
    }
    @Published var maxStablecoinBoostWeekly: Double = 0.0004049262363101775 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useStablecoinShiftMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
            }
        }
    }
    @Published var maxStablecoinBoostMonthly: Double = 0.0004049262363101775 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxStablecoinBoostMonthly, forKey: "maxStablecoinBoostMonthly")
            }
        }
    }

    // Demographic Adoption
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
                syncToggleAllState()
            }
        }
    }
    @Published var maxDemoBoost: Double = 0.0013056834936141968 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemoBoost, forKey: "maxDemoBoost")
            }
        }
    }
    // Weekly
    @Published var useDemographicAdoptionWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
            }
        }
    }
    @Published var maxDemoBoostWeekly: Double = 0.0013056834936141968 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useDemographicAdoptionMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
            }
        }
    }
    @Published var maxDemoBoostMonthly: Double = 0.0013056834936141968 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemoBoostMonthly, forKey: "maxDemoBoostMonthly")
            }
        }
    }

    // Altcoin Flight
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
                syncToggleAllState()
            }
        }
    }
    @Published var maxAltcoinBoost: Double = 0.0002802194461803342 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxAltcoinBoost, forKey: "maxAltcoinBoost")
            }
        }
    }
    // Weekly
    @Published var useAltcoinFlightWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
            }
        }
    }
    @Published var maxAltcoinBoostWeekly: Double = 0.0002802194461803342 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useAltcoinFlightMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
            }
        }
    }
    @Published var maxAltcoinBoostMonthly: Double = 0.0002802194461803342 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxAltcoinBoostMonthly, forKey: "maxAltcoinBoostMonthly")
            }
        }
    }

    // Adoption Factor
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
                syncToggleAllState()
            }
        }
    }
    @Published var adoptionBaseFactor: Double = 0.0009685099124908447 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(adoptionBaseFactor, forKey: "adoptionBaseFactor")
            }
        }
    }
    // Weekly
    @Published var useAdoptionFactorWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
            }
        }
    }
    @Published var adoptionBaseFactorWeekly: Double = 0.0009685099124908447 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
            }
        }
    }
    // Monthly
    @Published var useAdoptionFactorMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
            }
        }
    }
    @Published var adoptionBaseFactorMonthly: Double = 0.0009685099124908447 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")
            }
        }
    }

    // -----------------------------
    // MARK: - BEARISH FACTORS
    // -----------------------------
    @Published var useRegClampdown: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClampDown: Double = -0.0011883256912231445 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClampDown, forKey: "maxClampDown")
            }
        }
    }
    // Weekly
    @Published var useRegClampdownWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
            }
        }
    }
    @Published var maxClampDownWeekly: Double = -0.0011883256912231445 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
            }
        }
    }
    // Monthly
    @Published var useRegClampdownMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
            }
        }
    }
    @Published var maxClampDownMonthly: Double = -0.0011883256912231445 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")
            }
        }
    }

    @Published var useCompetitorCoin: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")
                syncToggleAllState()
            }
        }
    }
    @Published var maxCompetitorBoost: Double = -0.0011259913444519043 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCompetitorBoost, forKey: "maxCompetitorBoost")
            }
        }
    }
    // Weekly
    @Published var useCompetitorCoinWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
            }
        }
    }
    @Published var maxCompetitorBoostWeekly: Double = -0.0011259913444519043 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
            }
        }
    }
    // Monthly
    @Published var useCompetitorCoinMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
            }
        }
    }
    @Published var maxCompetitorBoostMonthly: Double = -0.0011259913444519043 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")
            }
        }
    }

    @Published var useSecurityBreach: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")
                syncToggleAllState()
            }
        }
    }
    @Published var breachImpact: Double = -0.0007612827334384092 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(breachImpact, forKey: "breachImpact")
            }
        }
    }
    // Weekly
    @Published var useSecurityBreachWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
            }
        }
    }
    @Published var breachImpactWeekly: Double = -0.0007612827334384092 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(breachImpactWeekly, forKey: "breachImpactWeekly")
            }
        }
    }
    // Monthly
    @Published var useSecurityBreachMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
            }
        }
    }
    @Published var breachImpactMonthly: Double = -0.0007612827334384092 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(breachImpactMonthly, forKey: "breachImpactMonthly")
            }
        }
    }

    @Published var useBubblePop: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")
                syncToggleAllState()
            }
        }
    }
    @Published var maxPopDrop: Double = -0.0012555068731307985 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxPopDrop, forKey: "maxPopDrop")
            }
        }
    }
    // Weekly
    @Published var useBubblePopWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
            }
        }
    }
    @Published var maxPopDropWeekly: Double = -0.0012555068731307985 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
            }
        }
    }
    // Monthly
    @Published var useBubblePopMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
            }
        }
    }
    @Published var maxPopDropMonthly: Double = -0.0012555068731307985 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")
            }
        }
    }

    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMeltdownDrop: Double = -0.0007028046205417837 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMeltdownDrop, forKey: "maxMeltdownDrop")
            }
        }
    }
    // Weekly
    @Published var useStablecoinMeltdownWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
            }
        }
    }
    @Published var maxMeltdownDropWeekly: Double = -0.0007028046205417837 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
            }
        }
    }
    // Monthly
    @Published var useStablecoinMeltdownMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
            }
        }
    }
    @Published var maxMeltdownDropMonthly: Double = -0.0007028046205417837 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")
            }
        }
    }

    @Published var useBlackSwan: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")
                syncToggleAllState()
            }
        }
    }
    @Published var blackSwanDrop: Double = -0.0018411452783672483 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(blackSwanDrop, forKey: "blackSwanDrop")
            }
        }
    }
    // Weekly
    @Published var useBlackSwanWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
            }
        }
    }
    @Published var blackSwanDropWeekly: Double = -0.0018411452783672483 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
            }
        }
    }
    // Monthly
    @Published var useBlackSwanMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
            }
        }
    }
    @Published var blackSwanDropMonthly: Double = -0.0018411452783672483 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")
            }
        }
    }

    @Published var useBearMarket: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")
                syncToggleAllState()
            }
        }
    }
    @Published var bearWeeklyDrift: Double = -0.0007195305824279769 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(bearWeeklyDrift, forKey: "bearWeeklyDrift")
            }
        }
    }
    // Weekly
    @Published var useBearMarketWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
            }
        }
    }
    @Published var bearWeeklyDriftWeekly: Double = -0.0007195305824279769 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
            }
        }
    }
    // Monthly
    @Published var useBearMarketMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
            }
        }
    }
    @Published var bearWeeklyDriftMonthly: Double = -0.0007195305824279769 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")
            }
        }
    }

    @Published var useMaturingMarket: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMaturingDrop: Double = -0.004 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMaturingDrop, forKey: "maxMaturingDrop")
            }
        }
    }
    // Weekly
    @Published var useMaturingMarketWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
            }
        }
    }
    @Published var maxMaturingDropWeekly: Double = -0.004 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
            }
        }
    }
    // Monthly
    @Published var useMaturingMarketMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
            }
        }
    }
    @Published var maxMaturingDropMonthly: Double = -0.004 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")
            }
        }
    }

    @Published var useRecession: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRecession, forKey: "useRecession")
                syncToggleAllState()
            }
        }
    }
    @Published var maxRecessionDrop: Double = -0.0014508080482482913 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxRecessionDrop, forKey: "maxRecessionDrop")
            }
        }
    }
    // Weekly
    @Published var useRecessionWeekly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
            }
        }
    }
    @Published var maxRecessionDropWeekly: Double = -0.0014508080482482913 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
            }
        }
    }
    // Monthly
    @Published var useRecessionMonthly: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRecessionMonthly, forKey: "useRecessionMonthly")
            }
        }
    }
    @Published var maxRecessionDropMonthly: Double = -0.0014508080482482913 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")
            }
        }
    }

    var areAllFactorsEnabled: Bool {
        useHalving &&
        useInstitutionalDemand &&
        useCountryAdoption &&
        useRegulatoryClarity &&
        useEtfApproval &&
        useTechBreakthrough &&
        useScarcityEvents &&
        useGlobalMacroHedge &&
        useStablecoinShift &&
        useDemographicAdoption &&
        useAltcoinFlight &&
        useAdoptionFactor &&
        useRegClampdown &&
        useCompetitorCoin &&
        useSecurityBreach &&
        useBubblePop &&
        useStablecoinMeltdown &&
        useBlackSwan &&
        useBearMarket &&
        useMaturingMarket &&
        useRecession
    }

    // -----------------------------
    // MARK: - NEW TOGGLE: LOCK HISTORICAL SAMPLING
    // -----------------------------
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }
    // -----------------------------

    // NEW: We'll compute a hash of the relevant toggles, so the simulation detects changes
    func computeInputsHash(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double
    ) -> UInt64 {
        var hasher = Hasher()
        
        // Combine period settings
        hasher.combine(periodUnit.rawValue)
        hasher.combine(userPeriods)
        
        hasher.combine(initialBTCPriceUSD)
        hasher.combine(startingBalance)
        hasher.combine(averageCostBasis)
        hasher.combine(lockedRandomSeed)
        hasher.combine(seedValue)
        hasher.combine(useRandomSeed)
        hasher.combine(useHistoricalSampling)
        hasher.combine(useVolShocks)
        hasher.combine(annualCAGR)
        hasher.combine(annualVolatility)
        hasher.combine(iterations)
        hasher.combine(currencyPreference.rawValue)
        hasher.combine(exchangeRateEURUSD)

        // Original toggles
        hasher.combine(useHalving)
        hasher.combine(useInstitutionalDemand)
        hasher.combine(useCountryAdoption)
        hasher.combine(useRegulatoryClarity)
        hasher.combine(useEtfApproval)
        hasher.combine(useTechBreakthrough)
        hasher.combine(useScarcityEvents)
        hasher.combine(useGlobalMacroHedge)
        hasher.combine(useStablecoinShift)
        hasher.combine(useDemographicAdoption)
        hasher.combine(useAltcoinFlight)
        hasher.combine(useAdoptionFactor)
        hasher.combine(useRegClampdown)
        hasher.combine(useCompetitorCoin)
        hasher.combine(useSecurityBreach)
        hasher.combine(useBubblePop)
        hasher.combine(useStablecoinMeltdown)
        hasher.combine(useBlackSwan)
        hasher.combine(useBearMarket)
        hasher.combine(useMaturingMarket)
        hasher.combine(useRecession)
        hasher.combine(lockHistoricalSampling)

        // New weekly/monthly toggles
        hasher.combine(useHalvingWeekly)
        hasher.combine(halvingBumpWeekly)
        hasher.combine(useHalvingMonthly)
        hasher.combine(halvingBumpMonthly)

        hasher.combine(useInstitutionalDemandWeekly)
        hasher.combine(maxDemandBoostWeekly)
        hasher.combine(useInstitutionalDemandMonthly)
        hasher.combine(maxDemandBoostMonthly)

        hasher.combine(useCountryAdoptionWeekly)
        hasher.combine(maxCountryAdBoostWeekly)
        hasher.combine(useCountryAdoptionMonthly)
        hasher.combine(maxCountryAdBoostMonthly)

        hasher.combine(useRegulatoryClarityWeekly)
        hasher.combine(maxClarityBoostWeekly)
        hasher.combine(useRegulatoryClarityMonthly)
        hasher.combine(maxClarityBoostMonthly)

        hasher.combine(useEtfApprovalWeekly)
        hasher.combine(maxEtfBoostWeekly)
        hasher.combine(useEtfApprovalMonthly)
        hasher.combine(maxEtfBoostMonthly)

        hasher.combine(useTechBreakthroughWeekly)
        hasher.combine(maxTechBoostWeekly)
        hasher.combine(useTechBreakthroughMonthly)
        hasher.combine(maxTechBoostMonthly)

        hasher.combine(useScarcityEventsWeekly)
        hasher.combine(maxScarcityBoostWeekly)
        hasher.combine(useScarcityEventsMonthly)
        hasher.combine(maxScarcityBoostMonthly)

        hasher.combine(useGlobalMacroHedgeWeekly)
        hasher.combine(maxMacroBoostWeekly)
        hasher.combine(useGlobalMacroHedgeMonthly)
        hasher.combine(maxMacroBoostMonthly)

        hasher.combine(useStablecoinShiftWeekly)
        hasher.combine(maxStablecoinBoostWeekly)
        hasher.combine(useStablecoinShiftMonthly)
        hasher.combine(maxStablecoinBoostMonthly)

        hasher.combine(useDemographicAdoptionWeekly)
        hasher.combine(maxDemoBoostWeekly)
        hasher.combine(useDemographicAdoptionMonthly)
        hasher.combine(maxDemoBoostMonthly)

        hasher.combine(useAltcoinFlightWeekly)
        hasher.combine(maxAltcoinBoostWeekly)
        hasher.combine(useAltcoinFlightMonthly)
        hasher.combine(maxAltcoinBoostMonthly)

        hasher.combine(useAdoptionFactorWeekly)
        hasher.combine(adoptionBaseFactorWeekly)
        hasher.combine(useAdoptionFactorMonthly)
        hasher.combine(adoptionBaseFactorMonthly)

        hasher.combine(useRegClampdownWeekly)
        hasher.combine(maxClampDownWeekly)
        hasher.combine(useRegClampdownMonthly)
        hasher.combine(maxClampDownMonthly)

        hasher.combine(useCompetitorCoinWeekly)
        hasher.combine(maxCompetitorBoostWeekly)
        hasher.combine(useCompetitorCoinMonthly)
        hasher.combine(maxCompetitorBoostMonthly)

        hasher.combine(useSecurityBreachWeekly)
        hasher.combine(breachImpactWeekly)
        hasher.combine(useSecurityBreachMonthly)
        hasher.combine(breachImpactMonthly)

        hasher.combine(useBubblePopWeekly)
        hasher.combine(maxPopDropWeekly)
        hasher.combine(useBubblePopMonthly)
        hasher.combine(maxPopDropMonthly)

        hasher.combine(useStablecoinMeltdownWeekly)
        hasher.combine(maxMeltdownDropWeekly)
        hasher.combine(useStablecoinMeltdownMonthly)
        hasher.combine(maxMeltdownDropMonthly)

        hasher.combine(useBlackSwanWeekly)
        hasher.combine(blackSwanDropWeekly)
        hasher.combine(useBlackSwanMonthly)
        hasher.combine(blackSwanDropMonthly)

        hasher.combine(useBearMarketWeekly)
        hasher.combine(bearWeeklyDriftWeekly)
        hasher.combine(useBearMarketMonthly)
        hasher.combine(bearWeeklyDriftMonthly)

        hasher.combine(useMaturingMarketWeekly)
        hasher.combine(maxMaturingDropWeekly)
        hasher.combine(useMaturingMarketMonthly)
        hasher.combine(maxMaturingDropMonthly)

        hasher.combine(useRecessionWeekly)
        hasher.combine(maxRecessionDropWeekly)
        hasher.combine(useRecessionMonthly)
        hasher.combine(maxRecessionDropMonthly)

        return UInt64(hasher.finalize())
    }

    // MARK: - Run Simulation
    func runSimulation(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double = 1.06
    ) {
        // 1) Compute new hash from toggles/settings
        let newHash = computeInputsHash(
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            iterations: iterations,
            exchangeRateEURUSD: exchangeRateEURUSD
        )
        
        // For demonstration, just print the hash comparison:
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = nil or unknown if you’re not storing it.")
        
        printAllSettings()
    }

    // MARK: - Restore Defaults
    func restoreDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks, forKey: "useVolShocks")

        // Remove factor keys
        defaults.removeObject(forKey: "useHalving")
        defaults.removeObject(forKey: "halvingBump")
        defaults.removeObject(forKey: "useInstitutionalDemand")
        defaults.removeObject(forKey: "maxDemandBoost")
        defaults.removeObject(forKey: "useCountryAdoption")
        defaults.removeObject(forKey: "maxCountryAdBoost")
        defaults.removeObject(forKey: "useRegulatoryClarity")
        defaults.removeObject(forKey: "maxClarityBoost")
        defaults.removeObject(forKey: "useEtfApproval")
        defaults.removeObject(forKey: "maxEtfBoost")
        defaults.removeObject(forKey: "useTechBreakthrough")
        defaults.removeObject(forKey: "maxTechBoost")
        defaults.removeObject(forKey: "useScarcityEvents")
        defaults.removeObject(forKey: "maxScarcityBoost")
        defaults.removeObject(forKey: "useGlobalMacroHedge")
        defaults.removeObject(forKey: "maxMacroBoost")
        defaults.removeObject(forKey: "useStablecoinShift")
        defaults.removeObject(forKey: "maxStablecoinBoost")
        defaults.removeObject(forKey: "useDemographicAdoption")
        defaults.removeObject(forKey: "maxDemoBoost")
        defaults.removeObject(forKey: "useAltcoinFlight")
        defaults.removeObject(forKey: "maxAltcoinBoost")
        defaults.removeObject(forKey: "useAdoptionFactor")
        defaults.removeObject(forKey: "adoptionBaseFactor")
        defaults.removeObject(forKey: "useRegClampdown")
        defaults.removeObject(forKey: "maxClampDown")
        defaults.removeObject(forKey: "useCompetitorCoin")
        defaults.removeObject(forKey: "maxCompetitorBoost")
        defaults.removeObject(forKey: "useSecurityBreach")
        defaults.removeObject(forKey: "breachImpact")
        defaults.removeObject(forKey: "useBubblePop")
        defaults.removeObject(forKey: "maxPopDrop")
        defaults.removeObject(forKey: "useStablecoinMeltdown")
        defaults.removeObject(forKey: "maxMeltdownDrop")
        defaults.removeObject(forKey: "useBlackSwan")
        defaults.removeObject(forKey: "blackSwanDrop")
        defaults.removeObject(forKey: "useBearMarket")
        defaults.removeObject(forKey: "bearWeeklyDrift")
        defaults.removeObject(forKey: "useMaturingMarket")
        defaults.removeObject(forKey: "maxMaturingDrop")
        defaults.removeObject(forKey: "useRecession")
        defaults.removeObject(forKey: "maxRecessionDrop")
        defaults.removeObject(forKey: "lockHistoricalSampling")

        // Remove your new toggles
        defaults.removeObject(forKey: "useHistoricalSampling")
        defaults.removeObject(forKey: "useVolShocks")

        // Remove new weekly/monthly keys
        defaults.removeObject(forKey: "useHalvingWeekly")
        defaults.removeObject(forKey: "halvingBumpWeekly")
        defaults.removeObject(forKey: "useHalvingMonthly")
        defaults.removeObject(forKey: "halvingBumpMonthly")

        defaults.removeObject(forKey: "useInstitutionalDemandWeekly")
        defaults.removeObject(forKey: "maxDemandBoostWeekly")
        defaults.removeObject(forKey: "useInstitutionalDemandMonthly")
        defaults.removeObject(forKey: "maxDemandBoostMonthly")

        defaults.removeObject(forKey: "useCountryAdoptionWeekly")
        defaults.removeObject(forKey: "maxCountryAdBoostWeekly")
        defaults.removeObject(forKey: "useCountryAdoptionMonthly")
        defaults.removeObject(forKey: "maxCountryAdBoostMonthly")

        defaults.removeObject(forKey: "useRegulatoryClarityWeekly")
        defaults.removeObject(forKey: "maxClarityBoostWeekly")
        defaults.removeObject(forKey: "useRegulatoryClarityMonthly")
        defaults.removeObject(forKey: "maxClarityBoostMonthly")

        defaults.removeObject(forKey: "useEtfApprovalWeekly")
        defaults.removeObject(forKey: "maxEtfBoostWeekly")
        defaults.removeObject(forKey: "useEtfApprovalMonthly")
        defaults.removeObject(forKey: "maxEtfBoostMonthly")

        defaults.removeObject(forKey: "useTechBreakthroughWeekly")
        defaults.removeObject(forKey: "maxTechBoostWeekly")
        defaults.removeObject(forKey: "useTechBreakthroughMonthly")
        defaults.removeObject(forKey: "maxTechBoostMonthly")

        defaults.removeObject(forKey: "useScarcityEventsWeekly")
        defaults.removeObject(forKey: "maxScarcityBoostWeekly")
        defaults.removeObject(forKey: "useScarcityEventsMonthly")
        defaults.removeObject(forKey: "maxScarcityBoostMonthly")

        defaults.removeObject(forKey: "useGlobalMacroHedgeWeekly")
        defaults.removeObject(forKey: "maxMacroBoostWeekly")
        defaults.removeObject(forKey: "useGlobalMacroHedgeMonthly")
        defaults.removeObject(forKey: "maxMacroBoostMonthly")

        defaults.removeObject(forKey: "useStablecoinShiftWeekly")
        defaults.removeObject(forKey: "maxStablecoinBoostWeekly")
        defaults.removeObject(forKey: "useStablecoinShiftMonthly")
        defaults.removeObject(forKey: "maxStablecoinBoostMonthly")

        defaults.removeObject(forKey: "useDemographicAdoptionWeekly")
        defaults.removeObject(forKey: "maxDemoBoostWeekly")
        defaults.removeObject(forKey: "useDemographicAdoptionMonthly")
        defaults.removeObject(forKey: "maxDemoBoostMonthly")

        defaults.removeObject(forKey: "useAltcoinFlightWeekly")
        defaults.removeObject(forKey: "maxAltcoinBoostWeekly")
        defaults.removeObject(forKey: "useAltcoinFlightMonthly")
        defaults.removeObject(forKey: "maxAltcoinBoostMonthly")

        defaults.removeObject(forKey: "useAdoptionFactorWeekly")
        defaults.removeObject(forKey: "adoptionBaseFactorWeekly")
        defaults.removeObject(forKey: "useAdoptionFactorMonthly")
        defaults.removeObject(forKey: "adoptionBaseFactorMonthly")

        defaults.removeObject(forKey: "useRegClampdownWeekly")
        defaults.removeObject(forKey: "maxClampDownWeekly")
        defaults.removeObject(forKey: "useRegClampdownMonthly")
        defaults.removeObject(forKey: "maxClampDownMonthly")

        defaults.removeObject(forKey: "useCompetitorCoinWeekly")
        defaults.removeObject(forKey: "maxCompetitorBoostWeekly")
        defaults.removeObject(forKey: "useCompetitorCoinMonthly")
        defaults.removeObject(forKey: "maxCompetitorBoostMonthly")

        defaults.removeObject(forKey: "useSecurityBreachWeekly")
        defaults.removeObject(forKey: "breachImpactWeekly")
        defaults.removeObject(forKey: "useSecurityBreachMonthly")
        defaults.removeObject(forKey: "breachImpactMonthly")

        defaults.removeObject(forKey: "useBubblePopWeekly")
        defaults.removeObject(forKey: "maxPopDropWeekly")
        defaults.removeObject(forKey: "useBubblePopMonthly")
        defaults.removeObject(forKey: "maxPopDropMonthly")

        defaults.removeObject(forKey: "useStablecoinMeltdownWeekly")
        defaults.removeObject(forKey: "maxMeltdownDropWeekly")
        defaults.removeObject(forKey: "useStablecoinMeltdownMonthly")
        defaults.removeObject(forKey: "maxMeltdownDropMonthly")

        defaults.removeObject(forKey: "useBlackSwanWeekly")
        defaults.removeObject(forKey: "blackSwanDropWeekly")
        defaults.removeObject(forKey: "useBlackSwanMonthly")
        defaults.removeObject(forKey: "blackSwanDropMonthly")

        defaults.removeObject(forKey: "useBearMarketWeekly")
        defaults.removeObject(forKey: "bearWeeklyDriftWeekly")
        defaults.removeObject(forKey: "useBearMarketMonthly")
        defaults.removeObject(forKey: "bearWeeklyDriftMonthly")

        defaults.removeObject(forKey: "useMaturingMarketWeekly")
        defaults.removeObject(forKey: "maxMaturingDropWeekly")
        defaults.removeObject(forKey: "useMaturingMarketMonthly")
        defaults.removeObject(forKey: "maxMaturingDropMonthly")

        defaults.removeObject(forKey: "useRecessionWeekly")
        defaults.removeObject(forKey: "maxRecessionDropWeekly")
        defaults.removeObject(forKey: "useRecessionMonthly")
        defaults.removeObject(forKey: "maxRecessionDropMonthly")

        // Also remove or reset the toggle
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true
    
        // Reassign them to the NEW defaults:
        useHistoricalSampling = true
        useVolShocks = true
    
        // Reassign them to the NEW defaults:
        useHalving = true
                
        useHalvingWeekly = true
        halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly

        useHalvingMonthly = true
        halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly

        useInstitutionalDemand = true
            
        // Weekly
        useInstitutionalDemandWeekly = true
        maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        
        // Monthly
        useInstitutionalDemandMonthly = true
        maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly

        useCountryAdoption = true
            
        useCountryAdoptionWeekly = true
        maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        
        useCountryAdoptionMonthly = true
        maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly

        useRegulatoryClarity = true
        maxClarityBoost = 0.0016644023749474966
        useRegulatoryClarityWeekly = true
        maxClarityBoostWeekly = 0.0016644023749474966
        useRegulatoryClarityMonthly = true
        maxClarityBoostMonthly = 0.0016644023749474966

        useEtfApproval = true
        maxEtfBoost = 0.0004546850204467774
        useEtfApprovalWeekly = true
        maxEtfBoostWeekly = 0.0004546850204467774
        useEtfApprovalMonthly = true
        maxEtfBoostMonthly = 0.0004546850204467774

        useTechBreakthrough = true
        maxTechBoost = 0.00040663959745637255
        useTechBreakthroughWeekly = true
        maxTechBoostWeekly = 0.00040663959745637255
        useTechBreakthroughMonthly = true
        maxTechBoostMonthly = 0.00040663959745637255

        useScarcityEvents = true
        maxScarcityBoost = 0.0007968083934443039
        useScarcityEventsWeekly = true
        maxScarcityBoostWeekly = 0.0007968083934443039
        useScarcityEventsMonthly = true
        maxScarcityBoostMonthly = 0.0007968083934443039

        useGlobalMacroHedge = true
        maxMacroBoost = 0.000419354572892189
        useGlobalMacroHedgeWeekly = true
        maxMacroBoostWeekly = 0.000419354572892189
        useGlobalMacroHedgeMonthly = true
        maxMacroBoostMonthly = 0.000419354572892189

        useStablecoinShift = true
        maxStablecoinBoost = 0.0004049262363101775
        useStablecoinShiftWeekly = true
        maxStablecoinBoostWeekly = 0.0004049262363101775
        useStablecoinShiftMonthly = true
        maxStablecoinBoostMonthly = 0.0004049262363101775

        useDemographicAdoption = true
        maxDemoBoost = 0.0013056834936141968
        useDemographicAdoptionWeekly = true
        maxDemoBoostWeekly = 0.0013056834936141968
        useDemographicAdoptionMonthly = true
        maxDemoBoostMonthly = 0.0013056834936141968

        useAltcoinFlight = true
        maxAltcoinBoost = 0.0002802194461803342
        useAltcoinFlightWeekly = true
        maxAltcoinBoostWeekly = 0.0002802194461803342
        useAltcoinFlightMonthly = true
        maxAltcoinBoostMonthly = 0.0002802194461803342

        useAdoptionFactor = true
        adoptionBaseFactor = 0.0009685099124908447
        useAdoptionFactorWeekly = true
        adoptionBaseFactorWeekly = 0.0009685099124908447
        useAdoptionFactorMonthly = true
        adoptionBaseFactorMonthly = 0.0009685099124908447

        useRegClampdown = true
        maxClampDown = -0.0011883256912231445
        useRegClampdownWeekly = true
        maxClampDownWeekly = -0.0011883256912231445
        useRegClampdownMonthly = true
        maxClampDownMonthly = -0.0011883256912231445

        useCompetitorCoin = true
        maxCompetitorBoost = -0.0011259913444519043
        useCompetitorCoinWeekly = true
        maxCompetitorBoostWeekly = -0.0011259913444519043
        useCompetitorCoinMonthly = true
        maxCompetitorBoostMonthly = -0.0011259913444519043

        useSecurityBreach = true
        breachImpact = -0.0007612827334384092
        useSecurityBreachWeekly = true
        breachImpactWeekly = -0.0007612827334384092
        useSecurityBreachMonthly = true
        breachImpactMonthly = -0.0007612827334384092

        useBubblePop = true
        maxPopDrop = -0.0012555068731307985
        useBubblePopWeekly = true
        maxPopDropWeekly = -0.0012555068731307985
        useBubblePopMonthly = true
        maxPopDropMonthly = -0.0012555068731307985

        useStablecoinMeltdown = true
        maxMeltdownDrop = -0.0007028046205417837
        useStablecoinMeltdownWeekly = true
        maxMeltdownDropWeekly = -0.0007028046205417837
        useStablecoinMeltdownMonthly = true
        maxMeltdownDropMonthly = -0.0007028046205417837

        useBlackSwan = true
        blackSwanDrop = -0.0018411452783672483
        useBlackSwanWeekly = true
        blackSwanDropWeekly = -0.0018411452783672483
        useBlackSwanMonthly = true
        blackSwanDropMonthly = -0.0018411452783672483

        useBearMarket = true
        bearWeeklyDrift = -0.0007195305824279769
        useBearMarketWeekly = true
        bearWeeklyDriftWeekly = -0.0007195305824279769
        useBearMarketMonthly = true
        bearWeeklyDriftMonthly = -0.0007195305824279769

        useMaturingMarket = true
        maxMaturingDrop = -0.004
        useMaturingMarketWeekly = true
        maxMaturingDropWeekly = -0.004
        useMaturingMarketMonthly = true
        maxMaturingDropMonthly = -0.004

        useRecession = true
        maxRecessionDrop = -0.0014508080482482913
        useRecessionWeekly = true
        maxRecessionDropWeekly = -0.0014508080482482913
        useRecessionMonthly = true
        maxRecessionDropMonthly = -0.0014508080482482913

        // Enable everything
        toggleAll = true

        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
    }
}
