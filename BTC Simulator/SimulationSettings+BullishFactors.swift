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
            print("didSet: useHalvingWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useHalvingWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useHalvingWeekly")
            print("DEBUG: After toggling, userDefaults[useHalvingWeekly] = \(storedVal)")
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
            print("didSet: halvingBumpWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "halvingBumpWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "halvingBumpWeekly")
            print("DEBUG: After updating, userDefaults[halvingBumpWeekly] = \(storedVal)")
        }
    }
    
    var useHalvingMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useHalvingMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useHalvingMonthly
            if oldVal == newValue { return }
            print("didSet: useHalvingMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useHalvingMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useHalvingMonthly")
            print("DEBUG: After toggling, userDefaults[useHalvingMonthly] = \(storedVal)")
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
            print("didSet: halvingBumpMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "halvingBumpMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "halvingBumpMonthly")
            print("DEBUG: After updating, userDefaults[halvingBumpMonthly] = \(storedVal)")
        }
    }
    
    var useInstitutionalDemandWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useInstitutionalDemandWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useInstitutionalDemandWeekly
            if oldVal == newValue { return }
            print("didSet: useInstitutionalDemandWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useInstitutionalDemandWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useInstitutionalDemandWeekly")
            print("DEBUG: After toggling, userDefaults[useInstitutionalDemandWeekly] = \(storedVal)")
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
            print("didSet: maxDemandBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemandBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxDemandBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxDemandBoostWeekly] = \(storedVal)")
        }
    }
    
    var useInstitutionalDemandMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useInstitutionalDemandMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useInstitutionalDemandMonthly
            if oldVal == newValue { return }
            print("didSet: useInstitutionalDemandMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useInstitutionalDemandMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useInstitutionalDemandMonthly")
            print("DEBUG: After toggling, userDefaults[useInstitutionalDemandMonthly] = \(storedVal)")
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
            print("didSet: maxDemandBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemandBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxDemandBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxDemandBoostMonthly] = \(storedVal)")
        }
    }
    
    var useCountryAdoptionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCountryAdoptionWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useCountryAdoptionWeekly
            if oldVal == newValue { return }
            print("didSet: useCountryAdoptionWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCountryAdoptionWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useCountryAdoptionWeekly")
            print("DEBUG: After toggling, userDefaults[useCountryAdoptionWeekly] = \(storedVal)")
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
            print("didSet: maxCountryAdBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxCountryAdBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxCountryAdBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxCountryAdBoostWeekly] = \(storedVal)")
        }
    }
    
    var useCountryAdoptionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCountryAdoptionMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useCountryAdoptionMonthly
            if oldVal == newValue { return }
            print("didSet: useCountryAdoptionMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCountryAdoptionMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useCountryAdoptionMonthly")
            print("DEBUG: After toggling, userDefaults[useCountryAdoptionMonthly] = \(storedVal)")
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
            print("didSet: maxCountryAdBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxCountryAdBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxCountryAdBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxCountryAdBoostMonthly] = \(storedVal)")
        }
    }
    
    var useRegulatoryClarityWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegulatoryClarityWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useRegulatoryClarityWeekly
            if oldVal == newValue { return }
            print("didSet: useRegulatoryClarityWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegulatoryClarityWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useRegulatoryClarityWeekly")
            print("DEBUG: After toggling, userDefaults[useRegulatoryClarityWeekly] = \(storedVal)")
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
            print("didSet: maxClarityBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxClarityBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxClarityBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxClarityBoostWeekly] = \(storedVal)")
        }
    }
    
    var useRegulatoryClarityMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegulatoryClarityMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useRegulatoryClarityMonthly
            if oldVal == newValue { return }
            print("didSet: useRegulatoryClarityMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegulatoryClarityMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useRegulatoryClarityMonthly")
            print("DEBUG: After toggling, userDefaults[useRegulatoryClarityMonthly] = \(storedVal)")
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
            print("didSet: maxClarityBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxClarityBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxClarityBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxClarityBoostMonthly] = \(storedVal)")
        }
    }
    
    var useEtfApprovalWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useEtfApprovalWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useEtfApprovalWeekly
            if oldVal == newValue { return }
            print("didSet: useEtfApprovalWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useEtfApprovalWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useEtfApprovalWeekly")
            print("DEBUG: After toggling, userDefaults[useEtfApprovalWeekly] = \(storedVal)")
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
            print("didSet: maxEtfBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxEtfBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxEtfBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxEtfBoostWeekly] = \(storedVal)")
        }
    }
    
    var useEtfApprovalMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useEtfApprovalMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useEtfApprovalMonthly
            if oldVal == newValue { return }
            print("didSet: useEtfApprovalMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useEtfApprovalMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useEtfApprovalMonthly")
            print("DEBUG: After toggling, userDefaults[useEtfApprovalMonthly] = \(storedVal)")
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
            print("didSet: maxEtfBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxEtfBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxEtfBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxEtfBoostMonthly] = \(storedVal)")
        }
    }
    
    var useTechBreakthroughWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useTechBreakthroughWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useTechBreakthroughWeekly
            if oldVal == newValue { return }
            print("didSet: useTechBreakthroughWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useTechBreakthroughWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useTechBreakthroughWeekly")
            print("DEBUG: After toggling, userDefaults[useTechBreakthroughWeekly] = \(storedVal)")
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
            print("didSet: maxTechBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxTechBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxTechBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxTechBoostWeekly] = \(storedVal)")
        }
    }
    
    var useTechBreakthroughMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useTechBreakthroughMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useTechBreakthroughMonthly
            if oldVal == newValue { return }
            print("didSet: useTechBreakthroughMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useTechBreakthroughMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useTechBreakthroughMonthly")
            print("DEBUG: After toggling, userDefaults[useTechBreakthroughMonthly] = \(storedVal)")
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
            print("didSet: maxTechBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxTechBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxTechBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxTechBoostMonthly] = \(storedVal)")
        }
    }
    
    var useScarcityEventsWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useScarcityEventsWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useScarcityEventsWeekly
            if oldVal == newValue { return }
            print("didSet: useScarcityEventsWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useScarcityEventsWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useScarcityEventsWeekly")
            print("DEBUG: After toggling, userDefaults[useScarcityEventsWeekly] = \(storedVal)")
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
            print("didSet: maxScarcityBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxScarcityBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxScarcityBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxScarcityBoostWeekly] = \(storedVal)")
        }
    }
    
    var useScarcityEventsMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useScarcityEventsMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useScarcityEventsMonthly
            if oldVal == newValue { return }
            print("didSet: useScarcityEventsMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useScarcityEventsMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useScarcityEventsMonthly")
            print("DEBUG: After toggling, userDefaults[useScarcityEventsMonthly] = \(storedVal)")
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
            print("didSet: maxScarcityBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxScarcityBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxScarcityBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxScarcityBoostMonthly] = \(storedVal)")
        }
    }
    
    var useGlobalMacroHedgeWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useGlobalMacroHedgeWeekly
            if oldVal == newValue { return }
            print("didSet: useGlobalMacroHedgeWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useGlobalMacroHedgeWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useGlobalMacroHedgeWeekly")
            print("DEBUG: After toggling, userDefaults[useGlobalMacroHedgeWeekly] = \(storedVal)")
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
            print("didSet: maxMacroBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMacroBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxMacroBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxMacroBoostWeekly] = \(storedVal)")
        }
    }
    
    var useGlobalMacroHedgeMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useGlobalMacroHedgeMonthly
            if oldVal == newValue { return }
            print("didSet: useGlobalMacroHedgeMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useGlobalMacroHedgeMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useGlobalMacroHedgeMonthly")
            print("DEBUG: After toggling, userDefaults[useGlobalMacroHedgeMonthly] = \(storedVal)")
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
            print("didSet: maxMacroBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMacroBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxMacroBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxMacroBoostMonthly] = \(storedVal)")
        }
    }
    
    var useStablecoinShiftWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinShiftWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useStablecoinShiftWeekly
            if oldVal == newValue { return }
            print("didSet: useStablecoinShiftWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinShiftWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useStablecoinShiftWeekly")
            print("DEBUG: After toggling, userDefaults[useStablecoinShiftWeekly] = \(storedVal)")
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
            print("didSet: maxStablecoinBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxStablecoinBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxStablecoinBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxStablecoinBoostWeekly] = \(storedVal)")
        }
    }
    
    var useStablecoinShiftMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinShiftMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useStablecoinShiftMonthly
            if oldVal == newValue { return }
            print("didSet: useStablecoinShiftMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinShiftMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useStablecoinShiftMonthly")
            print("DEBUG: After toggling, userDefaults[useStablecoinShiftMonthly] = \(storedVal)")
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
            print("didSet: maxStablecoinBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxStablecoinBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxStablecoinBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxStablecoinBoostMonthly] = \(storedVal)")
        }
    }
    
    var useDemographicAdoptionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useDemographicAdoptionWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useDemographicAdoptionWeekly
            if oldVal == newValue { return }
            print("didSet: useDemographicAdoptionWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useDemographicAdoptionWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useDemographicAdoptionWeekly")
            print("DEBUG: After toggling, userDefaults[useDemographicAdoptionWeekly] = \(storedVal)")
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
            print("didSet: maxDemoBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemoBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxDemoBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxDemoBoostWeekly] = \(storedVal)")
        }
    }
    
    var useDemographicAdoptionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useDemographicAdoptionMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useDemographicAdoptionMonthly
            if oldVal == newValue { return }
            print("didSet: useDemographicAdoptionMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useDemographicAdoptionMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useDemographicAdoptionMonthly")
            print("DEBUG: After toggling, userDefaults[useDemographicAdoptionMonthly] = \(storedVal)")
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
            print("didSet: maxDemoBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxDemoBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxDemoBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxDemoBoostMonthly] = \(storedVal)")
        }
    }
    
    var useAltcoinFlightWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAltcoinFlightWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useAltcoinFlightWeekly
            if oldVal == newValue { return }
            print("didSet: useAltcoinFlightWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAltcoinFlightWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useAltcoinFlightWeekly")
            print("DEBUG: After toggling, userDefaults[useAltcoinFlightWeekly] = \(storedVal)")
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
            print("didSet: maxAltcoinBoostWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxAltcoinBoostWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "maxAltcoinBoostWeekly")
            print("DEBUG: After updating, userDefaults[maxAltcoinBoostWeekly] = \(storedVal)")
        }
    }
    
    var useAltcoinFlightMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAltcoinFlightMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useAltcoinFlightMonthly
            if oldVal == newValue { return }
            print("didSet: useAltcoinFlightMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAltcoinFlightMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useAltcoinFlightMonthly")
            print("DEBUG: After toggling, userDefaults[useAltcoinFlightMonthly] = \(storedVal)")
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
            print("didSet: maxAltcoinBoostMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxAltcoinBoostMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "maxAltcoinBoostMonthly")
            print("DEBUG: After updating, userDefaults[maxAltcoinBoostMonthly] = \(storedVal)")
        }
    }
    
    var useAdoptionFactorWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAdoptionFactorWeekly") as? Bool ?? true
        }
        set {
            let oldVal = useAdoptionFactorWeekly
            if oldVal == newValue { return }
            print("didSet: useAdoptionFactorWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAdoptionFactorWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useAdoptionFactorWeekly")
            print("DEBUG: After toggling, userDefaults[useAdoptionFactorWeekly] = \(storedVal)")
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
            print("didSet: adoptionBaseFactorWeekly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "adoptionBaseFactorWeekly")
            let storedVal = UserDefaults.standard.double(forKey: "adoptionBaseFactorWeekly")
            print("DEBUG: After updating, userDefaults[adoptionBaseFactorWeekly] = \(storedVal)")
        }
    }
    
    var useAdoptionFactorMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAdoptionFactorMonthly") as? Bool ?? true
        }
        set {
            let oldVal = useAdoptionFactorMonthly
            if oldVal == newValue { return }
            print("didSet: useAdoptionFactorMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useAdoptionFactorMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useAdoptionFactorMonthly")
            print("DEBUG: After toggling, userDefaults[useAdoptionFactorMonthly] = \(storedVal)")
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
            print("didSet: adoptionBaseFactorMonthly changed to \(newValue).")
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "adoptionBaseFactorMonthly")
            let storedVal = UserDefaults.standard.double(forKey: "adoptionBaseFactorMonthly")
            print("DEBUG: After updating, userDefaults[adoptionBaseFactorMonthly] = \(storedVal)")
        }
    }
}
