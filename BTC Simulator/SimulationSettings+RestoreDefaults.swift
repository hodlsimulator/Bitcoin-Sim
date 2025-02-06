//
//  SimulationSettings+RestoreDefaults.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    func restoreDefaults() {
        // Signal that a bulk restore is in progress
        isRestoringDefaults = true
        
        // Clear locked factors
        lockedFactors.removeAll()
        
        print("RESTORE DEFAULTS CALLED!")
        
        let defaults = UserDefaults.standard
        
        // Reset global factor intensity
        defaults.removeObject(forKey: "factorIntensity")
        setFactorIntensity(0.5) // <-- call the setter, not factorIntensity = 0.5
        
        // Remove saved factor states so they’re rebuilt on next load
        defaults.removeObject(forKey: "factorStates")
        
        // Reset chart flags
        chartExtremeBearish = false
        chartExtremeBullish = false
        
        // Preserve any general toggles if desired
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks, forKey: "useVolShocks")
        
        // Remove old keys
        defaults.removeObject(forKey: "useHalving")
        defaults.removeObject(forKey: "halvingBump")
        
        defaults.removeObject(forKey: "useHistoricalSampling")
        defaults.removeObject(forKey: "useVolShocks")
        defaults.removeObject(forKey: "useGarchVolatility")
        defaults.removeObject(forKey: "useAutoCorrelation")
        defaults.removeObject(forKey: "autoCorrelationStrength")
        defaults.removeObject(forKey: "meanReversionTarget")
        
        defaults.removeObject(forKey: "useHalvingWeekly")
        defaults.removeObject(forKey: "halvingBumpWeekly")
        
        // Reset lognormal growth
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true
        
        // Reassign toggles to defaults
        useHistoricalSampling = true
        useVolShocks = true
        useGarchVolatility = true
        useRegimeSwitching = true
        
        lockHistoricalSampling = false
        
        useLognormalGrowth = true
        useHistoricalSampling = true
        useVolShocks = true
        useGarchVolatility = true
        
        // Loop over the factors and reset them to defaults
        for (factorName, var factor) in factors {
            factor.isEnabled = true
            factor.currentValue = factor.defaultValue
            factor.isLocked = false
            factors[factorName] = factor
        }
        
        defaults.synchronize()
        
        // Turn off the bulk restore flag after changes settle
        DispatchQueue.main.async {
            self.isRestoringDefaults = false
        }
    }
}
