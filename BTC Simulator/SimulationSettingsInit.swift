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

        // 1. Prevent didSet observers from triggering during bulk updates
        self.isUpdating = true

        // 2. MARK: - Load Basic Settings

        // Lognormal Growth
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            let val = defaults.bool(forKey: "useLognormalGrowth")
            print("DEBUG: read useLognormalGrowth => \(val)")
            self.useLognormalGrowth = val
        } else {
            // If there's no stored value, default to true
            self.useLognormalGrowth = true
        }

        // Onboarding Data
        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }

        // Period Settings
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

        // Currency Preference
        if let storedPrefRaw = defaults.string(forKey: "currencyPreference"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            print("DEBUG: read currencyPreference => \(storedPref)")
            self.currencyPreference = storedPref
        } else {
            self.currencyPreference = .eur
        }

        // Random Seed
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

        // Sampling & Volatility
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            let val = defaults.bool(forKey: "useHistoricalSampling")
            print("DEBUG: read useHistoricalSampling => \(val)")
            self.useHistoricalSampling = val
        }
        if defaults.object(forKey: "useVolShocks") != nil {
            let val = defaults.bool(forKey: "useVolShocks")
            print("DEBUG: read useVolShocks => \(val)")
            self.useVolShocks = val
        }

        // GARCH Toggle
        if defaults.object(forKey: "useGarchVolatility") != nil {
            let val = defaults.bool(forKey: "useGarchVolatility")
            print("DEBUG: read useGarchVolatility => \(val)")
            self.useGarchVolatility = val
        }

        // Autocorrelation Toggles
        if defaults.object(forKey: "useAutoCorrelation") != nil {
            let storedValue = defaults.bool(forKey: "useAutoCorrelation")
            print("DEBUG: read useAutoCorrelation => \(storedValue)")
            self.useAutoCorrelation = storedValue
        }
        if defaults.object(forKey: "autoCorrelationStrength") != nil {
            let val = defaults.double(forKey: "autoCorrelationStrength")
            print("DEBUG: read autoCorrelationStrength => \(val)")
            self.autoCorrelationStrength = val
        }
        if defaults.object(forKey: "meanReversionTarget") != nil {
            let val = defaults.double(forKey: "meanReversionTarget")
            print("DEBUG: read meanReversionTarget => \(val)")
            self.meanReversionTarget = val
        }

        // Lock Historical Sampling
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            print("DEBUG: read lockHistoricalSampling => \(savedLockSampling)")
            self.lockHistoricalSampling = savedLockSampling
        }

        // 3. MARK: - Load Bullish Factors (Parent Toggles)

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

        // 4. MARK: - Load Bearish Factors (Parent Toggles)

        // Regulatory Clampdown
        if let storedRegClamp = defaults.object(forKey: "useRegClampdown") as? Bool {
            print("DEBUG: read useRegClampdown => \(storedRegClamp)")
            self.useRegClampdown = storedRegClamp
        }

        // Competitor Coin
        if let storedCompetitor = defaults.object(forKey: "useCompetitorCoin") as? Bool {
            print("DEBUG: read useCompetitorCoin => \(storedCompetitor)")
            self.useCompetitorCoin = storedCompetitor
        }

        // Security Breach
        if let storedSecBreach = defaults.object(forKey: "useSecurityBreach") as? Bool {
            print("DEBUG: read useSecurityBreach => \(storedSecBreach)")
            self.useSecurityBreach = storedSecBreach
        }

        // Bubble Pop
        if let storedBubblePop = defaults.object(forKey: "useBubblePop") as? Bool {
            print("DEBUG: read useBubblePop => \(storedBubblePop)")
            self.useBubblePop = storedBubblePop
        }

        // Stablecoin Meltdown
        if let storedStableMeltdown = defaults.object(forKey: "useStablecoinMeltdown") as? Bool {
            print("DEBUG: read useStablecoinMeltdown => \(storedStableMeltdown)")
            self.useStablecoinMeltdown = storedStableMeltdown
        }

        // Black Swan
        if let storedSwan = defaults.object(forKey: "useBlackSwan") as? Bool {
            print("DEBUG: read useBlackSwan => \(storedSwan)")
            self.useBlackSwan = storedSwan
        }

        // Bear Market
        if let storedBearMkt = defaults.object(forKey: "useBearMarket") as? Bool {
            print("DEBUG: read useBearMarket => \(storedBearMkt)")
            self.useBearMarket = storedBearMkt
        }

        // Maturing Market
        if let storedMaturing = defaults.object(forKey: "useMaturingMarket") as? Bool {
            print("DEBUG: read useMaturingMarket => \(storedMaturing)")
            self.useMaturingMarket = storedMaturing
        }

        // Recession
        if let storedRecession = defaults.object(forKey: "useRecession") as? Bool {
            print("DEBUG: read useRecession => \(storedRecession)")
            self.useRecession = storedRecession
        }

        // 5. MARK: - Load Child Toggles (Weekly/Monthly)

        // Note: Load **Child Toggles First** to ensure consistency

        // -----------------------------
        // Halving Children
        // -----------------------------
        if let storedHalvingWeekly = defaults.object(forKey: "useHalvingWeekly") as? Bool {
            self.useHalvingWeekly = storedHalvingWeekly
        }
        if let storedHalvingBumpWeekly = defaults.object(forKey: "halvingBumpWeekly") as? Double {
            self.halvingBumpWeekly = storedHalvingBumpWeekly
        }
        if let storedHalvingMonthly = defaults.object(forKey: "useHalvingMonthly") as? Bool {
            self.useHalvingMonthly = storedHalvingMonthly
        }
        if let storedHalvingBumpMonthly = defaults.object(forKey: "halvingBumpMonthly") as? Double {
            self.halvingBumpMonthly = storedHalvingBumpMonthly
        }

        // -----------------------------
        // Institutional Demand Children
        // -----------------------------
        if let storedInstWeekly = defaults.object(forKey: "useInstitutionalDemandWeekly") as? Bool {
            self.useInstitutionalDemandWeekly = storedInstWeekly
        }
        if let storedInstBoostWeekly = defaults.object(forKey: "maxDemandBoostWeekly") as? Double {
            self.maxDemandBoostWeekly = storedInstBoostWeekly
        }
        if let storedInstMonthly = defaults.object(forKey: "useInstitutionalDemandMonthly") as? Bool {
            self.useInstitutionalDemandMonthly = storedInstMonthly
        }
        if let storedInstBoostMonthly = defaults.object(forKey: "maxDemandBoostMonthly") as? Double {
            self.maxDemandBoostMonthly = storedInstBoostMonthly
        }

        // -----------------------------
        // Country Adoption Children
        // -----------------------------
        if let storedCountryWeekly = defaults.object(forKey: "useCountryAdoptionWeekly") as? Bool {
            self.useCountryAdoptionWeekly = storedCountryWeekly
        }
        if let storedCountryAdBoostWeekly = defaults.object(forKey: "maxCountryAdBoostWeekly") as? Double {
            self.maxCountryAdBoostWeekly = storedCountryAdBoostWeekly
        }
        if let storedCountryMonthly = defaults.object(forKey: "useCountryAdoptionMonthly") as? Bool {
            self.useCountryAdoptionMonthly = storedCountryMonthly
        }
        if let storedCountryAdBoostMonthly = defaults.object(forKey: "maxCountryAdBoostMonthly") as? Double {
            self.maxCountryAdBoostMonthly = storedCountryAdBoostMonthly
        }

        // -----------------------------
        // Regulatory Clarity Children
        // -----------------------------
        if let storedRegClarityWeekly = defaults.object(forKey: "useRegulatoryClarityWeekly") as? Bool {
            self.useRegulatoryClarityWeekly = storedRegClarityWeekly
        }
        if let storedMaxClarityBoostWeekly = defaults.object(forKey: "maxClarityBoostWeekly") as? Double {
            self.maxClarityBoostWeekly = storedMaxClarityBoostWeekly
        }
        if let storedRegClarityMonthly = defaults.object(forKey: "useRegulatoryClarityMonthly") as? Bool {
            self.useRegulatoryClarityMonthly = storedRegClarityMonthly
        }
        if let storedMaxClarityBoostMonthly = defaults.object(forKey: "maxClarityBoostMonthly") as? Double {
            self.maxClarityBoostMonthly = storedMaxClarityBoostMonthly
        }

        // -----------------------------
        // ETF Approval Children
        // -----------------------------
        if let storedEtfWeekly = defaults.object(forKey: "useEtfApprovalWeekly") as? Bool {
            self.useEtfApprovalWeekly = storedEtfWeekly
        }
        if let storedEtfBoostWeekly = defaults.object(forKey: "maxEtfBoostWeekly") as? Double {
            self.maxEtfBoostWeekly = storedEtfBoostWeekly
        }
        if let storedEtfMonthly = defaults.object(forKey: "useEtfApprovalMonthly") as? Bool {
            self.useEtfApprovalMonthly = storedEtfMonthly
        }
        if let storedEtfBoostMonthly = defaults.object(forKey: "maxEtfBoostMonthly") as? Double {
            self.maxEtfBoostMonthly = storedEtfBoostMonthly
        }

        // -----------------------------
        // Tech Breakthrough Children
        // -----------------------------
        if let storedTechWeekly = defaults.object(forKey: "useTechBreakthroughWeekly") as? Bool {
            self.useTechBreakthroughWeekly = storedTechWeekly
        }
        if let storedTechBoostWeekly = defaults.object(forKey: "maxTechBoostWeekly") as? Double {
            self.maxTechBoostWeekly = storedTechBoostWeekly
        }
        if let storedTechMonthly = defaults.object(forKey: "useTechBreakthroughMonthly") as? Bool {
            self.useTechBreakthroughMonthly = storedTechMonthly
        }
        if let storedTechBoostMonthly = defaults.object(forKey: "maxTechBoostMonthly") as? Double {
            self.maxTechBoostMonthly = storedTechBoostMonthly
        }

        // -----------------------------
        // Scarcity Events Children
        // -----------------------------
        if let storedScarcityWeekly = defaults.object(forKey: "useScarcityEventsWeekly") as? Bool {
            self.useScarcityEventsWeekly = storedScarcityWeekly
        }
        if let storedScarcityBoostWeekly = defaults.object(forKey: "maxScarcityBoostWeekly") as? Double {
            self.maxScarcityBoostWeekly = storedScarcityBoostWeekly
        }
        if let storedScarcityMonthly = defaults.object(forKey: "useScarcityEventsMonthly") as? Bool {
            self.useScarcityEventsMonthly = storedScarcityMonthly
        }
        if let storedScarcityBoostMonthly = defaults.object(forKey: "maxScarcityBoostMonthly") as? Double {
            self.maxScarcityBoostMonthly = storedScarcityBoostMonthly
        }

        // -----------------------------
        // Global Macro Hedge Children
        // -----------------------------
        if let storedMacroWeekly = defaults.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool {
            self.useGlobalMacroHedgeWeekly = storedMacroWeekly
        }
        if let storedMacroBoostWeekly = defaults.object(forKey: "maxMacroBoostWeekly") as? Double {
            self.maxMacroBoostWeekly = storedMacroBoostWeekly
        }
        if let storedMacroMonthly = defaults.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool {
            self.useGlobalMacroHedgeMonthly = storedMacroMonthly
        }
        if let storedMacroBoostMonthly = defaults.object(forKey: "maxMacroBoostMonthly") as? Double {
            self.maxMacroBoostMonthly = storedMacroBoostMonthly
        }

        // -----------------------------
        // Stablecoin Shift Children
        // -----------------------------
        if let storedStableWeekly = defaults.object(forKey: "useStablecoinShiftWeekly") as? Bool {
            self.useStablecoinShiftWeekly = storedStableWeekly
        }
        if let storedStableBoostWeekly = defaults.object(forKey: "maxStablecoinBoostWeekly") as? Double {
            self.maxStablecoinBoostWeekly = storedStableBoostWeekly
        }
        if let storedStableMonthly = defaults.object(forKey: "useStablecoinShiftMonthly") as? Bool {
            self.useStablecoinShiftMonthly = storedStableMonthly
        }
        if let storedStableBoostMonthly = defaults.object(forKey: "maxStablecoinBoostMonthly") as? Double {
            self.maxStablecoinBoostMonthly = storedStableBoostMonthly
        }

        // -----------------------------
        // Demographic Adoption Children
        // -----------------------------
        if let storedDemoWeekly = defaults.object(forKey: "useDemographicAdoptionWeekly") as? Bool {
            self.useDemographicAdoptionWeekly = storedDemoWeekly
        }
        if let storedDemoBoostWeekly = defaults.object(forKey: "maxDemoBoostWeekly") as? Double {
            self.maxDemoBoostWeekly = storedDemoBoostWeekly
        }
        if let storedDemoMonthly = defaults.object(forKey: "useDemographicAdoptionMonthly") as? Bool {
            self.useDemographicAdoptionMonthly = storedDemoMonthly
        }
        if let storedDemoBoostMonthly = defaults.object(forKey: "maxDemoBoostMonthly") as? Double {
            self.maxDemoBoostMonthly = storedDemoBoostMonthly
        }

        // -----------------------------
        // Altcoin Flight Children
        // -----------------------------
        if let storedAltcoinWeekly = defaults.object(forKey: "useAltcoinFlightWeekly") as? Bool {
            self.useAltcoinFlightWeekly = storedAltcoinWeekly
        }
        if let storedAltcoinBoostWeekly = defaults.object(forKey: "maxAltcoinBoostWeekly") as? Double {
            self.maxAltcoinBoostWeekly = storedAltcoinBoostWeekly
        }
        if let storedAltcoinMonthly = defaults.object(forKey: "useAltcoinFlightMonthly") as? Bool {
            self.useAltcoinFlightMonthly = storedAltcoinMonthly
        }
        if let storedAltcoinBoostMonthly = defaults.object(forKey: "maxAltcoinBoostMonthly") as? Double {
            self.maxAltcoinBoostMonthly = storedAltcoinBoostMonthly
        }

        // -----------------------------
        // Adoption Factor Children
        // -----------------------------
        if let storedAdoptionWeekly = defaults.object(forKey: "useAdoptionFactorWeekly") as? Bool {
            self.useAdoptionFactorWeekly = storedAdoptionWeekly
        }
        if let storedAdoptionFactorWeekly = defaults.object(forKey: "adoptionBaseFactorWeekly") as? Double {
            self.adoptionBaseFactorWeekly = storedAdoptionFactorWeekly
        }
        if let storedAdoptionMonthly = defaults.object(forKey: "useAdoptionFactorMonthly") as? Bool {
            self.useAdoptionFactorMonthly = storedAdoptionMonthly
        }
        if let storedAdoptionFactorMonthly = defaults.object(forKey: "adoptionBaseFactorMonthly") as? Double {
            self.adoptionBaseFactorMonthly = storedAdoptionFactorMonthly
        }

        // -----------------------------
        // MARK: - Load Bearish Factors (Child Toggles)
        // -----------------------------

        // -----------------------------
        // Regulatory Clampdown Children
        // -----------------------------
        if let storedRegClampWeekly = defaults.object(forKey: "useRegClampdownWeekly") as? Bool {
            self.useRegClampdownWeekly = storedRegClampWeekly
        }
        if let storedClampDownWeekly = defaults.object(forKey: "maxClampDownWeekly") as? Double {
            self.maxClampDownWeekly = storedClampDownWeekly
        }
        if let storedRegClampMonthly = defaults.object(forKey: "useRegClampdownMonthly") as? Bool {
            self.useRegClampdownMonthly = storedRegClampMonthly
        }
        if let storedClampDownMonthly = defaults.object(forKey: "maxClampDownMonthly") as? Double {
            self.maxClampDownMonthly = storedClampDownMonthly
        }

        // -----------------------------
        // Competitor Coin Children
        // -----------------------------
        if let storedCompetitorWeekly = defaults.object(forKey: "useCompetitorCoinWeekly") as? Bool {
            self.useCompetitorCoinWeekly = storedCompetitorWeekly
        }
        if let storedCompetitorBoostWeekly = defaults.object(forKey: "maxCompetitorBoostWeekly") as? Double {
            self.maxCompetitorBoostWeekly = storedCompetitorBoostWeekly
        }
        if let storedCompetitorMonthly = defaults.object(forKey: "useCompetitorCoinMonthly") as? Bool {
            self.useCompetitorCoinMonthly = storedCompetitorMonthly
        }
        if let storedCompetitorBoostMonthly = defaults.object(forKey: "maxCompetitorBoostMonthly") as? Double {
            self.maxCompetitorBoostMonthly = storedCompetitorBoostMonthly
        }

        // -----------------------------
        // Security Breach Children
        // -----------------------------
        if let storedBreachWeekly = defaults.object(forKey: "useSecurityBreachWeekly") as? Bool {
            self.useSecurityBreachWeekly = storedBreachWeekly
        }
        if let storedBreachImpactWeekly = defaults.object(forKey: "breachImpactWeekly") as? Double {
            self.breachImpactWeekly = storedBreachImpactWeekly
        }
        if let storedBreachMonthly = defaults.object(forKey: "useSecurityBreachMonthly") as? Bool {
            self.useSecurityBreachMonthly = storedBreachMonthly
        }
        if let storedBreachImpactMonthly = defaults.object(forKey: "breachImpactMonthly") as? Double {
            self.breachImpactMonthly = storedBreachImpactMonthly
        }

        // -----------------------------
        // Bubble Pop Children
        // -----------------------------
        if let storedBubblePopWeekly = defaults.object(forKey: "useBubblePopWeekly") as? Bool {
            self.useBubblePopWeekly = storedBubblePopWeekly
        }
        if let storedPopDropWeekly = defaults.object(forKey: "maxPopDropWeekly") as? Double {
            self.maxPopDropWeekly = storedPopDropWeekly
        }
        if let storedBubblePopMonthly = defaults.object(forKey: "useBubblePopMonthly") as? Bool {
            self.useBubblePopMonthly = storedBubblePopMonthly
        }
        if let storedPopDropMonthly = defaults.object(forKey: "maxPopDropMonthly") as? Double {
            self.maxPopDropMonthly = storedPopDropMonthly
        }

        // -----------------------------
        // Stablecoin Meltdown Children
        // -----------------------------
        if let storedMeltdownWeekly = defaults.object(forKey: "useStablecoinMeltdownWeekly") as? Bool {
            self.useStablecoinMeltdownWeekly = storedMeltdownWeekly
        }
        if let storedMeltdownDropWeekly = defaults.object(forKey: "maxMeltdownDropWeekly") as? Double {
            self.maxMeltdownDropWeekly = storedMeltdownDropWeekly
        }
        if let storedMeltdownMonthly = defaults.object(forKey: "useStablecoinMeltdownMonthly") as? Bool {
            self.useStablecoinMeltdownMonthly = storedMeltdownMonthly
        }
        if let storedMeltdownDropMonthly = defaults.object(forKey: "maxMeltdownDropMonthly") as? Double {
            self.maxMeltdownDropMonthly = storedMeltdownDropMonthly
        }

        // -----------------------------
        // Black Swan Children
        // -----------------------------
        if let storedBlackSwanWeekly = defaults.object(forKey: "useBlackSwanWeekly") as? Bool {
            self.useBlackSwanWeekly = storedBlackSwanWeekly
        }
        if let storedBlackSwanDropWeekly = defaults.object(forKey: "blackSwanDropWeekly") as? Double {
            self.blackSwanDropWeekly = storedBlackSwanDropWeekly
        }
        if let storedBlackSwanMonthly = defaults.object(forKey: "useBlackSwanMonthly") as? Bool {
            self.useBlackSwanMonthly = storedBlackSwanMonthly
        }
        if let storedBlackSwanDropMonthly = defaults.object(forKey: "blackSwanDropMonthly") as? Double {
            self.blackSwanDropMonthly = storedBlackSwanDropMonthly
        }

        // -----------------------------
        // Bear Market Children
        // -----------------------------
        if let storedBearWeekly = defaults.object(forKey: "useBearMarketWeekly") as? Bool {
            self.useBearMarketWeekly = storedBearWeekly
        }
        if let storedBearWeeklyDriftWeekly = defaults.object(forKey: "bearWeeklyDriftWeekly") as? Double {
            self.bearWeeklyDriftWeekly = storedBearWeeklyDriftWeekly
        }
        if let storedBearMonthly = defaults.object(forKey: "useBearMarketMonthly") as? Bool {
            self.useBearMarketMonthly = storedBearMonthly
        }
        if let storedBearWeeklyDriftMonthly = defaults.object(forKey: "bearWeeklyDriftMonthly") as? Double {
            self.bearWeeklyDriftMonthly = storedBearWeeklyDriftMonthly
        }

        // -----------------------------
        // Maturing Market Children
        // -----------------------------
        if let storedMaturingWeekly = defaults.object(forKey: "useMaturingMarketWeekly") as? Bool {
            self.useMaturingMarketWeekly = storedMaturingWeekly
        }
        if let storedMaxMaturingDropWeekly = defaults.object(forKey: "maxMaturingDropWeekly") as? Double {
            self.maxMaturingDropWeekly = storedMaxMaturingDropWeekly
        }
        if let storedMaturingMonthly = defaults.object(forKey: "useMaturingMarketMonthly") as? Bool {
            self.useMaturingMarketMonthly = storedMaturingMonthly
        }
        if let storedMaxMaturingDropMonthly = defaults.object(forKey: "maxMaturingDropMonthly") as? Double {
            self.maxMaturingDropMonthly = storedMaxMaturingDropMonthly
        }

        // -----------------------------
        // Recession Children
        // -----------------------------
        if let storedRecessionWeekly = defaults.object(forKey: "useRecessionWeekly") as? Bool {
            self.useRecessionWeekly = storedRecessionWeekly
        }
        if let storedRecessionDropWeekly = defaults.object(forKey: "maxRecessionDropWeekly") as? Double {
            self.maxRecessionDropWeekly = storedRecessionDropWeekly
        }
        if let storedRecessionMonthly = defaults.object(forKey: "useRecessionMonthly") as? Bool {
            self.useRecessionMonthly = storedRecessionMonthly
        }
        if let storedRecessionDropMonthly = defaults.object(forKey: "maxRecessionDropMonthly") as? Double {
            self.maxRecessionDropMonthly = storedRecessionDropMonthly
        }

        // 6. MARK: - Finalize Initialization

        // Allow didSet observers to trigger again
        self.isUpdating = false

        // Mark initialization as complete
        self.isInitialized = true

        // Sync the master toggle based on all factors
        self.syncToggleAllState()

        // 7. MARK: - Set Default States on First Launch
        // Detect if it's the first launch by checking a specific key
        if defaults.object(forKey: "hasLaunchedBefore") == nil {
            print("DEBUG: First launch detected. Setting default toggles.")
            defaults.set(true, forKey: "hasLaunchedBefore")

            // Now, turn all factors on with weekly children on
            self.isUpdating = true
            self.toggleAll = true  // Assuming toggleAll's didSet handles setting children
            self.isUpdating = false

            // Sync again after setting toggleAll
            self.syncToggleAllState()
        }
    }
}
