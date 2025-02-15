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
            if let val = Self.bullishTiltValuesWeekly[lowerName] {
                return val
            } else if let val = Self.bearishTiltValuesWeekly[lowerName] {
                return val
            } else {
                return 9.0 // fallback if not found
            }
        }()
        
        // Decide if we skip adjusting global tilt
        let skipGlobalShift = (
            userIsActuallyTogglingAll
            || chartExtremeBearish
            || chartExtremeBullish
            || factorIntensity <= 0.0
            || factorIntensity >= 1.0
            || tiltBarValue == -1.0
            || tiltBarValue == 1.0
        )
        
        // 4. Toggling OFF => subtract the tilt value
        if !enabled {
            print("[Debug] Toggling OFF \(factorName): subtracting \(toggleAmount)")
            
            if !skipGlobalShift {
                extendedGlobalValue -= toggleAmount
            }
            
            factor.frozenValue = factor.currentValue
            factor.isEnabled   = false
            factor.isLocked    = true
            lockedFactors.insert(factorName)
        }
        // 5. Toggling ON => add the tilt value
        else {
            print("[Debug] Toggling ON \(factorName): adding \(toggleAmount)")
            
            if let frozen = factor.frozenValue {
                factor.currentValue = frozen
                factor.frozenValue  = nil
            }
            
            // Clear forced extremes if relevant
            if chartExtremeBearish && factor.currentValue > factor.minValue {
                chartExtremeBearish = false
            }
            if chartExtremeBullish && factor.currentValue < factor.maxValue {
                chartExtremeBullish = false
            }
            
            if !skipGlobalShift {
                extendedGlobalValue += toggleAmount
            }
            
            factor.isEnabled = true
            factor.isLocked  = false
            lockedFactors.remove(factorName)
            
            // Recalc offset so factor stays at the same numeric currentValue
            let base  = globalBaseline(for: factor)
            let range = factor.maxValue - factor.minValue
            factor.internalOffset = (factor.currentValue - base) / range
        }
        
        // 6. Save updated factor state
        factors[factorName] = factor
        overrodeTiltManually = true
        
        // 7. If you're not toggling all at once, optionally sync factors
        if !userIsActuallyTogglingAll {
            ignoreSync = true
            // e.g. syncFactorsToGlobalIntensity()
            ignoreSync = false
        }
        
        // 8. Reapply if your code structure needs it
        applyDictionaryFactorsToSim()
    }
    
    // MARK: - Toggle All Factors
    func toggleAllFactors(on: Bool) {
        userIsActuallyTogglingAll = true
        
        // 1) Turn each factor on/off in place
        for (name, var factor) in factors {
            if on {
                // Restore frozen
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    factor.frozenValue  = nil
                }
                factor.isEnabled = true
                factor.isLocked  = false
                factor.wasChartForced = false
            } else {
                // Freeze
                factor.frozenValue = factor.currentValue
                factor.isEnabled   = false
                factor.isLocked    = true
            }
            factors[name] = factor
        }
        
        // Done toggling
        userIsActuallyTogglingAll = false
        
        // 2) If everything is ON, force the global slider & tilt bar to neutral
        //    but *don't* recalc each factor's currentValue => no jump
        if on {
            // a) Manually centre the global slider at 0 => rawFactorIntensity = 0.5
            extendedGlobalValue = 0.0
            
            // b) Re‐baseline each *enabled* factor so currentValue = baseline + offset*range
            //    This ensures the factor doesn't shift from where it already is numerically.
            for (fname, var factor) in factors where factor.isEnabled {
                let base  = globalBaseline(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.internalOffset = (factor.currentValue - base) / range
                factors[fname] = factor
            }
        }
        
        // 3) Recalc tilt bar & reapply
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
