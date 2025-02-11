//
//  RestoreDefaultsMonthly.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    func restoreDefaultsMonthly() {
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
        
        // 4) Decide post-reset mode (remain monthly)
        periodUnitMonthly = .months
        
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
        
        // 6) Done with restore
        isRestoringDefaultsMonthly = false
        print("[restoreDefaultsMonthly] Completed monthly defaults reset.")
        
        // Turn off suspend after a short delay:
        DispatchQueue.main.async {
            self.suspendUnifiedUpdates = false
        }
    }
}

