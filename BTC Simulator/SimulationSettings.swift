//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {
    
    // MARK: - Hardcoded Default Constants for Weekly vs. Monthly Factors

    // -----------------------------
    // BULLISH FACTORS
    // -----------------------------

    // Halving
    private static let defaultHalvingBumpWeekly   = 0.48
    private static let defaultHalvingBumpMonthly  = 0.58

    // Institutional Demand
    private static let defaultMaxDemandBoostWeekly   = 0.0012392541338671777
    private static let defaultMaxDemandBoostMonthly  = 0.0012392541338671777

    // Country Adoption
    private static let defaultMaxCountryAdBoostWeekly   = 0.00047095964199831683
    private static let defaultMaxCountryAdBoostMonthly  = 0.00047095964199831683

    // Regulatory Clarity
    private static let defaultMaxClarityBoostWeekly   = 0.0016644023749474966
    private static let defaultMaxClarityBoostMonthly  = 0.0016644023749474966

    // ETF Approval
    private static let defaultMaxEtfBoostWeekly   = 0.0004546850204467774
    private static let defaultMaxEtfBoostMonthly  = 0.0004546850204467774

    // Tech Breakthrough
    private static let defaultMaxTechBoostWeekly   = 0.00040663959745637255
    private static let defaultMaxTechBoostMonthly  = 0.00040663959745637255

    // Scarcity Events
    private static let defaultMaxScarcityBoostWeekly   = 0.0007968083934443039
    private static let defaultMaxScarcityBoostMonthly  = 0.0007968083934443039

    // Global Macro Hedge
    private static let defaultMaxMacroBoostWeekly   = 0.000419354572892189
    private static let defaultMaxMacroBoostMonthly  = 0.000419354572892189

    // Stablecoin Shift
    private static let defaultMaxStablecoinBoostWeekly   = 0.0004049262363101775
    private static let defaultMaxStablecoinBoostMonthly  = 0.0004049262363101775

    // Demographic Adoption
    private static let defaultMaxDemoBoostWeekly   = 0.0013056834936141968
    private static let defaultMaxDemoBoostMonthly  = 0.0013056834936141968

    // Altcoin Flight
    private static let defaultMaxAltcoinBoostWeekly   = 0.0002802194461803342
    private static let defaultMaxAltcoinBoostMonthly  = 0.0002802194461803342

    // Adoption Factor
    private static let defaultAdoptionBaseFactorWeekly   = 0.0009685099124908447
    private static let defaultAdoptionBaseFactorMonthly  = 0.0009685099124908447


    // -----------------------------
    // BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    private static let defaultMaxClampDownWeekly   = -0.0011883256912231445
    private static let defaultMaxClampDownMonthly  = -0.0011883256912231445

    // Competitor Coin
    private static let defaultMaxCompetitorBoostWeekly   = -0.0011259913444519043
    private static let defaultMaxCompetitorBoostMonthly  = -0.0011259913444519043

    // Security Breach
    private static let defaultBreachImpactWeekly   = -0.0007612827334384092
    private static let defaultBreachImpactMonthly  = -0.0007612827334384092

    // Bubble Pop
    private static let defaultMaxPopDropWeekly   = -0.0012555068731307985
    private static let defaultMaxPopDropMonthly  = -0.0012555068731307985

    // Stablecoin Meltdown
    private static let defaultMaxMeltdownDropWeekly   = -0.0007028046205417837
    private static let defaultMaxMeltdownDropMonthly  = -0.0007028046205417837

    // Black Swan
    private static let defaultBlackSwanDropWeekly   = -0.0018411452783672483
    private static let defaultBlackSwanDropMonthly  = -0.0018411452783672483

    // Bear Market
    private static let defaultBearWeeklyDriftWeekly   = -0.0007195305824279769
    private static let defaultBearWeeklyDriftMonthly  = -0.0007195305824279769

    // Maturing Market
    private static let defaultMaxMaturingDropWeekly   = -0.004
    private static let defaultMaxMaturingDropMonthly  = -0.004

    // Recession
    private static let defaultMaxRecessionDropWeekly   = -0.0014508080482482913
    private static let defaultMaxRecessionDropMonthly  = -0.0014508080482482913
    
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
    var isUpdating = false

    @Published var toggleAll = false {
        didSet {
            // Only proceed if fully initialized
            guard isInitialized else { return }
            // Only proceed if it actually changed
            guard oldValue != toggleAll else { return }
            
            // If we’re not already in the middle of a bulk update:
            if !isUpdating {
                isUpdating = true

                if toggleAll {
                    // Turn ON all factors
                    useHalving = true
                    useHalvingWeekly = true
                    useHalvingMonthly = true

                    useInstitutionalDemand = true
                    useInstitutionalDemandWeekly = true
                    useInstitutionalDemandMonthly = true

                    useCountryAdoption = true
                    useCountryAdoptionWeekly = true
                    useCountryAdoptionMonthly = true

                    useRegulatoryClarity = true
                    useRegulatoryClarityWeekly = true
                    useRegulatoryClarityMonthly = true

                    useEtfApproval = true
                    useEtfApprovalWeekly = true
                    useEtfApprovalMonthly = true

                    useTechBreakthrough = true
                    useTechBreakthroughWeekly = true
                    useTechBreakthroughMonthly = true

                    useScarcityEvents = true
                    useScarcityEventsWeekly = true
                    useScarcityEventsMonthly = true

                    useGlobalMacroHedge = true
                    useGlobalMacroHedgeWeekly = true
                    useGlobalMacroHedgeMonthly = true

                    useStablecoinShift = true
                    useStablecoinShiftWeekly = true
                    useStablecoinShiftMonthly = true

                    useDemographicAdoption = true
                    useDemographicAdoptionWeekly = true
                    useDemographicAdoptionMonthly = true

                    useAltcoinFlight = true
                    useAltcoinFlightWeekly = true
                    useAltcoinFlightMonthly = true

                    useAdoptionFactor = true
                    useAdoptionFactorWeekly = true
                    useAdoptionFactorMonthly = true

                    useRegClampdown = true
                    useRegClampdownWeekly = true
                    useRegClampdownMonthly = true

                    useCompetitorCoin = true
                    useCompetitorCoinWeekly = true
                    useCompetitorCoinMonthly = true

                    useSecurityBreach = true
                    useSecurityBreachWeekly = true
                    useSecurityBreachMonthly = true

                    useBubblePop = true
                    useBubblePopWeekly = true
                    useBubblePopMonthly = true

                    useStablecoinMeltdown = true
                    useStablecoinMeltdownWeekly = true
                    useStablecoinMeltdownMonthly = true

                    useBlackSwan = true
                    useBlackSwanWeekly = true
                    useBlackSwanMonthly = true

                    useBearMarket = true
                    useBearMarketWeekly = true
                    useBearMarketMonthly = true

                    useMaturingMarket = true
                    useMaturingMarketWeekly = true
                    useMaturingMarketMonthly = true

                    useRecession = true
                    useRecessionWeekly = true
                    useRecessionMonthly = true

                } else {
                    // Turn OFF all factors
                    useHalving = false
                    useHalvingWeekly = false
                    useHalvingMonthly = false

                    useInstitutionalDemand = false
                    useInstitutionalDemandWeekly = false
                    useInstitutionalDemandMonthly = false

                    useCountryAdoption = false
                    useCountryAdoptionWeekly = false
                    useCountryAdoptionMonthly = false

                    useRegulatoryClarity = false
                    useRegulatoryClarityWeekly = false
                    useRegulatoryClarityMonthly = false

                    useEtfApproval = false
                    useEtfApprovalWeekly = false
                    useEtfApprovalMonthly = false

                    useTechBreakthrough = false
                    useTechBreakthroughWeekly = false
                    useTechBreakthroughMonthly = false

                    useScarcityEvents = false
                    useScarcityEventsWeekly = false
                    useScarcityEventsMonthly = false

                    useGlobalMacroHedge = false
                    useGlobalMacroHedgeWeekly = false
                    useGlobalMacroHedgeMonthly = false

                    useStablecoinShift = false
                    useStablecoinShiftWeekly = false
                    useStablecoinShiftMonthly = false

                    useDemographicAdoption = false
                    useDemographicAdoptionWeekly = false
                    useDemographicAdoptionMonthly = false

                    useAltcoinFlight = false
                    useAltcoinFlightWeekly = false
                    useAltcoinFlightMonthly = false

                    useAdoptionFactor = false
                    useAdoptionFactorWeekly = false
                    useAdoptionFactorMonthly = false

                    useRegClampdown = false
                    useRegClampdownWeekly = false
                    useRegClampdownMonthly = false

                    useCompetitorCoin = false
                    useCompetitorCoinWeekly = false
                    useCompetitorCoinMonthly = false

                    useSecurityBreach = false
                    useSecurityBreachWeekly = false
                    useSecurityBreachMonthly = false

                    useBubblePop = false
                    useBubblePopWeekly = false
                    useBubblePopMonthly = false

                    useStablecoinMeltdown = false
                    useStablecoinMeltdownWeekly = false
                    useStablecoinMeltdownMonthly = false

                    useBlackSwan = false
                    useBlackSwanWeekly = false
                    useBlackSwanMonthly = false

                    useBearMarket = false
                    useBearMarketWeekly = false
                    useBearMarketMonthly = false

                    useMaturingMarket = false
                    useMaturingMarketWeekly = false
                    useMaturingMarketMonthly = false

                    useRecession = false
                    useRecessionWeekly = false
                    useRecessionMonthly = false
                }
                
                // End the bulk update
                isUpdating = false
                
                // Optionally do one final sync now that everything is flipped
                syncToggleAllState()
            }
        }
    }

    func syncToggleAllState() {
        print(">> syncToggleAllState() called. isUpdating=\(isUpdating)")

        // If we're in the middle of changing multiple toggles at once, skip
        guard !isUpdating else {
            print(">> syncToggleAllState() skipped because isUpdating is true")
            return
        }

        // Check if ALL factors (including weekly/monthly variants) are on
        let allFactorsEnabled =
            (useHalving && useHalvingWeekly && useHalvingMonthly) &&
            (useInstitutionalDemand && useInstitutionalDemandWeekly && useInstitutionalDemandMonthly) &&
            (useCountryAdoption && useCountryAdoptionWeekly && useCountryAdoptionMonthly) &&
            (useRegulatoryClarity && useRegulatoryClarityWeekly && useRegulatoryClarityMonthly) &&
            (useEtfApproval && useEtfApprovalWeekly && useEtfApprovalMonthly) &&
            (useTechBreakthrough && useTechBreakthroughWeekly && useTechBreakthroughMonthly) &&
            (useScarcityEvents && useScarcityEventsWeekly && useScarcityEventsMonthly) &&
            (useGlobalMacroHedge && useGlobalMacroHedgeWeekly && useGlobalMacroHedgeMonthly) &&
            (useStablecoinShift && useStablecoinShiftWeekly && useStablecoinShiftMonthly) &&
            (useDemographicAdoption && useDemographicAdoptionWeekly && useDemographicAdoptionMonthly) &&
            (useAltcoinFlight && useAltcoinFlightWeekly && useAltcoinFlightMonthly) &&
            (useAdoptionFactor && useAdoptionFactorWeekly && useAdoptionFactorMonthly) &&
            (useRegClampdown && useRegClampdownWeekly && useRegClampdownMonthly) &&
            (useCompetitorCoin && useCompetitorCoinWeekly && useCompetitorCoinMonthly) &&
            (useSecurityBreach && useSecurityBreachWeekly && useSecurityBreachMonthly) &&
            (useBubblePop && useBubblePopWeekly && useBubblePopMonthly) &&
            (useStablecoinMeltdown && useStablecoinMeltdownWeekly && useStablecoinMeltdownMonthly) &&
            (useBlackSwan && useBlackSwanWeekly && useBlackSwanMonthly) &&
            (useBearMarket && useBearMarketWeekly && useBearMarketMonthly) &&
            (useMaturingMarket && useMaturingMarketWeekly && useMaturingMarketMonthly) &&
            (useRecession && useRecessionWeekly && useRecessionMonthly)

        print(">> syncToggleAllState() checking mismatch. allFactorsEnabled=\(allFactorsEnabled), toggleAll=\(toggleAll)")

        // If toggleAll is out of sync, fix it without triggering a full bulk flip
        if toggleAll != allFactorsEnabled {
            isUpdating = true
            toggleAll = allFactorsEnabled
            isUpdating = false
            print(">> syncToggleAllState() updated toggleAll => \(toggleAll)")
        } else {
            print(">> syncToggleAllState() no mismatch => nothing changed")
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

    // -----------------------------
    // MARK: - BULLISH FACTORS
    // -----------------------------

    // Halving
    @Published var useHalving: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useHalving {
                UserDefaults.standard.set(useHalving, forKey: "useHalving")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useHalvingWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useHalvingWeekly {
                UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
                // Now we call syncToggleAllState() so that if the weekly toggle goes off,
                // toggleAll can be set to false.
                syncToggleAllState()
            }
        }
    }
    @Published var halvingBumpWeekly: Double = SimulationSettings.defaultHalvingBumpWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpWeekly {
                UserDefaults.standard.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useHalvingMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useHalvingMonthly {
                UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useInstitutionalDemand {
                UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useInstitutionalDemandWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useInstitutionalDemandWeekly {
                UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxDemandBoostWeekly: Double = SimulationSettings.defaultMaxDemandBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostWeekly {
                UserDefaults.standard.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useInstitutionalDemandMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useInstitutionalDemandMonthly {
                UserDefaults.standard.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useCountryAdoption {
                UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useCountryAdoptionWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useCountryAdoptionWeekly {
                UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxCountryAdBoostWeekly: Double = SimulationSettings.defaultMaxCountryAdBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostWeekly {
                UserDefaults.standard.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useCountryAdoptionMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useCountryAdoptionMonthly {
                UserDefaults.standard.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useRegulatoryClarity {
                UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useRegulatoryClarityWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRegulatoryClarityWeekly {
                UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClarityBoostWeekly: Double = SimulationSettings.defaultMaxClarityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostWeekly {
                UserDefaults.standard.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useRegulatoryClarityMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRegulatoryClarityMonthly {
                UserDefaults.standard.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useEtfApproval {
                UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useEtfApprovalWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useEtfApprovalWeekly {
                UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxEtfBoostWeekly: Double = SimulationSettings.defaultMaxEtfBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostWeekly {
                UserDefaults.standard.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useEtfApprovalMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useEtfApprovalMonthly {
                UserDefaults.standard.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useTechBreakthrough {
                UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useTechBreakthroughWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useTechBreakthroughWeekly {
                UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxTechBoostWeekly: Double = SimulationSettings.defaultMaxTechBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostWeekly {
                UserDefaults.standard.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useTechBreakthroughMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useTechBreakthroughMonthly {
                UserDefaults.standard.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useScarcityEvents {
                UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useScarcityEventsWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useScarcityEventsWeekly {
                UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxScarcityBoostWeekly: Double = SimulationSettings.defaultMaxScarcityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostWeekly {
                UserDefaults.standard.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useScarcityEventsMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useScarcityEventsMonthly {
                UserDefaults.standard.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useGlobalMacroHedge {
                UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useGlobalMacroHedgeWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useGlobalMacroHedgeWeekly {
                UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMacroBoostWeekly: Double = SimulationSettings.defaultMaxMacroBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostWeekly {
                UserDefaults.standard.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useGlobalMacroHedgeMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useGlobalMacroHedgeMonthly {
                UserDefaults.standard.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useStablecoinShift {
                UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useStablecoinShiftWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useStablecoinShiftWeekly {
                UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxStablecoinBoostWeekly: Double = SimulationSettings.defaultMaxStablecoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostWeekly {
                UserDefaults.standard.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useStablecoinShiftMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useStablecoinShiftMonthly {
                UserDefaults.standard.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useDemographicAdoption {
                UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useDemographicAdoptionWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useDemographicAdoptionWeekly {
                UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxDemoBoostWeekly: Double = SimulationSettings.defaultMaxDemoBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostWeekly {
                UserDefaults.standard.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useDemographicAdoptionMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useDemographicAdoptionMonthly {
                UserDefaults.standard.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useAltcoinFlight {
                UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useAltcoinFlightWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAltcoinFlightWeekly {
                UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxAltcoinBoostWeekly: Double = SimulationSettings.defaultMaxAltcoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostWeekly {
                UserDefaults.standard.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useAltcoinFlightMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAltcoinFlightMonthly {
                UserDefaults.standard.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
                syncToggleAllState()
            }
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
            if isInitialized && !isUpdating && oldValue != useAdoptionFactor {
                UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useAdoptionFactorWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAdoptionFactorWeekly {
                UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var adoptionBaseFactorWeekly: Double = SimulationSettings.defaultAdoptionBaseFactorWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorWeekly {
                UserDefaults.standard.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useAdoptionFactorMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAdoptionFactorMonthly {
                UserDefaults.standard.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var adoptionBaseFactorMonthly: Double = SimulationSettings.defaultAdoptionBaseFactorMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorMonthly {
                UserDefaults.standard.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")
            }
        }
    }
    
    // -----------------------------
    // MARK: - BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    @Published var useRegClampdown: Bool = true {
        didSet {
            print(">> useRegClampdown changed from \(oldValue) to \(useRegClampdown). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useRegClampdown else { return }

            print(">> Storing useRegClampdown=\(useRegClampdown) in UserDefaults...")
            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")

            if !isUpdating {
                print(">> useRegClampdown calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useRegClampdownWeekly: Bool = true {
        didSet {
            print(">> useRegClampdownWeekly changed from \(oldValue) to \(useRegClampdownWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useRegClampdownWeekly {
                print(">> Storing useRegClampdownWeekly=\(useRegClampdownWeekly) in UserDefaults...")
                UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClampDownWeekly: Double = SimulationSettings.defaultMaxClampDownWeekly {
        didSet {
            print(">> maxClampDownWeekly changed from \(oldValue) to \(maxClampDownWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxClampDownWeekly {
                print(">> Storing maxClampDownWeekly=\(maxClampDownWeekly) in UserDefaults...")
                UserDefaults.standard.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useRegClampdownMonthly: Bool = true {
        didSet {
            print(">> useRegClampdownMonthly changed from \(oldValue) to \(useRegClampdownMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useRegClampdownMonthly {
                print(">> Storing useRegClampdownMonthly=\(useRegClampdownMonthly) in UserDefaults...")
                UserDefaults.standard.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClampDownMonthly: Double = SimulationSettings.defaultMaxClampDownMonthly {
        didSet {
            print(">> maxClampDownMonthly changed from \(oldValue) to \(maxClampDownMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxClampDownMonthly {
                print(">> Storing maxClampDownMonthly=\(maxClampDownMonthly) in UserDefaults...")
                UserDefaults.standard.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")
            }
        }
    }

    // Competitor Coin
    @Published var useCompetitorCoin: Bool = true {
        didSet {
            print(">> useCompetitorCoin changed from \(oldValue) to \(useCompetitorCoin). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useCompetitorCoin else { return }

            print(">> Storing useCompetitorCoin=\(useCompetitorCoin) in UserDefaults...")
            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")

            if !isUpdating {
                print(">> useCompetitorCoin calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useCompetitorCoinWeekly: Bool = true {
        didSet {
            print(">> useCompetitorCoinWeekly changed from \(oldValue) to \(useCompetitorCoinWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useCompetitorCoinWeekly {
                print(">> Storing useCompetitorCoinWeekly=\(useCompetitorCoinWeekly) in UserDefaults...")
                UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxCompetitorBoostWeekly: Double = SimulationSettings.defaultMaxCompetitorBoostWeekly {
        didSet {
            print(">> maxCompetitorBoostWeekly changed from \(oldValue) to \(maxCompetitorBoostWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostWeekly {
                print(">> Storing maxCompetitorBoostWeekly=\(maxCompetitorBoostWeekly) in UserDefaults...")
                UserDefaults.standard.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useCompetitorCoinMonthly: Bool = true {
        didSet {
            print(">> useCompetitorCoinMonthly changed from \(oldValue) to \(useCompetitorCoinMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useCompetitorCoinMonthly {
                print(">> Storing useCompetitorCoinMonthly=\(useCompetitorCoinMonthly) in UserDefaults...")
                UserDefaults.standard.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxCompetitorBoostMonthly: Double = SimulationSettings.defaultMaxCompetitorBoostMonthly {
        didSet {
            print(">> maxCompetitorBoostMonthly changed from \(oldValue) to \(maxCompetitorBoostMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostMonthly {
                print(">> Storing maxCompetitorBoostMonthly=\(maxCompetitorBoostMonthly) in UserDefaults...")
                UserDefaults.standard.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")
            }
        }
    }

    // Security Breach
    @Published var useSecurityBreach: Bool = true {
        didSet {
            print(">> useSecurityBreach changed from \(oldValue) to \(useSecurityBreach). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useSecurityBreach else { return }

            print(">> Storing useSecurityBreach=\(useSecurityBreach) in UserDefaults...")
            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")

            if !isUpdating {
                print(">> useSecurityBreach calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useSecurityBreachWeekly: Bool = true {
        didSet {
            print(">> useSecurityBreachWeekly changed from \(oldValue) to \(useSecurityBreachWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useSecurityBreachWeekly {
                print(">> Storing useSecurityBreachWeekly=\(useSecurityBreachWeekly) in UserDefaults...")
                UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var breachImpactWeekly: Double = SimulationSettings.defaultBreachImpactWeekly {
        didSet {
            print(">> breachImpactWeekly changed from \(oldValue) to \(breachImpactWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != breachImpactWeekly {
                print(">> Storing breachImpactWeekly=\(breachImpactWeekly) in UserDefaults...")
                UserDefaults.standard.set(breachImpactWeekly, forKey: "breachImpactWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useSecurityBreachMonthly: Bool = true {
        didSet {
            print(">> useSecurityBreachMonthly changed from \(oldValue) to \(useSecurityBreachMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useSecurityBreachMonthly {
                print(">> Storing useSecurityBreachMonthly=\(useSecurityBreachMonthly) in UserDefaults...")
                UserDefaults.standard.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var breachImpactMonthly: Double = SimulationSettings.defaultBreachImpactMonthly {
        didSet {
            print(">> breachImpactMonthly changed from \(oldValue) to \(breachImpactMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != breachImpactMonthly {
                print(">> Storing breachImpactMonthly=\(breachImpactMonthly) in UserDefaults...")
                UserDefaults.standard.set(breachImpactMonthly, forKey: "breachImpactMonthly")
            }
        }
    }

    // Bubble Pop
    @Published var useBubblePop: Bool = true {
        didSet {
            print(">> useBubblePop changed from \(oldValue) to \(useBubblePop). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useBubblePop else { return }

            print(">> Storing useBubblePop=\(useBubblePop) in UserDefaults...")
            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")

            if !isUpdating {
                print(">> useBubblePop calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useBubblePopWeekly: Bool = true {
        didSet {
            print(">> useBubblePopWeekly changed from \(oldValue) to \(useBubblePopWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useBubblePopWeekly {
                print(">> Storing useBubblePopWeekly=\(useBubblePopWeekly) in UserDefaults...")
                UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxPopDropWeekly: Double = SimulationSettings.defaultMaxPopDropWeekly {
        didSet {
            print(">> maxPopDropWeekly changed from \(oldValue) to \(maxPopDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxPopDropWeekly {
                print(">> Storing maxPopDropWeekly=\(maxPopDropWeekly) in UserDefaults...")
                UserDefaults.standard.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useBubblePopMonthly: Bool = true {
        didSet {
            print(">> useBubblePopMonthly changed from \(oldValue) to \(useBubblePopMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useBubblePopMonthly {
                print(">> Storing useBubblePopMonthly=\(useBubblePopMonthly) in UserDefaults...")
                UserDefaults.standard.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxPopDropMonthly: Double = SimulationSettings.defaultMaxPopDropMonthly {
        didSet {
            print(">> maxPopDropMonthly changed from \(oldValue) to \(maxPopDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxPopDropMonthly {
                print(">> Storing maxPopDropMonthly=\(maxPopDropMonthly) in UserDefaults...")
                UserDefaults.standard.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")
            }
        }
    }

    // Stablecoin Meltdown
    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            print(">> useStablecoinMeltdown changed from \(oldValue) to \(useStablecoinMeltdown). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useStablecoinMeltdown else { return }

            print(">> Storing useStablecoinMeltdown=\(useStablecoinMeltdown) in UserDefaults...")
            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")

            if !isUpdating {
                print(">> useStablecoinMeltdown calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useStablecoinMeltdownWeekly: Bool = true {
        didSet {
            print(">> useStablecoinMeltdownWeekly changed from \(oldValue) to \(useStablecoinMeltdownWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useStablecoinMeltdownWeekly {
                print(">> Storing useStablecoinMeltdownWeekly=\(useStablecoinMeltdownWeekly) in UserDefaults...")
                UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMeltdownDropWeekly: Double = SimulationSettings.defaultMaxMeltdownDropWeekly {
        didSet {
            print(">> maxMeltdownDropWeekly changed from \(oldValue) to \(maxMeltdownDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropWeekly {
                print(">> Storing maxMeltdownDropWeekly=\(maxMeltdownDropWeekly) in UserDefaults...")
                UserDefaults.standard.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useStablecoinMeltdownMonthly: Bool = true {
        didSet {
            print(">> useStablecoinMeltdownMonthly changed from \(oldValue) to \(useStablecoinMeltdownMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useStablecoinMeltdownMonthly {
                print(">> Storing useStablecoinMeltdownMonthly=\(useStablecoinMeltdownMonthly) in UserDefaults...")
                UserDefaults.standard.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMeltdownDropMonthly: Double = SimulationSettings.defaultMaxMeltdownDropMonthly {
        didSet {
            print(">> maxMeltdownDropMonthly changed from \(oldValue) to \(maxMeltdownDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropMonthly {
                print(">> Storing maxMeltdownDropMonthly=\(maxMeltdownDropMonthly) in UserDefaults...")
                UserDefaults.standard.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")
            }
        }
    }

    // Black Swan
    @Published var useBlackSwan: Bool = true {
        didSet {
            print(">> useBlackSwan changed from \(oldValue) to \(useBlackSwan). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useBlackSwan else { return }

            print(">> Storing useBlackSwan=\(useBlackSwan) in UserDefaults...")
            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")

            if !isUpdating {
                print(">> useBlackSwan calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useBlackSwanWeekly: Bool = true {
        didSet {
            print(">> useBlackSwanWeekly changed from \(oldValue) to \(useBlackSwanWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useBlackSwanWeekly {
                print(">> Storing useBlackSwanWeekly=\(useBlackSwanWeekly) in UserDefaults...")
                UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var blackSwanDropWeekly: Double = SimulationSettings.defaultBlackSwanDropWeekly {
        didSet {
            print(">> blackSwanDropWeekly changed from \(oldValue) to \(blackSwanDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != blackSwanDropWeekly {
                print(">> Storing blackSwanDropWeekly=\(blackSwanDropWeekly) in UserDefaults...")
                UserDefaults.standard.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useBlackSwanMonthly: Bool = true {
        didSet {
            print(">> useBlackSwanMonthly changed from \(oldValue) to \(useBlackSwanMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useBlackSwanMonthly {
                print(">> Storing useBlackSwanMonthly=\(useBlackSwanMonthly) in UserDefaults...")
                UserDefaults.standard.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var blackSwanDropMonthly: Double = SimulationSettings.defaultBlackSwanDropMonthly {
        didSet {
            print(">> blackSwanDropMonthly changed from \(oldValue) to \(blackSwanDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != blackSwanDropMonthly {
                print(">> Storing blackSwanDropMonthly=\(blackSwanDropMonthly) in UserDefaults...")
                UserDefaults.standard.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")
            }
        }
    }

    // Bear Market
    @Published var useBearMarket: Bool = true {
        didSet {
            print(">> useBearMarket changed from \(oldValue) to \(useBearMarket). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useBearMarket else { return }

            print(">> Storing useBearMarket=\(useBearMarket) in UserDefaults...")
            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")

            if !isUpdating {
                print(">> useBearMarket calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useBearMarketWeekly: Bool = true {
        didSet {
            print(">> useBearMarketWeekly changed from \(oldValue) to \(useBearMarketWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useBearMarketWeekly {
                print(">> Storing useBearMarketWeekly=\(useBearMarketWeekly) in UserDefaults...")
                UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var bearWeeklyDriftWeekly: Double = SimulationSettings.defaultBearWeeklyDriftWeekly {
        didSet {
            print(">> bearWeeklyDriftWeekly changed from \(oldValue) to \(bearWeeklyDriftWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftWeekly {
                print(">> Storing bearWeeklyDriftWeekly=\(bearWeeklyDriftWeekly) in UserDefaults...")
                UserDefaults.standard.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useBearMarketMonthly: Bool = true {
        didSet {
            print(">> useBearMarketMonthly changed from \(oldValue) to \(useBearMarketMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useBearMarketMonthly {
                print(">> Storing useBearMarketMonthly=\(useBearMarketMonthly) in UserDefaults...")
                UserDefaults.standard.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var bearWeeklyDriftMonthly: Double = SimulationSettings.defaultBearWeeklyDriftMonthly {
        didSet {
            print(">> bearWeeklyDriftMonthly changed from \(oldValue) to \(bearWeeklyDriftMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftMonthly {
                print(">> Storing bearWeeklyDriftMonthly=\(bearWeeklyDriftMonthly) in UserDefaults...")
                UserDefaults.standard.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")
            }
        }
    }

    // Maturing Market
    @Published var useMaturingMarket: Bool = true {
        didSet {
            print(">> useMaturingMarket changed from \(oldValue) to \(useMaturingMarket). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useMaturingMarket else { return }

            print(">> Storing useMaturingMarket=\(useMaturingMarket) in UserDefaults...")
            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")

            if !isUpdating {
                print(">> useMaturingMarket calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useMaturingMarketWeekly: Bool = true {
        didSet {
            print(">> useMaturingMarketWeekly changed from \(oldValue) to \(useMaturingMarketWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useMaturingMarketWeekly {
                print(">> Storing useMaturingMarketWeekly=\(useMaturingMarketWeekly) in UserDefaults...")
                UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMaturingDropWeekly: Double = SimulationSettings.defaultMaxMaturingDropWeekly {
        didSet {
            print(">> maxMaturingDropWeekly changed from \(oldValue) to \(maxMaturingDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxMaturingDropWeekly {
                print(">> Storing maxMaturingDropWeekly=\(maxMaturingDropWeekly) in UserDefaults...")
                UserDefaults.standard.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useMaturingMarketMonthly: Bool = true {
        didSet {
            print(">> useMaturingMarketMonthly changed from \(oldValue) to \(useMaturingMarketMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useMaturingMarketMonthly {
                print(">> Storing useMaturingMarketMonthly=\(useMaturingMarketMonthly) in UserDefaults...")
                UserDefaults.standard.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMaturingDropMonthly: Double = SimulationSettings.defaultMaxMaturingDropMonthly {
        didSet {
            print(">> maxMaturingDropMonthly changed from \(oldValue) to \(maxMaturingDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxMaturingDropMonthly {
                print(">> Storing maxMaturingDropMonthly=\(maxMaturingDropMonthly) in UserDefaults...")
                UserDefaults.standard.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")
            }
        }
    }

    // Recession
    @Published var useRecession: Bool = true {
        didSet {
            print(">> useRecession changed from \(oldValue) to \(useRecession). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            guard isInitialized else { return }
            guard oldValue != useRecession else { return }

            print(">> Storing useRecession=\(useRecession) in UserDefaults...")
            UserDefaults.standard.set(useRecession, forKey: "useRecession")

            if !isUpdating {
                print(">> useRecession calling syncToggleAllState()...")
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useRecessionWeekly: Bool = true {
        didSet {
            print(">> useRecessionWeekly changed from \(oldValue) to \(useRecessionWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useRecessionWeekly {
                print(">> Storing useRecessionWeekly=\(useRecessionWeekly) in UserDefaults...")
                UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxRecessionDropWeekly: Double = SimulationSettings.defaultMaxRecessionDropWeekly {
        didSet {
            print(">> maxRecessionDropWeekly changed from \(oldValue) to \(maxRecessionDropWeekly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxRecessionDropWeekly {
                print(">> Storing maxRecessionDropWeekly=\(maxRecessionDropWeekly) in UserDefaults...")
                UserDefaults.standard.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useRecessionMonthly: Bool = true {
        didSet {
            print(">> useRecessionMonthly changed from \(oldValue) to \(useRecessionMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != useRecessionMonthly {
                print(">> Storing useRecessionMonthly=\(useRecessionMonthly) in UserDefaults...")
                UserDefaults.standard.set(useRecessionMonthly, forKey: "useRecessionMonthly")
                syncToggleAllState()
            }
        }
    }
    @Published var maxRecessionDropMonthly: Double = SimulationSettings.defaultMaxRecessionDropMonthly {
        didSet {
            print(">> maxRecessionDropMonthly changed from \(oldValue) to \(maxRecessionDropMonthly). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            
            if isInitialized && !isUpdating && oldValue != maxRecessionDropMonthly {
                print(">> Storing maxRecessionDropMonthly=\(maxRecessionDropMonthly) in UserDefaults...")
                UserDefaults.standard.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")
            }
        }
    }
    
    private func setAllBearishFactors(to newValue: Bool) {
        // We do NOT call their didSet logic beyond saving to UserDefaults
        // We’ll just set them directly, so it won’t repeatedly override us.
        isUpdating = true
        
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
            
        useRegulatoryClarityWeekly = true
        maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        
        useRegulatoryClarityMonthly = true
        maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly

        useEtfApproval = true

        useEtfApprovalWeekly = true
        maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly

        useEtfApprovalMonthly = true
        maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly
    
        useTechBreakthrough = true

        useTechBreakthroughWeekly = true
        maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly

        useTechBreakthroughMonthly = true
        maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly

        useScarcityEvents = true

        useScarcityEventsWeekly = true
        maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly

        useScarcityEventsMonthly = true
        maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly

        useGlobalMacroHedge = true

        useGlobalMacroHedgeWeekly = true
        maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly

        useGlobalMacroHedgeMonthly = true
        maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly

        useStablecoinShift = true

        useStablecoinShiftWeekly = true
        maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly

        useStablecoinShiftMonthly = true
        maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly

        useDemographicAdoption = true

        useDemographicAdoptionWeekly = true
        maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly

        useDemographicAdoptionMonthly = true
        maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly
    
        useAltcoinFlight = true
            
        useAltcoinFlightWeekly = true
        maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        
        useAltcoinFlightMonthly = true
        maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly

        useAdoptionFactor = true
            
        useAdoptionFactorWeekly = true
        adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        
        useAdoptionFactorMonthly = true
        adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly

        useRegClampdown = true
            
        useRegClampdownWeekly = true
        maxClampDownWeekly = SimulationSettings.defaultMaxClampDownWeekly
        
        useRegClampdownMonthly = true
        maxClampDownMonthly = SimulationSettings.defaultMaxClampDownMonthly

        useCompetitorCoin = true
            
        useCompetitorCoinWeekly = true
        maxCompetitorBoostWeekly = SimulationSettings.defaultMaxCompetitorBoostWeekly
        
        useCompetitorCoinMonthly = true
        maxCompetitorBoostMonthly = SimulationSettings.defaultMaxCompetitorBoostMonthly

        useSecurityBreach = true
            
        useSecurityBreachWeekly = true
        breachImpactWeekly = SimulationSettings.defaultBreachImpactWeekly

        useSecurityBreachMonthly = true
        breachImpactMonthly = SimulationSettings.defaultBreachImpactMonthly

        useBubblePop = true
            
        useBubblePopWeekly = true
        maxPopDropWeekly = SimulationSettings.defaultMaxPopDropWeekly
        
        useBubblePopMonthly = true
        maxPopDropMonthly = SimulationSettings.defaultMaxPopDropMonthly

        useStablecoinMeltdown = true

        useStablecoinMeltdownWeekly = true
        maxMeltdownDropWeekly = SimulationSettings.defaultMaxMeltdownDropWeekly

        useStablecoinMeltdownMonthly = true
        maxMeltdownDropMonthly = SimulationSettings.defaultMaxMeltdownDropMonthly

        useBlackSwan = true
            
        useBlackSwanWeekly = true
        blackSwanDropWeekly = SimulationSettings.defaultBlackSwanDropWeekly

        useBlackSwanMonthly = true
        blackSwanDropMonthly = SimulationSettings.defaultBlackSwanDropMonthly

        useBearMarket = true

        useBearMarketWeekly = true
        bearWeeklyDriftWeekly = SimulationSettings.defaultBearWeeklyDriftWeekly

        useBearMarketMonthly = true
        bearWeeklyDriftMonthly = SimulationSettings.defaultBearWeeklyDriftMonthly

        useMaturingMarket = true

        useMaturingMarketWeekly = true
        maxMaturingDropWeekly = SimulationSettings.defaultMaxMaturingDropWeekly

        useMaturingMarketMonthly = true
        maxMaturingDropMonthly = SimulationSettings.defaultMaxMaturingDropMonthly

        useRecession = true

        useRecessionWeekly = true
        maxRecessionDropWeekly = SimulationSettings.defaultMaxRecessionDropWeekly

        useRecessionMonthly = true
        maxRecessionDropMonthly = SimulationSettings.defaultMaxRecessionDropMonthly

        // Enable everything
        toggleAll = true

        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
    }
}
