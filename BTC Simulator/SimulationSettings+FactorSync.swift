//
//  SimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 31/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// Called whenever the global slider (factorIntensity) changes.
    /// Maps factorIntensity in [0..1] onto each factor’s range [minValue..maxValue]
    /// around its defaultValue, provided the factor isEnabled && not isLocked.
    func syncFactorsToGlobalIntensity() {
        for (factorName, var factor) in factors {
            // Only update if the factor is enabled & not locked
            guard factor.isEnabled, !factor.isLocked else {
                continue
            }
            
            let t = factorIntensity  // in [0..1]
            if t < 0.5 {
                // Range from factor.defaultValue down to factor.minValue
                let ratio = t / 0.5
                factor.currentValue = factor.defaultValue -
                    (factor.defaultValue - factor.minValue) * (1.0 - ratio)
            } else {
                // Range from factor.defaultValue up to factor.maxValue
                let ratio = (t - 0.5) / 0.5
                factor.currentValue = factor.defaultValue +
                    (factor.maxValue - factor.defaultValue) * ratio
            }
            
            // Write the updated factor back
            factors[factorName] = factor
        }
    }
}
