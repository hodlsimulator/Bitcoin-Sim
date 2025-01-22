//
//  SimulationSettingsInit.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    convenience init(loadDefaults: Bool = true) {
        self.init()  // Calls the minimal init in SimulationSettings.swift
        guard loadDefaults else { return }

        let defaults = UserDefaults.standard

        // 1) Prevent didSet observers from triggering during bulk updates
        self.isUpdating = true

        // 2) MARK: - Load Basic Settings

        // Lognormal Growth
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            let val = defaults.bool(forKey: "useLognormalGrowth")
            self.useLognormalGrowth = val
        } else {
            self.useLognormalGrowth = true
        }

        // Onboarding Data
        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }

        // Period Settings
        if let savedPeriods = defaults.object(forKey: "savedUserPeriods") as? Int {
            self.userPeriods = savedPeriods
        }
        if let savedPeriodUnitRaw = defaults.string(forKey: "savedPeriodUnit"),
           let savedPeriodUnit = PeriodUnit(rawValue: savedPeriodUnitRaw) {
            self.periodUnit = savedPeriodUnit
        }
        if let savedBTCPrice = defaults.object(forKey: "savedInitialBTCPriceUSD") as? Double {
            self.initialBTCPriceUSD = savedBTCPrice
        }

        // Currency Preference
        if let storedPrefRaw = defaults.string(forKey: "currencyPreference"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            self.currencyPreference = storedPref
        } else {
            self.currencyPreference = .eur
        }

        // Random Seed
        let lockedSeedVal = defaults.bool(forKey: "lockedRandomSeed")
        self.lockedRandomSeed = lockedSeedVal

        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        let storedUseRandom = defaults.object(forKey: "useRandomSeed") as? Bool ?? true
        self.useRandomSeed = storedUseRandom

        // Sampling & Volatility
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            let val = defaults.bool(forKey: "useHistoricalSampling")
            self.useHistoricalSampling = val
        }
        if defaults.object(forKey: "useVolShocks") != nil {
            let val = defaults.bool(forKey: "useVolShocks")
            self.useVolShocks = val
        }
        if defaults.object(forKey: "useGarchVolatility") != nil {
            let val = defaults.bool(forKey: "useGarchVolatility")
            self.useGarchVolatility = val
        }

        // Autocorrelation
        if defaults.object(forKey: "useAutoCorrelation") != nil {
            let storedValue = defaults.bool(forKey: "useAutoCorrelation")
            self.useAutoCorrelation = storedValue
        }
        if defaults.object(forKey: "autoCorrelationStrength") != nil {
            let val = defaults.double(forKey: "autoCorrelationStrength")
            self.autoCorrelationStrength = val
        }
        if defaults.object(forKey: "meanReversionTarget") != nil {
            let val = defaults.double(forKey: "meanReversionTarget")
            self.meanReversionTarget = val
        }

        // Lock Historical Sampling
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            self.lockHistoricalSampling = savedLockSampling
        }

        // 3) MARK: - Remove loads of parent toggles (useHalving, etc.)
        // (All code that once loaded useHalving, useInstitutionalDemand, etc. is removed.)

        // 4) We can leave child toggles commented out or re-enable them if desired.
        //    For example:
        //    if let storedHalvingWeekly = defaults.object(forKey: "useHalvingWeekly") as? Bool {
        //        self.useHalvingWeekly = storedHalvingWeekly
        //    }
        //    ... etc. ...
        //
        // For now, they remain commented out to avoid reloading them from defaults:
        //    // if let storedHalvingWeekly = ...
        //    // ...
        
        // 7) Done loading from UserDefaults so far:
        self.isUpdating = false

        // 9) Sync or finalize toggles
        self.isInitialized = true
        finalizeToggleStateAfterLoad()
    }
}
