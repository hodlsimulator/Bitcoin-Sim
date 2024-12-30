//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    
    // If you use this InputManager, you can set it up
    var inputManager: PersistentInputManager? = nil
    
    // The basic fields for your simulation
    @Published var userWeeks: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
    
    // The fields you capture from onboarding
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0
    
    // MARK: - toggleAll
    @Published var toggleAll = false {
        didSet {
            if isUpdating { return }
            isUpdating = true
            if toggleAll {
                // Turn on all factors
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
                // Turn off all factors
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

    // A helper method to safely update the state of toggleAll
    private func syncToggleAllState() {
        if !isUpdating {
            isUpdating = true // Prevent recursive updates
            let allFactorsEnabled = useHalving &&
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

            // Update toggleAll only if its state differs
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
    @Published var lastUsedSeed: UInt64 = 0

    // MARK: - (New) Results Storage
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []

    // MARK: - Control Recursive Updates
    private var isUpdating = false

    // MARK: - Bullish Toggles
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
    
    // MARK: - Bearish Toggles
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
    
    // Check if all factors are on
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
        
        // Random seed logic
        self.lockedRandomSeed = UserDefaults.standard.bool(forKey: "lockedRandomSeed")
        if let storedSeed = UserDefaults.standard.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        let storedUseRandom = UserDefaults.standard.object(forKey: "useRandomSeed") as? Bool ?? true
        self.useRandomSeed = storedUseRandom

        // Load bullish toggles with defaults
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

        // Load bearish toggles with defaults
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
        
        // Recalculate toggleAll after loading states
        syncToggleAllState()
    }
    
    // MARK: - Run Simulation
    func runSimulation(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double = 1.06
    ) {
        // Decide on seed
        let finalSeed: UInt64? = lockedRandomSeed ? seedValue : nil
        
        let (medianRun, allIterations) = runMonteCarloSimulationsWithProgress(
            settings: self,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            correlationWithSP500: 0.0,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: self.userWeeks,
            iterations: iterations,
            initialBTCPriceUSD: self.initialBTCPriceUSD,
            isCancelled: { false },
            progressCallback: { _ in },
            seed: finalSeed
        )
        
        DispatchQueue.main.async {
            self.lastRunResults = medianRun
            self.allRuns = allIterations
        }
    }
    
    // MARK: - resetUserCriteria
    func resetUserCriteria() {
        UserDefaults.standard.set(false, forKey: "hasOnboarded")
        lockedRandomSeed = false
        seedValue = 0
        useRandomSeed = true
        restoreDefaults()
        print(">>> [RESET] Completed resetUserCriteria()")
    }
    
    // MARK: - restoreDefaults
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
        
        // Bullish toggles
        useHalving = true
        halvingBump = 0.06666665673255921
        useInstitutionalDemand = true
        maxDemandBoost = 0.0012041112184524537
        useCountryAdoption = true
        maxCountryAdBoost = 0.0026894273459911345
        useRegulatoryClarity = true
        maxClarityBoost = 0.0005488986611366271
        useEtfApproval = true
        maxEtfBoost = 0.0008
        useTechBreakthrough = true
        maxTechBoost = 0.0007312775254249572
        useScarcityEvents = true
        maxScarcityBoost = 0.0016519824042916299
        useGlobalMacroHedge = true
        maxMacroBoost = 0.0015
        useStablecoinShift = true
        maxStablecoinBoost = 0.00043788542747497556
        useDemographicAdoption = true
        maxDemoBoost = 0.001
        useAltcoinFlight = true
        maxAltcoinBoost = 0.00044493392109870914
        useAdoptionFactor = true
        adoptionBaseFactor = 6e-07
        
        // Bearish toggles
        useRegClampdown = true
        maxClampDown = -0.0004
        useCompetitorCoin = true
        maxCompetitorBoost = -0.0005629956722259521
        useSecurityBreach = true
        breachImpact = -0.03303965330123901
        useBubblePop = true
        maxPopDrop = -0.0012555068731307985
        useStablecoinMeltdown = true
        maxMeltdownDrop = -0.000756240963935852
        useBlackSwan = true
        blackSwanDrop = -0.45550661087036126
        useBearMarket = true
        bearWeeklyDrift = -0.0007195305824279769
        useMaturingMarket = true
        maxMaturingDrop = -0.001255506277084352
        useRecession = true
        maxRecessionDrop = -0.0014508080482482913
    }
}
