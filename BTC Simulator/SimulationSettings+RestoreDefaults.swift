//
//  SimulationSettings+RestoreDefaults.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    func restoreDefaults() {
        print("RESTORE DEFAULTS CALLED!")
        let defaults = UserDefaults.standard
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks, forKey: "useVolShocks")

        // Remove factor keys
        defaults.removeObject(forKey: "useHalving")
        defaults.removeObject(forKey: "halvingBump")
        defaults.removeObject(forKey: "useInstitutionalDemand")
        defaults.removeObject(forKey: "maxDemandBoost")
        defaults.removeObject(forKey: "useCountryAdoption")
        defaults.removeObject(forKey: "maxCountryAdBoost")
        defaults.removeObject(forKey: "useRegulatoryClarity")
        defaults.removeObject(forKey: "maxClarityBoost")
        defaults.removeObject(forKey: "useEtfApproval")
        defaults.removeObject(forKey: "maxEtfBoost")
        defaults.removeObject(forKey: "useTechBreakthrough")
        defaults.removeObject(forKey: "maxTechBoost")
        defaults.removeObject(forKey: "useScarcityEvents")
        defaults.removeObject(forKey: "maxScarcityBoost")
        defaults.removeObject(forKey: "useGlobalMacroHedge")
        defaults.removeObject(forKey: "maxMacroBoost")
        defaults.removeObject(forKey: "useStablecoinShift")
        defaults.removeObject(forKey: "maxStablecoinBoost")
        defaults.removeObject(forKey: "useDemographicAdoption")
        defaults.removeObject(forKey: "maxDemoBoost")
        defaults.removeObject(forKey: "useAltcoinFlight")
        defaults.removeObject(forKey: "maxAltcoinBoost")
        defaults.removeObject(forKey: "useAdoptionFactor")
        defaults.removeObject(forKey: "adoptionBaseFactor")
        defaults.removeObject(forKey: "useRegClampdown")
        defaults.removeObject(forKey: "maxClampDown")
        defaults.removeObject(forKey: "useCompetitorCoin")
        defaults.removeObject(forKey: "maxCompetitorBoost")
        defaults.removeObject(forKey: "useSecurityBreach")
        defaults.removeObject(forKey: "breachImpact")
        defaults.removeObject(forKey: "useBubblePop")
        defaults.removeObject(forKey: "maxPopDrop")
        defaults.removeObject(forKey: "useStablecoinMeltdown")
        defaults.removeObject(forKey: "maxMeltdownDrop")
        defaults.removeObject(forKey: "useBlackSwan")
        defaults.removeObject(forKey: "blackSwanDrop")
        defaults.removeObject(forKey: "useBearMarket")
        defaults.removeObject(forKey: "bearWeeklyDrift")
        defaults.removeObject(forKey: "useMaturingMarket")
        defaults.removeObject(forKey: "maxMaturingDrop")
        defaults.removeObject(forKey: "useRecession")
        defaults.removeObject(forKey: "maxRecessionDrop")
        defaults.removeObject(forKey: "lockHistoricalSampling")

        // Remove your new toggles
        defaults.removeObject(forKey: "useHistoricalSampling")
        defaults.removeObject(forKey: "useVolShocks")

        // NEW: Remove GARCH toggle
        defaults.removeObject(forKey: "useGarchVolatility")

        // Remove the keys from UserDefaults
        defaults.removeObject(forKey: "useAutoCorrelation")
        defaults.removeObject(forKey: "autoCorrelationStrength")
        defaults.removeObject(forKey: "meanReversionTarget")

        // Now set them to your desired "reset" values
        useAutoCorrelation = false   // default "off"
        autoCorrelationStrength = 0.2
        meanReversionTarget = 0.0

        // Remove new weekly/monthly keys
        defaults.removeObject(forKey: "useHalvingWeekly")
        defaults.removeObject(forKey: "halvingBumpWeekly")
        defaults.removeObject(forKey: "useHalvingMonthly")
        defaults.removeObject(forKey: "halvingBumpMonthly")

        defaults.removeObject(forKey: "useInstitutionalDemandWeekly")
        defaults.removeObject(forKey: "maxDemandBoostWeekly")
        defaults.removeObject(forKey: "useInstitutionalDemandMonthly")
        defaults.removeObject(forKey: "maxDemandBoostMonthly")

        defaults.removeObject(forKey: "useCountryAdoptionWeekly")
        defaults.removeObject(forKey: "maxCountryAdBoostWeekly")
        defaults.removeObject(forKey: "useCountryAdoptionMonthly")
        defaults.removeObject(forKey: "maxCountryAdBoostMonthly")

        defaults.removeObject(forKey: "useRegulatoryClarityWeekly")
        defaults.removeObject(forKey: "maxClarityBoostWeekly")
        defaults.removeObject(forKey: "useRegulatoryClarityMonthly")
        defaults.removeObject(forKey: "maxClarityBoostMonthly")

        defaults.removeObject(forKey: "useEtfApprovalWeekly")
        defaults.removeObject(forKey: "maxEtfBoostWeekly")
        defaults.removeObject(forKey: "useEtfApprovalMonthly")
        defaults.removeObject(forKey: "maxEtfBoostMonthly")

        defaults.removeObject(forKey: "useTechBreakthroughWeekly")
        defaults.removeObject(forKey: "maxTechBoostWeekly")
        defaults.removeObject(forKey: "useTechBreakthroughMonthly")
        defaults.removeObject(forKey: "maxTechBoostMonthly")

        defaults.removeObject(forKey: "useScarcityEventsWeekly")
        defaults.removeObject(forKey: "maxScarcityBoostWeekly")
        defaults.removeObject(forKey: "useScarcityEventsMonthly")
        defaults.removeObject(forKey: "maxScarcityBoostMonthly")

        defaults.removeObject(forKey: "useGlobalMacroHedgeWeekly")
        defaults.removeObject(forKey: "maxMacroBoostWeekly")
        defaults.removeObject(forKey: "useGlobalMacroHedgeMonthly")
        defaults.removeObject(forKey: "maxMacroBoostMonthly")

        defaults.removeObject(forKey: "useStablecoinShiftWeekly")
        defaults.removeObject(forKey: "maxStablecoinBoostWeekly")
        defaults.removeObject(forKey: "useStablecoinShiftMonthly")
        defaults.removeObject(forKey: "maxStablecoinBoostMonthly")

        defaults.removeObject(forKey: "useDemographicAdoptionWeekly")
        defaults.removeObject(forKey: "maxDemoBoostWeekly")
        defaults.removeObject(forKey: "useDemographicAdoptionMonthly")
        defaults.removeObject(forKey: "maxDemoBoostMonthly")

        defaults.removeObject(forKey: "useAltcoinFlightWeekly")
        defaults.removeObject(forKey: "maxAltcoinBoostWeekly")
        defaults.removeObject(forKey: "useAltcoinFlightMonthly")
        defaults.removeObject(forKey: "maxAltcoinBoostMonthly")

        defaults.removeObject(forKey: "useAdoptionFactorWeekly")
        defaults.removeObject(forKey: "adoptionBaseFactorWeekly")
        defaults.removeObject(forKey: "useAdoptionFactorMonthly")
        defaults.removeObject(forKey: "adoptionBaseFactorMonthly")

        defaults.removeObject(forKey: "useRegClampdownWeekly")
        defaults.removeObject(forKey: "maxClampDownWeekly")
        defaults.removeObject(forKey: "useRegClampdownMonthly")
        defaults.removeObject(forKey: "maxClampDownMonthly")

        defaults.removeObject(forKey: "useCompetitorCoinWeekly")
        defaults.removeObject(forKey: "maxCompetitorBoostWeekly")
        defaults.removeObject(forKey: "useCompetitorCoinMonthly")
        defaults.removeObject(forKey: "maxCompetitorBoostMonthly")

        defaults.removeObject(forKey: "useSecurityBreachWeekly")
        defaults.removeObject(forKey: "breachImpactWeekly")
        defaults.removeObject(forKey: "useSecurityBreachMonthly")
        defaults.removeObject(forKey: "breachImpactMonthly")

        defaults.removeObject(forKey: "useBubblePopWeekly")
        defaults.removeObject(forKey: "maxPopDropWeekly")
        defaults.removeObject(forKey: "useBubblePopMonthly")
        defaults.removeObject(forKey: "maxPopDropMonthly")

        defaults.removeObject(forKey: "useStablecoinMeltdownWeekly")
        defaults.removeObject(forKey: "maxMeltdownDropWeekly")
        defaults.removeObject(forKey: "useStablecoinMeltdownMonthly")
        defaults.removeObject(forKey: "maxMeltdownDropMonthly")

        defaults.removeObject(forKey: "useBlackSwanWeekly")
        defaults.removeObject(forKey: "blackSwanDropWeekly")
        defaults.removeObject(forKey: "useBlackSwanMonthly")
        defaults.removeObject(forKey: "blackSwanDropMonthly")

        defaults.removeObject(forKey: "useBearMarketWeekly")
        defaults.removeObject(forKey: "bearWeeklyDriftWeekly")
        defaults.removeObject(forKey: "useBearMarketMonthly")
        defaults.removeObject(forKey: "bearWeeklyDriftMonthly")

        defaults.removeObject(forKey: "useMaturingMarketWeekly")
        defaults.removeObject(forKey: "maxMaturingDropWeekly")
        defaults.removeObject(forKey: "useMaturingMarketMonthly")
        defaults.removeObject(forKey: "maxMaturingDropMonthly")

        defaults.removeObject(forKey: "useRecessionWeekly")
        defaults.removeObject(forKey: "maxRecessionDropWeekly")
        defaults.removeObject(forKey: "useRecessionMonthly")
        defaults.removeObject(forKey: "maxRecessionDropMonthly")

        // Also remove or reset the toggle
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true

        // Reassign them to the NEW defaults:
        useHistoricalSampling = true
        useVolShocks = true

        // NEW: Set GARCH default to true
        useGarchVolatility = true

        //
        // BULLISH FACTORS: set each parent's monthly = false by default
        //

        // Halving
        useHalving = true
        useHalvingWeekly = true
        halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly
        useHalvingMonthly = false
        halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly

        // Institutional Demand
        useInstitutionalDemand = true
        useInstitutionalDemandWeekly = true
        maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        useInstitutionalDemandMonthly = false
        maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly

        // Country Adoption
        useCountryAdoption = true
        useCountryAdoptionWeekly = true
        maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        useCountryAdoptionMonthly = false
        maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly

        // Regulatory Clarity
        useRegulatoryClarity = true
        useRegulatoryClarityWeekly = true
        maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        useRegulatoryClarityMonthly = false
        maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly

        // ETF Approval
        useEtfApproval = true
        useEtfApprovalWeekly = true
        maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly
        useEtfApprovalMonthly = false
        maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly

        // Tech Breakthrough
        useTechBreakthrough = true
        useTechBreakthroughWeekly = true
        maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly
        useTechBreakthroughMonthly = false
        maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly

        // Scarcity Events
        useScarcityEvents = true
        useScarcityEventsWeekly = true
        maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly
        useScarcityEventsMonthly = false
        maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly

        // Global Macro Hedge
        useGlobalMacroHedge = true
        useGlobalMacroHedgeWeekly = true
        maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly
        useGlobalMacroHedgeMonthly = false
        maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly

        // Stablecoin Shift
        useStablecoinShift = true
        useStablecoinShiftWeekly = true
        maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly
        useStablecoinShiftMonthly = false
        maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly

        // Demographic Adoption
        useDemographicAdoption = true
        useDemographicAdoptionWeekly = true
        maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly
        useDemographicAdoptionMonthly = false
        maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly

        // Altcoin Flight
        useAltcoinFlight = true
        useAltcoinFlightWeekly = true
        maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        useAltcoinFlightMonthly = false
        maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly

        // Adoption Factor
        useAdoptionFactor = true
        useAdoptionFactorWeekly = true
        adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        useAdoptionFactorMonthly = false
        adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly

        //
        // BEARISH FACTORS: left as is
        //

        useRegClampdown = true
        useRegClampdownWeekly = true
        maxClampDownWeekly = SimulationSettings.defaultMaxClampDownWeekly
        useRegClampdownMonthly = true
        maxClampDownMonthly = SimulationSettings.defaultMaxClampDownMonthly

        useCompetitorCoin = true
        useCompetitorCoinWeekly = true
        maxCompetitorBoostWeekly = SimulationSettings.defaultMaxCompetitorBoostWeekly
        useCompetitorCoinMonthly = true
        maxCompetitorBoostMonthly = SimulationSettings.defaultMaxCompetitorBoostMonthly

        useSecurityBreach = true
        useSecurityBreachWeekly = true
        breachImpactWeekly = SimulationSettings.defaultBreachImpactWeekly
        useSecurityBreachMonthly = true
        breachImpactMonthly = SimulationSettings.defaultBreachImpactMonthly

        useBubblePop = true
        useBubblePopWeekly = true
        maxPopDropWeekly = SimulationSettings.defaultMaxPopDropWeekly
        useBubblePopMonthly = true
        maxPopDropMonthly = SimulationSettings.defaultMaxPopDropMonthly

        useStablecoinMeltdown = true
        useStablecoinMeltdownWeekly = true
        maxMeltdownDropWeekly = SimulationSettings.defaultMaxMeltdownDropWeekly
        useStablecoinMeltdownMonthly = true
        maxMeltdownDropMonthly = SimulationSettings.defaultMaxMeltdownDropMonthly

        useBlackSwan = true
        useBlackSwanWeekly = true
        blackSwanDropWeekly = SimulationSettings.defaultBlackSwanDropWeekly
        useBlackSwanMonthly = true
        blackSwanDropMonthly = SimulationSettings.defaultBlackSwanDropMonthly

        useBearMarket = true
        useBearMarketWeekly = true
        bearWeeklyDriftWeekly = SimulationSettings.defaultBearWeeklyDriftWeekly
        useBearMarketMonthly = true
        bearWeeklyDriftMonthly = SimulationSettings.defaultBearWeeklyDriftMonthly

        useMaturingMarket = true
        useMaturingMarketWeekly = true
        maxMaturingDropWeekly = SimulationSettings.defaultMaxMaturingDropWeekly
        useMaturingMarketMonthly = true
        maxMaturingDropMonthly = SimulationSettings.defaultMaxMaturingDropMonthly

        useRecession = true
        useRecessionWeekly = true
        maxRecessionDropWeekly = SimulationSettings.defaultMaxRecessionDropWeekly
        useRecessionMonthly = true
        maxRecessionDropMonthly = SimulationSettings.defaultMaxRecessionDropMonthly

        // Finally, enable everything at once
        toggleAll = true

        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
    }
}
