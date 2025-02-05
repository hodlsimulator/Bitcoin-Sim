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
        
        // IMPORTANT: clear all locked factors so they can be changed again
        lockedFactors.removeAll()
        
        print("RESTORE DEFAULTS CALLED!")
        
        let defaults = UserDefaults.standard
        
        // Remove old factorIntensity and set it to a default
        defaults.removeObject(forKey: "factorIntensity")
        factorIntensity = 0.5
        
        // Reset chart icon flags
        chartExtremeBearish = false
        chartExtremeBullish = false
        
        // Keep any general toggles you still want
        // e.g. re-save them if needed:
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks,         forKey: "useVolShocks")

        // Remove old keys (the lines you already had)
        defaults.removeObject(forKey: "useHalving")     // etc. ...
        defaults.removeObject(forKey: "halvingBump")    // ...
        // ...

        defaults.removeObject(forKey: "useHistoricalSampling")
        defaults.removeObject(forKey: "useVolShocks")
        defaults.removeObject(forKey: "useGarchVolatility")
        defaults.removeObject(forKey: "useAutoCorrelation")
        defaults.removeObject(forKey: "autoCorrelationStrength")
        defaults.removeObject(forKey: "meanReversionTarget")

        // Remove old weekly/monthly keys if you haven’t fully migrated
        defaults.removeObject(forKey: "useHalvingWeekly")
        defaults.removeObject(forKey: "halvingBumpWeekly")
        // ... etc.

        // Remove or reset the lognormal growth key
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true

        // Reassign toggles to your chosen defaults
        useHistoricalSampling = true
        useVolShocks = true
        useGarchVolatility = true
        useRegimeSwitching = true  // or whatever default you prefer

        // If you still had old booleans or unified values, remove them or comment them out
        // e.g. halvingBumpUnified, factorEnableFrac references, etc.

        // Reset lockHistoricalSampling if you still use it
        lockHistoricalSampling = false

        // Reset final toggles
        useLognormalGrowth = true
        useHistoricalSampling = true
        useVolShocks = true
        useGarchVolatility = true

        // =========================================================
        // NEW: Loop over the factors dictionary
        //      so each factor is set to default.
        // =========================================================
        for (factorName, var factor) in factors {
            // If you want them all “on” by default:
            factor.isEnabled = true
            // Or if you want them all “off,” do factor.isEnabled = false

            // Reset the numeric value to the default
            factor.currentValue = factor.defaultValue

            // Unlock it
            factor.isLocked = false

            // Put it back
            factors[factorName] = factor
        }

        // Finally, write changes to disk
        defaults.synchronize()
        
        // 2) Delay turning isRestoringDefaults off so the changes “settle”
        DispatchQueue.main.async {
            self.isRestoringDefaults = false
        }
    }
}
