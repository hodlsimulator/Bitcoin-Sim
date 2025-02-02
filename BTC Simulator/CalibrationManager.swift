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
    var halvingMultiplierWeekly: Double = 1.0
    var halvingMultiplierMonthly: Double = 1.0
    
    // Institutional Demand
    var institutionalDemandMultiplierWeekly: Double = 1.0
    var institutionalDemandMultiplierMonthly: Double = 1.0
    
    // Country Adoption
    var countryAdoptionMultiplierWeekly: Double = 1.0
    var countryAdoptionMultiplierMonthly: Double = 1.0
    
    // Regulatory Clarity
    var regulatoryClarityMultiplierWeekly: Double = 1.0
    var regulatoryClarityMultiplierMonthly: Double = 1.0
    
    // ETF Approval
    var etfApprovalMultiplierWeekly: Double = 1.0
    var etfApprovalMultiplierMonthly: Double = 1.0
    
    // Tech Breakthrough
    var techBreakthroughMultiplierWeekly: Double = 1.0
    var techBreakthroughMultiplierMonthly: Double = 1.0
    
    // Scarcity Events
    var scarcityEventsMultiplierWeekly: Double = 1.0
    var scarcityEventsMultiplierMonthly: Double = 1.0
    
    // Global Macro Hedge
    var globalMacroHedgeMultiplierWeekly: Double = 1.0
    var globalMacroHedgeMultiplierMonthly: Double = 1.0
    
    // Stablecoin Shift
    var stablecoinShiftMultiplierWeekly: Double = 1.0
    var stablecoinShiftMultiplierMonthly: Double = 1.0
    
    // Demographic Adoption
    var demographicAdoptionMultiplierWeekly: Double = 1.0
    var demographicAdoptionMultiplierMonthly: Double = 1.0
    
    // Altcoin Flight
    var altcoinFlightMultiplierWeekly: Double = 1.0
    var altcoinFlightMultiplierMonthly: Double = 1.0
    
    // Adoption Factor
    var adoptionFactorMultiplierWeekly: Double = 1.0
    var adoptionFactorMultiplierMonthly: Double = 1.0

    // MARK: - Bearish Factors Multipliers
    
    // Regulatory Clampdown
    var regClampdownMultiplierWeekly: Double = 1.0
    var regClampdownMultiplierMonthly: Double = 1.0
    
    // Competitor Coin
    var competitorCoinMultiplierWeekly: Double = 1.0
    var competitorCoinMultiplierMonthly: Double = 1.0
    
    // Security Breach
    var securityBreachMultiplierWeekly: Double = 1.0
    var securityBreachMultiplierMonthly: Double = 1.0
    
    // Bubble Pop
    var bubblePopMultiplierWeekly: Double = 1.0
    var bubblePopMultiplierMonthly: Double = 1.0
    
    // Stablecoin Meltdown
    var stablecoinMeltdownMultiplierWeekly: Double = 1.0
    var stablecoinMeltdownMultiplierMonthly: Double = 1.0
    
    // Black Swan
    var blackSwanMultiplierWeekly: Double = 1.0
    var blackSwanMultiplierMonthly: Double = 1.0
    
    // Bear Market
    var bearMarketMultiplierWeekly: Double = 1.0
    var bearMarketMultiplierMonthly: Double = 1.0
    
    // Maturing Market
    var maturingMarketMultiplierWeekly: Double = 1.0
    var maturingMarketMultiplierMonthly: Double = 1.0
    
    // Recession
    var recessionMultiplierWeekly: Double = 1.0
    var recessionMultiplierMonthly: Double = 1.0

    // MARK: - Initialisation
    private init() {
        // Optionally load default values from a config file.
    }
    
    // MARK: - Methods
    
    /// Resets all calibration multipliers to their default values.
    func resetToDefaults() {
        // Bullish factors
        halvingMultiplierWeekly = 0.9
        halvingMultiplierMonthly = 0.9
        
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
        regClampdownMultiplierWeekly = 1.0
        regClampdownMultiplierMonthly = 1.0
        
        competitorCoinMultiplierWeekly = 1.0
        competitorCoinMultiplierMonthly = 1.0
        
        securityBreachMultiplierWeekly = 1.0
        securityBreachMultiplierMonthly = 1.0
        
        bubblePopMultiplierWeekly = 1.0
        bubblePopMultiplierMonthly = 1.0
        
        stablecoinMeltdownMultiplierWeekly = 1.0
        stablecoinMeltdownMultiplierMonthly = 1.0
        
        blackSwanMultiplierWeekly = 1.0
        blackSwanMultiplierMonthly = 1.0
        
        bearMarketMultiplierWeekly = 1.0
        bearMarketMultiplierMonthly = 1.0
        
        maturingMarketMultiplierWeekly = 1.0
        maturingMarketMultiplierMonthly = 1.0
        
        recessionMultiplierWeekly = 1.0
        recessionMultiplierMonthly = 1.0
    }
    
    /// Loads calibration settings from a JSON file.
    /// - Parameter url: URL of the JSON configuration file.
    func loadFromFile(url: URL) {
        // Placeholder for JSON parsing to update multipliers.
        // For now, this method does nothing.
    }
    
    /// Saves the current calibration settings to a JSON file.
    /// - Parameter url: URL where the JSON configuration should be saved.
    func saveToFile(url: URL) {
        // Placeholder for JSON serialization to save multipliers.
        // For now, this method does nothing.
    }
}
