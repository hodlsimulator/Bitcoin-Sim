//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

// 1) Create an ObservableObject to hold all toggle states (plus any sliders/text fields).
//    Each @Published var corresponds to a factor in your MonteCarloSimulator logic.
class SimulationSettings: ObservableObject {
    // Bullish factors
    @Published var useHalving               = false
    @Published var useInstitutionalDemand    = true
    @Published var useCountryAdoption        = true
    @Published var useRegulatoryClarity      = true
    @Published var useEtfApproval            = true
    @Published var useTechBreakthrough       = true
    @Published var useScarcityEvents         = true
    @Published var useGlobalMacroHedge       = true
    @Published var useStablecoinShift        = true
    @Published var useDemographicAdoption    = true
    @Published var useAltcoinFlight          = true
    @Published var useAdoptionFactor         = true

    // Bearish factors
    @Published var useRegClampdown           = true
    @Published var useCompetitorCoin         = true
    @Published var useSecurityBreach         = true
    @Published var useBubblePop              = true
    @Published var useStablecoinMeltdown     = true
    @Published var useBlackSwan              = true
    @Published var useBearMarket             = true
    @Published var useMaturingMarket         = true
    @Published var useRecession              = true

    // Example slider parameters (e.g. halvingBump, maxDemandBoost).
    // Just for illustration; you can add as many as needed.
    @Published var halvingBump       = 0.20
    @Published var maxDemandBoost    = 0.004
    @Published var maxCountryAdBoost = 0.0055
    // etc.
}
