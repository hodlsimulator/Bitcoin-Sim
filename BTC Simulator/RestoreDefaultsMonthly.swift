//
//  RestoreDefaultsMonthly.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    func restoreDefaultsMonthly(whenIn mode: PeriodUnit) {
        // Removed the guard so this always executes:
        // guard mode != .weeks else {
        //     print("Skipping monthly restore because weekly mode is active")
        //     return
        // }

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

        // 2) Reset rawFactorIntensityMonthly, chart extremes, tilt bar
        rawFactorIntensityMonthly = 0.5
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

        // 4) Decide post-reset mode (remain monthly)
        periodUnitMonthly = .months
        print("[restoreDefaultsMonthly] periodUnitMonthly set to: \(periodUnitMonthly)")

        // 5) Re-assign advanced toggles to your preferred fresh defaults
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

        print("[restoreDefaultsMonthly] Advanced toggles reset:")
        print("   useLognormalGrowthMonthly: \(useLognormalGrowthMonthly)")
        print("   lockedRandomSeedMonthly: \(lockedRandomSeedMonthly)")
        print("   useRandomSeedMonthly: \(useRandomSeedMonthly)")
        print("   useHistoricalSamplingMonthly: \(useHistoricalSamplingMonthly)")
        print("   useVolShocksMonthly: \(useVolShocksMonthly)")
        print("   useGarchVolatilityMonthly: \(useGarchVolatilityMonthly)")
        print("   useAutoCorrelationMonthly: \(useAutoCorrelationMonthly)")
        print("   autoCorrelationStrengthMonthly: \(autoCorrelationStrengthMonthly)")
        print("   meanReversionTargetMonthly: \(meanReversionTargetMonthly)")
        print("   useMeanReversionMonthly: \(useMeanReversionMonthly)")
        print("   useRegimeSwitchingMonthly: \(useRegimeSwitchingMonthly)")
        print("   useExtendedHistoricalSamplingMonthly: \(useExtendedHistoricalSamplingMonthly)")
        print("   lockHistoricalSamplingMonthly: \(lockHistoricalSamplingMonthly)")

        // 6) Done with restore
        isRestoringDefaultsMonthly = false
        print("[restoreDefaultsMonthly] Completed monthly defaults reset.")

        // Turn off suspend after a short delay:
        DispatchQueue.main.async {
            self.suspendUnifiedUpdates = false
            print("[restoreDefaultsMonthly] suspendUnifiedUpdates set to false.")
        }

        self.saveToUserDefaultsMonthly()
    }
}
