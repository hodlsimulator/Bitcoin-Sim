//
//  AnnualStepAdjustFactor.swift
//  BTCMonteCarlo
//
//  Created by Conor on 23/01/2025.
//

import Foundation

/// Adjusts an annual step growth factor based on toggles and volatility.
func annualStepAdjustFactor(
    settings: SimulationSettings,
    annualVolatility: Double
) -> Double {
    var toggles = 0

    // Only if userVolShocks is TRUE do we factor in big volatility
    if settings.useVolShocks {
        if annualVolatility > 5.0 {
            let added = Int((annualVolatility - 5.0) / 5.0) + 1
            toggles += added
        }
    }
    
    // Count bullish toggles
    let isWeekly = (settings.periodUnit == .weeks)
    let bullishCount = isWeekly
        ? [
            settings.useHalvingWeekly,
            settings.useInstitutionalDemandWeekly,
            settings.useCountryAdoptionWeekly,
            settings.useRegulatoryClarityWeekly,
            settings.useEtfApprovalWeekly,
            settings.useTechBreakthroughWeekly,
            settings.useScarcityEventsWeekly,
            settings.useGlobalMacroHedgeWeekly,
            settings.useStablecoinShiftWeekly,
            settings.useDemographicAdoptionWeekly,
            settings.useAltcoinFlightWeekly,
            settings.useAdoptionFactorWeekly
          ].filter { $0 }.count
        : [
            settings.useHalvingMonthly,
            settings.useInstitutionalDemandMonthly,
            settings.useCountryAdoptionMonthly,
            settings.useRegulatoryClarityMonthly,
            settings.useEtfApprovalMonthly,
            settings.useTechBreakthroughMonthly,
            settings.useScarcityEventsMonthly,
            settings.useGlobalMacroHedgeMonthly,
            settings.useStablecoinShiftMonthly,
            settings.useDemographicAdoptionMonthly,
            settings.useAltcoinFlightMonthly,
            settings.useAdoptionFactorMonthly
          ].filter { $0 }.count
    
    // Count bearish toggles
    let bearishCount = isWeekly
        ? [
            settings.useRegClampdownWeekly,
            settings.useCompetitorCoinWeekly,
            settings.useSecurityBreachWeekly,
            settings.useBubblePopWeekly,
            settings.useStablecoinMeltdownWeekly,
            settings.useBlackSwanWeekly,
            settings.useBearMarketWeekly,
            settings.useMaturingMarketWeekly,
            settings.useRecessionWeekly
          ].filter { $0 }.count
        : [
            settings.useRegClampdownMonthly,
            settings.useCompetitorCoinMonthly,
            settings.useSecurityBreachMonthly,
            settings.useBubblePopMonthly,
            settings.useStablecoinMeltdownMonthly,
            settings.useBlackSwanMonthly,
            settings.useBearMarketMonthly,
            settings.useMaturingMarketMonthly,
            settings.useRecessionMonthly
          ].filter { $0 }.count
    
    // If the user has ANY toggles on, you could apply some penalty or logic here
    if (bullishCount + bearishCount) > 0 {
        // e.g., toggles += 1 or some other multiplier
    }

    // Each toggle => 2% cut, but never go below 80%
    let maxCutPerToggle = 0.02
    let totalCut = Double(toggles) * maxCutPerToggle
    var factor = 1.0 - totalCut
    factor = max(factor, 0.80)

    return factor
}
