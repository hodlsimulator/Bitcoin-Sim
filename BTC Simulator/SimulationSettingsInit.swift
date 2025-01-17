//
//  SimulationSettingsInit.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    convenience init(loadDefaults: Bool = true) {
        self.init()  // Calls the empty init in SimulationSettings.swift
        guard loadDefaults else { return }

        let defaults = UserDefaults.standard
            
        // (A) Load any stored boolean for useLognormalGrowth (if it exists)
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        } else {
            // If there's no stored value, default to true
            useLognormalGrowth = true
        }
        
        // Onboarding data
        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }
        
        // Instead of userWeeks, load userPeriods
        if let savedPeriods = defaults.object(forKey: "savedUserPeriods") as? Int {
            self.userPeriods = savedPeriods
        }
        if let savedPeriodUnitRaw = defaults.string(forKey: "savedPeriodUnit"),
           let savedPeriodUnit = PeriodUnit(rawValue: savedPeriodUnitRaw) {
            self.periodUnit = savedPeriodUnit
        }
        if let savedBTCPrice = defaults.object(forKey: "savedInitialBTCPriceUSD") as? Double {
            self.initialBTCPriceUSD = savedBTCPrice
        }
        
        // (NEW) Currency preference
        if let storedPrefRaw = defaults.string(forKey: "currencyPreference"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            self.currencyPreference = storedPref
        } else {
            self.currencyPreference = .eur
        }
        
        // Random seed
        self.lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        let storedUseRandom = defaults.object(forKey: "useRandomSeed") as? Bool ?? true
        self.useRandomSeed = storedUseRandom
        
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        }
        if defaults.object(forKey: "useVolShocks") != nil {
            useVolShocks = defaults.bool(forKey: "useVolShocks")
        }
        
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
        
        // Load our NEW lockHistoricalSampling toggle from defaults
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            self.lockHistoricalSampling = savedLockSampling
        }
        
        isInitialized = true
        syncToggleAllState()
        
    }
}
