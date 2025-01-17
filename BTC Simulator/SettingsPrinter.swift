//
//  SettingsPrinter.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    func printAllSettings() {
        print("=== FACTOR SETTINGS (once only) ===")
        print("// DEBUG: SimulationSettings run => periodUnit=\(self.periodUnit.rawValue), userPeriods=\(self.userPeriods), initialBTCPriceUSD=\(self.initialBTCPriceUSD)")
        print("// DEBUG:   startingBalance=\(self.startingBalance), averageCostBasis=\(self.averageCostBasis)")
        print("// DEBUG:   lockedRandomSeed=\(self.lockedRandomSeed), seedValue=\(self.seedValue), useRandomSeed=\(self.useRandomSeed)")
        print("// DEBUG:   currencyPreference=\(self.currencyPreference.rawValue)")
        
        // NEW Toggles
        print("// DEBUG: useHistoricalSampling=\(self.useHistoricalSampling)")
        print("// DEBUG: useVolShocks=\(self.useVolShocks)")
        
        // BULLISH
        print("// DEBUG: BULLISH FACTORS =>")
        print("// DEBUG:   useHalving=\(self.useHalving), halvingBump=\(self.halvingBump)")
        print("// DEBUG:   useInstitutionalDemand=\(self.useInstitutionalDemand), maxDemandBoost=\(self.maxDemandBoost)")
        print("// DEBUG:   useCountryAdoption=\(self.useCountryAdoption), maxCountryAdBoost=\(self.maxCountryAdBoost)")
        print("// DEBUG:   useRegulatoryClarity=\(self.useRegulatoryClarity), maxClarityBoost=\(self.maxClarityBoost)")
        print("// DEBUG:   useEtfApproval=\(self.useEtfApproval), maxEtfBoost=\(self.maxEtfBoost)")
        print("// DEBUG:   useTechBreakthrough=\(self.useTechBreakthrough), maxTechBoost=\(self.maxTechBoost)")
        print("// DEBUG:   useScarcityEvents=\(self.useScarcityEvents), maxScarcityBoost=\(self.maxScarcityBoost)")
        print("// DEBUG:   useGlobalMacroHedge=\(self.useGlobalMacroHedge), maxMacroBoost=\(self.maxMacroBoost)")
        print("// DEBUG:   useStablecoinShift=\(self.useStablecoinShift), maxStablecoinBoost=\(self.maxStablecoinBoost)")
        print("// DEBUG:   useDemographicAdoption=\(self.useDemographicAdoption), maxDemoBoost=\(self.maxDemoBoost)")
        print("// DEBUG:   useAltcoinFlight=\(self.useAltcoinFlight), maxAltcoinBoost=\(self.maxAltcoinBoost)")
        print("// DEBUG:   useAdoptionFactor=\(self.useAdoptionFactor), adoptionBaseFactor=\(self.adoptionBaseFactor)")
        
        // BEARISH
        print("// DEBUG: BEARISH FACTORS =>")
        print("// DEBUG:   useRegClampdown=\(self.useRegClampdown), maxClampDown=\(self.maxClampDown)")
        print("// DEBUG:   useCompetitorCoin=\(self.useCompetitorCoin), maxCompetitorBoost=\(self.maxCompetitorBoost)")
        print("// DEBUG:   useSecurityBreach=\(self.useSecurityBreach), breachImpact=\(self.breachImpact)")
        print("// DEBUG:   useBubblePop=\(self.useBubblePop), maxPopDrop=\(self.maxPopDrop)")
        print("// DEBUG:   useStablecoinMeltdown=\(self.useStablecoinMeltdown), maxMeltdownDrop=\(self.maxMeltdownDrop)")
        print("// DEBUG:   useBlackSwan=\(self.useBlackSwan), blackSwanDrop=\(self.blackSwanDrop)")
        print("// DEBUG:   useBearMarket=\(self.useBearMarket), bearWeeklyDrift=\(self.bearWeeklyDrift)")
        print("// DEBUG:   useMaturingMarket=\(self.useMaturingMarket), maxMaturingDrop=\(self.maxMaturingDrop)")
        print("// DEBUG:   useRecession=\(self.useRecession), maxRecessionDrop=\(self.maxRecessionDrop)")
        
        print("// DEBUG: lockHistoricalSampling=\(self.lockHistoricalSampling)")
        print("// DEBUG: toggleAll=\(self.toggleAll), areAllFactorsEnabled=\(self.areAllFactorsEnabled)")
        
        print("======================================================================================")
    }
}
