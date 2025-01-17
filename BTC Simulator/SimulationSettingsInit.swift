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
        // Removed: self.halvingBump = ...
        // If you want to migrate, do so here manually:
        // if defaults.object(forKey: "halvingBump") != nil {
        //     let oldVal = defaults.double(forKey: "halvingBump")
        //     // e.g. halvingBumpWeekly = oldVal
        // }

        if let storedInstitutional = defaults.object(forKey: "useInstitutionalDemand") as? Bool {
            self.useInstitutionalDemand = storedInstitutional
        }
        // Removed: self.maxDemandBoost = ...
        
        if let storedCountry = defaults.object(forKey: "useCountryAdoption") as? Bool {
            self.useCountryAdoption = storedCountry
        }
        // Removed: self.maxCountryAdBoost = ...
        
        if let storedRegClarity = defaults.object(forKey: "useRegulatoryClarity") as? Bool {
            self.useRegulatoryClarity = storedRegClarity
        }
        // Removed: self.maxClarityBoost = ...
        
        if let storedEtf = defaults.object(forKey: "useEtfApproval") as? Bool {
            self.useEtfApproval = storedEtf
        }
        // Removed: self.maxEtfBoost = ...
        
        if let storedTech = defaults.object(forKey: "useTechBreakthrough") as? Bool {
            self.useTechBreakthrough = storedTech
        }
        // Removed: self.maxTechBoost = ...
        
        if let storedScarcity = defaults.object(forKey: "useScarcityEvents") as? Bool {
            self.useScarcityEvents = storedScarcity
        }
        // Removed: self.maxScarcityBoost = ...
        
        if let storedMacro = defaults.object(forKey: "useGlobalMacroHedge") as? Bool {
            self.useGlobalMacroHedge = storedMacro
        }
        // Removed: self.maxMacroBoost = ...
        
        if let storedStableShift = defaults.object(forKey: "useStablecoinShift") as? Bool {
            self.useStablecoinShift = storedStableShift
        }
        // Removed: self.maxStablecoinBoost = ...
        
        if let storedDemo = defaults.object(forKey: "useDemographicAdoption") as? Bool {
            self.useDemographicAdoption = storedDemo
        }
        // Removed: self.maxDemoBoost = ...
        
        if let storedAltcoinFlight = defaults.object(forKey: "useAltcoinFlight") as? Bool {
            self.useAltcoinFlight = storedAltcoinFlight
        }
        // Removed: self.maxAltcoinBoost = ...
        
        if let storedAdoption = defaults.object(forKey: "useAdoptionFactor") as? Bool {
            self.useAdoptionFactor = storedAdoption
        }
        // Removed: self.adoptionBaseFactor = ...
        
        // BEARISH FACTORS
        if let storedRegClamp = defaults.object(forKey: "useRegClampdown") as? Bool {
            self.useRegClampdown = storedRegClamp
        }
        // Removed: self.maxClampDown = ...
        
        if let storedCompetitor = defaults.object(forKey: "useCompetitorCoin") as? Bool {
            self.useCompetitorCoin = storedCompetitor
        }
        // Removed: self.maxCompetitorBoost = ...
        
        if let storedSecBreach = defaults.object(forKey: "useSecurityBreach") as? Bool {
            self.useSecurityBreach = storedSecBreach
        }
        // Removed: self.breachImpact = ...
        
        if let storedBubblePop = defaults.object(forKey: "useBubblePop") as? Bool {
            self.useBubblePop = storedBubblePop
        }
        // Removed: self.maxPopDrop = ...
        
        if let storedStableMeltdown = defaults.object(forKey: "useStablecoinMeltdown") as? Bool {
            self.useStablecoinMeltdown = storedStableMeltdown
        }
        // Removed: self.maxMeltdownDrop = ...
        
        if let storedSwan = defaults.object(forKey: "useBlackSwan") as? Bool {
            self.useBlackSwan = storedSwan
        }
        // Removed: self.blackSwanDrop = ...
        
        if let storedBearMkt = defaults.object(forKey: "useBearMarket") as? Bool {
            self.useBearMarket = storedBearMkt
        }
        // Removed: self.bearWeeklyDrift = ...
        
        if let storedMaturing = defaults.object(forKey: "useMaturingMarket") as? Bool {
            self.useMaturingMarket = storedMaturing
        }
        // Removed: self.maxMaturingDrop = ...
        
        if let storedRecession = defaults.object(forKey: "useRecession") as? Bool {
            self.useRecession = storedRecession
        }
        // Removed: self.maxRecessionDrop = ...
        
        // Load our NEW lockHistoricalSampling toggle from defaults
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            self.lockHistoricalSampling = savedLockSampling
        }
        
        isInitialized = true
        syncToggleAllState()
    }
}
