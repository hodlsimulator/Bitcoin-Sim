//
//  SimulationSettings+BullishFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    // =============================
    // MARK: BULLISH FACTORS (weekly/monthly)
    // =============================

    var useHalvingWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useHalvingWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useHalvingWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useHalvingWeekly")
        }
    }
    
    var halvingBumpWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "halvingBumpWeekly") as? Double
            ?? SimulationSettings.defaultHalvingBumpWeekly
        }
        set {
            let oldVal = halvingBumpWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "halvingBumpWeekly")
        }
    }
    
    var useHalvingMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useHalvingMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useHalvingMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useHalvingMonthly")
        }
    }
    
    var halvingBumpMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "halvingBumpMonthly") as? Double
            ?? SimulationSettings.defaultHalvingBumpMonthly
        }
        set {
            let oldVal = halvingBumpMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "halvingBumpMonthly")
        }
    }
    
    var useInstitutionalDemandWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useInstitutionalDemandWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useInstitutionalDemandWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useInstitutionalDemandWeekly")
        }
    }
    
    var maxDemandBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxDemandBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxDemandBoostWeekly
        }
        set {
            let oldVal = maxDemandBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemandBoostWeekly")
        }
    }
    
    var useInstitutionalDemandMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useInstitutionalDemandMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useInstitutionalDemandMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useInstitutionalDemandMonthly")
        }
    }
    
    var maxDemandBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxDemandBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxDemandBoostMonthly
        }
        set {
            let oldVal = maxDemandBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemandBoostMonthly")
        }
    }
    
    var useCountryAdoptionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCountryAdoptionWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useCountryAdoptionWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCountryAdoptionWeekly")
        }
    }
    
    var maxCountryAdBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxCountryAdBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxCountryAdBoostWeekly
        }
        set {
            let oldVal = maxCountryAdBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxCountryAdBoostWeekly")
        }
    }
    
    var useCountryAdoptionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCountryAdoptionMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useCountryAdoptionMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCountryAdoptionMonthly")
        }
    }
    
    var maxCountryAdBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxCountryAdBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxCountryAdBoostMonthly
        }
        set {
            let oldVal = maxCountryAdBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxCountryAdBoostMonthly")
        }
    }
    
    var useRegulatoryClarityWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegulatoryClarityWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useRegulatoryClarityWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegulatoryClarityWeekly")
        }
    }
    
    var maxClarityBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxClarityBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxClarityBoostWeekly
        }
        set {
            let oldVal = maxClarityBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxClarityBoostWeekly")
        }
    }
    
    var useRegulatoryClarityMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegulatoryClarityMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useRegulatoryClarityMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegulatoryClarityMonthly")
        }
    }
    
    var maxClarityBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxClarityBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxClarityBoostMonthly
        }
        set {
            let oldVal = maxClarityBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxClarityBoostMonthly")
        }
    }
    
    var useEtfApprovalWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useEtfApprovalWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useEtfApprovalWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useEtfApprovalWeekly")
        }
    }
    
    var maxEtfBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxEtfBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxEtfBoostWeekly
        }
        set {
            let oldVal = maxEtfBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxEtfBoostWeekly")
        }
    }
    
    var useEtfApprovalMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useEtfApprovalMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useEtfApprovalMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useEtfApprovalMonthly")
        }
    }
    
    var maxEtfBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxEtfBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxEtfBoostMonthly
        }
        set {
            let oldVal = maxEtfBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxEtfBoostMonthly")
        }
    }
    
    var useTechBreakthroughWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useTechBreakthroughWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useTechBreakthroughWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useTechBreakthroughWeekly")
        }
    }
    
    var maxTechBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxTechBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxTechBoostWeekly
        }
        set {
            let oldVal = maxTechBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxTechBoostWeekly")
        }
    }
    
    var useTechBreakthroughMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useTechBreakthroughMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useTechBreakthroughMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useTechBreakthroughMonthly")
        }
    }
    
    var maxTechBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxTechBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxTechBoostMonthly
        }
        set {
            let oldVal = maxTechBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxTechBoostMonthly")
        }
    }
    
    var useScarcityEventsWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useScarcityEventsWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useScarcityEventsWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useScarcityEventsWeekly")
        }
    }
    
    var maxScarcityBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxScarcityBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxScarcityBoostWeekly
        }
        set {
            let oldVal = maxScarcityBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxScarcityBoostWeekly")
        }
    }
    
    var useScarcityEventsMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useScarcityEventsMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useScarcityEventsMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useScarcityEventsMonthly")
        }
    }
    
    var maxScarcityBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxScarcityBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxScarcityBoostMonthly
        }
        set {
            let oldVal = maxScarcityBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxScarcityBoostMonthly")
        }
    }
    
    var useGlobalMacroHedgeWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useGlobalMacroHedgeWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useGlobalMacroHedgeWeekly")
        }
    }
    
    var maxMacroBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMacroBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxMacroBoostWeekly
        }
        set {
            let oldVal = maxMacroBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMacroBoostWeekly")
        }
    }
    
    var useGlobalMacroHedgeMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useGlobalMacroHedgeMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useGlobalMacroHedgeMonthly")
        }
    }
    
    var maxMacroBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMacroBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxMacroBoostMonthly
        }
        set {
            let oldVal = maxMacroBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMacroBoostMonthly")
        }
    }
    
    var useStablecoinShiftWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinShiftWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useStablecoinShiftWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinShiftWeekly")
        }
    }
    
    var maxStablecoinBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxStablecoinBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxStablecoinBoostWeekly
        }
        set {
            let oldVal = maxStablecoinBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxStablecoinBoostWeekly")
        }
    }
    
    var useStablecoinShiftMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinShiftMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useStablecoinShiftMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinShiftMonthly")
        }
    }
    
    var maxStablecoinBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxStablecoinBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxStablecoinBoostMonthly
        }
        set {
            let oldVal = maxStablecoinBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxStablecoinBoostMonthly")
        }
    }
    
    var useDemographicAdoptionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useDemographicAdoptionWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useDemographicAdoptionWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useDemographicAdoptionWeekly")
        }
    }
    
    var maxDemoBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxDemoBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxDemoBoostWeekly
        }
        set {
            let oldVal = maxDemoBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemoBoostWeekly")
        }
    }
    
    var useDemographicAdoptionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useDemographicAdoptionMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useDemographicAdoptionMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useDemographicAdoptionMonthly")
        }
    }
    
    var maxDemoBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxDemoBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxDemoBoostMonthly
        }
        set {
            let oldVal = maxDemoBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemoBoostMonthly")
        }
    }
    
    var useAltcoinFlightWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAltcoinFlightWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useAltcoinFlightWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAltcoinFlightWeekly")
        }
    }
    
    var maxAltcoinBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxAltcoinBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxAltcoinBoostWeekly
        }
        set {
            let oldVal = maxAltcoinBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxAltcoinBoostWeekly")
        }
    }
    
    var useAltcoinFlightMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAltcoinFlightMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useAltcoinFlightMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAltcoinFlightMonthly")
        }
    }
    
    var maxAltcoinBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxAltcoinBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxAltcoinBoostMonthly
        }
        set {
            let oldVal = maxAltcoinBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxAltcoinBoostMonthly")
        }
    }
    
    var useAdoptionFactorWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAdoptionFactorWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useAdoptionFactorWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAdoptionFactorWeekly")
        }
    }
    
    var adoptionBaseFactorWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "adoptionBaseFactorWeekly") as? Double
            ?? SimulationSettings.defaultAdoptionBaseFactorWeekly
        }
        set {
            let oldVal = adoptionBaseFactorWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "adoptionBaseFactorWeekly")
        }
    }
    
    var useAdoptionFactorMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAdoptionFactorMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useAdoptionFactorMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAdoptionFactorMonthly")
        }
    }
    
    var adoptionBaseFactorMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "adoptionBaseFactorMonthly") as? Double
            ?? SimulationSettings.defaultAdoptionBaseFactorMonthly
        }
        set {
            let oldVal = adoptionBaseFactorMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "adoptionBaseFactorMonthly")
        }
    }
}
