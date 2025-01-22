//
//  SimulationSettings+BearishFactors.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    // =============================
    // MARK: BEARISH FACTORS (weekly/monthly)
    // =============================
    
    var useRegClampdownWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegClampdownWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useRegClampdownWeekly
            print("didSet: useRegClampdownWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegClampdownWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useRegClampdownWeekly")
            print("DEBUG: After toggling, userDefaults[useRegClampdownWeekly] = \(storedVal)")
        }
    }
    
    var maxClampDownWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxClampDownWeekly") as? Double
            ?? SimulationSettings.defaultMaxClampDownWeekly
        }
        set {
            let oldValue = maxClampDownWeekly
            print("didSet: maxClampDownWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxClampDownWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxClampDownWeekly")
                print("DEBUG: After updating, userDefaults[maxClampDownWeekly] = \(storedVal)")
            }
        }
    }
    
    var useRegClampdownMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegClampdownMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useRegClampdownMonthly
            print("didSet: useRegClampdownMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegClampdownMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useRegClampdownMonthly")
            print("DEBUG: After toggling, userDefaults[useRegClampdownMonthly] = \(storedVal)")
        }
    }
    
    var maxClampDownMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxClampDownMonthly") as? Double
            ?? SimulationSettings.defaultMaxClampDownMonthly
        }
        set {
            let oldValue = maxClampDownMonthly
            print("didSet: maxClampDownMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxClampDownMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxClampDownMonthly")
                print("DEBUG: After updating, userDefaults[maxClampDownMonthly] = \(storedVal)")
            }
        }
    }
    
    var useCompetitorCoinWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCompetitorCoinWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useCompetitorCoinWeekly
            print("didSet: useCompetitorCoinWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCompetitorCoinWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useCompetitorCoinWeekly")
            print("DEBUG: After toggling, userDefaults[useCompetitorCoinWeekly] = \(storedVal)")
        }
    }
    
    var maxCompetitorBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxCompetitorBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxCompetitorBoostWeekly
        }
        set {
            let oldValue = maxCompetitorBoostWeekly
            print("didSet: maxCompetitorBoostWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxCompetitorBoostWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxCompetitorBoostWeekly")
                print("DEBUG: After updating, userDefaults[maxCompetitorBoostWeekly] = \(storedVal)")
            }
        }
    }
    
    var useCompetitorCoinMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCompetitorCoinMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useCompetitorCoinMonthly
            print("didSet: useCompetitorCoinMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCompetitorCoinMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useCompetitorCoinMonthly")
            print("DEBUG: After toggling, userDefaults[useCompetitorCoinMonthly] = \(storedVal)")
        }
    }
    
    var maxCompetitorBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxCompetitorBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxCompetitorBoostMonthly
        }
        set {
            let oldValue = maxCompetitorBoostMonthly
            print("didSet: maxCompetitorBoostMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxCompetitorBoostMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxCompetitorBoostMonthly")
                print("DEBUG: After updating, userDefaults[maxCompetitorBoostMonthly] = \(storedVal)")
            }
        }
    }
    
    var useSecurityBreachWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useSecurityBreachWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useSecurityBreachWeekly
            print("didSet: useSecurityBreachWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useSecurityBreachWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useSecurityBreachWeekly")
            print("DEBUG: After toggling, userDefaults[useSecurityBreachWeekly] = \(storedVal)")
        }
    }
    
    var breachImpactWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "breachImpactWeekly") as? Double
            ?? SimulationSettings.defaultBreachImpactWeekly
        }
        set {
            let oldValue = breachImpactWeekly
            print("didSet: breachImpactWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "breachImpactWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "breachImpactWeekly")
                print("DEBUG: After updating, userDefaults[breachImpactWeekly] = \(storedVal)")
            }
        }
    }
    
    var useSecurityBreachMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useSecurityBreachMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useSecurityBreachMonthly
            print("didSet: useSecurityBreachMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useSecurityBreachMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useSecurityBreachMonthly")
            print("DEBUG: After toggling, userDefaults[useSecurityBreachMonthly] = \(storedVal)")
        }
    }
    
    var breachImpactMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "breachImpactMonthly") as? Double
            ?? SimulationSettings.defaultBreachImpactMonthly
        }
        set {
            let oldValue = breachImpactMonthly
            print("didSet: breachImpactMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "breachImpactMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "breachImpactMonthly")
                print("DEBUG: After updating, userDefaults[breachImpactMonthly] = \(storedVal)")
            }
        }
    }
    
    var useBubblePopWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBubblePopWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useBubblePopWeekly
            print("didSet: useBubblePopWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBubblePopWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useBubblePopWeekly")
            print("DEBUG: After toggling, userDefaults[useBubblePopWeekly] = \(storedVal)")
        }
    }
    
    var maxPopDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxPopDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxPopDropWeekly
        }
        set {
            let oldValue = maxPopDropWeekly
            print("didSet: maxPopDropWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxPopDropWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxPopDropWeekly")
                print("DEBUG: After updating, userDefaults[maxPopDropWeekly] = \(storedVal)")
            }
        }
    }
    
    var useBubblePopMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBubblePopMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useBubblePopMonthly
            print("didSet: useBubblePopMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBubblePopMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useBubblePopMonthly")
            print("DEBUG: After toggling, userDefaults[useBubblePopMonthly] = \(storedVal)")
        }
    }
    
    var maxPopDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxPopDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxPopDropMonthly
        }
        set {
            let oldValue = maxPopDropMonthly
            print("didSet: maxPopDropMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxPopDropMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxPopDropMonthly")
                print("DEBUG: After updating, userDefaults[maxPopDropMonthly] = \(storedVal)")
            }
        }
    }
    
    var useStablecoinMeltdownWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinMeltdownWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useStablecoinMeltdownWeekly
            print("didSet: useStablecoinMeltdownWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinMeltdownWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useStablecoinMeltdownWeekly")
            print("DEBUG: After toggling, userDefaults[useStablecoinMeltdownWeekly] = \(storedVal)")
        }
    }
    
    var maxMeltdownDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMeltdownDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxMeltdownDropWeekly
        }
        set {
            let oldValue = maxMeltdownDropWeekly
            print("didSet: maxMeltdownDropWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxMeltdownDropWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxMeltdownDropWeekly")
                print("DEBUG: After updating, userDefaults[maxMeltdownDropWeekly] = \(storedVal)")
            }
        }
    }
    
    var useStablecoinMeltdownMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinMeltdownMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useStablecoinMeltdownMonthly
            print("didSet: useStablecoinMeltdownMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinMeltdownMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useStablecoinMeltdownMonthly")
            print("DEBUG: After toggling, userDefaults[useStablecoinMeltdownMonthly] = \(storedVal)")
        }
    }
    
    var maxMeltdownDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMeltdownDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxMeltdownDropMonthly
        }
        set {
            let oldValue = maxMeltdownDropMonthly
            print("didSet: maxMeltdownDropMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxMeltdownDropMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxMeltdownDropMonthly")
                print("DEBUG: After updating, userDefaults[maxMeltdownDropMonthly] = \(storedVal)")
            }
        }
    }
    
    var useBlackSwanWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBlackSwanWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useBlackSwanWeekly
            print("didSet: useBlackSwanWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBlackSwanWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useBlackSwanWeekly")
            print("DEBUG: After toggling, userDefaults[useBlackSwanWeekly] = \(storedVal)")
        }
    }
    
    var blackSwanDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "blackSwanDropWeekly") as? Double
            ?? SimulationSettings.defaultBlackSwanDropWeekly
        }
        set {
            let oldValue = blackSwanDropWeekly
            print("didSet: blackSwanDropWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "blackSwanDropWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "blackSwanDropWeekly")
                print("DEBUG: After updating, userDefaults[blackSwanDropWeekly] = \(storedVal)")
            }
        }
    }
    
    var useBlackSwanMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBlackSwanMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useBlackSwanMonthly
            print("didSet: useBlackSwanMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBlackSwanMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useBlackSwanMonthly")
            print("DEBUG: After toggling, userDefaults[useBlackSwanMonthly] = \(storedVal)")
        }
    }
    
    var blackSwanDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "blackSwanDropMonthly") as? Double
            ?? SimulationSettings.defaultBlackSwanDropMonthly
        }
        set {
            let oldValue = blackSwanDropMonthly
            print("didSet: blackSwanDropMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "blackSwanDropMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "blackSwanDropMonthly")
                print("DEBUG: After updating, userDefaults[blackSwanDropMonthly] = \(storedVal)")
            }
        }
    }
    
    var useBearMarketWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBearMarketWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useBearMarketWeekly
            print("didSet: useBearMarketWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBearMarketWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useBearMarketWeekly")
            print("DEBUG: After toggling, userDefaults[useBearMarketWeekly] = \(storedVal)")
        }
    }
    
    var bearWeeklyDriftWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "bearWeeklyDriftWeekly") as? Double
            ?? SimulationSettings.defaultBearWeeklyDriftWeekly
        }
        set {
            let oldValue = bearWeeklyDriftWeekly
            print("didSet: bearWeeklyDriftWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "bearWeeklyDriftWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "bearWeeklyDriftWeekly")
                print("DEBUG: After updating, userDefaults[bearWeeklyDriftWeekly] = \(storedVal)")
            }
        }
    }
    
    var useBearMarketMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBearMarketMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useBearMarketMonthly
            print("didSet: useBearMarketMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBearMarketMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useBearMarketMonthly")
            print("DEBUG: After toggling, userDefaults[useBearMarketMonthly] = \(storedVal)")
        }
    }
    
    var bearWeeklyDriftMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "bearWeeklyDriftMonthly") as? Double
            ?? SimulationSettings.defaultBearWeeklyDriftMonthly
        }
        set {
            let oldValue = bearWeeklyDriftMonthly
            print("didSet: bearWeeklyDriftMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "bearWeeklyDriftMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "bearWeeklyDriftMonthly")
                print("DEBUG: After updating, userDefaults[bearWeeklyDriftMonthly] = \(storedVal)")
            }
        }
    }
    
    var useMaturingMarketWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useMaturingMarketWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useMaturingMarketWeekly
            print("didSet: useMaturingMarketWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useMaturingMarketWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useMaturingMarketWeekly")
            print("DEBUG: After toggling, userDefaults[useMaturingMarketWeekly] = \(storedVal)")
        }
    }
    
    var maxMaturingDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMaturingDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxMaturingDropWeekly
        }
        set {
            let oldValue = maxMaturingDropWeekly
            print("didSet: maxMaturingDropWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxMaturingDropWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxMaturingDropWeekly")
                print("DEBUG: After updating, userDefaults[maxMaturingDropWeekly] = \(storedVal)")
            }
        }
    }
    
    var useMaturingMarketMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useMaturingMarketMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useMaturingMarketMonthly
            print("didSet: useMaturingMarketMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useMaturingMarketMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useMaturingMarketMonthly")
            print("DEBUG: After toggling, userDefaults[useMaturingMarketMonthly] = \(storedVal)")
        }
    }
    
    var maxMaturingDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMaturingDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxMaturingDropMonthly
        }
        set {
            let oldValue = maxMaturingDropMonthly
            print("didSet: maxMaturingDropMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxMaturingDropMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxMaturingDropMonthly")
                print("DEBUG: After updating, userDefaults[maxMaturingDropMonthly] = \(storedVal)")
            }
        }
    }
    
    var useRecessionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRecessionWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useRecessionWeekly
            print("didSet: useRecessionWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRecessionWeekly")
            let storedVal = UserDefaults.standard.bool(forKey: "useRecessionWeekly")
            print("DEBUG: After toggling, userDefaults[useRecessionWeekly] = \(storedVal)")
        }
    }
    
    var maxRecessionDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxRecessionDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxRecessionDropWeekly
        }
        set {
            let oldValue = maxRecessionDropWeekly
            print("didSet: maxRecessionDropWeekly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxRecessionDropWeekly")
                let storedVal = UserDefaults.standard.double(forKey: "maxRecessionDropWeekly")
                print("DEBUG: After updating, userDefaults[maxRecessionDropWeekly] = \(storedVal)")
            }
        }
    }
    
    var useRecessionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRecessionMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useRecessionMonthly
            print("didSet: useRecessionMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            guard isInitialized, oldValue != newValue else { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRecessionMonthly")
            let storedVal = UserDefaults.standard.bool(forKey: "useRecessionMonthly")
            print("DEBUG: After toggling, userDefaults[useRecessionMonthly] = \(storedVal)")
        }
    }
    
    var maxRecessionDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxRecessionDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxRecessionDropMonthly
        }
        set {
            let oldValue = maxRecessionDropMonthly
            print("didSet: maxRecessionDropMonthly changed to \(newValue). isInitialized=\(isInitialized), isUpdating=\(isUpdating)")
            if isInitialized && oldValue != newValue {
                objectWillChange.send()
                UserDefaults.standard.set(newValue, forKey: "maxRecessionDropMonthly")
                let storedVal = UserDefaults.standard.double(forKey: "maxRecessionDropMonthly")
                print("DEBUG: After updating, userDefaults[maxRecessionDropMonthly] = \(storedVal)")
            }
        }
    }
}
