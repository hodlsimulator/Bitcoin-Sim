//
//  ApplyDictionaryFactorsToSim.swift
//  BTCMonteCarlo
//
//  Created by . . on 06/02/2025.
//

import SwiftUI

extension SimulationSettings {
    func applyDictionaryFactorsToSim() {
        for (factorName, factorState) in factors {
            let isEnabled = factorState.isEnabled
            let value = factorState.currentValue
            
            switch factorName {
                
            // =======================
            // MARK: - BULLISH FACTORS
            // =======================
                
            case "Halving":
                if periodUnit == .weeks {
                    useHalvingWeekly = isEnabled
                    halvingBumpWeekly = value
                } else {
                    useHalvingMonthly = isEnabled
                    halvingBumpMonthly = value
                }
                
            case "InstitutionalDemand":
                if periodUnit == .weeks {
                    useInstitutionalDemandWeekly = isEnabled
                    maxDemandBoostWeekly = value
                } else {
                    useInstitutionalDemandMonthly = isEnabled
                    maxDemandBoostMonthly = value
                }
                
            case "CountryAdoption":
                if periodUnit == .weeks {
                    useCountryAdoptionWeekly = isEnabled
                    maxCountryAdBoostWeekly = value
                } else {
                    useCountryAdoptionMonthly = isEnabled
                    maxCountryAdBoostMonthly = value
                }
                
            case "RegulatoryClarity":
                if periodUnit == .weeks {
                    useRegulatoryClarityWeekly = isEnabled
                    maxClarityBoostWeekly = value
                } else {
                    useRegulatoryClarityMonthly = isEnabled
                    maxClarityBoostMonthly = value
                }
                
            case "EtfApproval":
                if periodUnit == .weeks {
                    useEtfApprovalWeekly = isEnabled
                    maxEtfBoostWeekly = value
                } else {
                    useEtfApprovalMonthly = isEnabled
                    maxEtfBoostMonthly = value
                }
                
            case "TechBreakthrough":
                if periodUnit == .weeks {
                    useTechBreakthroughWeekly = isEnabled
                    maxTechBoostWeekly = value
                } else {
                    useTechBreakthroughMonthly = isEnabled
                    maxTechBoostMonthly = value
                }
                
            case "ScarcityEvents":
                if periodUnit == .weeks {
                    useScarcityEventsWeekly = isEnabled
                    maxScarcityBoostWeekly = value
                } else {
                    useScarcityEventsMonthly = isEnabled
                    maxScarcityBoostMonthly = value
                }
                
            case "GlobalMacroHedge":
                if periodUnit == .weeks {
                    useGlobalMacroHedgeWeekly = isEnabled
                    maxMacroBoostWeekly = value
                } else {
                    useGlobalMacroHedgeMonthly = isEnabled
                    maxMacroBoostMonthly = value
                }
                
            case "StablecoinShift":
                if periodUnit == .weeks {
                    useStablecoinShiftWeekly = isEnabled
                    maxStablecoinBoostWeekly = value
                } else {
                    useStablecoinShiftMonthly = isEnabled
                    maxStablecoinBoostMonthly = value
                }
                
            case "DemographicAdoption":
                if periodUnit == .weeks {
                    useDemographicAdoptionWeekly = isEnabled
                    maxDemoBoostWeekly = value
                } else {
                    useDemographicAdoptionMonthly = isEnabled
                    maxDemoBoostMonthly = value
                }
                
            case "AltcoinFlight":
                if periodUnit == .weeks {
                    useAltcoinFlightWeekly = isEnabled
                    maxAltcoinBoostWeekly = value
                } else {
                    useAltcoinFlightMonthly = isEnabled
                    maxAltcoinBoostMonthly = value
                }
                
            case "AdoptionFactor":
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
                
            case "RegClampdown":
                if periodUnit == .weeks {
                    useRegClampdownWeekly = isEnabled
                    maxClampDownWeekly = value
                } else {
                    useRegClampdownMonthly = isEnabled
                    maxClampDownMonthly = value
                }
                
            case "CompetitorCoin":
                if periodUnit == .weeks {
                    useCompetitorCoinWeekly = isEnabled
                    maxCompetitorBoostWeekly = value
                } else {
                    useCompetitorCoinMonthly = isEnabled
                    maxCompetitorBoostMonthly = value
                }
                
            case "SecurityBreach":
                if periodUnit == .weeks {
                    useSecurityBreachWeekly = isEnabled
                    breachImpactWeekly = value
                } else {
                    useSecurityBreachMonthly = isEnabled
                    breachImpactMonthly = value
                }
                
            case "BubblePop":
                if periodUnit == .weeks {
                    useBubblePopWeekly = isEnabled
                    maxPopDropWeekly = value
                } else {
                    useBubblePopMonthly = isEnabled
                    maxPopDropMonthly = value
                }
                
            case "StablecoinMeltdown":
                if periodUnit == .weeks {
                    useStablecoinMeltdownWeekly = isEnabled
                    maxMeltdownDropWeekly = value
                } else {
                    useStablecoinMeltdownMonthly = isEnabled
                    maxMeltdownDropMonthly = value
                }
                
            case "BlackSwan":
                if periodUnit == .weeks {
                    useBlackSwanWeekly = isEnabled
                    blackSwanDropWeekly = value
                } else {
                    useBlackSwanMonthly = isEnabled
                    blackSwanDropMonthly = value
                }
                
            case "BearMarket":
                if periodUnit == .weeks {
                    useBearMarketWeekly = isEnabled
                    bearWeeklyDriftWeekly = value
                } else {
                    useBearMarketMonthly = isEnabled
                    bearWeeklyDriftMonthly = value
                }
                
            case "MaturingMarket":
                if periodUnit == .weeks {
                    useMaturingMarketWeekly = isEnabled
                    maxMaturingDropWeekly = value
                } else {
                    useMaturingMarketMonthly = isEnabled
                    maxMaturingDropMonthly = value
                }
                
            case "Recession":
                if periodUnit == .weeks {
                    useRecessionWeekly = isEnabled
                    maxRecessionDropWeekly = value
                } else {
                    useRecessionMonthly = isEnabled
                    maxRecessionDropMonthly = value
                }
                
            default:
                // If a new factor is added but not yet handled, do nothing here.
                break
            }
        }
    }
}
