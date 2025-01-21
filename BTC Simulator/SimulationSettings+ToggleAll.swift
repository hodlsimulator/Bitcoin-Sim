
//
//  SimulationSettings+ToggleAll.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
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

    func handleToggleAllChange() {
        // If something else is in progress, do nothing
        guard !isUpdating else { return }

        isUpdating = true

        let usingWeeklyMode = (periodUnit == .weeks)

        if toggleAll {
            // Turn on all factors
            useHalving = true
            useInstitutionalDemand = true
            useCountryAdoption = true
            useRegulatoryClarity = true
            useEtfApproval = true
            useTechBreakthrough = true
            useScarcityEvents = true
            useGlobalMacroHedge = true
            useStablecoinShift = true
            useDemographicAdoption = true
            useAltcoinFlight = true
            useAdoptionFactor = true

            useRegClampdown = true
            useCompetitorCoin = true
            useSecurityBreach = true
            useBubblePop = true
            useStablecoinMeltdown = true
            useBlackSwan = true
            useBearMarket = true
            useMaturingMarket = true
            useRecession = true

            // Switch between weekly/monthly children
            if usingWeeklyMode {
                // Turn on all weekly, off monthly
                useHalvingWeekly = true
                useHalvingMonthly = false

                useInstitutionalDemandWeekly = true
                useInstitutionalDemandMonthly = false

                useCountryAdoptionWeekly = true
                useCountryAdoptionMonthly = false

                useRegulatoryClarityWeekly = true
                useRegulatoryClarityMonthly = false

                useEtfApprovalWeekly = true
                useEtfApprovalMonthly = false

                useTechBreakthroughWeekly = true
                useTechBreakthroughMonthly = false

                useScarcityEventsWeekly = true
                useScarcityEventsMonthly = false

                useGlobalMacroHedgeWeekly = true
                useGlobalMacroHedgeMonthly = false

                useStablecoinShiftWeekly = true
                useStablecoinShiftMonthly = false

                useDemographicAdoptionWeekly = true
                useDemographicAdoptionMonthly = false

                useAltcoinFlightWeekly = true
                useAltcoinFlightMonthly = false

                useAdoptionFactorWeekly = true
                useAdoptionFactorMonthly = false

                // Bearish
                useRegClampdownWeekly = true
                useRegClampdownMonthly = false

                useCompetitorCoinWeekly = true
                useCompetitorCoinMonthly = false

                useSecurityBreachWeekly = true
                useSecurityBreachMonthly = false

                useBubblePopWeekly = true
                useBubblePopMonthly = false

                useStablecoinMeltdownWeekly = true
                useStablecoinMeltdownMonthly = false

                useBlackSwanWeekly = true
                useBlackSwanMonthly = false

                useBearMarketWeekly = true
                useBearMarketMonthly = false

                useMaturingMarketWeekly = true
                useMaturingMarketMonthly = false

                useRecessionWeekly = true
                useRecessionMonthly = false

            } else {
                // Turn on all monthly, off weekly
                useHalvingWeekly = false
                useHalvingMonthly = true

                useInstitutionalDemandWeekly = false
                useInstitutionalDemandMonthly = true

                useCountryAdoptionWeekly = false
                useCountryAdoptionMonthly = true

                useRegulatoryClarityWeekly = false
                useRegulatoryClarityMonthly = true

                useEtfApprovalWeekly = false
                useEtfApprovalMonthly = true

                useTechBreakthroughWeekly = false
                useTechBreakthroughMonthly = true

                useScarcityEventsWeekly = false
                useScarcityEventsMonthly = true

                useGlobalMacroHedgeWeekly = false
                useGlobalMacroHedgeMonthly = true

                useStablecoinShiftWeekly = false
                useStablecoinShiftMonthly = true

                useDemographicAdoptionWeekly = false
                useDemographicAdoptionMonthly = true

                useAltcoinFlightWeekly = false
                useAltcoinFlightMonthly = true

                useAdoptionFactorWeekly = false
                useAdoptionFactorMonthly = true

                useRegClampdownWeekly = false
                useRegClampdownMonthly = true

                useCompetitorCoinWeekly = false
                useCompetitorCoinMonthly = true

                useSecurityBreachWeekly = false
                useSecurityBreachMonthly = true

                useBubblePopWeekly = false
                useBubblePopMonthly = true

                useStablecoinMeltdownWeekly = false
                useStablecoinMeltdownMonthly = true

                useBlackSwanWeekly = false
                useBlackSwanMonthly = true

                useBearMarketWeekly = false
                useBearMarketMonthly = true

                useMaturingMarketWeekly = false
                useMaturingMarketMonthly = true

                useRecessionWeekly = false
                useRecessionMonthly = true
            }

        } else {
            // Turn off all factors
            useHalving = false
            useInstitutionalDemand = false
            useCountryAdoption = false
            useRegulatoryClarity = false
            useEtfApproval = false
            useTechBreakthrough = false
            useScarcityEvents = false
            useGlobalMacroHedge = false
            useStablecoinShift = false
            useDemographicAdoption = false
            useAltcoinFlight = false
            useAdoptionFactor = false

            useRegClampdown = false
            useCompetitorCoin = false
            useSecurityBreach = false
            useBubblePop = false
            useStablecoinMeltdown = false
            useBlackSwan = false
            useBearMarket = false
            useMaturingMarket = false
            useRecession = false

            // Turn off all weekly/monthly children
            useHalvingWeekly = false
            useHalvingMonthly = false

            useInstitutionalDemandWeekly = false
            useInstitutionalDemandMonthly = false

            useCountryAdoptionWeekly = false
            useCountryAdoptionMonthly = false

            useRegulatoryClarityWeekly = false
            useRegulatoryClarityMonthly = false

            useEtfApprovalWeekly = false
            useEtfApprovalMonthly = false

            useTechBreakthroughWeekly = false
            useTechBreakthroughMonthly = false

            useScarcityEventsWeekly = false
            useScarcityEventsMonthly = false

            useGlobalMacroHedgeWeekly = false
            useGlobalMacroHedgeMonthly = false

            useStablecoinShiftWeekly = false
            useStablecoinShiftMonthly = false

            useDemographicAdoptionWeekly = false
            useDemographicAdoptionMonthly = false

            useAltcoinFlightWeekly = false
            useAltcoinFlightMonthly = false

            useAdoptionFactorWeekly = false
            useAdoptionFactorMonthly = false

            useRegClampdownWeekly = false
            useRegClampdownMonthly = false

            useCompetitorCoinWeekly = false
            useCompetitorCoinMonthly = false

            useSecurityBreachWeekly = false
            useSecurityBreachMonthly = false

            useBubblePopWeekly = false
            useBubblePopMonthly = false

            useStablecoinMeltdownWeekly = false
            useStablecoinMeltdownMonthly = false

            useBlackSwanWeekly = false
            useBlackSwanMonthly = false

            useBearMarketWeekly = false
            useBearMarketMonthly = false

            useMaturingMarketWeekly = false
            useMaturingMarketMonthly = false

            useRecessionWeekly = false
            useRecessionMonthly = false
        }

        isUpdating = false
        syncToggleAllState()
    }

    func syncToggleAllState() {
        // If everything is turned on, we want toggleAll to match that.
        guard !isUpdating else { return }

        let allOn =
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

        if toggleAll != allOn {
            isUpdating = true
            toggleAll = allOn
            isUpdating = false
        }
    }
}
