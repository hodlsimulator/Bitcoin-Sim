//
//  SimulationSettings+ToggleAll.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    /// Previously checked parent toggles.
    /// Now we rewrite areAllFactorsEnabled to reference only weekly or monthly toggles,
    /// based on the current periodUnit.
    var areAllFactorsEnabled: Bool {
        if periodUnit == .weeks {
            return useHalvingWeekly
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
                && useRegClampdownWeekly
                && useCompetitorCoinWeekly
                && useSecurityBreachWeekly
                && useBubblePopWeekly
                && useStablecoinMeltdownWeekly
                && useBlackSwanWeekly
                && useBearMarketWeekly
                && useMaturingMarketWeekly
                && useRecessionWeekly
        } else {
            return useHalvingMonthly
                && useInstitutionalDemandMonthly
                && useCountryAdoptionMonthly
                && useRegulatoryClarityMonthly
                && useEtfApprovalMonthly
                && useTechBreakthroughMonthly
                && useScarcityEventsMonthly
                && useGlobalMacroHedgeMonthly
                && useStablecoinShiftMonthly
                && useDemographicAdoptionMonthly
                && useAltcoinFlightMonthly
                && useAdoptionFactorMonthly
                && useRegClampdownMonthly
                && useCompetitorCoinMonthly
                && useSecurityBreachMonthly
                && useBubblePopMonthly
                && useStablecoinMeltdownMonthly
                && useBlackSwanMonthly
                && useBearMarketMonthly
                && useMaturingMarketMonthly
                && useRecessionMonthly
        }
    }
}
