//
//  SimulationSettingsInit.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    convenience init(loadDefaults: Bool = true) {
        self.init()
        guard loadDefaults else { return }

        let defaults = UserDefaults.standard
        self.isUpdating = true  // stop didSet spam during init

        print("** SimulationSettingsInit: Reading from UserDefaults...")

        // =========================================================
        // BASIC EXAMPLE PROPERTIES
        // =========================================================

        if defaults.object(forKey: "useLognormalGrowth") != nil {
            self.useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        } else {
            self.useLognormalGrowth = true
        }
        print("Loaded useLognormalGrowth = \(useLognormalGrowth)")

        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
            print("Loaded savedStartingBalance = \(savedBal)")
        }

        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
            print("Loaded savedAverageCostBasis = \(savedACB)")
        }

        // Period & Price
        if let savedPeriods = defaults.object(forKey: "savedUserPeriods") as? Int {
            self.userPeriods = savedPeriods
            print("Loaded savedUserPeriods = \(savedPeriods)")
        }

        if let savedPeriodUnitRaw = defaults.string(forKey: "savedPeriodUnit"),
           let savedPeriodUnit = PeriodUnit(rawValue: savedPeriodUnitRaw) {
            self.periodUnit = savedPeriodUnit
            print("Loaded periodUnit = \(savedPeriodUnit)")
        }

        if let savedBTCPrice = defaults.object(forKey: "savedInitialBTCPriceUSD") as? Double {
            self.initialBTCPriceUSD = savedBTCPrice
            print("Loaded savedInitialBTCPriceUSD = \(savedBTCPrice)")
        }

        // Currency
        if let storedPrefRaw = defaults.string(forKey: "currencyPreference"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            self.currencyPreference = storedPref
            print("Loaded currencyPreference = \(storedPref)")
        } else {
            self.currencyPreference = .eur
            print("No stored currencyPreference, defaulting to .eur")
        }

        // Random seed
        self.lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        print("Loaded lockedRandomSeed = \(lockedRandomSeed)")

        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
            print("Loaded seedValue = \(storedSeed)")
        }

        self.useRandomSeed = defaults.object(forKey: "useRandomSeed") as? Bool ?? true
        print("Loaded useRandomSeed = \(useRandomSeed)")

        // Sampling & Vol
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            self.useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        } else {
            self.useHistoricalSampling = true
        }
        print("Loaded useHistoricalSampling = \(useHistoricalSampling)")

        if defaults.object(forKey: "useVolShocks") != nil {
            self.useVolShocks = defaults.bool(forKey: "useVolShocks")
        } else {
            self.useVolShocks = true
        }
        print("Loaded useVolShocks = \(useVolShocks)")

        if defaults.object(forKey: "useGarchVolatility") != nil {
            self.useGarchVolatility = defaults.bool(forKey: "useGarchVolatility")
        } else {
            self.useGarchVolatility = true
        }
        print("Loaded useGarchVolatility = \(useGarchVolatility)")

        // Autocorrelation
        if defaults.object(forKey: "useAutoCorrelation") != nil {
            self.useAutoCorrelation = defaults.bool(forKey: "useAutoCorrelation")
        }
        print("Loaded useAutoCorrelation = \(useAutoCorrelation)")

        if defaults.object(forKey: "autoCorrelationStrength") != nil {
            self.autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        }
        print("Loaded autoCorrelationStrength = \(autoCorrelationStrength)")

        if defaults.object(forKey: "meanReversionTarget") != nil {
            self.meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        }
        print("Loaded meanReversionTarget = \(meanReversionTarget)")

        // Lock sampling
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            self.lockHistoricalSampling = savedLockSampling
        }
        print("Loaded lockHistoricalSampling = \(lockHistoricalSampling)")

        // =========================================================
        // BULLISH FACTORS (Weekly & Monthly)
        // =========================================================

        // Halving
        if let val = defaults.object(forKey: "useHalvingWeekly") as? Bool {
            self.useHalvingWeekly = val
        }
        print("Loaded useHalvingWeekly = \(useHalvingWeekly)")

        if let val = defaults.object(forKey: "halvingBumpWeekly") as? Double {
            self.halvingBumpWeekly = val
        } else {
            self.halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly
        }
        print("Loaded halvingBumpWeekly = \(halvingBumpWeekly)")

        if let val = defaults.object(forKey: "useHalvingMonthly") as? Bool {
            self.useHalvingMonthly = val
        }
        print("Loaded useHalvingMonthly = \(useHalvingMonthly)")

        if let val = defaults.object(forKey: "halvingBumpMonthly") as? Double {
            self.halvingBumpMonthly = val
        } else {
            self.halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly
        }
        print("Loaded halvingBumpMonthly = \(halvingBumpMonthly)")

        // Institutional Demand
        if let val = defaults.object(forKey: "useInstitutionalDemandWeekly") as? Bool {
            self.useInstitutionalDemandWeekly = val
        }
        print("Loaded useInstitutionalDemandWeekly = \(useInstitutionalDemandWeekly)")

        if let val = defaults.object(forKey: "maxDemandBoostWeekly") as? Double {
            self.maxDemandBoostWeekly = val
        } else {
            self.maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        }
        print("Loaded maxDemandBoostWeekly = \(maxDemandBoostWeekly)")

        if let val = defaults.object(forKey: "useInstitutionalDemandMonthly") as? Bool {
            self.useInstitutionalDemandMonthly = val
        }
        print("Loaded useInstitutionalDemandMonthly = \(useInstitutionalDemandMonthly)")

        if let val = defaults.object(forKey: "maxDemandBoostMonthly") as? Double {
            self.maxDemandBoostMonthly = val
        } else {
            self.maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly
        }
        print("Loaded maxDemandBoostMonthly = \(maxDemandBoostMonthly)")

        // Country Adoption
        if let val = defaults.object(forKey: "useCountryAdoptionWeekly") as? Bool {
            self.useCountryAdoptionWeekly = val
        }
        print("Loaded useCountryAdoptionWeekly = \(useCountryAdoptionWeekly)")

        if let val = defaults.object(forKey: "maxCountryAdBoostWeekly") as? Double {
            self.maxCountryAdBoostWeekly = val
        } else {
            self.maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        }
        print("Loaded maxCountryAdBoostWeekly = \(maxCountryAdBoostWeekly)")

        if let val = defaults.object(forKey: "useCountryAdoptionMonthly") as? Bool {
            self.useCountryAdoptionMonthly = val
        }
        print("Loaded useCountryAdoptionMonthly = \(useCountryAdoptionMonthly)")

        if let val = defaults.object(forKey: "maxCountryAdBoostMonthly") as? Double {
            self.maxCountryAdBoostMonthly = val
        } else {
            self.maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly
        }
        print("Loaded maxCountryAdBoostMonthly = \(maxCountryAdBoostMonthly)")

        // Regulatory Clarity
        if let val = defaults.object(forKey: "useRegulatoryClarityWeekly") as? Bool {
            self.useRegulatoryClarityWeekly = val
        }
        print("Loaded useRegulatoryClarityWeekly = \(useRegulatoryClarityWeekly)")

        if let val = defaults.object(forKey: "maxClarityBoostWeekly") as? Double {
            self.maxClarityBoostWeekly = val
        } else {
            self.maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        }
        print("Loaded maxClarityBoostWeekly = \(maxClarityBoostWeekly)")

        if let val = defaults.object(forKey: "useRegulatoryClarityMonthly") as? Bool {
            self.useRegulatoryClarityMonthly = val
        }
        print("Loaded useRegulatoryClarityMonthly = \(useRegulatoryClarityMonthly)")

        if let val = defaults.object(forKey: "maxClarityBoostMonthly") as? Double {
            self.maxClarityBoostMonthly = val
        } else {
            self.maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly
        }
        print("Loaded maxClarityBoostMonthly = \(maxClarityBoostMonthly)")

        // Etf Approval
        if let val = defaults.object(forKey: "useEtfApprovalWeekly") as? Bool {
            self.useEtfApprovalWeekly = val
        }
        print("Loaded useEtfApprovalWeekly = \(useEtfApprovalWeekly)")

        if let val = defaults.object(forKey: "maxEtfBoostWeekly") as? Double {
            self.maxEtfBoostWeekly = val
        } else {
            self.maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly
        }
        print("Loaded maxEtfBoostWeekly = \(maxEtfBoostWeekly)")

        if let val = defaults.object(forKey: "useEtfApprovalMonthly") as? Bool {
            self.useEtfApprovalMonthly = val
        }
        print("Loaded useEtfApprovalMonthly = \(useEtfApprovalMonthly)")

        if let val = defaults.object(forKey: "maxEtfBoostMonthly") as? Double {
            self.maxEtfBoostMonthly = val
        } else {
            self.maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly
        }
        print("Loaded maxEtfBoostMonthly = \(maxEtfBoostMonthly)")

        // Tech Breakthrough
        if let val = defaults.object(forKey: "useTechBreakthroughWeekly") as? Bool {
            self.useTechBreakthroughWeekly = val
        }
        print("Loaded useTechBreakthroughWeekly = \(useTechBreakthroughWeekly)")

        if let val = defaults.object(forKey: "maxTechBoostWeekly") as? Double {
            self.maxTechBoostWeekly = val
        } else {
            self.maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly
        }
        print("Loaded maxTechBoostWeekly = \(maxTechBoostWeekly)")

        if let val = defaults.object(forKey: "useTechBreakthroughMonthly") as? Bool {
            self.useTechBreakthroughMonthly = val
        }
        print("Loaded useTechBreakthroughMonthly = \(useTechBreakthroughMonthly)")

        if let val = defaults.object(forKey: "maxTechBoostMonthly") as? Double {
            self.maxTechBoostMonthly = val
        } else {
            self.maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly
        }
        print("Loaded maxTechBoostMonthly = \(maxTechBoostMonthly)")

        // Scarcity Events
        if let val = defaults.object(forKey: "useScarcityEventsWeekly") as? Bool {
            self.useScarcityEventsWeekly = val
        }
        print("Loaded useScarcityEventsWeekly = \(useScarcityEventsWeekly)")

        if let val = defaults.object(forKey: "maxScarcityBoostWeekly") as? Double {
            self.maxScarcityBoostWeekly = val
        } else {
            self.maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly
        }
        print("Loaded maxScarcityBoostWeekly = \(maxScarcityBoostWeekly)")

        if let val = defaults.object(forKey: "useScarcityEventsMonthly") as? Bool {
            self.useScarcityEventsMonthly = val
        }
        print("Loaded useScarcityEventsMonthly = \(useScarcityEventsMonthly)")

        if let val = defaults.object(forKey: "maxScarcityBoostMonthly") as? Double {
            self.maxScarcityBoostMonthly = val
        } else {
            self.maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly
        }
        print("Loaded maxScarcityBoostMonthly = \(maxScarcityBoostMonthly)")

        // Global Macro Hedge
        if let val = defaults.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool {
            self.useGlobalMacroHedgeWeekly = val
        }
        print("Loaded useGlobalMacroHedgeWeekly = \(useGlobalMacroHedgeWeekly)")

        if let val = defaults.object(forKey: "maxMacroBoostWeekly") as? Double {
            self.maxMacroBoostWeekly = val
        } else {
            self.maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly
        }
        print("Loaded maxMacroBoostWeekly = \(maxMacroBoostWeekly)")

        if let val = defaults.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool {
            self.useGlobalMacroHedgeMonthly = val
        }
        print("Loaded useGlobalMacroHedgeMonthly = \(useGlobalMacroHedgeMonthly)")

        if let val = defaults.object(forKey: "maxMacroBoostMonthly") as? Double {
            self.maxMacroBoostMonthly = val
        } else {
            self.maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly
        }
        print("Loaded maxMacroBoostMonthly = \(maxMacroBoostMonthly)")

        // Stablecoin Shift
        if let val = defaults.object(forKey: "useStablecoinShiftWeekly") as? Bool {
            self.useStablecoinShiftWeekly = val
        }
        print("Loaded useStablecoinShiftWeekly = \(useStablecoinShiftWeekly)")

        if let val = defaults.object(forKey: "maxStablecoinBoostWeekly") as? Double {
            self.maxStablecoinBoostWeekly = val
        } else {
            self.maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly
        }
        print("Loaded maxStablecoinBoostWeekly = \(maxStablecoinBoostWeekly)")

        if let val = defaults.object(forKey: "useStablecoinShiftMonthly") as? Bool {
            self.useStablecoinShiftMonthly = val
        }
        print("Loaded useStablecoinShiftMonthly = \(useStablecoinShiftMonthly)")

        if let val = defaults.object(forKey: "maxStablecoinBoostMonthly") as? Double {
            self.maxStablecoinBoostMonthly = val
        } else {
            self.maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly
        }
        print("Loaded maxStablecoinBoostMonthly = \(maxStablecoinBoostMonthly)")

        // Demographic Adoption
        if let val = defaults.object(forKey: "useDemographicAdoptionWeekly") as? Bool {
            self.useDemographicAdoptionWeekly = val
        }
        print("Loaded useDemographicAdoptionWeekly = \(useDemographicAdoptionWeekly)")

        if let val = defaults.object(forKey: "maxDemoBoostWeekly") as? Double {
            self.maxDemoBoostWeekly = val
        } else {
            self.maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly
        }
        print("Loaded maxDemoBoostWeekly = \(maxDemoBoostWeekly)")

        if let val = defaults.object(forKey: "useDemographicAdoptionMonthly") as? Bool {
            self.useDemographicAdoptionMonthly = val
        }
        print("Loaded useDemographicAdoptionMonthly = \(useDemographicAdoptionMonthly)")

        if let val = defaults.object(forKey: "maxDemoBoostMonthly") as? Double {
            self.maxDemoBoostMonthly = val
        } else {
            self.maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly
        }
        print("Loaded maxDemoBoostMonthly = \(maxDemoBoostMonthly)")

        // Altcoin Flight
        if let val = defaults.object(forKey: "useAltcoinFlightWeekly") as? Bool {
            self.useAltcoinFlightWeekly = val
        }
        print("Loaded useAltcoinFlightWeekly = \(useAltcoinFlightWeekly)")

        if let val = defaults.object(forKey: "maxAltcoinBoostWeekly") as? Double {
            self.maxAltcoinBoostWeekly = val
        } else {
            self.maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        }
        print("Loaded maxAltcoinBoostWeekly = \(maxAltcoinBoostWeekly)")

        if let val = defaults.object(forKey: "useAltcoinFlightMonthly") as? Bool {
            self.useAltcoinFlightMonthly = val
        }
        print("Loaded useAltcoinFlightMonthly = \(useAltcoinFlightMonthly)")

        if let val = defaults.object(forKey: "maxAltcoinBoostMonthly") as? Double {
            self.maxAltcoinBoostMonthly = val
        } else {
            self.maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly
        }
        print("Loaded maxAltcoinBoostMonthly = \(maxAltcoinBoostMonthly)")

        // Adoption Factor
        if let val = defaults.object(forKey: "useAdoptionFactorWeekly") as? Bool {
            self.useAdoptionFactorWeekly = val
        }
        print("Loaded useAdoptionFactorWeekly = \(useAdoptionFactorWeekly)")

        if let val = defaults.object(forKey: "adoptionBaseFactorWeekly") as? Double {
            self.adoptionBaseFactorWeekly = val
        } else {
            self.adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        }
        print("Loaded adoptionBaseFactorWeekly = \(adoptionBaseFactorWeekly)")

        if let val = defaults.object(forKey: "useAdoptionFactorMonthly") as? Bool {
            self.useAdoptionFactorMonthly = val
        }
        print("Loaded useAdoptionFactorMonthly = \(useAdoptionFactorMonthly)")

        if let val = defaults.object(forKey: "adoptionBaseFactorMonthly") as? Double {
            self.adoptionBaseFactorMonthly = val
        } else {
            self.adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly
        }
        print("Loaded adoptionBaseFactorMonthly = \(adoptionBaseFactorMonthly)")

        // =========================================================
        // BEARISH FACTORS (Weekly & Monthly)
        // =========================================================

        // Regulatory Clampdown
        if let val = defaults.object(forKey: "useRegClampdownWeekly") as? Bool {
            self.useRegClampdownWeekly = val
        }
        print("Loaded useRegClampdownWeekly = \(useRegClampdownWeekly)")

        if let val = defaults.object(forKey: "maxClampDownWeekly") as? Double {
            self.maxClampDownWeekly = val
        } else {
            self.maxClampDownWeekly = SimulationSettings.defaultMaxClampDownWeekly
        }
        print("Loaded maxClampDownWeekly = \(maxClampDownWeekly)")

        if let val = defaults.object(forKey: "useRegClampdownMonthly") as? Bool {
            self.useRegClampdownMonthly = val
        }
        print("Loaded useRegClampdownMonthly = \(useRegClampdownMonthly)")

        if let val = defaults.object(forKey: "maxClampDownMonthly") as? Double {
            self.maxClampDownMonthly = val
        } else {
            self.maxClampDownMonthly = SimulationSettings.defaultMaxClampDownMonthly
        }
        print("Loaded maxClampDownMonthly = \(maxClampDownMonthly)")

        // Competitor Coin
        if let val = defaults.object(forKey: "useCompetitorCoinWeekly") as? Bool {
            self.useCompetitorCoinWeekly = val
        }
        print("Loaded useCompetitorCoinWeekly = \(useCompetitorCoinWeekly)")

        if let val = defaults.object(forKey: "maxCompetitorBoostWeekly") as? Double {
            self.maxCompetitorBoostWeekly = val
        } else {
            self.maxCompetitorBoostWeekly = SimulationSettings.defaultMaxCompetitorBoostWeekly
        }
        print("Loaded maxCompetitorBoostWeekly = \(maxCompetitorBoostWeekly)")

        if let val = defaults.object(forKey: "useCompetitorCoinMonthly") as? Bool {
            self.useCompetitorCoinMonthly = val
        }
        print("Loaded useCompetitorCoinMonthly = \(useCompetitorCoinMonthly)")

        if let val = defaults.object(forKey: "maxCompetitorBoostMonthly") as? Double {
            self.maxCompetitorBoostMonthly = val
        } else {
            self.maxCompetitorBoostMonthly = SimulationSettings.defaultMaxCompetitorBoostMonthly
        }
        print("Loaded maxCompetitorBoostMonthly = \(maxCompetitorBoostMonthly)")

        // Security Breach
        if let val = defaults.object(forKey: "useSecurityBreachWeekly") as? Bool {
            self.useSecurityBreachWeekly = val
        }
        print("Loaded useSecurityBreachWeekly = \(useSecurityBreachWeekly)")

        if let val = defaults.object(forKey: "breachImpactWeekly") as? Double {
            self.breachImpactWeekly = val
        } else {
            self.breachImpactWeekly = SimulationSettings.defaultBreachImpactWeekly
        }
        print("Loaded breachImpactWeekly = \(breachImpactWeekly)")

        if let val = defaults.object(forKey: "useSecurityBreachMonthly") as? Bool {
            self.useSecurityBreachMonthly = val
        }
        print("Loaded useSecurityBreachMonthly = \(useSecurityBreachMonthly)")

        if let val = defaults.object(forKey: "breachImpactMonthly") as? Double {
            self.breachImpactMonthly = val
        } else {
            self.breachImpactMonthly = SimulationSettings.defaultBreachImpactMonthly
        }
        print("Loaded breachImpactMonthly = \(breachImpactMonthly)")

        // Bubble Pop
        if let val = defaults.object(forKey: "useBubblePopWeekly") as? Bool {
            self.useBubblePopWeekly = val
        }
        print("Loaded useBubblePopWeekly = \(useBubblePopWeekly)")

        if let val = defaults.object(forKey: "maxPopDropWeekly") as? Double {
            self.maxPopDropWeekly = val
        } else {
            self.maxPopDropWeekly = SimulationSettings.defaultMaxPopDropWeekly
        }
        print("Loaded maxPopDropWeekly = \(maxPopDropWeekly)")

        if let val = defaults.object(forKey: "useBubblePopMonthly") as? Bool {
            self.useBubblePopMonthly = val
        }
        print("Loaded useBubblePopMonthly = \(useBubblePopMonthly)")

        if let val = defaults.object(forKey: "maxPopDropMonthly") as? Double {
            self.maxPopDropMonthly = val
        } else {
            self.maxPopDropMonthly = SimulationSettings.defaultMaxPopDropMonthly
        }
        print("Loaded maxPopDropMonthly = \(maxPopDropMonthly)")

        // Stablecoin Meltdown
        if let val = defaults.object(forKey: "useStablecoinMeltdownWeekly") as? Bool {
            self.useStablecoinMeltdownWeekly = val
        }
        print("Loaded useStablecoinMeltdownWeekly = \(useStablecoinMeltdownWeekly)")

        if let val = defaults.object(forKey: "maxMeltdownDropWeekly") as? Double {
            self.maxMeltdownDropWeekly = val
        } else {
            self.maxMeltdownDropWeekly = SimulationSettings.defaultMaxMeltdownDropWeekly
        }
        print("Loaded maxMeltdownDropWeekly = \(maxMeltdownDropWeekly)")

        if let val = defaults.object(forKey: "useStablecoinMeltdownMonthly") as? Bool {
            self.useStablecoinMeltdownMonthly = val
        }
        print("Loaded useStablecoinMeltdownMonthly = \(useStablecoinMeltdownMonthly)")

        if let val = defaults.object(forKey: "maxMeltdownDropMonthly") as? Double {
            self.maxMeltdownDropMonthly = val
        } else {
            self.maxMeltdownDropMonthly = SimulationSettings.defaultMaxMeltdownDropMonthly
        }
        print("Loaded maxMeltdownDropMonthly = \(maxMeltdownDropMonthly)")

        // Black Swan
        if let val = defaults.object(forKey: "useBlackSwanWeekly") as? Bool {
            self.useBlackSwanWeekly = val
        }
        print("Loaded useBlackSwanWeekly = \(useBlackSwanWeekly)")

        if let val = defaults.object(forKey: "blackSwanDropWeekly") as? Double {
            self.blackSwanDropWeekly = val
        } else {
            self.blackSwanDropWeekly = SimulationSettings.defaultBlackSwanDropWeekly
        }
        print("Loaded blackSwanDropWeekly = \(blackSwanDropWeekly)")

        if let val = defaults.object(forKey: "useBlackSwanMonthly") as? Bool {
            self.useBlackSwanMonthly = val
        }
        print("Loaded useBlackSwanMonthly = \(useBlackSwanMonthly)")

        if let val = defaults.object(forKey: "blackSwanDropMonthly") as? Double {
            self.blackSwanDropMonthly = val
        } else {
            self.blackSwanDropMonthly = SimulationSettings.defaultBlackSwanDropMonthly
        }
        print("Loaded blackSwanDropMonthly = \(blackSwanDropMonthly)")

        // Bear Market
        if let val = defaults.object(forKey: "useBearMarketWeekly") as? Bool {
            self.useBearMarketWeekly = val
        }
        print("Loaded useBearMarketWeekly = \(useBearMarketWeekly)")

        if let val = defaults.object(forKey: "bearWeeklyDriftWeekly") as? Double {
            self.bearWeeklyDriftWeekly = val
        } else {
            self.bearWeeklyDriftWeekly = SimulationSettings.defaultBearWeeklyDriftWeekly
        }
        print("Loaded bearWeeklyDriftWeekly = \(bearWeeklyDriftWeekly)")

        if let val = defaults.object(forKey: "useBearMarketMonthly") as? Bool {
            self.useBearMarketMonthly = val
        }
        print("Loaded useBearMarketMonthly = \(useBearMarketMonthly)")

        if let val = defaults.object(forKey: "bearWeeklyDriftMonthly") as? Double {
            self.bearWeeklyDriftMonthly = val
        } else {
            self.bearWeeklyDriftMonthly = SimulationSettings.defaultBearWeeklyDriftMonthly
        }
        print("Loaded bearWeeklyDriftMonthly = \(bearWeeklyDriftMonthly)")

        // Maturing Market
        if let val = defaults.object(forKey: "useMaturingMarketWeekly") as? Bool {
            self.useMaturingMarketWeekly = val
        }
        print("Loaded useMaturingMarketWeekly = \(useMaturingMarketWeekly)")

        if let val = defaults.object(forKey: "maxMaturingDropWeekly") as? Double {
            self.maxMaturingDropWeekly = val
        } else {
            self.maxMaturingDropWeekly = SimulationSettings.defaultMaxMaturingDropWeekly
        }
        print("Loaded maxMaturingDropWeekly = \(maxMaturingDropWeekly)")

        if let val = defaults.object(forKey: "useMaturingMarketMonthly") as? Bool {
            self.useMaturingMarketMonthly = val
        }
        print("Loaded useMaturingMarketMonthly = \(useMaturingMarketMonthly)")

        if let val = defaults.object(forKey: "maxMaturingDropMonthly") as? Double {
            self.maxMaturingDropMonthly = val
        } else {
            self.maxMaturingDropMonthly = SimulationSettings.defaultMaxMaturingDropMonthly
        }
        print("Loaded maxMaturingDropMonthly = \(maxMaturingDropMonthly)")

        // Recession
        if let val = defaults.object(forKey: "useRecessionWeekly") as? Bool {
            self.useRecessionWeekly = val
        }
        print("Loaded useRecessionWeekly = \(useRecessionWeekly)")

        if let val = defaults.object(forKey: "maxRecessionDropWeekly") as? Double {
            self.maxRecessionDropWeekly = val
        } else {
            self.maxRecessionDropWeekly = SimulationSettings.defaultMaxRecessionDropWeekly
        }
        print("Loaded maxRecessionDropWeekly = \(maxRecessionDropWeekly)")

        if let val = defaults.object(forKey: "useRecessionMonthly") as? Bool {
            self.useRecessionMonthly = val
        }
        print("Loaded useRecessionMonthly = \(useRecessionMonthly)")

        if let val = defaults.object(forKey: "maxRecessionDropMonthly") as? Double {
            self.maxRecessionDropMonthly = val
        } else {
            self.maxRecessionDropMonthly = SimulationSettings.defaultMaxRecessionDropMonthly
        }
        print("Loaded maxRecessionDropMonthly = \(maxRecessionDropMonthly)")

        // =========================================================
        // Finish up
        // =========================================================
        self.isUpdating = false
        self.isInitialized = true
        print("** SimulationSettingsInit: Defaults loaded. isInitialized set to true.")

        finalizeToggleStateAfterLoad()
    }
}
