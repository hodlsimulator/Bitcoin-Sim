//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// The main settings object, holding global slider, factor dictionary, tilt bar value, etc.
class SimulationSettings: ObservableObject {
    
    // Now we define keys so watchers can see them:
    let bearishKeys: [String] = [
        "RegClampdown", "CompetitorCoin", "SecurityBreach",
        "BubblePop", "StablecoinMeltdown", "BlackSwan",
        "BearMarket", "MaturingMarket", "Recession"
    ]
    
    // MARK: - Published Properties
    
    /// For the “Chart extremes” UI logic
    @Published var chartExtremeBearish: Bool = false
    @Published var chartExtremeBullish: Bool = false
    
    /// Tells the UI if we’re in the process of restoring defaults
    @Published var isRestoringDefaults: Bool = false
    
    /// Dictionary of all factors, keyed by name
    @Published var factors: [String: FactorState] = [:]
    
    /// A set of factor names that are locked to prevent changes from the global slider
    @Published var lockedFactors: Set<String> = []
    
    /// The global slider in [0..1]. As soon as it changes, we sync factors so they track the new baseline.
    @Published var rawFactorIntensity: Double = 0.5 {
        didSet {
            // Replicate test-app logic: whenever global slider changes, sync all factors
            syncFactors()
        }
    }
    
    /// If user manually overrides tilt bar (e.g. dragging the bar directly), we note it here
    var overrodeTiltManually = false
    
    /// The final –1..+1 tilt bar value displayed in UI
    @Published var tiltBarValue: Double = 0.0
    
    /// Toggling all factors at once
    @Published var userIsActuallyTogglingAll = false {
        didSet {
            if !userIsActuallyTogglingAll {
                resetTiltBar()
            }
        }
    }
    
    // MARK: - Additional Published Props
    
    @Published var defaultTilt: Double = 0.0
    @Published var maxSwing: Double = 1.0
    @Published var hasCapturedDefault: Bool = false
    
    @Published var isOnboarding: Bool = false
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet {
            if isInitialized {
                print("didSet: periodUnit changed to \(periodUnit)")
            }
        }
    }
    
    @Published var userPeriods: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0
    
    @Published var currencyPreference: PreferredCurrency = .eur {
        didSet {
            if isInitialized {
                print("didSet: currencyPreference changed to \(currencyPreference)")
                UserDefaults.standard.set(currencyPreference.rawValue, forKey: "currencyPreference")
            }
        }
    }
    
    @Published var contributionCurrencyWhenBoth: PreferredCurrency = .eur
    @Published var startingBalanceCurrencyWhenBoth: PreferredCurrency = .usd
    
    /// The results of the last simulation run
    @Published var lastRunResults: [SimulationData] = []
    /// All runs
    @Published var allRuns: [[SimulationData]] = []
    
    /// Internal flags
    var isInitialized = false
    var isUpdating = false
    
    // MARK: - Advanced Toggles
    
    @Published var useLognormalGrowth: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useLognormalGrowth changed to \(useLognormalGrowth)")
                UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
                if !useLognormalGrowth { useAnnualStep = true }
            }
        }
    }
    
    @Published var useAnnualStep: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: useAnnualStep changed to \(useAnnualStep)")
                UserDefaults.standard.set(useAnnualStep, forKey: "useAnnualStep")
            }
        }
    }
    
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: lockedRandomSeed changed to \(lockedRandomSeed)")
                UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
            }
        }
    }
    
    @Published var seedValue: UInt64 = 0 {
        didSet {
            if isInitialized {
                print("didSet: seedValue changed to \(seedValue)")
                UserDefaults.standard.set(seedValue, forKey: "seedValue")
            }
        }
    }
    
    @Published var useRandomSeed: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useRandomSeed changed to \(useRandomSeed)")
                UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
            }
        }
    }
    
    @Published var useHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useHistoricalSampling changed to \(useHistoricalSampling)")
                UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
            }
        }
    }
    
    @Published var useExtendedHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useExtendedHistoricalSampling changed to \(useExtendedHistoricalSampling)")
                UserDefaults.standard.set(useExtendedHistoricalSampling, forKey: "useExtendedHistoricalSampling")
            }
        }
    }
    
    @Published var useVolShocks: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useVolShocks changed to \(useVolShocks)")
                UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
            }
        }
    }
    
    @Published var useGarchVolatility: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useGarchVolatility changed to \(useGarchVolatility)")
                UserDefaults.standard.set(useGarchVolatility, forKey: "useGarchVolatility")
            }
        }
    }
    
    @Published var useAutoCorrelation: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: useAutoCorrelation changed to \(useAutoCorrelation)")
                UserDefaults.standard.set(useAutoCorrelation, forKey: "useAutoCorrelation")
                if !useAutoCorrelation { useMeanReversion = false }
            }
        }
    }
    
    @Published var autoCorrelationStrength: Double = 0.2 {
        didSet {
            if isInitialized {
                print("didSet: autoCorrelationStrength changed to \(autoCorrelationStrength)")
                UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
            }
        }
    }
    
    @Published var meanReversionTarget: Double = 0.0 {
        didSet {
            if isInitialized {
                print("didSet: meanReversionTarget changed to \(meanReversionTarget)")
                UserDefaults.standard.set(meanReversionTarget, forKey: "meanReversionTarget")
            }
        }
    }
    
    @Published var useMeanReversion: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useMeanReversion changed to \(useMeanReversion)")
                UserDefaults.standard.set(useMeanReversion, forKey: "useMeanReversion")
            }
        }
    }
    
    @Published var lastUsedSeed: UInt64 = 0
    
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: lockHistoricalSampling changed to \(lockHistoricalSampling)")
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }
    
    @Published var useRegimeSwitching: Bool = false {
        didSet {
            if isInitialized {
                print("didSet: useRegimeSwitching changed to \(useRegimeSwitching)")
                UserDefaults.standard.set(useRegimeSwitching, forKey: "useRegimeSwitching")
            }
        }
    }
    
    // MARK: - Keys for tilt bar in UserDefaults
    
    private let defaultTiltKey = "defaultTilt"
    private let maxSwingKey = "maxSwing"
    private let hasCapturedDefaultKey = "capturedTilt"
    private let tiltBarValueKey = "tiltBarValue"
    
    // MARK: - Init
    
    init() {
        isUpdating = false
        isInitialized = false
        
        // Load everything from user defaults
        loadFromUserDefaults()
        
        // If we never captured tilt state, define some defaults
        if !hasCapturedDefault {
            defaultTilt = 0.0
            maxSwing = 1.0
            hasCapturedDefault = true
            saveTiltState()
        }
        
        isInitialized = true
    }
    
    // MARK: - Tilt Bar Reset
    
    func resetTiltBar() {
        UserDefaults.standard.removeObject(forKey: tiltBarValueKey)
        tiltBarValue = 0.0
        defaultTilt = 0.0
        maxSwing = 1.0
        hasCapturedDefault = true
        saveTiltState()
        saveTiltBarValue()
    }
    
    // MARK: - Loading & Saving
    
    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        isInitialized = false
        
        // Basic toggles
        useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        lockedRandomSeed = defaults.bool(forKey: "lockedRandomSeed")
        seedValue = defaults.object(forKey: "seedValue") as? UInt64 ?? 0
        useRandomSeed = defaults.bool(forKey: "useRandomSeed")
        useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        useVolShocks = defaults.bool(forKey: "useVolShocks")
        useGarchVolatility = defaults.bool(forKey: "useGarchVolatility")
        useAutoCorrelation = defaults.bool(forKey: "useAutoCorrelation")
        autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        lockHistoricalSampling = defaults.bool(forKey: "lockHistoricalSampling")
        useRegimeSwitching = defaults.bool(forKey: "useRegimeSwitching")
        
        if defaults.object(forKey: "useExtendedHistoricalSampling") == nil {
            useExtendedHistoricalSampling = true
        } else {
            useExtendedHistoricalSampling = defaults.bool(forKey: "useExtendedHistoricalSampling")
        }
        
        if defaults.object(forKey: "autoCorrelationStrength") == nil {
            autoCorrelationStrength = 0.05
        }
        
        if defaults.object(forKey: "meanReversionTarget") == nil {
            meanReversionTarget = 0.03
        }
        
        if defaults.object(forKey: "useMeanReversion") == nil {
            useMeanReversion = true
        } else {
            useMeanReversion = defaults.bool(forKey: "useMeanReversion")
        }
        
        // Tilt bar values
        if defaults.object(forKey: defaultTiltKey) != nil {
            defaultTilt = defaults.double(forKey: defaultTiltKey)
        }
        if defaults.object(forKey: maxSwingKey) != nil {
            maxSwing = defaults.double(forKey: maxSwingKey)
        }
        if defaults.object(forKey: hasCapturedDefaultKey) != nil {
            hasCapturedDefault = defaults.bool(forKey: hasCapturedDefaultKey)
        }
        if defaults.object(forKey: tiltBarValueKey) != nil {
            tiltBarValue = defaults.double(forKey: tiltBarValueKey)
        } else {
            tiltBarValue = 0.0
        }
        
        // Load other saved values
        if let savedPeriods = defaults.object(forKey: "savedUserPeriods") as? Int {
            userPeriods = savedPeriods
        }
        if let savedBTCPrice = defaults.object(forKey: "savedInitialBTCPriceUSD") as? Double {
            initialBTCPriceUSD = savedBTCPrice
        }
        if let savedBalance = defaults.object(forKey: "savedStartingBalance") as? Double {
            startingBalance = savedBalance
        }
        if let savedACB = defaults.object(forKey: "savedAverageCostBasis") as? Double {
            averageCostBasis = savedACB
        }
        if let savedPeriodUnitRaw = defaults.string(forKey: "savedPeriodUnit"),
           let savedPeriodUnit = PeriodUnit(rawValue: savedPeriodUnitRaw) {
            periodUnit = savedPeriodUnit
        }
        if let storedPrefRaw = defaults.string(forKey: "currencyPreference"),
           let storedPref = PreferredCurrency(rawValue: storedPrefRaw) {
            currencyPreference = storedPref
        } else {
            currencyPreference = .eur
        }
        
        // Load factor states if available
        if let savedFactorStatesData = defaults.data(forKey: "factorStates"),
           let savedFactors = try? JSONDecoder().decode([String: FactorState].self, from: savedFactorStatesData) {
            factors = savedFactors
        } else {
            // Build factors from FactorCatalog if none saved
            factors.removeAll()
            for (factorName, def) in FactorCatalog.all {
                let (minVal, midVal, maxVal) = (periodUnit == .weeks)
                    ? (def.minWeekly, def.midWeekly, def.maxWeekly)
                    : (def.minMonthly, def.midMonthly, def.maxMonthly)
                
                // We set each factor as enabled = true by default
                let fs = FactorState(
                    name: factorName,
                    currentValue: midVal,
                    defaultValue: midVal,
                    minValue: minVal,
                    maxValue: maxVal,
                    isEnabled: true,
                    isLocked: false
                )
                factors[factorName] = fs
            }
        }
        
        isInitialized = true
    }
    
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Example of saving toggles if needed:
        defaults.set(useLognormalGrowth, forKey: "useLognormalGrowth")
        defaults.set(lockedRandomSeed, forKey: "lockedRandomSeed")
        defaults.set(seedValue, forKey: "seedValue")
        defaults.set(useRandomSeed, forKey: "useRandomSeed")
        defaults.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        defaults.set(useVolShocks, forKey: "useVolShocks")
        defaults.set(useGarchVolatility, forKey: "useGarchVolatility")
        defaults.set(useAutoCorrelation, forKey: "useAutoCorrelation")
        defaults.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
        defaults.set(meanReversionTarget, forKey: "meanReversionTarget")
        defaults.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
        defaults.set(useRegimeSwitching, forKey: "useRegimeSwitching")
        
        // Save factor states
        if let encodedFactors = try? JSONEncoder().encode(factors) {
            defaults.set(encodedFactors, forKey: "factorStates")
        }
        
        defaults.synchronize()
    }
    
    private func saveTiltState() {
        let defaults = UserDefaults.standard
        defaults.set(defaultTilt, forKey: defaultTiltKey)
        defaults.set(maxSwing, forKey: maxSwingKey)
        defaults.set(hasCapturedDefault, forKey: hasCapturedDefaultKey)
    }
    
    private func saveTiltBarValue() {
        UserDefaults.standard.set(tiltBarValue, forKey: tiltBarValueKey)
    }
    
    // MARK: - Factor Intensity Accessors
    
    func getFactorIntensity() -> Double {
        rawFactorIntensity
    }
    
    func setFactorIntensity(_ val: Double) {
        rawFactorIntensity = val
    }
    
    // MARK: - userDidDragFactorSlider
    
    /// Called whenever the user manually drags a factor’s slider to a new value.
    /// We compute the offset = how far above/below the baseline it is.
    func userDidDragFactorSlider(_ factorName: String, to newValue: Double) {
        guard var factor = factors[factorName] else { return }
        let baseline = globalBaseline(for: factor)
        let range = factor.maxValue - factor.minValue
        
        let clampedVal = max(min(newValue, factor.maxValue), factor.minValue)
        factor.currentValue = clampedVal
        factor.internalOffset = (clampedVal - baseline) / range
        
        factors[factorName] = factor
    }
    
    // MARK: - recalcTiltBarValue
    func recalcTiltBarValue(bullishKeys: [String], bearishKeys: [String]) {
        print("\n--- recalcTiltBarValue called ---")
        print("Bullish keys: \(bullishKeys)")
        print("Bearish keys: \(bearishKeys)")
        
        // 1) Check "forced extremes" logic (unchanged)
        if chartExtremeBearish {
            let slope = 0.7
            let forcedTilt = -1.0 + (rawFactorIntensity * slope)
            tiltBarValue = min(forcedTilt, 0.0)
            overrodeTiltManually = true
            print("chartExtremeBearish. forcedTilt = \(forcedTilt). tiltBarValue = \(tiltBarValue)")
            return
        }
        if chartExtremeBullish {
            let slope = 0.7
            let forcedTilt = 1.0 - ((1.0 - rawFactorIntensity) * slope)
            tiltBarValue = max(forcedTilt, 0.0)
            overrodeTiltManually = true
            print("chartExtremeBullish. forcedTilt = \(forcedTilt). tiltBarValue = \(tiltBarValue)")
            return
        }
        
        // -------------------------------------------------------------------------
        // --- S-CURVE FUNCTIONS WITH EXTRA CONTROL ---
        //
        // We’ll use a logistic-style curve here for more control over:
        //   alpha  -> overall steepness
        //   beta   -> horizontal shift (i.e., which point is considered mid-slope)
        //   offset -> vertical shift if needed
        //   scale  -> amplitude (how tall the curve is)
        //
        // The default shape: y = offset + (scale / (1 + exp(-alpha * (x - beta))))
        // -------------------------------------------------------------------------
        func applyGlobalSCurve(_ x: Double,
                               alpha: Double = 10.0,  // Controls the steepness.
                               beta:  Double = 0.5,   // With beta=0.5, rawFactorIntensity=0.5 yields 0.5.
                               offset: Double = 0.0,  // Vertical shift.
                               scale:  Double = 1.0) -> Double {  // Scale factor.
            let exponent = -alpha * (x - beta)
            let rawLogistic = offset + (scale / (1.0 + exp(exponent)))
            
            let logisticAt0 = offset + (scale / (1.0 + exp(-alpha * (0 - beta))))
            let logisticAt1 = offset + (scale / (1.0 + exp(-alpha * (1 - beta))))
            
            let normalized = (rawLogistic - logisticAt0) / (logisticAt1 - logisticAt0)
            return max(0.0, min(1.0, normalized))
        }
        
        func applyFactorSCurve(_ x: Double,
                               alpha: Double = 10.0,   // Controls the steepness of the factor curve.
                               beta:  Double = 0.3,    // Sets the midpoint.
                               offset: Double = 0.0,   // Vertical shift.
                               scale:  Double = 1.0) -> Double {  // Scale factor.
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
        
        // -------------------------------------------------------------------------
        
        // 2) Global slider: pass rawFactorIntensity through the global s‑curve.
        let globalCurveValue = applyGlobalSCurve(rawFactorIntensity)
        let baseTilt = (globalCurveValue * 2.0) - 1.0
        let baseTiltScaled = baseTilt * 108.0
        print("globalCurveValue = \(globalCurveValue), baseTilt = \(baseTilt) => scaled to \(baseTiltScaled)")
        
        // 3) Summation for bullish factors => total ±108 if all on/off.
        // Each factor’s slider (normalized then s‑curved) is scaled by 9.
        var sumBullish = 0.0
        for key in bullishKeys {
            guard let factor = factors[key] else { continue }
            let minVal = factor.minValue
            let maxVal = factor.maxValue
            let val = factor.currentValue
            let rawNorm = (val - minVal) / (maxVal - minVal)
            // When a bullish factor is disabled, override its effective value to 1.0 for maximum negative impact.
            let effectiveRawNorm = factor.isEnabled ? rawNorm : 1.0
            let scNorm = applyFactorSCurve(effectiveRawNorm)
            let factorMagnitude = 9.0 * scNorm
            
            if factor.isEnabled {
                sumBullish += factorMagnitude
                print("  Bullish '\(key)' ENABLED => +\(factorMagnitude) (rawNorm=\(rawNorm), scNorm=\(scNorm))")
            } else {
                sumBullish -= factorMagnitude
                print("  Bullish '\(key)' DISABLED => -\(factorMagnitude) (rawNorm=\(rawNorm), scNorm=\(scNorm))")
            }
        }
        
        // 4) Summation for bearish factors => total ±108 if all on/off.
        // Invert the normalized value, pass through the s‑curve, and scale by 12.
        var sumBearish = 0.0
        for key in bearishKeys {
            guard let factor = factors[key] else { continue }
            let minVal = factor.minValue
            let maxVal = factor.maxValue
            let val = factor.currentValue
            let rawNorm = (val - minVal) / (maxVal - minVal)
            // For bearish factors, when enabled the value is used normally;
            // if disabled, override to 0.0 (so that 1 - effectiveRawNorm = 1) for maximum negative impact.
            let effectiveRawNorm = factor.isEnabled ? rawNorm : 0.0
            let invertedNorm = 1.0 - effectiveRawNorm
            let scNorm = applyFactorSCurve(invertedNorm)
            let factorMagnitude = 12.0 * scNorm
            
            if factor.isEnabled {
                sumBearish += factorMagnitude
                print("  Bearish '\(key)' ENABLED => +\(factorMagnitude) (rawNorm=\(rawNorm), scNorm=\(scNorm))")
            } else {
                sumBearish -= factorMagnitude
                print("  Bearish '\(key)' DISABLED => -\(factorMagnitude) (rawNorm=\(rawNorm), scNorm=\(scNorm))")
            }
        }
        
        print("sumBullish = \(sumBullish), sumBearish = \(sumBearish)")
        
        let netOffset = sumBullish - sumBearish
        print("netOffset = \(netOffset)")
        
        var combinedRaw = baseTiltScaled + netOffset
        combinedRaw = max(min(combinedRaw, 216.0), -216.0)
        
        tiltBarValue = combinedRaw / 216.0
        overrodeTiltManually = true
        print("Final tiltBarValue = \(tiltBarValue)")
    }

    // MARK: - syncFactors
    /// Called automatically whenever rawFactorIntensity changes. This keeps each factor at baseline + offset.
    func syncFactors() {
        for (name, var factor) in factors {
            // Only sync if factor is enabled and not locked
            guard factor.isEnabled, !factor.isLocked else { continue }
            
            let baseline = globalBaseline(for: factor)
            let range = factor.maxValue - factor.minValue
            
            let newValue = baseline + factor.internalOffset * range
            let clamped = min(max(newValue, factor.minValue), factor.maxValue)
            
            // If we had to clamp, update offset to reflect the new position
            if clamped != newValue {
                factor.internalOffset = (clamped - baseline) / range
            }
            
            factor.currentValue = clamped
            factors[name] = factor
        }
    }
}
