//
//  RestoreDefaultsMonthly.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    func restoreDefaultsMonthly() {
        print("[restoreDefaultsMonthly] Restoring defaults for monthly.")
        
        // Mark that we are restoring
        isRestoringDefaultsMonthly = true
        
        // Clear locked monthly factors
        lockedFactorsMonthly.removeAll()
        
        let defaults = UserDefaults.standard
        
        // Remove monthly factor states & intensity
        defaults.removeObject(forKey: "factorStatesMonthly")
        defaults.removeObject(forKey: "rawFactorIntensityMonthly")
        
        // Reset chart extremes
        chartExtremeBearishMonthly = false
        chartExtremeBullishMonthly = false
        
        // Remove advanced monthly toggles if you want them to revert
        defaults.removeObject(forKey: "useLognormalGrowthMonthly")
        defaults.removeObject(forKey: "useAnnualStepMonthly")
        defaults.removeObject(forKey: "lockedRandomSeedMonthly")
        defaults.removeObject(forKey: "seedValueMonthly")
        defaults.removeObject(forKey: "useRandomSeedMonthly")
        defaults.removeObject(forKey: "useHistoricalSamplingMonthly")
        defaults.removeObject(forKey: "useExtendedHistoricalSamplingMonthly")
        defaults.removeObject(forKey: "useVolShocksMonthly")
        defaults.removeObject(forKey: "useGarchVolatilityMonthly")
        defaults.removeObject(forKey: "useAutoCorrelationMonthly")
        defaults.removeObject(forKey: "autoCorrelationStrengthMonthly")
        defaults.removeObject(forKey: "meanReversionTargetMonthly")
        defaults.removeObject(forKey: "useMeanReversionMonthly")
        defaults.removeObject(forKey: "useRegimeSwitchingMonthly")
        defaults.removeObject(forKey: "lockHistoricalSamplingMonthly")
        
        // Remove monthly currency preference & period unit if you want them reset
        defaults.removeObject(forKey: "currencyPreferenceMonthly")
        defaults.removeObject(forKey: "savedPeriodUnitMonthly")
        
        // Rebuild from scratch in code:
        rawFactorIntensityMonthly = 0.5
        
        // Reset each monthly factor to its default
        for (factorName, var factor) in factorsMonthly {
            factor.isEnabled = true
            factor.currentValue = factor.defaultValue
            factor.isLocked = false
            factor.internalOffset = 0.0
            factorsMonthly[factorName] = factor
        }
        
        // If you track monthly tilt bar
        resetTiltBarMonthly()
        
        // Persist these changes
        defaults.synchronize()
        
        // End restore
        DispatchQueue.main.async {
            self.isRestoringDefaultsMonthly = false
        }
        
        print("[restoreDefaultsMonthly] Completed monthly defaults restore.")
    }
}
