//
//  SimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/02/2025.
//

import SwiftUI

extension SimulationSettings {
    
    // MARK: - Computed Global Slider
    //
    // Instead of calling getFactorIntensity() or setFactorIntensity(_:) somewhere else,
    // you can now just do: simSettings.factorIntensity = 0.7
    // -> This triggers syncFactorsToGlobalIntensity() automatically.
    //
    var factorIntensity: Double {
        get {
            rawFactorIntensity
        }
        set {
            rawFactorIntensity = newValue
            // Replicate the test app logic: whenever factorIntensity changes, sync
            syncFactorsToGlobalIntensity()
        }
    }
    
    // MARK: - Global Baseline
    // Same as before, but we read factorIntensity from the new computed property above.
    func globalBaseline(for factor: FactorState) -> Double {
        let t = factorIntensity
        if t < 0.5 {
            let ratio = t / 0.5
            // from defaultValue down to minValue
            return factor.defaultValue - (factor.defaultValue - factor.minValue) * (1.0 - ratio)
        } else {
            let ratio = (t - 0.5) / 0.5
            // from defaultValue up to maxValue
            return factor.defaultValue + (factor.maxValue - factor.defaultValue) * ratio
        }
    }
    
    // MARK: - Sync Factors
    func syncFactorsToGlobalIntensity() {
        for (name, var factor) in factors where factor.isEnabled && !factor.isLocked {
            let baseline = globalBaseline(for: factor)
            let range = factor.maxValue - factor.minValue
            let newValue = baseline + factor.internalOffset * range
            
            // Clamp if out of bounds
            let clamped = min(max(newValue, factor.minValue), factor.maxValue)
            if clamped != newValue {
                factor.internalOffset = (clamped - baseline) / range
            }
            
            factor.currentValue = clamped
            factors[name] = factor
            
        }
    }
    
    // MARK: - Enable/Disable Individual Factor
    func setFactorEnabled(factorName: String, enabled: Bool) {
        guard var factor = factors[factorName] else {
            print("[Factor Debug] setFactorEnabled(\(factorName), \(enabled)): factor not found!")
            return
        }
        
        if enabled {
            if let frozen = factor.frozenValue {
                factor.currentValue = frozen
                let base = globalBaseline(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.internalOffset = (frozen - base) / range
                
                factor.frozenValue = nil
                factor.wasChartForced = false
            }
            factor.isEnabled = true
            factor.isLocked = false
            lockedFactors.remove(factorName)
        } else {
            factor.frozenValue = factor.currentValue
            factor.isEnabled = false
            factor.isLocked = true
            lockedFactors.insert(factorName)
        }
        
        factors[factorName] = factor
        
        // Recalculate tilt bar to apply sign-flip logic
        recalcTiltBarValue(
            bullishKeys: [
                "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
                "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
                "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
            ],
            bearishKeys: [
                "RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
                "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket",
                "Recession"
            ]
        )
    }

    // MARK: - Toggle All Factors
    func toggleAllFactors(on: Bool) {
        for (name, var factor) in factors {
            if on {
                // Re-enable
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    print("[toggleAll] Restoring factor \(name) -> \(frozen)")
                    
                    let base = globalBaseline(for: factor)
                    let range = factor.maxValue - factor.minValue
                    factor.internalOffset = (frozen - base) / range
                    print("[toggleAll]   New offset = \(factor.internalOffset) for factor \(name)")
                    
                    factor.frozenValue = nil
                }
                factor.isEnabled = true
                factor.isLocked = false
                factor.wasChartForced = false
            } else {
                // Disable
                factor.frozenValue = factor.currentValue
                print("[toggleAll] Freezing factor \(name) at \(factor.currentValue)")
                
                factor.isEnabled = false
                factor.isLocked = true
            }
            factors[name] = factor
        }
        
        // If your architecture calls sync immediately here, do it:
        // syncFactorsToGlobalIntensity()
    }
}
