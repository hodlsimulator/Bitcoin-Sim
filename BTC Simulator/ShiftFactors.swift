//
//  ShiftFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {
    
    /// Shift all enabled factors’ currentValue by `delta` * (maxVal - minVal).
    /// We clamp to each factor’s [minValue..maxValue].
    func shiftAllFactors(by delta: Double) {
        for (factorName, var factor) in simSettings.factors {
            // Only shift if factor is enabled
            guard factor.isEnabled else { continue }
            
            let range = factor.maxValue - factor.minValue
            let shifted = factor.currentValue + delta * range
            
            // Clamp within [minValue..maxValue]
            factor.currentValue = max(factor.minValue, min(shifted, factor.maxValue))
            
            // Put the factor back into the dictionary
            simSettings.factors[factorName] = factor
        }
    }
    
    // OPTIONAL: If you had an “updateUniversalFactorIntensity()” function that
    // computed an “average normalised value” across all factors, you might do:
    func updateUniversalFactorIntensity() {
        var totalNorm = 0.0
        var countEnabled = 0
        
        for (_, factor) in simSettings.factors {
            if factor.isEnabled {
                let norm = (factor.currentValue - factor.minValue)
                            / (factor.maxValue - factor.minValue)
                totalNorm += norm
                countEnabled += 1
            }
        }
        guard countEnabled > 0 else { return }
        
        // E.g. set the global slider to the average normalised value
        let average = totalNorm / Double(countEnabled)
        simSettings.setFactorIntensity(average)  // <<-- we call setFactorIntensity(...) now
    }
    
    // OPTIONAL: If you want an “animateFactor” function to turn a factor on/off with a SwiftUI animation:
    func animateFactor(_ factorName: String, newEnabled: Bool) {
        guard var factor = simSettings.factors[factorName] else { return }

        // Example: animate toggling factor.isEnabled
        withAnimation(.easeInOut(duration: 0.6)) {
            factor.isEnabled = newEnabled
            
            // If turning it on, maybe reset currentValue to defaultValue
            if newEnabled {
                factor.currentValue = factor.defaultValue
            }
            simSettings.factors[factorName] = factor
        }
    }
    
    // OPTIONAL: If you want to “sync factor’s currentValue to the global slider”
    // E.g. factorIntensity in [0..1], then map to [factor.minValue..factor.maxValue].
    func syncFactorToSlider(_ factorName: String) {
        guard var factor = simSettings.factors[factorName] else { return }
        let t = simSettings.getFactorIntensity() // <<-- we call getFactorIntensity() now
        factor.currentValue = factor.minValue + t * (factor.maxValue - factor.minValue)
        simSettings.factors[factorName] = factor
    }
}
