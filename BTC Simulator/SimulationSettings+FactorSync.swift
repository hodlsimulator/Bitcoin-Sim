//
//  SimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/02/2025.
//

import SwiftUI

extension SimulationSettings {
    static let bullishTiltValuesWeekly: [String: Double] = [
            "halving":            25.41,
            "institutionaldemand": 8.30,
            "countryadoption":     8.19,
            "regulatoryclarity":   7.46,
            "etfapproval":         8.94,
            "techbreakthrough":    7.20,
            "scarcityevents":      6.66,
            "globalmacrohedge":    6.43,
            "stablecoinshift":     6.37,
            "demographicadoption": 8.06,
            "altcoinflight":       6.19,
            "adoptionfactor":      8.75
        ]
        
        static let bearishTiltValuesWeekly: [String: Double] = [
            "regclampdown":       9.66,
            "competitorcoin":     9.46,
            "securitybreach":     9.60,
            "bubblepop":         10.57,
            "stablecoinmeltdown": 8.79,
            "blackswan":         31.21,
            "bearmarket":         9.18,
            "maturingmarket":    10.29,
            "recession":          9.22
        ]
    
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
        guard var factor = factors[factorName] else { return }
        if factor.isEnabled == enabled { return }
        
        let lowerName = factorName.lowercased()
        let toggleAmount: Double = {
            if let val = SimulationSettings.bullishTiltValuesWeekly[lowerName] {
                return val
            } else if let val = SimulationSettings.bearishTiltValuesWeekly[lowerName] {
                return val
            }
            return 9.0
        }()
        
        if !enabled {
            // Toggling OFF
            if !userIsActuallyTogglingAll {
                extendedGlobalValue -= toggleAmount
            }
            factor.frozenValue = factor.currentValue
            factor.isEnabled = false
            factor.isLocked = true
            lockedFactors.insert(factorName)
        } else {
            // Toggling ON
            if let frozen = factor.frozenValue {
                factor.currentValue = frozen
                factor.frozenValue = nil
                let base = globalBaseline(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.internalOffset = (factor.currentValue - base) / range
            }
            
            if !userIsActuallyTogglingAll {
                extendedGlobalValue += toggleAmount
            }
            
            factor.isEnabled = true
            factor.isLocked = false
            lockedFactors.remove(factorName)
        }
        
        factors[factorName] = factor
        overrodeTiltManually = true

        // Skip the usual sync if toggling all
        if !userIsActuallyTogglingAll {
            ignoreSync = true
            // e.g. syncFactors() or syncFactorsToGlobalIntensity() if needed
            ignoreSync = false
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
