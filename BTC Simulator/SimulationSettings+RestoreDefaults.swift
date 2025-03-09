//
//  SimulationSettings+RestoreDefaults.swift
//  BTCMonteCarlo
//
//  Created by ... on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    func restoreDefaults() {
        isRestoringDefaults = true

        // 0) Clear locked factors
        lockedFactors.removeAll()

        // 1) Rebuild the weekly factor dictionary
        var newFactors: [String: FactorState] = [:]
        for (factorName, def) in FactorCatalog.all {
            let (minVal, midVal, maxVal) = (def.minWeekly, def.midWeekly, def.maxWeekly)
            let fs = FactorState(
                name: factorName,
                currentValue: midVal,
                defaultValue: midVal,
                minValue: minVal,
                maxValue: maxVal,
                isEnabled: true,
                isLocked: false
            )
            newFactors[factorName] = fs
        }
        factors = newFactors

        // 2) Reset intensity, tilt bar, and chart extremes
        ignoreSync = true
        extendedGlobalValue = 0.0 // This corresponds to 0.5 in rawFactorIntensity
        ignoreSync = false
        
        chartExtremeBearish = false
        chartExtremeBullish = false
        resetTiltBar()

        // 3) Remove user defaults keys, **but** if lockedRandomSeed == true, skip removing
        var keysToRemove = [
            "factorStates",
            "rawFactorIntensity",
            "defaultTilt",
            "maxSwing",
            "capturedTilt",
            "tiltBarValue",
            "savedUserPeriods",
            "savedInitialBTCPriceUSD",
            "savedStartingBalance",
            "savedAverageCostBasis",
            "currencyPreference",
            "savedPeriodUnit",
            "useLognormalGrowth",
            "useAnnualStep",
            // "seedValue",           // We'll conditionally remove below
            // "useRandomSeed",       // We'll conditionally remove below
            "useHistoricalSampling",
            "useExtendedHistoricalSampling",
            "useVolShocks",
            "useGarchVolatility",
            "useAutoCorrelation",
            "autoCorrelationStrength",
            "meanReversionTarget",
            "useMeanReversion",
            "useRegimeSwitching",
            "lockHistoricalSampling"
            // "lockedRandomSeed"     // We'll conditionally remove below
        ]
        
        // If we're NOT locked, remove seed-related keys too (so it goes back to "random" by default)
        if !lockedRandomSeed {
            keysToRemove.append(contentsOf: ["seedValue", "lockedRandomSeed", "useRandomSeed"])
        }

        let defaults = UserDefaults.standard
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()

        // 4) Force periodUnit to weekly
        periodUnit = .weeks

        // 5) Reset your 'unified' slider properties to their midWeekly default
        halvingBumpUnified            = FactorCatalog.all["Halving"]?.midWeekly ?? 0.2773386887
        maxDemandBoostUnified         = FactorCatalog.all["InstitutionalDemand"]?.midWeekly ?? 0.00142485
        maxCountryAdBoostUnified      = FactorCatalog.all["CountryAdoption"]?.midWeekly ?? 0.0012868959977
        maxClarityBoostUnified        = FactorCatalog.all["RegulatoryClarity"]?.midWeekly ?? 0.0008361034861605167
        maxEtfBoostUnified            = FactorCatalog.all["EtfApproval"]?.midWeekly ?? 0.0020880183160305023
        maxTechBoostUnified           = FactorCatalog.all["TechBreakthrough"]?.midWeekly ?? 0.0007150633579173088
        maxScarcityBoostUnified       = FactorCatalog.all["ScarcityEvents"]?.midWeekly ?? 0.00047505153681182863
        maxMacroBoostUnified          = FactorCatalog.all["GlobalMacroHedge"]?.midWeekly ?? 0.0004126829724932909
        maxStablecoinBoostUnified     = FactorCatalog.all["StablecoinShift"]?.midWeekly ?? 0.0003919609116327763
        maxDemoBoostUnified           = FactorCatalog.all["DemographicAdoption"]?.midWeekly ?? 0.0012578432036626339
        maxAltcoinBoostUnified        = FactorCatalog.all["AltcoinFlight"]?.midWeekly ?? 0.0003222524461803342
        adoptionBaseFactorUnified     = FactorCatalog.all["AdoptionFactor"]?.midWeekly ?? 0.0018451869088897705
        maxClampDownUnified           = FactorCatalog.all["RegClampdown"]?.midWeekly ?? -0.0008449512243542672
        maxCompetitorBoostUnified     = FactorCatalog.all["CompetitorCoin"]?.midWeekly ?? -0.0008454221746411323
        breachImpactUnified           = FactorCatalog.all["SecurityBreach"]?.midWeekly ?? -0.0009009755168380737
        maxPopDropUnified             = FactorCatalog.all["BubblePop"]?.midWeekly ?? -0.001280529890762329
        maxMeltdownDropUnified        = FactorCatalog.all["StablecoinMeltdown"]?.midWeekly ?? -0.0004600706159477233
        blackSwanDropUnified          = FactorCatalog.all["BlackSwan"]?.midWeekly ?? -0.319108
        bearWeeklyDriftUnified        = FactorCatalog.all["BearMarket"]?.midWeekly ?? -0.0007278802752494812
        maxMaturingDropUnified        = FactorCatalog.all["MaturingMarket"]?.midWeekly ?? -0.0010537001055486196
        maxRecessionDropUnified       = FactorCatalog.all["Recession"]?.midWeekly ?? -0.0007494520467487811

        // 6) Reassign weekly advanced toggles to desired “on by default” values
        useLognormalGrowth = true
        useAnnualStep      = false

        // If we are not locked, revert to seed=0 / random seed
        // If locked, skip changing the seed or forcing random seed
        if !lockedRandomSeed {
            seedValue     = 0
            useRandomSeed = true
        } else {
            // If locked, ensure we actually use the locked seed
            useRandomSeed = false
        }

        useHistoricalSampling         = true
        useExtendedHistoricalSampling = true
        useVolShocks       = true
        useGarchVolatility = true
        useAutoCorrelation = true
        autoCorrelationStrength = 0.05
        meanReversionTarget = 0.03
        useMeanReversion   = true
        useRegimeSwitching = true
        lockHistoricalSampling = false

        // 7) Defer flipping isRestoringDefaults back to false
        DispatchQueue.main.async {
            self.isRestoringDefaults = false
        }
    }
}
