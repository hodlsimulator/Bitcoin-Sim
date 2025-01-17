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
        print("// DEBUG: SimulationSettings => periodUnit=\(self.periodUnit.rawValue), userPeriods=\(self.userPeriods), initialBTCPriceUSD=\(self.initialBTCPriceUSD)")
        print("// DEBUG:   startingBalance=\(self.startingBalance), averageCostBasis=\(self.averageCostBasis)")
        print("// DEBUG:   lockedRandomSeed=\(self.lockedRandomSeed), seedValue=\(self.seedValue), useRandomSeed=\(self.useRandomSeed)")
        print("// DEBUG:   currencyPreference=\(self.currencyPreference.rawValue)")
        
        // NEW Toggles
        print("// DEBUG: useHistoricalSampling=\(self.useHistoricalSampling)")
        print("// DEBUG: useVolShocks=\(self.useVolShocks)")
        
        // -----------------------------
        // BULLISH
        // -----------------------------
        print("// DEBUG: BULLISH FACTORS =>")
        
        print("// DEBUG:   useHalving=\(self.useHalving), [Wk=\(self.useHalvingWeekly), Mo=\(self.useHalvingMonthly)]")
        print("// DEBUG:       halvingBumpWeekly=\(self.halvingBumpWeekly), halvingBumpMonthly=\(self.halvingBumpMonthly)")
        
        print("// DEBUG:   useInstitutionalDemand=\(self.useInstitutionalDemand), [Wk=\(self.useInstitutionalDemandWeekly), Mo=\(self.useInstitutionalDemandMonthly)]")
        print("// DEBUG:       maxDemandBoostWeekly=\(self.maxDemandBoostWeekly), maxDemandBoostMonthly=\(self.maxDemandBoostMonthly)")
        
        print("// DEBUG:   useCountryAdoption=\(self.useCountryAdoption), [Wk=\(self.useCountryAdoptionWeekly), Mo=\(self.useCountryAdoptionMonthly)]")
        print("// DEBUG:       maxCountryAdBoostWeekly=\(self.maxCountryAdBoostWeekly), maxCountryAdBoostMonthly=\(self.maxCountryAdBoostMonthly)")
        
        print("// DEBUG:   useRegulatoryClarity=\(self.useRegulatoryClarity), [Wk=\(self.useRegulatoryClarityWeekly), Mo=\(self.useRegulatoryClarityMonthly)]")
        print("// DEBUG:       maxClarityBoostWeekly=\(self.maxClarityBoostWeekly), maxClarityBoostMonthly=\(self.maxClarityBoostMonthly)")
        
        print("// DEBUG:   useEtfApproval=\(self.useEtfApproval), [Wk=\(self.useEtfApprovalWeekly), Mo=\(self.useEtfApprovalMonthly)]")
        print("// DEBUG:       maxEtfBoostWeekly=\(self.maxEtfBoostWeekly), maxEtfBoostMonthly=\(self.maxEtfBoostMonthly)")
        
        print("// DEBUG:   useTechBreakthrough=\(self.useTechBreakthrough), [Wk=\(self.useTechBreakthroughWeekly), Mo=\(self.useTechBreakthroughMonthly)]")
        print("// DEBUG:       maxTechBoostWeekly=\(self.maxTechBoostWeekly), maxTechBoostMonthly=\(self.maxTechBoostMonthly)")
        
        print("// DEBUG:   useScarcityEvents=\(self.useScarcityEvents), [Wk=\(self.useScarcityEventsWeekly), Mo=\(self.useScarcityEventsMonthly)]")
        print("// DEBUG:       maxScarcityBoostWeekly=\(self.maxScarcityBoostWeekly), maxScarcityBoostMonthly=\(self.maxScarcityBoostMonthly)")
        
        print("// DEBUG:   useGlobalMacroHedge=\(self.useGlobalMacroHedge), [Wk=\(self.useGlobalMacroHedgeWeekly), Mo=\(self.useGlobalMacroHedgeMonthly)]")
        print("// DEBUG:       maxMacroBoostWeekly=\(self.maxMacroBoostWeekly), maxMacroBoostMonthly=\(self.maxMacroBoostMonthly)")
        
        print("// DEBUG:   useStablecoinShift=\(self.useStablecoinShift), [Wk=\(self.useStablecoinShiftWeekly), Mo=\(self.useStablecoinShiftMonthly)]")
        print("// DEBUG:       maxStablecoinBoostWeekly=\(self.maxStablecoinBoostWeekly), maxStablecoinBoostMonthly=\(self.maxStablecoinBoostMonthly)")
        
        print("// DEBUG:   useDemographicAdoption=\(self.useDemographicAdoption), [Wk=\(self.useDemographicAdoptionWeekly), Mo=\(self.useDemographicAdoptionMonthly)]")
        print("// DEBUG:       maxDemoBoostWeekly=\(self.maxDemoBoostWeekly), maxDemoBoostMonthly=\(self.maxDemoBoostMonthly)")
        
        print("// DEBUG:   useAltcoinFlight=\(self.useAltcoinFlight), [Wk=\(self.useAltcoinFlightWeekly), Mo=\(self.useAltcoinFlightMonthly)]")
        print("// DEBUG:       maxAltcoinBoostWeekly=\(self.maxAltcoinBoostWeekly), maxAltcoinBoostMonthly=\(self.maxAltcoinBoostMonthly)")
        
        print("// DEBUG:   useAdoptionFactor=\(self.useAdoptionFactor), [Wk=\(self.useAdoptionFactorWeekly), Mo=\(self.useAdoptionFactorMonthly)]")
        print("// DEBUG:       adoptionBaseFactorWeekly=\(self.adoptionBaseFactorWeekly), adoptionBaseFactorMonthly=\(self.adoptionBaseFactorMonthly)")
        
        // -----------------------------
        // BEARISH
        // -----------------------------
        print("// DEBUG: BEARISH FACTORS =>")
        
        print("// DEBUG:   useRegClampdown=\(self.useRegClampdown), [Wk=\(self.useRegClampdownWeekly), Mo=\(self.useRegClampdownMonthly)]")
        print("// DEBUG:       maxClampDownWeekly=\(self.maxClampDownWeekly), maxClampDownMonthly=\(self.maxClampDownMonthly)")
        
        print("// DEBUG:   useCompetitorCoin=\(self.useCompetitorCoin), [Wk=\(self.useCompetitorCoinWeekly), Mo=\(self.useCompetitorCoinMonthly)]")
        print("// DEBUG:       maxCompetitorBoostWeekly=\(self.maxCompetitorBoostWeekly), maxCompetitorBoostMonthly=\(self.maxCompetitorBoostMonthly)")
        
        print("// DEBUG:   useSecurityBreach=\(self.useSecurityBreach), [Wk=\(self.useSecurityBreachWeekly), Mo=\(self.useSecurityBreachMonthly)]")
        print("// DEBUG:       breachImpactWeekly=\(self.breachImpactWeekly), breachImpactMonthly=\(self.breachImpactMonthly)")
        
        print("// DEBUG:   useBubblePop=\(self.useBubblePop), [Wk=\(self.useBubblePopWeekly), Mo=\(self.useBubblePopMonthly)]")
        print("// DEBUG:       maxPopDropWeekly=\(self.maxPopDropWeekly), maxPopDropMonthly=\(self.maxPopDropMonthly)")
        
        print("// DEBUG:   useStablecoinMeltdown=\(self.useStablecoinMeltdown), [Wk=\(self.useStablecoinMeltdownWeekly), Mo=\(self.useStablecoinMeltdownMonthly)]")
        print("// DEBUG:       maxMeltdownDropWeekly=\(self.maxMeltdownDropWeekly), maxMeltdownDropMonthly=\(self.maxMeltdownDropMonthly)")
        
        print("// DEBUG:   useBlackSwan=\(self.useBlackSwan), [Wk=\(self.useBlackSwanWeekly), Mo=\(self.useBlackSwanMonthly)]")
        print("// DEBUG:       blackSwanDropWeekly=\(self.blackSwanDropWeekly), blackSwanDropMonthly=\(self.blackSwanDropMonthly)")
        
        print("// DEBUG:   useBearMarket=\(self.useBearMarket), [Wk=\(self.useBearMarketWeekly), Mo=\(self.useBearMarketMonthly)]")
        print("// DEBUG:       bearWeeklyDriftWeekly=\(self.bearWeeklyDriftWeekly), bearWeeklyDriftMonthly=\(self.bearWeeklyDriftMonthly)")
        
        print("// DEBUG:   useMaturingMarket=\(self.useMaturingMarket), [Wk=\(self.useMaturingMarketWeekly), Mo=\(self.useMaturingMarketMonthly)]")
        print("// DEBUG:       maxMaturingDropWeekly=\(self.maxMaturingDropWeekly), maxMaturingDropMonthly=\(self.maxMaturingDropMonthly)")
        
        print("// DEBUG:   useRecession=\(self.useRecession), [Wk=\(self.useRecessionWeekly), Mo=\(self.useRecessionMonthly)]")
        print("// DEBUG:       maxRecessionDropWeekly=\(self.maxRecessionDropWeekly), maxRecessionDropMonthly=\(self.maxRecessionDropMonthly)")
        
        print("// DEBUG: lockHistoricalSampling=\(self.lockHistoricalSampling)")
        print("// DEBUG: toggleAll=\(self.toggleAll), areAllFactorsEnabled=\(self.areAllFactorsEnabled)")
        
        print("======================================================================================")
    }
}
