//
//  SimulationSettings+Defaults.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    // MARK: - Hardcoded Default Constants for Weekly vs. Monthly Factors

    // -----------------------------
    // BULLISH FACTORS
    // -----------------------------

    // Halving
    static let defaultHalvingBumpWeekly   = 0.32983868867158894
    static let defaultHalvingBumpMonthly  = 0.35

    // Institutional Demand
    static let defaultMaxDemandBoostWeekly   = 0.001239
    static let defaultMaxDemandBoostMonthly  = 0.0056589855

    // Country Adoption
    static let defaultMaxCountryAdBoostWeekly   = 0.0011375879977679254
    static let defaultMaxCountryAdBoostMonthly  = 0.005515515952320099

    // Regulatory Clarity
    static let defaultMaxClarityBoostWeekly   = 0.0007170254861605167
    static let defaultMaxClarityBoostMonthly  = 0.0040737327

    // ETF Approval
    static let defaultMaxEtfBoostWeekly   = 0.0017880183160305023
    static let defaultMaxEtfBoostMonthly  = 0.0057142851

    // Tech Breakthrough
    static let defaultMaxTechBoostWeekly   = 0.0006083193579173088
    static let defaultMaxTechBoostMonthly  = 0.0028387091

    // Scarcity Events
    static let defaultMaxScarcityBoostWeekly   = 0.00041308753681182863
    static let defaultMaxScarcityBoostMonthly  = 0.0032928705475521085

    // Global Macro Hedge
    static let defaultMaxMacroBoostWeekly   = 0.0003497809724932909
    static let defaultMaxMacroBoostMonthly  = 0.0032442397

    // Stablecoin Shift
    static let defaultMaxStablecoinBoostWeekly   = 0.0003312209116327763
    static let defaultMaxStablecoinBoostMonthly  = 0.0023041475

    // Demographic Adoption
    static let defaultMaxDemoBoostWeekly   = 0.0010619932036626339
    static let defaultMaxDemoBoostMonthly  = 0.007291124714649915

    // Altcoin Flight
    static let defaultMaxAltcoinBoostWeekly   = 0.0002802194461803342
    static let defaultMaxAltcoinBoostMonthly  = 0.0021566817

    // Adoption Factor
    static let defaultAdoptionBaseFactorWeekly   = 0.0016045109088897705
    static let defaultAdoptionBaseFactorMonthly  = 0.014660959934071304

    // -----------------------------
    // BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    static let defaultMaxClampDownWeekly   = -0.0011361452243542672
    static let defaultMaxClampDownMonthly  = -0.02

    // Competitor Coin
    static let defaultMaxCompetitorBoostWeekly   = -0.0010148181746411323
    static let defaultMaxCompetitorBoostMonthly  = -0.008

    // Security Breach
    static let defaultBreachImpactWeekly   = -0.0010914715168380737
    static let defaultBreachImpactMonthly  = -0.007

    // Bubble Pop
    static let defaultMaxPopDropWeekly   = -0.001762673890762329
    static let defaultMaxPopDropMonthly  = -0.01

    // Stablecoin Meltdown
    static let defaultMaxMeltdownDropWeekly   = -0.0007141026159477233
    static let defaultMaxMeltdownDropMonthly  = -0.01

    // Black Swan
    static let defaultBlackSwanDropWeekly   = -0.39888499999999993
    static let defaultBlackSwanDropMonthly  = -0.4

    // Bear Market
    static let defaultBearWeeklyDriftWeekly   = -0.0008778802752494812
    static let defaultBearWeeklyDriftMonthly  = -0.01

    // Maturing Market
    static let defaultMaxMaturingDropWeekly   = -0.0015440231055486196
    static let defaultMaxMaturingDropMonthly  = -0.01

    // Recession
    static let defaultMaxRecessionDropWeekly   = -0.0009005491467487811
    static let defaultMaxRecessionDropMonthly  = -0.0014508080482482913
}
