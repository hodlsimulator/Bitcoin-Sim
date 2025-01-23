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
        
        // Newly printed settings:
        print("// DEBUG: useHistoricalSampling=\(self.useHistoricalSampling)")
        print("// DEBUG: useVolShocks=\(self.useVolShocks)")
        print("// DEBUG: useGarchVolatility=\(self.useGarchVolatility)")
        print("// DEBUG: useLognormalGrowth=\(self.useLognormalGrowth)")
        print("// DEBUG: useAutoCorrelation=\(self.useAutoCorrelation), autoCorrelationStrength=\(self.autoCorrelationStrength), meanReversionTarget=\(self.meanReversionTarget)")
        print("// DEBUG: lockHistoricalSampling=\(self.lockHistoricalSampling)")

        // -----------------------------
        // BULLISH
        // -----------------------------
        print("// DEBUG: BULLISH FACTORS =>")
        // Halving
        print("// DEBUG:   Halving => [Wk=\(self.useHalvingWeekly), Mo=\(self.useHalvingMonthly)]")
        print("// DEBUG:       halvingBumpWeekly=\(self.halvingBumpWeekly), halvingBumpMonthly=\(self.halvingBumpMonthly)")
        
        // Institutional Demand
        print("// DEBUG:   Institutional Demand => [Wk=\(self.useInstitutionalDemandWeekly), Mo=\(self.useInstitutionalDemandMonthly)]")
        print("// DEBUG:       maxDemandBoostWeekly=\(self.maxDemandBoostWeekly), maxDemandBoostMonthly=\(self.maxDemandBoostMonthly)")
        
        // Country Adoption
        print("// DEBUG:   Country Adoption => [Wk=\(self.useCountryAdoptionWeekly), Mo=\(self.useCountryAdoptionMonthly)]")
        print("// DEBUG:       maxCountryAdBoostWeekly=\(self.maxCountryAdBoostWeekly), maxCountryAdBoostMonthly=\(self.maxCountryAdBoostMonthly)")
        
        // Regulatory Clarity
        print("// DEBUG:   Regulatory Clarity => [Wk=\(self.useRegulatoryClarityWeekly), Mo=\(self.useRegulatoryClarityMonthly)]")
        print("// DEBUG:       maxClarityBoostWeekly=\(self.maxClarityBoostWeekly), maxClarityBoostMonthly=\(self.maxClarityBoostMonthly)")
        
        // ETF Approval
        print("// DEBUG:   ETF Approval => [Wk=\(self.useEtfApprovalWeekly), Mo=\(self.useEtfApprovalMonthly)]")
        print("// DEBUG:       maxEtfBoostWeekly=\(self.maxEtfBoostWeekly), maxEtfBoostMonthly=\(self.maxEtfBoostMonthly)")
        
        // Tech Breakthrough
        print("// DEBUG:   Tech Breakthrough => [Wk=\(self.useTechBreakthroughWeekly), Mo=\(self.useTechBreakthroughMonthly)]")
        print("// DEBUG:       maxTechBoostWeekly=\(self.maxTechBoostWeekly), maxTechBoostMonthly=\(self.maxTechBoostMonthly)")
        
        // Scarcity Events
        print("// DEBUG:   Scarcity Events => [Wk=\(self.useScarcityEventsWeekly), Mo=\(self.useScarcityEventsMonthly)]")
        print("// DEBUG:       maxScarcityBoostWeekly=\(self.maxScarcityBoostWeekly), maxScarcityBoostMonthly=\(self.maxScarcityBoostMonthly)")
        
        // Global Macro Hedge
        print("// DEBUG:   Global Macro Hedge => [Wk=\(self.useGlobalMacroHedgeWeekly), Mo=\(self.useGlobalMacroHedgeMonthly)]")
        print("// DEBUG:       maxMacroBoostWeekly=\(self.maxMacroBoostWeekly), maxMacroBoostMonthly=\(self.maxMacroBoostMonthly)")
        
        // Stablecoin Shift
        print("// DEBUG:   Stablecoin Shift => [Wk=\(self.useStablecoinShiftWeekly), Mo=\(self.useStablecoinShiftMonthly)]")
        print("// DEBUG:       maxStablecoinBoostWeekly=\(self.maxStablecoinBoostWeekly), maxStablecoinBoostMonthly=\(self.maxStablecoinBoostMonthly)")
        
        // Demographic Adoption
        print("// DEBUG:   Demographic Adoption => [Wk=\(self.useDemographicAdoptionWeekly), Mo=\(self.useDemographicAdoptionMonthly)]")
        print("// DEBUG:       maxDemoBoostWeekly=\(self.maxDemoBoostWeekly), maxDemoBoostMonthly=\(self.maxDemoBoostMonthly)")
        
        // Altcoin Flight
        print("// DEBUG:   Altcoin Flight => [Wk=\(self.useAltcoinFlightWeekly), Mo=\(self.useAltcoinFlightMonthly)]")
        print("// DEBUG:       maxAltcoinBoostWeekly=\(self.maxAltcoinBoostWeekly), maxAltcoinBoostMonthly=\(self.maxAltcoinBoostMonthly)")
        
        // Adoption Factor
        print("// DEBUG:   Adoption Factor => [Wk=\(self.useAdoptionFactorWeekly), Mo=\(self.useAdoptionFactorMonthly)]")
        print("// DEBUG:       adoptionBaseFactorWeekly=\(self.adoptionBaseFactorWeekly), adoptionBaseFactorMonthly=\(self.adoptionBaseFactorMonthly)")
        
        // -----------------------------
        // BEARISH
        // -----------------------------
        print("// DEBUG: BEARISH FACTORS =>")
        
        // Regulatory Clampdown
        print("// DEBUG:   Regulatory Clampdown => [Wk=\(self.useRegClampdownWeekly), Mo=\(self.useRegClampdownMonthly)]")
        print("// DEBUG:       maxClampDownWeekly=\(self.maxClampDownWeekly), maxClampDownMonthly=\(self.maxClampDownMonthly)")
        
        // Competitor Coin
        print("// DEBUG:   Competitor Coin => [Wk=\(self.useCompetitorCoinWeekly), Mo=\(self.useCompetitorCoinMonthly)]")
        print("// DEBUG:       maxCompetitorBoostWeekly=\(self.maxCompetitorBoostWeekly), maxCompetitorBoostMonthly=\(self.maxCompetitorBoostMonthly)")
        
        // Security Breach
        print("// DEBUG:   Security Breach => [Wk=\(self.useSecurityBreachWeekly), Mo=\(self.useSecurityBreachMonthly)]")
        print("// DEBUG:       breachImpactWeekly=\(self.breachImpactWeekly), breachImpactMonthly=\(self.breachImpactMonthly)")
        
        // Bubble Pop
        print("// DEBUG:   Bubble Pop => [Wk=\(self.useBubblePopWeekly), Mo=\(self.useBubblePopMonthly)]")
        print("// DEBUG:       maxPopDropWeekly=\(self.maxPopDropWeekly), maxPopDropMonthly=\(self.maxPopDropMonthly)")
        
        // Stablecoin Meltdown
        print("// DEBUG:   Stablecoin Meltdown => [Wk=\(self.useStablecoinMeltdownWeekly), Mo=\(self.useStablecoinMeltdownMonthly)]")
        print("// DEBUG:       maxMeltdownDropWeekly=\(self.maxMeltdownDropWeekly), maxMeltdownDropMonthly=\(self.maxMeltdownDropMonthly)")
        
        // Black Swan
        print("// DEBUG:   Black Swan => [Wk=\(self.useBlackSwanWeekly), Mo=\(self.useBlackSwanMonthly)]")
        print("// DEBUG:       blackSwanDropWeekly=\(self.blackSwanDropWeekly), blackSwanDropMonthly=\(self.blackSwanDropMonthly)")
        
        // Bear Market
        print("// DEBUG:   Bear Market => [Wk=\(self.useBearMarketWeekly), Mo=\(self.useBearMarketMonthly)]")
        print("// DEBUG:       bearWeeklyDriftWeekly=\(self.bearWeeklyDriftWeekly), bearWeeklyDriftMonthly=\(self.bearWeeklyDriftMonthly)")
        
        // Maturing Market
        print("// DEBUG:   Maturing Market => [Wk=\(self.useMaturingMarketWeekly), Mo=\(self.useMaturingMarketMonthly)]")
        print("// DEBUG:       maxMaturingDropWeekly=\(self.maxMaturingDropWeekly), maxMaturingDropMonthly=\(self.maxMaturingDropMonthly)")
        
        // Recession
        print("// DEBUG:   Recession => [Wk=\(self.useRecessionWeekly), Mo=\(self.useRecessionMonthly)]")
        print("// DEBUG:       maxRecessionDropWeekly=\(self.maxRecessionDropWeekly), maxRecessionDropMonthly=\(self.maxRecessionDropMonthly)")
        
        // toggleAll & areAllFactorsEnabled
        print("// DEBUG: toggleAll=\(self.toggleAll), areAllFactorsEnabled=\(self.areAllFactorsEnabled)")

        print("======================================================================================")
    }
}
