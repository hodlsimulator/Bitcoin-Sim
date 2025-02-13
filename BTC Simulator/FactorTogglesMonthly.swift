//
//  FactorTogglesMonthly.swift
//  BTCMonteCarlo
//
//  Created by . . on 13/02/2025.
//

import Foundation
import GameplayKit

/// Applies monthly toggles to a base log-return, using the factor dictionary in MonthlySimulationSettings.
func applyFactorTogglesMonthly(
    baseReturn: Double,
    stepIndex: Int,
    monthlySettings: MonthlySimulationSettings,
    mempoolDataManager: MempoolDataManager,
    rng: GKRandomSource
) -> Double {
    
    var adjustedReturn = baseReturn
    
    // Helper function to log each factor (now empty):
    func logFactor(_ name: String, _ factor: FactorState) {
        // (Removed print statements)
    }
    
    // ─────────────────────────
    // BULLISH FACTORS
    // ─────────────────────────
    
    // Halving
    if let halving = monthlySettings.factorsMonthly["Halving"] {
        logFactor("Halving", halving)
        if halving.isEnabled {
            let stressLevel = mempoolDataManager.stressLevel(at: stepIndex)
            let baseProb = 0.02
            let dynamicProb = (stressLevel > 80.0) ? baseProb * 1.5 : baseProb
            let roll = Double(rng.nextUniform())
            if roll < dynamicProb {
                let historicalBump = HalvingHistoricalManager.shared.cachedAverageHalvingBump
                let userBump = halving.currentValue
                let rawBump = (userBump + historicalBump) * CalibrationManager.shared.halvingMultiplierMonthly
                let dampenedBump = rawBump * (atan(rawBump) / (Double.pi / 2))
                adjustedReturn += dampenedBump
            }
        }
    }
    
    // Institutional Demand
    if let instDemand = monthlySettings.factorsMonthly["InstitutionalDemand"] {
        logFactor("InstitutionalDemand", instDemand)
        if instDemand.isEnabled {
            adjustedReturn += instDemand.currentValue
        }
    }
    
    // Country Adoption
    if let countryAdoption = monthlySettings.factorsMonthly["CountryAdoption"] {
        logFactor("CountryAdoption", countryAdoption)
        if countryAdoption.isEnabled {
            adjustedReturn += countryAdoption.currentValue
        }
    }
    
    // Regulatory Clarity
    if let regClarity = monthlySettings.factorsMonthly["RegulatoryClarity"] {
        logFactor("RegulatoryClarity", regClarity)
        if regClarity.isEnabled {
            adjustedReturn += regClarity.currentValue
        }
    }
    
    // ETF Approval
    if let etfApproval = monthlySettings.factorsMonthly["EtfApproval"] {
        logFactor("EtfApproval", etfApproval)
        if etfApproval.isEnabled {
            adjustedReturn += etfApproval.currentValue
        }
    }
    
    // Tech Breakthrough
    if let techBreakthrough = monthlySettings.factorsMonthly["TechBreakthrough"] {
        logFactor("TechBreakthrough", techBreakthrough)
        if techBreakthrough.isEnabled {
            adjustedReturn += techBreakthrough.currentValue
        }
    }
    
    // Scarcity Events
    if let scarcity = monthlySettings.factorsMonthly["ScarcityEvents"] {
        logFactor("ScarcityEvents", scarcity)
        if scarcity.isEnabled {
            adjustedReturn += scarcity.currentValue
        }
    }
    
    // Global Macro Hedge
    if let macro = monthlySettings.factorsMonthly["GlobalMacroHedge"] {
        logFactor("GlobalMacroHedge", macro)
        if macro.isEnabled {
            adjustedReturn += macro.currentValue
        }
    }
    
    // Stablecoin Shift
    if let stablecoin = monthlySettings.factorsMonthly["StablecoinShift"] {
        logFactor("StablecoinShift", stablecoin)
        if stablecoin.isEnabled {
            adjustedReturn += stablecoin.currentValue
        }
    }
    
    // Demographic Adoption
    if let demo = monthlySettings.factorsMonthly["DemographicAdoption"] {
        logFactor("DemographicAdoption", demo)
        if demo.isEnabled {
            adjustedReturn += demo.currentValue
        }
    }
    
    // Altcoin Flight
    if let altcoin = monthlySettings.factorsMonthly["AltcoinFlight"] {
        logFactor("AltcoinFlight", altcoin)
        if altcoin.isEnabled {
            adjustedReturn += altcoin.currentValue
        }
    }
    
    // Adoption Factor
    if let adoption = monthlySettings.factorsMonthly["AdoptionFactor"] {
        logFactor("AdoptionFactor", adoption)
        if adoption.isEnabled {
            adjustedReturn += adoption.currentValue
        }
    }
    
    // ─────────────────────────
    // BEARISH FACTORS
    // ─────────────────────────
    
    // Regulatory Clampdown
    if let regClampdown = monthlySettings.factorsMonthly["RegClampdown"] {
        logFactor("RegClampdown", regClampdown)
        if regClampdown.isEnabled {
            adjustedReturn += regClampdown.currentValue
        }
    }
    
    // Competitor Coin
    if let competitor = monthlySettings.factorsMonthly["CompetitorCoin"] {
        logFactor("CompetitorCoin", competitor)
        if competitor.isEnabled {
            adjustedReturn += competitor.currentValue
        }
    }
    
    // Security Breach
    if let breach = monthlySettings.factorsMonthly["SecurityBreach"] {
        logFactor("SecurityBreach", breach)
        if breach.isEnabled {
            adjustedReturn += breach.currentValue
        }
    }
    
    // Bubble Pop
    if let bubble = monthlySettings.factorsMonthly["BubblePop"] {
        logFactor("BubblePop", bubble)
        if bubble.isEnabled {
            adjustedReturn += bubble.currentValue
        }
    }
    
    // Stablecoin Meltdown
    if let meltdown = monthlySettings.factorsMonthly["StablecoinMeltdown"] {
        logFactor("StablecoinMeltdown", meltdown)
        if meltdown.isEnabled {
            adjustedReturn += meltdown.currentValue
        }
    }
    
    // Black Swan (probability approach)
    if let blackSwan = monthlySettings.factorsMonthly["BlackSwan"] {
        logFactor("BlackSwan", blackSwan)
        if blackSwan.isEnabled {
            let stressLevel = mempoolDataManager.stressLevel(at: stepIndex)
            let baseProb = 0.028
            let dynamicProb = (stressLevel > 80.0) ? baseProb * 2.0 : baseProb
            let roll = Double(rng.nextUniform())
            if roll < dynamicProb {
                let rawDrop = blackSwan.currentValue * CalibrationManager.shared.blackSwanMultiplierMonthly
                let dampenedDrop = rawDrop * (atan(abs(rawDrop)) / (Double.pi / 2))
                adjustedReturn += dampenedDrop
            }
        }
    }
    
    // Bear Market
    if let bearMarket = monthlySettings.factorsMonthly["BearMarket"] {
        logFactor("BearMarket", bearMarket)
        if bearMarket.isEnabled {
            adjustedReturn += bearMarket.currentValue
        }
    }
    
    // Maturing Market
    if let maturing = monthlySettings.factorsMonthly["MaturingMarket"] {
        logFactor("MaturingMarket", maturing)
        if maturing.isEnabled {
            adjustedReturn += maturing.currentValue
        }
    }
    
    // Recession
    if let recession = monthlySettings.factorsMonthly["Recession"] {
        logFactor("Recession", recession)
        if recession.isEnabled {
            adjustedReturn += recession.currentValue
        }
    }
    
    return adjustedReturn
}
    