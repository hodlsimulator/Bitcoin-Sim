//
//  SimulationSettings+RestoreDefaults.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    func restoreDefaults() {
        print("[restoreDefaults (weekly)] Restoring all weekly defaults in one pass.")
        isRestoringDefaults = true

        // 0) Clear locked factors
        lockedFactors.removeAll()

        // 1) Rebuild the dictionary in one go
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
        rawFactorIntensity = 0.5
        chartExtremeBearish = false
        chartExtremeBullish = false
        resetTiltBar()

        // 3) Remove user defaults
        let keysToRemove = [
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
            "lockedRandomSeed",
            "seedValue",
            "useRandomSeed",
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
        ]
        let defaults = UserDefaults.standard
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()

        // 4) Decide post-reset mode (stay weekly)
        periodUnit = .weeks

        // 5) Avoid reloading from user defaults
        isRestoringDefaults = false
        print("[restoreDefaults (weekly)] Completed weekly defaults reset.")
    }
}
