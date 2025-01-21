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
                
            // If we’re not in a bulk update:
            if !isUpdating {
                isUpdating = true

                if toggleAll {
                    // Turn ON all parent toggles
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
                    // Turn OFF all parent toggles
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

                // End the bulk update
                isUpdating = false

                // Optionally do one final sync
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
            guard isInitialized else { return }
            guard oldValue != useHalving else { return }

            UserDefaults.standard.set(useHalving, forKey: "useHalving")

            // If parent is ON => pick weekly by default
            isUpdating = true
            if useHalving {
                useHalvingWeekly = true
                useHalvingMonthly = false
            } else {
                // Parent OFF => both children OFF
                useHalvingWeekly = false
                useHalvingMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    // Weekly child
    @Published var useHalvingWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useHalvingWeekly else { return }

            UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
            isUpdating = true

            if useHalvingWeekly {
                // Turn parent on, turn monthly off
                useHalving = true
                useHalvingMonthly = false
            } else {
                // If weekly is off and monthly is off => parent off
                if !useHalvingMonthly {
                    useHalving = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useHalvingMonthly {
                // Turn parent on, turn weekly off
                useHalving = true
                useHalvingWeekly = false
            } else {
                // If monthly is off and weekly is off => parent off
                if !useHalvingWeekly {
                    useHalving = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useInstitutionalDemand else { return }

            UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")

            isUpdating = true
            if useInstitutionalDemand {
                // Default to weekly on, monthly off
                useInstitutionalDemandWeekly = true
                useInstitutionalDemandMonthly = false
            } else {
                // Off => both children off
                useInstitutionalDemandWeekly = false
                useInstitutionalDemandMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useInstitutionalDemandWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useInstitutionalDemandWeekly else { return }

            UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
            isUpdating = true

            if useInstitutionalDemandWeekly {
                useInstitutionalDemand = true
                useInstitutionalDemandMonthly = false
            } else {
                if !useInstitutionalDemandMonthly {
                    useInstitutionalDemand = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useInstitutionalDemandMonthly {
                useInstitutionalDemand = true
                useInstitutionalDemandWeekly = false
            } else {
                if !useInstitutionalDemandWeekly {
                    useInstitutionalDemand = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useCountryAdoption else { return }

            UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")

            isUpdating = true
            if useCountryAdoption {
                useCountryAdoptionWeekly = true
                useCountryAdoptionMonthly = false
            } else {
                useCountryAdoptionWeekly = false
                useCountryAdoptionMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useCountryAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCountryAdoptionWeekly else { return }

            UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
            isUpdating = true

            if useCountryAdoptionWeekly {
                useCountryAdoption = true
                useCountryAdoptionMonthly = false
            } else {
                if !useCountryAdoptionMonthly {
                    useCountryAdoption = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useCountryAdoptionMonthly {
                useCountryAdoption = true
                useCountryAdoptionWeekly = false
            } else {
                if !useCountryAdoptionWeekly {
                    useCountryAdoption = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useRegulatoryClarity else { return }

            UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")

            isUpdating = true
            if useRegulatoryClarity {
                useRegulatoryClarityWeekly = true
                useRegulatoryClarityMonthly = false
            } else {
                useRegulatoryClarityWeekly = false
                useRegulatoryClarityMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useRegulatoryClarityWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegulatoryClarityWeekly else { return }

            UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
            isUpdating = true

            if useRegulatoryClarityWeekly {
                useRegulatoryClarity = true
                useRegulatoryClarityMonthly = false
            } else {
                if !useRegulatoryClarityMonthly {
                    useRegulatoryClarity = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useRegulatoryClarityMonthly {
                useRegulatoryClarity = true
                useRegulatoryClarityWeekly = false
            } else {
                if !useRegulatoryClarityWeekly {
                    useRegulatoryClarity = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useEtfApproval else { return }

            UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")

            isUpdating = true
            if useEtfApproval {
                useEtfApprovalWeekly = true
                useEtfApprovalMonthly = false
            } else {
                useEtfApprovalWeekly = false
                useEtfApprovalMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useEtfApprovalWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useEtfApprovalWeekly else { return }

            UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
            isUpdating = true

            if useEtfApprovalWeekly {
                useEtfApproval = true
                useEtfApprovalMonthly = false
            } else {
                if !useEtfApprovalMonthly {
                    useEtfApproval = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useEtfApprovalMonthly {
                useEtfApproval = true
                useEtfApprovalWeekly = false
            } else {
                if !useEtfApprovalWeekly {
                    useEtfApproval = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useTechBreakthrough else { return }

            UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")

            isUpdating = true
            if useTechBreakthrough {
                useTechBreakthroughWeekly = true
                useTechBreakthroughMonthly = false
            } else {
                useTechBreakthroughWeekly = false
                useTechBreakthroughMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useTechBreakthroughWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useTechBreakthroughWeekly else { return }

            UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
            isUpdating = true

            if useTechBreakthroughWeekly {
                useTechBreakthrough = true
                useTechBreakthroughMonthly = false
            } else {
                if !useTechBreakthroughMonthly {
                    useTechBreakthrough = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useTechBreakthroughMonthly {
                useTechBreakthrough = true
                useTechBreakthroughWeekly = false
            } else {
                if !useTechBreakthroughWeekly {
                    useTechBreakthrough = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useScarcityEvents else { return }

            UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")

            isUpdating = true
            if useScarcityEvents {
                useScarcityEventsWeekly = true
                useScarcityEventsMonthly = false
            } else {
                useScarcityEventsWeekly = false
                useScarcityEventsMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useScarcityEventsWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useScarcityEventsWeekly else { return }

            UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
            isUpdating = true

            if useScarcityEventsWeekly {
                useScarcityEvents = true
                useScarcityEventsMonthly = false
            } else {
                if !useScarcityEventsMonthly {
                    useScarcityEvents = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useScarcityEventsMonthly {
                useScarcityEvents = true
                useScarcityEventsWeekly = false
            } else {
                if !useScarcityEventsWeekly {
                    useScarcityEvents = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useGlobalMacroHedge else { return }

            UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")

            isUpdating = true
            if useGlobalMacroHedge {
                useGlobalMacroHedgeWeekly = true
                useGlobalMacroHedgeMonthly = false
            } else {
                useGlobalMacroHedgeWeekly = false
                useGlobalMacroHedgeMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useGlobalMacroHedgeWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useGlobalMacroHedgeWeekly else { return }

            UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
            isUpdating = true

            if useGlobalMacroHedgeWeekly {
                useGlobalMacroHedge = true
                useGlobalMacroHedgeMonthly = false
            } else {
                if !useGlobalMacroHedgeMonthly {
                    useGlobalMacroHedge = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useGlobalMacroHedgeMonthly {
                useGlobalMacroHedge = true
                useGlobalMacroHedgeWeekly = false
            } else {
                if !useGlobalMacroHedgeWeekly {
                    useGlobalMacroHedge = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useStablecoinShift else { return }

            UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")

            isUpdating = true
            if useStablecoinShift {
                useStablecoinShiftWeekly = true
                useStablecoinShiftMonthly = false
            } else {
                useStablecoinShiftWeekly = false
                useStablecoinShiftMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useStablecoinShiftWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinShiftWeekly else { return }

            UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
            isUpdating = true

            if useStablecoinShiftWeekly {
                useStablecoinShift = true
                useStablecoinShiftMonthly = false
            } else {
                if !useStablecoinShiftMonthly {
                    useStablecoinShift = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useStablecoinShiftMonthly {
                useStablecoinShift = true
                useStablecoinShiftWeekly = false
            } else {
                if !useStablecoinShiftWeekly {
                    useStablecoinShift = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useDemographicAdoption else { return }

            UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")

            isUpdating = true
            if useDemographicAdoption {
                useDemographicAdoptionWeekly = true
                useDemographicAdoptionMonthly = false
            } else {
                useDemographicAdoptionWeekly = false
                useDemographicAdoptionMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useDemographicAdoptionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useDemographicAdoptionWeekly else { return }

            UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
            isUpdating = true

            if useDemographicAdoptionWeekly {
                useDemographicAdoption = true
                useDemographicAdoptionMonthly = false
            } else {
                if !useDemographicAdoptionMonthly {
                    useDemographicAdoption = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useDemographicAdoptionMonthly {
                useDemographicAdoption = true
                useDemographicAdoptionWeekly = false
            } else {
                if !useDemographicAdoptionWeekly {
                    useDemographicAdoption = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useAltcoinFlight else { return }

            UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")

            isUpdating = true
            if useAltcoinFlight {
                useAltcoinFlightWeekly = true
                useAltcoinFlightMonthly = false
            } else {
                useAltcoinFlightWeekly = false
                useAltcoinFlightMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useAltcoinFlightWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAltcoinFlightWeekly else { return }

            UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
            isUpdating = true

            if useAltcoinFlightWeekly {
                useAltcoinFlight = true
                useAltcoinFlightMonthly = false
            } else {
                if !useAltcoinFlightMonthly {
                    useAltcoinFlight = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useAltcoinFlightMonthly {
                useAltcoinFlight = true
                useAltcoinFlightWeekly = false
            } else {
                if !useAltcoinFlightWeekly {
                    useAltcoinFlight = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useAdoptionFactor else { return }

            UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")

            isUpdating = true
            if useAdoptionFactor {
                useAdoptionFactorWeekly = true
                useAdoptionFactorMonthly = false
            } else {
                useAdoptionFactorWeekly = false
                useAdoptionFactorMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useAdoptionFactorWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useAdoptionFactorWeekly else { return }

            UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
            isUpdating = true

            if useAdoptionFactorWeekly {
                useAdoptionFactor = true
                useAdoptionFactorMonthly = false
            } else {
                if !useAdoptionFactorMonthly {
                    useAdoptionFactor = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useAdoptionFactorMonthly {
                useAdoptionFactor = true
                useAdoptionFactorWeekly = false
            } else {
                if !useAdoptionFactorWeekly {
                    useAdoptionFactor = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useRegClampdown else { return }

            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")

            isUpdating = true
            if useRegClampdown {
                // Parent on => weekly on, monthly off
                useRegClampdownWeekly = true
                useRegClampdownMonthly = false
            } else {
                // Parent off => both children off
                useRegClampdownWeekly = false
                useRegClampdownMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useRegClampdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRegClampdownWeekly else { return }

            UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
            isUpdating = true

            if useRegClampdownWeekly {
                // Child on => parent on, sibling off
                useRegClampdown = true
                useRegClampdownMonthly = false
            } else {
                // If both weekly & monthly are off => parent off
                if !useRegClampdownMonthly {
                    useRegClampdown = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useRegClampdownMonthly {
                useRegClampdown = true
                useRegClampdownWeekly = false
            } else {
                if !useRegClampdownWeekly {
                    useRegClampdown = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useCompetitorCoin else { return }

            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")

            isUpdating = true
            if useCompetitorCoin {
                useCompetitorCoinWeekly = true
                useCompetitorCoinMonthly = false
            } else {
                useCompetitorCoinWeekly = false
                useCompetitorCoinMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useCompetitorCoinWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useCompetitorCoinWeekly else { return }

            UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
            isUpdating = true

            if useCompetitorCoinWeekly {
                useCompetitorCoin = true
                useCompetitorCoinMonthly = false
            } else {
                if !useCompetitorCoinMonthly {
                    useCompetitorCoin = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useCompetitorCoinMonthly {
                useCompetitorCoin = true
                useCompetitorCoinWeekly = false
            } else {
                if !useCompetitorCoinWeekly {
                    useCompetitorCoin = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useSecurityBreach else { return }

            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")

            isUpdating = true
            if useSecurityBreach {
                useSecurityBreachWeekly = true
                useSecurityBreachMonthly = false
            } else {
                useSecurityBreachWeekly = false
                useSecurityBreachMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useSecurityBreachWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useSecurityBreachWeekly else { return }

            UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
            isUpdating = true

            if useSecurityBreachWeekly {
                useSecurityBreach = true
                useSecurityBreachMonthly = false
            } else {
                if !useSecurityBreachMonthly {
                    useSecurityBreach = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useSecurityBreachMonthly {
                useSecurityBreach = true
                useSecurityBreachWeekly = false
            } else {
                if !useSecurityBreachWeekly {
                    useSecurityBreach = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useBubblePop else { return }

            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")

            isUpdating = true
            if useBubblePop {
                useBubblePopWeekly = true
                useBubblePopMonthly = false
            } else {
                useBubblePopWeekly = false
                useBubblePopMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useBubblePopWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBubblePopWeekly else { return }

            UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
            isUpdating = true

            if useBubblePopWeekly {
                useBubblePop = true
                useBubblePopMonthly = false
            } else {
                if !useBubblePopMonthly {
                    useBubblePop = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useBubblePopMonthly {
                useBubblePop = true
                useBubblePopWeekly = false
            } else {
                if !useBubblePopWeekly {
                    useBubblePop = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useStablecoinMeltdown else { return }

            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")

            isUpdating = true
            if useStablecoinMeltdown {
                useStablecoinMeltdownWeekly = true
                useStablecoinMeltdownMonthly = false
            } else {
                useStablecoinMeltdownWeekly = false
                useStablecoinMeltdownMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useStablecoinMeltdownWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useStablecoinMeltdownWeekly else { return }

            UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
            isUpdating = true

            if useStablecoinMeltdownWeekly {
                useStablecoinMeltdown = true
                useStablecoinMeltdownMonthly = false
            } else {
                if !useStablecoinMeltdownMonthly {
                    useStablecoinMeltdown = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useStablecoinMeltdownMonthly {
                useStablecoinMeltdown = true
                useStablecoinMeltdownWeekly = false
            } else {
                if !useStablecoinMeltdownWeekly {
                    useStablecoinMeltdown = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useBlackSwan else { return }

            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")

            isUpdating = true
            if useBlackSwan {
                // Turn on weekly by default, monthly off
                useBlackSwanWeekly = true
                useBlackSwanMonthly = false
            } else {
                // Turn both children off
                useBlackSwanWeekly = false
                useBlackSwanMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useBlackSwanWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBlackSwanWeekly else { return }

            UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
            isUpdating = true

            if useBlackSwanWeekly {
                useBlackSwan = true
                useBlackSwanMonthly = false
            } else {
                if !useBlackSwanMonthly {
                    useBlackSwan = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useBlackSwanMonthly {
                useBlackSwan = true
                useBlackSwanWeekly = false
            } else {
                if !useBlackSwanWeekly {
                    useBlackSwan = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useBearMarket else { return }

            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")

            isUpdating = true
            if useBearMarket {
                useBearMarketWeekly = true
                useBearMarketMonthly = false
            } else {
                useBearMarketWeekly = false
                useBearMarketMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useBearMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useBearMarketWeekly else { return }

            UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
            isUpdating = true

            if useBearMarketWeekly {
                useBearMarket = true
                useBearMarketMonthly = false
            } else {
                if !useBearMarketMonthly {
                    useBearMarket = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useBearMarketMonthly {
                useBearMarket = true
                useBearMarketWeekly = false
            } else {
                if !useBearMarketWeekly {
                    useBearMarket = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useMaturingMarket else { return }

            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")

            isUpdating = true
            if useMaturingMarket {
                useMaturingMarketWeekly = true
                useMaturingMarketMonthly = false
            } else {
                useMaturingMarketWeekly = false
                useMaturingMarketMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useMaturingMarketWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useMaturingMarketWeekly else { return }

            UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
            isUpdating = true

            if useMaturingMarketWeekly {
                useMaturingMarket = true
                useMaturingMarketMonthly = false
            } else {
                if !useMaturingMarketMonthly {
                    useMaturingMarket = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useMaturingMarketMonthly {
                useMaturingMarket = true
                useMaturingMarketWeekly = false
            } else {
                if !useMaturingMarketWeekly {
                    useMaturingMarket = false
                }
            }
            isUpdating = false

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
            guard isInitialized else { return }
            guard oldValue != useRecession else { return }

            UserDefaults.standard.set(useRecession, forKey: "useRecession")

            isUpdating = true
            if useRecession {
                useRecessionWeekly = true
                useRecessionMonthly = false
            } else {
                useRecessionWeekly = false
                useRecessionMonthly = false
            }
            isUpdating = false

            syncToggleAllState()
        }
    }

    @Published var useRecessionWeekly: Bool = false {
        didSet {
            guard isInitialized, !isUpdating, oldValue != useRecessionWeekly else { return }

            UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
            isUpdating = true

            if useRecessionWeekly {
                useRecession = true
                useRecessionMonthly = false
            } else {
                if !useRecessionMonthly {
                    useRecession = false
                }
            }
            isUpdating = false

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
            isUpdating = true

            if useRecessionMonthly {
                useRecession = true
                useRecessionWeekly = false
            } else {
                if !useRecessionWeekly {
                    useRecession = false
                }
            }
            isUpdating = false

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
    
    /// After finishing our initial UserDefaults load (when `isUpdating` is false),
    /// call this to sync parent toggles based on their child weekly/monthly toggles.
    /// If either weekly or monthly is `true`, the parent becomes `true`; otherwise `false`.
    private func finalizeToggleStateAfterLoad() {
        // -----------------------------
        // BULLISH
        // -----------------------------
        // Halving
        useHalving = (useHalvingWeekly || useHalvingMonthly)
        // Institutional Demand
        useInstitutionalDemand = (useInstitutionalDemandWeekly || useInstitutionalDemandMonthly)
        // Country Adoption
        useCountryAdoption = (useCountryAdoptionWeekly || useCountryAdoptionMonthly)
        // Regulatory Clarity
        useRegulatoryClarity = (useRegulatoryClarityWeekly || useRegulatoryClarityMonthly)
        // ETF Approval
        useEtfApproval = (useEtfApprovalWeekly || useEtfApprovalMonthly)
        // Tech Breakthrough
        useTechBreakthrough = (useTechBreakthroughWeekly || useTechBreakthroughMonthly)
        // Scarcity Events
        useScarcityEvents = (useScarcityEventsWeekly || useScarcityEventsMonthly)
        // Global Macro Hedge
        useGlobalMacroHedge = (useGlobalMacroHedgeWeekly || useGlobalMacroHedgeMonthly)
        // Stablecoin Shift
        useStablecoinShift = (useStablecoinShiftWeekly || useStablecoinShiftMonthly)
        // Demographic Adoption
        useDemographicAdoption = (useDemographicAdoptionWeekly || useDemographicAdoptionMonthly)
        // Altcoin Flight
        useAltcoinFlight = (useAltcoinFlightWeekly || useAltcoinFlightMonthly)
        // Adoption Factor
        useAdoptionFactor = (useAdoptionFactorWeekly || useAdoptionFactorMonthly)
        
        // -----------------------------
        // BEARISH
        // -----------------------------
        // Regulatory Clampdown
        useRegClampdown = (useRegClampdownWeekly || useRegClampdownMonthly)
        // Competitor Coin
        useCompetitorCoin = (useCompetitorCoinWeekly || useCompetitorCoinMonthly)
        // Security Breach
        useSecurityBreach = (useSecurityBreachWeekly || useSecurityBreachMonthly)
        // Bubble Pop
        useBubblePop = (useBubblePopWeekly || useBubblePopMonthly)
        // Stablecoin Meltdown
        useStablecoinMeltdown = (useStablecoinMeltdownWeekly || useStablecoinMeltdownMonthly)
        // Black Swan
        useBlackSwan = (useBlackSwanWeekly || useBlackSwanMonthly)
        // Bear Market
        useBearMarket = (useBearMarketWeekly || useBearMarketMonthly)
        // Maturing Market
        useMaturingMarket = (useMaturingMarketWeekly || useMaturingMarketMonthly)
        // Recession
        useRecession = (useRecessionWeekly || useRecessionMonthly)
        
        // Finally, let’s sync the master toggle if needed
        syncToggleAllState()
    }
}
