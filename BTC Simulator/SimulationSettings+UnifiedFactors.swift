//
//  SimulationSettings+UnifiedFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    // MARK: - Halving
    var useHalvingUnified: Bool {
        get { periodUnit == .weeks ? useHalvingWeekly : useHalvingMonthly }
        set {
            if periodUnit == .weeks {
                useHalvingWeekly = newValue
            } else {
                useHalvingMonthly = newValue
            }
        }   
    }
    var halvingBumpUnified: Double {
        get { periodUnit == .weeks ? halvingBumpWeekly : halvingBumpMonthly }
        set {
            if periodUnit == .weeks {
                halvingBumpWeekly = newValue
            } else {
                halvingBumpMonthly = newValue
            }
        }
    }
    
    // MARK: - Institutional Demand
    var useInstitutionalDemandUnified: Bool {
        get { periodUnit == .weeks ? useInstitutionalDemandWeekly : useInstitutionalDemandMonthly }
        set {
            if periodUnit == .weeks {
                useInstitutionalDemandWeekly = newValue
            } else {
                useInstitutionalDemandMonthly = newValue
            }
        }
    }
    var maxDemandBoostUnified: Double {
        get { periodUnit == .weeks ? maxDemandBoostWeekly : maxDemandBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxDemandBoostWeekly = newValue
            } else {
                maxDemandBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Country Adoption
    var useCountryAdoptionUnified: Bool {
        get { periodUnit == .weeks ? useCountryAdoptionWeekly : useCountryAdoptionMonthly }
        set {
            if periodUnit == .weeks {
                useCountryAdoptionWeekly = newValue
            } else {
                useCountryAdoptionMonthly = newValue
            }
        }
    }
    var maxCountryAdBoostUnified: Double {
        get { periodUnit == .weeks ? maxCountryAdBoostWeekly : maxCountryAdBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxCountryAdBoostWeekly = newValue
            } else {
                maxCountryAdBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Regulatory Clarity
    var useRegulatoryClarityUnified: Bool {
        get { periodUnit == .weeks ? useRegulatoryClarityWeekly : useRegulatoryClarityMonthly }
        set {
            if periodUnit == .weeks {
                useRegulatoryClarityWeekly = newValue
            } else {
                useRegulatoryClarityMonthly = newValue
            }
        }
    }
    var maxClarityBoostUnified: Double {
        get { periodUnit == .weeks ? maxClarityBoostWeekly : maxClarityBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxClarityBoostWeekly = newValue
            } else {
                maxClarityBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - ETF Approval
    var useEtfApprovalUnified: Bool {
        get { periodUnit == .weeks ? useEtfApprovalWeekly : useEtfApprovalMonthly }
        set {
            if periodUnit == .weeks {
                useEtfApprovalWeekly = newValue
            } else {
                useEtfApprovalMonthly = newValue
            }
        }
    }
    var maxEtfBoostUnified: Double {
        get { periodUnit == .weeks ? maxEtfBoostWeekly : maxEtfBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxEtfBoostWeekly = newValue
            } else {
                maxEtfBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Tech Breakthrough
    var useTechBreakthroughUnified: Bool {
        get { periodUnit == .weeks ? useTechBreakthroughWeekly : useTechBreakthroughMonthly }
        set {
            if periodUnit == .weeks {
                useTechBreakthroughWeekly = newValue
            } else {
                useTechBreakthroughMonthly = newValue
            }
        }
    }
    var maxTechBoostUnified: Double {
        get { periodUnit == .weeks ? maxTechBoostWeekly : maxTechBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxTechBoostWeekly = newValue
            } else {
                maxTechBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Scarcity Events
    var useScarcityEventsUnified: Bool {
        get { periodUnit == .weeks ? useScarcityEventsWeekly : useScarcityEventsMonthly }
        set {
            if periodUnit == .weeks {
                useScarcityEventsWeekly = newValue
            } else {
                useScarcityEventsMonthly = newValue
            }
        }
    }
    var maxScarcityBoostUnified: Double {
        get { periodUnit == .weeks ? maxScarcityBoostWeekly : maxScarcityBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxScarcityBoostWeekly = newValue
            } else {
                maxScarcityBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Global Macro Hedge
    var useGlobalMacroHedgeUnified: Bool {
        get { periodUnit == .weeks ? useGlobalMacroHedgeWeekly : useGlobalMacroHedgeMonthly }
        set {
            if periodUnit == .weeks {
                useGlobalMacroHedgeWeekly = newValue
            } else {
                useGlobalMacroHedgeMonthly = newValue
            }
        }
    }
    var maxMacroBoostUnified: Double {
        get { periodUnit == .weeks ? maxMacroBoostWeekly : maxMacroBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxMacroBoostWeekly = newValue
            } else {
                maxMacroBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Stablecoin Shift
    var useStablecoinShiftUnified: Bool {
        get { periodUnit == .weeks ? useStablecoinShiftWeekly : useStablecoinShiftMonthly }
        set {
            if periodUnit == .weeks {
                useStablecoinShiftWeekly = newValue
            } else {
                useStablecoinShiftMonthly = newValue
            }
        }
    }
    var maxStablecoinBoostUnified: Double {
        get { periodUnit == .weeks ? maxStablecoinBoostWeekly : maxStablecoinBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxStablecoinBoostWeekly = newValue
            } else {
                maxStablecoinBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Demographic Adoption
    var useDemographicAdoptionUnified: Bool {
        get { periodUnit == .weeks ? useDemographicAdoptionWeekly : useDemographicAdoptionMonthly }
        set {
            if periodUnit == .weeks {
                useDemographicAdoptionWeekly = newValue
            } else {
                useDemographicAdoptionMonthly = newValue
            }
        }
    }
    var maxDemoBoostUnified: Double {
        get { periodUnit == .weeks ? maxDemoBoostWeekly : maxDemoBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxDemoBoostWeekly = newValue
            } else {
                maxDemoBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Altcoin Flight
    var useAltcoinFlightUnified: Bool {
        get { periodUnit == .weeks ? useAltcoinFlightWeekly : useAltcoinFlightMonthly }
        set {
            if periodUnit == .weeks {
                useAltcoinFlightWeekly = newValue
            } else {
                useAltcoinFlightMonthly = newValue
            }
        }
    }
    var maxAltcoinBoostUnified: Double {
        get { periodUnit == .weeks ? maxAltcoinBoostWeekly : maxAltcoinBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxAltcoinBoostWeekly = newValue
            } else {
                maxAltcoinBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Adoption Factor
    var useAdoptionFactorUnified: Bool {
        get { periodUnit == .weeks ? useAdoptionFactorWeekly : useAdoptionFactorMonthly }
        set {
            if periodUnit == .weeks {
                useAdoptionFactorWeekly = newValue
            } else {
                useAdoptionFactorMonthly = newValue
            }
        }
    }
    var adoptionBaseFactorUnified: Double {
        get { periodUnit == .weeks ? adoptionBaseFactorWeekly : adoptionBaseFactorMonthly }
        set {
            if periodUnit == .weeks {
                adoptionBaseFactorWeekly = newValue
            } else {
                adoptionBaseFactorMonthly = newValue
            }
        }
    }
    
    // MARK: - Regulatory Clampdown
    var useRegClampdownUnified: Bool {
        get { periodUnit == .weeks ? useRegClampdownWeekly : useRegClampdownMonthly }
        set {
            if periodUnit == .weeks {
                useRegClampdownWeekly = newValue
            } else {
                useRegClampdownMonthly = newValue
            }
        }
    }
    var maxClampDownUnified: Double {
        get { periodUnit == .weeks ? maxClampDownWeekly : maxClampDownMonthly }
        set {
            if periodUnit == .weeks {
                maxClampDownWeekly = newValue
            } else {
                maxClampDownMonthly = newValue
            }
        }
    }
    
    // MARK: - Competitor Coin
    var useCompetitorCoinUnified: Bool {
        get { periodUnit == .weeks ? useCompetitorCoinWeekly : useCompetitorCoinMonthly }
        set {
            if periodUnit == .weeks {
                useCompetitorCoinWeekly = newValue
            } else {
                useCompetitorCoinMonthly = newValue
            }
        }
    }
    var maxCompetitorBoostUnified: Double {
        get { periodUnit == .weeks ? maxCompetitorBoostWeekly : maxCompetitorBoostMonthly }
        set {
            if periodUnit == .weeks {
                maxCompetitorBoostWeekly = newValue
            } else {
                maxCompetitorBoostMonthly = newValue
            }
        }
    }
    
    // MARK: - Security Breach
    var useSecurityBreachUnified: Bool {
        get { periodUnit == .weeks ? useSecurityBreachWeekly : useSecurityBreachMonthly }
        set {
            if periodUnit == .weeks {
                useSecurityBreachWeekly = newValue
            } else {
                useSecurityBreachMonthly = newValue
            }
        }
    }
    var breachImpactUnified: Double {
        get { periodUnit == .weeks ? breachImpactWeekly : breachImpactMonthly }
        set {
            if periodUnit == .weeks {
                breachImpactWeekly = newValue
            } else {
                breachImpactMonthly = newValue
            }
        }
    }
    
    // MARK: - Bubble Pop
    var useBubblePopUnified: Bool {
        get { periodUnit == .weeks ? useBubblePopWeekly : useBubblePopMonthly }
        set {
            if periodUnit == .weeks {
                useBubblePopWeekly = newValue
            } else {
                useBubblePopMonthly = newValue
            }
        }
    }
    var maxPopDropUnified: Double {
        get { periodUnit == .weeks ? maxPopDropWeekly : maxPopDropMonthly }
        set {
            if periodUnit == .weeks {
                maxPopDropWeekly = newValue
            } else {
                maxPopDropMonthly = newValue
            }
        }
    }
    
    // MARK: - Stablecoin Meltdown
    var useStablecoinMeltdownUnified: Bool {
        get { periodUnit == .weeks ? useStablecoinMeltdownWeekly : useStablecoinMeltdownMonthly }
        set {
            if periodUnit == .weeks {
                useStablecoinMeltdownWeekly = newValue
            } else {
                useStablecoinMeltdownMonthly = newValue
            }
        }
    }
    var maxMeltdownDropUnified: Double {
        get { periodUnit == .weeks ? maxMeltdownDropWeekly : maxMeltdownDropMonthly }
        set {
            if periodUnit == .weeks {
                maxMeltdownDropWeekly = newValue
            } else {
                maxMeltdownDropMonthly = newValue
            }
        }
    }
    
    // MARK: - Black Swan
    var useBlackSwanUnified: Bool {
        get { periodUnit == .weeks ? useBlackSwanWeekly : useBlackSwanMonthly }
        set {
            if periodUnit == .weeks {
                useBlackSwanWeekly = newValue
            } else {
                useBlackSwanMonthly = newValue
            }
        }
    }
    var blackSwanDropUnified: Double {
        get { periodUnit == .weeks ? blackSwanDropWeekly : blackSwanDropMonthly }
        set {
            if periodUnit == .weeks {
                blackSwanDropWeekly = newValue
            } else {
                blackSwanDropMonthly = newValue
            }
        }
    }
    
    // MARK: - Bear Market
    var useBearMarketUnified: Bool {
        get { periodUnit == .weeks ? useBearMarketWeekly : useBearMarketMonthly }
        set {
            if periodUnit == .weeks {
                useBearMarketWeekly = newValue
            } else {
                useBearMarketMonthly = newValue
            }
        }
    }
    var bearWeeklyDriftUnified: Double {
        get { periodUnit == .weeks ? bearWeeklyDriftWeekly : bearWeeklyDriftMonthly }
        set {
            if periodUnit == .weeks {
                bearWeeklyDriftWeekly = newValue
            } else {
                bearWeeklyDriftMonthly = newValue
            }
        }
    }
    
    // MARK: - Maturing Market
    var useMaturingMarketUnified: Bool {
        get { periodUnit == .weeks ? useMaturingMarketWeekly : useMaturingMarketMonthly }
        set {
            if periodUnit == .weeks {
                useMaturingMarketWeekly = newValue
            } else {
                useMaturingMarketMonthly = newValue
            }
        }
    }
    var maxMaturingDropUnified: Double {
        get { periodUnit == .weeks ? maxMaturingDropWeekly : maxMaturingDropMonthly }
        set {
            if periodUnit == .weeks {
                maxMaturingDropWeekly = newValue
            } else {
                maxMaturingDropMonthly = newValue
            }
        }
    }
    
    // MARK: - Recession
    var useRecessionUnified: Bool {
        get { periodUnit == .weeks ? useRecessionWeekly : useRecessionMonthly }
        set {
            if periodUnit == .weeks {
                useRecessionWeekly = newValue
            } else {
                useRecessionMonthly = newValue
            }
        }
    }
    var maxRecessionDropUnified: Double {
        get { periodUnit == .weeks ? maxRecessionDropWeekly : maxRecessionDropMonthly }
        set {
            if periodUnit == .weeks {
                maxRecessionDropWeekly = newValue
            } else {
                maxRecessionDropMonthly = newValue
            }
        }
    }
}
