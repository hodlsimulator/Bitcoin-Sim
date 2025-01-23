//
//  LumpsumFactor.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation

/// Adjusts a lumpsum growth factor based on toggles and volatility.
func lumpsumAdjustFactor(
    settings: SimulationSettings,
    annualVolatility: Double
) -> Double {
    // We’ll add +1 to `toggles` for each "condition" we meet, then reduce factor by 0.02 each time
    var toggles = 0

    // If annualVol > 5.0 => add toggles
    if annualVolatility > 5.0 {
        toggles += Int((annualVolatility - 5.0) / 5.0) + 1
    }
    
    // If vol shocks are on
    if settings.useVolShocks {
        toggles += 1
    }
    
    // Count how many toggles are on for the *active* period (weekly or monthly)
    let isWeekly = (settings.periodUnit == .weeks)
    
    // BULLISH toggles count
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
    
    // BEARISH toggles count
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
    
    if (bullishCount + bearishCount) > 0 {
        toggles += 1
    }
    
    let maxCutPerToggle = 0.02
    let totalCut = Double(toggles) * maxCutPerToggle
    var factor = 1.0 - totalCut
    factor = max(factor, 0.80)
    return factor
}
