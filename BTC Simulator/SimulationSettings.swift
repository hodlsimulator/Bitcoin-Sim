//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    
    // MARK: - Bullish Toggles
    @Published var useHalving               = true
    @Published var halvingBump              = 0.20
    
    @Published var useInstitutionalDemand    = true
    @Published var maxDemandBoost           = 0.004
    
    @Published var useCountryAdoption        = true
    @Published var maxCountryAdBoost        = 0.0055
    
    @Published var useRegulatoryClarity      = true
    @Published var maxClarityBoost          = 0.0006
    
    @Published var useEtfApproval            = true
    @Published var maxEtfBoost              = 0.0008
    
    @Published var useTechBreakthrough       = true
    @Published var maxTechBoost             = 0.002
    
    @Published var useScarcityEvents         = true
    @Published var maxScarcityBoost         = 0.025
    
    @Published var useGlobalMacroHedge       = true
    @Published var maxMacroBoost            = 0.0015
    
    @Published var useStablecoinShift        = true
    @Published var maxStablecoinBoost       = 0.0006
    
    @Published var useDemographicAdoption    = true
    @Published var maxDemoBoost             = 0.001
    
    @Published var useAltcoinFlight          = true
    @Published var maxAltcoinBoost          = 0.001
    
    @Published var useAdoptionFactor         = true
    @Published var adoptionBaseFactor       = 0.000005
    
    // MARK: - Bearish Toggles
    @Published var useRegClampdown           = true
    @Published var maxClampDown             = -0.0002
    
    @Published var useCompetitorCoin         = true
    @Published var maxCompetitorBoost       = -0.0018
    
    @Published var useSecurityBreach         = true
    @Published var breachImpact             = -0.1
    
    @Published var useBubblePop              = true
    @Published var maxPopDrop               = -0.005
    
    @Published var useStablecoinMeltdown     = true
    @Published var maxMeltdownDrop          = -0.001
    
    @Published var useBlackSwan              = true
    @Published var blackSwanDrop            = -0.60
    
    @Published var useBearMarket             = true
    @Published var bearWeeklyDrift          = -0.01
    
    @Published var useMaturingMarket         = true
    @Published var maxMaturingDrop          = -0.015
    
    @Published var useRecession              = true
    @Published var maxRecessionDrop         = -0.004
}
