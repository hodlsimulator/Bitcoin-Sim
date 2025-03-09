//
//  MonthlySimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 10/02/2025.
//

import SwiftUI
import GameplayKit

class MonthlySimulationSettings: ObservableObject {
    
    // MARK: - Monthly Keys & Dictionaries
    let bearishKeysMonthly: [String] = [
        "RegClampdown", "CompetitorCoin", "SecurityBreach",
        "BubblePop", "StablecoinMeltdown", "BlackSwan",
        "BearMarket", "MaturingMarket", "Recession"
    ]
    
    // These tilt dictionaries mirror the weekly ones but may have adjusted values.
    static let bullishTiltValuesMonthly: [String: Double] = [
        "halving":            25.41,
        "institutionaldemand": 8.30,
        "countryadoption":     8.19,
        "regulatoryclarity":   7.46,
        "etfapproval":         8.94,
        "techbreakthrough":    7.20,
        "scarcityevents":      6.66,
        "globalmacrohedge":    6.43,
        "stablecoinshift":     6.37,
        "demographicadoption": 8.06,
        "altcoinflight":       6.19,
        "adoptionfactor":      8.75
    ]
    
    static let bearishTiltValuesMonthly: [String: Double] = [
        "regclampdown":       9.66,
        "competitorcoin":     9.46,
        "securitybreach":     9.60,
        "bubblepop":         10.57,
        "stablecoinmeltdown": 8.79,
        "blackswan":         31.21,
        "bearmarket":         9.18,
        "maturingmarket":    10.29,
        "recession":          9.22
    ]
    
    // MARK: - Published Properties
    @Published var feePercentageMonthly: Double = 0.6
    @Published var suspendUnifiedUpdates: Bool = false
    
    @Published var chartExtremeBearishMonthly: Bool = false
    @Published var chartExtremeBullishMonthly: Bool = false
    @Published var isRestoringDefaultsMonthly: Bool = false
    
    @Published var factorsMonthly: [String: FactorState] = [:]
    @Published var lockedFactorsMonthly: Set<String> = []
    
    @Published var rawFactorIntensityMonthly: Double {
        didSet {
            UserDefaults.standard.set(rawFactorIntensityMonthly, forKey: "rawFactorIntensityMonthly")
            if !ignoreSyncMonthly { syncFactorsMonthly() }
        }
    }
    var ignoreSyncMonthly: Bool = false
    
    @Published var overrodeTiltManuallyMonthly = false
    @Published var tiltBarValueMonthly: Double = 0.0
    @Published var userIsActuallyTogglingAllMonthly = false {
        didSet {
            if !userIsActuallyTogglingAllMonthly { resetTiltBarMonthly() }
        }
    }
    @Published var defaultTiltMonthly: Double = 0.0
    @Published var maxSwingMonthly: Double = 1.0
    @Published var hasCapturedDefaultMonthly: Bool = false
    @Published var isOnboardingMonthly: Bool = false
    
    @Published var periodUnitMonthly: PeriodUnit = .months
    @Published var userPeriodsMonthly: Int = 12
    @Published var initialBTCPriceUSDMonthly: Double = 30000.0
    @Published var startingBalanceMonthly: Double = 0.0
    @Published var averageCostBasisMonthly: Double = 25000.0
    
    @Published var currencyPreferenceMonthly: PreferredCurrency = .eur {
        didSet {
            if isInitializedMonthly {
                UserDefaults.standard.set(currencyPreferenceMonthly.rawValue, forKey: "currencyPreferenceMonthly")
            }
        }
    }
    @Published var extendedGlobalValueMonthly: Double = 0.0 {
        didSet {
            // Clamp to [-108, +108]
            if extendedGlobalValueMonthly < -108.0 { extendedGlobalValueMonthly = -108.0 }
            if extendedGlobalValueMonthly > 108.0  { extendedGlobalValueMonthly = 108.0 }

            // Convert sum to [0..1]
            let newRaw = (extendedGlobalValueMonthly + 108.0) / 216.0

            // Only update rawFactorIntensityMonthly if it changed
            if abs(newRaw - rawFactorIntensityMonthly) > 1e-9 {
                ignoreSyncMonthly = true
                rawFactorIntensityMonthly = newRaw
                ignoreSyncMonthly = false
            }
        }
    }
    @Published var contributionCurrencyWhenBothMonthly: PreferredCurrency = .eur
    @Published var startingBalanceCurrencyWhenBothMonthly: PreferredCurrency = .usd
    @Published var lastRunResultsMonthly: [SimulationData] = []
    @Published var allRunsMonthly: [[SimulationData]] = []
    
    var isInitializedMonthly = false
    var isUpdatingMonthly = false
    var isIndividualChangeMonthly = false
    
    // MARK: - Advanced Toggles (Monthly)
    @Published var useLognormalGrowthMonthly: Bool = true {
        didSet {
            if isInitializedMonthly {
                UserDefaults.standard.set(useLognormalGrowthMonthly, forKey: "useLognormalGrowthMonthly")
                if !useLognormalGrowthMonthly { useAnnualStepMonthly = true }
            }
        }
    }
    @Published var useAnnualStepMonthly: Bool = false {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useAnnualStepMonthly, forKey: "useAnnualStepMonthly") }
        }
    }
    @Published var lockedRandomSeedMonthly: Bool = false {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(lockedRandomSeedMonthly, forKey: "lockedRandomSeedMonthly") }
        }
    }
    @Published var seedValueMonthly: UInt64 = 0 {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(seedValueMonthly, forKey: "seedValueMonthly") }
        }
    }
    @Published var useRandomSeedMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useRandomSeedMonthly, forKey: "useRandomSeedMonthly") }
        }
    }
    @Published var useHistoricalSamplingMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useHistoricalSamplingMonthly, forKey: "useHistoricalSamplingMonthly") }
        }
    }
    @Published var useExtendedHistoricalSamplingMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useExtendedHistoricalSamplingMonthly, forKey: "useExtendedHistoricalSamplingMonthly") }
        }
    }
    @Published var useVolShocksMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useVolShocksMonthly, forKey: "useVolShocksMonthly") }
        }
    }
    @Published var useGarchVolatilityMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useGarchVolatilityMonthly, forKey: "useGarchVolatilityMonthly") }
        }
    }
    @Published var useAutoCorrelationMonthly: Bool = true {
        didSet {
            if isInitializedMonthly {
                UserDefaults.standard.set(useAutoCorrelationMonthly, forKey: "useAutoCorrelationMonthly")
                if !useAutoCorrelationMonthly { useMeanReversionMonthly = false }
            }
        }
    }
    @Published var autoCorrelationStrengthMonthly: Double = 0.05 {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(autoCorrelationStrengthMonthly, forKey: "autoCorrelationStrengthMonthly") }
        }
    }
    @Published var meanReversionTargetMonthly: Double = 0.03 {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(meanReversionTargetMonthly, forKey: "meanReversionTargetMonthly") }
        }
    }
    @Published var useMeanReversionMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useMeanReversionMonthly, forKey: "useMeanReversionMonthly") }
        }
    }
    @Published var lastUsedSeedMonthly: UInt64 = 0
    @Published var lockHistoricalSamplingMonthly: Bool = false {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(lockHistoricalSamplingMonthly, forKey: "lockHistoricalSamplingMonthly") }
        }
    }
    @Published var useRegimeSwitchingMonthly: Bool = true {
        didSet {
            if isInitializedMonthly { UserDefaults.standard.set(useRegimeSwitchingMonthly, forKey: "useRegimeSwitchingMonthly") }
        }
    }
    
    // Persistence Keys
    let defaultTiltKeyMonthly = "defaultTiltMonthly"
    let maxSwingKeyMonthly = "maxSwingMonthly"
    let hasCapturedDefaultKeyMonthly = "capturedTiltMonthly"
    let tiltBarValueKeyMonthly = "tiltBarValueMonthly"
    let periodUnitKeyMonthly = "savedPeriodUnitMonthly"
    
    // MARK: - Init
    init(loadDefaults: Bool = true) {
        if let savedIntensity = UserDefaults.standard.object(forKey: "rawFactorIntensityMonthly") as? Double {
            rawFactorIntensityMonthly = savedIntensity
        } else {
            rawFactorIntensityMonthly = 0.5
        }
        
        isUpdatingMonthly = false
        isInitializedMonthly = false
        
        if loadDefaults {
            loadFromUserDefaultsMonthly()
        }
        
        if !hasCapturedDefaultMonthly {
            defaultTiltMonthly = 0.0
            maxSwingMonthly = 1.0
            hasCapturedDefaultMonthly = true
            saveTiltStateMonthly()
        }
        
        isInitializedMonthly = true
    }
    
    func lockFactorAtMinMonthly(_ factorName: String) {
        guard var factor = factorsMonthly[factorName] else { return }
        factor.currentValue = factor.minValue
        let base = globalBaselineMonthly(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (factor.minValue - base) / range
        factor.wasChartForced = true
        factor.isEnabled = false
        factor.isLocked = true
        lockedFactorsMonthly.insert(factorName)
        factorsMonthly[factorName] = factor
    }

    func lockFactorAtMaxMonthly(_ factorName: String) {
        guard var factor = factorsMonthly[factorName] else { return }
        factor.currentValue = factor.maxValue
        let base = globalBaselineMonthly(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (factor.maxValue - base) / range
        factor.wasChartForced = true
        factor.isEnabled = false
        factor.isLocked = true
        lockedFactorsMonthly.insert(factorName)
        factorsMonthly[factorName] = factor
    }

    func unlockFactorAndSetMinMonthly(_ factorName: String) {
        guard var factor = factorsMonthly[factorName] else { return }
        factor.currentValue = factor.minValue
        let base = globalBaselineMonthly(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (factor.minValue - base) / range
        factor.isEnabled = true
        factor.isLocked = false
        factor.wasChartForced = false
        lockedFactorsMonthly.remove(factorName)
        factorsMonthly[factorName] = factor
    }

    func unlockFactorAndSetMaxMonthly(_ factorName: String) {
        guard var factor = factorsMonthly[factorName] else { return }
        factor.currentValue = factor.maxValue
        let base = globalBaselineMonthly(for: factor)
        let range = factor.maxValue - factor.minValue
        factor.internalOffset = (factor.maxValue - base) / range
        factor.isEnabled = true
        factor.isLocked = false
        factor.wasChartForced = false
        lockedFactorsMonthly.remove(factorName)
        factorsMonthly[factorName] = factor
    }
    
    // MARK: - Loading & Saving (Monthly)
    func loadFromUserDefaultsMonthly() {
        let defaults = UserDefaults.standard
        isInitializedMonthly = false
        
        // Advanced toggles
        useLognormalGrowthMonthly = defaults.bool(forKey: "useLognormalGrowthMonthly")
        lockedRandomSeedMonthly   = defaults.bool(forKey: "lockedRandomSeedMonthly")
        seedValueMonthly          = defaults.object(forKey: "seedValueMonthly") as? UInt64 ?? 0
        useRandomSeedMonthly      = defaults.bool(forKey: "useRandomSeedMonthly")
        useHistoricalSamplingMonthly = defaults.bool(forKey: "useHistoricalSamplingMonthly")
        useVolShocksMonthly       = defaults.bool(forKey: "useVolShocksMonthly")
        useGarchVolatilityMonthly = defaults.bool(forKey: "useGarchVolatilityMonthly")
        if defaults.object(forKey: "useAutoCorrelationMonthly") == nil {
            useAutoCorrelationMonthly = true
        } else {
            useAutoCorrelationMonthly = defaults.bool(forKey: "useAutoCorrelationMonthly")
        }
        if defaults.object(forKey: "autoCorrelationStrengthMonthly") == nil {
            autoCorrelationStrengthMonthly = 0.05
        } else {
            autoCorrelationStrengthMonthly = defaults.double(forKey: "autoCorrelationStrengthMonthly")
        }
        if defaults.object(forKey: "meanReversionTargetMonthly") == nil {
            meanReversionTargetMonthly = 0.03
        } else {
            meanReversionTargetMonthly = defaults.double(forKey: "meanReversionTargetMonthly")
        }
        if defaults.object(forKey: "useMeanReversionMonthly") == nil {
            useMeanReversionMonthly = true
        } else {
            useMeanReversionMonthly = defaults.bool(forKey: "useMeanReversionMonthly")
        }
        if defaults.object(forKey: "useRegimeSwitchingMonthly") == nil {
            useRegimeSwitchingMonthly = true
        } else {
            useRegimeSwitchingMonthly = defaults.bool(forKey: "useRegimeSwitchingMonthly")
        }
        if defaults.object(forKey: "useExtendedHistoricalSamplingMonthly") == nil {
            useExtendedHistoricalSamplingMonthly = true
        } else {
            useExtendedHistoricalSamplingMonthly = defaults.bool(forKey: "useExtendedHistoricalSamplingMonthly")
        }
        
        // Tilt bar values
        if let dt = defaults.object(forKey: defaultTiltKeyMonthly) as? Double {
            defaultTiltMonthly = dt
        }
        if let ms = defaults.object(forKey: maxSwingKeyMonthly) as? Double {
            maxSwingMonthly = ms
        }
        if let hc = defaults.object(forKey: hasCapturedDefaultKeyMonthly) as? Bool {
            hasCapturedDefaultMonthly = hc
        }
        if let tv = defaults.object(forKey: tiltBarValueKeyMonthly) as? Double {
            tiltBarValueMonthly = tv
        }
        
        // Monthly period and price/balance
        if let savedPeriods = defaults.object(forKey: "savedUserPeriodsMonthly") as? Int {
            userPeriodsMonthly = savedPeriods
        }
        if let savedBTCMonthly = defaults.object(forKey: "savedInitialBTCPriceUSDMonthly") as? Double {
            initialBTCPriceUSDMonthly = savedBTCMonthly
        }
        if let savedBalanceMonthly = defaults.object(forKey: "savedStartingBalanceMonthly") as? Double {
            startingBalanceMonthly = savedBalanceMonthly
        }
        if let savedACBMonthly = defaults.object(forKey: "savedAverageCostBasisMonthly") as? Double {
            averageCostBasisMonthly = savedACBMonthly
        }
        
        // Currency preference
        if let storedPrefRaw = defaults.string(forKey: "currencyPreferenceMonthly"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            currencyPreferenceMonthly = storedPref
        } else {
            currencyPreferenceMonthly = .eur
        }
        
        // Period unit
        if let rawPU = defaults.string(forKey: periodUnitKeyMonthly),
           let loadedPU = PeriodUnit(rawValue: rawPU) {
            periodUnitMonthly = loadedPU
        } else {
            periodUnitMonthly = .months
        }
        
        // Factor states
        if let savedFactorData = defaults.data(forKey: "factorStatesMonthly"),
           let savedFactors = try? JSONDecoder().decode([String: FactorState].self, from: savedFactorData) {
            factorsMonthly = savedFactors
        } else {
            factorsMonthly.removeAll()
            for (factorName, def) in FactorCatalog.all {
                let (minVal, midVal, maxVal) = (def.minMonthly, def.midMonthly, def.maxMonthly)
                let fs = FactorState(
                    name: factorName,
                    currentValue: midVal,
                    defaultValue: midVal,
                    minValue: minVal,
                    maxValue: maxVal,
                    isEnabled: true,
                    isLocked: false
                )
                factorsMonthly[factorName] = fs
            }
        }
        
        isInitializedMonthly = true
    }
    
    func saveToUserDefaultsMonthly() {
        let defaults = UserDefaults.standard
        defaults.set(useLognormalGrowthMonthly, forKey: "useLognormalGrowthMonthly")
        defaults.set(lockedRandomSeedMonthly, forKey: "lockedRandomSeedMonthly")
        defaults.set(seedValueMonthly, forKey: "seedValueMonthly")
        defaults.set(useRandomSeedMonthly, forKey: "useRandomSeedMonthly")
        defaults.set(useHistoricalSamplingMonthly, forKey: "useHistoricalSamplingMonthly")
        defaults.set(useVolShocksMonthly, forKey: "useVolShocksMonthly")
        defaults.set(useGarchVolatilityMonthly, forKey: "useGarchVolatilityMonthly")
        defaults.set(useAutoCorrelationMonthly, forKey: "useAutoCorrelationMonthly")
        defaults.set(autoCorrelationStrengthMonthly, forKey: "autoCorrelationStrengthMonthly")
        defaults.set(meanReversionTargetMonthly, forKey: "meanReversionTargetMonthly")
        defaults.set(useMeanReversionMonthly, forKey: "useMeanReversionMonthly")
        defaults.set(useRegimeSwitchingMonthly, forKey: "useRegimeSwitchingMonthly")
        defaults.set(useExtendedHistoricalSamplingMonthly, forKey: "useExtendedHistoricalSamplingMonthly")
        defaults.set(lockHistoricalSamplingMonthly, forKey: "lockHistoricalSamplingMonthly")
        defaults.set(currencyPreferenceMonthly.rawValue, forKey: "currencyPreferenceMonthly")
        
        defaults.set(periodUnitMonthly.rawValue, forKey: periodUnitKeyMonthly)
        defaults.set(userPeriodsMonthly, forKey: "savedUserPeriodsMonthly")
        defaults.set(initialBTCPriceUSDMonthly, forKey: "savedInitialBTCPriceUSDMonthly")
        defaults.set(startingBalanceMonthly, forKey: "savedStartingBalanceMonthly")
        defaults.set(averageCostBasisMonthly, forKey: "savedAverageCostBasisMonthly")
        
        defaults.set(defaultTiltMonthly, forKey: defaultTiltKeyMonthly)
        defaults.set(maxSwingMonthly, forKey: maxSwingKeyMonthly)
        defaults.set(hasCapturedDefaultMonthly, forKey: hasCapturedDefaultKeyMonthly)
        defaults.set(tiltBarValueMonthly, forKey: tiltBarValueKeyMonthly)
        
        if let encodedFactors = try? JSONEncoder().encode(factorsMonthly) {
            defaults.set(encodedFactors, forKey: "factorStatesMonthly")
        }
        defaults.synchronize()
    }
    
    private func saveTiltStateMonthly() {
        let defaults = UserDefaults.standard
        defaults.set(defaultTiltMonthly, forKey: defaultTiltKeyMonthly)
        defaults.set(maxSwingMonthly, forKey: maxSwingKeyMonthly)
        defaults.set(hasCapturedDefaultMonthly, forKey: hasCapturedDefaultKeyMonthly)
    }
    
    private func saveTiltBarValueMonthly() {
        UserDefaults.standard.set(tiltBarValueMonthly, forKey: tiltBarValueKeyMonthly)
    }
    
    // MARK: - Reset Tilt Bar (Monthly)
    func resetTiltBarMonthly() {
        UserDefaults.standard.removeObject(forKey: tiltBarValueKeyMonthly)
        tiltBarValueMonthly = 0.0
        defaultTiltMonthly = 0.0
        maxSwingMonthly = 1.0
        hasCapturedDefaultMonthly = true
        saveTiltStateMonthly()
        saveTiltBarValueMonthly()
    }
    
    // MARK: - Factor Intensity Access (Monthly)
    func getFactorIntensityMonthly() -> Double {
        rawFactorIntensityMonthly
    }
    
    func setFactorIntensityMonthly(_ val: Double) {
        rawFactorIntensityMonthly = val
    }
    
    // MARK: - Computed Global Slider (Monthly)
    var factorIntensityMonthlyComputed: Double {
        get { rawFactorIntensityMonthly }
        set {
            withAnimation(.easeInOut(duration: 0.4)) {
                rawFactorIntensityMonthly = newValue
            }
            syncFactorsToGlobalIntensityMonthly()
        }
    }
    
    // MARK: - Sync Factors (Monthly)
    func syncFactorsMonthly() {
        for (name, var factor) in factorsMonthly {
            guard factor.isEnabled, !factor.isLocked else { continue }
            let baseline = globalBaselineMonthly(for: factor)
            let range = factor.maxValue - factor.minValue
            let newValue = baseline + factor.internalOffset * range
            let clamped = min(max(newValue, factor.minValue), factor.maxValue)
            if clamped != newValue {
                let _ = factor.internalOffset
                factor.internalOffset = (clamped - baseline) / range
            }
            factor.currentValue = clamped
            factorsMonthly[name] = factor
        }
    }
    
    // MARK: - Global Baseline (Monthly)
    func globalBaselineMonthly(for factor: FactorState) -> Double {
        let t = rawFactorIntensityMonthly
        if t < 0.5 {
            let ratio = t / 0.5
            return factor.defaultValue - (factor.defaultValue - factor.minValue) * (1.0 - ratio)
        } else {
            let ratio = (t - 0.5) / 0.5
            return factor.defaultValue + (factor.maxValue - factor.defaultValue) * ratio
        }
    }
    
    // MARK: - Recalculate Global Slider from Factors (Monthly)
    func recalcGlobalSliderFromFactorsMonthly() {
        let activeFactors = factorsMonthly.values.filter { $0.isEnabled && !$0.isLocked }
        guard !activeFactors.isEmpty else {
            ignoreSyncMonthly = true
            rawFactorIntensityMonthly = 0.5
            extendedGlobalValueMonthly = 0.0
            ignoreSyncMonthly = false
            return
        }
        let sumOffsets = activeFactors.reduce(0.0) { $0 + $1.internalOffset }
        let avgOffset = sumOffsets / Double(activeFactors.count)
        var newIntensity = 0.5 + avgOffset
        newIntensity = max(0.0, min(1.0, newIntensity))
        ignoreSyncMonthly = true
        rawFactorIntensityMonthly = newIntensity
        ignoreSyncMonthly = false
    }
    
    // MARK: - User Dragging Factor Slider (Monthly)
    func userDidDragFactorSliderMonthly(_ factorName: String, to newValue: Double) {
        guard var factor = factorsMonthly[factorName] else {
            return
        }
        
        let bullishKeysMonthly: [String] = [
            "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
            "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
            "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
        ]
        let bearishKeysMonthly = self.bearishKeysMonthly
        
        if chartExtremeBearishMonthly && newValue > factor.minValue {
            chartExtremeBearishMonthly = false
            recalcTiltBarValueMonthly(bullishKeys: bullishKeysMonthly, bearishKeys: bearishKeysMonthly)
        }
        if chartExtremeBullishMonthly && newValue < factor.maxValue {
            chartExtremeBullishMonthly = false
            recalcTiltBarValueMonthly(bullishKeys: bullishKeysMonthly, bearishKeys: bearishKeysMonthly)
        }
        
        let oldOffset = factor.internalOffset
        let baseline = globalBaselineMonthly(for: factor)
        let range = factor.maxValue - factor.minValue
        let clampedVal = max(factor.minValue, min(newValue, factor.maxValue))
        factor.currentValue = clampedVal
        let newOffset = (clampedVal - baseline) / range
        factor.internalOffset = newOffset
        factorsMonthly[factorName] = factor
        
        let deltaOffset = newOffset - oldOffset
        let activeCount = factorsMonthly.values.filter { $0.isEnabled && !$0.isLocked }.count
        if activeCount > 0 {
            let shift = deltaOffset / Double(activeCount)
            ignoreSyncMonthly = true
            rawFactorIntensityMonthly += shift
            rawFactorIntensityMonthly = min(max(rawFactorIntensityMonthly, 0), 1)
            DispatchQueue.main.async {
                self.ignoreSyncMonthly = false
            }
        }
        
        recalcTiltBarValueMonthly(bullishKeys: bullishKeysMonthly, bearishKeys: bearishKeysMonthly)
        saveToUserDefaultsMonthly()
        applyDictionaryFactorForMonthly(factorName)
    }
    
    // MARK: - Global Slider Changed (Monthly)
    func globalSliderChangedMonthly(to newGlobalValue: Double) {
        rawFactorIntensityMonthly = newGlobalValue
        // Optionally, call applyDictionaryFactorsToSimMonthly() if needed
        saveToUserDefaultsMonthly()
    }
    
    // MARK: - Recalculate Tilt Bar (Monthly)
    func recalcTiltBarValueMonthly(bullishKeys: [String], bearishKeys: [String]) {
        if chartExtremeBearishMonthly {
            let slope = 0.7
            tiltBarValueMonthly = min(-1.0 + (rawFactorIntensityMonthly * slope), 0.0)
            overrodeTiltManuallyMonthly = true
            return
        }
        if chartExtremeBullishMonthly {
            let slope = 0.7
            tiltBarValueMonthly = max(1.0 - ((1.0 - rawFactorIntensityMonthly) * slope), 0.0)
            overrodeTiltManuallyMonthly = true
            return
        }
        
        let globalCurveValue = applyGlobalSCurveMonthly(rawFactorIntensityMonthly)
        let baseTilt = (globalCurveValue * 2.0) - 1.0
        let baseTiltScaled = baseTilt * 108.0
        
        var sumBullish = 0.0
        for key in bullishKeys {
            guard let factor = factorsMonthly[key] else { continue }
            let minVal = factor.minValue
            let maxVal = factor.maxValue
            let val = factor.currentValue
            let rawNorm = (val - minVal) / (maxVal - minVal)
            let effectiveRawNorm = factor.isEnabled ? rawNorm : 1.0
            let scNorm = applyFactorSCurveMonthly(effectiveRawNorm)
            let weight = MonthlySimulationSettings.bullishWeightsMonthly[key.lowercased()] ?? 9.0
            if factor.isEnabled {
                sumBullish += weight * scNorm
            } else {
                sumBullish -= weight * scNorm
            }
        }
        
        var sumBearish = 0.0
        for key in bearishKeys {
            guard let factor = factorsMonthly[key] else { continue }
            let minVal = factor.minValue
            let maxVal = factor.maxValue
            let val = factor.currentValue
            let rawNorm = (val - minVal) / (maxVal - minVal)
            let effectiveRawNorm = factor.isEnabled ? rawNorm : 0.0
            let invertedNorm = 1.0 - effectiveRawNorm
            let scNorm = applyFactorSCurveMonthly(invertedNorm)
            let weight = MonthlySimulationSettings.bearishWeightsMonthly[key.lowercased()] ?? 12.0
            if factor.isEnabled {
                sumBearish += weight * scNorm
            } else {
                sumBearish -= weight * scNorm
            }
        }
        
        let netOffset = sumBullish - sumBearish
        var combinedRaw = baseTiltScaled + netOffset
        combinedRaw = max(min(combinedRaw, 216.0), -216.0)
        
        tiltBarValueMonthly = combinedRaw / 216.0
        overrodeTiltManuallyMonthly = true
        
        if !factorsMonthly.values.contains(where: { $0.isEnabled }) {
            tiltBarValueMonthly = 0.0
            overrodeTiltManuallyMonthly = true
        }
    }
    
    // MARK: - Weights & S-Curves (Monthly)
    static let bullishWeightsMonthly: [String: Double] = [
        "halving":            20.15,
        "institutionaldemand": 8.69,
        "countryadoption":     8.47,
        "regulatoryclarity":   7.55,
        "etfapproval":         8.24,
        "techbreakthrough":    7.09,
        "scarcityevents":      7.55,
        "globalmacrohedge":    7.32,
        "stablecoinshift":     6.86,
        "demographicadoption": 9.39,
        "altcoinflight":       6.40,
        "adoptionfactor":     10.29
    ]
    
    static let bearishWeightsMonthly: [String: Double] = [
        "regclampdown":       13.15,
        "competitorcoin":     11.02,
        "securitybreach":     11.02,
        "bubblepop":          10.69,
        "stablecoinmeltdown": 10.69,
        "blackswan":          20.18,
        "bearmarket":         11.62,
        "maturingmarket":     11.62,
        "recession":           7.96
    ]
    
    func applyGlobalSCurveMonthly(_ x: Double,
                                  alpha: Double = 10.0,
                                  beta:  Double = 0.5,
                                  offset: Double = 0.0,
                                  scale:  Double = 1.0) -> Double {
        let exponent = -alpha * (x - beta)
        let rawLogistic = offset + (scale / (1.0 + exp(exponent)))
        let logisticAt0 = offset + (scale / (1.0 + exp(-alpha * (0 - beta))))
        let logisticAt1 = offset + (scale / (1.0 + exp(-alpha * (1 - beta))))
        let normalized = (rawLogistic - logisticAt0) / (logisticAt1 - logisticAt0)
        return max(0.0, min(1.0, normalized))
    }
    
    func applyFactorSCurveMonthly(_ x: Double,
                                  alpha: Double = 10.0,
                                  beta:  Double = 0.7,
                                  offset: Double = 0.0,
                                  scale:  Double = 1.0) -> Double {
        let exponent = -alpha * (x - beta)
        let rawLogistic = offset + (scale / (1.0 + exp(exponent)))
        let logisticAt0 = offset + (scale / (1.0 + exp(-alpha * (0 - beta))))
        let logisticAt1 = offset + (scale / (1.0 + exp(-alpha * (1 - beta))))
        var normalized = (rawLogistic - logisticAt0) / (logisticAt1 - logisticAt0)
        let epsilon = 1e-6
        if abs(normalized) < epsilon { normalized = 0.0 }
        if abs(normalized - 1.0) < epsilon { normalized = 1.0 }
        return max(0.0, min(1.0, normalized))
    }
    
    // MARK: - Additional Factor Handling (Monthly)
    func applyDictionaryFactorForMonthly(_ factorName: String) {
        // Add any monthly-specific adjustments here.
    }
    
    // MARK: - Toggle All Factors (Monthly)
    var toggleAllMonthly: Bool {
        get { factorsMonthly.values.allSatisfy { $0.isEnabled } }
        set { toggleAllFactorsMonthly(on: newValue) }
    }
}
        