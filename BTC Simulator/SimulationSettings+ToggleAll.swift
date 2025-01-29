//
//  SimulationSettings+ToggleAll.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// A computed property to represent "toggle all factors on/off."
    /// When 'true':
    ///   - Set *all* factor booleans to on.
    ///   - Set each fraction to 0.5 (or your chosen midpoint).
    /// When 'false':
    ///   - Set *all* factor booleans to off.
    ///   - Optionally set each fraction to 0.0.
    var toggleAll: Bool {
        get {
            // Return true if *all* factor booleans are on
            // (instead of checking fraction==1.0).
            let allBullishOn = useHalvingWeekly
                && useInstitutionalDemandWeekly
                && useCountryAdoptionWeekly
                && useRegulatoryClarityWeekly
                && useEtfApprovalWeekly
                && useTechBreakthroughWeekly
                && useScarcityEventsWeekly
                && useGlobalMacroHedgeWeekly
                && useStablecoinShiftWeekly
                && useDemographicAdoptionWeekly
                && useAltcoinFlightWeekly
                && useAdoptionFactorWeekly
            
            let allBearishOn = useRegClampdownWeekly
                && useCompetitorCoinWeekly
                && useSecurityBreachWeekly
                && useBubblePopWeekly
                && useStablecoinMeltdownWeekly
                && useBlackSwanWeekly
                && useBearMarketWeekly
                && useMaturingMarketWeekly
                && useRecessionWeekly
            
            return (allBullishOn && allBearishOn)
        }
        set {
            if newValue {
                // Turn *all* factors on
                useHalvingWeekly = true
                useInstitutionalDemandWeekly = true
                useCountryAdoptionWeekly = true
                useRegulatoryClarityWeekly = true
                useEtfApprovalWeekly = true
                useTechBreakthroughWeekly = true
                useScarcityEventsWeekly = true
                useGlobalMacroHedgeWeekly = true
                useStablecoinShiftWeekly = true
                useDemographicAdoptionWeekly = true
                useAltcoinFlightWeekly = true
                useAdoptionFactorWeekly = true
                
                useRegClampdownWeekly = true
                useCompetitorCoinWeekly = true
                useSecurityBreachWeekly = true
                useBubblePopWeekly = true
                useStablecoinMeltdownWeekly = true
                useBlackSwanWeekly = true
                useBearMarketWeekly = true
                useMaturingMarketWeekly = true
                useRecessionWeekly = true
                
                // Set fraction of each factor to your "midpoint."
                // If you prefer a dictionary of midpoints or the actual min..max
                // from FactorRange, do that here. For simplicity, we use 0.5:
                for key in factorEnableFrac.keys {
                    factorEnableFrac[key] = 0.5
                }
                
            } else {
                // Turn *all* factors off
                useHalvingWeekly = false
                useInstitutionalDemandWeekly = false
                useCountryAdoptionWeekly = false
                useRegulatoryClarityWeekly = false
                useEtfApprovalWeekly = false
                useTechBreakthroughWeekly = false
                useScarcityEventsWeekly = false
                useGlobalMacroHedgeWeekly = false
                useStablecoinShiftWeekly = false
                useDemographicAdoptionWeekly = false
                useAltcoinFlightWeekly = false
                useAdoptionFactorWeekly = false
                
                useRegClampdownWeekly = false
                useCompetitorCoinWeekly = false
                useSecurityBreachWeekly = false
                useBubblePopWeekly = false
                useStablecoinMeltdownWeekly = false
                useBlackSwanWeekly = false
                useBearMarketWeekly = false
                useMaturingMarketWeekly = false
                useRecessionWeekly = false
                
                // Optionally set fraction to 0.0 so they
                // have no effect if turned off.
                for key in factorEnableFrac.keys {
                    factorEnableFrac[key] = 0.0
                }
            }
        }
    }
}
