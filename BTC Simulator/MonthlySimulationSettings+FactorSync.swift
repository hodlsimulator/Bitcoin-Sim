//
//  MonthlySimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    
    /// A computed property analogous to `factorIntensity` for weekly
    var factorIntensityMonthlyComputed: Double {
        get {
            rawFactorIntensityMonthly
        }
        set {
            rawFactorIntensityMonthly = newValue
            syncFactorsToGlobalIntensityMonthly(for: newValue)
        }
    }

    /// The monthly version of setFactorEnabled()
    func setFactorEnabledMonthly(factorName: String, enabled: Bool) {
        guard var factor = factorsMonthly[factorName] else {
            print("[setFactorEnabledMonthly] Factor \(factorName) not found!")
            return
        }
        
        if enabled {
            // Re-enable
            if let frozen = factor.frozenValue {
                factor.currentValue = frozen
                let base = globalBaselineMonthly(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.internalOffset = (frozen - base) / range
                factor.frozenValue = nil
                factor.wasChartForced = false
            }
            factor.isEnabled = true
            factor.isLocked  = false
            lockedFactorsMonthly.remove(factorName)
        } else {
            factor.frozenValue = factor.currentValue
            factor.isEnabled   = false
            factor.isLocked    = true
            lockedFactorsMonthly.insert(factorName)
        }
        
        factorsMonthly[factorName] = factor
        // Possibly recalc tilt:
        recalcTiltBarValueMonthly(
            bullishKeys: [
                "Halving","InstitutionalDemand","CountryAdoption","RegulatoryClarity",
                "EtfApproval","TechBreakthrough","ScarcityEvents","GlobalMacroHedge",
                "StablecoinShift","DemographicAdoption","AltcoinFlight","AdoptionFactor"
            ],
            bearishKeys: [
                "RegClampdown","CompetitorCoin","SecurityBreach","BubblePop",
                "StablecoinMeltdown","BlackSwan","BearMarket","MaturingMarket",
                "Recession"
            ]
        )
        // applyDictionaryFactorsToSimMonthly()
    }
    
    /// The monthly version of toggleAllFactors(on:)
    func toggleAllFactorsMonthly(on: Bool) {
        for (name, var factor) in factorsMonthly {
            if on {
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    let base = globalBaselineMonthly(for: factor)
                    let range = factor.maxValue - factor.minValue
                    factor.internalOffset = (frozen - base) / range
                    factor.frozenValue = nil
                    factor.wasChartForced = false
                }
                factor.isEnabled = true
                factor.isLocked  = false
                lockedFactorsMonthly.remove(name)
            } else {
                factor.frozenValue = factor.currentValue
                factor.isEnabled = false
                factor.isLocked  = true
                lockedFactorsMonthly.insert(name)
            }
            factorsMonthly[name] = factor
        }
        // If you want to re‐sync or recalc tilt, do so here
        // recalcTiltBarValueMonthly(...)
        // applyDictionaryFactorsToSimMonthly()
    }
}
