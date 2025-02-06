//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    /// Shift all enabled factors’ currentValue by `delta * (maxVal - minVal)`.
    /// After shifting, we recalc each factor's offset so it remains consistent
    /// with the global slider baseline in the future.
    func shiftAllFactors(by delta: Double) {
        for (factorName, var factor) in simSettings.factors {
            guard factor.isEnabled else { continue }
            
            let range = factor.maxValue - factor.minValue
            let shifted = factor.currentValue + delta * range
            
            // Clamp within [minValue..maxValue]
            let clamped = max(factor.minValue, min(shifted, factor.maxValue))
            factor.currentValue = clamped
            
            // Recalc offset so future slider changes keep this new position
            let base = simSettings.globalBaseline(for: factor)
            factor.internalOffset = (clamped - base) / range
            
            simSettings.factors[factorName] = factor
        }
    }
    
    /// (Optional) Recompute a "universal" factorIntensity by averaging all enabled factors.
    /// Then assign it, which triggers syncFactorsToGlobalIntensity().
    func updateUniversalFactorIntensity() {
        var totalNorm = 0.0
        var countEnabled = 0
        
        for (_, factor) in simSettings.factors {
            if factor.isEnabled {
                // Normalised 0..1 for each factor
                let norm = (factor.currentValue - factor.minValue)
                           / (factor.maxValue - factor.minValue)
                totalNorm += norm
                countEnabled += 1
            }
        }
        guard countEnabled > 0 else { return }
        
        let average = totalNorm / Double(countEnabled)
        simSettings.factorIntensity = average
    }
    
    /// Example: animate toggling a factor on/off with SwiftUI.
    /// If turning on, we restore from .frozenValue if present (so we don’t snap to mid).
    /// Otherwise, we do factor.defaultValue.
    func animateFactor(_ factorName: String, newEnabled: Bool) {
        guard var factor = simSettings.factors[factorName] else { return }
        
        withAnimation(.easeInOut(duration: 0.6)) {
            factor.isEnabled = newEnabled
            if newEnabled {
                // CHANGED HERE: Only reset to default if we have no frozenValue
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    factor.frozenValue = nil
                } else {
                    factor.currentValue = factor.defaultValue
                }
                
                // Recalc offset
                let base = simSettings.globalBaseline(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.internalOffset = (factor.currentValue - base) / range
                factor.isLocked = false
            } else {
                // Freeze currentValue so we can restore it on re-enable
                factor.frozenValue = factor.currentValue
                factor.isLocked = true
            }
            simSettings.factors[factorName] = factor
        }
    }
    
    /// Sync a single factor’s currentValue to the global slider in a simplistic manner:
    /// factor.currentValue = factor.minValue + factorIntensity*(range).
    /// Then recalc offset so future changes track that baseline consistently.
    func syncFactorToSlider(_ factorName: String) {
        guard var factor = simSettings.factors[factorName] else { return }
        
        let t = simSettings.factorIntensity
        let range = factor.maxValue - factor.minValue
        let newVal = factor.minValue + t * range
        
        factor.currentValue = newVal
        
        // Recalc offset so next global slider move keeps that newVal
        let base = simSettings.globalBaseline(for: factor)
        factor.internalOffset = (newVal - base) / range
        
        simSettings.factors[factorName] = factor
    }
}
