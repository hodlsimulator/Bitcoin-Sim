//
//  ApplyDictionaryFactorsToSim.swift
//  BTCMonteCarlo
//
//  Created by . . on 06/02/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// Updates the simulation’s working properties for a given factor based on its stored state.
    /// This helper centralizes the switch‑logic for updating each factor.
    private func updateSimulationSetting(for factorName: String, with factorState: FactorState) {
        let isEnabled = factorState.isEnabled
        let value = factorState.currentValue
        
        switch factorName.lowercased() {
            
        // =======================
        // MARK: - BULLISH FACTORS
        // =======================
            
        case "halving":
            if periodUnit == .weeks {
                useHalvingWeekly = isEnabled
                halvingBumpWeekly = value
            } else {
                useHalvingMonthly = isEnabled
                halvingBumpMonthly = value
            }
            
        case "institutionaldemand":
            if periodUnit == .weeks {
                useInstitutionalDemandWeekly = isEnabled
                maxDemandBoostWeekly = value
            } else {
                useInstitutionalDemandMonthly = isEnabled
                maxDemandBoostMonthly = value
            }
            
        case "countryadoption":
            if periodUnit == .weeks {
                useCountryAdoptionWeekly = isEnabled
                maxCountryAdBoostWeekly = value
            } else {
                useCountryAdoptionMonthly = isEnabled
                maxCountryAdBoostMonthly = value
            }
            
        case "regulatoryclarity":
            if periodUnit == .weeks {
                useRegulatoryClarityWeekly = isEnabled
                maxClarityBoostWeekly = value
            } else {
                useRegulatoryClarityMonthly = isEnabled
                maxClarityBoostMonthly = value
            }
            
        case "etfapproval":
            if periodUnit == .weeks {
                useEtfApprovalWeekly = isEnabled
                maxEtfBoostWeekly = value
            } else {
                useEtfApprovalMonthly = isEnabled
                maxEtfBoostMonthly = value
            }
            
        case "techbreakthrough":
            if periodUnit == .weeks {
                useTechBreakthroughWeekly = isEnabled
                maxTechBoostWeekly = value
            } else {
                useTechBreakthroughMonthly = isEnabled
                maxTechBoostMonthly = value
            }
            
        case "scarcityevents":
            if periodUnit == .weeks {
                useScarcityEventsWeekly = isEnabled
                maxScarcityBoostWeekly = value
            } else {
                useScarcityEventsMonthly = isEnabled
                maxScarcityBoostMonthly = value
            }
            
        case "globalmacrohedge":
            if periodUnit == .weeks {
                useGlobalMacroHedgeWeekly = isEnabled
                maxMacroBoostWeekly = value
            } else {
                useGlobalMacroHedgeMonthly = isEnabled
                maxMacroBoostMonthly = value
            }
            
        case "stablecoinshift":
            if periodUnit == .weeks {
                useStablecoinShiftWeekly = isEnabled
                maxStablecoinBoostWeekly = value
            } else {
                useStablecoinShiftMonthly = isEnabled
                maxStablecoinBoostMonthly = value
            }
            
        case "demographicadoption":
            if periodUnit == .weeks {
                useDemographicAdoptionWeekly = isEnabled
                maxDemoBoostWeekly = value
            } else {
                useDemographicAdoptionMonthly = isEnabled
                maxDemoBoostMonthly = value
            }
            
        case "altcoinflight":
            if periodUnit == .weeks {
                useAltcoinFlightWeekly = isEnabled
                maxAltcoinBoostWeekly = value
            } else {
                useAltcoinFlightMonthly = isEnabled
                maxAltcoinBoostMonthly = value
            }
            
        case "adoptionfactor":
            if periodUnit == .weeks {
                useAdoptionFactorWeekly = isEnabled
                adoptionBaseFactorWeekly = value
            } else {
                useAdoptionFactorMonthly = isEnabled
                adoptionBaseFactorMonthly = value
            }
            
        // =======================
        // MARK: - BEARISH FACTORS
        // =======================
            
        case "regclampdown":
            if periodUnit == .weeks {
                useRegClampdownWeekly = isEnabled
                maxClampDownWeekly = value
            } else {
                useRegClampdownMonthly = isEnabled
                maxClampDownMonthly = value
            }
            
        case "competitorcoin":
            if periodUnit == .weeks {
                useCompetitorCoinWeekly = isEnabled
                maxCompetitorBoostWeekly = value
            } else {
                useCompetitorCoinMonthly = isEnabled
                maxCompetitorBoostMonthly = value
            }
            
        case "securitybreach":
            if periodUnit == .weeks {
                useSecurityBreachWeekly = isEnabled
                breachImpactWeekly = value
            } else {
                useSecurityBreachMonthly = isEnabled
                breachImpactMonthly = value
            }
            
        case "bubblepop":
            if periodUnit == .weeks {
                useBubblePopWeekly = isEnabled
                maxPopDropWeekly = value
            } else {
                useBubblePopMonthly = isEnabled
                maxPopDropMonthly = value
            }
            
        case "stablecoinmeltdown":
            if periodUnit == .weeks {
                useStablecoinMeltdownWeekly = isEnabled
                maxMeltdownDropWeekly = value
            } else {
                useStablecoinMeltdownMonthly = isEnabled
                maxMeltdownDropMonthly = value
            }
            
        case "blackswan":
            if periodUnit == .weeks {
                useBlackSwanWeekly = isEnabled
                blackSwanDropWeekly = value
            } else {
                useBlackSwanMonthly = isEnabled
                blackSwanDropMonthly = value
            }
            
        case "bearmarket":
            if periodUnit == .weeks {
                useBearMarketWeekly = isEnabled
                bearWeeklyDriftWeekly = value
            } else {
                useBearMarketMonthly = isEnabled
                bearWeeklyDriftMonthly = value
            }
            
        case "maturingmarket":
            if periodUnit == .weeks {
                useMaturingMarketWeekly = isEnabled
                maxMaturingDropWeekly = value
            } else {
                useMaturingMarketMonthly = isEnabled
                maxMaturingDropMonthly = value
            }
            
        case "recession":
            if periodUnit == .weeks {
                useRecessionWeekly = isEnabled
                maxRecessionDropWeekly = value
            } else {
                useRecessionMonthly = isEnabled
                maxRecessionDropMonthly = value
            }
            
        default:
            // If a new factor is added but not yet handled, do nothing.
            break
        }
    }
    
    /// Updates simulation settings for all factors in the dictionary.
    func applyDictionaryFactorsToSim() {
        for (factorName, factorState) in factors {
            updateSimulationSetting(for: factorName, with: factorState)
        }
    }
    
    /// Updates simulation settings for a single factor identified by `factorName`.
    func applyDictionaryFactorFor(_ factorName: String) {
        if let factorState = factors[factorName] {
            updateSimulationSetting(for: factorName, with: factorState)
        }
    }
}
