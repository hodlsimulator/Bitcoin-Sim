//
//  SimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/02/2025.
//

import SwiftUI

extension SimulationSettings {
    
    // MARK: - Computed Global Slider
    var factorIntensity: Double {
        get {
            rawFactorIntensity
        }
        set {
            rawFactorIntensity = newValue
            syncFactorsToGlobalIntensity()
        }
    }
    
    // MARK: - Sync Factors
    func syncFactorsToGlobalIntensity() {
        for (name, var factor) in factors where factor.isEnabled && !factor.isLocked {
            let baseline = globalBaseline(for: factor)
            let range = factor.maxValue - factor.minValue
            let newValue = baseline + factor.internalOffset * range
            
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
        let oldActive = factors.values.filter { $0.isEnabled && !$0.isLocked }
        
        guard var factor = factors[factorName] else {
            print("[Factor Debug] setFactorEnabled(\(factorName), \(enabled)): not found!")
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
            
            if chartExtremeBearish && factor.currentValue > factor.minValue {
                chartExtremeBearish = false
            }
            if chartExtremeBullish && factor.currentValue < factor.maxValue {
                chartExtremeBullish = false
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
        overrodeTiltManually = true
        
        // Shift the global slider to mimic manual slider movement
        if !userIsActuallyTogglingAll {
            ignoreSync = true
            if enabled {
                let newActiveCount = oldActive.count + 1
                if newActiveCount > 0 {
                    let shift = factor.internalOffset / Double(newActiveCount)
                    rawFactorIntensity = min(max(rawFactorIntensity + shift, 0.0), 1.0)
                }
            } else {
                let activeCount = oldActive.count
                if activeCount > 0 {
                    let shift = factor.internalOffset / Double(activeCount)
                    rawFactorIntensity = min(max(rawFactorIntensity - shift, 0.0), 1.0)
                }
            }
            ignoreSync = false
            syncFactors()
        }
        
        applyDictionaryFactorsToSim()
    }
    
    // MARK: - Toggle All Factors
    func toggleAllFactors(on: Bool) {
        userIsActuallyTogglingAll = true
        
        for (name, var factor) in factors {
            if on {
                // Re-enable factor
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    print("[toggleAll (monthly)] Restoring factor \(name) -> \(frozen)")
                    let base = globalBaseline(for: factor)
                    let range = factor.maxValue - factor.minValue
                    factor.internalOffset = (frozen - base) / range
                    print("[toggleAll (monthly)]   New offset = \(factor.internalOffset) for factor \(name)")
                    factor.frozenValue = nil
                }
                factor.isEnabled = true
                factor.isLocked = false
                factor.wasChartForced = false
            } else {
                // Disable factor
                factor.frozenValue = factor.currentValue
                print("[toggleAll (monthly)] Freezing factor \(name) at \(factor.currentValue)")
                factor.isEnabled = false
                factor.isLocked = true
            }
            factors[name] = factor
        }
        
        // Done toggling all, reset the flag
        userIsActuallyTogglingAll = false
        
        // Optionally re-sync factors
        syncFactorsToGlobalIntensity()
        
        // Recalc tilt bar so it goes back to neutral if everything is on
        let bullishKeys: [String] = [
            "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
            "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
            "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
        ]
        let bearishKeys: [String] = [
            "RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
            "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket",
            "Recession"
        ]
        
        recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
        applyDictionaryFactorsToSim()
    }
}
