//
//  MonthlySimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    
    // MARK: - Computed Global Slider (Monthly)
    var factorIntensityMonthly: Double {
        get {
            rawFactorIntensityMonthly
        }
        set {
            withAnimation(.easeInOut(duration: 0.4)) {
                rawFactorIntensityMonthly = newValue
            }
            syncFactorsToGlobalIntensityMonthly()
        }
    }

    // MARK: - Sync Factors (Monthly)
    func syncFactorsToGlobalIntensityMonthly() {
        for (name, var factor) in factorsMonthly where factor.isEnabled && !factor.isLocked {
            let baseline = globalBaselineMonthly(for: factor)
            let range    = factor.maxValue - factor.minValue
            let newValue = baseline + factor.internalOffset * range

            let clamped  = min(max(newValue, factor.minValue), factor.maxValue)
            if clamped != newValue {
                factor.internalOffset = (clamped - baseline) / range
            }
            factor.currentValue = clamped
            factorsMonthly[name] = factor
        }
    }
    
    // Utility to check if factor is Bearish (Monthly)
    private func isBearishFactorMonthly(_ factorName: String) -> Bool {
        let lower = factorName.lowercased()
        return Self.bearishTiltValuesMonthly[lower] != nil
    }

    // MARK: - Enable/Disable Individual Factor (Monthly)
    func setFactorEnabled(factorName: String, enabled: Bool) {
        print("[Debug] monthly setFactorEnabled for \(factorName), newValue: \(enabled)")
        
        // 1. Make sure this factor exists
        guard var factor = factorsMonthly[factorName] else {
            print("[Factor Debug] setFactorEnabledMonthly(\(factorName), \(enabled)): not found!")
            return
        }

        // 2. If there's no actual change, do nothing
        if factor.isEnabled == enabled {
            print("[Debug] Factor \(factorName) already enabled = \(enabled). Doing nothing.")
            return
        }

        // 3. Find the tilt amount
        let lowerName = factorName.lowercased()
        let baseAmount: Double = {
            if let val = Self.bullishTiltValuesMonthly[lowerName] {
                return val
            } else if let val = Self.bearishTiltValuesMonthly[lowerName] {
                return val
            } else {
                return 9.0 // fallback
            }
        }()
        let isBearish = isBearishFactorMonthly(factorName)

        // 4. Decide if we skip adjusting the global slider
        //    (Remove checks for factorIntensity extremes if you don’t want “locking”)
        let skipGlobalShift = (
            userIsActuallyTogglingAllMonthly
            || chartExtremeBearishMonthly
            || chartExtremeBullishMonthly
        )

        // 5. Toggling OFF => for Bearish, we ADD; for Bullish, we SUBTRACT
        if !enabled {
            print("[Debug] Toggling OFF \(factorName)")
            if !skipGlobalShift {
                withAnimation(.easeInOut(duration: 0.4)) {
                    extendedGlobalValueMonthly += (isBearish ? baseAmount : -baseAmount)
                }
            }
            
            factor.frozenValue = factor.currentValue
            factor.isEnabled   = false
            factor.isLocked    = true
            lockedFactorsMonthly.insert(factorName)
        }
        // 6. Toggling ON => for Bearish, we SUBTRACT; for Bullish, we ADD
        else {
            print("[Debug] Toggling ON \(factorName)")
            if let frozen = factor.frozenValue {
                factor.currentValue = frozen
                factor.frozenValue  = nil
            }
            
            // Clear forced extremes if relevant
            if chartExtremeBearishMonthly && factor.currentValue > factor.minValue {
                chartExtremeBearishMonthly = false
            }
            if chartExtremeBullishMonthly && factor.currentValue < factor.maxValue {
                chartExtremeBullishMonthly = false
            }
            
            if !skipGlobalShift {
                withAnimation(.easeInOut(duration: 0.4)) {
                    extendedGlobalValueMonthly += (isBearish ? -baseAmount : baseAmount)
                }
            }
            
            factor.isEnabled = true
            factor.isLocked  = false
            lockedFactorsMonthly.remove(factorName)
            
            // Recalc offset so factor stays at same numeric currentValue
            let base  = globalBaselineMonthly(for: factor)
            let range = factor.maxValue - factor.minValue
            factor.internalOffset = (factor.currentValue - base) / range
        }

        // 7. Save the updated factor
        factorsMonthly[factorName] = factor

        // 8. If not toggling all at once, optionally skip the sync
        if !userIsActuallyTogglingAllMonthly {
            ignoreSyncMonthly = true
            // e.g. syncFactorsToGlobalIntensityMonthly()
            ignoreSyncMonthly = false
        }

        // 9. Reapply if needed
        // applyDictionaryFactorsToSimMonthly()
        
        // 10. Indicate manual tilt override if you track that
        // overrodeTiltManuallyMonthly = true  // if you have such a property

        // 11. Recalc tilt bar
        recalcTiltBarValueMonthly(
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

    // MARK: - Toggle All Factors (Monthly)
    func toggleAllFactorsMonthly(on: Bool) {
        userIsActuallyTogglingAllMonthly = true

        // 1) Turn each factor on/off
        for (name, var factor) in factorsMonthly {
            if on {
                if let frozen = factor.frozenValue {
                    factor.currentValue = frozen
                    factor.frozenValue  = nil
                }
                factor.isEnabled = true
                factor.isLocked  = false
                factor.wasChartForced = false
                lockedFactorsMonthly.remove(name)
            } else {
                factor.frozenValue = factor.currentValue
                factor.isEnabled   = false
                factor.isLocked    = true
                lockedFactorsMonthly.insert(name)
            }
            factorsMonthly[name] = factor
        }

        userIsActuallyTogglingAllMonthly = false

        // 2) If turning everything ON, reset global slider to neutral
        if on {
            withAnimation(.easeInOut(duration: 0.4)) {
                extendedGlobalValueMonthly = 0.0
            }
            
            // Re‐baseline each factor
            for (fname, var factor) in factorsMonthly where factor.isEnabled {
                let base  = globalBaselineMonthly(for: factor)
                let range = factor.maxValue - factor.minValue
                factor.internalOffset = (factor.currentValue - base) / range
                factorsMonthly[fname] = factor
            }
        }

        // 3) Recalc tilt bar
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
        recalcTiltBarValueMonthly(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
        
        // 4) Reapply if you need
        // applyDictionaryFactorsToSimMonthly()
    }
}
