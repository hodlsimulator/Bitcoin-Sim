//
//  SimulationSettings+RestoreDefaults.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    func restoreDefaults() {
        // 1) Signal that we're doing a bulk restore so onChange logic is skipped
        isRestoringDefaults = true
        print("RESTORE DEFAULTS CALLED!")
        
        let defaults = UserDefaults.standard
        
        // Remove old factorIntensity and set it to default
        UserDefaults.standard.removeObject(forKey: "factorIntensity")
        factorIntensity = 0.5
        
        // Reset chart icon flags (make sure these properties are defined in SimulationSettings)
        chartExtremeBearish = false
        chartExtremeBullish = false
        
        // Clear all manual offsets and leftover stored values
        manualOffsets = [:]

        // Keep any general toggles you want to preserve:
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks,         forKey: "useVolShocks")

        // Remove old parent-toggle keys (we no longer use them in code)
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

        // Remove or reset any new toggles you plan to revert
        defaults.removeObject(forKey: "useHistoricalSampling")
        defaults.removeObject(forKey: "useVolShocks")

        // GARCH
        defaults.removeObject(forKey: "useGarchVolatility")

        // AutoCorrelation
        defaults.removeObject(forKey: "useAutoCorrelation")
        defaults.removeObject(forKey: "autoCorrelationStrength")
        defaults.removeObject(forKey: "meanReversionTarget")

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

        // Remove or reset the lognormal growth key
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true

        // Reassign to the new defaults for these general toggles
        useHistoricalSampling = true
        useVolShocks = true
        useGarchVolatility = true

        // Remove existing user default for regime switching & set default to true
        defaults.removeObject(forKey: "useRegimeSwitching")
        useRegimeSwitching = true
        
        // -------------------
        // Bullish / Bearish Toggles (old system)
        // -------------------
        
        // Halving
        useHalvingWeekly = true
        halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly
        useHalvingMonthly = true
        halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly

        // Institutional Demand
        useInstitutionalDemandWeekly = true
        maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        useInstitutionalDemandMonthly = true
        maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly

        // Country Adoption
        useCountryAdoptionWeekly = true
        maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        useCountryAdoptionMonthly = true
        maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly

        // Regulatory Clarity
        useRegulatoryClarityWeekly = true
        maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        useRegulatoryClarityMonthly = true
        maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly

        // ETF Approval
        useEtfApprovalWeekly = true
        maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly
        useEtfApprovalMonthly = true
        maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly

        // Tech Breakthrough
        useTechBreakthroughWeekly = true
        maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly
        useTechBreakthroughMonthly = true
        maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly

        // Scarcity Events
        useScarcityEventsWeekly = true
        maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly
        useScarcityEventsMonthly = true
        maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly

        // Global Macro Hedge
        useGlobalMacroHedgeWeekly = true
        maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly
        useGlobalMacroHedgeMonthly = true
        maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly

        // Stablecoin Shift
        useStablecoinShiftWeekly = true
        maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly
        useStablecoinShiftMonthly = true
        maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly

        // Demographic Adoption
        useDemographicAdoptionWeekly = true
        maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly
        useDemographicAdoptionMonthly = true
        maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly

        // Altcoin Flight
        useAltcoinFlightWeekly = true
        maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        useAltcoinFlightMonthly = true
        maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly

        // Adoption Factor
        useAdoptionFactorWeekly = true
        adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        useAdoptionFactorMonthly = true
        adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly

        // Bearish factors default on for both
        useRegClampdownWeekly = true
        maxClampDownWeekly = SimulationSettings.defaultMaxClampDownWeekly
        useRegClampdownMonthly = true
        maxClampDownMonthly = SimulationSettings.defaultMaxClampDownMonthly

        useCompetitorCoinWeekly = true
        maxCompetitorBoostWeekly = SimulationSettings.defaultMaxCompetitorBoostWeekly
        useCompetitorCoinMonthly = true
        maxCompetitorBoostMonthly = SimulationSettings.defaultMaxCompetitorBoostMonthly

        useSecurityBreachWeekly = true
        breachImpactWeekly = SimulationSettings.defaultBreachImpactWeekly
        useSecurityBreachMonthly = true
        breachImpactMonthly = SimulationSettings.defaultBreachImpactMonthly

        useBubblePopWeekly = true
        maxPopDropWeekly = SimulationSettings.defaultMaxPopDropWeekly
        useBubblePopMonthly = true
        maxPopDropMonthly = SimulationSettings.defaultMaxPopDropMonthly

        useStablecoinMeltdownWeekly = true
        maxMeltdownDropWeekly = SimulationSettings.defaultMaxMeltdownDropWeekly
        useStablecoinMeltdownMonthly = true
        maxMeltdownDropMonthly = SimulationSettings.defaultMaxMeltdownDropMonthly

        useBlackSwanWeekly = true
        blackSwanDropWeekly = SimulationSettings.defaultBlackSwanDropWeekly
        useBlackSwanMonthly = true
        blackSwanDropMonthly = SimulationSettings.defaultBlackSwanDropMonthly

        useBearMarketWeekly = true
        bearWeeklyDriftWeekly = SimulationSettings.defaultBearWeeklyDriftWeekly
        useBearMarketMonthly = true
        bearWeeklyDriftMonthly = SimulationSettings.defaultBearWeeklyDriftMonthly

        useMaturingMarketWeekly = true
        maxMaturingDropWeekly = SimulationSettings.defaultMaxMaturingDropWeekly
        useMaturingMarketMonthly = true
        maxMaturingDropMonthly = SimulationSettings.defaultMaxMaturingDropMonthly

        useRecessionWeekly = true
        maxRecessionDropWeekly = SimulationSettings.defaultMaxRecessionDropWeekly
        useRecessionMonthly = true
        maxRecessionDropMonthly = SimulationSettings.defaultMaxRecessionDropMonthly
        
        // --------------------------------------------------
        // ALSO set fraction-based toggles to 1.0 and restore
        // each "unified" factor to a default/midpoint value.
        // --------------------------------------------------
        
        factorEnableFrac["Halving"] = 0.5
        halvingBumpUnified = 0.3298386887 // midpoint of 0.2773386887...0.3823386887

        factorEnableFrac["InstitutionalDemand"] = 0.5
        maxDemandBoostUnified = 0.001239 // midpoint of 0.00105315...0.00142485

        factorEnableFrac["CountryAdoption"] = 0.5
        maxCountryAdBoostUnified = 0.0011375879977

        factorEnableFrac["RegulatoryClarity"] = 0.5
        maxClarityBoostUnified = 0.0007170254861605167

        factorEnableFrac["EtfApproval"] = 0.5
        maxEtfBoostUnified = 0.0017880183160305023

        factorEnableFrac["TechBreakthrough"] = 0.5
        maxTechBoostUnified = 0.0006083193579173088

        factorEnableFrac["ScarcityEvents"] = 0.5
        maxScarcityBoostUnified = 0.00041308753681182863

        factorEnableFrac["GlobalMacroHedge"] = 0.5
        maxMacroBoostUnified = 0.0003497809724932909

        factorEnableFrac["StablecoinShift"] = 0.5
        maxStablecoinBoostUnified = 0.0003312209116327763

        factorEnableFrac["DemographicAdoption"] = 0.5
        maxDemoBoostUnified = 0.001061993203662634

        factorEnableFrac["AltcoinFlight"] = 0.5
        maxAltcoinBoostUnified = 0.0002802194461803342

        factorEnableFrac["AdoptionFactor"] = 0.5
        adoptionBaseFactorUnified = 0.0016045109088897705

        factorEnableFrac["RegClampdown"] = 0.5
        maxClampDownUnified = -0.0011361452243542672

        factorEnableFrac["CompetitorCoin"] = 0.5
        maxCompetitorBoostUnified = -0.0010148181746411323

        factorEnableFrac["SecurityBreach"] = 0.5
        breachImpactUnified = -0.0010914715168380737

        factorEnableFrac["BubblePop"] = 0.5
        maxPopDropUnified = -0.001762673890762329

        factorEnableFrac["StablecoinMeltdown"] = 0.5
        maxMeltdownDropUnified = -0.0007141026159477233

        factorEnableFrac["BlackSwan"] = 0.5
        blackSwanDropUnified = -0.398885

        factorEnableFrac["BearMarket"] = 0.5
        bearWeeklyDriftUnified = -0.0008778802752494812

        factorEnableFrac["MaturingMarket"] = 0.5
        maxMaturingDropUnified = -0.0015440231055486196

        factorEnableFrac["Recession"] = 0.5
        maxRecessionDropUnified = -0.0009005491467487811
        
        // Finally, toggle everything on for the *current* period
        toggleAll = true
        
        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
        
        // Reset final toggles
        useLognormalGrowth = true
        useHistoricalSampling = true
        useVolShocks = true
        useGarchVolatility = true
        
        // Write changes to disk
        defaults.synchronize()
        
        // 2) Delay turning isRestoringDefaults off so factorEnableFrac changes “settle”
        DispatchQueue.main.async {
            self.isRestoringDefaults = false
        }
    }
}
