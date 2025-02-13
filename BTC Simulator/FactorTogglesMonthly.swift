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
    
    print("[applyFactorTogglesMonthly] Called at stepIndex=\(stepIndex), baseReturn=\(baseReturn)")
    var adjustedReturn = baseReturn
    
    // Helper function to log each factor:
    func logFactor(_ name: String, _ factor: FactorState) {
        print("[applyFactorTogglesMonthly] \(name) => enabled=\(factor.isEnabled), currentValue=\(factor.currentValue)")
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
                print("   [Halving Triggered] roll=\(roll), finalBump=\(dampenedBump), newReturn=\(adjustedReturn)")
            }
        }
    }
    
    // Institutional Demand
    if let instDemand = monthlySettings.factorsMonthly["InstitutionalDemand"] {
        logFactor("InstitutionalDemand", instDemand)
        if instDemand.isEnabled {
            adjustedReturn += instDemand.currentValue
            print("   [InstitutionalDemand] Added \(instDemand.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Country Adoption
    if let countryAdoption = monthlySettings.factorsMonthly["CountryAdoption"] {
        logFactor("CountryAdoption", countryAdoption)
        if countryAdoption.isEnabled {
            adjustedReturn += countryAdoption.currentValue
            print("   [CountryAdoption] Added \(countryAdoption.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Regulatory Clarity
    if let regClarity = monthlySettings.factorsMonthly["RegulatoryClarity"] {
        logFactor("RegulatoryClarity", regClarity)
        if regClarity.isEnabled {
            adjustedReturn += regClarity.currentValue
            print("   [RegulatoryClarity] Added \(regClarity.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // ETF Approval
    if let etfApproval = monthlySettings.factorsMonthly["EtfApproval"] {
        logFactor("EtfApproval", etfApproval)
        if etfApproval.isEnabled {
            adjustedReturn += etfApproval.currentValue
            print("   [EtfApproval] Added \(etfApproval.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Tech Breakthrough
    if let techBreakthrough = monthlySettings.factorsMonthly["TechBreakthrough"] {
        logFactor("TechBreakthrough", techBreakthrough)
        if techBreakthrough.isEnabled {
            adjustedReturn += techBreakthrough.currentValue
            print("   [TechBreakthrough] Added \(techBreakthrough.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Scarcity Events
    if let scarcity = monthlySettings.factorsMonthly["ScarcityEvents"] {
        logFactor("ScarcityEvents", scarcity)
        if scarcity.isEnabled {
            adjustedReturn += scarcity.currentValue
            print("   [ScarcityEvents] Added \(scarcity.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Global Macro Hedge
    if let macro = monthlySettings.factorsMonthly["GlobalMacroHedge"] {
        logFactor("GlobalMacroHedge", macro)
        if macro.isEnabled {
            adjustedReturn += macro.currentValue
            print("   [GlobalMacroHedge] Added \(macro.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Stablecoin Shift
    if let stablecoin = monthlySettings.factorsMonthly["StablecoinShift"] {
        logFactor("StablecoinShift", stablecoin)
        if stablecoin.isEnabled {
            adjustedReturn += stablecoin.currentValue
            print("   [StablecoinShift] Added \(stablecoin.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Demographic Adoption
    if let demo = monthlySettings.factorsMonthly["DemographicAdoption"] {
        logFactor("DemographicAdoption", demo)
        if demo.isEnabled {
            adjustedReturn += demo.currentValue
            print("   [DemographicAdoption] Added \(demo.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Altcoin Flight
    if let altcoin = monthlySettings.factorsMonthly["AltcoinFlight"] {
        logFactor("AltcoinFlight", altcoin)
        if altcoin.isEnabled {
            adjustedReturn += altcoin.currentValue
            print("   [AltcoinFlight] Added \(altcoin.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Adoption Factor
    if let adoption = monthlySettings.factorsMonthly["AdoptionFactor"] {
        logFactor("AdoptionFactor", adoption)
        if adoption.isEnabled {
            adjustedReturn += adoption.currentValue
            print("   [AdoptionFactor] Added \(adoption.currentValue), newReturn=\(adjustedReturn)")
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
            print("   [RegClampdown] Added \(regClampdown.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Competitor Coin
    if let competitor = monthlySettings.factorsMonthly["CompetitorCoin"] {
        logFactor("CompetitorCoin", competitor)
        if competitor.isEnabled {
            adjustedReturn += competitor.currentValue
            print("   [CompetitorCoin] Added \(competitor.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Security Breach
    if let breach = monthlySettings.factorsMonthly["SecurityBreach"] {
        logFactor("SecurityBreach", breach)
        if breach.isEnabled {
            adjustedReturn += breach.currentValue
            print("   [SecurityBreach] Added \(breach.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Bubble Pop
    if let bubble = monthlySettings.factorsMonthly["BubblePop"] {
        logFactor("BubblePop", bubble)
        if bubble.isEnabled {
            adjustedReturn += bubble.currentValue
            print("   [BubblePop] Added \(bubble.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Stablecoin Meltdown
    if let meltdown = monthlySettings.factorsMonthly["StablecoinMeltdown"] {
        logFactor("StablecoinMeltdown", meltdown)
        if meltdown.isEnabled {
            adjustedReturn += meltdown.currentValue
            print("   [StablecoinMeltdown] Added \(meltdown.currentValue), newReturn=\(adjustedReturn)")
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
                print("   [BlackSwan Triggered] roll=\(roll), finalDrop=\(dampenedDrop), newReturn=\(adjustedReturn)")
            }
        }
    }
    
    // Bear Market
    if let bearMarket = monthlySettings.factorsMonthly["BearMarket"] {
        logFactor("BearMarket", bearMarket)
        if bearMarket.isEnabled {
            adjustedReturn += bearMarket.currentValue
            print("   [BearMarket] Added \(bearMarket.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Maturing Market
    if let maturing = monthlySettings.factorsMonthly["MaturingMarket"] {
        logFactor("MaturingMarket", maturing)
        if maturing.isEnabled {
            adjustedReturn += maturing.currentValue
            print("   [MaturingMarket] Added \(maturing.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    // Recession
    if let recession = monthlySettings.factorsMonthly["Recession"] {
        logFactor("Recession", recession)
        if recession.isEnabled {
            adjustedReturn += recession.currentValue
            print("   [Recession] Added \(recession.currentValue), newReturn=\(adjustedReturn)")
        }
    }
    
    print("[applyFactorTogglesMonthly] Finished. Final adjustedReturn = \(adjustedReturn)")
    return adjustedReturn
}
