//
//  CalibrationManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/02/2025
//

import Foundation

/// Manages calibration multipliers for simulation factors.
class CalibrationManager {

    // Singleton instance for central access.
    static let shared = CalibrationManager()
    
    // MARK: - Bullish Factors Multipliers
    
    // Halving
    var halvingMultiplierWeekly: Double = 0.9
    var halvingMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Institutional Demand
    var institutionalDemandMultiplierWeekly: Double = 1.0
    var institutionalDemandMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Country Adoption
    var countryAdoptionMultiplierWeekly: Double = 1.0
    var countryAdoptionMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Regulatory Clarity
    var regulatoryClarityMultiplierWeekly: Double = 1.0
    var regulatoryClarityMultiplierMonthly: Double = 1.0  // unchanged
    
    // ETF Approval
    var etfApprovalMultiplierWeekly: Double = 1.0
    var etfApprovalMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Tech Breakthrough
    var techBreakthroughMultiplierWeekly: Double = 1.0
    var techBreakthroughMultiplierMonthly: Double = 1.0  // unchanged
    
    // Scarcity Events
    var scarcityEventsMultiplierWeekly: Double = 1.0
    var scarcityEventsMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Global Macro Hedge
    var globalMacroHedgeMultiplierWeekly: Double = 1.0
    var globalMacroHedgeMultiplierMonthly: Double = 1.0  // unchanged
    
    // Stablecoin Shift
    var stablecoinShiftMultiplierWeekly: Double = 1.0
    var stablecoinShiftMultiplierMonthly: Double = 1.0  // unchanged
    
    // Demographic Adoption
    var demographicAdoptionMultiplierWeekly: Double = 1.0
    var demographicAdoptionMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Altcoin Flight
    var altcoinFlightMultiplierWeekly: Double = 1.0
    var altcoinFlightMultiplierMonthly: Double = 0.8  // calibrated default
    
    // Adoption Factor
    var adoptionFactorMultiplierWeekly: Double = 1.0
    var adoptionFactorMultiplierMonthly: Double = 1.0  // calibrated default

    // MARK: - Bearish Factors Multipliers
    
    // Regulatory Clampdown
    var regClampdownMultiplierWeekly: Double = 1.5
    var regClampdownMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Competitor Coin
    var competitorCoinMultiplierWeekly: Double = 1.5
    var competitorCoinMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Security Breach
    var securityBreachMultiplierWeekly: Double = 1.5
    var securityBreachMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Bubble Pop
    var bubblePopMultiplierWeekly: Double = 2.0
    var bubblePopMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Stablecoin Meltdown
    var stablecoinMeltdownMultiplierWeekly: Double = 1.5
    var stablecoinMeltdownMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Black Swan
    var blackSwanMultiplierWeekly: Double = 0.85
    var blackSwanMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Bear Market
    var bearMarketMultiplierWeekly: Double = 2.0
    var bearMarketMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Maturing Market
    var maturingMarketMultiplierWeekly: Double = 2.0
    var maturingMarketMultiplierMonthly: Double = 1.0  // calibrated default
    
    // Recession
    var recessionMultiplierWeekly: Double = 2.0
    var recessionMultiplierMonthly: Double = 1.0  // calibrated default

    // MARK: - Initialisation
    private init() {
        // Optionally load default values from a config file.
    }
    
    // MARK: - Methods
    
    /// Resets all calibration multipliers to their default calibrated values.
    func resetToDefaults() {
        // Bullish factors
        halvingMultiplierWeekly = 0.9
        halvingMultiplierMonthly = 1.0
        
        institutionalDemandMultiplierWeekly = 1.0
        institutionalDemandMultiplierMonthly = 1.0
        
        countryAdoptionMultiplierWeekly = 1.0
        countryAdoptionMultiplierMonthly = 1.0
        
        regulatoryClarityMultiplierWeekly = 1.0
        regulatoryClarityMultiplierMonthly = 1.0
        
        etfApprovalMultiplierWeekly = 1.0
        etfApprovalMultiplierMonthly = 1.0
        
        techBreakthroughMultiplierWeekly = 1.0
        techBreakthroughMultiplierMonthly = 1.0
        
        scarcityEventsMultiplierWeekly = 1.0
        scarcityEventsMultiplierMonthly = 1.0
        
        globalMacroHedgeMultiplierWeekly = 1.0
        globalMacroHedgeMultiplierMonthly = 1.0
        
        stablecoinShiftMultiplierWeekly = 1.0
        stablecoinShiftMultiplierMonthly = 1.0
        
        demographicAdoptionMultiplierWeekly = 1.0
        demographicAdoptionMultiplierMonthly = 1.0
        
        altcoinFlightMultiplierWeekly = 1.0
        altcoinFlightMultiplierMonthly = 1.0
        
        adoptionFactorMultiplierWeekly = 1.0
        adoptionFactorMultiplierMonthly = 1.0
        
        // Bearish factors
        regClampdownMultiplierWeekly = 1.5
        regClampdownMultiplierMonthly = 1.0
        
        competitorCoinMultiplierWeekly = 1.5
        competitorCoinMultiplierMonthly = 1.0
        
        securityBreachMultiplierWeekly = 1.5
        securityBreachMultiplierMonthly = 1.0
        
        bubblePopMultiplierWeekly = 2.0
        bubblePopMultiplierMonthly = 1.0
        
        stablecoinMeltdownMultiplierWeekly = 1.5
        stablecoinMeltdownMultiplierMonthly = 1.0
        
        blackSwanMultiplierWeekly = 0.85
        blackSwanMultiplierMonthly = 1.0
        
        bearMarketMultiplierWeekly = 2.0
        bearMarketMultiplierMonthly = 1.0
        
        maturingMarketMultiplierWeekly = 2.0
        maturingMarketMultiplierMonthly = 1.0
        
        recessionMultiplierWeekly = 2.0
        recessionMultiplierMonthly = 1.0
    }
    
    /// Loads calibration settings from a JSON file.
    /// - Parameter url: URL of the JSON configuration file.
    func loadFromFile(url: URL) {
        // Placeholder for JSON parsing to update multipliers.
    }
    
    /// Saves the current calibration settings to a JSON file.
    /// - Parameter url: URL where the JSON configuration should be saved.
    func saveToFile(url: URL) {
        // Placeholder for JSON serialization to save multipliers.
    }
}
