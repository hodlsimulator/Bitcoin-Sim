//
//  RestoreDefaultsMonthly.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    func restoreDefaultsMonthly(whenIn mode: PeriodUnit) {
        print("[restoreDefaultsMonthly] Restoring all monthly defaults in one pass.")
        isRestoringDefaultsMonthly = true
        suspendUnifiedUpdates = true

        // 0) Clear locked factors
        lockedFactorsMonthly.removeAll()

        // 1) Rebuild the dictionary in one go
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

        // 2) Reset to centre. Make sure rawFactorIntensity=0.5 AND extendedGlobalValue=0.0
        ignoreSyncMonthly = true
        rawFactorIntensityMonthly = 0.5
        extendedGlobalValueMonthly = 0.0
        ignoreSyncMonthly = false
        
        chartExtremeBearishMonthly = false
        chartExtremeBullishMonthly = false
        resetTiltBarMonthly()

        // 3) Remove the relevant UserDefaults keys
        let keysToRemove = [
            "factorStatesMonthly",
            "rawFactorIntensityMonthly",
            defaultTiltKeyMonthly,
            maxSwingKeyMonthly,
            hasCapturedDefaultKeyMonthly,
            tiltBarValueKeyMonthly,
            "savedUserPeriodsMonthly",
            "savedInitialBTCPriceUSDMonthly",
            "savedStartingBalanceMonthly",
            "savedAverageCostBasisMonthly",
            "currencyPreferenceMonthly",
            periodUnitKeyMonthly,
            "useLognormalGrowthMonthly",
            "lockedRandomSeedMonthly",
            "useRandomSeedMonthly",
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
        let defaults = UserDefaults.standard
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        print("[restoreDefaultsMonthly] Removed UserDefaults keys.")

        // 4) Remain in monthly mode
        periodUnitMonthly = .months
        print("[restoreDefaultsMonthly] periodUnitMonthly set to: \(periodUnitMonthly)")

        // 5) Re-assign advanced toggles to fresh defaults
        useLognormalGrowthMonthly      = true
        lockedRandomSeedMonthly        = false
        useRandomSeedMonthly           = true
        useHistoricalSamplingMonthly   = true
        useVolShocksMonthly            = true
        useGarchVolatilityMonthly      = true
        useAutoCorrelationMonthly      = true
        autoCorrelationStrengthMonthly = 0.05
        meanReversionTargetMonthly     = 0.03
        useMeanReversionMonthly        = true
        useRegimeSwitchingMonthly      = true
        useExtendedHistoricalSamplingMonthly = true
        lockHistoricalSamplingMonthly  = false

        print("[restoreDefaultsMonthly] Advanced toggles reset.")
        
        // 6) Done
        isRestoringDefaultsMonthly = false
        print("[restoreDefaultsMonthly] Completed monthly defaults reset.")

        DispatchQueue.main.async {
            self.suspendUnifiedUpdates = false
            print("[restoreDefaultsMonthly] suspendUnifiedUpdates set to false.")
        }

        self.saveToUserDefaultsMonthly()
    }
}
