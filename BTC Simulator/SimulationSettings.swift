//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    // MARK: - Random Seed Logic
    
    /// Whether the random seed is locked (so it doesn't change each simulation)
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
        }
    }
    
    /// The actual seed value. If locked, we'll always use this seed.
    @Published var seedValue: UInt64 = 12345 {
        didSet {
            UserDefaults.standard.set(seedValue, forKey: "seedValue")
        }
    }
    
    /// Whether we pick a new random seed each run (if lockedRandomSeed is false)
    @Published var useRandomSeed: Bool = false {
        didSet {
            UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
        }
    }
    
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
    
    // MARK: - Init
    
    init() {
        // --- Load random seed settings ---
        self.lockedRandomSeed = UserDefaults.standard.bool(forKey: "lockedRandomSeed")
        if let storedSeed = UserDefaults.standard.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        let storedUseRandom = UserDefaults.standard.object(forKey: "useRandomSeed") as? Bool ?? false
        self.useRandomSeed = storedUseRandom

        // --- Load bullish toggles ---
        let storedUseHalving  = UserDefaults.standard.object(forKey: "useHalving") as? Bool ?? true
        let storedHalvingBump = UserDefaults.standard.double(forKey: "halvingBump")
        let finalHalvingBump  = (storedHalvingBump == 0) ? 0.20 : storedHalvingBump

        let storedUseInst     = UserDefaults.standard.object(forKey: "useInstitutionalDemand") as? Bool ?? true
        let storedMaxDemand   = UserDefaults.standard.double(forKey: "maxDemandBoost")
        let finalMaxDemand    = (storedMaxDemand == 0) ? 0.004 : storedMaxDemand

        let storedUseCountry  = UserDefaults.standard.object(forKey: "useCountryAdoption") as? Bool ?? true
        let storedMaxCountry  = UserDefaults.standard.double(forKey: "maxCountryAdBoost")
        let finalMaxCountry   = (storedMaxCountry == 0) ? 0.0055 : storedMaxCountry

        let storedUseClarity  = UserDefaults.standard.object(forKey: "useRegulatoryClarity") as? Bool ?? true
        let storedMaxClarity  = UserDefaults.standard.double(forKey: "maxClarityBoost")
        let finalMaxClarity   = (storedMaxClarity == 0) ? 0.0006 : storedMaxClarity

        let storedUseEtf      = UserDefaults.standard.object(forKey: "useEtfApproval") as? Bool ?? true
        let storedMaxEtf      = UserDefaults.standard.double(forKey: "maxEtfBoost")
        let finalMaxEtf       = (storedMaxEtf == 0) ? 0.0008 : storedMaxEtf

        let storedUseTech     = UserDefaults.standard.object(forKey: "useTechBreakthrough") as? Bool ?? true
        let storedMaxTech     = UserDefaults.standard.double(forKey: "maxTechBoost")
        let finalMaxTech      = (storedMaxTech == 0) ? 0.002 : storedMaxTech

        let storedUseScarcity = UserDefaults.standard.object(forKey: "useScarcityEvents") as? Bool ?? true
        let storedMaxScarcity = UserDefaults.standard.double(forKey: "maxScarcityBoost")
        let finalMaxScarcity  = (storedMaxScarcity == 0) ? 0.025 : storedMaxScarcity

        let storedUseMacro    = UserDefaults.standard.object(forKey: "useGlobalMacroHedge") as? Bool ?? true
        let storedMaxMacro    = UserDefaults.standard.double(forKey: "maxMacroBoost")
        let finalMaxMacro     = (storedMaxMacro == 0) ? 0.0015 : storedMaxMacro

        let storedUseStable   = UserDefaults.standard.object(forKey: "useStablecoinShift") as? Bool ?? true
        let storedMaxStable   = UserDefaults.standard.double(forKey: "maxStablecoinBoost")
        let finalMaxStable    = (storedMaxStable == 0) ? 0.0006 : storedMaxStable

        let storedUseDemo     = UserDefaults.standard.object(forKey: "useDemographicAdoption") as? Bool ?? true
        let storedMaxDemo     = UserDefaults.standard.double(forKey: "maxDemoBoost")
        let finalMaxDemo      = (storedMaxDemo == 0) ? 0.001 : storedMaxDemo

        let storedUseAltcoin  = UserDefaults.standard.object(forKey: "useAltcoinFlight") as? Bool ?? true
        let storedMaxAltcoin  = UserDefaults.standard.double(forKey: "maxAltcoinBoost")
        let finalMaxAltcoin   = (storedMaxAltcoin == 0) ? 0.001 : storedMaxAltcoin

        let storedUseAdoption = UserDefaults.standard.object(forKey: "useAdoptionFactor") as? Bool ?? true
        let storedAdoptionVal = UserDefaults.standard.double(forKey: "adoptionBaseFactor")
        let finalAdoptionVal  = (storedAdoptionVal == 0) ? 0.000005 : storedAdoptionVal

        // --- Load bearish toggles ---
        let storedUseClamp    = UserDefaults.standard.object(forKey: "useRegClampdown") as? Bool ?? true
        let storedMaxClamp    = UserDefaults.standard.double(forKey: "maxClampDown")
        let finalMaxClamp     = (storedMaxClamp == 0) ? -0.0002 : storedMaxClamp

        let storedUseCompet   = UserDefaults.standard.object(forKey: "useCompetitorCoin") as? Bool ?? true
        let storedMaxCompet   = UserDefaults.standard.double(forKey: "maxCompetitorBoost")
        let finalMaxCompet = (storedMaxCompet == 0) ? -0.0018 : storedMaxCompet

        let storedUseBreach   = UserDefaults.standard.object(forKey: "useSecurityBreach") as? Bool ?? true
        let storedBreachImp   = UserDefaults.standard.double(forKey: "breachImpact")
        let finalBreachImp    = (storedBreachImp == 0) ? -0.1 : storedBreachImp

        let storedUsePop      = UserDefaults.standard.object(forKey: "useBubblePop") as? Bool ?? true
        let storedMaxPop      = UserDefaults.standard.double(forKey: "maxPopDrop")
        let finalMaxPop       = (storedMaxPop == 0) ? -0.005 : storedMaxPop

        let storedUseMelt     = UserDefaults.standard.object(forKey: "useStablecoinMeltdown") as? Bool ?? true
        let storedMaxMelt     = UserDefaults.standard.double(forKey: "maxMeltdownDrop")
        let finalMaxMelt      = (storedMaxMelt == 0) ? -0.001 : storedMaxMelt

        let storedUseBlack    = UserDefaults.standard.object(forKey: "useBlackSwan") as? Bool ?? true
        let storedBlackDrop   = UserDefaults.standard.double(forKey: "blackSwanDrop")
        let finalBlackDrop    = (storedBlackDrop == 0) ? -0.60 : storedBlackDrop

        let storedUseBear     = UserDefaults.standard.object(forKey: "useBearMarket") as? Bool ?? true
        let storedBearDrift   = UserDefaults.standard.double(forKey: "bearWeeklyDrift")
        let finalBearDrift    = (storedBearDrift == 0) ? -0.01 : storedBearDrift

        let storedUseMatur    = UserDefaults.standard.object(forKey: "useMaturingMarket") as? Bool ?? true
        let storedMaxMatur    = UserDefaults.standard.double(forKey: "maxMaturingDrop")
        let finalMaxMatur     = (storedMaxMatur == 0) ? -0.015 : storedMaxMatur

        let storedUseRecession = UserDefaults.standard.object(forKey: "useRecession") as? Bool ?? true
        let storedMaxRecession = UserDefaults.standard.double(forKey: "maxRecessionDrop")
        let finalMaxRecession  = (storedMaxRecession == 0) ? -0.004 : storedMaxRecession

        // --- Assign to properties ---
        // Bullish
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

        // Bearish
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
    
    // MARK: - Restore Defaults
    
    func restoreDefaults() {
        // Reset random seed logic
        lockedRandomSeed = false
        useRandomSeed = false
        seedValue = 12345
        
        // Reset bullish toggles
        useHalving = true
        halvingBump = 0.20
        
        useInstitutionalDemand = true
        maxDemandBoost = 0.004
        
        useCountryAdoption = true
        maxCountryAdBoost = 0.0055
        
        useRegulatoryClarity = true
        maxClarityBoost = 0.0006
        
        useEtfApproval = true
        maxEtfBoost = 0.0008
        
        useTechBreakthrough = true
        maxTechBoost = 0.002
        
        useScarcityEvents = true
        maxScarcityBoost = 0.025
        
        useGlobalMacroHedge = true
        maxMacroBoost = 0.0015
        
        useStablecoinShift = true
        maxStablecoinBoost = 0.0006
        
        useDemographicAdoption = true
        maxDemoBoost = 0.001
        
        useAltcoinFlight = true
        maxAltcoinBoost = 0.001
        
        useAdoptionFactor = true
        adoptionBaseFactor = 0.000005
        
        // Reset bearish toggles
        useRegClampdown = true
        maxClampDown = -0.0002
        
        useCompetitorCoin = true
        maxCompetitorBoost = -0.0018
        
        useSecurityBreach = true
        breachImpact = -0.1
        
        useBubblePop = true
        maxPopDrop = -0.005
        
        useStablecoinMeltdown = true
        maxMeltdownDrop = -0.001
        
        useBlackSwan = true
        blackSwanDrop = -0.60
        
        useBearMarket = true
        bearWeeklyDrift = -0.01
        
        useMaturingMarket = true
        maxMaturingDrop = -0.015
        
        useRecession = true
        maxRecessionDrop = -0.004
    }
}
