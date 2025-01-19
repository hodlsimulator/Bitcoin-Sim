//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A class for storing user toggles and results
class SimulationSettings: ObservableObject {
    /// This flag will be `true` only when the user flips the "toggle all" switch in the UI.
    /// It will be `false` if code flips `toggleAll`.
    var userIsActuallyTogglingAll = false
    
    // MARK: - Hardcoded Default Constants for Weekly vs. Monthly Factors

    // -----------------------------
    // BULLISH FACTORS
    // -----------------------------

    // Halving
    private static let defaultHalvingBumpWeekly   = 0.35   // was 0.2
    private static let defaultHalvingBumpMonthly  = 0.35   // was 0.35

    // Institutional Demand
    private static let defaultMaxDemandBoostWeekly   = 0.001239      // was 0.0012392541338671777
    private static let defaultMaxDemandBoostMonthly  = 0.0056589855  // was 0.008 (unchanged)

    // Country Adoption
    private static let defaultMaxCountryAdBoostWeekly   = 0.0009953915979713202  // was 0.00047095964199831683
    private static let defaultMaxCountryAdBoostMonthly  = 0.005515515952320099    // was 0.0031705064

    // Regulatory Clarity
    private static let defaultMaxClarityBoostWeekly   = 0.000793849712267518  // was 0.0016644023749474966 (monthly)
    private static let defaultMaxClarityBoostMonthly  = 0.0040737327          // was 0.008 (unchanged)

    // ETF Approval
    private static let defaultMaxEtfBoostWeekly   = 0.002         // was 0.00045468
    private static let defaultMaxEtfBoostMonthly  = 0.0057142851  // was 0.008 (unchanged)

    // Tech Breakthrough
    private static let defaultMaxTechBoostWeekly   = 0.00071162    // was 0.00040663959745637255
    private static let defaultMaxTechBoostMonthly  = 0.0028387091  // was 0.008 (unchanged)

    // Scarcity Events
    private static let defaultMaxScarcityBoostWeekly   = 0.00041308753681182863  // was 0.0007968083934443039
    private static let defaultMaxScarcityBoostMonthly  = 0.0032928705475521085   // was 0.0023778799

    // Global Macro Hedge
    private static let defaultMaxMacroBoostWeekly   = 0.00041935     // was 0.000419354572892189
    private static let defaultMaxMacroBoostMonthly  = 0.0032442397   // was 0.008 (unchanged)

    // Stablecoin Shift
    private static let defaultMaxStablecoinBoostWeekly   = 0.00040493     // was 0.0004049262363101775
    private static let defaultMaxStablecoinBoostMonthly  = 0.0023041475   // was 0.008 (unchanged)

    // Demographic Adoption
    private static let defaultMaxDemoBoostWeekly   = 0.00130568       // was 0.0013056834936141968
    private static let defaultMaxDemoBoostMonthly  = 0.007291124714649915  // was 0.0054746541

    // Altcoin Flight
    private static let defaultMaxAltcoinBoostWeekly   = 0.0002802194461803342  // unchanged
    private static let defaultMaxAltcoinBoostMonthly  = 0.0021566817           // was 0.008 (unchanged)

    // Adoption Factor
    private static let defaultAdoptionBaseFactorWeekly   = 0.0016045109088897705  // was 0.0009685099124908447
    private static let defaultAdoptionBaseFactorMonthly  = 0.014660959934071304   // was 0.009714285

    // -----------------------------
    // BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    private static let defaultMaxClampDownWeekly   = -0.0019412885584652421  // was -0.0011883256912231445 (monthly)
    private static let defaultMaxClampDownMonthly  = -0.02  // was -0.0011883256912231445

    // Competitor Coin
    private static let defaultMaxCompetitorBoostWeekly   = -0.001129314495845437  // was -0.0011259913444519043
    private static let defaultMaxCompetitorBoostMonthly  = -0.008  // was -0.0011259913444519043

    // Security Breach
    private static let defaultBreachImpactWeekly   = -0.0012699694280987979  // was -0.0007612827334384092 (monthly)
    private static let defaultBreachImpactMonthly  = -0.007  //was -0.0007612827334384092

    // Bubble Pop
    private static let defaultMaxPopDropWeekly   = -0.003214285969734192  // was -0.0012555068731307985
    private static let defaultMaxPopDropMonthly  = -0.01  // was -0.0012555068731307985

    // Stablecoin Meltdown
    private static let defaultMaxMeltdownDropWeekly   = -0.0016935482919216154  // was -0.0006013240111422539
    private static let defaultMaxMeltdownDropMonthly  = -0.01  // was -0.0007028046205417837 

    // Black Swan
    private static let defaultBlackSwanDropWeekly   = -0.7977726936340332  // was -0.3
    private static let defaultBlackSwanDropMonthly  = -0.8  // was -0.0018411452783672483

    // Bear Market
    private static let defaultBearWeeklyDriftWeekly   = -0.001  // was -0.0001
    private static let defaultBearWeeklyDriftMonthly  = -0.01  // was -0.0007195305824279769

    // Maturing Market
    private static let defaultMaxMaturingDropWeekly   = -0.00326881742477417  // was -0.004
    private static let defaultMaxMaturingDropMonthly  = -0.01  // was -0.004

    // Recession
    private static let defaultMaxRecessionDropWeekly   = -0.0010073162441545725  // was -0.0014508080482482913
    private static let defaultMaxRecessionDropMonthly  = -0.0014508080482482913
    
    init() {
        let defaults = UserDefaults.standard
        // Temporarily prevent didSet logic from firing while we load from UserDefaults
        isUpdating = true

        // ------------------------------------------------
        // Basic Settings
        // ------------------------------------------------

        if let storedPeriodUnit = defaults.string(forKey: "periodUnit"),
           let loadedPeriodUnit = PeriodUnit(rawValue: storedPeriodUnit) {
            periodUnit = loadedPeriodUnit
        }
        if defaults.object(forKey: "userPeriods") != nil {
            userPeriods = defaults.integer(forKey: "userPeriods")
        }
        if defaults.object(forKey: "initialBTCPriceUSD") != nil {
            initialBTCPriceUSD = defaults.double(forKey: "initialBTCPriceUSD")
        }
        if defaults.object(forKey: "startingBalance") != nil {
            startingBalance = defaults.double(forKey: "startingBalance")
        }
        if defaults.object(forKey: "averageCostBasis") != nil {
            averageCostBasis = defaults.double(forKey: "averageCostBasis")
        }

        if let currencyString = defaults.string(forKey: "currencyPreference"),
           let loadedCurrency = PreferredCurrency(rawValue: currencyString) {
            currencyPreference = loadedCurrency
        }
        // These two are used only if you have logic to save them:
        // if let ccwbString = defaults.string(forKey: "contributionCurrencyWhenBoth"),
        //    let ccwbEnum = PreferredCurrency(rawValue: ccwbString) {
        //    contributionCurrencyWhenBoth = ccwbEnum
        // }
        // if let sbcwbString = defaults.string(forKey: "startingBalanceCurrencyWhenBoth"),
        //    let sbcwbEnum = PreferredCurrency(rawValue: sbcwbString) {
        //    startingBalanceCurrencyWhenBoth = sbcwbEnum
        // }

        // ------------------------------------------------
        // Master Toggle
        // ------------------------------------------------
        if defaults.object(forKey: "toggleAll") != nil {
            toggleAll = defaults.bool(forKey: "toggleAll")
        }

        // ------------------------------------------------
        // Seeds & Sampling
        // ------------------------------------------------
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        }
        if defaults.object(forKey: "lockedRandomSeed") != nil {
            lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        }
        let rawSeed = defaults.integer(forKey: "seedValue")
        if rawSeed >= 0 {
            seedValue = UInt64(rawSeed)
        } else {
            // Fallback to zero or any default you prefer
            seedValue = 0
        }
        if defaults.object(forKey: "useRandomSeed") != nil {
            useRandomSeed = defaults.bool(forKey: "useRandomSeed")
        }
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        }
        if defaults.object(forKey: "useVolShocks") != nil {
            useVolShocks = defaults.bool(forKey: "useVolShocks")
        }
        if defaults.object(forKey: "lastUsedSeed") != nil {
            lastUsedSeed = UInt64(defaults.integer(forKey: "lastUsedSeed"))
        }
        if defaults.object(forKey: "lockHistoricalSampling") != nil {
            lockHistoricalSampling = defaults.bool(forKey: "lockHistoricalSampling")
        }

        // ------------------------------------------------
        // BULLISH FACTORS
        // ------------------------------------------------

        // Halving
        if defaults.object(forKey: "useHalving") != nil {
            useHalving = defaults.bool(forKey: "useHalving")
        }
        if defaults.object(forKey: "useHalvingWeekly") != nil {
            useHalvingWeekly = defaults.bool(forKey: "useHalvingWeekly")
        }
        if defaults.object(forKey: "useHalvingMonthly") != nil {
            useHalvingMonthly = defaults.bool(forKey: "useHalvingMonthly")
        }
        if defaults.object(forKey: "halvingBumpWeekly") != nil {
            halvingBumpWeekly = defaults.double(forKey: "halvingBumpWeekly")
        }
        if defaults.object(forKey: "halvingBumpMonthly") != nil {
            halvingBumpMonthly = defaults.double(forKey: "halvingBumpMonthly")
        }

        // Institutional Demand
        if defaults.object(forKey: "useInstitutionalDemand") != nil {
            useInstitutionalDemand = defaults.bool(forKey: "useInstitutionalDemand")
        }
        if defaults.object(forKey: "useInstitutionalDemandWeekly") != nil {
            useInstitutionalDemandWeekly = defaults.bool(forKey: "useInstitutionalDemandWeekly")
        }
        if defaults.object(forKey: "useInstitutionalDemandMonthly") != nil {
            useInstitutionalDemandMonthly = defaults.bool(forKey: "useInstitutionalDemandMonthly")
        }
        if defaults.object(forKey: "maxDemandBoostWeekly") != nil {
            maxDemandBoostWeekly = defaults.double(forKey: "maxDemandBoostWeekly")
        }
        if defaults.object(forKey: "maxDemandBoostMonthly") != nil {
            maxDemandBoostMonthly = defaults.double(forKey: "maxDemandBoostMonthly")
        }

        // Country Adoption
        if defaults.object(forKey: "useCountryAdoption") != nil {
            useCountryAdoption = defaults.bool(forKey: "useCountryAdoption")
        }
        if defaults.object(forKey: "useCountryAdoptionWeekly") != nil {
            useCountryAdoptionWeekly = defaults.bool(forKey: "useCountryAdoptionWeekly")
        }
        if defaults.object(forKey: "useCountryAdoptionMonthly") != nil {
            useCountryAdoptionMonthly = defaults.bool(forKey: "useCountryAdoptionMonthly")
        }
        if defaults.object(forKey: "maxCountryAdBoostWeekly") != nil {
            maxCountryAdBoostWeekly = defaults.double(forKey: "maxCountryAdBoostWeekly")
        }
        if defaults.object(forKey: "maxCountryAdBoostMonthly") != nil {
            maxCountryAdBoostMonthly = defaults.double(forKey: "maxCountryAdBoostMonthly")
        }

        // Regulatory Clarity
        if defaults.object(forKey: "useRegulatoryClarity") != nil {
            useRegulatoryClarity = defaults.bool(forKey: "useRegulatoryClarity")
        }
        if defaults.object(forKey: "useRegulatoryClarityWeekly") != nil {
            useRegulatoryClarityWeekly = defaults.bool(forKey: "useRegulatoryClarityWeekly")
        }
        if defaults.object(forKey: "useRegulatoryClarityMonthly") != nil {
            useRegulatoryClarityMonthly = defaults.bool(forKey: "useRegulatoryClarityMonthly")
        }
        if defaults.object(forKey: "maxClarityBoostWeekly") != nil {
            maxClarityBoostWeekly = defaults.double(forKey: "maxClarityBoostWeekly")
        }
        if defaults.object(forKey: "maxClarityBoostMonthly") != nil {
            maxClarityBoostMonthly = defaults.double(forKey: "maxClarityBoostMonthly")
        }

        // ETF Approval
        if defaults.object(forKey: "useEtfApproval") != nil {
            useEtfApproval = defaults.bool(forKey: "useEtfApproval")
        }
        if defaults.object(forKey: "useEtfApprovalWeekly") != nil {
            useEtfApprovalWeekly = defaults.bool(forKey: "useEtfApprovalWeekly")
        }
        if defaults.object(forKey: "useEtfApprovalMonthly") != nil {
            useEtfApprovalMonthly = defaults.bool(forKey: "useEtfApprovalMonthly")
        }
        if defaults.object(forKey: "maxEtfBoostWeekly") != nil {
            maxEtfBoostWeekly = defaults.double(forKey: "maxEtfBoostWeekly")
        }
        if defaults.object(forKey: "maxEtfBoostMonthly") != nil {
            maxEtfBoostMonthly = defaults.double(forKey: "maxEtfBoostMonthly")
        }

        // Tech Breakthrough
        if defaults.object(forKey: "useTechBreakthrough") != nil {
            useTechBreakthrough = defaults.bool(forKey: "useTechBreakthrough")
        }
        if defaults.object(forKey: "useTechBreakthroughWeekly") != nil {
            useTechBreakthroughWeekly = defaults.bool(forKey: "useTechBreakthroughWeekly")
        }
        if defaults.object(forKey: "useTechBreakthroughMonthly") != nil {
            useTechBreakthroughMonthly = defaults.bool(forKey: "useTechBreakthroughMonthly")
        }
        if defaults.object(forKey: "maxTechBoostWeekly") != nil {
            maxTechBoostWeekly = defaults.double(forKey: "maxTechBoostWeekly")
        }
        if defaults.object(forKey: "maxTechBoostMonthly") != nil {
            maxTechBoostMonthly = defaults.double(forKey: "maxTechBoostMonthly")
        }

        // Scarcity Events
        if defaults.object(forKey: "useScarcityEvents") != nil {
            useScarcityEvents = defaults.bool(forKey: "useScarcityEvents")
        }
        if defaults.object(forKey: "useScarcityEventsWeekly") != nil {
            useScarcityEventsWeekly = defaults.bool(forKey: "useScarcityEventsWeekly")
        }
        if defaults.object(forKey: "useScarcityEventsMonthly") != nil {
            useScarcityEventsMonthly = defaults.bool(forKey: "useScarcityEventsMonthly")
        }
        if defaults.object(forKey: "maxScarcityBoostWeekly") != nil {
            maxScarcityBoostWeekly = defaults.double(forKey: "maxScarcityBoostWeekly")
        }
        if defaults.object(forKey: "maxScarcityBoostMonthly") != nil {
            maxScarcityBoostMonthly = defaults.double(forKey: "maxScarcityBoostMonthly")
        }

        // Global Macro Hedge
        if defaults.object(forKey: "useGlobalMacroHedge") != nil {
            useGlobalMacroHedge = defaults.bool(forKey: "useGlobalMacroHedge")
        }
        if defaults.object(forKey: "useGlobalMacroHedgeWeekly") != nil {
            useGlobalMacroHedgeWeekly = defaults.bool(forKey: "useGlobalMacroHedgeWeekly")
        }
        if defaults.object(forKey: "useGlobalMacroHedgeMonthly") != nil {
            useGlobalMacroHedgeMonthly = defaults.bool(forKey: "useGlobalMacroHedgeMonthly")
        }
        if defaults.object(forKey: "maxMacroBoostWeekly") != nil {
            maxMacroBoostWeekly = defaults.double(forKey: "maxMacroBoostWeekly")
        }
        if defaults.object(forKey: "maxMacroBoostMonthly") != nil {
            maxMacroBoostMonthly = defaults.double(forKey: "maxMacroBoostMonthly")
        }

        // Stablecoin Shift
        if defaults.object(forKey: "useStablecoinShift") != nil {
            useStablecoinShift = defaults.bool(forKey: "useStablecoinShift")
        }
        if defaults.object(forKey: "useStablecoinShiftWeekly") != nil {
            useStablecoinShiftWeekly = defaults.bool(forKey: "useStablecoinShiftWeekly")
        }
        if defaults.object(forKey: "useStablecoinShiftMonthly") != nil {
            useStablecoinShiftMonthly = defaults.bool(forKey: "useStablecoinShiftMonthly")
        }
        if defaults.object(forKey: "maxStablecoinBoostWeekly") != nil {
            maxStablecoinBoostWeekly = defaults.double(forKey: "maxStablecoinBoostWeekly")
        }
        if defaults.object(forKey: "maxStablecoinBoostMonthly") != nil {
            maxStablecoinBoostMonthly = defaults.double(forKey: "maxStablecoinBoostMonthly")
        }

        // Demographic Adoption
        if defaults.object(forKey: "useDemographicAdoption") != nil {
            useDemographicAdoption = defaults.bool(forKey: "useDemographicAdoption")
        }
        if defaults.object(forKey: "useDemographicAdoptionWeekly") != nil {
            useDemographicAdoptionWeekly = defaults.bool(forKey: "useDemographicAdoptionWeekly")
        }
        if defaults.object(forKey: "useDemographicAdoptionMonthly") != nil {
            useDemographicAdoptionMonthly = defaults.bool(forKey: "useDemographicAdoptionMonthly")
        }
        if defaults.object(forKey: "maxDemoBoostWeekly") != nil {
            maxDemoBoostWeekly = defaults.double(forKey: "maxDemoBoostWeekly")
        }
        if defaults.object(forKey: "maxDemoBoostMonthly") != nil {
            maxDemoBoostMonthly = defaults.double(forKey: "maxDemoBoostMonthly")
        }

        // Altcoin Flight
        if defaults.object(forKey: "useAltcoinFlight") != nil {
            useAltcoinFlight = defaults.bool(forKey: "useAltcoinFlight")
        }
        if defaults.object(forKey: "useAltcoinFlightWeekly") != nil {
            useAltcoinFlightWeekly = defaults.bool(forKey: "useAltcoinFlightWeekly")
        }
        if defaults.object(forKey: "useAltcoinFlightMonthly") != nil {
            useAltcoinFlightMonthly = defaults.bool(forKey: "useAltcoinFlightMonthly")
        }
        if defaults.object(forKey: "maxAltcoinBoostWeekly") != nil {
            maxAltcoinBoostWeekly = defaults.double(forKey: "maxAltcoinBoostWeekly")
        }
        if defaults.object(forKey: "maxAltcoinBoostMonthly") != nil {
            maxAltcoinBoostMonthly = defaults.double(forKey: "maxAltcoinBoostMonthly")
        }

        // Adoption Factor
        if defaults.object(forKey: "useAdoptionFactor") != nil {
            useAdoptionFactor = defaults.bool(forKey: "useAdoptionFactor")
        }
        if defaults.object(forKey: "useAdoptionFactorWeekly") != nil {
            useAdoptionFactorWeekly = defaults.bool(forKey: "useAdoptionFactorWeekly")
        }
        if defaults.object(forKey: "useAdoptionFactorMonthly") != nil {
            useAdoptionFactorMonthly = defaults.bool(forKey: "useAdoptionFactorMonthly")
        }
        if defaults.object(forKey: "adoptionBaseFactorWeekly") != nil {
            adoptionBaseFactorWeekly = defaults.double(forKey: "adoptionBaseFactorWeekly")
        }
        if defaults.object(forKey: "adoptionBaseFactorMonthly") != nil {
            adoptionBaseFactorMonthly = defaults.double(forKey: "adoptionBaseFactorMonthly")
        }

        // ------------------------------------------------
        // BEARISH FACTORS
        // ------------------------------------------------

        // Regulatory Clampdown
        if defaults.object(forKey: "useRegClampdown") != nil {
            useRegClampdown = defaults.bool(forKey: "useRegClampdown")
        }
        if defaults.object(forKey: "useRegClampdownWeekly") != nil {
            useRegClampdownWeekly = defaults.bool(forKey: "useRegClampdownWeekly")
        }
        if defaults.object(forKey: "useRegClampdownMonthly") != nil {
            useRegClampdownMonthly = defaults.bool(forKey: "useRegClampdownMonthly")
        }
        if defaults.object(forKey: "maxClampDownWeekly") != nil {
            maxClampDownWeekly = defaults.double(forKey: "maxClampDownWeekly")
        }
        if defaults.object(forKey: "maxClampDownMonthly") != nil {
            maxClampDownMonthly = defaults.double(forKey: "maxClampDownMonthly")
        }

        // Competitor Coin
        if defaults.object(forKey: "useCompetitorCoin") != nil {
            useCompetitorCoin = defaults.bool(forKey: "useCompetitorCoin")
        }
        if defaults.object(forKey: "useCompetitorCoinWeekly") != nil {
            useCompetitorCoinWeekly = defaults.bool(forKey: "useCompetitorCoinWeekly")
        }
        if defaults.object(forKey: "useCompetitorCoinMonthly") != nil {
            useCompetitorCoinMonthly = defaults.bool(forKey: "useCompetitorCoinMonthly")
        }
        if defaults.object(forKey: "maxCompetitorBoostWeekly") != nil {
            maxCompetitorBoostWeekly = defaults.double(forKey: "maxCompetitorBoostWeekly")
        }
        if defaults.object(forKey: "maxCompetitorBoostMonthly") != nil {
            maxCompetitorBoostMonthly = defaults.double(forKey: "maxCompetitorBoostMonthly")
        }

        // Security Breach
        if defaults.object(forKey: "useSecurityBreach") != nil {
            useSecurityBreach = defaults.bool(forKey: "useSecurityBreach")
        }
        if defaults.object(forKey: "useSecurityBreachWeekly") != nil {
            useSecurityBreachWeekly = defaults.bool(forKey: "useSecurityBreachWeekly")
        }
        if defaults.object(forKey: "useSecurityBreachMonthly") != nil {
            useSecurityBreachMonthly = defaults.bool(forKey: "useSecurityBreachMonthly")
        }
        if defaults.object(forKey: "breachImpactWeekly") != nil {
            breachImpactWeekly = defaults.double(forKey: "breachImpactWeekly")
        }
        if defaults.object(forKey: "breachImpactMonthly") != nil {
            breachImpactMonthly = defaults.double(forKey: "breachImpactMonthly")
        }

        // Bubble Pop
        if defaults.object(forKey: "useBubblePop") != nil {
            useBubblePop = defaults.bool(forKey: "useBubblePop")
        }
        if defaults.object(forKey: "useBubblePopWeekly") != nil {
            useBubblePopWeekly = defaults.bool(forKey: "useBubblePopWeekly")
        }
        if defaults.object(forKey: "useBubblePopMonthly") != nil {
            useBubblePopMonthly = defaults.bool(forKey: "useBubblePopMonthly")
        }
        if defaults.object(forKey: "maxPopDropWeekly") != nil {
            maxPopDropWeekly = defaults.double(forKey: "maxPopDropWeekly")
        }
        if defaults.object(forKey: "maxPopDropMonthly") != nil {
            maxPopDropMonthly = defaults.double(forKey: "maxPopDropMonthly")
        }

        // Stablecoin Meltdown
        if defaults.object(forKey: "useStablecoinMeltdown") != nil {
            useStablecoinMeltdown = defaults.bool(forKey: "useStablecoinMeltdown")
        }
        if defaults.object(forKey: "useStablecoinMeltdownWeekly") != nil {
            useStablecoinMeltdownWeekly = defaults.bool(forKey: "useStablecoinMeltdownWeekly")
        }
        if defaults.object(forKey: "useStablecoinMeltdownMonthly") != nil {
            useStablecoinMeltdownMonthly = defaults.bool(forKey: "useStablecoinMeltdownMonthly")
        }
        if defaults.object(forKey: "maxMeltdownDropWeekly") != nil {
            maxMeltdownDropWeekly = defaults.double(forKey: "maxMeltdownDropWeekly")
        }
        if defaults.object(forKey: "maxMeltdownDropMonthly") != nil {
            maxMeltdownDropMonthly = defaults.double(forKey: "maxMeltdownDropMonthly")
        }

        // Black Swan
        if defaults.object(forKey: "useBlackSwan") != nil {
            useBlackSwan = defaults.bool(forKey: "useBlackSwan")
        }
        if defaults.object(forKey: "useBlackSwanWeekly") != nil {
            useBlackSwanWeekly = defaults.bool(forKey: "useBlackSwanWeekly")
        }
        if defaults.object(forKey: "useBlackSwanMonthly") != nil {
            useBlackSwanMonthly = defaults.bool(forKey: "useBlackSwanMonthly")
        }
        if defaults.object(forKey: "blackSwanDropWeekly") != nil {
            blackSwanDropWeekly = defaults.double(forKey: "blackSwanDropWeekly")
        }
        if defaults.object(forKey: "blackSwanDropMonthly") != nil {
            blackSwanDropMonthly = defaults.double(forKey: "blackSwanDropMonthly")
        }

        // Bear Market
        if defaults.object(forKey: "useBearMarket") != nil {
            useBearMarket = defaults.bool(forKey: "useBearMarket")
        }
        if defaults.object(forKey: "useBearMarketWeekly") != nil {
            useBearMarketWeekly = defaults.bool(forKey: "useBearMarketWeekly")
        }
        if defaults.object(forKey: "useBearMarketMonthly") != nil {
            useBearMarketMonthly = defaults.bool(forKey: "useBearMarketMonthly")
        }
        if defaults.object(forKey: "bearWeeklyDriftWeekly") != nil {
            bearWeeklyDriftWeekly = defaults.double(forKey: "bearWeeklyDriftWeekly")
        }
        if defaults.object(forKey: "bearWeeklyDriftMonthly") != nil {
            bearWeeklyDriftMonthly = defaults.double(forKey: "bearWeeklyDriftMonthly")
        }

        // Maturing Market
        if defaults.object(forKey: "useMaturingMarket") != nil {
            useMaturingMarket = defaults.bool(forKey: "useMaturingMarket")
        }
        if defaults.object(forKey: "useMaturingMarketWeekly") != nil {
            useMaturingMarketWeekly = defaults.bool(forKey: "useMaturingMarketWeekly")
        }
        if defaults.object(forKey: "useMaturingMarketMonthly") != nil {
            useMaturingMarketMonthly = defaults.bool(forKey: "useMaturingMarketMonthly")
        }
        if defaults.object(forKey: "maxMaturingDropWeekly") != nil {
            maxMaturingDropWeekly = defaults.double(forKey: "maxMaturingDropWeekly")
        }
        if defaults.object(forKey: "maxMaturingDropMonthly") != nil {
            maxMaturingDropMonthly = defaults.double(forKey: "maxMaturingDropMonthly")
        }

        // Recession
        if defaults.object(forKey: "useRecession") != nil {
            useRecession = defaults.bool(forKey: "useRecession")
        }
        if defaults.object(forKey: "useRecessionWeekly") != nil {
            useRecessionWeekly = defaults.bool(forKey: "useRecessionWeekly")
        }
        if defaults.object(forKey: "useRecessionMonthly") != nil {
            useRecessionMonthly = defaults.bool(forKey: "useRecessionMonthly")
        }
        if defaults.object(forKey: "maxRecessionDropWeekly") != nil {
            maxRecessionDropWeekly = defaults.double(forKey: "maxRecessionDropWeekly")
        }
        if defaults.object(forKey: "maxRecessionDropMonthly") != nil {
            maxRecessionDropMonthly = defaults.double(forKey: "maxRecessionDropMonthly")
        }

        // Done loading from UserDefaults
        isUpdating = false
        
        finalizeToggleStateAfterLoad()
        
        isInitialized = true

        // Optional final sync to set toggleAll properly
        syncToggleAllState()
    }
    
    var inputManager: PersistentInputManager? = nil
    
    // @AppStorage("useLognormalGrowth") var useLognormalGrowth: Bool = true

    // MARK: - Weekly vs. Monthly
    /// The user’s chosen period unit (weeks or months)
    @Published var periodUnit: PeriodUnit = .weeks
    
    /// The total number of periods, e.g. 1040 for weeks, 240 for months
    @Published var userPeriods: Int = 52

    @Published var initialBTCPriceUSD: Double = 58000.0

    // Onboarding
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0

    // CHANGED: Add a currencyPreference
    @Published var currencyPreference: PreferredCurrency = .eur {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(currencyPreference.rawValue, forKey: "currencyPreference")
            }
        }
    }

    @Published var contributionCurrencyWhenBoth: PreferredCurrency = .eur
    @Published var startingBalanceCurrencyWhenBoth: PreferredCurrency = .usd

    // Results
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    var isInitialized = false
    var isUpdating = false

    @Published var toggleAll = false {
        didSet {
            // Only proceed if fully initialized
            guard isInitialized else { return }
            // Only proceed if it actually changed
            guard oldValue != toggleAll else { return }
                
            // If we’re not in a bulk update:
            if !isUpdating {
                isUpdating = true

                // If toggling all ON:
                if toggleAll {
                    // Turn ON all factors
                    useHalving = true
                    useHalvingWeekly = true
                    useHalvingMonthly = true

                    useInstitutionalDemand = true
                    useInstitutionalDemandWeekly = true
                    useInstitutionalDemandMonthly = true

                    useCountryAdoption = true
                    useCountryAdoptionWeekly = true
                    useCountryAdoptionMonthly = true

                    useRegulatoryClarity = true
                    useRegulatoryClarityWeekly = true
                    useRegulatoryClarityMonthly = true

                    useEtfApproval = true
                    useEtfApprovalWeekly = true
                    useEtfApprovalMonthly = true

                    useTechBreakthrough = true
                    useTechBreakthroughWeekly = true
                    useTechBreakthroughMonthly = true

                    useScarcityEvents = true
                    useScarcityEventsWeekly = true
                    useScarcityEventsMonthly = true

                    useGlobalMacroHedge = true
                    useGlobalMacroHedgeWeekly = true
                    useGlobalMacroHedgeMonthly = true

                    useStablecoinShift = true
                    useStablecoinShiftWeekly = true
                    useStablecoinShiftMonthly = true

                    useDemographicAdoption = true
                    useDemographicAdoptionWeekly = true
                    useDemographicAdoptionMonthly = true

                    useAltcoinFlight = true
                    useAltcoinFlightWeekly = true
                    useAltcoinFlightMonthly = true

                    useAdoptionFactor = true
                    useAdoptionFactorWeekly = true
                    useAdoptionFactorMonthly = true

                    useRegClampdown = true
                    useRegClampdownWeekly = true
                    useRegClampdownMonthly = true

                    useCompetitorCoin = true
                    useCompetitorCoinWeekly = true
                    useCompetitorCoinMonthly = true

                    useSecurityBreach = true
                    useSecurityBreachWeekly = true
                    useSecurityBreachMonthly = true

                    useBubblePop = true
                    useBubblePopWeekly = true
                    useBubblePopMonthly = true

                    useStablecoinMeltdown = true
                    useStablecoinMeltdownWeekly = true
                    useStablecoinMeltdownMonthly = true

                    useBlackSwan = true
                    useBlackSwanWeekly = true
                    useBlackSwanMonthly = true

                    useBearMarket = true
                    useBearMarketWeekly = true
                    useBearMarketMonthly = true

                    useMaturingMarket = true
                    useMaturingMarketWeekly = true
                    useMaturingMarketMonthly = true

                    useRecession = true
                    useRecessionWeekly = true
                    useRecessionMonthly = true
                    
                } else if userIsActuallyTogglingAll {
                    // Only turn everything OFF if the user explicitly toggled from on->off
                    useHalving = false
                    useHalvingWeekly = false
                    useHalvingMonthly = false

                    useInstitutionalDemand = false
                    useInstitutionalDemandWeekly = false
                    useInstitutionalDemandMonthly = false

                    useCountryAdoption = false
                    useCountryAdoptionWeekly = false
                    useCountryAdoptionMonthly = false

                    useRegulatoryClarity = false
                    useRegulatoryClarityWeekly = false
                    useRegulatoryClarityMonthly = false

                    useEtfApproval = false
                    useEtfApprovalWeekly = false
                    useEtfApprovalMonthly = false

                    useTechBreakthrough = false
                    useTechBreakthroughWeekly = false
                    useTechBreakthroughMonthly = false

                    useScarcityEvents = false
                    useScarcityEventsWeekly = false
                    useScarcityEventsMonthly = false

                    useGlobalMacroHedge = false
                    useGlobalMacroHedgeWeekly = false
                    useGlobalMacroHedgeMonthly = false

                    useStablecoinShift = false
                    useStablecoinShiftWeekly = false
                    useStablecoinShiftMonthly = false

                    useDemographicAdoption = false
                    useDemographicAdoptionWeekly = false
                    useDemographicAdoptionMonthly = false

                    useAltcoinFlight = false
                    useAltcoinFlightWeekly = false
                    useAltcoinFlightMonthly = false

                    useAdoptionFactor = false
                    useAdoptionFactorWeekly = false
                    useAdoptionFactorMonthly = false

                    useRegClampdown = false
                    useRegClampdownWeekly = false
                    useRegClampdownMonthly = false

                    useCompetitorCoin = false
                    useCompetitorCoinWeekly = false
                    useCompetitorCoinMonthly = false

                    useSecurityBreach = false
                    useSecurityBreachWeekly = false
                    useSecurityBreachMonthly = false

                    useBubblePop = false
                    useBubblePopWeekly = false
                    useBubblePopMonthly = false

                    useStablecoinMeltdown = false
                    useStablecoinMeltdownWeekly = false
                    useStablecoinMeltdownMonthly = false

                    useBlackSwan = false
                    useBlackSwanWeekly = false
                    useBlackSwanMonthly = false

                    useBearMarket = false
                    useBearMarketWeekly = false
                    useBearMarketMonthly = false

                    useMaturingMarket = false
                    useMaturingMarketWeekly = false
                    useMaturingMarketMonthly = false

                    useRecession = false
                    useRecessionWeekly = false
                    useRecessionMonthly = false
                }

                // We reset the flag now that we've handled the user toggle
                userIsActuallyTogglingAll = false

                // End the bulk update
                isUpdating = false

                // Optionally do one final sync
                syncToggleAllState()
            }
        }
    }

    func syncToggleAllState() {

        // If we're in the middle of changing multiple toggles at once, skip
        guard !isUpdating else {
            return
        }

        // Check if ALL factors (including weekly/monthly variants) are on
        let allFactorsEnabled =
            (useHalving && useHalvingWeekly && useHalvingMonthly) &&
            (useInstitutionalDemand && useInstitutionalDemandWeekly && useInstitutionalDemandMonthly) &&
            (useCountryAdoption && useCountryAdoptionWeekly && useCountryAdoptionMonthly) &&
            (useRegulatoryClarity && useRegulatoryClarityWeekly && useRegulatoryClarityMonthly) &&
            (useEtfApproval && useEtfApprovalWeekly && useEtfApprovalMonthly) &&
            (useTechBreakthrough && useTechBreakthroughWeekly && useTechBreakthroughMonthly) &&
            (useScarcityEvents && useScarcityEventsWeekly && useScarcityEventsMonthly) &&
            (useGlobalMacroHedge && useGlobalMacroHedgeWeekly && useGlobalMacroHedgeMonthly) &&
            (useStablecoinShift && useStablecoinShiftWeekly && useStablecoinShiftMonthly) &&
            (useDemographicAdoption && useDemographicAdoptionWeekly && useDemographicAdoptionMonthly) &&
            (useAltcoinFlight && useAltcoinFlightWeekly && useAltcoinFlightMonthly) &&
            (useAdoptionFactor && useAdoptionFactorWeekly && useAdoptionFactorMonthly) &&
            (useRegClampdown && useRegClampdownWeekly && useRegClampdownMonthly) &&
            (useCompetitorCoin && useCompetitorCoinWeekly && useCompetitorCoinMonthly) &&
            (useSecurityBreach && useSecurityBreachWeekly && useSecurityBreachMonthly) &&
            (useBubblePop && useBubblePopWeekly && useBubblePopMonthly) &&
            (useStablecoinMeltdown && useStablecoinMeltdownWeekly && useStablecoinMeltdownMonthly) &&
            (useBlackSwan && useBlackSwanWeekly && useBlackSwanMonthly) &&
            (useBearMarket && useBearMarketWeekly && useBearMarketMonthly) &&
            (useMaturingMarket && useMaturingMarketWeekly && useMaturingMarketMonthly) &&
            (useRecession && useRecessionWeekly && useRecessionMonthly)

        // If toggleAll is out of sync, fix it without triggering a full bulk flip
        if toggleAll != allFactorsEnabled {
            isUpdating = true
            toggleAll = allFactorsEnabled
            isUpdating = false
        } else {
            // print(">> syncToggleAllState() no mismatch => nothing changed")
        }
    }

    @Published var useLognormalGrowth: Bool = true {
        didSet {
            UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        }
    }

    // Random Seed
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
            }
        }
    }
    @Published var seedValue: UInt64 = 0 {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(seedValue, forKey: "seedValue")
            }
        }
    }
    @Published var useRandomSeed: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
            }
        }
    }
    @Published var useHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
            }
        }
    }

    @Published var useVolShocks: Bool = true {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
            }
        }
    }
    @Published var lastUsedSeed: UInt64 = 0

    // -----------------------------
    // MARK: - BULLISH FACTORS
    // -----------------------------

    // Halving
    @Published var useHalving: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useHalving else { return }

            UserDefaults.standard.set(useHalving, forKey: "useHalving")
            
            if useHalving {
                // Turn children on
                useHalvingWeekly = true
                UserDefaults.standard.set(true, forKey: "useHalvingWeekly")
                useHalvingMonthly = true
                UserDefaults.standard.set(true, forKey: "useHalvingMonthly")
            } else {
                // Turn children off
                useHalvingWeekly = false
                UserDefaults.standard.set(false, forKey: "useHalvingWeekly")
                useHalvingMonthly = false
                UserDefaults.standard.set(false, forKey: "useHalvingMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useHalvingWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useHalvingWeekly {
                UserDefaults.standard.set(useHalvingWeekly, forKey: "useHalvingWeekly")
                
                if useHalvingWeekly {
                    useHalving = true
                } else if !useHalvingMonthly {
                    useHalving = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var halvingBumpWeekly: Double = SimulationSettings.defaultHalvingBumpWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpWeekly {
                UserDefaults.standard.set(halvingBumpWeekly, forKey: "halvingBumpWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useHalvingMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useHalvingMonthly {
                UserDefaults.standard.set(useHalvingMonthly, forKey: "useHalvingMonthly")
                
                if useHalvingMonthly {
                    useHalving = true
                } else if !useHalvingWeekly {
                    useHalving = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var halvingBumpMonthly: Double = SimulationSettings.defaultHalvingBumpMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != halvingBumpMonthly {
                UserDefaults.standard.set(halvingBumpMonthly, forKey: "halvingBumpMonthly")
            }
        }
    }


    // Institutional Demand
    @Published var useInstitutionalDemand: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useInstitutionalDemand else { return }

            UserDefaults.standard.set(useInstitutionalDemand, forKey: "useInstitutionalDemand")
            
            if useInstitutionalDemand {
                useInstitutionalDemandWeekly = true
                UserDefaults.standard.set(true, forKey: "useInstitutionalDemandWeekly")
                useInstitutionalDemandMonthly = true
                UserDefaults.standard.set(true, forKey: "useInstitutionalDemandMonthly")
            } else {
                useInstitutionalDemandWeekly = false
                UserDefaults.standard.set(false, forKey: "useInstitutionalDemandWeekly")
                useInstitutionalDemandMonthly = false
                UserDefaults.standard.set(false, forKey: "useInstitutionalDemandMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useInstitutionalDemandWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useInstitutionalDemandWeekly {
                UserDefaults.standard.set(useInstitutionalDemandWeekly, forKey: "useInstitutionalDemandWeekly")
                
                if useInstitutionalDemandWeekly {
                    useInstitutionalDemand = true
                } else if !useInstitutionalDemandMonthly {
                    useInstitutionalDemand = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxDemandBoostWeekly: Double = SimulationSettings.defaultMaxDemandBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostWeekly {
                UserDefaults.standard.set(maxDemandBoostWeekly, forKey: "maxDemandBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useInstitutionalDemandMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useInstitutionalDemandMonthly {
                UserDefaults.standard.set(useInstitutionalDemandMonthly, forKey: "useInstitutionalDemandMonthly")
                
                if useInstitutionalDemandMonthly {
                    useInstitutionalDemand = true
                } else if !useInstitutionalDemandWeekly {
                    useInstitutionalDemand = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxDemandBoostMonthly: Double = SimulationSettings.defaultMaxDemandBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemandBoostMonthly {
                UserDefaults.standard.set(maxDemandBoostMonthly, forKey: "maxDemandBoostMonthly")
            }
        }
    }


    // Country Adoption
    @Published var useCountryAdoption: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useCountryAdoption else { return }

            UserDefaults.standard.set(useCountryAdoption, forKey: "useCountryAdoption")

            if useCountryAdoption {
                useCountryAdoptionWeekly = true
                UserDefaults.standard.set(true, forKey: "useCountryAdoptionWeekly")
                useCountryAdoptionMonthly = true
                UserDefaults.standard.set(true, forKey: "useCountryAdoptionMonthly")
            } else {
                useCountryAdoptionWeekly = false
                UserDefaults.standard.set(false, forKey: "useCountryAdoptionWeekly")
                useCountryAdoptionMonthly = false
                UserDefaults.standard.set(false, forKey: "useCountryAdoptionMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useCountryAdoptionWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useCountryAdoptionWeekly {
                UserDefaults.standard.set(useCountryAdoptionWeekly, forKey: "useCountryAdoptionWeekly")
                
                if useCountryAdoptionWeekly {
                    useCountryAdoption = true
                } else if !useCountryAdoptionMonthly {
                    useCountryAdoption = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxCountryAdBoostWeekly: Double = SimulationSettings.defaultMaxCountryAdBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostWeekly {
                UserDefaults.standard.set(maxCountryAdBoostWeekly, forKey: "maxCountryAdBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useCountryAdoptionMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useCountryAdoptionMonthly {
                UserDefaults.standard.set(useCountryAdoptionMonthly, forKey: "useCountryAdoptionMonthly")
                
                if useCountryAdoptionMonthly {
                    useCountryAdoption = true
                } else if !useCountryAdoptionWeekly {
                    useCountryAdoption = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxCountryAdBoostMonthly: Double = SimulationSettings.defaultMaxCountryAdBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCountryAdBoostMonthly {
                UserDefaults.standard.set(maxCountryAdBoostMonthly, forKey: "maxCountryAdBoostMonthly")
            }
        }
    }


    // Regulatory Clarity
    @Published var useRegulatoryClarity: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useRegulatoryClarity else { return }

            UserDefaults.standard.set(useRegulatoryClarity, forKey: "useRegulatoryClarity")
            
            if useRegulatoryClarity {
                useRegulatoryClarityWeekly = true
                UserDefaults.standard.set(true, forKey: "useRegulatoryClarityWeekly")
                useRegulatoryClarityMonthly = true
                UserDefaults.standard.set(true, forKey: "useRegulatoryClarityMonthly")
            } else {
                useRegulatoryClarityWeekly = false
                UserDefaults.standard.set(false, forKey: "useRegulatoryClarityWeekly")
                useRegulatoryClarityMonthly = false
                UserDefaults.standard.set(false, forKey: "useRegulatoryClarityMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useRegulatoryClarityWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRegulatoryClarityWeekly {
                UserDefaults.standard.set(useRegulatoryClarityWeekly, forKey: "useRegulatoryClarityWeekly")
                
                if useRegulatoryClarityWeekly {
                    useRegulatoryClarity = true
                } else if !useRegulatoryClarityMonthly {
                    useRegulatoryClarity = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxClarityBoostWeekly: Double = SimulationSettings.defaultMaxClarityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostWeekly {
                UserDefaults.standard.set(maxClarityBoostWeekly, forKey: "maxClarityBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useRegulatoryClarityMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRegulatoryClarityMonthly {
                UserDefaults.standard.set(useRegulatoryClarityMonthly, forKey: "useRegulatoryClarityMonthly")
                
                if useRegulatoryClarityMonthly {
                    useRegulatoryClarity = true
                } else if !useRegulatoryClarityWeekly {
                    useRegulatoryClarity = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxClarityBoostMonthly: Double = SimulationSettings.defaultMaxClarityBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClarityBoostMonthly {
                UserDefaults.standard.set(maxClarityBoostMonthly, forKey: "maxClarityBoostMonthly")
            }
        }
    }


    // ETF Approval
    @Published var useEtfApproval: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useEtfApproval else { return }

            UserDefaults.standard.set(useEtfApproval, forKey: "useEtfApproval")
            
            if useEtfApproval {
                useEtfApprovalWeekly = true
                UserDefaults.standard.set(true, forKey: "useEtfApprovalWeekly")
                useEtfApprovalMonthly = true
                UserDefaults.standard.set(true, forKey: "useEtfApprovalMonthly")
            } else {
                useEtfApprovalWeekly = false
                UserDefaults.standard.set(false, forKey: "useEtfApprovalWeekly")
                useEtfApprovalMonthly = false
                UserDefaults.standard.set(false, forKey: "useEtfApprovalMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useEtfApprovalWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useEtfApprovalWeekly {
                UserDefaults.standard.set(useEtfApprovalWeekly, forKey: "useEtfApprovalWeekly")
                
                if useEtfApprovalWeekly {
                    useEtfApproval = true
                } else if !useEtfApprovalMonthly {
                    useEtfApproval = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxEtfBoostWeekly: Double = SimulationSettings.defaultMaxEtfBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostWeekly {
                UserDefaults.standard.set(maxEtfBoostWeekly, forKey: "maxEtfBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useEtfApprovalMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useEtfApprovalMonthly {
                UserDefaults.standard.set(useEtfApprovalMonthly, forKey: "useEtfApprovalMonthly")
                
                if useEtfApprovalMonthly {
                    useEtfApproval = true
                } else if !useEtfApprovalWeekly {
                    useEtfApproval = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxEtfBoostMonthly: Double = SimulationSettings.defaultMaxEtfBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxEtfBoostMonthly {
                UserDefaults.standard.set(maxEtfBoostMonthly, forKey: "maxEtfBoostMonthly")
            }
        }
    }


    // Tech Breakthrough
    @Published var useTechBreakthrough: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useTechBreakthrough else { return }

            UserDefaults.standard.set(useTechBreakthrough, forKey: "useTechBreakthrough")
            
            if useTechBreakthrough {
                useTechBreakthroughWeekly = true
                UserDefaults.standard.set(true, forKey: "useTechBreakthroughWeekly")
                useTechBreakthroughMonthly = true
                UserDefaults.standard.set(true, forKey: "useTechBreakthroughMonthly")
            } else {
                useTechBreakthroughWeekly = false
                UserDefaults.standard.set(false, forKey: "useTechBreakthroughWeekly")
                useTechBreakthroughMonthly = false
                UserDefaults.standard.set(false, forKey: "useTechBreakthroughMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useTechBreakthroughWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useTechBreakthroughWeekly {
                UserDefaults.standard.set(useTechBreakthroughWeekly, forKey: "useTechBreakthroughWeekly")
                
                if useTechBreakthroughWeekly {
                    useTechBreakthrough = true
                } else if !useTechBreakthroughMonthly {
                    useTechBreakthrough = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxTechBoostWeekly: Double = SimulationSettings.defaultMaxTechBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostWeekly {
                UserDefaults.standard.set(maxTechBoostWeekly, forKey: "maxTechBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useTechBreakthroughMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useTechBreakthroughMonthly {
                UserDefaults.standard.set(useTechBreakthroughMonthly, forKey: "useTechBreakthroughMonthly")
                
                if useTechBreakthroughMonthly {
                    useTechBreakthrough = true
                } else if !useTechBreakthroughWeekly {
                    useTechBreakthrough = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxTechBoostMonthly: Double = SimulationSettings.defaultMaxTechBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxTechBoostMonthly {
                UserDefaults.standard.set(maxTechBoostMonthly, forKey: "maxTechBoostMonthly")
            }
        }
    }


    // Scarcity Events
    @Published var useScarcityEvents: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useScarcityEvents else { return }

            UserDefaults.standard.set(useScarcityEvents, forKey: "useScarcityEvents")
            
            if useScarcityEvents {
                useScarcityEventsWeekly = true
                UserDefaults.standard.set(true, forKey: "useScarcityEventsWeekly")
                useScarcityEventsMonthly = true
                UserDefaults.standard.set(true, forKey: "useScarcityEventsMonthly")
            } else {
                useScarcityEventsWeekly = false
                UserDefaults.standard.set(false, forKey: "useScarcityEventsWeekly")
                useScarcityEventsMonthly = false
                UserDefaults.standard.set(false, forKey: "useScarcityEventsMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useScarcityEventsWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useScarcityEventsWeekly {
                UserDefaults.standard.set(useScarcityEventsWeekly, forKey: "useScarcityEventsWeekly")
                
                if useScarcityEventsWeekly {
                    useScarcityEvents = true
                } else if !useScarcityEventsMonthly {
                    useScarcityEvents = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxScarcityBoostWeekly: Double = SimulationSettings.defaultMaxScarcityBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostWeekly {
                UserDefaults.standard.set(maxScarcityBoostWeekly, forKey: "maxScarcityBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useScarcityEventsMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useScarcityEventsMonthly {
                UserDefaults.standard.set(useScarcityEventsMonthly, forKey: "useScarcityEventsMonthly")
                
                if useScarcityEventsMonthly {
                    useScarcityEvents = true
                } else if !useScarcityEventsWeekly {
                    useScarcityEvents = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxScarcityBoostMonthly: Double = SimulationSettings.defaultMaxScarcityBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxScarcityBoostMonthly {
                UserDefaults.standard.set(maxScarcityBoostMonthly, forKey: "maxScarcityBoostMonthly")
            }
        }
    }


    // Global Macro Hedge
    @Published var useGlobalMacroHedge: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useGlobalMacroHedge else { return }

            UserDefaults.standard.set(useGlobalMacroHedge, forKey: "useGlobalMacroHedge")
            
            if useGlobalMacroHedge {
                useGlobalMacroHedgeWeekly = true
                UserDefaults.standard.set(true, forKey: "useGlobalMacroHedgeWeekly")
                useGlobalMacroHedgeMonthly = true
                UserDefaults.standard.set(true, forKey: "useGlobalMacroHedgeMonthly")
            } else {
                useGlobalMacroHedgeWeekly = false
                UserDefaults.standard.set(false, forKey: "useGlobalMacroHedgeWeekly")
                useGlobalMacroHedgeMonthly = false
                UserDefaults.standard.set(false, forKey: "useGlobalMacroHedgeMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useGlobalMacroHedgeWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useGlobalMacroHedgeWeekly {
                UserDefaults.standard.set(useGlobalMacroHedgeWeekly, forKey: "useGlobalMacroHedgeWeekly")
                
                if useGlobalMacroHedgeWeekly {
                    useGlobalMacroHedge = true
                } else if !useGlobalMacroHedgeMonthly {
                    useGlobalMacroHedge = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxMacroBoostWeekly: Double = SimulationSettings.defaultMaxMacroBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostWeekly {
                UserDefaults.standard.set(maxMacroBoostWeekly, forKey: "maxMacroBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useGlobalMacroHedgeMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useGlobalMacroHedgeMonthly {
                UserDefaults.standard.set(useGlobalMacroHedgeMonthly, forKey: "useGlobalMacroHedgeMonthly")
                
                if useGlobalMacroHedgeMonthly {
                    useGlobalMacroHedge = true
                } else if !useGlobalMacroHedgeWeekly {
                    useGlobalMacroHedge = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxMacroBoostMonthly: Double = SimulationSettings.defaultMaxMacroBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMacroBoostMonthly {
                UserDefaults.standard.set(maxMacroBoostMonthly, forKey: "maxMacroBoostMonthly")
            }
        }
    }


    // Stablecoin Shift
    @Published var useStablecoinShift: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useStablecoinShift else { return }

            UserDefaults.standard.set(useStablecoinShift, forKey: "useStablecoinShift")
            
            if useStablecoinShift {
                useStablecoinShiftWeekly = true
                UserDefaults.standard.set(true, forKey: "useStablecoinShiftWeekly")
                useStablecoinShiftMonthly = true
                UserDefaults.standard.set(true, forKey: "useStablecoinShiftMonthly")
            } else {
                useStablecoinShiftWeekly = false
                UserDefaults.standard.set(false, forKey: "useStablecoinShiftWeekly")
                useStablecoinShiftMonthly = false
                UserDefaults.standard.set(false, forKey: "useStablecoinShiftMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useStablecoinShiftWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useStablecoinShiftWeekly {
                UserDefaults.standard.set(useStablecoinShiftWeekly, forKey: "useStablecoinShiftWeekly")
                
                if useStablecoinShiftWeekly {
                    useStablecoinShift = true
                } else if !useStablecoinShiftMonthly {
                    useStablecoinShift = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxStablecoinBoostWeekly: Double = SimulationSettings.defaultMaxStablecoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostWeekly {
                UserDefaults.standard.set(maxStablecoinBoostWeekly, forKey: "maxStablecoinBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useStablecoinShiftMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useStablecoinShiftMonthly {
                UserDefaults.standard.set(useStablecoinShiftMonthly, forKey: "useStablecoinShiftMonthly")
                
                if useStablecoinShiftMonthly {
                    useStablecoinShift = true
                } else if !useStablecoinShiftWeekly {
                    useStablecoinShift = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxStablecoinBoostMonthly: Double = SimulationSettings.defaultMaxStablecoinBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxStablecoinBoostMonthly {
                UserDefaults.standard.set(maxStablecoinBoostMonthly, forKey: "maxStablecoinBoostMonthly")
            }
        }
    }


    // Demographic Adoption
    @Published var useDemographicAdoption: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useDemographicAdoption else { return }

            UserDefaults.standard.set(useDemographicAdoption, forKey: "useDemographicAdoption")
            
            if useDemographicAdoption {
                useDemographicAdoptionWeekly = true
                UserDefaults.standard.set(true, forKey: "useDemographicAdoptionWeekly")
                useDemographicAdoptionMonthly = true
                UserDefaults.standard.set(true, forKey: "useDemographicAdoptionMonthly")
            } else {
                useDemographicAdoptionWeekly = false
                UserDefaults.standard.set(false, forKey: "useDemographicAdoptionWeekly")
                useDemographicAdoptionMonthly = false
                UserDefaults.standard.set(false, forKey: "useDemographicAdoptionMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useDemographicAdoptionWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useDemographicAdoptionWeekly {
                UserDefaults.standard.set(useDemographicAdoptionWeekly, forKey: "useDemographicAdoptionWeekly")
                
                if useDemographicAdoptionWeekly {
                    useDemographicAdoption = true
                } else if !useDemographicAdoptionMonthly {
                    useDemographicAdoption = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxDemoBoostWeekly: Double = SimulationSettings.defaultMaxDemoBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostWeekly {
                UserDefaults.standard.set(maxDemoBoostWeekly, forKey: "maxDemoBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useDemographicAdoptionMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useDemographicAdoptionMonthly {
                UserDefaults.standard.set(useDemographicAdoptionMonthly, forKey: "useDemographicAdoptionMonthly")
                
                if useDemographicAdoptionMonthly {
                    useDemographicAdoption = true
                } else if !useDemographicAdoptionWeekly {
                    useDemographicAdoption = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxDemoBoostMonthly: Double = SimulationSettings.defaultMaxDemoBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxDemoBoostMonthly {
                UserDefaults.standard.set(maxDemoBoostMonthly, forKey: "maxDemoBoostMonthly")
            }
        }
    }


    // Altcoin Flight
    @Published var useAltcoinFlight: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useAltcoinFlight else { return }

            UserDefaults.standard.set(useAltcoinFlight, forKey: "useAltcoinFlight")
            
            if useAltcoinFlight {
                useAltcoinFlightWeekly = true
                UserDefaults.standard.set(true, forKey: "useAltcoinFlightWeekly")
                useAltcoinFlightMonthly = true
                UserDefaults.standard.set(true, forKey: "useAltcoinFlightMonthly")
            } else {
                useAltcoinFlightWeekly = false
                UserDefaults.standard.set(false, forKey: "useAltcoinFlightWeekly")
                useAltcoinFlightMonthly = false
                UserDefaults.standard.set(false, forKey: "useAltcoinFlightMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useAltcoinFlightWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAltcoinFlightWeekly {
                UserDefaults.standard.set(useAltcoinFlightWeekly, forKey: "useAltcoinFlightWeekly")
                
                if useAltcoinFlightWeekly {
                    useAltcoinFlight = true
                } else if !useAltcoinFlightMonthly {
                    useAltcoinFlight = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxAltcoinBoostWeekly: Double = SimulationSettings.defaultMaxAltcoinBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostWeekly {
                UserDefaults.standard.set(maxAltcoinBoostWeekly, forKey: "maxAltcoinBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useAltcoinFlightMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAltcoinFlightMonthly {
                UserDefaults.standard.set(useAltcoinFlightMonthly, forKey: "useAltcoinFlightMonthly")
                
                if useAltcoinFlightMonthly {
                    useAltcoinFlight = true
                } else if !useAltcoinFlightWeekly {
                    useAltcoinFlight = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxAltcoinBoostMonthly: Double = SimulationSettings.defaultMaxAltcoinBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxAltcoinBoostMonthly {
                UserDefaults.standard.set(maxAltcoinBoostMonthly, forKey: "maxAltcoinBoostMonthly")
            }
        }
    }


    // Adoption Factor
    @Published var useAdoptionFactor: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useAdoptionFactor else { return }

            UserDefaults.standard.set(useAdoptionFactor, forKey: "useAdoptionFactor")
            
            if useAdoptionFactor {
                useAdoptionFactorWeekly = true
                UserDefaults.standard.set(true, forKey: "useAdoptionFactorWeekly")
                useAdoptionFactorMonthly = true
                UserDefaults.standard.set(true, forKey: "useAdoptionFactorMonthly")
            } else {
                useAdoptionFactorWeekly = false
                UserDefaults.standard.set(false, forKey: "useAdoptionFactorWeekly")
                useAdoptionFactorMonthly = false
                UserDefaults.standard.set(false, forKey: "useAdoptionFactorMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useAdoptionFactorWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAdoptionFactorWeekly {
                UserDefaults.standard.set(useAdoptionFactorWeekly, forKey: "useAdoptionFactorWeekly")
                
                if useAdoptionFactorWeekly {
                    useAdoptionFactor = true
                } else if !useAdoptionFactorMonthly {
                    useAdoptionFactor = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var adoptionBaseFactorWeekly: Double = SimulationSettings.defaultAdoptionBaseFactorWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorWeekly {
                UserDefaults.standard.set(adoptionBaseFactorWeekly, forKey: "adoptionBaseFactorWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useAdoptionFactorMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useAdoptionFactorMonthly {
                UserDefaults.standard.set(useAdoptionFactorMonthly, forKey: "useAdoptionFactorMonthly")
                
                if useAdoptionFactorMonthly {
                    useAdoptionFactor = true
                } else if !useAdoptionFactorWeekly {
                    useAdoptionFactor = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var adoptionBaseFactorMonthly: Double = SimulationSettings.defaultAdoptionBaseFactorMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != adoptionBaseFactorMonthly {
                UserDefaults.standard.set(adoptionBaseFactorMonthly, forKey: "adoptionBaseFactorMonthly")
            }
        }
    }
    
    // -----------------------------
    // MARK: - BEARISH FACTORS
    // -----------------------------

    // Regulatory Clampdown
    @Published var useRegClampdown: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useRegClampdown else { return }

            UserDefaults.standard.set(useRegClampdown, forKey: "useRegClampdown")

            if useRegClampdown {
                useRegClampdownWeekly = true
                UserDefaults.standard.set(true, forKey: "useRegClampdownWeekly")
                useRegClampdownMonthly = true
                UserDefaults.standard.set(true, forKey: "useRegClampdownMonthly")
            } else {
                useRegClampdownWeekly = false
                UserDefaults.standard.set(false, forKey: "useRegClampdownWeekly")
                useRegClampdownMonthly = false
                UserDefaults.standard.set(false, forKey: "useRegClampdownMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useRegClampdownWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRegClampdownWeekly {
                UserDefaults.standard.set(useRegClampdownWeekly, forKey: "useRegClampdownWeekly")
                
                if useRegClampdownWeekly {
                    useRegClampdown = true
                } else if !useRegClampdownMonthly {
                    useRegClampdown = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxClampDownWeekly: Double = SimulationSettings.defaultMaxClampDownWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClampDownWeekly {
                UserDefaults.standard.set(maxClampDownWeekly, forKey: "maxClampDownWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useRegClampdownMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRegClampdownMonthly {
                UserDefaults.standard.set(useRegClampdownMonthly, forKey: "useRegClampdownMonthly")
                
                if useRegClampdownMonthly {
                    useRegClampdown = true
                } else if !useRegClampdownWeekly {
                    useRegClampdown = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxClampDownMonthly: Double = SimulationSettings.defaultMaxClampDownMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxClampDownMonthly {
                UserDefaults.standard.set(maxClampDownMonthly, forKey: "maxClampDownMonthly")
            }
        }
    }


    // Competitor Coin
    @Published var useCompetitorCoin: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useCompetitorCoin else { return }

            UserDefaults.standard.set(useCompetitorCoin, forKey: "useCompetitorCoin")

            if useCompetitorCoin {
                useCompetitorCoinWeekly = true
                UserDefaults.standard.set(true, forKey: "useCompetitorCoinWeekly")
                useCompetitorCoinMonthly = true
                UserDefaults.standard.set(true, forKey: "useCompetitorCoinMonthly")
            } else {
                useCompetitorCoinWeekly = false
                UserDefaults.standard.set(false, forKey: "useCompetitorCoinWeekly")
                useCompetitorCoinMonthly = false
                UserDefaults.standard.set(false, forKey: "useCompetitorCoinMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useCompetitorCoinWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useCompetitorCoinWeekly {
                UserDefaults.standard.set(useCompetitorCoinWeekly, forKey: "useCompetitorCoinWeekly")
                
                if useCompetitorCoinWeekly {
                    useCompetitorCoin = true
                } else if !useCompetitorCoinMonthly {
                    useCompetitorCoin = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxCompetitorBoostWeekly: Double = SimulationSettings.defaultMaxCompetitorBoostWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostWeekly {
                UserDefaults.standard.set(maxCompetitorBoostWeekly, forKey: "maxCompetitorBoostWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useCompetitorCoinMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useCompetitorCoinMonthly {
                UserDefaults.standard.set(useCompetitorCoinMonthly, forKey: "useCompetitorCoinMonthly")
                
                if useCompetitorCoinMonthly {
                    useCompetitorCoin = true
                } else if !useCompetitorCoinWeekly {
                    useCompetitorCoin = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxCompetitorBoostMonthly: Double = SimulationSettings.defaultMaxCompetitorBoostMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxCompetitorBoostMonthly {
                UserDefaults.standard.set(maxCompetitorBoostMonthly, forKey: "maxCompetitorBoostMonthly")
            }
        }
    }


    // Security Breach
    @Published var useSecurityBreach: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useSecurityBreach else { return }

            UserDefaults.standard.set(useSecurityBreach, forKey: "useSecurityBreach")
            
            if useSecurityBreach {
                useSecurityBreachWeekly = true
                UserDefaults.standard.set(true, forKey: "useSecurityBreachWeekly")
                useSecurityBreachMonthly = true
                UserDefaults.standard.set(true, forKey: "useSecurityBreachMonthly")
            } else {
                useSecurityBreachWeekly = false
                UserDefaults.standard.set(false, forKey: "useSecurityBreachWeekly")
                useSecurityBreachMonthly = false
                UserDefaults.standard.set(false, forKey: "useSecurityBreachMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useSecurityBreachWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useSecurityBreachWeekly {
                UserDefaults.standard.set(useSecurityBreachWeekly, forKey: "useSecurityBreachWeekly")
                
                if useSecurityBreachWeekly {
                    useSecurityBreach = true
                } else if !useSecurityBreachMonthly {
                    useSecurityBreach = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var breachImpactWeekly: Double = SimulationSettings.defaultBreachImpactWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != breachImpactWeekly {
                UserDefaults.standard.set(breachImpactWeekly, forKey: "breachImpactWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useSecurityBreachMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useSecurityBreachMonthly {
                UserDefaults.standard.set(useSecurityBreachMonthly, forKey: "useSecurityBreachMonthly")
                
                if useSecurityBreachMonthly {
                    useSecurityBreach = true
                } else if !useSecurityBreachWeekly {
                    useSecurityBreach = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var breachImpactMonthly: Double = SimulationSettings.defaultBreachImpactMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != breachImpactMonthly {
                UserDefaults.standard.set(breachImpactMonthly, forKey: "breachImpactMonthly")
            }
        }
    }


    // Bubble Pop
    @Published var useBubblePop: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useBubblePop else { return }

            UserDefaults.standard.set(useBubblePop, forKey: "useBubblePop")
            
            if useBubblePop {
                useBubblePopWeekly = true
                UserDefaults.standard.set(true, forKey: "useBubblePopWeekly")
                useBubblePopMonthly = true
                UserDefaults.standard.set(true, forKey: "useBubblePopMonthly")
            } else {
                useBubblePopWeekly = false
                UserDefaults.standard.set(false, forKey: "useBubblePopWeekly")
                useBubblePopMonthly = false
                UserDefaults.standard.set(false, forKey: "useBubblePopMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useBubblePopWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useBubblePopWeekly {
                UserDefaults.standard.set(useBubblePopWeekly, forKey: "useBubblePopWeekly")
                
                if useBubblePopWeekly {
                    useBubblePop = true
                } else if !useBubblePopMonthly {
                    useBubblePop = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxPopDropWeekly: Double = SimulationSettings.defaultMaxPopDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxPopDropWeekly {
                UserDefaults.standard.set(maxPopDropWeekly, forKey: "maxPopDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useBubblePopMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useBubblePopMonthly {
                UserDefaults.standard.set(useBubblePopMonthly, forKey: "useBubblePopMonthly")
                
                if useBubblePopMonthly {
                    useBubblePop = true
                } else if !useBubblePopWeekly {
                    useBubblePop = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxPopDropMonthly: Double = SimulationSettings.defaultMaxPopDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxPopDropMonthly {
                UserDefaults.standard.set(maxPopDropMonthly, forKey: "maxPopDropMonthly")
            }
        }
    }


    // Stablecoin Meltdown
    @Published var useStablecoinMeltdown: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useStablecoinMeltdown else { return }

            UserDefaults.standard.set(useStablecoinMeltdown, forKey: "useStablecoinMeltdown")
            
            if useStablecoinMeltdown {
                useStablecoinMeltdownWeekly = true
                UserDefaults.standard.set(true, forKey: "useStablecoinMeltdownWeekly")
                useStablecoinMeltdownMonthly = true
                UserDefaults.standard.set(true, forKey: "useStablecoinMeltdownMonthly")
            } else {
                useStablecoinMeltdownWeekly = false
                UserDefaults.standard.set(false, forKey: "useStablecoinMeltdownWeekly")
                useStablecoinMeltdownMonthly = false
                UserDefaults.standard.set(false, forKey: "useStablecoinMeltdownMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useStablecoinMeltdownWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useStablecoinMeltdownWeekly {
                UserDefaults.standard.set(useStablecoinMeltdownWeekly, forKey: "useStablecoinMeltdownWeekly")
                
                if useStablecoinMeltdownWeekly {
                    useStablecoinMeltdown = true
                } else if !useStablecoinMeltdownMonthly {
                    useStablecoinMeltdown = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxMeltdownDropWeekly: Double = SimulationSettings.defaultMaxMeltdownDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropWeekly {
                UserDefaults.standard.set(maxMeltdownDropWeekly, forKey: "maxMeltdownDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useStablecoinMeltdownMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useStablecoinMeltdownMonthly {
                UserDefaults.standard.set(useStablecoinMeltdownMonthly, forKey: "useStablecoinMeltdownMonthly")
                
                if useStablecoinMeltdownMonthly {
                    useStablecoinMeltdown = true
                } else if !useStablecoinMeltdownWeekly {
                    useStablecoinMeltdown = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxMeltdownDropMonthly: Double = SimulationSettings.defaultMaxMeltdownDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMeltdownDropMonthly {
                UserDefaults.standard.set(maxMeltdownDropMonthly, forKey: "maxMeltdownDropMonthly")
            }
        }
    }


    // Black Swan
    @Published var useBlackSwan: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useBlackSwan else { return }

            UserDefaults.standard.set(useBlackSwan, forKey: "useBlackSwan")
            
            if useBlackSwan {
                useBlackSwanWeekly = true
                UserDefaults.standard.set(true, forKey: "useBlackSwanWeekly")
                useBlackSwanMonthly = true
                UserDefaults.standard.set(true, forKey: "useBlackSwanMonthly")
            } else {
                useBlackSwanWeekly = false
                UserDefaults.standard.set(false, forKey: "useBlackSwanWeekly")
                useBlackSwanMonthly = false
                UserDefaults.standard.set(false, forKey: "useBlackSwanMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useBlackSwanWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useBlackSwanWeekly {
                UserDefaults.standard.set(useBlackSwanWeekly, forKey: "useBlackSwanWeekly")
                
                if useBlackSwanWeekly {
                    useBlackSwan = true
                } else if !useBlackSwanMonthly {
                    useBlackSwan = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var blackSwanDropWeekly: Double = SimulationSettings.defaultBlackSwanDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != blackSwanDropWeekly {
                UserDefaults.standard.set(blackSwanDropWeekly, forKey: "blackSwanDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useBlackSwanMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useBlackSwanMonthly {
                UserDefaults.standard.set(useBlackSwanMonthly, forKey: "useBlackSwanMonthly")
                
                if useBlackSwanMonthly {
                    useBlackSwan = true
                } else if !useBlackSwanWeekly {
                    useBlackSwan = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var blackSwanDropMonthly: Double = SimulationSettings.defaultBlackSwanDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != blackSwanDropMonthly {
                UserDefaults.standard.set(blackSwanDropMonthly, forKey: "blackSwanDropMonthly")
            }
        }
    }


    // Bear Market
    @Published var useBearMarket: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useBearMarket else { return }

            UserDefaults.standard.set(useBearMarket, forKey: "useBearMarket")
            
            if useBearMarket {
                useBearMarketWeekly = true
                UserDefaults.standard.set(true, forKey: "useBearMarketWeekly")
                useBearMarketMonthly = true
                UserDefaults.standard.set(true, forKey: "useBearMarketMonthly")
            } else {
                useBearMarketWeekly = false
                UserDefaults.standard.set(false, forKey: "useBearMarketWeekly")
                useBearMarketMonthly = false
                UserDefaults.standard.set(false, forKey: "useBearMarketMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useBearMarketWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useBearMarketWeekly {
                UserDefaults.standard.set(useBearMarketWeekly, forKey: "useBearMarketWeekly")
                
                if useBearMarketWeekly {
                    useBearMarket = true
                } else if !useBearMarketMonthly {
                    useBearMarket = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var bearWeeklyDriftWeekly: Double = SimulationSettings.defaultBearWeeklyDriftWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftWeekly {
                UserDefaults.standard.set(bearWeeklyDriftWeekly, forKey: "bearWeeklyDriftWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useBearMarketMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useBearMarketMonthly {
                UserDefaults.standard.set(useBearMarketMonthly, forKey: "useBearMarketMonthly")
                
                if useBearMarketMonthly {
                    useBearMarket = true
                } else if !useBearMarketWeekly {
                    useBearMarket = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var bearWeeklyDriftMonthly: Double = SimulationSettings.defaultBearWeeklyDriftMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != bearWeeklyDriftMonthly {
                UserDefaults.standard.set(bearWeeklyDriftMonthly, forKey: "bearWeeklyDriftMonthly")
            }
        }
    }


    // Maturing Market
    @Published var useMaturingMarket: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useMaturingMarket else { return }

            UserDefaults.standard.set(useMaturingMarket, forKey: "useMaturingMarket")
            
            if useMaturingMarket {
                useMaturingMarketWeekly = true
                UserDefaults.standard.set(true, forKey: "useMaturingMarketWeekly")
                useMaturingMarketMonthly = true
                UserDefaults.standard.set(true, forKey: "useMaturingMarketMonthly")
            } else {
                useMaturingMarketWeekly = false
                UserDefaults.standard.set(false, forKey: "useMaturingMarketWeekly")
                useMaturingMarketMonthly = false
                UserDefaults.standard.set(false, forKey: "useMaturingMarketMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useMaturingMarketWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useMaturingMarketWeekly {
                UserDefaults.standard.set(useMaturingMarketWeekly, forKey: "useMaturingMarketWeekly")
                
                if useMaturingMarketWeekly {
                    useMaturingMarket = true
                } else if !useMaturingMarketMonthly {
                    useMaturingMarket = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxMaturingDropWeekly: Double = SimulationSettings.defaultMaxMaturingDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMaturingDropWeekly {
                UserDefaults.standard.set(maxMaturingDropWeekly, forKey: "maxMaturingDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useMaturingMarketMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useMaturingMarketMonthly {
                UserDefaults.standard.set(useMaturingMarketMonthly, forKey: "useMaturingMarketMonthly")
                
                if useMaturingMarketMonthly {
                    useMaturingMarket = true
                } else if !useMaturingMarketWeekly {
                    useMaturingMarket = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxMaturingDropMonthly: Double = SimulationSettings.defaultMaxMaturingDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxMaturingDropMonthly {
                UserDefaults.standard.set(maxMaturingDropMonthly, forKey: "maxMaturingDropMonthly")
            }
        }
    }


    // Recession
    @Published var useRecession: Bool = true {
        didSet {
            guard isInitialized else { return }
            guard oldValue != useRecession else { return }

            UserDefaults.standard.set(useRecession, forKey: "useRecession")
            
            if useRecession {
                useRecessionWeekly = true
                UserDefaults.standard.set(true, forKey: "useRecessionWeekly")
                useRecessionMonthly = true
                UserDefaults.standard.set(true, forKey: "useRecessionMonthly")
            } else {
                useRecessionWeekly = false
                UserDefaults.standard.set(false, forKey: "useRecessionWeekly")
                useRecessionMonthly = false
                UserDefaults.standard.set(false, forKey: "useRecessionMonthly")
            }

            if !isUpdating {
                syncToggleAllState()
            }
        }
    }

    // WEEKLY
    @Published var useRecessionWeekly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRecessionWeekly {
                UserDefaults.standard.set(useRecessionWeekly, forKey: "useRecessionWeekly")
                
                if useRecessionWeekly {
                    useRecession = true
                } else if !useRecessionMonthly {
                    useRecession = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxRecessionDropWeekly: Double = SimulationSettings.defaultMaxRecessionDropWeekly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxRecessionDropWeekly {
                UserDefaults.standard.set(maxRecessionDropWeekly, forKey: "maxRecessionDropWeekly")
            }
        }
    }

    // MONTHLY
    @Published var useRecessionMonthly: Bool = true {
        didSet {
            if isInitialized && !isUpdating && oldValue != useRecessionMonthly {
                UserDefaults.standard.set(useRecessionMonthly, forKey: "useRecessionMonthly")
                
                if useRecessionMonthly {
                    useRecession = true
                } else if !useRecessionWeekly {
                    useRecession = false
                }
                
                if toggleAll {
                    toggleAll = false
                }
                syncToggleAllState()
            }
        }
    }

    @Published var maxRecessionDropMonthly: Double = SimulationSettings.defaultMaxRecessionDropMonthly {
        didSet {
            if isInitialized && !isUpdating && oldValue != maxRecessionDropMonthly {
                UserDefaults.standard.set(maxRecessionDropMonthly, forKey: "maxRecessionDropMonthly")
            }
        }
    }
    
    private func setAllBearishFactors(to newValue: Bool) {
        // We do NOT call their didSet logic beyond saving to UserDefaults
        // We’ll just set them directly, so it won’t repeatedly override us.
        isUpdating = true
        
        useRegClampdown = newValue
        useCompetitorCoin = newValue
        useSecurityBreach = newValue
        useBubblePop = newValue
        useStablecoinMeltdown = newValue
        useBlackSwan = newValue
        useBearMarket = newValue
        useMaturingMarket = newValue
        useRecession = newValue
        
        isUpdating = false
    }

    var areAllFactorsEnabled: Bool {
        useHalving &&
        useInstitutionalDemand &&
        useCountryAdoption &&
        useRegulatoryClarity &&
        useEtfApproval &&
        useTechBreakthrough &&
        useScarcityEvents &&
        useGlobalMacroHedge &&
        useStablecoinShift &&
        useDemographicAdoption &&
        useAltcoinFlight &&
        useAdoptionFactor &&
        useRegClampdown &&
        useCompetitorCoin &&
        useSecurityBreach &&
        useBubblePop &&
        useStablecoinMeltdown &&
        useBlackSwan &&
        useBearMarket &&
        useMaturingMarket &&
        useRecession
    }

    // -----------------------------
    // MARK: - NEW TOGGLE: LOCK HISTORICAL SAMPLING
    // -----------------------------
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            if isInitialized {
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }
    // -----------------------------

    // NEW: We'll compute a hash of the relevant toggles, so the simulation detects changes
    func computeInputsHash(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double
    ) -> UInt64 {
        var hasher = Hasher()
        
        // Combine period settings
        hasher.combine(periodUnit.rawValue)
        hasher.combine(userPeriods)
        
        hasher.combine(initialBTCPriceUSD)
        hasher.combine(startingBalance)
        hasher.combine(averageCostBasis)
        hasher.combine(lockedRandomSeed)
        hasher.combine(seedValue)
        hasher.combine(useRandomSeed)
        hasher.combine(useHistoricalSampling)
        hasher.combine(useVolShocks)
        hasher.combine(annualCAGR)
        hasher.combine(annualVolatility)
        hasher.combine(iterations)
        hasher.combine(currencyPreference.rawValue)
        hasher.combine(exchangeRateEURUSD)

        // Original toggles
        hasher.combine(useHalving)
        hasher.combine(useInstitutionalDemand)
        hasher.combine(useCountryAdoption)
        hasher.combine(useRegulatoryClarity)
        hasher.combine(useEtfApproval)
        hasher.combine(useTechBreakthrough)
        hasher.combine(useScarcityEvents)
        hasher.combine(useGlobalMacroHedge)
        hasher.combine(useStablecoinShift)
        hasher.combine(useDemographicAdoption)
        hasher.combine(useAltcoinFlight)
        hasher.combine(useAdoptionFactor)
        hasher.combine(useRegClampdown)
        hasher.combine(useCompetitorCoin)
        hasher.combine(useSecurityBreach)
        hasher.combine(useBubblePop)
        hasher.combine(useStablecoinMeltdown)
        hasher.combine(useBlackSwan)
        hasher.combine(useBearMarket)
        hasher.combine(useMaturingMarket)
        hasher.combine(useRecession)
        hasher.combine(lockHistoricalSampling)

        // New weekly/monthly toggles
        hasher.combine(useHalvingWeekly)
        hasher.combine(halvingBumpWeekly)
        hasher.combine(useHalvingMonthly)
        hasher.combine(halvingBumpMonthly)

        hasher.combine(useInstitutionalDemandWeekly)
        hasher.combine(maxDemandBoostWeekly)
        hasher.combine(useInstitutionalDemandMonthly)
        hasher.combine(maxDemandBoostMonthly)

        hasher.combine(useCountryAdoptionWeekly)
        hasher.combine(maxCountryAdBoostWeekly)
        hasher.combine(useCountryAdoptionMonthly)
        hasher.combine(maxCountryAdBoostMonthly)

        hasher.combine(useRegulatoryClarityWeekly)
        hasher.combine(maxClarityBoostWeekly)
        hasher.combine(useRegulatoryClarityMonthly)
        hasher.combine(maxClarityBoostMonthly)

        hasher.combine(useEtfApprovalWeekly)
        hasher.combine(maxEtfBoostWeekly)
        hasher.combine(useEtfApprovalMonthly)
        hasher.combine(maxEtfBoostMonthly)

        hasher.combine(useTechBreakthroughWeekly)
        hasher.combine(maxTechBoostWeekly)
        hasher.combine(useTechBreakthroughMonthly)
        hasher.combine(maxTechBoostMonthly)

        hasher.combine(useScarcityEventsWeekly)
        hasher.combine(maxScarcityBoostWeekly)
        hasher.combine(useScarcityEventsMonthly)
        hasher.combine(maxScarcityBoostMonthly)

        hasher.combine(useGlobalMacroHedgeWeekly)
        hasher.combine(maxMacroBoostWeekly)
        hasher.combine(useGlobalMacroHedgeMonthly)
        hasher.combine(maxMacroBoostMonthly)

        hasher.combine(useStablecoinShiftWeekly)
        hasher.combine(maxStablecoinBoostWeekly)
        hasher.combine(useStablecoinShiftMonthly)
        hasher.combine(maxStablecoinBoostMonthly)

        hasher.combine(useDemographicAdoptionWeekly)
        hasher.combine(maxDemoBoostWeekly)
        hasher.combine(useDemographicAdoptionMonthly)
        hasher.combine(maxDemoBoostMonthly)

        hasher.combine(useAltcoinFlightWeekly)
        hasher.combine(maxAltcoinBoostWeekly)
        hasher.combine(useAltcoinFlightMonthly)
        hasher.combine(maxAltcoinBoostMonthly)

        hasher.combine(useAdoptionFactorWeekly)
        hasher.combine(adoptionBaseFactorWeekly)
        hasher.combine(useAdoptionFactorMonthly)
        hasher.combine(adoptionBaseFactorMonthly)

        hasher.combine(useRegClampdownWeekly)
        hasher.combine(maxClampDownWeekly)
        hasher.combine(useRegClampdownMonthly)
        hasher.combine(maxClampDownMonthly)

        hasher.combine(useCompetitorCoinWeekly)
        hasher.combine(maxCompetitorBoostWeekly)
        hasher.combine(useCompetitorCoinMonthly)
        hasher.combine(maxCompetitorBoostMonthly)

        hasher.combine(useSecurityBreachWeekly)
        hasher.combine(breachImpactWeekly)
        hasher.combine(useSecurityBreachMonthly)
        hasher.combine(breachImpactMonthly)

        hasher.combine(useBubblePopWeekly)
        hasher.combine(maxPopDropWeekly)
        hasher.combine(useBubblePopMonthly)
        hasher.combine(maxPopDropMonthly)

        hasher.combine(useStablecoinMeltdownWeekly)
        hasher.combine(maxMeltdownDropWeekly)
        hasher.combine(useStablecoinMeltdownMonthly)
        hasher.combine(maxMeltdownDropMonthly)

        hasher.combine(useBlackSwanWeekly)
        hasher.combine(blackSwanDropWeekly)
        hasher.combine(useBlackSwanMonthly)
        hasher.combine(blackSwanDropMonthly)

        hasher.combine(useBearMarketWeekly)
        hasher.combine(bearWeeklyDriftWeekly)
        hasher.combine(useBearMarketMonthly)
        hasher.combine(bearWeeklyDriftMonthly)

        hasher.combine(useMaturingMarketWeekly)
        hasher.combine(maxMaturingDropWeekly)
        hasher.combine(useMaturingMarketMonthly)
        hasher.combine(maxMaturingDropMonthly)

        hasher.combine(useRecessionWeekly)
        hasher.combine(maxRecessionDropWeekly)
        hasher.combine(useRecessionMonthly)
        hasher.combine(maxRecessionDropMonthly)

        return UInt64(hasher.finalize())
    }

    // MARK: - Run Simulation
    func runSimulation(
        annualCAGR: Double,
        annualVolatility: Double,
        iterations: Int,
        exchangeRateEURUSD: Double = 1.06
    ) {
        // 1) Compute new hash from toggles/settings
        let newHash = computeInputsHash(
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            iterations: iterations,
            exchangeRateEURUSD: exchangeRateEURUSD
        )
        
        // For demonstration, just print the hash comparison:
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = nil or unknown if you’re not storing it.")
        
        printAllSettings()
    }

    // MARK: - Restore Defaults
    func restoreDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks, forKey: "useVolShocks")

        // Remove factor keys
        defaults.removeObject(forKey: "useHalving")
        defaults.removeObject(forKey: "halvingBump")
        defaults.removeObject(forKey: "useInstitutionalDemand")
        defaults.removeObject(forKey: "maxDemandBoost")
        defaults.removeObject(forKey: "useCountryAdoption")
        defaults.removeObject(forKey: "maxCountryAdBoost")
        defaults.removeObject(forKey: "useRegulatoryClarity")
        defaults.removeObject(forKey: "maxClarityBoost")
        defaults.removeObject(forKey: "useEtfApproval")
        defaults.removeObject(forKey: "maxEtfBoost")
        defaults.removeObject(forKey: "useTechBreakthrough")
        defaults.removeObject(forKey: "maxTechBoost")
        defaults.removeObject(forKey: "useScarcityEvents")
        defaults.removeObject(forKey: "maxScarcityBoost")
        defaults.removeObject(forKey: "useGlobalMacroHedge")
        defaults.removeObject(forKey: "maxMacroBoost")
        defaults.removeObject(forKey: "useStablecoinShift")
        defaults.removeObject(forKey: "maxStablecoinBoost")
        defaults.removeObject(forKey: "useDemographicAdoption")
        defaults.removeObject(forKey: "maxDemoBoost")
        defaults.removeObject(forKey: "useAltcoinFlight")
        defaults.removeObject(forKey: "maxAltcoinBoost")
        defaults.removeObject(forKey: "useAdoptionFactor")
        defaults.removeObject(forKey: "adoptionBaseFactor")
        defaults.removeObject(forKey: "useRegClampdown")
        defaults.removeObject(forKey: "maxClampDown")
        defaults.removeObject(forKey: "useCompetitorCoin")
        defaults.removeObject(forKey: "maxCompetitorBoost")
        defaults.removeObject(forKey: "useSecurityBreach")
        defaults.removeObject(forKey: "breachImpact")
        defaults.removeObject(forKey: "useBubblePop")
        defaults.removeObject(forKey: "maxPopDrop")
        defaults.removeObject(forKey: "useStablecoinMeltdown")
        defaults.removeObject(forKey: "maxMeltdownDrop")
        defaults.removeObject(forKey: "useBlackSwan")
        defaults.removeObject(forKey: "blackSwanDrop")
        defaults.removeObject(forKey: "useBearMarket")
        defaults.removeObject(forKey: "bearWeeklyDrift")
        defaults.removeObject(forKey: "useMaturingMarket")
        defaults.removeObject(forKey: "maxMaturingDrop")
        defaults.removeObject(forKey: "useRecession")
        defaults.removeObject(forKey: "maxRecessionDrop")
        defaults.removeObject(forKey: "lockHistoricalSampling")

        // Remove your new toggles
        defaults.removeObject(forKey: "useHistoricalSampling")
        defaults.removeObject(forKey: "useVolShocks")

        // Remove new weekly/monthly keys
        defaults.removeObject(forKey: "useHalvingWeekly")
        defaults.removeObject(forKey: "halvingBumpWeekly")
        defaults.removeObject(forKey: "useHalvingMonthly")
        defaults.removeObject(forKey: "halvingBumpMonthly")

        defaults.removeObject(forKey: "useInstitutionalDemandWeekly")
        defaults.removeObject(forKey: "maxDemandBoostWeekly")
        defaults.removeObject(forKey: "useInstitutionalDemandMonthly")
        defaults.removeObject(forKey: "maxDemandBoostMonthly")

        defaults.removeObject(forKey: "useCountryAdoptionWeekly")
        defaults.removeObject(forKey: "maxCountryAdBoostWeekly")
        defaults.removeObject(forKey: "useCountryAdoptionMonthly")
        defaults.removeObject(forKey: "maxCountryAdBoostMonthly")

        defaults.removeObject(forKey: "useRegulatoryClarityWeekly")
        defaults.removeObject(forKey: "maxClarityBoostWeekly")
        defaults.removeObject(forKey: "useRegulatoryClarityMonthly")
        defaults.removeObject(forKey: "maxClarityBoostMonthly")

        defaults.removeObject(forKey: "useEtfApprovalWeekly")
        defaults.removeObject(forKey: "maxEtfBoostWeekly")
        defaults.removeObject(forKey: "useEtfApprovalMonthly")
        defaults.removeObject(forKey: "maxEtfBoostMonthly")

        defaults.removeObject(forKey: "useTechBreakthroughWeekly")
        defaults.removeObject(forKey: "maxTechBoostWeekly")
        defaults.removeObject(forKey: "useTechBreakthroughMonthly")
        defaults.removeObject(forKey: "maxTechBoostMonthly")

        defaults.removeObject(forKey: "useScarcityEventsWeekly")
        defaults.removeObject(forKey: "maxScarcityBoostWeekly")
        defaults.removeObject(forKey: "useScarcityEventsMonthly")
        defaults.removeObject(forKey: "maxScarcityBoostMonthly")

        defaults.removeObject(forKey: "useGlobalMacroHedgeWeekly")
        defaults.removeObject(forKey: "maxMacroBoostWeekly")
        defaults.removeObject(forKey: "useGlobalMacroHedgeMonthly")
        defaults.removeObject(forKey: "maxMacroBoostMonthly")

        defaults.removeObject(forKey: "useStablecoinShiftWeekly")
        defaults.removeObject(forKey: "maxStablecoinBoostWeekly")
        defaults.removeObject(forKey: "useStablecoinShiftMonthly")
        defaults.removeObject(forKey: "maxStablecoinBoostMonthly")

        defaults.removeObject(forKey: "useDemographicAdoptionWeekly")
        defaults.removeObject(forKey: "maxDemoBoostWeekly")
        defaults.removeObject(forKey: "useDemographicAdoptionMonthly")
        defaults.removeObject(forKey: "maxDemoBoostMonthly")

        defaults.removeObject(forKey: "useAltcoinFlightWeekly")
        defaults.removeObject(forKey: "maxAltcoinBoostWeekly")
        defaults.removeObject(forKey: "useAltcoinFlightMonthly")
        defaults.removeObject(forKey: "maxAltcoinBoostMonthly")

        defaults.removeObject(forKey: "useAdoptionFactorWeekly")
        defaults.removeObject(forKey: "adoptionBaseFactorWeekly")
        defaults.removeObject(forKey: "useAdoptionFactorMonthly")
        defaults.removeObject(forKey: "adoptionBaseFactorMonthly")

        defaults.removeObject(forKey: "useRegClampdownWeekly")
        defaults.removeObject(forKey: "maxClampDownWeekly")
        defaults.removeObject(forKey: "useRegClampdownMonthly")
        defaults.removeObject(forKey: "maxClampDownMonthly")

        defaults.removeObject(forKey: "useCompetitorCoinWeekly")
        defaults.removeObject(forKey: "maxCompetitorBoostWeekly")
        defaults.removeObject(forKey: "useCompetitorCoinMonthly")
        defaults.removeObject(forKey: "maxCompetitorBoostMonthly")

        defaults.removeObject(forKey: "useSecurityBreachWeekly")
        defaults.removeObject(forKey: "breachImpactWeekly")
        defaults.removeObject(forKey: "useSecurityBreachMonthly")
        defaults.removeObject(forKey: "breachImpactMonthly")

        defaults.removeObject(forKey: "useBubblePopWeekly")
        defaults.removeObject(forKey: "maxPopDropWeekly")
        defaults.removeObject(forKey: "useBubblePopMonthly")
        defaults.removeObject(forKey: "maxPopDropMonthly")

        defaults.removeObject(forKey: "useStablecoinMeltdownWeekly")
        defaults.removeObject(forKey: "maxMeltdownDropWeekly")
        defaults.removeObject(forKey: "useStablecoinMeltdownMonthly")
        defaults.removeObject(forKey: "maxMeltdownDropMonthly")

        defaults.removeObject(forKey: "useBlackSwanWeekly")
        defaults.removeObject(forKey: "blackSwanDropWeekly")
        defaults.removeObject(forKey: "useBlackSwanMonthly")
        defaults.removeObject(forKey: "blackSwanDropMonthly")

        defaults.removeObject(forKey: "useBearMarketWeekly")
        defaults.removeObject(forKey: "bearWeeklyDriftWeekly")
        defaults.removeObject(forKey: "useBearMarketMonthly")
        defaults.removeObject(forKey: "bearWeeklyDriftMonthly")

        defaults.removeObject(forKey: "useMaturingMarketWeekly")
        defaults.removeObject(forKey: "maxMaturingDropWeekly")
        defaults.removeObject(forKey: "useMaturingMarketMonthly")
        defaults.removeObject(forKey: "maxMaturingDropMonthly")

        defaults.removeObject(forKey: "useRecessionWeekly")
        defaults.removeObject(forKey: "maxRecessionDropWeekly")
        defaults.removeObject(forKey: "useRecessionMonthly")
        defaults.removeObject(forKey: "maxRecessionDropMonthly")

        // Also remove or reset the toggle
        defaults.removeObject(forKey: "useLognormalGrowth")
        useLognormalGrowth = true
    
        // Reassign them to the NEW defaults:
        useHistoricalSampling = true
        useVolShocks = true
    
        // Reassign them to the NEW defaults:
        useHalving = true
                
        useHalvingWeekly = true
        halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly

        useHalvingMonthly = true
        halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly

        useInstitutionalDemand = true
            
        // Weekly
        useInstitutionalDemandWeekly = true
        maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        
        // Monthly
        useInstitutionalDemandMonthly = true
        maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly

        useCountryAdoption = true
            
        useCountryAdoptionWeekly = true
        maxCountryAdBoostWeekly = SimulationSettings.defaultMaxCountryAdBoostWeekly
        
        useCountryAdoptionMonthly = true
        maxCountryAdBoostMonthly = SimulationSettings.defaultMaxCountryAdBoostMonthly

        useRegulatoryClarity = true
            
        useRegulatoryClarityWeekly = true
        maxClarityBoostWeekly = SimulationSettings.defaultMaxClarityBoostWeekly
        
        useRegulatoryClarityMonthly = true
        maxClarityBoostMonthly = SimulationSettings.defaultMaxClarityBoostMonthly

        useEtfApproval = true

        useEtfApprovalWeekly = true
        maxEtfBoostWeekly = SimulationSettings.defaultMaxEtfBoostWeekly

        useEtfApprovalMonthly = true
        maxEtfBoostMonthly = SimulationSettings.defaultMaxEtfBoostMonthly
    
        useTechBreakthrough = true

        useTechBreakthroughWeekly = true
        maxTechBoostWeekly = SimulationSettings.defaultMaxTechBoostWeekly

        useTechBreakthroughMonthly = true
        maxTechBoostMonthly = SimulationSettings.defaultMaxTechBoostMonthly

        useScarcityEvents = true

        useScarcityEventsWeekly = true
        maxScarcityBoostWeekly = SimulationSettings.defaultMaxScarcityBoostWeekly

        useScarcityEventsMonthly = true
        maxScarcityBoostMonthly = SimulationSettings.defaultMaxScarcityBoostMonthly

        useGlobalMacroHedge = true

        useGlobalMacroHedgeWeekly = true
        maxMacroBoostWeekly = SimulationSettings.defaultMaxMacroBoostWeekly

        useGlobalMacroHedgeMonthly = true
        maxMacroBoostMonthly = SimulationSettings.defaultMaxMacroBoostMonthly

        useStablecoinShift = true

        useStablecoinShiftWeekly = true
        maxStablecoinBoostWeekly = SimulationSettings.defaultMaxStablecoinBoostWeekly

        useStablecoinShiftMonthly = true
        maxStablecoinBoostMonthly = SimulationSettings.defaultMaxStablecoinBoostMonthly

        useDemographicAdoption = true

        useDemographicAdoptionWeekly = true
        maxDemoBoostWeekly = SimulationSettings.defaultMaxDemoBoostWeekly

        useDemographicAdoptionMonthly = true
        maxDemoBoostMonthly = SimulationSettings.defaultMaxDemoBoostMonthly
    
        useAltcoinFlight = true
            
        useAltcoinFlightWeekly = true
        maxAltcoinBoostWeekly = SimulationSettings.defaultMaxAltcoinBoostWeekly
        
        useAltcoinFlightMonthly = true
        maxAltcoinBoostMonthly = SimulationSettings.defaultMaxAltcoinBoostMonthly

        useAdoptionFactor = true
            
        useAdoptionFactorWeekly = true
        adoptionBaseFactorWeekly = SimulationSettings.defaultAdoptionBaseFactorWeekly
        
        useAdoptionFactorMonthly = true
        adoptionBaseFactorMonthly = SimulationSettings.defaultAdoptionBaseFactorMonthly

        useRegClampdown = true
            
        useRegClampdownWeekly = true
        maxClampDownWeekly = SimulationSettings.defaultMaxClampDownWeekly
        
        useRegClampdownMonthly = true
        maxClampDownMonthly = SimulationSettings.defaultMaxClampDownMonthly

        useCompetitorCoin = true
            
        useCompetitorCoinWeekly = true
        maxCompetitorBoostWeekly = SimulationSettings.defaultMaxCompetitorBoostWeekly
        
        useCompetitorCoinMonthly = true
        maxCompetitorBoostMonthly = SimulationSettings.defaultMaxCompetitorBoostMonthly

        useSecurityBreach = true
            
        useSecurityBreachWeekly = true
        breachImpactWeekly = SimulationSettings.defaultBreachImpactWeekly

        useSecurityBreachMonthly = true
        breachImpactMonthly = SimulationSettings.defaultBreachImpactMonthly

        useBubblePop = true
            
        useBubblePopWeekly = true
        maxPopDropWeekly = SimulationSettings.defaultMaxPopDropWeekly
        
        useBubblePopMonthly = true
        maxPopDropMonthly = SimulationSettings.defaultMaxPopDropMonthly

        useStablecoinMeltdown = true

        useStablecoinMeltdownWeekly = true
        maxMeltdownDropWeekly = SimulationSettings.defaultMaxMeltdownDropWeekly

        useStablecoinMeltdownMonthly = true
        maxMeltdownDropMonthly = SimulationSettings.defaultMaxMeltdownDropMonthly

        useBlackSwan = true
            
        useBlackSwanWeekly = true
        blackSwanDropWeekly = SimulationSettings.defaultBlackSwanDropWeekly

        useBlackSwanMonthly = true
        blackSwanDropMonthly = SimulationSettings.defaultBlackSwanDropMonthly

        useBearMarket = true

        useBearMarketWeekly = true
        bearWeeklyDriftWeekly = SimulationSettings.defaultBearWeeklyDriftWeekly

        useBearMarketMonthly = true
        bearWeeklyDriftMonthly = SimulationSettings.defaultBearWeeklyDriftMonthly

        useMaturingMarket = true

        useMaturingMarketWeekly = true
        maxMaturingDropWeekly = SimulationSettings.defaultMaxMaturingDropWeekly

        useMaturingMarketMonthly = true
        maxMaturingDropMonthly = SimulationSettings.defaultMaxMaturingDropMonthly

        useRecession = true

        useRecessionWeekly = true
        maxRecessionDropWeekly = SimulationSettings.defaultMaxRecessionDropWeekly

        useRecessionMonthly = true
        maxRecessionDropMonthly = SimulationSettings.defaultMaxRecessionDropMonthly

        // Enable everything
        toggleAll = true

        // Reset lockHistoricalSampling
        lockHistoricalSampling = false
    }
    
    /// After finishing our initial UserDefaults load (when `isUpdating` is false),
    /// call this to sync parent toggles based on their child weekly/monthly toggles.
    /// If either weekly or monthly is `true`, the parent becomes `true`; otherwise `false`.
    private func finalizeToggleStateAfterLoad() {
        
        // -----------------------------
        // BULLISH
        // -----------------------------
        // Halving
        useHalving = (useHalvingWeekly || useHalvingMonthly)
        // Institutional Demand
        useInstitutionalDemand = (useInstitutionalDemandWeekly || useInstitutionalDemandMonthly)
        // Country Adoption
        useCountryAdoption = (useCountryAdoptionWeekly || useCountryAdoptionMonthly)
        // Regulatory Clarity
        useRegulatoryClarity = (useRegulatoryClarityWeekly || useRegulatoryClarityMonthly)
        // ETF Approval
        useEtfApproval = (useEtfApprovalWeekly || useEtfApprovalMonthly)
        // Tech Breakthrough
        useTechBreakthrough = (useTechBreakthroughWeekly || useTechBreakthroughMonthly)
        // Scarcity Events
        useScarcityEvents = (useScarcityEventsWeekly || useScarcityEventsMonthly)
        // Global Macro Hedge
        useGlobalMacroHedge = (useGlobalMacroHedgeWeekly || useGlobalMacroHedgeMonthly)
        // Stablecoin Shift
        useStablecoinShift = (useStablecoinShiftWeekly || useStablecoinShiftMonthly)
        // Demographic Adoption
        useDemographicAdoption = (useDemographicAdoptionWeekly || useDemographicAdoptionMonthly)
        // Altcoin Flight
        useAltcoinFlight = (useAltcoinFlightWeekly || useAltcoinFlightMonthly)
        // Adoption Factor
        useAdoptionFactor = (useAdoptionFactorWeekly || useAdoptionFactorMonthly)
        
        // -----------------------------
        // BEARISH
        // -----------------------------
        // Regulatory Clampdown
        useRegClampdown = (useRegClampdownWeekly || useRegClampdownMonthly)
        // Competitor Coin
        useCompetitorCoin = (useCompetitorCoinWeekly || useCompetitorCoinMonthly)
        // Security Breach
        useSecurityBreach = (useSecurityBreachWeekly || useSecurityBreachMonthly)
        // Bubble Pop
        useBubblePop = (useBubblePopWeekly || useBubblePopMonthly)
        // Stablecoin Meltdown
        useStablecoinMeltdown = (useStablecoinMeltdownWeekly || useStablecoinMeltdownMonthly)
        // Black Swan
        useBlackSwan = (useBlackSwanWeekly || useBlackSwanMonthly)
        // Bear Market
        useBearMarket = (useBearMarketWeekly || useBearMarketMonthly)
        // Maturing Market
        useMaturingMarket = (useMaturingMarketWeekly || useMaturingMarketMonthly)
        // Recession
        useRecession = (useRecessionWeekly || useRecessionMonthly)
        
        // Finally, let’s sync the master toggle if needed
        syncToggleAllState()
    }
}
