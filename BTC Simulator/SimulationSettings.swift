//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {
    
    // If you use this InputManager, you can set it up
    var inputManager: PersistentInputManager? = nil
    
    // Basic fields
    @Published var userWeeks: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
    
    // Onboarding
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0
    
    // Just store results here
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    // Toggle for enabling all factors
    @Published var toggleAll = false {
        didSet {
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
    
    private func syncToggleAllState() {
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
    
    // MARK: - Random Seed Logic
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
        }
    }
    
    @Published var seedValue: UInt64 = 0 {
        didSet {
            UserDefaults.standard.set(seedValue, forKey: "seedValue")
        }
    }
    
    @Published var useRandomSeed: Bool = true {
        didSet {
            UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
        }
    }
    
    // The property that caused errors
    @Published var lastUsedSeed: UInt64 = 0  // <— Should be fine now
    
    // This must NOT contain SwiftUI .navigationDestination code
    // i.e. remove the snippet referencing showHistograms/simSettings lastRunResults
    
    private var isUpdating = false
    
    // Bullish toggles
    @Published var useHalving: Bool {
        didSet {
            UserDefaults.standard.set(useHalving, forKey: "useHalving")
            syncToggleAllState()
        }
    }
    @Published var halvingBump: Double {
        didSet {
            UserDefaults.standard.set(halvingBump, forKey: "halvingBump")
        }
    }
    @Published var useInstitutionalDemand: Bool {
        didSet {
            UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
            syncToggleAllState()
        }
    }
    @Published var maxDemandBoost: Double {
        didSet {
            UserDefaults.standard.set(maxDemandBoost, forKey: "maxDemandBoost")
        }
    }
    @Published var useCountryAdoption: Bool {
        didSet {
            UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
            syncToggleAllState()
        }
    }
    @Published var maxCountryAdBoost: Double {
        didSet {
            UserDefaults.standard.set(maxCountryAdBoost, forKey: "maxCountryAdBoost")
        }
    }
    @Published var useRegulatoryClarity: Bool {
        didSet {
            UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
            syncToggleAllState()
        }
    }
    @Published var maxClarityBoost: Double {
        didSet {
            UserDefaults.standard.set(maxClarityBoost, forKey: "maxClarityBoost")
        }
    }
    @Published var useEtfApproval: Bool {
        didSet {
            UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
            syncToggleAllState()
        }
    }
    @Published var maxEtfBoost: Double {
        didSet {
            UserDefaults.standard.set(maxEtfBoost, forKey: "maxEtfBoost")
        }
    }
    @Published var useTechBreakthrough: Bool {
        didSet {
            UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
            syncToggleAllState()
        }
    }
    @Published var maxTechBoost: Double {
        didSet {
            UserDefaults.standard.set(maxTechBoost, forKey: "maxTechBoost")
        }
    }
    @Published var useScarcityEvents: Bool {
        didSet {
            UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
            syncToggleAllState()
        }
    }
    @Published var maxScarcityBoost: Double {
        didSet {
            UserDefaults.standard.set(maxScarcityBoost, forKey: "maxScarcityBoost")
        }
    }
    @Published var useGlobalMacroHedge: Bool {
        didSet {
            UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
            syncToggleAllState()
        }
    }
    @Published var maxMacroBoost: Double {
        didSet {
            UserDefaults.standard.set(maxMacroBoost, forKey: "maxMacroBoost")
        }
    }
    @Published var useStablecoinShift: Bool {
        didSet {
            UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
            syncToggleAllState()
        }
    }
    @Published var maxStablecoinBoost: Double {
        didSet {
            UserDefaults.standard.set(maxStablecoinBoost, forKey: "maxStablecoinBoost")
        }
    }
    @Published var useDemographicAdoption: Bool {
        didSet {
            UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
            syncToggleAllState()
        }
    }
    @Published var maxDemoBoost: Double {
        didSet {
            UserDefaults.standard.set(maxDemoBoost, forKey: "maxDemoBoost")
        }
    }
    @Published var useAltcoinFlight: Bool {
        didSet {
            UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
            syncToggleAllState()
        }
    }
    @Published var maxAltcoinBoost: Double {
        didSet {
            UserDefaults.standard.set(maxAltcoinBoost, forKey: "maxAltcoinBoost")
        }
    }
    @Published var useAdoptionFactor: Bool {
        didSet {
            UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
            syncToggleAllState()
        }
    }
    @Published var adoptionBaseFactor: Double {
        didSet {
            UserDefaults.standard.set(adoptionBaseFactor, forKey: "adoptionBaseFactor")
        }
    }
    
    // Bearish toggles
    @Published var useRegClampdown: Bool {
        didSet {
            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")
            syncToggleAllState()
        }
    }
    @Published var maxClampDown: Double {
        didSet {
            UserDefaults.standard.set(maxClampDown, forKey: "maxClampDown")
        }
    }
    @Published var useCompetitorCoin: Bool {
        didSet {
            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")
            syncToggleAllState()
        }
    }
    @Published var maxCompetitorBoost: Double {
        didSet {
            UserDefaults.standard.set(maxCompetitorBoost, forKey: "maxCompetitorBoost")
        }
    }
    @Published var useSecurityBreach: Bool {
        didSet {
            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")
            syncToggleAllState()
        }
    }
    @Published var breachImpact: Double {
        didSet {
            UserDefaults.standard.set(breachImpact, forKey: "breachImpact")
        }
    }
    @Published var useBubblePop: Bool {
        didSet {
            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")
            syncToggleAllState()
        }
    }
    @Published var maxPopDrop: Double {
        didSet {
            UserDefaults.standard.set(maxPopDrop, forKey: "maxPopDrop")
        }
    }
    @Published var useStablecoinMeltdown: Bool {
        didSet {
            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")
            syncToggleAllState()
        }
    }
    @Published var maxMeltdownDrop: Double {
        didSet {
            UserDefaults.standard.set(maxMeltdownDrop, forKey: "maxMeltdownDrop")
        }
    }
    @Published var useBlackSwan: Bool {
        didSet {
            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")
            syncToggleAllState()
        }
    }
    @Published var blackSwanDrop: Double {
        didSet {
            UserDefaults.standard.set(blackSwanDrop, forKey: "blackSwanDrop")
        }
    }
    @Published var useBearMarket: Bool {
        didSet {
            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")
            syncToggleAllState()
        }
    }
    @Published var bearWeeklyDrift: Double {
        didSet {
            UserDefaults.standard.set(bearWeeklyDrift, forKey: "bearWeeklyDrift")
        }
    }
    @Published var useMaturingMarket: Bool {
        didSet {
            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")
            syncToggleAllState()
        }
    }
    @Published var maxMaturingDrop: Double {
        didSet {
            UserDefaults.standard.set(maxMaturingDrop, forKey: "maxMaturingDrop")
        }
    }
    @Published var useRecession: Bool {
        didSet {
            UserDefaults.standard.set(useRecession, forKey: "useRecession")
            syncToggleAllState()
        }
    }
    @Published var maxRecessionDrop: Double {
        didSet {
            UserDefaults.standard.set(maxRecessionDrop, forKey: "maxRecessionDrop")
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
    
    // MARK: - Init
    init() {
        // Load user’s saved onboarding data (if any)
        if let savedBal = UserDefaults.standard.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }
        if let savedACB = UserDefaults.standard.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }
        if let savedWeeks = UserDefaults.standard.object(forKey: "savedUserWeeks") as? Int {
            self.userWeeks = savedWeeks
        }
        if let savedBTCPrice = UserDefaults.standard.object(forKey: "savedInitialBTCPriceUSD") as? Double {
            self.initialBTCPriceUSD = savedBTCPrice
        }
        
        self.lockedRandomSeed = UserDefaults.standard.bool(forKey: "lockedRandomSeed")
        if let storedSeed = UserDefaults.standard.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        let storedUseRandom = UserDefaults.standard.object(forKey: "useRandomSeed") as? Bool ?? true
        self.useRandomSeed = storedUseRandom
        
        // Load toggles
        self.useHalving = UserDefaults.standard.object(forKey: "useHalving") as? Bool ?? true
        self.halvingBump = UserDefaults.standard.double(forKey: "halvingBump")
        self.useInstitutionalDemand = UserDefaults.standard.object(forKey: "useInstitutionalDemand") as? Bool ?? true
        self.maxDemandBoost = UserDefaults.standard.double(forKey: "maxDemandBoost")
        self.useCountryAdoption = UserDefaults.standard.object(forKey: "useCountryAdoption") as? Bool ?? true
        self.maxCountryAdBoost = UserDefaults.standard.double(forKey: "maxCountryAdBoost")
        self.useRegulatoryClarity = UserDefaults.standard.object(forKey: "useRegulatoryClarity") as? Bool ?? true
        self.maxClarityBoost = UserDefaults.standard.double(forKey: "maxClarityBoost")
        self.useEtfApproval = UserDefaults.standard.object(forKey: "useEtfApproval") as? Bool ?? true
        self.maxEtfBoost = UserDefaults.standard.double(forKey: "maxEtfBoost")
        self.useTechBreakthrough = UserDefaults.standard.object(forKey: "useTechBreakthrough") as? Bool ?? true
        self.maxTechBoost = UserDefaults.standard.double(forKey: "maxTechBoost")
        self.useScarcityEvents = UserDefaults.standard.object(forKey: "useScarcityEvents") as? Bool ?? true
        self.maxScarcityBoost = UserDefaults.standard.double(forKey: "maxScarcityBoost")
        self.useGlobalMacroHedge = UserDefaults.standard.object(forKey: "useGlobalMacroHedge") as? Bool ?? true
        self.maxMacroBoost = UserDefaults.standard.double(forKey: "maxMacroBoost")
        self.useStablecoinShift = UserDefaults.standard.object(forKey: "useStablecoinShift") as? Bool ?? true
        self.maxStablecoinBoost = UserDefaults.standard.double(forKey: "maxStablecoinBoost")
        self.useDemographicAdoption = UserDefaults.standard.object(forKey: "useDemographicAdoption") as? Bool ?? true
        self.maxDemoBoost = UserDefaults.standard.double(forKey: "maxDemoBoost")
        self.useAltcoinFlight = UserDefaults.standard.object(forKey: "useAltcoinFlight") as? Bool ?? true
        self.maxAltcoinBoost = UserDefaults.standard.double(forKey: "maxAltcoinBoost")
        self.useAdoptionFactor = UserDefaults.standard.object(forKey: "useAdoptionFactor") as? Bool ?? true
        self.adoptionBaseFactor = UserDefaults.standard.double(forKey: "adoptionBaseFactor")
        
        self.useRegClampdown = UserDefaults.standard.object(forKey: "useRegClampdown") as? Bool ?? true
        self.maxClampDown = UserDefaults.standard.double(forKey: "maxClampDown")
        self.useCompetitorCoin = UserDefaults.standard.object(forKey: "useCompetitorCoin") as? Bool ?? true
        self.maxCompetitorBoost = UserDefaults.standard.double(forKey: "maxCompetitorBoost")
        self.useSecurityBreach = UserDefaults.standard.object(forKey: "useSecurityBreach") as? Bool ?? true
        self.breachImpact = UserDefaults.standard.double(forKey: "breachImpact")
        self.useBubblePop = UserDefaults.standard.object(forKey: "useBubblePop") as? Bool ?? true
        self.maxPopDrop = UserDefaults.standard.double(forKey: "maxPopDrop")
        self.useStablecoinMeltdown = UserDefaults.standard.object(forKey: "useStablecoinMeltdown") as? Bool ?? true
        self.maxMeltdownDrop = UserDefaults.standard.double(forKey: "maxMeltdownDrop")
        self.useBlackSwan = UserDefaults.standard.object(forKey: "useBlackSwan") as? Bool ?? true
        self.blackSwanDrop = UserDefaults.standard.double(forKey: "blackSwanDrop")
        self.useBearMarket = UserDefaults.standard.object(forKey: "useBearMarket") as? Bool ?? true
        self.bearWeeklyDrift = UserDefaults.standard.double(forKey: "bearWeeklyDrift")
        self.useMaturingMarket = UserDefaults.standard.object(forKey: "useMaturingMarket") as? Bool ?? true
        self.maxMaturingDrop = UserDefaults.standard.double(forKey: "maxMaturingDrop")
        self.useRecession = UserDefaults.standard.object(forKey: "useRecession") as? Bool ?? true
        self.maxRecessionDrop = UserDefaults.standard.double(forKey: "maxRecessionDrop")
        
        syncToggleAllState()
    }
    
    // MARK: - Run Simulation
    func runSimulation(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double = 1.06
    ) {
        // If you had a function to run your MonteCarlo, do it here.
        // Then store the results in `lastRunResults` / `allRuns`.

        // e.g.
        // let (medianRun, all) = runMonteCarloSimulationsWithProgress(...)

        // DispatchQueue.main.async {
        //    self.lastRunResults = medianRun
        //    self.allRuns = all
        // }
    }
    
    func resetUserCriteria() {
        UserDefaults.standard.set(false, forKey: "hasOnboarded")
        lockedRandomSeed = false
        seedValue = 0
        useRandomSeed = true
        restoreDefaults()
        print(">>> [RESET] Completed resetUserCriteria()")
    }
    
    func restoreDefaults() {
        lockedRandomSeed = false
        useRandomSeed = true
        seedValue = 0
        
        UserDefaults.standard.removeObject(forKey: "savedStartingBalance")
        UserDefaults.standard.removeObject(forKey: "savedAverageCostBasis")
        UserDefaults.standard.removeObject(forKey: "savedUserWeeks")
        UserDefaults.standard.removeObject(forKey: "savedInitialBTCPriceUSD")
        
        startingBalance = 0.0
        averageCostBasis = 25000.0
        userWeeks = 52
        initialBTCPriceUSD = 58000.0
        
        // same toggles as your snippet...
    }
}
