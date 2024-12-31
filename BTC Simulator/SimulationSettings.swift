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
    
    // This flag prevents `didSet` from calling `syncToggleAllState()` during init
    private var isInitialized = false

    // Toggle for enabling all factors
    @Published var toggleAll = false {
        didSet {
            if isInitialized {
                // Only run this if fully initialised
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
    
    @Published var lastUsedSeed: UInt64 = 0
    
    private var isUpdating = false
    
    // -----------------------------
    // MARK: - BULLISH FACTORS
    // -----------------------------
    
    @Published var useHalving: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useHalving, forKey: "useHalving")
                syncToggleAllState()
            }
        }
    }
    @Published var halvingBump: Double = 0.06666665673255921 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(halvingBump, forKey: "halvingBump")
            }
        }
    }
    
    @Published var useInstitutionalDemand: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
                syncToggleAllState()
            }
        }
    }
    @Published var maxDemandBoost: Double = 0.0012041112184524537 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemandBoost, forKey: "maxDemandBoost")
            }
        }
    }
    
    @Published var useCountryAdoption: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")
                syncToggleAllState()
            }
        }
    }
    @Published var maxCountryAdBoost: Double = 0.0026894273459911345 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCountryAdBoost, forKey: "maxCountryAdBoost")
            }
        }
    }
    
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClarityBoost: Double = 0.0005488986611366271 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClarityBoost, forKey: "maxClarityBoost")
            }
        }
    }
    
    @Published var useEtfApproval: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
                syncToggleAllState()
            }
        }
    }
    @Published var maxEtfBoost: Double = 0.0008 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxEtfBoost, forKey: "maxEtfBoost")
            }
        }
    }
    
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
                syncToggleAllState()
            }
        }
    }
    @Published var maxTechBoost: Double = 0.0007312775254249572 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxTechBoost, forKey: "maxTechBoost")
            }
        }
    }
    
    @Published var useScarcityEvents: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
                syncToggleAllState()
            }
        }
    }
    @Published var maxScarcityBoost: Double = 0.0016519824042916299 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxScarcityBoost, forKey: "maxScarcityBoost")
            }
        }
    }
    
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMacroBoost: Double = 0.0015 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMacroBoost, forKey: "maxMacroBoost")
            }
        }
    }
    
    @Published var useStablecoinShift: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
                syncToggleAllState()
            }
        }
    }
    @Published var maxStablecoinBoost: Double = 0.00043788542747497556 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxStablecoinBoost, forKey: "maxStablecoinBoost")
            }
        }
    }
    
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
                syncToggleAllState()
            }
        }
    }
    @Published var maxDemoBoost: Double = 0.001 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxDemoBoost, forKey: "maxDemoBoost")
            }
        }
    }
    
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
                syncToggleAllState()
            }
        }
    }
    @Published var maxAltcoinBoost: Double = 0.00044493392109870914 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxAltcoinBoost, forKey: "maxAltcoinBoost")
            }
        }
    }
    
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
                syncToggleAllState()
            }
        }
    }
    @Published var adoptionBaseFactor: Double = 6e-07 {
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
            if isInitialized {
                UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")
                syncToggleAllState()
            }
        }
    }
    @Published var maxClampDown: Double = -0.0004 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxClampDown, forKey: "maxClampDown")
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
    @Published var maxCompetitorBoost: Double = -0.0005629956722259521 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxCompetitorBoost, forKey: "maxCompetitorBoost")
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
    @Published var breachImpact: Double = -0.03303965330123901 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(breachImpact, forKey: "breachImpact")
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
    
    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMeltdownDrop: Double = -0.000756240963935852 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMeltdownDrop, forKey: "maxMeltdownDrop")
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
    @Published var blackSwanDrop: Double = -0.45550661087036126 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(blackSwanDrop, forKey: "blackSwanDrop")
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
    
    @Published var useMaturingMarket: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")
                syncToggleAllState()
            }
        }
    }
    @Published var maxMaturingDrop: Double = -0.001255506277084352 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(maxMaturingDrop, forKey: "maxMaturingDrop")
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
        let defaults = UserDefaults.standard
        
        // Onboarding data
        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }
        if let savedWeeks = defaults.object(forKey: "savedUserWeeks") as? Int {
            self.userWeeks = savedWeeks
        }
        if let savedBTCPrice = defaults.object(forKey: "savedInitialBTCPriceUSD") as? Double {
            self.initialBTCPriceUSD = savedBTCPrice
        }
        
        // Random seed
        self.lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        let storedUseRandom = defaults.object(forKey: "useRandomSeed") as? Bool ?? true
        self.useRandomSeed = storedUseRandom
        
        // BULLISH FACTORS
        if let storedHalving = defaults.object(forKey: "useHalving") as? Bool {
            self.useHalving = storedHalving
        }
        if defaults.object(forKey: "halvingBump") != nil {
            self.halvingBump = defaults.double(forKey: "halvingBump")
        }
        
        if let storedInstitutional = defaults.object(forKey: "useInstitutionalDemand") as? Bool {
            self.useInstitutionalDemand = storedInstitutional
        }
        if defaults.object(forKey: "maxDemandBoost") != nil {
            self.maxDemandBoost = defaults.double(forKey: "maxDemandBoost")
        }
        
        if let storedCountry = defaults.object(forKey: "useCountryAdoption") as? Bool {
            self.useCountryAdoption = storedCountry
        }
        if defaults.object(forKey: "maxCountryAdBoost") != nil {
            self.maxCountryAdBoost = defaults.double(forKey: "maxCountryAdBoost")
        }
        
        if let storedRegClarity = defaults.object(forKey: "useRegulatoryClarity") as? Bool {
            self.useRegulatoryClarity = storedRegClarity
        }
        if defaults.object(forKey: "maxClarityBoost") != nil {
            self.maxClarityBoost = defaults.double(forKey: "maxClarityBoost")
        }
        
        if let storedEtf = defaults.object(forKey: "useEtfApproval") as? Bool {
            self.useEtfApproval = storedEtf
        }
        if defaults.object(forKey: "maxEtfBoost") != nil {
            self.maxEtfBoost = defaults.double(forKey: "maxEtfBoost")
        }
        
        if let storedTech = defaults.object(forKey: "useTechBreakthrough") as? Bool {
            self.useTechBreakthrough = storedTech
        }
        if defaults.object(forKey: "maxTechBoost") != nil {
            self.maxTechBoost = defaults.double(forKey: "maxTechBoost")
        }
        
        if let storedScarcity = defaults.object(forKey: "useScarcityEvents") as? Bool {
            self.useScarcityEvents = storedScarcity
        }
        if defaults.object(forKey: "maxScarcityBoost") != nil {
            self.maxScarcityBoost = defaults.double(forKey: "maxScarcityBoost")
        }
        
        if let storedMacro = defaults.object(forKey: "useGlobalMacroHedge") as? Bool {
            self.useGlobalMacroHedge = storedMacro
        }
        if defaults.object(forKey: "maxMacroBoost") != nil {
            self.maxMacroBoost = defaults.double(forKey: "maxMacroBoost")
        }
        
        if let storedStableShift = defaults.object(forKey: "useStablecoinShift") as? Bool {
            self.useStablecoinShift = storedStableShift
        }
        if defaults.object(forKey: "maxStablecoinBoost") != nil {
            self.maxStablecoinBoost = defaults.double(forKey: "maxStablecoinBoost")
        }
        
        if let storedDemo = defaults.object(forKey: "useDemographicAdoption") as? Bool {
            self.useDemographicAdoption = storedDemo
        }
        if defaults.object(forKey: "maxDemoBoost") != nil {
            self.maxDemoBoost = defaults.double(forKey: "maxDemoBoost")
        }
        
        if let storedAltcoinFlight = defaults.object(forKey: "useAltcoinFlight") as? Bool {
            self.useAltcoinFlight = storedAltcoinFlight
        }
        if defaults.object(forKey: "maxAltcoinBoost") != nil {
            self.maxAltcoinBoost = defaults.double(forKey: "maxAltcoinBoost")
        }
        
        if let storedAdoption = defaults.object(forKey: "useAdoptionFactor") as? Bool {
            self.useAdoptionFactor = storedAdoption
        }
        if defaults.object(forKey: "adoptionBaseFactor") != nil {
            self.adoptionBaseFactor = defaults.double(forKey: "adoptionBaseFactor")
        }
        
        // BEARISH FACTORS
        if let storedRegClamp = defaults.object(forKey: "useRegClampdown") as? Bool {
            self.useRegClampdown = storedRegClamp
        }
        if defaults.object(forKey: "maxClampDown") != nil {
            self.maxClampDown = defaults.double(forKey: "maxClampDown")
        }
        
        if let storedCompetitor = defaults.object(forKey: "useCompetitorCoin") as? Bool {
            self.useCompetitorCoin = storedCompetitor
        }
        if defaults.object(forKey: "maxCompetitorBoost") != nil {
            self.maxCompetitorBoost = defaults.double(forKey: "maxCompetitorBoost")
        }
        
        if let storedSecBreach = defaults.object(forKey: "useSecurityBreach") as? Bool {
            self.useSecurityBreach = storedSecBreach
        }
        if defaults.object(forKey: "breachImpact") != nil {
            self.breachImpact = defaults.double(forKey: "breachImpact")
        }
        
        if let storedBubblePop = defaults.object(forKey: "useBubblePop") as? Bool {
            self.useBubblePop = storedBubblePop
        }
        if defaults.object(forKey: "maxPopDrop") != nil {
            self.maxPopDrop = defaults.double(forKey: "maxPopDrop")
        }
        
        if let storedStableMeltdown = defaults.object(forKey: "useStablecoinMeltdown") as? Bool {
            self.useStablecoinMeltdown = storedStableMeltdown
        }
        if defaults.object(forKey: "maxMeltdownDrop") != nil {
            self.maxMeltdownDrop = defaults.double(forKey: "maxMeltdownDrop")
        }
        
        if let storedSwan = defaults.object(forKey: "useBlackSwan") as? Bool {
            self.useBlackSwan = storedSwan
        }
        if defaults.object(forKey: "blackSwanDrop") != nil {
            self.blackSwanDrop = defaults.double(forKey: "blackSwanDrop")
        }
        
        if let storedBearMkt = defaults.object(forKey: "useBearMarket") as? Bool {
            self.useBearMarket = storedBearMkt
        }
        if defaults.object(forKey: "bearWeeklyDrift") != nil {
            self.bearWeeklyDrift = defaults.double(forKey: "bearWeeklyDrift")
        }
        
        if let storedMaturing = defaults.object(forKey: "useMaturingMarket") as? Bool {
            self.useMaturingMarket = storedMaturing
        }
        if defaults.object(forKey: "maxMaturingDrop") != nil {
            self.maxMaturingDrop = defaults.double(forKey: "maxMaturingDrop")
        }
        
        if let storedRecession = defaults.object(forKey: "useRecession") as? Bool {
            self.useRecession = storedRecession
        }
        if defaults.object(forKey: "maxRecessionDrop") != nil {
            self.maxRecessionDrop = defaults.double(forKey: "maxRecessionDrop")
        }
        
        // Mark as initialized so didSet logic triggers hereafter
        isInitialized = true
        
        // Finally, sync toggles if needed
        syncToggleAllState()
    }
    
    // MARK: - Run Simulation
    func runSimulation(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double = 1.06
    ) {
        // ...
    }
    
    // Example “Restore Defaults” that only resets factor keys
    func restoreDefaults() {
        // Remove factor keys so next time we load,
        // it falls back to code defaults in init() if you'd prefer that approach.
        let defaults = UserDefaults.standard
        
        // We do *not* remove onboarding or seeds here, only the factor toggles:
        defaults.removeObject(forKey: "useHalving")
        defaults.removeObject(forKey: "halvingBump")
        defaults.removeObject(forKey: "useInstitutionalDemand")
        defaults.removeObject(forKey: "maxDemandBoost")
        // ...and so on for all your factor keys...
        
        // Immediately set them in memory so UI updates
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

        // Finally, toggleAll = true (or false) if you want everything on by default
        toggleAll = true

    }
}
