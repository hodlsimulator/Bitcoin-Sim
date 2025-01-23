//
//  FactorToggles.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation
import GameplayKit

/// Applies weekly or monthly toggles to a base return.
func applyFactorToggles(
    baseReturn: Double,
    stepIndex: Int,
    settings: SimulationSettings,
    mempoolDataManager: MempoolDataManager,
    rng: GKRandomSource
) -> Double {
    var r = baseReturn
    let isWeekly = (settings.periodUnit == .weeks)
    
    // ─────────────────────────
    // BULLISH
    // ─────────────────────────
    
    // Halving => Probability example if user specifically wants it
    if isWeekly && settings.useHalvingWeekly {
        let stressLevel = mempoolDataManager.stressLevel(at: stepIndex)
        let baseProb = 0.02
        let dynamicProb = (stressLevel > 80.0) ? baseProb * 1.5 : baseProb
        let roll = Double(rng.nextUniform())
        if roll < dynamicProb {
            r += settings.halvingBumpWeekly
        }
    } else if !isWeekly && settings.useHalvingMonthly {
        let stressLevel = mempoolDataManager.stressLevel(at: stepIndex)
        let baseProb = 0.02
        let dynamicProb = (stressLevel > 80.0) ? baseProb * 1.5 : baseProb
        let roll = Double(rng.nextUniform())
        if roll < dynamicProb {
            r += settings.halvingBumpMonthly
        }
    }
    
    // Institutional Demand
    if isWeekly && settings.useInstitutionalDemandWeekly {
        r += settings.maxDemandBoostWeekly
    } else if !isWeekly && settings.useInstitutionalDemandMonthly {
        r += settings.maxDemandBoostMonthly
    }

    // Country Adoption
    if isWeekly && settings.useCountryAdoptionWeekly {
        r += settings.maxCountryAdBoostWeekly
    } else if !isWeekly && settings.useCountryAdoptionMonthly {
        r += settings.maxCountryAdBoostMonthly
    }

    // Regulatory Clarity
    if isWeekly && settings.useRegulatoryClarityWeekly {
        r += settings.maxClarityBoostWeekly
    } else if !isWeekly && settings.useRegulatoryClarityMonthly {
        r += settings.maxClarityBoostMonthly
    }

    // ETF Approval
    if isWeekly && settings.useEtfApprovalWeekly {
        r += settings.maxEtfBoostWeekly
    } else if !isWeekly && settings.useEtfApprovalMonthly {
        r += settings.maxEtfBoostMonthly
    }

    // Tech Breakthrough
    if isWeekly && settings.useTechBreakthroughWeekly {
        r += settings.maxTechBoostWeekly
    } else if !isWeekly && settings.useTechBreakthroughMonthly {
        r += settings.maxTechBoostMonthly
    }

    // Scarcity Events
    if isWeekly && settings.useScarcityEventsWeekly {
        r += settings.maxScarcityBoostWeekly
    } else if !isWeekly && settings.useScarcityEventsMonthly {
        r += settings.maxScarcityBoostMonthly
    }

    // Global Macro Hedge
    if isWeekly && settings.useGlobalMacroHedgeWeekly {
        r += settings.maxMacroBoostWeekly
    } else if !isWeekly && settings.useGlobalMacroHedgeMonthly {
        r += settings.maxMacroBoostMonthly
    }

    // Stablecoin Shift
    if isWeekly && settings.useStablecoinShiftWeekly {
        r += settings.maxStablecoinBoostWeekly
    } else if !isWeekly && settings.useStablecoinShiftMonthly {
        r += settings.maxStablecoinBoostMonthly
    }

    // Demographic Adoption
    if isWeekly && settings.useDemographicAdoptionWeekly {
        r += settings.maxDemoBoostWeekly
    } else if !isWeekly && settings.useDemographicAdoptionMonthly {
        r += settings.maxDemoBoostMonthly
    }

    // Altcoin Flight
    if isWeekly && settings.useAltcoinFlightWeekly {
        r += settings.maxAltcoinBoostWeekly
    } else if !isWeekly && settings.useAltcoinFlightMonthly {
        r += settings.maxAltcoinBoostMonthly
    }

    // Adoption Factor
    if isWeekly && settings.useAdoptionFactorWeekly {
        r += settings.adoptionBaseFactorWeekly
    } else if !isWeekly && settings.useAdoptionFactorMonthly {
        r += settings.adoptionBaseFactorMonthly
    }
    
    // ─────────────────────────
    // BEARISH
    // ─────────────────────────
    
    // Reg Clampdown
    if isWeekly && settings.useRegClampdownWeekly {
        r += settings.maxClampDownWeekly
    } else if !isWeekly && settings.useRegClampdownMonthly {
        r += settings.maxClampDownMonthly
    }

    // Competitor Coin
    if isWeekly && settings.useCompetitorCoinWeekly {
        r += settings.maxCompetitorBoostWeekly
    } else if !isWeekly && settings.useCompetitorCoinMonthly {
        r += settings.maxCompetitorBoostMonthly
    }

    // Security Breach
    if isWeekly && settings.useSecurityBreachWeekly {
        r += settings.breachImpactWeekly
    } else if !isWeekly && settings.useSecurityBreachMonthly {
        r += settings.breachImpactMonthly
    }

    // Bubble Pop
    if isWeekly && settings.useBubblePopWeekly {
        r += settings.maxPopDropWeekly
    } else if !isWeekly && settings.useBubblePopMonthly {
        r += settings.maxPopDropMonthly
    }

    // Stablecoin Meltdown
    if isWeekly && settings.useStablecoinMeltdownWeekly {
        r += settings.maxMeltdownDropWeekly
    } else if !isWeekly && settings.useStablecoinMeltdownMonthly {
        r += settings.maxMeltdownDropMonthly
    }

    // Black Swan => Probability-based approach
    if isWeekly && settings.useBlackSwanWeekly {
        let stressLevel = mempoolDataManager.stressLevel(at: stepIndex)
        let baseProb = 0.028
        let dynamicProb = (stressLevel > 80.0) ? baseProb * 2.0 : baseProb
        let roll = Double(rng.nextUniform())
        if roll < dynamicProb {
            r += settings.blackSwanDropWeekly
        }
    } else if !isWeekly && settings.useBlackSwanMonthly {
        let stressLevel = mempoolDataManager.stressLevel(at: stepIndex)
        let baseProb = 0.028
        let dynamicProb = (stressLevel > 80.0) ? baseProb * 2.0 : baseProb
        let roll = Double(rng.nextUniform())
        if roll < dynamicProb {
            r += settings.blackSwanDropMonthly
        }
    }

    // Bear Market
    if isWeekly && settings.useBearMarketWeekly {
        r += settings.bearWeeklyDriftWeekly
    } else if !isWeekly && settings.useBearMarketMonthly {
        r += settings.bearWeeklyDriftMonthly
    }

    // Maturing Market
    if isWeekly && settings.useMaturingMarketWeekly {
        r += settings.maxMaturingDropWeekly
    } else if !isWeekly && settings.useMaturingMarketMonthly {
        r += settings.maxMaturingDropMonthly
    }

    // Recession
    if isWeekly && settings.useRecessionWeekly {
        r += settings.maxRecessionDropWeekly
    } else if !isWeekly && settings.useRecessionMonthly {
        r += settings.maxRecessionDropMonthly
    }
    
    return r
}
