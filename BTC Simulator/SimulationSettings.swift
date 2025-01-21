//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {
    /// This flag will be `true` only when the user flips the "toggle all" switch in the UI.
    /// It will be `false` if code flips `toggleAll`.
    var userIsActuallyTogglingAll = false
    
    // MARK: - Hardcoded Default Constants for Weekly vs. Monthly Factors

    // -----------------------------
    // BULLISH FACTORS
    // -----------------------------

    // Halving
    private static let defaultHalvingBumpWeekly   = 0.35   // was 0.2
    private static let defaultHalvingBumpMonthly  = 0.35   // was 0.35

    // Institutional Demand
    private static let defaultMaxDemandBoostWeekly   = 0.001239      // was 0.0012392541338671777
    private static let defaultMaxDemandBoostMonthly  = 0.0056589855  // was 0.008 (unchanged)

    // Country Adoption
    private static let defaultMaxCountryAdBoostWeekly   = 0.0009953915979713202  // was 0.00047095964199831683
    private static let defaultMaxCountryAdBoostMonthly  = 0.005515515952320099    // was 0.0031705064

    // Regulatory Clarity
    private static let defaultMaxClarityBoostWeekly   = 0.000793849712267518  // was 0.0016644023749474966 (monthly)
    private static let defaultMaxClarityBoostMonthly  = 0.0040737327          // was 0.008 (unchanged)

    // ETF Approval
    private static let defaultMaxEtfBoostWeekly   = 0.002         // was 0.00045468
    private static let defaultMaxEtfBoostMonthly  = 0.0057142851  // was 0.008 (unchanged)

    // Tech Breakthrough
    private static let defaultMaxTechBoostWeekly   = 0.00071162    // was 0.00040663959745637255
    private static let defaultMaxTechBoostMonthly  = 0.0028387091  // was 0.008 (unchanged)

    // Scarcity Events
    private static let defaultMaxScarcityBoostWeekly   = 0.00041308753681182863  // was 0.0007968083934443039
    private static let defaultMaxScarcityBoostMonthly  = 0.0032928705475521085   // was 0.0023778799

    // Global Macro Hedge
    private static let defaultMaxMacroBoostWeekly   = 0.00041935     // was 0.000419354572892189
    private static let defaultMaxMacroBoostMonthly  = 0.0032442397   // was 0.008 (unchanged)

    // Stablecoin Shift
    private static let defaultMaxStablecoinBoostWeekly   = 0.00040493     // was 0.0004049262363101775
    private static let defaultMaxStablecoinBoostMonthly  = 0.0023041475   // was 0.008 (unchanged)

    // Demographic Adoption
    private static let defaultMaxDemoBoostWeekly   = 0.00130568       // was 0.0013056834936141968
    private static let defaultMaxDemoBoostMonthly  = 0.007291124714649915  // was 0.0054746541

    // Altcoin Flight
    private static let defaultMaxAltcoinBoostWeekly   = 0.0002802194461803342  // unchanged
    private static let defaultMaxAltcoinBoostMonthly  = 0.0021566817           // was 0.008 (unchanged)

    // Adoption Factor
    private static let defaultAdoptionBaseFactorWeekly   = 0.0016045109088897705  // was 0.0009685099124908447
    private static let defaultAdoptionBaseFactorMonthly  = 0.014660959934071304   // was 0.009714285

    // -----------------------------
    // BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    private static let defaultMaxClampDownWeekly   = -0.0019412885584652421  // was -0.0011883256912231445 (monthly)
    private static let defaultMaxClampDownMonthly  = -0.02  // was -0.0011883256912231445

    // Competitor Coin
    private static let defaultMaxCompetitorBoostWeekly   = -0.001129314495845437  // was -0.0011259913444519043
    private static let defaultMaxCompetitorBoostMonthly  = -0.008  // was -0.0011259913444519043

    // Security Breach
    private static let defaultBreachImpactWeekly   = -0.0012699694280987979  // was -0.0007612827334384092 (monthly)
    private static let defaultBreachImpactMonthly  = -0.007  //was -0.0007612827334384092

    // Bubble Pop
    private static let defaultMaxPopDropWeekly   = -0.003214285969734192  // was -0.0012555068731307985
    private static let defaultMaxPopDropMonthly  = -0.01  // was -0.0012555068731307985

    // Stablecoin Meltdown
    private static let defaultMaxMeltdownDropWeekly   = -0.0016935482919216154  // was -0.0006013240111422539
    private static let defaultMaxMeltdownDropMonthly  = -0.01  // was -0.0007028046205417837 

    // Black Swan
    private static let defaultBlackSwanDropWeekly   = -0.7977726936340332  // was -0.3
    private static let defaultBlackSwanDropMonthly  = -0.4  // was -0.8

    // Bear Market
    private static let defaultBearWeeklyDriftWeekly   = -0.001  // was -0.0001
    private static let defaultBearWeeklyDriftMonthly  = -0.01  // was -0.0007195305824279769

    // Maturing Market
    private static let defaultMaxMaturingDropWeekly   = -0.00326881742477417  // was -0.004
    private static let defaultMaxMaturingDropMonthly  = -0.01  // was -0.004

    // Recession
    private static let defaultMaxRecessionDropWeekly   = -0.0010073162441545725  // was -0.0014508080482482913
    private static let defaultMaxRecessionDropMonthly  = -0.0014508080482482913
    
    init() {
        // No UserDefaults loading here; handled in SimulationSettingsInit.swift
        isUpdating = false
        isInitialized = false
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

            if !isUpdating {
                isUpdating = true

                // Decide which child toggles to pick based on a global mode (e.g. periodUnit)
                // Adjust if your actual code uses a different property to indicate weekly vs monthly.
                let usingWeeklyMode = (periodUnit == .weeks)

                if toggleAll {
                    // Turn ON all *parent* toggles
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

                    // Pick weekly or monthly children based on the global mode:
                    if usingWeeklyMode {
                        // Bullish children
                        useHalvingWeekly = true
                        useHalvingMonthly = false

                        useInstitutionalDemandWeekly = true
                        useInstitutionalDemandMonthly = false

                        useCountryAdoptionWeekly = true
                        useCountryAdoptionMonthly = false

                        useRegulatoryClarityWeekly = true
                        useRegulatoryClarityMonthly = false

                        useEtfApprovalWeekly = true
                        useEtfApprovalMonthly = false

                        useTechBreakthroughWeekly = true
                        useTechBreakthroughMonthly = false

                        useScarcityEventsWeekly = true
                        useScarcityEventsMonthly = false

                        useGlobalMacroHedgeWeekly = true
                        useGlobalMacroHedgeMonthly = false

                        useStablecoinShiftWeekly = true
                        useStablecoinShiftMonthly = false

                        useDemographicAdoptionWeekly = true
                        useDemographicAdoptionMonthly = false

                        useAltcoinFlightWeekly = true
                        useAltcoinFlightMonthly = false

                        useAdoptionFactorWeekly = true
                        useAdoptionFactorMonthly = false

                        // Bearish children
                        useRegClampdownWeekly = true
                        useRegClampdownMonthly = false

                        useCompetitorCoinWeekly = true
                        useCompetitorCoinMonthly = false

                        useSecurityBreachWeekly = true
                        useSecurityBreachMonthly = false

                        useBubblePopWeekly = true
                        useBubblePopMonthly = false

                        useStablecoinMeltdownWeekly = true
                        useStablecoinMeltdownMonthly = false

                        useBlackSwanWeekly = true
                        useBlackSwanMonthly = false

                        useBearMarketWeekly = true
                        useBearMarketMonthly = false

                        useMaturingMarketWeekly = true
                        useMaturingMarketMonthly = false

                        useRecessionWeekly = true
                        useRecessionMonthly = false
                    } else {
                        // Monthly mode
                        useHalvingWeekly = false
                        useHalvingMonthly = true

                        useInstitutionalDemandWeekly = false
                        useInstitutionalDemandMonthly = true

                        useCountryAdoptionWeekly = false
                        useCountryAdoptionMonthly = true

                        useRegulatoryClarityWeekly = false
                        useRegulatoryClarityMonthly = true

                        useEtfApprovalWeekly = false
                        useEtfApprovalMonthly = true

                        useTechBreakthroughWeekly = false
                        useTechBreakthroughMonthly = true

                        useScarcityEventsWeekly = false
                        useScarcityEventsMonthly = true

                        useGlobalMacroHedgeWeekly = false
                        useGlobalMacroHedgeMonthly = true

                        useStablecoinShiftWeekly = false
                        useStablecoinShiftMonthly = true

                        useDemographicAdoptionWeekly = false
                        useDemographicAdoptionMonthly = true

                        useAltcoinFlightWeekly = false
                        useAltcoinFlightMonthly = true

                        useAdoptionFactorWeekly = false
                        useAdoptionFactorMonthly = true

                        useRegClampdownWeekly = false
                        useRegClampdownMonthly = true

                        useCompetitorCoinWeekly = false
                        useCompetitorCoinMonthly = true

                        useSecurityBreachWeekly = false
                        useSecurityBreachMonthly = true

                        useBubblePopWeekly = false
                        useBubblePopMonthly = true

                        useStablecoinMeltdownWeekly = false
                        useStablecoinMeltdownMonthly = true

                        useBlackSwanWeekly = false
                        useBlackSwanMonthly = true

                        useBearMarketWeekly = false
                        useBearMarketMonthly = true

                        useMaturingMarketWeekly = false
                        useMaturingMarketMonthly = true

                        useRecessionWeekly = false
                        useRecessionMonthly = true
                    }

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

                    // Also turn OFF all child toggles so everything is definitely off:
                    useHalvingWeekly = false
                    useHalvingMonthly = false

                    useInstitutionalDemandWeekly = false
                    useInstitutionalDemandMonthly = false

                    useCountryAdoptionWeekly = false
                    useCountryAdoptionMonthly = false

                    useRegulatoryClarityWeekly = false
                    useRegulatoryClarityMonthly = false

                    useEtfApprovalWeekly = false
                    useEtfApprovalMonthly = false

                    useTechBreakthroughWeekly = false
                    useTechBreakthroughMonthly = false

                    useScarcityEventsWeekly = false
                    useScarcityEventsMonthly = false

                    useGlobalMacroHedgeWeekly = false
                    useGlobalMacroHedgeMonthly = false

                    useStablecoinShiftWeekly = false
                    useStablecoinShiftMonthly = false

                    useDemographicAdoptionWeekly = false
                    useDemographicAdoptionMonthly = false

                    useAltcoinFlightWeekly = false
                    useAltcoinFlightMonthly = false

                    useAdoptionFactorWeekly = false
                    useAdoptionFactorMonthly = false

                    useRegClampdownWeekly = false
                    useRegClampdownMonthly = false

                    useCompetitorCoinWeekly = false
                    useCompetitorCoinMonthly = false

                    useSecurityBreachWeekly = false
                    useSecurityBreachMonthly = false

                    useBubblePopWeekly = false
                    useBubblePopMonthly = false

                    useStablecoinMeltdownWeekly = false
                    useStablecoinMeltdownMonthly = false

                    useBlackSwanWeekly = false
                    useBlackSwanMonthly = false

                    useBearMarketWeekly = false
                    useBearMarketMonthly = false

                    useMaturingMarketWeekly = false
                    useMaturingMarketMonthly = false

                    useRecessionWeekly = false
                    useRecessionMonthly = false
                }

                // Done adjusting everything
                isUpdating = false

                // Sync the master toggle if needed
                syncToggleAllState()
            }
        }
    }

    func syncToggleAllState() {
        guard !isUpdating else { return }

        // Check if *all parent toggles* are true
        let allParentsOn =
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

        // If toggleAll is out of sync, fix it
        if toggleAll != allParentsOn {
            isUpdating = true
            toggleAll = allParentsOn
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

    /// Strength of autocorrelation (0 = none, 1 = full carryover of last return).
    @Published var autoCorrelationStrength: Double = 0.2 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
            }
        }
    }

    /// Mean reversion target, e.g. 0 for no drift, or you can pick a small positivity.
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

    // -----------------------------
    // Halving
    // -----------------------------
    @Published var useHalving: Bool = true {
        didSet {
            guard isInitialized, oldValue != useHalving else { return }
            UserDefaults.standard.set(useHalving, forKey: "useHalving")

            // NOTE: Removed the forced "default to weekly" logic here
            // Now toggling this on/off won't auto-choose weekly or monthly.

            syncToggleAllState()
        }
    }

    // Weekly child
    @Published var useHalvingWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingWeekly else { return }
            UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")

            // Removed the code that turned the parent on or forced the other child off

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

    // Monthly child
    @Published var useHalvingMonthly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingMonthly else { return }
            UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")

            // Removed the code that turned the parent on or forced the other child off

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

    // -----------------------------
    // Institutional Demand
    // -----------------------------
    @Published var useInstitutionalDemand: Bool = true {
        didSet {
            guard isInitialized, oldValue != useInstitutionalDemand else { return }
            UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
            
            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useInstitutionalDemandWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandWeekly else { return }
            UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
            
            // Removed parent + sibling forcing

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
            
            // Removed parent + sibling forcing

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

    // -----------------------------
    // Country Adoption
    // -----------------------------
    @Published var useCountryAdoption: Bool = true {
        didSet {
            guard isInitialized, oldValue != useCountryAdoption else { return }
            UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
            
            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useCountryAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionWeekly else { return }
            UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
            
            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Regulatory Clarity
    // -----------------------------
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRegulatoryClarity else { return }
            UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useRegulatoryClarityWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityWeekly else { return }
            UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")

            // Removed parent + sibling forcing

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
            
            // Removed parent + sibling forcing

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

    // -----------------------------
    // ETF Approval
    // -----------------------------
    @Published var useEtfApproval: Bool = true {
        didSet {
            guard isInitialized, oldValue != useEtfApproval else { return }
            UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useEtfApprovalWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalWeekly else { return }
            UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Tech Breakthrough
    // -----------------------------
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            guard isInitialized, oldValue != useTechBreakthrough else { return }
            UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useTechBreakthroughWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughWeekly else { return }
            UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Scarcity Events
    // -----------------------------
    @Published var useScarcityEvents: Bool = true {
        didSet {
            guard isInitialized, oldValue != useScarcityEvents else { return }
            UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useScarcityEventsWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsWeekly else { return }
            UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Global Macro Hedge
    // -----------------------------
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            guard isInitialized, oldValue != useGlobalMacroHedge else { return }
            UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useGlobalMacroHedgeWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeWeekly else { return }
            UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Stablecoin Shift
    // -----------------------------
    @Published var useStablecoinShift: Bool = true {
        didSet {
            guard isInitialized, oldValue != useStablecoinShift else { return }
            UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useStablecoinShiftWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftWeekly else { return }
            UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Demographic Adoption
    // -----------------------------
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            guard isInitialized, oldValue != useDemographicAdoption else { return }
            UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useDemographicAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionWeekly else { return }
            UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Altcoin Flight
    // -----------------------------
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            guard isInitialized, oldValue != useAltcoinFlight else { return }
            UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useAltcoinFlightWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightWeekly else { return }
            UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Adoption Factor
    // -----------------------------
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            guard isInitialized, oldValue != useAdoptionFactor else { return }
            UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")

            // Removed default-to-weekly logic

            syncToggleAllState()
        }
    }

    @Published var useAdoptionFactorWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorWeekly else { return }
            UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")

            // Removed parent + sibling forcing

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

            // Removed parent + sibling forcing

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

    // -----------------------------
    // Regulatory Clampdown
    // -----------------------------
    @Published var useRegClampdown: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRegClampdown else { return }
            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")

            // Removed the forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useRegClampdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownWeekly else { return }
            UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")

            // Removed the code that forced parent on or sibling off.

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

            // Removed the code that forced parent on or sibling off.

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

    // -----------------------------
    // Competitor Coin
    // -----------------------------
    @Published var useCompetitorCoin: Bool = true {
        didSet {
            guard isInitialized, oldValue != useCompetitorCoin else { return }
            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useCompetitorCoinWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinWeekly else { return }
            UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Security Breach
    // -----------------------------
    @Published var useSecurityBreach: Bool = true {
        didSet {
            guard isInitialized, oldValue != useSecurityBreach else { return }
            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useSecurityBreachWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachWeekly else { return }
            UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Bubble Pop
    // -----------------------------
    @Published var useBubblePop: Bool = true {
        didSet {
            guard isInitialized, oldValue != useBubblePop else { return }
            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useBubblePopWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopWeekly else { return }
            UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Stablecoin Meltdown
    // -----------------------------
    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            guard isInitialized, oldValue != useStablecoinMeltdown else { return }
            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useStablecoinMeltdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownWeekly else { return }
            UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Black Swan
    // -----------------------------
    @Published var useBlackSwan: Bool = false {
        didSet {
            guard isInitialized, oldValue != useBlackSwan else { return }
            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")

            // Removed forced "weekly on" logic.

            syncToggleAllState()
        }
    }

    @Published var useBlackSwanWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanWeekly else { return }
            UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Bear Market
    // -----------------------------
    @Published var useBearMarket: Bool = true {
        didSet {
            guard isInitialized, oldValue != useBearMarket else { return }
            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useBearMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketWeekly else { return }
            UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Maturing Market
    // -----------------------------
    @Published var useMaturingMarket: Bool = true {
        didSet {
            guard isInitialized, oldValue != useMaturingMarket else { return }
            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useMaturingMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketWeekly else { return }
            UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    // -----------------------------
    // Recession
    // -----------------------------
    @Published var useRecession: Bool = true {
        didSet {
            guard isInitialized, oldValue != useRecession else { return }
            UserDefaults.standard.set(useRecession, forKey: "useRecession")

            // Removed forced "weekly on, monthly off" logic.

            syncToggleAllState()
        }
    }

    @Published var useRecessionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionWeekly else { return }
            UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")

            // Removed parent & sibling forcing.

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

            // Removed parent & sibling forcing.

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

    /// MARK: - Restore Defaults
    func restoreDefaults() {
        print("RESTORE DEFAULTS CALLED!")
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

        // NEW: Remove GARCH toggle
        defaults.removeObject(forKey: "useGarchVolatility")

        // Remove the keys from UserDefaults
        defaults.removeObject(forKey: "useAutoCorrelation")
        defaults.removeObject(forKey: "autoCorrelationStrength")
        defaults.removeObject(forKey: "meanReversionTarget")

        // Now set them to your desired "reset" values
        useAutoCorrelation = false   // default "off"
        autoCorrelationStrength = 0.2
        meanReversionTarget = 0.0

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

        // NEW: Set GARCH default to true
        useGarchVolatility = true

        //
        // BULLISH FACTORS: set each parent's monthly = false by default
        //

        // Halving
        useHalving = true
        useHalvingWeekly = true
        halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly
        useHalvingMonthly = false
        halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly

        // Institutional Demand
        useInstitutionalDemand = true
        useInstitutionalDemandWeekly = true
        maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        useInstitutionalDemandMonthly = false
        maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly

        // Country Adoption
        useCountryAdoption = true
        useCountryAdoptionWeekly = true
        maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        useCountryAdoptionMonthly = false
        maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly

        // Regulatory Clarity
        useRegulatoryClarity = true
        useRegulatoryClarityWeekly = true
        maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        useRegulatoryClarityMonthly = false
        maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly

        // ETF Approval
        useEtfApproval = true
        useEtfApprovalWeekly = true
        maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly
        useEtfApprovalMonthly = false
        maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly

        // Tech Breakthrough
        useTechBreakthrough = true
        useTechBreakthroughWeekly = true
        maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly
        useTechBreakthroughMonthly = false
        maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly

        // Scarcity Events
        useScarcityEvents = true
        useScarcityEventsWeekly = true
        maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly
        useScarcityEventsMonthly = false
        maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly

        // Global Macro Hedge
        useGlobalMacroHedge = true
        useGlobalMacroHedgeWeekly = true
        maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly
        useGlobalMacroHedgeMonthly = false
        maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly

        // Stablecoin Shift
        useStablecoinShift = true
        useStablecoinShiftWeekly = true
        maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly
        useStablecoinShiftMonthly = false
        maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly

        // Demographic Adoption
        useDemographicAdoption = true
        useDemographicAdoptionWeekly = true
        maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly
        useDemographicAdoptionMonthly = false
        maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly

        // Altcoin Flight
        useAltcoinFlight = true
        useAltcoinFlightWeekly = true
        maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        useAltcoinFlightMonthly = false
        maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly

        // Adoption Factor
        useAdoptionFactor = true
        useAdoptionFactorWeekly = true
        adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        useAdoptionFactorMonthly = false
        adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly

        //
        // BEARISH FACTORS: left as is
        //

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

        // Finally, enable everything at once
        toggleAll = true

        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
    }
    
    private func finalizeToggleStateAfterLoad() {
        // Temporarily disable the chain-reaction logic
        isUpdating = true

        // BULLISH:
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

        // BEARISH:
        useRegClampdown = (useRegClampdownWeekly || useRegClampdownMonthly)
        useCompetitorCoin = (useCompetitorCoinWeekly || useCompetitorCoinMonthly)
        useSecurityBreach = (useSecurityBreachWeekly || useSecurityBreachMonthly)
        useBubblePop = (useBubblePopWeekly || useBubblePopMonthly)
        useStablecoinMeltdown = (useStablecoinMeltdownWeekly || useStablecoinMeltdownMonthly)
        useBlackSwan = (useBlackSwanWeekly || useBlackSwanMonthly)
        useBearMarket = (useBearMarketWeekly || useBearMarketMonthly)
        useMaturingMarket = (useMaturingMarketWeekly || useMaturingMarketMonthly)
        useRecession = (useRecessionWeekly || useRecessionMonthly)

        // Re-enable normal updates
        isUpdating = false

        // Finally, sync the master toggle
        syncToggleAllState()
    }
}
