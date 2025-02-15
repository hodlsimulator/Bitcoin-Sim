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
        print("[Debug] weekly setFactorEnabled for \(factorName), newValue: \(enabled)")
        
        // 1. Make sure this factor exists in the dictionary
        guard var factor = factors[factorName] else {
            print("[Factor Debug] setFactorEnabled(\(factorName), \(enabled)): not found!")
            return
        }
        
        // 2. If there's no actual change, do nothing
        if factor.isEnabled == enabled {
            print("[Debug] Factor \(factorName) already enabled = \(enabled). Doing nothing.")
            return
        }
        
        // 3. Find the tilt value from your dictionaries.
        //    We'll fallback to 9.0 if not found in either dict.
        let lowerName = factorName.lowercased()
        let toggleAmount: Double = {
            if let val = SimulationSettings.bullishTiltValuesWeekly[lowerName] {
                return val
            } else if let val = SimulationSettings.bearishTiltValuesWeekly[lowerName] {
                return val
            } else {
                return 9.0 // fallback if not found
            }
        }()
        
        // We'll skip shifting the global tilt if:
        //   1) We’re toggling everything at once
        //   2) or we’re in an extreme state
        //   3) or the global slider is forcibly pinned at 0 or 1
        //   4) or the tilt bar is forcibly pinned at -1 or 1
        let skipGlobalShift = (
            userIsActuallyTogglingAll
            || chartExtremeBearish
            || chartExtremeBullish
            || factorIntensity == 0.0
            || factorIntensity == 1.0
            || tiltBarValue == -1.0
            || tiltBarValue == 1.0
        )
        
        // 4. Toggling OFF => subtract the tilt value
        if !enabled {
            print("[Debug] Toggling OFF \(factorName): subtracting \(toggleAmount)")
            
            // Skip if above condition says so
            if !skipGlobalShift {
                extendedGlobalValue -= toggleAmount
            }
            
            // Freeze or lock the factor
            factor.frozenValue = factor.currentValue
            factor.isEnabled   = false
            factor.isLocked    = true
            lockedFactors.insert(factorName)
        }
        // 5. Toggling ON => add the tilt value
        else {
            print("[Debug] Toggling ON \(factorName): adding \(toggleAmount)")
            
            // If it was frozen, restore that
            if let frozen = factor.frozenValue {
                factor.currentValue = frozen
                factor.frozenValue = nil
            }
            
            // Clear forced extremes if relevant
            if chartExtremeBearish && factor.currentValue > factor.minValue {
                chartExtremeBearish = false
            }
            if chartExtremeBullish && factor.currentValue < factor.maxValue {
                chartExtremeBullish = false
            }
            
            // Skip if above condition says so
            if !skipGlobalShift {
                extendedGlobalValue += toggleAmount
            }
            
            factor.isEnabled = true
            factor.isLocked  = false
            lockedFactors.remove(factorName)
        }
        
        // 6. Save updated factor state
        factors[factorName] = factor
        overrodeTiltManually = true
        
        // 7. If you're not toggling all at once, optionally sync factors
        if !userIsActuallyTogglingAll {
            ignoreSync = true
            // syncFactors() or syncFactorsToGlobalIntensity() if needed
            ignoreSync = false
        }
        
        // 8. Reapply if your code structure needs it
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
