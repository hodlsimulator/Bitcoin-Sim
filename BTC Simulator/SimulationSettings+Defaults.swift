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
    static let defaultHalvingBumpWeekly   = 0.35   // was 0.2
    static let defaultHalvingBumpMonthly  = 0.35   // was 0.35

    // Institutional Demand
    static let defaultMaxDemandBoostWeekly   = 0.001239      // was 0.0012392541338671777
    static let defaultMaxDemandBoostMonthly  = 0.0056589855  // was 0.008 (unchanged)

    // Country Adoption
    static let defaultMaxCountryAdBoostWeekly   = 0.0009953915979713202  // was 0.00047095964199831683
    static let defaultMaxCountryAdBoostMonthly  = 0.005515515952320099    // was 0.0031705064

    // Regulatory Clarity
    static let defaultMaxClarityBoostWeekly   = 0.000793849712267518  // was 0.0016644023749474966 (monthly)
    static let defaultMaxClarityBoostMonthly  = 0.0040737327          // was 0.008 (unchanged)

    // ETF Approval
    static let defaultMaxEtfBoostWeekly   = 0.002         // was 0.00045468
    static let defaultMaxEtfBoostMonthly  = 0.0057142851  // was 0.008 (unchanged)

    // Tech Breakthrough
    static let defaultMaxTechBoostWeekly   = 0.00071162    // was 0.00040663959745637255
    static let defaultMaxTechBoostMonthly  = 0.0028387091  // was 0.008 (unchanged)

    // Scarcity Events
    static let defaultMaxScarcityBoostWeekly   = 0.00041308753681182863  // was 0.0007968083934443039
    static let defaultMaxScarcityBoostMonthly  = 0.0032928705475521085   // was 0.0023778799

    // Global Macro Hedge
    static let defaultMaxMacroBoostWeekly   = 0.00041935     // was 0.000419354572892189
    static let defaultMaxMacroBoostMonthly  = 0.0032442397   // was 0.008 (unchanged)

    // Stablecoin Shift
    static let defaultMaxStablecoinBoostWeekly   = 0.00040493     // was 0.0004049262363101775
    static let defaultMaxStablecoinBoostMonthly  = 0.0023041475   // was 0.008 (unchanged)

    // Demographic Adoption
    static let defaultMaxDemoBoostWeekly   = 0.00130568       // was 0.0013056834936141968
    static let defaultMaxDemoBoostMonthly  = 0.007291124714649915  // was 0.0054746541

    // Altcoin Flight
    static let defaultMaxAltcoinBoostWeekly   = 0.0002802194461803342  // unchanged
    static let defaultMaxAltcoinBoostMonthly  = 0.0021566817           // was 0.008 (unchanged)

    // Adoption Factor
    static let defaultAdoptionBaseFactorWeekly   = 0.0016045109088897705  // was 0.0009685099124908447
    static let defaultAdoptionBaseFactorMonthly  = 0.014660959934071304   // was 0.009714285

    // -----------------------------
    // BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    static let defaultMaxClampDownWeekly   = -0.0019412885584652421  // was -0.0011883256912231445 (monthly)
    static let defaultMaxClampDownMonthly  = -0.02  // was -0.0011883256912231445

    // Competitor Coin
    static let defaultMaxCompetitorBoostWeekly   = -0.001129314495845437  // was -0.0011259913444519043
    static let defaultMaxCompetitorBoostMonthly  = -0.008  // was -0.0011259913444519043

    // Security Breach
    static let defaultBreachImpactWeekly   = -0.0012699694280987979  // was -0.0007612827334384092 (monthly)
    static let defaultBreachImpactMonthly  = -0.007  //was -0.0007612827334384092

    // Bubble Pop
    static let defaultMaxPopDropWeekly   = -0.003214285969734192  // was -0.0012555068731307985
    static let defaultMaxPopDropMonthly  = -0.01  // was -0.0012555068731307985

    // Stablecoin Meltdown
    static let defaultMaxMeltdownDropWeekly   = -0.0016935482919216154  // was -0.0006013240111422539
    static let defaultMaxMeltdownDropMonthly  = -0.01  // was -0.0007028046205417837

    // Black Swan
    static let defaultBlackSwanDropWeekly   = -0.7977726936340332  // was -0.3
    static let defaultBlackSwanDropMonthly  = -0.4  // was -0.8

    // Bear Market
    static let defaultBearWeeklyDriftWeekly   = -0.001  // was -0.0001
    static let defaultBearWeeklyDriftMonthly  = -0.01  // was -0.0007195305824279769

    // Maturing Market
    static let defaultMaxMaturingDropWeekly   = -0.00326881742477417  // was -0.004
    static let defaultMaxMaturingDropMonthly  = -0.01  // was -0.004

    // Recession
    static let defaultMaxRecessionDropWeekly   = -0.0010073162441545725  // was -0.0014508080482482913
    static let defaultMaxRecessionDropMonthly  = -0.0014508080482482913
}
