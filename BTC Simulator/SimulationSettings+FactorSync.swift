//
//  SimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/02/2025.
//

import SwiftUI

extension SimulationSettings {
    
    // MARK: - Global Baseline
    func globalBaseline(for factor: FactorState) -> Double {
        // Standard interpolation
        let t = factorIntensity
        if t < 0.5 {
            let ratio = t / 0.5
            // go from defaultValue down to minValue
            return factor.defaultValue - (factor.defaultValue - factor.minValue) * (1.0 - ratio)
        } else {
            let ratio = (t - 0.5) / 0.5
            // go from defaultValue up to maxValue
            return factor.defaultValue + (factor.maxValue - factor.defaultValue) * ratio
        }
    }
    
    func syncFactorsToGlobalIntensity() {
        for (name, var factor) in factors where factor.isEnabled && !factor.isLocked {
            let baseline = globalBaseline(for: factor)
            let range = factor.maxValue - factor.minValue

            // Proposed new value
            let newValue = baseline + factor.internalOffset * range

            // Clamp it
            let clamped = min(max(newValue, factor.minValue), factor.maxValue)
            
            // If we had to clamp, adjust offset so it stays consistent
            if clamped != newValue {
                factor.internalOffset = (clamped - baseline) / range
            }

            factor.currentValue = clamped
            factors[name] = factor
        }
    }

    func setFactorEnabled(factorName: String, enabled: Bool) {
        guard var factor = factors[factorName] else { return }

        if enabled {
            // Restore from frozenValue if it exists
            if let frozen = factor.frozenValue {
                let base = globalBaseline(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.currentValue = frozen
                factor.internalOffset = (frozen - base) / range
                factor.frozenValue = nil
            }
            factor.isEnabled = true
            factor.isLocked = false
            lockedFactors.remove(factorName)
        } else {
            // Freeze current value so we can restore later
            factor.frozenValue = factor.currentValue
            factor.isEnabled = false
            factor.isLocked = true
            lockedFactors.insert(factorName)
        }

        factors[factorName] = factor
    }

    func toggleAllFactors(on: Bool) {
        for (name, var factor) in factors {
            if on {
                // restore from frozen if needed
                if let frozen = factor.frozenValue {
                    let base = globalBaseline(for: factor)
                    let range = factor.maxValue - factor.minValue
                    factor.currentValue = frozen
                    factor.internalOffset = (frozen - base) / range
                    factor.frozenValue = nil
                }
                factor.isEnabled = true
                factor.isLocked = false
            } else {
                // freeze current value so we can restore later
                factor.frozenValue = factor.currentValue
                factor.isEnabled = false
                factor.isLocked = true
            }
            factors[name] = factor
        }
    }
}
