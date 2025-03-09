//
//  RestoreDefaultsMonthly.swift
//  BTCMonteCarlo
//
//  Created by ... on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    /// Restores monthly defaults, with an option to preserve user-entered fields (like starting balance, etc.).
    func restoreDefaultsMonthly(
        whenIn mode: PeriodUnit,
        preserveUserInputs: Bool = false
    ) {
        isRestoringDefaultsMonthly = true
        suspendUnifiedUpdates = true

        // 0) Clear locked factors
        lockedFactorsMonthly.removeAll()

        // 1) Rebuild the factor dictionary in one go
        var newFactors: [String: FactorState] = [:]
        for (factorName, def) in FactorCatalog.all {
            let (minVal, midVal, maxVal) = (def.minMonthly, def.midMonthly, def.maxMonthly)
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
        factorsMonthly = newFactors

        // 2) Reset factor intensity
        ignoreSyncMonthly = true
        rawFactorIntensityMonthly = 0.5
        extendedGlobalValueMonthly = 0.0
        ignoreSyncMonthly = false
        
        chartExtremeBearishMonthly = false
        chartExtremeBullishMonthly = false
        resetTiltBarMonthly()

        // 3) Prepare list of defaults keys to remove
        var keysToRemove: [String] = [
            "factorStatesMonthly",
            "rawFactorIntensityMonthly",
            defaultTiltKeyMonthly,
            maxSwingKeyMonthly,
            hasCapturedDefaultKeyMonthly,
            tiltBarValueKeyMonthly,
            "currencyPreferenceMonthly",
            periodUnitKeyMonthly,
            "useLognormalGrowthMonthly",
            "useHistoricalSamplingMonthly",
            "useVolShocksMonthly",
            "useGarchVolatilityMonthly",
            "useAutoCorrelationMonthly",
            "autoCorrelationStrengthMonthly",
            "meanReversionTargetMonthly",
            "useMeanReversionMonthly",
            "useRegimeSwitchingMonthly",
            "useExtendedHistoricalSamplingMonthly",
            "lockHistoricalSamplingMonthly"
        ]
        
        // Also remove the user inputs if we do NOT want to preserve them
        if !preserveUserInputs {
            keysToRemove.append(contentsOf: [
                "savedUserPeriodsMonthly",
                "savedInitialBTCPriceUSDMonthly",
                "savedStartingBalanceMonthly",
                "savedAverageCostBasisMonthly"
            ])
        }

        // If NOT locked, also remove seed-related keys so we revert to random
        if !lockedRandomSeedMonthly {
            keysToRemove.append(contentsOf: [
                "seedValueMonthly",
                "lockedRandomSeedMonthly",
                "useRandomSeedMonthly"
            ])
        }

        // Remove those keys from UserDefaults
        let defaults = UserDefaults.standard
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()

        // 4) Always remain in monthly mode
        periodUnitMonthly = .months

        // 5) Reset toggles to "factory" defaults
        useLognormalGrowthMonthly = true
        if !lockedRandomSeedMonthly {
            seedValueMonthly = 0
            useRandomSeedMonthly = true
        } else {
            useRandomSeedMonthly = false
        }
        useHistoricalSamplingMonthly = true
        useVolShocksMonthly = true
        useGarchVolatilityMonthly = true
        useAutoCorrelationMonthly = true
        autoCorrelationStrengthMonthly = 0.05
        meanReversionTargetMonthly = 0.03
        useMeanReversionMonthly = true
        useRegimeSwitchingMonthly = true
        useExtendedHistoricalSamplingMonthly = true
        lockHistoricalSamplingMonthly = false

        // 6) Done
        isRestoringDefaultsMonthly = false

        DispatchQueue.main.async {
            self.suspendUnifiedUpdates = false
        }

        // 7) Save the new state
        self.saveToUserDefaultsMonthly()
    }
}
