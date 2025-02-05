//
//  SimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/02/2025.
//

import SwiftUI

extension SimulationSettings {
    
    func globalBaselineFor(_ factor: FactorState) -> Double {
        let t = factorIntensity  // in [0,1]
        let baseline: Double
        if t < 0.5 {
            let ratio = t / 0.5
            baseline = factor.defaultValue - (factor.defaultValue - factor.minValue) * (1.0 - ratio)
        } else {
            let ratio = (t - 0.5) / 0.5
            baseline = factor.defaultValue + (factor.maxValue - factor.defaultValue) * ratio
        }
        if factor.name == "Halving" {
            print("[GlobalBaseline] Halving: t=\(t), baseline=\(baseline)")
        }
        return baseline
    }
    
    func syncFactorsToGlobalIntensity() {
        let toleranceFactor = 0.005  // 0.5% relative tolerance
        
        // Upper extreme case:
        if factorIntensity >= 0.99 {
            var totalRelativeDev = 0.0
            var count = 0.0
            // For each enabled factor, compute relative deviation from its maximum.
            for (_, factor) in factors where factor.isEnabled && !factor.isLocked {
                let baseline = globalBaselineFor(factor)
                let range = factor.maxValue - factor.minValue
                let computed = baseline + factor.internalOffset * range
                // Relative deviation: how far is computed from max, as a fraction of the range?
                let relativeDev = (factor.maxValue - computed) / range
                totalRelativeDev += relativeDev
                count += 1
            }
            let avgRelativeDev = count > 0 ? totalRelativeDev / count : 0.0
            if avgRelativeDev < toleranceFactor {
                // If on average the computed values are very close to the max, reset offsets.
                for (name, var factor) in factors where factor.isEnabled && !factor.isLocked {
                    factor.internalOffset = 0.0
                    factor.currentValue = factor.maxValue
                    factors[name] = factor
                }
                return  // All done for this sync cycle.
            }
        }
        // Lower extreme case:
        else if factorIntensity <= 0.01 {
            var totalRelativeDev = 0.0
            var count = 0.0
            // For each enabled factor, compute relative deviation from its minimum.
            for (_, factor) in factors where factor.isEnabled && !factor.isLocked {
                let baseline = globalBaselineFor(factor)
                let range = factor.maxValue - factor.minValue
                let computed = baseline + factor.internalOffset * range
                // Relative deviation: how far is computed above min, as a fraction of the range?
                let relativeDev = (computed - factor.minValue) / range
                totalRelativeDev += relativeDev
                count += 1
            }
            let avgRelativeDev = count > 0 ? totalRelativeDev / count : 0.0
            if avgRelativeDev < toleranceFactor {
                for (name, var factor) in factors where factor.isEnabled && !factor.isLocked {
                    factor.internalOffset = 0.0
                    factor.currentValue = factor.minValue
                    factors[name] = factor
                }
                return
            }
        }
        
        // Normal sync: update each factor based on the global slider and its stored offset.
        for (name, var factor) in factors {
            guard factor.isEnabled, !factor.isLocked else { continue }
            let baseline = globalBaselineFor(factor)
            let range = factor.maxValue - factor.minValue
            let newValue = baseline + factor.internalOffset * range
            factor.currentValue = newValue
            factors[name] = factor
        }
    }
    
    // MARK: - Toggling a Factor On/Off with Extra Logging for "Halving"
    func setFactorEnabled(factorName: String, enabled: Bool) {
        print("setFactorEnabled called for \(factorName) with enabled=\(enabled)")
        guard var factor = factors[factorName] else { return }
        
        let range = factor.maxValue - factor.minValue
        
        if enabled {
            print("[Toggle On] \(factorName): globalIntensity=\(factorIntensity)")
            // When toggling on, if we have a frozenValue, use it:
            if let frozen = factor.frozenValue {
                let newBaseline = globalBaselineFor(factor)
                // Update internalOffset so that:
                // currentValue = newBaseline + internalOffset * range == frozen
                factor.internalOffset = (frozen - newBaseline) / range
                factor.currentValue = frozen
                factor.frozenValue = nil  // clear it now that we've restored
            }
            factor.isEnabled = true
            factor.isLocked = false
            factor.savedGlobalIntensity = factorIntensity
            lockedFactors.remove(factorName)
        } else {
            let base = globalBaselineFor(factor)
            // Record the offset as before...
            factor.internalOffset = (factor.currentValue - base) / range
            // Also store the current value so we can restore it later.
            factor.frozenValue = factor.currentValue
            print("[Toggle Off] \(factorName): base=\(base), currentValue=\(factor.currentValue), internalOffset=\(factor.internalOffset)")
            factor.savedGlobalIntensity = nil
            factor.isEnabled = false
            factor.isLocked = true
            lockedFactors.insert(factorName)
        }
        
        factors[factorName] = factor
    }
}
