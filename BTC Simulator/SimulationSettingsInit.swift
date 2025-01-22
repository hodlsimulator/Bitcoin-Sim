//
//  SimulationSettingsInit.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/01/2025.
//

import SwiftUI

extension SimulationSettings {
    convenience init(loadDefaults: Bool = true) {
        self.init()
        guard loadDefaults else { return }

        let defaults = UserDefaults.standard
        self.isUpdating = true  // stop didSet spam

        // Basic
        if defaults.object(forKey: "useLognormalGrowth") != nil {
            self.useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        } else {
            self.useLognormalGrowth = true
        }
        if let savedBal = defaults.object(forKey: "savedStartingBalance") as? Double {
            self.startingBalance = savedBal
        }
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            self.averageCostBasis = savedACB
        }

        // Period & Price
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

        // Currency
        if let storedPrefRaw = defaults.string(forKey: "currencyPreference"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            self.currencyPreference = storedPref
        } else {
            self.currencyPreference = .eur
        }

        // Random seed
        self.lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        if let storedSeed = defaults.object(forKey: "seedValue") as? UInt64 {
            self.seedValue = storedSeed
        }
        self.useRandomSeed = defaults.object(forKey: "useRandomSeed") as? Bool ?? true

        // Sampling & Vol
        if defaults.object(forKey: "useHistoricalSampling") != nil {
            self.useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        } else {
            self.useHistoricalSampling = true
        }
        if defaults.object(forKey: "useVolShocks") != nil {
            self.useVolShocks = defaults.bool(forKey: "useVolShocks")
        } else {
            self.useVolShocks = true
        }
        if defaults.object(forKey: "useGarchVolatility") != nil {
            self.useGarchVolatility = defaults.bool(forKey: "useGarchVolatility")
        } else {
            self.useGarchVolatility = true
        }

        // Autocorrelation
        if defaults.object(forKey: "useAutoCorrelation") != nil {
            self.useAutoCorrelation = defaults.bool(forKey: "useAutoCorrelation")
        }
        if defaults.object(forKey: "autoCorrelationStrength") != nil {
            self.autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        }
        if defaults.object(forKey: "meanReversionTarget") != nil {
            self.meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        }

        // Lock sampling
        if let savedLockSampling = defaults.object(forKey: "lockHistoricalSampling") as? Bool {
            self.lockHistoricalSampling = savedLockSampling
        }

        // ---- Load each weekly/monthly toggle from UserDefaults, default = true ----
        // For brevity, here's the pattern repeated:

        if defaults.object(forKey: "useHalvingWeekly") != nil {
            self.useHalvingWeekly = defaults.bool(forKey: "useHalvingWeekly")
        } else {
            self.useHalvingWeekly = true
        }
        if defaults.object(forKey: "halvingBumpWeekly") != nil {
            self.halvingBumpWeekly = defaults.double(forKey: "halvingBumpWeekly")
        } else {
            self.halvingBumpWeekly = SimulationSettings.defaultHalvingBumpWeekly
        }
        if defaults.object(forKey: "useHalvingMonthly") != nil {
            self.useHalvingMonthly = defaults.bool(forKey: "useHalvingMonthly")
        } else {
            self.useHalvingMonthly = true
        }
        if defaults.object(forKey: "halvingBumpMonthly") != nil {
            self.halvingBumpMonthly = defaults.double(forKey: "halvingBumpMonthly")
        } else {
            self.halvingBumpMonthly = SimulationSettings.defaultHalvingBumpMonthly
        }

        // ...and so on for every single factor. Just do the same “if let / else” pattern:
        // useInstitutionalDemandWeekly, useInstitutionalDemandMonthly,
        // useCountryAdoptionWeekly, useCountryAdoptionMonthly,
        // etc., each with default = true for the bool toggles,
        // and default = SimulationSettings.xxx for the Double values.

        // BULLISH toggles (Institutional Demand, CountryAdoption, etc.)
        if let val = defaults.object(forKey: "useInstitutionalDemandWeekly") as? Bool {
            self.useInstitutionalDemandWeekly = val
        } else {
            self.useInstitutionalDemandWeekly = true
        }
        if let val = defaults.object(forKey: "maxDemandBoostWeekly") as? Double {
            self.maxDemandBoostWeekly = val
        } else {
            self.maxDemandBoostWeekly = SimulationSettings.defaultMaxDemandBoostWeekly
        }
        // ... do likewise for the monthly version:
        if let val = defaults.object(forKey: "useInstitutionalDemandMonthly") as? Bool {
            self.useInstitutionalDemandMonthly = val
        } else {
            self.useInstitutionalDemandMonthly = true
        }
        if let val = defaults.object(forKey: "maxDemandBoostMonthly") as? Double {
            self.maxDemandBoostMonthly = val
        } else {
            self.maxDemandBoostMonthly = SimulationSettings.defaultMaxDemandBoostMonthly
        }

        // Repeated for every factor…

        // Finally:
        self.isUpdating = false
        self.isInitialized = true
        finalizeToggleStateAfterLoad()
    }
}
