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
            // Animate whenever the global slider is updated
            withAnimation(.easeInOut(duration: 0.4)) {
                rawFactorIntensity = newValue
            }
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
    
    // Utility to check if factor is Bearish
    private func isBearishFactor(_ factorName: String) -> Bool {
        let lower = factorName.lowercased()
        return Self.bearishTiltValuesWeekly[lower] != nil
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
        
        // 3. Find the tilt value
        let lowerName = factorName.lowercased()
        let baseAmount: Double = {
            if let val = Self.bullishTiltValuesWeekly[lowerName] {
                return val
            } else if let val = Self.bearishTiltValuesWeekly[lowerName] {
                return val
            } else {
                return 9.0 // fallback
            }
        }()
        
        // For Bearish factors, we invert the direction
        let isBearish = isBearishFactor(factorName)
        
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
        
        // 4. Toggling OFF => for Bearish, we ADD (removing negative tilt); for Bullish, we SUBTRACT
        if !enabled {
            print("[Debug] Toggling OFF \(factorName)")
            if !skipGlobalShift {
                withAnimation(.easeInOut(duration: 0.4)) {
                    extendedGlobalValue += (isBearish ? baseAmount : -baseAmount)
                }
            }
            
            factor.frozenValue = factor.currentValue
            factor.isEnabled   = false
            factor.isLocked    = true
            lockedFactors.insert(factorName)
        }
        // 5. Toggling ON => for Bearish, we SUBTRACT (adding negative tilt); for Bullish, we ADD
        else {
            print("[Debug] Toggling ON \(factorName)")
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
                withAnimation(.easeInOut(duration: 0.4)) {
                    extendedGlobalValue += (isBearish ? -baseAmount : baseAmount)
                }
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
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    factor.frozenValue  = nil
                }
                factor.isEnabled = true
                factor.isLocked  = false
                factor.wasChartForced = false
            } else {
                factor.frozenValue = factor.currentValue
                factor.isEnabled   = false
                factor.isLocked    = true
            }
            factors[name] = factor
        }
        
        // Done toggling
        userIsActuallyTogglingAll = false
        
        // 2) If everything is ON, force the global slider & tilt bar to neutral
        if on {
            withAnimation(.easeInOut(duration: 0.4)) {
                extendedGlobalValue = 0.0
            }
            
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
