//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// The main settings object, holding global slider, factor dictionary, tilt bar value, etc.
class SimulationSettings: ObservableObject {
    
    let bearishKeys: [String] = [
        "RegClampdown", "CompetitorCoin", "SecurityBreach",
        "BubblePop", "StablecoinMeltdown", "BlackSwan",
        "BearMarket", "MaturingMarket", "Recession"
    ]
    
    var isGlobalSliderDisabled: Bool {
        return factors.values.allSatisfy { !$0.isEnabled }
    }
    
    // MARK: - Published Properties
    
    @Published var chartExtremeBearish: Bool = false
    @Published var chartExtremeBullish: Bool = false
    @Published var isRestoringDefaults: Bool = false
    @Published var factors: [String: FactorState] = [:]
    @Published var lockedFactors: Set<String> = []
    
    /// Global slider controlling the baseline for factors.
    /// When updated manually, its didSet calls syncFactors().
    @Published var rawFactorIntensity: Double = 0.5 {
        didSet {
            // Debug print to trace changes.
            print("[rawFactorIntensity didSet] New value: \(rawFactorIntensity), ignoreSync: \(ignoreSync)")
            // If this change is not coming from an individual update, sync all factors.
            if !ignoreSync {
                syncFactors()
            }
        }
    }
    
    /// When true, changes to rawFactorIntensity do not trigger a full sync.
    var ignoreSync: Bool = false
    
    @Published var overrodeTiltManually = false
    @Published var tiltBarValue: Double = 0.0
    @Published var userIsActuallyTogglingAll = false {
        didSet {
            if !userIsActuallyTogglingAll {
                resetTiltBar()
            }
        }
    }
    
    @Published var defaultTilt: Double = 0.0
    @Published var maxSwing: Double = 1.0
    @Published var hasCapturedDefault: Bool = false
    @Published var isOnboarding: Bool = false
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet {
            if isInitialized {
                print("[periodUnit didSet] periodUnit changed to \(periodUnit)")
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
                print("[currencyPreference didSet] currencyPreference changed to \(currencyPreference)")
                UserDefaults.standard.set(currencyPreference.rawValue, forKey: "currencyPreference")
            }
        }
    }
    
    @Published var contributionCurrencyWhenBoth: PreferredCurrency = .eur
    @Published var startingBalanceCurrencyWhenBoth: PreferredCurrency = .usd
    
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    var isInitialized = false
    var isUpdating = false
    
    // Global flag to indicate the source of change (if needed for further debugging)
    var isIndividualChange = false
    
    // MARK: - Advanced Toggles
    @Published var useLognormalGrowth: Bool = true {
        didSet {
            if isInitialized {
                print("[useLognormalGrowth didSet] useLognormalGrowth changed to \(useLognormalGrowth)")
                UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
                if !useLognormalGrowth { useAnnualStep = true }
            }
        }
    }
    @Published var useAnnualStep: Bool = false {
        didSet {
            if isInitialized {
                print("[useAnnualStep didSet] useAnnualStep changed to \(useAnnualStep)")
                UserDefaults.standard.set(useAnnualStep, forKey: "useAnnualStep")
            }
        }
    }
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            if isInitialized {
                print("[lockedRandomSeed didSet] lockedRandomSeed changed to \(lockedRandomSeed)")
                UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
            }
        }
    }
    @Published var seedValue: UInt64 = 0 {
        didSet {
            if isInitialized {
                print("[seedValue didSet] seedValue changed to \(seedValue)")
                UserDefaults.standard.set(seedValue, forKey: "seedValue")
            }
        }
    }
    @Published var useRandomSeed: Bool = true {
        didSet {
            if isInitialized {
                print("[useRandomSeed didSet] useRandomSeed changed to \(useRandomSeed)")
                UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
            }
        }
    }
    @Published var useHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                print("[useHistoricalSampling didSet] useHistoricalSampling changed to \(useHistoricalSampling)")
                UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
            }
        }
    }
    @Published var useExtendedHistoricalSampling: Bool = true {
        didSet {
            if isInitialized {
                print("[useExtendedHistoricalSampling didSet] useExtendedHistoricalSampling changed to \(useExtendedHistoricalSampling)")
                UserDefaults.standard.set(useExtendedHistoricalSampling, forKey: "useExtendedHistoricalSampling")
            }
        }
    }
    @Published var useVolShocks: Bool = true {
        didSet {
            if isInitialized {
                print("[useVolShocks didSet] useVolShocks changed to \(useVolShocks)")
                UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
            }
        }
    }
    @Published var useGarchVolatility: Bool = true {
        didSet {
            if isInitialized {
                print("[useGarchVolatility didSet] useGarchVolatility changed to \(useGarchVolatility)")
                UserDefaults.standard.set(useGarchVolatility, forKey: "useGarchVolatility")
            }
        }
    }
    @Published var useAutoCorrelation: Bool = false {
        didSet {
            if isInitialized {
                print("[useAutoCorrelation didSet] useAutoCorrelation changed to \(useAutoCorrelation)")
                UserDefaults.standard.set(useAutoCorrelation, forKey: "useAutoCorrelation")
                if !useAutoCorrelation { useMeanReversion = false }
            }
        }
    }
    @Published var autoCorrelationStrength: Double = 0.2 {
        didSet {
            if isInitialized {
                print("[autoCorrelationStrength didSet] autoCorrelationStrength changed to \(autoCorrelationStrength)")
                UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
            }
        }
    }
    @Published var meanReversionTarget: Double = 0.0 {
        didSet {
            if isInitialized {
                print("[meanReversionTarget didSet] meanReversionTarget changed to \(meanReversionTarget)")
                UserDefaults.standard.set(meanReversionTarget, forKey: "meanReversionTarget")
            }
        }
    }
    @Published var useMeanReversion: Bool = true {
        didSet {
            if isInitialized {
                print("[useMeanReversion didSet] useMeanReversion changed to \(useMeanReversion)")
                UserDefaults.standard.set(useMeanReversion, forKey: "useMeanReversion")
            }
        }
    }
    @Published var lastUsedSeed: UInt64 = 0
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            if isInitialized {
                print("[lockHistoricalSampling didSet] lockHistoricalSampling changed to \(lockHistoricalSampling)")
                UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
            }
        }
    }
    @Published var useRegimeSwitching: Bool = false {
        didSet {
            if isInitialized {
                print("[useRegimeSwitching didSet] useRegimeSwitching changed to \(useRegimeSwitching)")
                UserDefaults.standard.set(useRegimeSwitching, forKey: "useRegimeSwitching")
            }
        }
    }
    
    // MARK: - Keys
    private let defaultTiltKey = "defaultTilt"
    private let maxSwingKey = "maxSwing"
    private let hasCapturedDefaultKey = "capturedTilt"
    private let tiltBarValueKey = "tiltBarValue"
    
    // MARK: - Init
    init() {
        isUpdating = false
        isInitialized = false
        loadFromUserDefaults()
        
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
        print("[resetTiltBar] Resetting tilt bar")
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
        print("[loadFromUserDefaults] Loading settings")
        isInitialized = false
        
        useLognormalGrowth = defaults.bool(forKey: "useLognormalGrowth")
        lockedRandomSeed   = defaults.bool(forKey: "lockedRandomSeed")
        seedValue          = defaults.object(forKey: "seedValue") as? UInt64 ?? 0
        useRandomSeed      = defaults.bool(forKey: "useRandomSeed")
        useHistoricalSampling = defaults.bool(forKey: "useHistoricalSampling")
        useVolShocks       = defaults.bool(forKey: "useVolShocks")
        useGarchVolatility = defaults.bool(forKey: "useGarchVolatility")
        useAutoCorrelation = defaults.bool(forKey: "useAutoCorrelation")
        autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        lockHistoricalSampling  = defaults.bool(forKey: "lockHistoricalSampling")
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
        }
        
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
            print("[loadFromUserDefaults] Loaded \(factors.count) factors from defaults")
        } else {
            print("[loadFromUserDefaults] No saved factor states; creating defaults")
            factors.removeAll()
            for (factorName, def) in FactorCatalog.all {
                let (minVal, midVal, maxVal) = (periodUnit == .weeks)
                    ? (def.minWeekly, def.midWeekly, def.maxWeekly)
                    : (def.minMonthly, def.midMonthly, def.maxMonthly)
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
        print("[saveToUserDefaults] Saving settings")
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
    
    // MARK: - Factor Intensity Access
    func getFactorIntensity() -> Double {
        rawFactorIntensity
    }
    
    func setFactorIntensity(_ val: Double) {
        rawFactorIntensity = val
    }
    
    // MARK: - userDidDragFactorSlider
    //
    // The “delta offset” approach lets an individual slider change update only that factor,
    // and in doing so, it nudges the global slider slightly. However, we do not want this
    // individual change to re-sync (and thus modify) the values of the other factors.
    // When the global slider itself is manually moved, then all factors will be updated.
    func userDidDragFactorSlider(_ factorName: String, to newValue: Double) {
        guard var factor = factors[factorName] else { return }
        
        // Define bullish and bearish keys (for tilt calculations)
        let bullishKeys: [String] = [
            "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
            "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
            "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
        ]
        let bearishKeys: [String] = [
            "RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
            "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket",
            "Recession"
        ]
        
        // Cancel forced extremes if needed
        if chartExtremeBearish && newValue > factor.minValue {
            chartExtremeBearish = false
            recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
        }
        if chartExtremeBullish && newValue < factor.maxValue {
            chartExtremeBullish = false
            recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
        }
        
        // Compute the new value and offset:
        let oldOffset = factor.internalOffset
        let baseline  = globalBaseline(for: factor)
        let range     = factor.maxValue - factor.minValue
        let clampedVal = max(factor.minValue, min(newValue, factor.maxValue))
        factor.currentValue = clampedVal
        let newOffset = (clampedVal - baseline) / range
        factor.internalOffset = newOffset
        
        // Write back into the dictionary:
        factors[factorName] = factor
        print("[userDidDragFactorSlider] Updated \(factorName): currentValue=\(factor.currentValue), internalOffset=\(factor.internalOffset)")
        
        // Compute the delta offset and adjust the global slider:
        let deltaOffset = newOffset - oldOffset
        let activeCount = factors.values.filter { $0.isEnabled && !$0.isLocked }.count
        if activeCount > 0 {
            let shift = deltaOffset / Double(activeCount)
            print("[userDidDragFactorSlider] Applying global slider shift of \(shift) from deltaOffset \(deltaOffset)")
            ignoreSync = true
            rawFactorIntensity += shift
            rawFactorIntensity = min(max(rawFactorIntensity, 0), 1)
            // Reset ignoreSync asynchronously so that subsequent manual updates trigger syncing.
            DispatchQueue.main.async {
                self.ignoreSync = false
                print("[userDidDragFactorSlider] ignoreSync reset to false")
            }
        }
        
        // Recalculate the tilt bar for display:
        recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
        
        // Persist the updated state:
        saveToUserDefaults()
        
        // IMPORTANT: For an individual update, update only the changed factor.
        // Do not call applyDictionaryFactorsToSim(), which would re-sync all factors from rawFactorIntensity.
        applyDictionaryFactorFor(factorName)
    }
    
    // Called when the user manually moves the global slider:
    func globalSliderChanged(to newGlobalValue: Double) {
        print("[globalSliderChanged] Global slider changed to \(newGlobalValue)")
        // Manual global update: set rawFactorIntensity normally so syncFactors() runs.
        rawFactorIntensity = newGlobalValue
        applyDictionaryFactorsToSim()
        saveToUserDefaults()
    }
    
    // MARK: - recalcTiltBarValue
    func recalcTiltBarValue(bullishKeys: [String], bearishKeys: [String]) {
        print("[recalcTiltBarValue] Starting recalculation with rawFactorIntensity: \(rawFactorIntensity)")
        
        if chartExtremeBearish {
            let slope = 0.7
            tiltBarValue = min(-1.0 + (rawFactorIntensity * slope), 0.0)
            overrodeTiltManually = true
            print("[recalcTiltBarValue] Extreme bearish active. Tilt bar set to \(tiltBarValue)")
            return
        }
        if chartExtremeBullish {
            let slope = 0.7
            tiltBarValue = max(1.0 - ((1.0 - rawFactorIntensity) * slope), 0.0)
            overrodeTiltManually = true
            print("[recalcTiltBarValue] Extreme bullish active. Tilt bar set to \(tiltBarValue)")
            return
        }
        
        let globalCurveValue = applyGlobalSCurve(rawFactorIntensity)
        let baseTilt = (globalCurveValue * 2.0) - 1.0
        let baseTiltScaled = baseTilt * 108.0
        
        var sumBullish = 0.0
        for key in bullishKeys {
            guard let factor = factors[key] else { continue }
            let minVal = factor.minValue
            let maxVal = factor.maxValue
            let val = factor.currentValue
            let rawNorm = (val - minVal) / (maxVal - minVal)
            let effectiveRawNorm = factor.isEnabled ? rawNorm : 1.0
            let scNorm = applyFactorSCurve(effectiveRawNorm)
            let weight = SimulationSettings.bullishWeights[key.lowercased()] ?? 9.0
            if factor.isEnabled {
                sumBullish += weight * scNorm
            } else {
                sumBullish -= weight * scNorm
            }
        }
        
        var sumBearish = 0.0
        for key in bearishKeys {
            guard let factor = factors[key] else { continue }
            let minVal = factor.minValue
            let maxVal = factor.maxValue
            let val = factor.currentValue
            let rawNorm = (val - minVal) / (maxVal - minVal)
            let effectiveRawNorm = factor.isEnabled ? rawNorm : 0.0
            let invertedNorm = 1.0 - effectiveRawNorm
            let scNorm = applyFactorSCurve(invertedNorm)
            let weight = SimulationSettings.bearishWeights[key.lowercased()] ?? 12.0
            if factor.isEnabled {
                sumBearish += weight * scNorm
            } else {
                sumBearish -= weight * scNorm
            }
        }
        
        let netOffset = sumBullish - sumBearish
        var combinedRaw = baseTiltScaled + netOffset
        combinedRaw = max(min(combinedRaw, 216.0), -216.0)
        
        tiltBarValue = combinedRaw / 216.0
        overrodeTiltManually = true
        
        if !factors.values.contains(where: { $0.isEnabled }) {
            tiltBarValue = 0.0
            overrodeTiltManually = true
        }
        print("[recalcTiltBarValue] Final tiltBarValue set to \(tiltBarValue)")
    }
    
    // MARK: - syncFactors
    func syncFactors() {
        print("[syncFactors] Syncing all factors using rawFactorIntensity: \(rawFactorIntensity)")
        // Update each enabled and unlocked factor so that its currentValue remains
        // consistent with its stored offset and the new global baseline.
        for (name, var factor) in factors {
            guard factor.isEnabled, !factor.isLocked else { continue }
            
            let baseline = globalBaseline(for: factor)
            let range = factor.maxValue - factor.minValue
            let newValue = baseline + factor.internalOffset * range
            let clamped = min(max(newValue, factor.minValue), factor.maxValue)
            if clamped != newValue {
                let oldOffset = factor.internalOffset
                factor.internalOffset = (clamped - baseline) / range
                print("[syncFactors] \(name): Adjusting offset from \(oldOffset) to \(factor.internalOffset)")
            }
            factor.currentValue = clamped
            factors[name] = factor
            print("[syncFactors] \(name): currentValue updated to \(factor.currentValue) using baseline \(baseline)")
        }
    }
    
    // MARK: - globalBaseline(for:)
    func globalBaseline(for factor: FactorState) -> Double {
        // Linear interpolation from factor.defaultValue to factor.minValue or maxValue based on rawFactorIntensity.
        let t = rawFactorIntensity
        if t < 0.5 {
            let ratio = t / 0.5
            let baseline = factor.defaultValue - (factor.defaultValue - factor.minValue) * (1.0 - ratio)
            print("[globalBaseline] For \(factor.name): t = \(t), baseline = \(baseline) (min: \(factor.minValue))")
            return baseline
        } else {
            let ratio = (t - 0.5) / 0.5
            let baseline = factor.defaultValue + (factor.maxValue - factor.defaultValue) * ratio
            print("[globalBaseline] For \(factor.name): t = \(t), baseline = \(baseline) (max: \(factor.maxValue))")
            return baseline
        }
    }
    
    // MARK: - recalcGlobalSliderFromFactors
    // Not used on every drag (we use incremental shifts), but can be called for a full re-average.
    func recalcGlobalSliderFromFactors() {
        print("[recalcGlobalSliderFromFactors] Recalculating global slider from factor offsets.")
        let activeFactors = factors.values.filter { $0.isEnabled && !$0.isLocked }
        guard !activeFactors.isEmpty else {
            ignoreSync = true
            rawFactorIntensity = 0.5
            ignoreSync = false
            print("[recalcGlobalSliderFromFactors] No active factors; global slider reset to 0.5")
            return
        }
        let sumOffsets = activeFactors.reduce(0.0) { $0 + $1.internalOffset }
        let avgOffset = sumOffsets / Double(activeFactors.count)
        var newIntensity = 0.5 + avgOffset
        newIntensity = max(0.0, min(1.0, newIntensity))
        ignoreSync = true
        rawFactorIntensity = newIntensity
        ignoreSync = false
        print("[recalcGlobalSliderFromFactors] Global slider set to \(rawFactorIntensity) from avgOffset \(avgOffset)")
    }
}

// MARK: - Weights & S-Curves
extension SimulationSettings {
    static let bullishWeights: [String: Double] = [
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
    
    static let bearishWeights: [String: Double] = [
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
    
    func applyGlobalSCurve(_ x: Double,
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
    
    func applyFactorSCurve(_ x: Double,
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
}
