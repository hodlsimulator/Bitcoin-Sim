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

        // Halving
        // (Parent toggle commented out)
        // print("// DEBUG:   useHalving=\(self.useHalving)")
        print("// DEBUG:   Halving => [Wk=\(self.useHalvingWeekly), Mo=\(self.useHalvingMonthly)]")
        print("// DEBUG:       halvingBumpWeekly=\(self.halvingBumpWeekly), halvingBumpMonthly=\(self.halvingBumpMonthly)")

        // Institutional Demand
        // (Parent toggle commented out)
        // print("// DEBUG:   useInstitutionalDemand=\(self.useInstitutionalDemand)")
        print("// DEBUG:   Institutional Demand => [Wk=\(self.useInstitutionalDemandWeekly), Mo=\(self.useInstitutionalDemandMonthly)]")
        print("// DEBUG:       maxDemandBoostWeekly=\(self.maxDemandBoostWeekly), maxDemandBoostMonthly=\(self.maxDemandBoostMonthly)")

        // Country Adoption
        // (Parent toggle commented out)
        // print("// DEBUG:   useCountryAdoption=\(self.useCountryAdoption)")
        print("// DEBUG:   Country Adoption => [Wk=\(self.useCountryAdoptionWeekly), Mo=\(self.useCountryAdoptionMonthly)]")
        print("// DEBUG:       maxCountryAdBoostWeekly=\(self.maxCountryAdBoostWeekly), maxCountryAdBoostMonthly=\(self.maxCountryAdBoostMonthly)")

        // Regulatory Clarity
        // (Parent toggle commented out)
        // print("// DEBUG:   useRegulatoryClarity=\(self.useRegulatoryClarity)")
        print("// DEBUG:   Regulatory Clarity => [Wk=\(self.useRegulatoryClarityWeekly), Mo=\(self.useRegulatoryClarityMonthly)]")
        print("// DEBUG:       maxClarityBoostWeekly=\(self.maxClarityBoostWeekly), maxClarityBoostMonthly=\(self.maxClarityBoostMonthly)")

        // ETF Approval
        // (Parent toggle commented out)
        // print("// DEBUG:   useEtfApproval=\(self.useEtfApproval)")
        print("// DEBUG:   ETF Approval => [Wk=\(self.useEtfApprovalWeekly), Mo=\(self.useEtfApprovalMonthly)]")
        print("// DEBUG:       maxEtfBoostWeekly=\(self.maxEtfBoostWeekly), maxEtfBoostMonthly=\(self.maxEtfBoostMonthly)")

        // Tech Breakthrough
        // (Parent toggle commented out)
        // print("// DEBUG:   useTechBreakthrough=\(self.useTechBreakthrough)")
        print("// DEBUG:   Tech Breakthrough => [Wk=\(self.useTechBreakthroughWeekly), Mo=\(self.useTechBreakthroughMonthly)]")
        print("// DEBUG:       maxTechBoostWeekly=\(self.maxTechBoostWeekly), maxTechBoostMonthly=\(self.maxTechBoostMonthly)")

        // Scarcity Events
        // (Parent toggle commented out)
        // print("// DEBUG:   useScarcityEvents=\(self.useScarcityEvents)")
        print("// DEBUG:   Scarcity Events => [Wk=\(self.useScarcityEventsWeekly), Mo=\(self.useScarcityEventsMonthly)]")
        print("// DEBUG:       maxScarcityBoostWeekly=\(self.maxScarcityBoostWeekly), maxScarcityBoostMonthly=\(self.maxScarcityBoostMonthly)")

        // Global Macro Hedge
        // (Parent toggle commented out)
        // print("// DEBUG:   useGlobalMacroHedge=\(self.useGlobalMacroHedge)")
        print("// DEBUG:   Global Macro Hedge => [Wk=\(self.useGlobalMacroHedgeWeekly), Mo=\(self.useGlobalMacroHedgeMonthly)]")
        print("// DEBUG:       maxMacroBoostWeekly=\(self.maxMacroBoostWeekly), maxMacroBoostMonthly=\(self.maxMacroBoostMonthly)")

        // Stablecoin Shift
        // (Parent toggle commented out)
        // print("// DEBUG:   useStablecoinShift=\(self.useStablecoinShift)")
        print("// DEBUG:   Stablecoin Shift => [Wk=\(self.useStablecoinShiftWeekly), Mo=\(self.useStablecoinShiftMonthly)]")
        print("// DEBUG:       maxStablecoinBoostWeekly=\(self.maxStablecoinBoostWeekly), maxStablecoinBoostMonthly=\(self.maxStablecoinBoostMonthly)")

        // Demographic Adoption
        // (Parent toggle commented out)
        // print("// DEBUG:   useDemographicAdoption=\(self.useDemographicAdoption)")
        print("// DEBUG:   Demographic Adoption => [Wk=\(self.useDemographicAdoptionWeekly), Mo=\(self.useDemographicAdoptionMonthly)]")
        print("// DEBUG:       maxDemoBoostWeekly=\(self.maxDemoBoostWeekly), maxDemoBoostMonthly=\(self.maxDemoBoostMonthly)")

        // Altcoin Flight
        // (Parent toggle commented out)
        // print("// DEBUG:   useAltcoinFlight=\(self.useAltcoinFlight)")
        print("// DEBUG:   Altcoin Flight => [Wk=\(self.useAltcoinFlightWeekly), Mo=\(self.useAltcoinFlightMonthly)]")
        print("// DEBUG:       maxAltcoinBoostWeekly=\(self.maxAltcoinBoostWeekly), maxAltcoinBoostMonthly=\(self.maxAltcoinBoostMonthly)")

        // Adoption Factor
        // (Parent toggle commented out)
        // print("// DEBUG:   useAdoptionFactor=\(self.useAdoptionFactor)")
        print("// DEBUG:   Adoption Factor => [Wk=\(self.useAdoptionFactorWeekly), Mo=\(self.useAdoptionFactorMonthly)]")
        print("// DEBUG:       adoptionBaseFactorWeekly=\(self.adoptionBaseFactorWeekly), adoptionBaseFactorMonthly=\(self.adoptionBaseFactorMonthly)")

        // -----------------------------
        // BEARISH
        // -----------------------------
        print("// DEBUG: BEARISH FACTORS =>")

        // Regulatory Clampdown
        // (Parent toggle commented out)
        // print("// DEBUG:   useRegClampdown=\(self.useRegClampdown)")
        print("// DEBUG:   Regulatory Clampdown => [Wk=\(self.useRegClampdownWeekly), Mo=\(self.useRegClampdownMonthly)]")
        print("// DEBUG:       maxClampDownWeekly=\(self.maxClampDownWeekly), maxClampDownMonthly=\(self.maxClampDownMonthly)")

        // Competitor Coin
        // (Parent toggle commented out)
        // print("// DEBUG:   useCompetitorCoin=\(self.useCompetitorCoin)")
        print("// DEBUG:   Competitor Coin => [Wk=\(self.useCompetitorCoinWeekly), Mo=\(self.useCompetitorCoinMonthly)]")
        print("// DEBUG:       maxCompetitorBoostWeekly=\(self.maxCompetitorBoostWeekly), maxCompetitorBoostMonthly=\(self.maxCompetitorBoostMonthly)")

        // Security Breach
        // (Parent toggle commented out)
        // print("// DEBUG:   useSecurityBreach=\(self.useSecurityBreach)")
        print("// DEBUG:   Security Breach => [Wk=\(self.useSecurityBreachWeekly), Mo=\(self.useSecurityBreachMonthly)]")
        print("// DEBUG:       breachImpactWeekly=\(self.breachImpactWeekly), breachImpactMonthly=\(self.breachImpactMonthly)")

        // Bubble Pop
        // (Parent toggle commented out)
        // print("// DEBUG:   useBubblePop=\(self.useBubblePop)")
        print("// DEBUG:   Bubble Pop => [Wk=\(self.useBubblePopWeekly), Mo=\(self.useBubblePopMonthly)]")
        print("// DEBUG:       maxPopDropWeekly=\(self.maxPopDropWeekly), maxPopDropMonthly=\(self.maxPopDropMonthly)")

        // Stablecoin Meltdown
        // (Parent toggle commented out)
        // print("// DEBUG:   useStablecoinMeltdown=\(self.useStablecoinMeltdown)")
        print("// DEBUG:   Stablecoin Meltdown => [Wk=\(self.useStablecoinMeltdownWeekly), Mo=\(self.useStablecoinMeltdownMonthly)]")
        print("// DEBUG:       maxMeltdownDropWeekly=\(self.maxMeltdownDropWeekly), maxMeltdownDropMonthly=\(self.maxMeltdownDropMonthly)")

        // Black Swan
        // (Parent toggle commented out)
        // print("// DEBUG:   useBlackSwan=\(self.useBlackSwan)")
        print("// DEBUG:   Black Swan => [Wk=\(self.useBlackSwanWeekly), Mo=\(self.useBlackSwanMonthly)]")
        print("// DEBUG:       blackSwanDropWeekly=\(self.blackSwanDropWeekly), blackSwanDropMonthly=\(self.blackSwanDropMonthly)")

        // Bear Market
        // (Parent toggle commented out)
        // print("// DEBUG:   useBearMarket=\(self.useBearMarket)")
        print("// DEBUG:   Bear Market => [Wk=\(self.useBearMarketWeekly), Mo=\(self.useBearMarketMonthly)]")
        print("// DEBUG:       bearWeeklyDriftWeekly=\(self.bearWeeklyDriftWeekly), bearWeeklyDriftMonthly=\(self.bearWeeklyDriftMonthly)")

        // Maturing Market
        // (Parent toggle commented out)
        // print("// DEBUG:   useMaturingMarket=\(self.useMaturingMarket)")
        print("// DEBUG:   Maturing Market => [Wk=\(self.useMaturingMarketWeekly), Mo=\(self.useMaturingMarketMonthly)]")
        print("// DEBUG:       maxMaturingDropWeekly=\(self.maxMaturingDropWeekly), maxMaturingDropMonthly=\(self.maxMaturingDropMonthly)")

        // Recession
        // (Parent toggle commented out)
        // print("// DEBUG:   useRecession=\(self.useRecession)")
        print("// DEBUG:   Recession => [Wk=\(self.useRecessionWeekly), Mo=\(self.useRecessionMonthly)]")
        print("// DEBUG:       maxRecessionDropWeekly=\(self.maxRecessionDropWeekly), maxRecessionDropMonthly=\(self.maxRecessionDropMonthly)")

        // lockHistoricalSampling
        print("// DEBUG: lockHistoricalSampling=\(self.lockHistoricalSampling)")

        // toggleAll & areAllFactorsEnabled
        print("// DEBUG: toggleAll=\(self.toggleAll), areAllFactorsEnabled=\(self.areAllFactorsEnabled)")

        print("======================================================================================")
    }
}
