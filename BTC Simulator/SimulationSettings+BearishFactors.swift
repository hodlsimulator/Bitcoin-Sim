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
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegClampdownWeekly")
        }
    }
    
    var maxClampDownWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxClampDownWeekly") as? Double
            ?? SimulationSettings.defaultMaxClampDownWeekly
        }
        set {
            let oldVal = maxClampDownWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxClampDownWeekly")
        }
    }
    
    var useRegClampdownMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRegClampdownMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useRegClampdownMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRegClampdownMonthly")
        }
    }
    
    var maxClampDownMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxClampDownMonthly") as? Double
            ?? SimulationSettings.defaultMaxClampDownMonthly
        }
        set {
            let oldVal = maxClampDownMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxClampDownMonthly")
        }
    }
    
    var useCompetitorCoinWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCompetitorCoinWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useCompetitorCoinWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCompetitorCoinWeekly")
        }
    }
    
    var maxCompetitorBoostWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxCompetitorBoostWeekly") as? Double
            ?? SimulationSettings.defaultMaxCompetitorBoostWeekly
        }
        set {
            let oldVal = maxCompetitorBoostWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxCompetitorBoostWeekly")
        }
    }
    
    var useCompetitorCoinMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useCompetitorCoinMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useCompetitorCoinMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useCompetitorCoinMonthly")
        }
    }
    
    var maxCompetitorBoostMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxCompetitorBoostMonthly") as? Double
            ?? SimulationSettings.defaultMaxCompetitorBoostMonthly
        }
        set {
            let oldVal = maxCompetitorBoostMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxCompetitorBoostMonthly")
        }
    }
    
    var useSecurityBreachWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useSecurityBreachWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useSecurityBreachWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useSecurityBreachWeekly")
        }
    }
    
    var breachImpactWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "breachImpactWeekly") as? Double
            ?? SimulationSettings.defaultBreachImpactWeekly
        }
        set {
            let oldVal = breachImpactWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "breachImpactWeekly")
        }
    }
    
    var useSecurityBreachMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useSecurityBreachMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useSecurityBreachMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useSecurityBreachMonthly")
        }
    }
    
    var breachImpactMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "breachImpactMonthly") as? Double
            ?? SimulationSettings.defaultBreachImpactMonthly
        }
        set {
            let oldVal = breachImpactMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "breachImpactMonthly")
        }
    }
    
    var useBubblePopWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBubblePopWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useBubblePopWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBubblePopWeekly")
        }
    }
    
    var maxPopDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxPopDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxPopDropWeekly
        }
        set {
            let oldVal = maxPopDropWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxPopDropWeekly")
        }
    }
    
    var useBubblePopMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBubblePopMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useBubblePopMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBubblePopMonthly")
        }
    }
    
    var maxPopDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxPopDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxPopDropMonthly
        }
        set {
            let oldVal = maxPopDropMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxPopDropMonthly")
        }
    }
    
    var useStablecoinMeltdownWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinMeltdownWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useStablecoinMeltdownWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinMeltdownWeekly")
        }
    }
    
    var maxMeltdownDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMeltdownDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxMeltdownDropWeekly
        }
        set {
            let oldVal = maxMeltdownDropWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMeltdownDropWeekly")
        }
    }
    
    var useStablecoinMeltdownMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useStablecoinMeltdownMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useStablecoinMeltdownMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useStablecoinMeltdownMonthly")
        }
    }
    
    var maxMeltdownDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMeltdownDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxMeltdownDropMonthly
        }
        set {
            let oldVal = maxMeltdownDropMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMeltdownDropMonthly")
        }
    }
    
    var useBlackSwanWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBlackSwanWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useBlackSwanWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBlackSwanWeekly")
        }
    }
    
    var blackSwanDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "blackSwanDropWeekly") as? Double
            ?? SimulationSettings.defaultBlackSwanDropWeekly
        }
        set {
            let oldVal = blackSwanDropWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "blackSwanDropWeekly")
        }
    }
    
    var useBlackSwanMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBlackSwanMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useBlackSwanMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBlackSwanMonthly")
        }
    }
    
    var blackSwanDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "blackSwanDropMonthly") as? Double
            ?? SimulationSettings.defaultBlackSwanDropMonthly
        }
        set {
            let oldVal = blackSwanDropMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "blackSwanDropMonthly")
        }
    }
    
    var useBearMarketWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBearMarketWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useBearMarketWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBearMarketWeekly")
        }
    }
    
    var bearWeeklyDriftWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "bearWeeklyDriftWeekly") as? Double
            ?? SimulationSettings.defaultBearWeeklyDriftWeekly
        }
        set {
            let oldVal = bearWeeklyDriftWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "bearWeeklyDriftWeekly")
        }
    }
    
    var useBearMarketMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useBearMarketMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useBearMarketMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useBearMarketMonthly")
        }
    }
    
    var bearWeeklyDriftMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "bearWeeklyDriftMonthly") as? Double
            ?? SimulationSettings.defaultBearWeeklyDriftMonthly
        }
        set {
            let oldVal = bearWeeklyDriftMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "bearWeeklyDriftMonthly")
        }
    }
    
    var useMaturingMarketWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useMaturingMarketWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useMaturingMarketWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useMaturingMarketWeekly")
        }
    }
    
    var maxMaturingDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMaturingDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxMaturingDropWeekly
        }
        set {
            let oldVal = maxMaturingDropWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMaturingDropWeekly")
        }
    }
    
    var useMaturingMarketMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useMaturingMarketMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useMaturingMarketMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useMaturingMarketMonthly")
        }
    }
    
    var maxMaturingDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxMaturingDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxMaturingDropMonthly
        }
        set {
            let oldVal = maxMaturingDropMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxMaturingDropMonthly")
        }
    }
    
    var useRecessionWeekly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRecessionWeekly") as? Bool ?? true
        }
        set {
            let oldValue = useRecessionWeekly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRecessionWeekly")
        }
    }
    
    var maxRecessionDropWeekly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxRecessionDropWeekly") as? Double
            ?? SimulationSettings.defaultMaxRecessionDropWeekly
        }
        set {
            let oldVal = maxRecessionDropWeekly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxRecessionDropWeekly")
        }
    }
    
    var useRecessionMonthly: Bool {
        get {
            UserDefaults.standard.object(forKey: "useRecessionMonthly") as? Bool ?? true
        }
        set {
            let oldValue = useRecessionMonthly
            if oldValue == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "useRecessionMonthly")
        }
    }
    
    var maxRecessionDropMonthly: Double {
        get {
            UserDefaults.standard.object(forKey: "maxRecessionDropMonthly") as? Double
            ?? SimulationSettings.defaultMaxRecessionDropMonthly
        }
        set {
            let oldVal = maxRecessionDropMonthly
            if oldVal == newValue { return }
            objectWillChange.send()
            UserDefaults.standard.set(newValue, forKey: "maxRecessionDropMonthly")
        }
    }
}
