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
    
    // A simple "toggleAll"
    @Published var toggleAll = false {
        didSet {
            // Turn on/off each factor
            useHalving              = toggleAll
            useInstitutionalDemand  = toggleAll
            useCountryAdoption      = toggleAll
            useRegulatoryClarity    = toggleAll
            useEtfApproval          = toggleAll
            useTechBreakthrough     = toggleAll
            useScarcityEvents       = toggleAll
            useGlobalMacroHedge     = toggleAll
            useStablecoinShift      = toggleAll
            useDemographicAdoption  = toggleAll
            useAltcoinFlight        = toggleAll
            useAdoptionFactor       = toggleAll

            useRegClampdown         = toggleAll
            useCompetitorCoin       = toggleAll
            useSecurityBreach       = toggleAll
            useBubblePop            = toggleAll
            useStablecoinMeltdown   = toggleAll
            useBlackSwan            = toggleAll
            useBearMarket           = toggleAll
            useMaturingMarket       = toggleAll
            useRecession            = toggleAll
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
    // We store the final run (median) in `lastRunResults`,
    // and all the runs in `allRuns` if needed.
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    // MARK: - Bullish Toggles
    @Published var useHalving: Bool {
        didSet { UserDefaults.standard.set(useHalving, forKey: "useHalving") }
    }
    @Published var halvingBump: Double {
        didSet { UserDefaults.standard.set(halvingBump, forKey: "halvingBump") }
    }
    @Published var useInstitutionalDemand: Bool {
        didSet { UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand") }
    }
    @Published var maxDemandBoost: Double {
        didSet { UserDefaults.standard.set(maxDemandBoost, forKey: "maxDemandBoost") }
    }
    @Published var useCountryAdoption: Bool {
        didSet { UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption") }
    }
    @Published var maxCountryAdBoost: Double {
        didSet { UserDefaults.standard.set(maxCountryAdBoost, forKey: "maxCountryAdBoost") }
    }
    @Published var useRegulatoryClarity: Bool {
        didSet { UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity") }
    }
    @Published var maxClarityBoost: Double {
        didSet { UserDefaults.standard.set(maxClarityBoost, forKey: "maxClarityBoost") }
    }
    @Published var useEtfApproval: Bool {
        didSet { UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval") }
    }
    @Published var maxEtfBoost: Double {
        didSet { UserDefaults.standard.set(maxEtfBoost, forKey: "maxEtfBoost") }
    }
    @Published var useTechBreakthrough: Bool {
        didSet { UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough") }
    }
    @Published var maxTechBoost: Double {
        didSet { UserDefaults.standard.set(maxTechBoost, forKey: "maxTechBoost") }
    }
    @Published var useScarcityEvents: Bool {
        didSet { UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents") }
    }
    @Published var maxScarcityBoost: Double {
        didSet { UserDefaults.standard.set(maxScarcityBoost, forKey: "maxScarcityBoost") }
    }
    @Published var useGlobalMacroHedge: Bool {
        didSet { UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge") }
    }
    @Published var maxMacroBoost: Double {
        didSet { UserDefaults.standard.set(maxMacroBoost, forKey: "maxMacroBoost") }
    }
    @Published var useStablecoinShift: Bool {
        didSet { UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift") }
    }
    @Published var maxStablecoinBoost: Double {
        didSet { UserDefaults.standard.set(maxStablecoinBoost, forKey: "maxStablecoinBoost") }
    }
    @Published var useDemographicAdoption: Bool {
        didSet { UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption") }
    }
    @Published var maxDemoBoost: Double {
        didSet { UserDefaults.standard.set(maxDemoBoost, forKey: "maxDemoBoost") }
    }
    @Published var useAltcoinFlight: Bool {
        didSet { UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight") }
    }
    @Published var maxAltcoinBoost: Double {
        didSet { UserDefaults.standard.set(maxAltcoinBoost, forKey: "maxAltcoinBoost") }
    }
    @Published var useAdoptionFactor: Bool {
        didSet { UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor") }
    }
    @Published var adoptionBaseFactor: Double {
        didSet { UserDefaults.standard.set(adoptionBaseFactor, forKey: "adoptionBaseFactor") }
    }
    
    // MARK: - Bearish Toggles
    @Published var useRegClampdown: Bool {
        didSet { UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown") }
    }
    @Published var maxClampDown: Double {
        didSet { UserDefaults.standard.set(maxClampDown, forKey: "maxClampDown") }
    }
    @Published var useCompetitorCoin: Bool {
        didSet { UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin") }
    }
    @Published var maxCompetitorBoost: Double {
        didSet { UserDefaults.standard.set(maxCompetitorBoost, forKey: "maxCompetitorBoost") }
    }
    @Published var useSecurityBreach: Bool {
        didSet { UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach") }
    }
    @Published var breachImpact: Double {
        didSet { UserDefaults.standard.set(breachImpact, forKey: "breachImpact") }
    }
    @Published var useBubblePop: Bool {
        didSet { UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop") }
    }
    @Published var maxPopDrop: Double {
        didSet { UserDefaults.standard.set(maxPopDrop, forKey: "maxPopDrop") }
    }
    @Published var useStablecoinMeltdown: Bool {
        didSet { UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown") }
    }
    @Published var maxMeltdownDrop: Double {
        didSet { UserDefaults.standard.set(maxMeltdownDrop, forKey: "maxMeltdownDrop") }
    }
    @Published var useBlackSwan: Bool {
        didSet { UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan") }
    }
    @Published var blackSwanDrop: Double {
        didSet { UserDefaults.standard.set(blackSwanDrop, forKey: "blackSwanDrop") }
    }
    @Published var useBearMarket: Bool {
        didSet { UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket") }
    }
    @Published var bearWeeklyDrift: Double {
        didSet { UserDefaults.standard.set(bearWeeklyDrift, forKey: "bearWeeklyDrift") }
    }
    @Published var useMaturingMarket: Bool {
        didSet { UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket") }
    }
    @Published var maxMaturingDrop: Double {
        didSet { UserDefaults.standard.set(maxMaturingDrop, forKey: "maxMaturingDrop") }
    }
    @Published var useRecession: Bool {
        didSet { UserDefaults.standard.set(useRecession, forKey: "useRecession") }
    }
    @Published var maxRecessionDrop: Double {
        didSet { UserDefaults.standard.set(maxRecessionDrop, forKey: "maxRecessionDrop") }
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
        
        // Load bullish toggles
        let storedUseHalving  = UserDefaults.standard.object(forKey: "useHalving") as? Bool ?? true
        let storedHalvingBump = UserDefaults.standard.double(forKey: "halvingBump")
        let finalHalvingBump  = (storedHalvingBump == 0) ? 0.20 : storedHalvingBump

        let storedUseInst   = UserDefaults.standard.object(forKey: "useInstitutionalDemand") as? Bool ?? true
        let storedMaxDemand = UserDefaults.standard.double(forKey: "maxDemandBoost")
        let finalMaxDemand  = (storedMaxDemand == 0) ? 0.004 : storedMaxDemand

        let storedUseCountry = UserDefaults.standard.object(forKey: "useCountryAdoption") as? Bool ?? true
        let storedMaxCountry = UserDefaults.standard.double(forKey: "maxCountryAdBoost")
        let finalMaxCountry  = (storedMaxCountry == 0) ? 0.0055 : storedMaxCountry

        let storedUseClarity = UserDefaults.standard.object(forKey: "useRegulatoryClarity") as? Bool ?? true
        let storedMaxClarity = UserDefaults.standard.double(forKey: "maxClarityBoost")
        let finalMaxClarity  = (storedMaxClarity == 0) ? 0.0006 : storedMaxClarity

        let storedUseEtf   = UserDefaults.standard.object(forKey: "useEtfApproval") as? Bool ?? true
        let storedMaxEtf   = UserDefaults.standard.double(forKey: "maxEtfBoost")
        let finalMaxEtf    = (storedMaxEtf == 0) ? 0.0008 : storedMaxEtf

        let storedUseTech  = UserDefaults.standard.object(forKey: "useTechBreakthrough") as? Bool ?? true
        let storedMaxTech  = UserDefaults.standard.double(forKey: "maxTechBoost")
        let finalMaxTech   = (storedMaxTech == 0) ? 0.002 : storedMaxTech

        let storedUseScarcity = UserDefaults.standard.object(forKey: "useScarcityEvents") as? Bool ?? true
        let storedMaxScarcity = UserDefaults.standard.double(forKey: "maxScarcityBoost")
        let finalMaxScarcity  = (storedMaxScarcity == 0) ? 0.025 : storedMaxScarcity

        let storedUseMacro = UserDefaults.standard.object(forKey: "useGlobalMacroHedge") as? Bool ?? true
        let storedMaxMacro = UserDefaults.standard.double(forKey: "maxMacroBoost")
        let finalMaxMacro  = (storedMaxMacro == 0) ? 0.0015 : storedMaxMacro

        let storedUseStable = UserDefaults.standard.object(forKey: "useStablecoinShift") as? Bool ?? true
        let storedMaxStable = UserDefaults.standard.double(forKey: "maxStablecoinBoost")
        let finalMaxStable  = (storedMaxStable == 0) ? 0.0006 : storedMaxStable

        let storedUseDemo  = UserDefaults.standard.object(forKey: "useDemographicAdoption") as? Bool ?? true
        let storedMaxDemo  = UserDefaults.standard.double(forKey: "maxDemoBoost")
        let finalMaxDemo   = (storedMaxDemo == 0) ? 0.001 : storedMaxDemo

        let storedUseAltcoin = UserDefaults.standard.object(forKey: "useAltcoinFlight") as? Bool ?? true
        let storedMaxAltcoin = UserDefaults.standard.double(forKey: "maxAltcoinBoost")
        let finalMaxAltcoin  = (storedMaxAltcoin == 0) ? 0.001 : storedMaxAltcoin

        let storedUseAdoption = UserDefaults.standard.object(forKey: "useAdoptionFactor") as? Bool ?? true
        let storedAdoptionVal = UserDefaults.standard.double(forKey: "adoptionBaseFactor")
        let finalAdoptionVal  = (storedAdoptionVal == 0) ? 0.000005 : storedAdoptionVal
        
        // Load bearish toggles
        let storedUseClamp  = UserDefaults.standard.object(forKey: "useRegClampdown") as? Bool ?? true
        let storedMaxClamp  = UserDefaults.standard.double(forKey: "maxClampDown")
        let finalMaxClamp   = (storedMaxClamp == 0) ? -0.0002 : storedMaxClamp

        let storedUseCompet = UserDefaults.standard.object(forKey: "useCompetitorCoin") as? Bool ?? true
        let storedMaxCompet = UserDefaults.standard.double(forKey: "maxCompetitorBoost")
        let finalMaxCompet  = (storedMaxCompet == 0) ? -0.0018 : storedMaxCompet

        let storedUseBreach = UserDefaults.standard.object(forKey: "useSecurityBreach") as? Bool ?? true
        let storedBreachImp = UserDefaults.standard.double(forKey: "breachImpact")
        let finalBreachImp  = (storedBreachImp == 0) ? -0.1 : storedBreachImp

        let storedUsePop    = UserDefaults.standard.object(forKey: "useBubblePop") as? Bool ?? true
        let storedMaxPop    = UserDefaults.standard.double(forKey: "maxPopDrop")
        let finalMaxPop     = (storedMaxPop == 0) ? -0.005 : storedMaxPop

        let storedUseMelt   = UserDefaults.standard.object(forKey: "useStablecoinMeltdown") as? Bool ?? true
        let storedMaxMelt   = UserDefaults.standard.double(forKey: "maxMeltdownDrop")
        let finalMaxMelt    = (storedMaxMelt == 0) ? -0.001 : storedMaxMelt

        let storedUseBlack  = UserDefaults.standard.object(forKey: "useBlackSwan") as? Bool ?? true
        let storedBlackDrop = UserDefaults.standard.double(forKey: "blackSwanDrop")
        let finalBlackDrop  = (storedBlackDrop == 0) ? -0.60 : storedBlackDrop

        let storedUseBear   = UserDefaults.standard.object(forKey: "useBearMarket") as? Bool ?? true
        let storedBearDrift = UserDefaults.standard.double(forKey: "bearWeeklyDrift")
        let finalBearDrift  = (storedBearDrift == 0) ? -0.01 : storedBearDrift

        let storedUseMatur  = UserDefaults.standard.object(forKey: "useMaturingMarket") as? Bool ?? true
        let storedMaxMatur  = UserDefaults.standard.double(forKey: "maxMaturingDrop")
        let finalMaxMatur   = (storedMaxMatur == 0) ? -0.015 : storedMaxMatur

        let storedUseRecession = UserDefaults.standard.object(forKey: "useRecession") as? Bool ?? true
        let storedMaxRecession = UserDefaults.standard.double(forKey: "maxRecessionDrop")
        let finalMaxRecession  = (storedMaxRecession == 0) ? -0.004 : storedMaxRecession
        
        // Assign
        self.useHalving = storedUseHalving
        self.halvingBump = finalHalvingBump
        self.useInstitutionalDemand = storedUseInst
        self.maxDemandBoost = finalMaxDemand
        self.useCountryAdoption = storedUseCountry
        self.maxCountryAdBoost = finalMaxCountry
        self.useRegulatoryClarity = storedUseClarity
        self.maxClarityBoost = finalMaxClarity
        self.useEtfApproval = storedUseEtf
        self.maxEtfBoost = finalMaxEtf
        self.useTechBreakthrough = storedUseTech
        self.maxTechBoost = finalMaxTech
        self.useScarcityEvents = storedUseScarcity
        self.maxScarcityBoost = finalMaxScarcity
        self.useGlobalMacroHedge = storedUseMacro
        self.maxMacroBoost = finalMaxMacro
        self.useStablecoinShift = storedUseStable
        self.maxStablecoinBoost = finalMaxStable
        self.useDemographicAdoption = storedUseDemo
        self.maxDemoBoost = finalMaxDemo
        self.useAltcoinFlight = storedUseAltcoin
        self.maxAltcoinBoost = finalMaxAltcoin
        self.useAdoptionFactor = storedUseAdoption
        self.adoptionBaseFactor = finalAdoptionVal

        self.useRegClampdown = storedUseClamp
        self.maxClampDown = finalMaxClamp
        self.useCompetitorCoin = storedUseCompet
        self.maxCompetitorBoost = finalMaxCompet
        self.useSecurityBreach = storedUseBreach
        self.breachImpact = finalBreachImp
        self.useBubblePop = storedUsePop
        self.maxPopDrop = finalMaxPop
        self.useStablecoinMeltdown = storedUseMelt
        self.maxMeltdownDrop = finalMaxMelt
        self.useBlackSwan = storedUseBlack
        self.blackSwanDrop = finalBlackDrop
        self.useBearMarket = storedUseBear
        self.bearWeeklyDrift = finalBearDrift
        self.useMaturingMarket = storedUseMatur
        self.maxMaturingDrop = finalMaxMatur
        self.useRecession = storedUseRecession
        self.maxRecessionDrop = finalMaxRecession
    }
    
    // MARK: - Run Simulation
    // This is how we actually store the final (median) run and all runs
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
            // Store them so your UI sees the new data
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
