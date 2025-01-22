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
            let oldValue = useHalvingWeekly
            print("didSet: useHalvingWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = halvingBumpWeekly
            print("didSet: halvingBumpWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "halvingBumpWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "halvingBumpWeekly")
                print("DEBUG: After updating, userDefaults[halvingBumpWeekly] = \(storedVal)")
            }
        }
    }
    
    var useHalvingMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useHalvingMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useHalvingMonthly
            print("didSet: useHalvingMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = halvingBumpMonthly
            print("didSet: halvingBumpMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "halvingBumpMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "halvingBumpMonthly")
                print("DEBUG: After updating, userDefaults[halvingBumpMonthly] = \(storedVal)")
            }
        }
    }
    
    var useInstitutionalDemandWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useInstitutionalDemandWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useInstitutionalDemandWeekly
            print("didSet: useInstitutionalDemandWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxDemandBoostWeekly
            print("didSet: maxDemandBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxDemandBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxDemandBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxDemandBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useInstitutionalDemandMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useInstitutionalDemandMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useInstitutionalDemandMonthly
            print("didSet: useInstitutionalDemandMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxDemandBoostMonthly
            print("didSet: maxDemandBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxDemandBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxDemandBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxDemandBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useCountryAdoptionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCountryAdoptionWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useCountryAdoptionWeekly
            print("didSet: useCountryAdoptionWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxCountryAdBoostWeekly
            print("didSet: maxCountryAdBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxCountryAdBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxCountryAdBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxCountryAdBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useCountryAdoptionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCountryAdoptionMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useCountryAdoptionMonthly
            print("didSet: useCountryAdoptionMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxCountryAdBoostMonthly
            print("didSet: maxCountryAdBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxCountryAdBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxCountryAdBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxCountryAdBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useRegulatoryClarityWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegulatoryClarityWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useRegulatoryClarityWeekly
            print("didSet: useRegulatoryClarityWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxClarityBoostWeekly
            print("didSet: maxClarityBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxClarityBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxClarityBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxClarityBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useRegulatoryClarityMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegulatoryClarityMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useRegulatoryClarityMonthly
            print("didSet: useRegulatoryClarityMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxClarityBoostMonthly
            print("didSet: maxClarityBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxClarityBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxClarityBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxClarityBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useEtfApprovalWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useEtfApprovalWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useEtfApprovalWeekly
            print("didSet: useEtfApprovalWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxEtfBoostWeekly
            print("didSet: maxEtfBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxEtfBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxEtfBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxEtfBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useEtfApprovalMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useEtfApprovalMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useEtfApprovalMonthly
            print("didSet: useEtfApprovalMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxEtfBoostMonthly
            print("didSet: maxEtfBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxEtfBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxEtfBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxEtfBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useTechBreakthroughWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useTechBreakthroughWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useTechBreakthroughWeekly
            print("didSet: useTechBreakthroughWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxTechBoostWeekly
            print("didSet: maxTechBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxTechBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxTechBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxTechBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useTechBreakthroughMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useTechBreakthroughMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useTechBreakthroughMonthly
            print("didSet: useTechBreakthroughMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxTechBoostMonthly
            print("didSet: maxTechBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxTechBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxTechBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxTechBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useScarcityEventsWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useScarcityEventsWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useScarcityEventsWeekly
            print("didSet: useScarcityEventsWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxScarcityBoostWeekly
            print("didSet: maxScarcityBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxScarcityBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxScarcityBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxScarcityBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useScarcityEventsMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useScarcityEventsMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useScarcityEventsMonthly
            print("didSet: useScarcityEventsMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxScarcityBoostMonthly
            print("didSet: maxScarcityBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxScarcityBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxScarcityBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxScarcityBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useGlobalMacroHedgeWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useGlobalMacroHedgeWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useGlobalMacroHedgeWeekly
            print("didSet: useGlobalMacroHedgeWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxMacroBoostWeekly
            print("didSet: maxMacroBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxMacroBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxMacroBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxMacroBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useGlobalMacroHedgeMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useGlobalMacroHedgeMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useGlobalMacroHedgeMonthly
            print("didSet: useGlobalMacroHedgeMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxMacroBoostMonthly
            print("didSet: maxMacroBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxMacroBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxMacroBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxMacroBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useStablecoinShiftWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinShiftWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useStablecoinShiftWeekly
            print("didSet: useStablecoinShiftWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxStablecoinBoostWeekly
            print("didSet: maxStablecoinBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxStablecoinBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxStablecoinBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxStablecoinBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useStablecoinShiftMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinShiftMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useStablecoinShiftMonthly
            print("didSet: useStablecoinShiftMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxStablecoinBoostMonthly
            print("didSet: maxStablecoinBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxStablecoinBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxStablecoinBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxStablecoinBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useDemographicAdoptionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useDemographicAdoptionWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useDemographicAdoptionWeekly
            print("didSet: useDemographicAdoptionWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxDemoBoostWeekly
            print("didSet: maxDemoBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxDemoBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxDemoBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxDemoBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useDemographicAdoptionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useDemographicAdoptionMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useDemographicAdoptionMonthly
            print("didSet: useDemographicAdoptionMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxDemoBoostMonthly
            print("didSet: maxDemoBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxDemoBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxDemoBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxDemoBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useAltcoinFlightWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAltcoinFlightWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useAltcoinFlightWeekly
            print("didSet: useAltcoinFlightWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxAltcoinBoostWeekly
            print("didSet: maxAltcoinBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxAltcoinBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxAltcoinBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxAltcoinBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useAltcoinFlightMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAltcoinFlightMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useAltcoinFlightMonthly
            print("didSet: useAltcoinFlightMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = maxAltcoinBoostMonthly
            print("didSet: maxAltcoinBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxAltcoinBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxAltcoinBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxAltcoinBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useAdoptionFactorWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAdoptionFactorWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useAdoptionFactorWeekly
            print("didSet: useAdoptionFactorWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = adoptionBaseFactorWeekly
            print("didSet: adoptionBaseFactorWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "adoptionBaseFactorWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "adoptionBaseFactorWeekly")
                print("DEBUG: After updating, userDefaults[adoptionBaseFactorWeekly] = \(storedVal)")
            }
        }
    }
    
    var useAdoptionFactorMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useAdoptionFactorMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useAdoptionFactorMonthly
            print("didSet: useAdoptionFactorMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
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
            let oldValue = adoptionBaseFactorMonthly
            print("didSet: adoptionBaseFactorMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "adoptionBaseFactorMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "adoptionBaseFactorMonthly")
                print("DEBUG: After updating, userDefaults[adoptionBaseFactorMonthly] = \(storedVal)")
            }
        }
    }
}
