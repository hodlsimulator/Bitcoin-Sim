//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {
    
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
            print(">> useHalving changed to \(useHalving). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useHalving, forKey: "useHalving")
                syncToggleAllState()
            }
        }
    }

    @Published var halvingBump: Double = 0.47967220152334283 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(halvingBump, forKey: "halvingBump")
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
    @Published var maxDemandBoost: Double = 0.0012392541338671777 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemandBoost, forKey: "maxDemandBoost")
            }
        }
    }

    // Country Adoption
    @Published var useCountryAdoption: Bool = true {
        didSet {
            print(">> useCountryAdoption changed to \(useCountryAdoption). isInitialized=\(isInitialized)")
            if isInitialized {
                UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
                syncToggleAllState()
            }
        }
    }
    @Published var maxCountryAdBoost: Double = 0.00047095964199831683 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCountryAdBoost, forKey: "maxCountryAdBoost")
            }
        }
    }

    // Regulatory Clarity
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            print(">> useRegulatoryClarity changed to \(useRegulatoryClarity). isInitialized=\(isInitialized)")
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

    // ETF Approval
    @Published var useEtfApproval: Bool = true {
        didSet {
            print(">> useEtfApproval changed to \(useEtfApproval). isInitialized=\(isInitialized)")
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

    // Tech Breakthrough
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            print(">> useTechBreakthrough changed to \(useTechBreakthrough). isInitialized=\(isInitialized)")
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

    // Scarcity Events
    @Published var useScarcityEvents: Bool = true {
        didSet {
            print(">> useScarcityEvents changed to \(useScarcityEvents). isInitialized=\(isInitialized)")
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

    // Global Macro Hedge
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            print(">> useGlobalMacroHedge changed to \(useGlobalMacroHedge). isInitialized=\(isInitialized)")
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

    // Stablecoin Shift
    @Published var useStablecoinShift: Bool = true {
        didSet {
            print(">> useStablecoinShift changed to \(useStablecoinShift). isInitialized=\(isInitialized)")
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

    // Demographic Adoption
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            print(">> useDemographicAdoption changed to \(useDemographicAdoption). isInitialized=\(isInitialized)")
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

    // Altcoin Flight
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            print(">> useAltcoinFlight changed to \(useAltcoinFlight). isInitialized=\(isInitialized)")
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

    // Adoption Factor
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            print(">> useAdoptionFactor changed to \(useAdoptionFactor). isInitialized=\(isInitialized)")
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

    // -----------------------------
    // MARK: - BEARISH FACTORS
    // -----------------------------
    @Published var useRegClampdown: Bool = true {
        didSet {
            print(">> useRegClampdown changed to \(useRegClampdown). isInitialized=\(isInitialized)")
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

    @Published var useCompetitorCoin: Bool = true {
        didSet {
            print(">> useCompetitorCoin changed to \(useCompetitorCoin). isInitialized=\(isInitialized)")
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

    @Published var useSecurityBreach: Bool = true {
        didSet {
            print(">> useSecurityBreach changed to \(useSecurityBreach). isInitialized=\(isInitialized)")
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

    @Published var useBubblePop: Bool = true {
        didSet {
            print(">> useBubblePop changed to \(useBubblePop). isInitialized=\(isInitialized)")
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

    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            print(">> useStablecoinMeltdown changed to \(useStablecoinMeltdown). isInitialized=\(isInitialized)")
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

    @Published var useBlackSwan: Bool = true {
        didSet {
            print(">> useBlackSwan changed to \(useBlackSwan). isInitialized=\(isInitialized)")
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

    @Published var useBearMarket: Bool = true {
        didSet {
            print(">> useBearMarket changed to \(useBearMarket). isInitialized=\(isInitialized)")
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

    @Published var useMaturingMarket: Bool = true {
        didSet {
            print(">> useMaturingMarket changed to \(useMaturingMarket). isInitialized=\(isInitialized)")
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

    @Published var useRecession: Bool = true {
        didSet {
            print(">> useRecession changed to \(useRecession). isInitialized=\(isInitialized)")
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

    init() {
        // do nothing, or do something minimal if you really need to
    }

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

        // If you want to go further, you can combine bullish/bearish toggles too
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

        // Also remove or reset the toggle
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true
    
        // Reassign them to the NEW defaults:
        useHistoricalSampling = true
        useVolShocks = true
    
        // Reassign them to the NEW defaults:
        useHalving = true
        halvingBump = 0.47967220152334283

        useInstitutionalDemand = true
        maxDemandBoost = 0.0012392541338671777

        useCountryAdoption = true
        maxCountryAdBoost = 0.00047095964199831683

        useRegulatoryClarity = true
        maxClarityBoost = 0.0016644023749474966

        useEtfApproval = true
        maxEtfBoost = 0.0004546850204467774

        useTechBreakthrough = true
        maxTechBoost = 0.00040663959745637255

        useScarcityEvents = true
        maxScarcityBoost = 0.0007968083934443039

        useGlobalMacroHedge = true
        maxMacroBoost = 0.000419354572892189

        useStablecoinShift = true
        maxStablecoinBoost = 0.0004049262363101775

        useDemographicAdoption = true
        maxDemoBoost = 0.0013056834936141968

        useAltcoinFlight = true
        maxAltcoinBoost = 0.0002802194461803342

        useAdoptionFactor = true
        adoptionBaseFactor = 0.0009685099124908447

        useRegClampdown = true
        maxClampDown = -0.0011883256912231445

        useCompetitorCoin = true
        maxCompetitorBoost = -0.0011259913444519043

        useSecurityBreach = true
        breachImpact = -0.0007612827334384092

        useBubblePop = true
        maxPopDrop = -0.0012555068731307985

        useStablecoinMeltdown = true
        maxMeltdownDrop = -0.0007028046205417837

        useBlackSwan = true
        blackSwanDrop = -0.0018411452783672483

        useBearMarket = true
        bearWeeklyDrift = -0.0007195305824279769

        useMaturingMarket = true
        maxMaturingDrop = -0.004

        useRecession = true
        maxRecessionDrop = -0.0014508080482482913

        // Enable everything
        toggleAll = true

        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
    }
}
