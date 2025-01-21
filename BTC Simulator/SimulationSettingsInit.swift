//
//  SimulationSettingsInit.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    convenience init(loadDefaults: Bool = true) {
        self.init()  // Calls the minimal init in SimulationSettings.swift
        guard loadDefaults else { return }

        let defaults = UserDefaults.standard

        // (A) Load any stored boolean for useLognormalGrowth (if it exists)
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            let val = defaults.bool(forKey: "useLognormalGrowth")
            print("DEBUG: read useLognormalGrowth => \(val)")
            useLognormalGrowth = val
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
            print("DEBUG: read currencyPreference => \(storedPref)")
            self.currencyPreference = storedPref
        } else {
            self.currencyPreference = .eur
        }

        // Random seed
        let lockedSeedVal = defaults.bool(forKey: "lockedRandomSeed")
        print("DEBUG: read lockedRandomSeed => \(lockedSeedVal)")
        self.lockedRandomSeed = lockedSeedVal

        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            print("DEBUG: read seedValue => \(storedSeed)")
            self.seedValue = storedSeed
        }
        let storedUseRandom = defaults.object(forKey: "useRandomSeed") as? Bool ?? true
        print("DEBUG: read useRandomSeed => \(storedUseRandom)")
        self.useRandomSeed = storedUseRandom

        if defaults.object(forKey: "useHistoricalSampling") != nil {
            let val = defaults.bool(forKey: "useHistoricalSampling")
            print("DEBUG: read useHistoricalSampling => \(val)")
            useHistoricalSampling = val
        }
        if defaults.object(forKey: "useVolShocks") != nil {
            let val = defaults.bool(forKey: "useVolShocks")
            print("DEBUG: read useVolShocks => \(val)")
            useVolShocks = val
        }

        // GARCH toggle (if it exists)
        if defaults.object(forKey: "useGarchVolatility") != nil {
            let val = defaults.bool(forKey: "useGarchVolatility")
            print("DEBUG: read useGarchVolatility => \(val)")
            useGarchVolatility = val
        }

        // --- LOAD AUTOCORRELATION TOGGLES ---
        if defaults.object(forKey: "useAutoCorrelation") != nil {
            let storedValue = defaults.bool(forKey: "useAutoCorrelation")
            print("DEBUG: read useAutoCorrelation => \(storedValue)")
            self.useAutoCorrelation = storedValue
        }
        if defaults.object(forKey: "autoCorrelationStrength") != nil {
            let val = defaults.double(forKey: "autoCorrelationStrength")
            print("DEBUG: read autoCorrelationStrength => \(val)")
            autoCorrelationStrength = val
        }
        if defaults.object(forKey: "meanReversionTarget") != nil {
            let val = defaults.double(forKey: "meanReversionTarget")
            print("DEBUG: read meanReversionTarget => \(val)")
            meanReversionTarget = val
        }

        // Load our lockHistoricalSampling toggle
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            print("DEBUG: read lockHistoricalSampling => \(savedLockSampling)")
            self.lockHistoricalSampling = savedLockSampling
        }

        // -----------------------------
        // BULLISH FACTORS (Parent toggles)
        // -----------------------------

        // Halving
        if let storedHalving = defaults.object(forKey: "useHalving") as? Bool {
            print("DEBUG: read useHalving => \(storedHalving)")
            self.useHalving = storedHalving
        }
        // Institutional Demand
        if let storedInstitutional = defaults.object(forKey: "useInstitutionalDemand") as? Bool {
            print("DEBUG: read useInstitutionalDemand => \(storedInstitutional)")
            self.useInstitutionalDemand = storedInstitutional
        }
        // Country Adoption
        if let storedCountry = defaults.object(forKey: "useCountryAdoption") as? Bool {
            print("DEBUG: read useCountryAdoption => \(storedCountry)")
            self.useCountryAdoption = storedCountry
        }
        // Regulatory Clarity
        if let storedRegClarity = defaults.object(forKey: "useRegulatoryClarity") as? Bool {
            print("DEBUG: read useRegulatoryClarity => \(storedRegClarity)")
            self.useRegulatoryClarity = storedRegClarity
        }
        // ETF Approval
        if let storedEtf = defaults.object(forKey: "useEtfApproval") as? Bool {
            print("DEBUG: read useEtfApproval => \(storedEtf)")
            self.useEtfApproval = storedEtf
        }
        // Tech Breakthrough
        if let storedTech = defaults.object(forKey: "useTechBreakthrough") as? Bool {
            print("DEBUG: read useTechBreakthrough => \(storedTech)")
            self.useTechBreakthrough = storedTech
        }
        // Scarcity Events
        if let storedScarcity = defaults.object(forKey: "useScarcityEvents") as? Bool {
            print("DEBUG: read useScarcityEvents => \(storedScarcity)")
            self.useScarcityEvents = storedScarcity
        }
        // Global Macro Hedge
        if let storedMacro = defaults.object(forKey: "useGlobalMacroHedge") as? Bool {
            print("DEBUG: read useGlobalMacroHedge => \(storedMacro)")
            self.useGlobalMacroHedge = storedMacro
        }
        // Stablecoin Shift
        if let storedStableShift = defaults.object(forKey: "useStablecoinShift") as? Bool {
            print("DEBUG: read useStablecoinShift => \(storedStableShift)")
            self.useStablecoinShift = storedStableShift
        }
        // Demographic Adoption
        if let storedDemo = defaults.object(forKey: "useDemographicAdoption") as? Bool {
            print("DEBUG: read useDemographicAdoption => \(storedDemo)")
            self.useDemographicAdoption = storedDemo
        }
        // Altcoin Flight
        if let storedAltcoinFlight = defaults.object(forKey: "useAltcoinFlight") as? Bool {
            print("DEBUG: read useAltcoinFlight => \(storedAltcoinFlight)")
            self.useAltcoinFlight = storedAltcoinFlight
        }
        // Adoption Factor
        if let storedAdoption = defaults.object(forKey: "useAdoptionFactor") as? Bool {
            print("DEBUG: read useAdoptionFactor => \(storedAdoption)")
            self.useAdoptionFactor = storedAdoption
        }

        // -----------------------------
        // BEARISH FACTORS (Parent toggles)
        // -----------------------------
        if let storedRegClamp = defaults.object(forKey: "useRegClampdown") as? Bool {
            print("DEBUG: read useRegClampdown => \(storedRegClamp)")
            self.useRegClampdown = storedRegClamp
        }
        if let storedCompetitor = defaults.object(forKey: "useCompetitorCoin") as? Bool {
            print("DEBUG: read useCompetitorCoin => \(storedCompetitor)")
            self.useCompetitorCoin = storedCompetitor
        }
        if let storedSecBreach = defaults.object(forKey: "useSecurityBreach") as? Bool {
            print("DEBUG: read useSecurityBreach => \(storedSecBreach)")
            self.useSecurityBreach = storedSecBreach
        }
        if let storedBubblePop = defaults.object(forKey: "useBubblePop") as? Bool {
            print("DEBUG: read useBubblePop => \(storedBubblePop)")
            self.useBubblePop = storedBubblePop
        }
        if let storedStableMeltdown = defaults.object(forKey: "useStablecoinMeltdown") as? Bool {
            print("DEBUG: read useStablecoinMeltdown => \(storedStableMeltdown)")
            self.useStablecoinMeltdown = storedStableMeltdown
        }
        if let storedSwan = defaults.object(forKey: "useBlackSwan") as? Bool {
            print("DEBUG: read useBlackSwan => \(storedSwan)")
            self.useBlackSwan = storedSwan
        }
        if let storedBearMkt = defaults.object(forKey: "useBearMarket") as? Bool {
            print("DEBUG: read useBearMarket => \(storedBearMkt)")
            self.useBearMarket = storedBearMkt
        }
        if let storedMaturing = defaults.object(forKey: "useMaturingMarket") as? Bool {
            print("DEBUG: read useMaturingMarket => \(storedMaturing)")
            self.useMaturingMarket = storedMaturing
        }
        if let storedRecession = defaults.object(forKey: "useRecession") as? Bool {
            print("DEBUG: read useRecession => \(storedRecession)")
            self.useRecession = storedRecession
        }

        // -----------------------------
        // NOW LOAD CHILD TOGGLES (Weekly/Monthly)
        // -----------------------------

        // HALVING
        if let storedHalvingWeekly = defaults.object(forKey: "useHalvingWeekly") as? Bool {
            useHalvingWeekly = storedHalvingWeekly
        }
        if let storedHalvingBumpWeekly = defaults.object(forKey: "halvingBumpWeekly") as? Double {
            halvingBumpWeekly = storedHalvingBumpWeekly
        }
        if let storedHalvingMonthly = defaults.object(forKey: "useHalvingMonthly") as? Bool {
            useHalvingMonthly = storedHalvingMonthly
        }
        if let storedHalvingBumpMonthly = defaults.object(forKey: "halvingBumpMonthly") as? Double {
            halvingBumpMonthly = storedHalvingBumpMonthly
        }

        // INSTITUTIONAL DEMAND
        if let storedInstWeekly = defaults.object(forKey: "useInstitutionalDemandWeekly") as? Bool {
            useInstitutionalDemandWeekly = storedInstWeekly
        }
        if let storedInstBoostWeekly = defaults.object(forKey: "maxDemandBoostWeekly") as? Double {
            maxDemandBoostWeekly = storedInstBoostWeekly
        }
        if let storedInstMonthly = defaults.object(forKey: "useInstitutionalDemandMonthly") as? Bool {
            useInstitutionalDemandMonthly = storedInstMonthly
        }
        if let storedInstBoostMonthly = defaults.object(forKey: "maxDemandBoostMonthly") as? Double {
            maxDemandBoostMonthly = storedInstBoostMonthly
        }

        // COUNTRY ADOPTION
        if let storedCountryWeekly = defaults.object(forKey: "useCountryAdoptionWeekly") as? Bool {
            useCountryAdoptionWeekly = storedCountryWeekly
        }
        if let storedCountryAdBoostWeekly = defaults.object(forKey: "maxCountryAdBoostWeekly") as? Double {
            maxCountryAdBoostWeekly = storedCountryAdBoostWeekly
        }
        if let storedCountryMonthly = defaults.object(forKey: "useCountryAdoptionMonthly") as? Bool {
            useCountryAdoptionMonthly = storedCountryMonthly
        }
        if let storedCountryAdBoostMonthly = defaults.object(forKey: "maxCountryAdBoostMonthly") as? Double {
            maxCountryAdBoostMonthly = storedCountryAdBoostMonthly
        }

        // REGULATORY CLARITY
        if let storedRegClarityWeekly = defaults.object(forKey: "useRegulatoryClarityWeekly") as? Bool {
            useRegulatoryClarityWeekly = storedRegClarityWeekly
        }
        if let storedMaxClarityBoostWeekly = defaults.object(forKey: "maxClarityBoostWeekly") as? Double {
            maxClarityBoostWeekly = storedMaxClarityBoostWeekly
        }
        if let storedRegClarityMonthly = defaults.object(forKey: "useRegulatoryClarityMonthly") as? Bool {
            useRegulatoryClarityMonthly = storedRegClarityMonthly
        }
        if let storedMaxClarityBoostMonthly = defaults.object(forKey: "maxClarityBoostMonthly") as? Double {
            maxClarityBoostMonthly = storedMaxClarityBoostMonthly
        }

        // ETF APPROVAL
        if let storedEtfWeekly = defaults.object(forKey: "useEtfApprovalWeekly") as? Bool {
            useEtfApprovalWeekly = storedEtfWeekly
        }
        if let storedEtfBoostWeekly = defaults.object(forKey: "maxEtfBoostWeekly") as? Double {
            maxEtfBoostWeekly = storedEtfBoostWeekly
        }
        if let storedEtfMonthly = defaults.object(forKey: "useEtfApprovalMonthly") as? Bool {
            useEtfApprovalMonthly = storedEtfMonthly
        }
        if let storedEtfBoostMonthly = defaults.object(forKey: "maxEtfBoostMonthly") as? Double {
            maxEtfBoostMonthly = storedEtfBoostMonthly
        }

        // TECH BREAKTHROUGH
        if let storedTechWeekly = defaults.object(forKey: "useTechBreakthroughWeekly") as? Bool {
            useTechBreakthroughWeekly = storedTechWeekly
        }
        if let storedTechBoostWeekly = defaults.object(forKey: "maxTechBoostWeekly") as? Double {
            maxTechBoostWeekly = storedTechBoostWeekly
        }
        if let storedTechMonthly = defaults.object(forKey: "useTechBreakthroughMonthly") as? Bool {
            useTechBreakthroughMonthly = storedTechMonthly
        }
        if let storedTechBoostMonthly = defaults.object(forKey: "maxTechBoostMonthly") as? Double {
            maxTechBoostMonthly = storedTechBoostMonthly
        }

        // SCARCITY EVENTS
        if let storedScarcityWeekly = defaults.object(forKey: "useScarcityEventsWeekly") as? Bool {
            useScarcityEventsWeekly = storedScarcityWeekly
        }
        if let storedScarcityBoostWeekly = defaults.object(forKey: "maxScarcityBoostWeekly") as? Double {
            maxScarcityBoostWeekly = storedScarcityBoostWeekly
        }
        if let storedScarcityMonthly = defaults.object(forKey: "useScarcityEventsMonthly") as? Bool {
            useScarcityEventsMonthly = storedScarcityMonthly
        }
        if let storedScarcityBoostMonthly = defaults.object(forKey: "maxScarcityBoostMonthly") as? Double {
            maxScarcityBoostMonthly = storedScarcityBoostMonthly
        }

        // GLOBAL MACRO HEDGE
        if let storedMacroWeekly = defaults.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool {
            useGlobalMacroHedgeWeekly = storedMacroWeekly
        }
        if let storedMacroBoostWeekly = defaults.object(forKey: "maxMacroBoostWeekly") as? Double {
            maxMacroBoostWeekly = storedMacroBoostWeekly
        }
        if let storedMacroMonthly = defaults.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool {
            useGlobalMacroHedgeMonthly = storedMacroMonthly
        }
        if let storedMacroBoostMonthly = defaults.object(forKey: "maxMacroBoostMonthly") as? Double {
            maxMacroBoostMonthly = storedMacroBoostMonthly
        }

        // STABLECOIN SHIFT
        if let storedStableWeekly = defaults.object(forKey: "useStablecoinShiftWeekly") as? Bool {
            useStablecoinShiftWeekly = storedStableWeekly
        }
        if let storedStableBoostWeekly = defaults.object(forKey: "maxStablecoinBoostWeekly") as? Double {
            maxStablecoinBoostWeekly = storedStableBoostWeekly
        }
        if let storedStableMonthly = defaults.object(forKey: "useStablecoinShiftMonthly") as? Bool {
            useStablecoinShiftMonthly = storedStableMonthly
        }
        if let storedStableBoostMonthly = defaults.object(forKey: "maxStablecoinBoostMonthly") as? Double {
            maxStablecoinBoostMonthly = storedStableBoostMonthly
        }

        // DEMOGRAPHIC ADOPTION
        if let storedDemoWeekly = defaults.object(forKey: "useDemographicAdoptionWeekly") as? Bool {
            useDemographicAdoptionWeekly = storedDemoWeekly
        }
        if let storedDemoBoostWeekly = defaults.object(forKey: "maxDemoBoostWeekly") as? Double {
            maxDemoBoostWeekly = storedDemoBoostWeekly
        }
        if let storedDemoMonthly = defaults.object(forKey: "useDemographicAdoptionMonthly") as? Bool {
            useDemographicAdoptionMonthly = storedDemoMonthly
        }
        if let storedDemoBoostMonthly = defaults.object(forKey: "maxDemoBoostMonthly") as? Double {
            maxDemoBoostMonthly = storedDemoBoostMonthly
        }

        // ALTCOIN FLIGHT
        if let storedAltcoinWeekly = defaults.object(forKey: "useAltcoinFlightWeekly") as? Bool {
            useAltcoinFlightWeekly = storedAltcoinWeekly
        }
        if let storedAltcoinBoostWeekly = defaults.object(forKey: "maxAltcoinBoostWeekly") as? Double {
            maxAltcoinBoostWeekly = storedAltcoinBoostWeekly
        }
        if let storedAltcoinMonthly = defaults.object(forKey: "useAltcoinFlightMonthly") as? Bool {
            useAltcoinFlightMonthly = storedAltcoinMonthly
        }
        if let storedAltcoinBoostMonthly = defaults.object(forKey: "maxAltcoinBoostMonthly") as? Double {
            maxAltcoinBoostMonthly = storedAltcoinBoostMonthly
        }

        // ADOPTION FACTOR
        if let storedAdoptionWeekly = defaults.object(forKey: "useAdoptionFactorWeekly") as? Bool {
            useAdoptionFactorWeekly = storedAdoptionWeekly
        }
        if let storedAdoptionFactorWeekly = defaults.object(forKey: "adoptionBaseFactorWeekly") as? Double {
            adoptionBaseFactorWeekly = storedAdoptionFactorWeekly
        }
        if let storedAdoptionMonthly = defaults.object(forKey: "useAdoptionFactorMonthly") as? Bool {
            useAdoptionFactorMonthly = storedAdoptionMonthly
        }
        if let storedAdoptionFactorMonthly = defaults.object(forKey: "adoptionBaseFactorMonthly") as? Double {
            adoptionBaseFactorMonthly = storedAdoptionFactorMonthly
        }

        // -----------------------------
        // BEARISH FACTOR CHILD TOGGLES
        // -----------------------------

        // REGULATORY CLAMPDOWN
        if let storedRegClampWeekly = defaults.object(forKey: "useRegClampdownWeekly") as? Bool {
            useRegClampdownWeekly = storedRegClampWeekly
        }
        if let storedClampDownWeekly = defaults.object(forKey: "maxClampDownWeekly") as? Double {
            maxClampDownWeekly = storedClampDownWeekly
        }
        if let storedRegClampMonthly = defaults.object(forKey: "useRegClampdownMonthly") as? Bool {
            useRegClampdownMonthly = storedRegClampMonthly
        }
        if let storedClampDownMonthly = defaults.object(forKey: "maxClampDownMonthly") as? Double {
            maxClampDownMonthly = storedClampDownMonthly
        }

        // COMPETITOR COIN
        if let storedCompetitorWeekly = defaults.object(forKey: "useCompetitorCoinWeekly") as? Bool {
            useCompetitorCoinWeekly = storedCompetitorWeekly
        }
        if let storedCompetitorBoostWeekly = defaults.object(forKey: "maxCompetitorBoostWeekly") as? Double {
            maxCompetitorBoostWeekly = storedCompetitorBoostWeekly
        }
        if let storedCompetitorMonthly = defaults.object(forKey: "useCompetitorCoinMonthly") as? Bool {
            useCompetitorCoinMonthly = storedCompetitorMonthly
        }
        if let storedCompetitorBoostMonthly = defaults.object(forKey: "maxCompetitorBoostMonthly") as? Double {
            maxCompetitorBoostMonthly = storedCompetitorBoostMonthly
        }

        // SECURITY BREACH
        if let storedBreachWeekly = defaults.object(forKey: "useSecurityBreachWeekly") as? Bool {
            useSecurityBreachWeekly = storedBreachWeekly
        }
        if let storedBreachImpactWeekly = defaults.object(forKey: "breachImpactWeekly") as? Double {
            breachImpactWeekly = storedBreachImpactWeekly
        }
        if let storedBreachMonthly = defaults.object(forKey: "useSecurityBreachMonthly") as? Bool {
            useSecurityBreachMonthly = storedBreachMonthly
        }
        if let storedBreachImpactMonthly = defaults.object(forKey: "breachImpactMonthly") as? Double {
            breachImpactMonthly = storedBreachImpactMonthly
        }

        // BUBBLE POP
        if let storedBubblePopWeekly = defaults.object(forKey: "useBubblePopWeekly") as? Bool {
            useBubblePopWeekly = storedBubblePopWeekly
        }
        if let storedPopDropWeekly = defaults.object(forKey: "maxPopDropWeekly") as? Double {
            maxPopDropWeekly = storedPopDropWeekly
        }
        if let storedBubblePopMonthly = defaults.object(forKey: "useBubblePopMonthly") as? Bool {
            useBubblePopMonthly = storedBubblePopMonthly
        }
        if let storedPopDropMonthly = defaults.object(forKey: "maxPopDropMonthly") as? Double {
            maxPopDropMonthly = storedPopDropMonthly
        }

        // STABLECOIN MELTDOWN
        if let storedMeltdownWeekly = defaults.object(forKey: "useStablecoinMeltdownWeekly") as? Bool {
            useStablecoinMeltdownWeekly = storedMeltdownWeekly
        }
        if let storedMeltdownDropWeekly = defaults.object(forKey: "maxMeltdownDropWeekly") as? Double {
            maxMeltdownDropWeekly = storedMeltdownDropWeekly
        }
        if let storedMeltdownMonthly = defaults.object(forKey: "useStablecoinMeltdownMonthly") as? Bool {
            useStablecoinMeltdownMonthly = storedMeltdownMonthly
        }
        if let storedMeltdownDropMonthly = defaults.object(forKey: "maxMeltdownDropMonthly") as? Double {
            maxMeltdownDropMonthly = storedMeltdownDropMonthly
        }

        // BLACK SWAN
        if let storedBlackSwanWeekly = defaults.object(forKey: "useBlackSwanWeekly") as? Bool {
            useBlackSwanWeekly = storedBlackSwanWeekly
        }
        if let storedBlackSwanDropWeekly = defaults.object(forKey: "blackSwanDropWeekly") as? Double {
            blackSwanDropWeekly = storedBlackSwanDropWeekly
        }
        if let storedBlackSwanMonthly = defaults.object(forKey: "useBlackSwanMonthly") as? Bool {
            useBlackSwanMonthly = storedBlackSwanMonthly
        }
        if let storedBlackSwanDropMonthly = defaults.object(forKey: "blackSwanDropMonthly") as? Double {
            blackSwanDropMonthly = storedBlackSwanDropMonthly
        }

        // BEAR MARKET
        if let storedBearWeekly = defaults.object(forKey: "useBearMarketWeekly") as? Bool {
            useBearMarketWeekly = storedBearWeekly
        }
        if let storedBearWeeklyDriftWeekly = defaults.object(forKey: "bearWeeklyDriftWeekly") as? Double {
            bearWeeklyDriftWeekly = storedBearWeeklyDriftWeekly
        }
        if let storedBearMonthly = defaults.object(forKey: "useBearMarketMonthly") as? Bool {
            useBearMarketMonthly = storedBearMonthly
        }
        if let storedBearWeeklyDriftMonthly = defaults.object(forKey: "bearWeeklyDriftMonthly") as? Double {
            bearWeeklyDriftMonthly = storedBearWeeklyDriftMonthly
        }

        // MATURING MARKET
        if let storedMaturingWeekly = defaults.object(forKey: "useMaturingMarketWeekly") as? Bool {
            useMaturingMarketWeekly = storedMaturingWeekly
        }
        if let storedMaxMaturingDropWeekly = defaults.object(forKey: "maxMaturingDropWeekly") as? Double {
            maxMaturingDropWeekly = storedMaxMaturingDropWeekly
        }
        if let storedMaturingMonthly = defaults.object(forKey: "useMaturingMarketMonthly") as? Bool {
            useMaturingMarketMonthly = storedMaturingMonthly
        }
        if let storedMaxMaturingDropMonthly = defaults.object(forKey: "maxMaturingDropMonthly") as? Double {
            maxMaturingDropMonthly = storedMaxMaturingDropMonthly
        }

        // RECESSION
        if let storedRecessionWeekly = defaults.object(forKey: "useRecessionWeekly") as? Bool {
            useRecessionWeekly = storedRecessionWeekly
        }
        if let storedRecessionDropWeekly = defaults.object(forKey: "maxRecessionDropWeekly") as? Double {
            maxRecessionDropWeekly = storedRecessionDropWeekly
        }
        if let storedRecessionMonthly = defaults.object(forKey: "useRecessionMonthly") as? Bool {
            useRecessionMonthly = storedRecessionMonthly
        }
        if let storedRecessionDropMonthly = defaults.object(forKey: "maxRecessionDropMonthly") as? Double {
            maxRecessionDropMonthly = storedRecessionDropMonthly
        }

        // Mark initialization done
        isInitialized = true

        // Sync toggles (will update toggleAll if needed)
        syncToggleAllState()
    }
}
