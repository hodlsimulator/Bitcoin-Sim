//
//  MonthlySimulationSettings+FactorSync.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

extension MonthlySimulationSettings {
    
    // You can store these as @Published in your MonthlySimulationSettings class,
    // or leave them here as static if that suits your architecture. Just be consistent.
    
    // Stored properties that back the vars above (if your class doesn't already have them)
    private static var _userIsActuallyTogglingAllMonthlyKey: UInt8 = 0
    private var _userIsActuallyTogglingAllMonthly: Bool? {
        get { objc_getAssociatedObject(self, &Self._userIsActuallyTogglingAllMonthlyKey) as? Bool }
        set { objc_setAssociatedObject(self, &Self._userIsActuallyTogglingAllMonthlyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private static var _ignoreSyncMonthlyKey: UInt8 = 0
    private var _ignoreSyncMonthly: Bool? {
        get { objc_getAssociatedObject(self, &Self._ignoreSyncMonthlyKey) as? Bool }
        set { objc_setAssociatedObject(self, &Self._ignoreSyncMonthlyKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - A computed property analogous to factorIntensity for weekly
    var factorIntensityMonthlyComputed: Double {
        get {
            rawFactorIntensityMonthly
        }
        set {
            // Let’s skip the normal sync if ignoreSyncMonthly == true
            rawFactorIntensityMonthly = newValue
            if !ignoreSyncMonthly {
                syncFactorsToGlobalIntensityMonthly(for: newValue)
            }
        }
    }

    // MARK: - setFactorEnabledMonthly (Mirroring the weekly approach)
    func setFactorEnabledMonthly(factorName: String, enabled: Bool) {
        // Capture the currently-active monthly factors
        let oldActive = factorsMonthly.values.filter { $0.isEnabled && !$0.isLocked }
        
        guard var factor = factorsMonthly[factorName] else {
            print("[setFactorEnabledMonthly] Factor \(factorName) not found!")
            return
        }
        
        // Toggle the factor on/off
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
            // Disable
            factor.frozenValue = factor.currentValue
            factor.isEnabled   = false
            factor.isLocked    = true
            lockedFactorsMonthly.insert(factorName)
        }
        
        // Store back
        factorsMonthly[factorName] = factor
        
        // Shift the global slider similarly to how dragging the factor to/from zero would do
        if !userIsActuallyTogglingAllMonthly {
            ignoreSyncMonthly = true
            
            if enabled {
                // Factor was off -> on
                let newActiveCount = oldActive.count + 1
                if newActiveCount > 0 {
                    let shift = factor.internalOffset / Double(newActiveCount)
                    rawFactorIntensityMonthly = min(max(rawFactorIntensityMonthly + shift, 0.0), 1.0)
                }
            } else {
                // Factor was on -> off
                let oldActiveCount = oldActive.count
                if oldActiveCount > 0 {
                    let shift = factor.internalOffset / Double(oldActiveCount)
                    rawFactorIntensityMonthly = min(max(rawFactorIntensityMonthly - shift, 0.0), 1.0)
                }
            }
            
            ignoreSyncMonthly = false
            // Re-sync to clamp any factors, etc.
            syncFactorsToGlobalIntensityMonthly(for: rawFactorIntensityMonthly)
        }
        
        // Finally, recalc the tilt bar.
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
        
        // If you need to apply them to the simulation, do that here
        // applyDictionaryFactorsToSimMonthly()
    }
    
    // MARK: - toggleAllFactorsMonthly (Mirroring the weekly approach)
    func toggleAllFactorsMonthly(on: Bool) {
        // Indicate that we are toggling all so setFactorEnabledMonthly() can skip
        userIsActuallyTogglingAllMonthly = true
        
        // Turn everything on/off
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
        
        // Done toggling all
        userIsActuallyTogglingAllMonthly = false
        
        // Optionally re‐sync everything
        syncFactorsToGlobalIntensityMonthly(for: rawFactorIntensityMonthly)
        
        // And recalc tilt bar so it returns to neutral if everything is enabled
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
}
