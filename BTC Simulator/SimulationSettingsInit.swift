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

        // =========================================================
        // BASIC EXAMPLE PROPERTIES
        // =========================================================

        // Lognormal Growth
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            self.useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        } else {
            self.useLognormalGrowth = true
        }

        // Starting Balance
        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }

        // Average Cost Basis
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }

        // Period & Price
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
            self.currencyPreference = storedPref
        } else {
            self.currencyPreference = .eur
        }

        // Random seed
        self.lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")

        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }

        self.useRandomSeed = defaults.object(forKey: "useRandomSeed") as? Bool ?? true

        // Sampling & Vol
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            self.useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        } else {
            self.useHistoricalSampling = true
        }

        if defaults.object(forKey: "useVolShocks") != nil {
            self.useVolShocks = defaults.bool(forKey: "useVolShocks")
        } else {
            self.useVolShocks = true
        }

        if defaults.object(forKey: "useGarchVolatility") != nil {
            self.useGarchVolatility = defaults.bool(forKey: "useGarchVolatility")
        } else {
            self.useGarchVolatility = true
        }

        // Autocorrelation
        if defaults.object(forKey: "useAutoCorrelation") != nil {
            self.useAutoCorrelation = defaults.bool(forKey: "useAutoCorrelation")
        }

        if defaults.object(forKey: "autoCorrelationStrength") != nil {
            self.autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        }

        if defaults.object(forKey: "meanReversionTarget") != nil {
            self.meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        }

        // Lock sampling
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            self.lockHistoricalSampling = savedLockSampling
        }

        // Regime Switching
        let hasRegimeSwitchingKey = defaults.object(forKey: "useRegimeSwitching") != nil
        print("DEBUG: 'useRegimeSwitching' in defaults? \(hasRegimeSwitchingKey)")

        if hasRegimeSwitchingKey {
            let storedValue = defaults.bool(forKey: "useRegimeSwitching")
            print("DEBUG: Found stored useRegimeSwitching=\(storedValue)")
            self.useRegimeSwitching = storedValue
        } else {
            print("DEBUG: No stored value. Defaulting useRegimeSwitching to TRUE.")
            self.useRegimeSwitching = true
        }

        // =========================================================
        // BULLISH FACTORS (Weekly & Monthly)
        // =========================================================

        // Halving
        if let val = defaults.object(forKey: "useHalvingWeekly") as? Bool {
            self.useHalvingWeekly = val
        }
        if let val = defaults.object(forKey: "halvingBumpWeekly") as? Double {
            self.halvingBumpWeekly = val
        } else {
            self.halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly
        }

        if let val = defaults.object(forKey: "useHalvingMonthly") as? Bool {
            self.useHalvingMonthly = val
        }
        if let val = defaults.object(forKey: "halvingBumpMonthly") as? Double {
            self.halvingBumpMonthly = val
        } else {
            self.halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly
        }

        // Institutional Demand
        if let val = defaults.object(forKey: "useInstitutionalDemandWeekly") as? Bool {
            self.useInstitutionalDemandWeekly = val
        }
        if let val = defaults.object(forKey: "maxDemandBoostWeekly") as? Double {
            self.maxDemandBoostWeekly = val
        } else {
            self.maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        }

        if let val = defaults.object(forKey: "useInstitutionalDemandMonthly") as? Bool {
            self.useInstitutionalDemandMonthly = val
        }
        if let val = defaults.object(forKey: "maxDemandBoostMonthly") as? Double {
            self.maxDemandBoostMonthly = val
        } else {
            self.maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly
        }

        // Country Adoption
        if let val = defaults.object(forKey: "useCountryAdoptionWeekly") as? Bool {
            self.useCountryAdoptionWeekly = val
        }
        if let val = defaults.object(forKey: "maxCountryAdBoostWeekly") as? Double {
            self.maxCountryAdBoostWeekly = val
        } else {
            self.maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        }

        if let val = defaults.object(forKey: "useCountryAdoptionMonthly") as? Bool {
            self.useCountryAdoptionMonthly = val
        }
        if let val = defaults.object(forKey: "maxCountryAdBoostMonthly") as? Double {
            self.maxCountryAdBoostMonthly = val
        } else {
            self.maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly
        }

        // Regulatory Clarity
        if let val = defaults.object(forKey: "useRegulatoryClarityWeekly") as? Bool {
            self.useRegulatoryClarityWeekly = val
        }
        if let val = defaults.object(forKey: "maxClarityBoostWeekly") as? Double {
            self.maxClarityBoostWeekly = val
        } else {
            self.maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        }

        if let val = defaults.object(forKey: "useRegulatoryClarityMonthly") as? Bool {
            self.useRegulatoryClarityMonthly = val
        }
        if let val = defaults.object(forKey: "maxClarityBoostMonthly") as? Double {
            self.maxClarityBoostMonthly = val
        } else {
            self.maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly
        }

        // Etf Approval
        if let val = defaults.object(forKey: "useEtfApprovalWeekly") as? Bool {
            self.useEtfApprovalWeekly = val
        }
        if let val = defaults.object(forKey: "maxEtfBoostWeekly") as? Double {
            self.maxEtfBoostWeekly = val
        } else {
            self.maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly
        }

        if let val = defaults.object(forKey: "useEtfApprovalMonthly") as? Bool {
            self.useEtfApprovalMonthly = val
        }
        if let val = defaults.object(forKey: "maxEtfBoostMonthly") as? Double {
            self.maxEtfBoostMonthly = val
        } else {
            self.maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly
        }

        // Tech Breakthrough
        if let val = defaults.object(forKey: "useTechBreakthroughWeekly") as? Bool {
            self.useTechBreakthroughWeekly = val
        }
        if let val = defaults.object(forKey: "maxTechBoostWeekly") as? Double {
            self.maxTechBoostWeekly = val
        } else {
            self.maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly
        }

        if let val = defaults.object(forKey: "useTechBreakthroughMonthly") as? Bool {
            self.useTechBreakthroughMonthly = val
        }
        if let val = defaults.object(forKey: "maxTechBoostMonthly") as? Double {
            self.maxTechBoostMonthly = val
        } else {
            self.maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly
        }

        // Scarcity Events
        if let val = defaults.object(forKey: "useScarcityEventsWeekly") as? Bool {
            self.useScarcityEventsWeekly = val
        }
        if let val = defaults.object(forKey: "maxScarcityBoostWeekly") as? Double {
            self.maxScarcityBoostWeekly = val
        } else {
            self.maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly
        }

        if let val = defaults.object(forKey: "useScarcityEventsMonthly") as? Bool {
            self.useScarcityEventsMonthly = val
        }
        if let val = defaults.object(forKey: "maxScarcityBoostMonthly") as? Double {
            self.maxScarcityBoostMonthly = val
        } else {
            self.maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly
        }

        // Global Macro Hedge
        if let val = defaults.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool {
            self.useGlobalMacroHedgeWeekly = val
        }
        if let val = defaults.object(forKey: "maxMacroBoostWeekly") as? Double {
            self.maxMacroBoostWeekly = val
        } else {
            self.maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly
        }

        if let val = defaults.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool {
            self.useGlobalMacroHedgeMonthly = val
        }
        if let val = defaults.object(forKey: "maxMacroBoostMonthly") as? Double {
            self.maxMacroBoostMonthly = val
        } else {
            self.maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly
        }

        // Stablecoin Shift
        if let val = defaults.object(forKey: "useStablecoinShiftWeekly") as? Bool {
            self.useStablecoinShiftWeekly = val
        }
        if let val = defaults.object(forKey: "maxStablecoinBoostWeekly") as? Double {
            self.maxStablecoinBoostWeekly = val
        } else {
            self.maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly
        }

        if let val = defaults.object(forKey: "useStablecoinShiftMonthly") as? Bool {
            self.useStablecoinShiftMonthly = val
        }
        if let val = defaults.object(forKey: "maxStablecoinBoostMonthly") as? Double {
            self.maxStablecoinBoostMonthly = val
        } else {
            self.maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly
        }

        // Demographic Adoption
        if let val = defaults.object(forKey: "useDemographicAdoptionWeekly") as? Bool {
            self.useDemographicAdoptionWeekly = val
        }
        if let val = defaults.object(forKey: "maxDemoBoostWeekly") as? Double {
            self.maxDemoBoostWeekly = val
        } else {
            self.maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly
        }

        if let val = defaults.object(forKey: "useDemographicAdoptionMonthly") as? Bool {
            self.useDemographicAdoptionMonthly = val
        }
        if let val = defaults.object(forKey: "maxDemoBoostMonthly") as? Double {
            self.maxDemoBoostMonthly = val
        } else {
            self.maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly
        }

        // Altcoin Flight
        if let val = defaults.object(forKey: "useAltcoinFlightWeekly") as? Bool {
            self.useAltcoinFlightWeekly = val
        }
        if let val = defaults.object(forKey: "maxAltcoinBoostWeekly") as? Double {
            self.maxAltcoinBoostWeekly = val
        } else {
            self.maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        }

        if let val = defaults.object(forKey: "useAltcoinFlightMonthly") as? Bool {
            self.useAltcoinFlightMonthly = val
        }
        if let val = defaults.object(forKey: "maxAltcoinBoostMonthly") as? Double {
            self.maxAltcoinBoostMonthly = val
        } else {
            self.maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly
        }

        // Adoption Factor
        if let val = defaults.object(forKey: "useAdoptionFactorWeekly") as? Bool {
            self.useAdoptionFactorWeekly = val
        }
        if let val = defaults.object(forKey: "adoptionBaseFactorWeekly") as? Double {
            self.adoptionBaseFactorWeekly = val
        } else {
            self.adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        }

        if let val = defaults.object(forKey: "useAdoptionFactorMonthly") as? Bool {
            self.useAdoptionFactorMonthly = val
        }
        if let val = defaults.object(forKey: "adoptionBaseFactorMonthly") as? Double {
            self.adoptionBaseFactorMonthly = val
        } else {
            self.adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly
        }

        // =========================================================
        // BEARISH FACTORS (Weekly & Monthly)
        // =========================================================

        // Regulatory Clampdown
        if let val = defaults.object(forKey: "useRegClampdownWeekly") as? Bool {
            self.useRegClampdownWeekly = val
        }
        if let val = defaults.object(forKey: "maxClampDownWeekly") as? Double {
            self.maxClampDownWeekly = val
        } else {
            self.maxClampDownWeekly = SimulationSettings.defaultMaxClampDownWeekly
        }

        if let val = defaults.object(forKey: "useRegClampdownMonthly") as? Bool {
            self.useRegClampdownMonthly = val
        }
        if let val = defaults.object(forKey: "maxClampDownMonthly") as? Double {
            self.maxClampDownMonthly = val
        } else {
            self.maxClampDownMonthly = SimulationSettings.defaultMaxClampDownMonthly
        }

        // Competitor Coin
        if let val = defaults.object(forKey: "useCompetitorCoinWeekly") as? Bool {
            self.useCompetitorCoinWeekly = val
        }
        if let val = defaults.object(forKey: "maxCompetitorBoostWeekly") as? Double {
            self.maxCompetitorBoostWeekly = val
        } else {
            self.maxCompetitorBoostWeekly = SimulationSettings.defaultMaxCompetitorBoostWeekly
        }

        if let val = defaults.object(forKey: "useCompetitorCoinMonthly") as? Bool {
            self.useCompetitorCoinMonthly = val
        }
        if let val = defaults.object(forKey: "maxCompetitorBoostMonthly") as? Double {
            self.maxCompetitorBoostMonthly = val
        } else {
            self.maxCompetitorBoostMonthly = SimulationSettings.defaultMaxCompetitorBoostMonthly
        }

        // Security Breach
        if let val = defaults.object(forKey: "useSecurityBreachWeekly") as? Bool {
            self.useSecurityBreachWeekly = val
        }
        if let val = defaults.object(forKey: "breachImpactWeekly") as? Double {
            self.breachImpactWeekly = val
        } else {
            self.breachImpactWeekly = SimulationSettings.defaultBreachImpactWeekly
        }

        if let val = defaults.object(forKey: "useSecurityBreachMonthly") as? Bool {
            self.useSecurityBreachMonthly = val
        }
        if let val = defaults.object(forKey: "breachImpactMonthly") as? Double {
            self.breachImpactMonthly = val
        } else {
            self.breachImpactMonthly = SimulationSettings.defaultBreachImpactMonthly
        }

        // Bubble Pop
        if let val = defaults.object(forKey: "useBubblePopWeekly") as? Bool {
            self.useBubblePopWeekly = val
        }
        if let val = defaults.object(forKey: "maxPopDropWeekly") as? Double {
            self.maxPopDropWeekly = val
        } else {
            self.maxPopDropWeekly = SimulationSettings.defaultMaxPopDropWeekly
        }

        if let val = defaults.object(forKey: "useBubblePopMonthly") as? Bool {
            self.useBubblePopMonthly = val
        }
        if let val = defaults.object(forKey: "maxPopDropMonthly") as? Double {
            self.maxPopDropMonthly = val
        } else {
            self.maxPopDropMonthly = SimulationSettings.defaultMaxPopDropMonthly
        }

        // Stablecoin Meltdown
        if let val = defaults.object(forKey: "useStablecoinMeltdownWeekly") as? Bool {
            self.useStablecoinMeltdownWeekly = val
        }
        if let val = defaults.object(forKey: "maxMeltdownDropWeekly") as? Double {
            self.maxMeltdownDropWeekly = val
        } else {
            self.maxMeltdownDropWeekly = SimulationSettings.defaultMaxMeltdownDropWeekly
        }

        if let val = defaults.object(forKey: "useStablecoinMeltdownMonthly") as? Bool {
            self.useStablecoinMeltdownMonthly = val
        }
        if let val = defaults.object(forKey: "maxMeltdownDropMonthly") as? Double {
            self.maxMeltdownDropMonthly = val
        } else {
            self.maxMeltdownDropMonthly = SimulationSettings.defaultMaxMeltdownDropMonthly
        }

        // Black Swan
        if let val = defaults.object(forKey: "useBlackSwanWeekly") as? Bool {
            self.useBlackSwanWeekly = val
        }
        if let val = defaults.object(forKey: "blackSwanDropWeekly") as? Double {
            self.blackSwanDropWeekly = val
        } else {
            self.blackSwanDropWeekly = SimulationSettings.defaultBlackSwanDropWeekly
        }

        if let val = defaults.object(forKey: "useBlackSwanMonthly") as? Bool {
            self.useBlackSwanMonthly = val
        }
        if let val = defaults.object(forKey: "blackSwanDropMonthly") as? Double {
            self.blackSwanDropMonthly = val
        } else {
            self.blackSwanDropMonthly = SimulationSettings.defaultBlackSwanDropMonthly
        }

        // Bear Market
        if let val = defaults.object(forKey: "useBearMarketWeekly") as? Bool {
            self.useBearMarketWeekly = val
        }
        if let val = defaults.object(forKey: "bearWeeklyDriftWeekly") as? Double {
            self.bearWeeklyDriftWeekly = val
        } else {
            self.bearWeeklyDriftWeekly = SimulationSettings.defaultBearWeeklyDriftWeekly
        }

        if let val = defaults.object(forKey: "useBearMarketMonthly") as? Bool {
            self.useBearMarketMonthly = val
        }
        if let val = defaults.object(forKey: "bearWeeklyDriftMonthly") as? Double {
            self.bearWeeklyDriftMonthly = val
        } else {
            self.bearWeeklyDriftMonthly = SimulationSettings.defaultBearWeeklyDriftMonthly
        }

        // Maturing Market
        if let val = defaults.object(forKey: "useMaturingMarketWeekly") as? Bool {
            self.useMaturingMarketWeekly = val
        }
        if let val = defaults.object(forKey: "maxMaturingDropWeekly") as? Double {
            self.maxMaturingDropWeekly = val
        } else {
            self.maxMaturingDropWeekly = SimulationSettings.defaultMaxMaturingDropWeekly
        }

        if let val = defaults.object(forKey: "useMaturingMarketMonthly") as? Bool {
            self.useMaturingMarketMonthly = val
        }
        if let val = defaults.object(forKey: "maxMaturingDropMonthly") as? Double {
            self.maxMaturingDropMonthly = val
        } else {
            self.maxMaturingDropMonthly = SimulationSettings.defaultMaxMaturingDropMonthly
        }

        // Recession
        if let val = defaults.object(forKey: "useRecessionWeekly") as? Bool {
            self.useRecessionWeekly = val
        }
        if let val = defaults.object(forKey: "maxRecessionDropWeekly") as? Double {
            self.maxRecessionDropWeekly = val
        } else {
            self.maxRecessionDropWeekly = SimulationSettings.defaultMaxRecessionDropWeekly
        }

        if let val = defaults.object(forKey: "useRecessionMonthly") as? Bool {
            self.useRecessionMonthly = val
        }
        if let val = defaults.object(forKey: "maxRecessionDropMonthly") as? Double {
            self.maxRecessionDropMonthly = val
        } else {
            self.maxRecessionDropMonthly = SimulationSettings.defaultMaxRecessionDropMonthly
        }

        // =========================================================
        // Finish up
        // =========================================================
        self.isUpdating = false
        self.isInitialized = true

        finalizeToggleStateAfterLoad()
    }
}
