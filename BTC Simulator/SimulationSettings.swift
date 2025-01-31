//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class SimulationSettings: ObservableObject {
    
    // MARK: - Factor Toggling
    @Published var factorEnableFrac: [String: Double] = [
        "Halving": 1.0,
        "InstitutionalDemand": 1.0,
        "CountryAdoption": 1.0,
        "RegulatoryClarity": 1.0,
        "EtfApproval": 1.0,
        "TechBreakthrough": 1.0,
        "ScarcityEvents": 1.0,
        "GlobalMacroHedge": 1.0,
        "StablecoinShift": 1.0,
        "DemographicAdoption": 1.0,
        "AltcoinFlight": 1.0,
        "AdoptionFactor": 1.0,
        "RegClampdown": 1.0,
        "CompetitorCoin": 1.0,
        "SecurityBreach": 1.0,
        "BubblePop": 1.0,
        "StablecoinMeltdown": 1.0,
        "BlackSwan": 1.0,
        "BearMarket": 1.0,
        "MaturingMarket": 1.0,
        "Recession": 1.0,
    ] {
        didSet {
            guard isInitialized else { return }
            saveFactorEnableFrac()
        }
    }

    // MARK: - Tilt Baseline
    @Published var defaultTilt: Double = 0.0 {
        didSet {
            guard isInitialized else { return }
            saveTiltState()
        }
    }
    
    @Published var maxSwing: Double = 1.0 {
        didSet {
            guard isInitialized else { return }
            saveTiltState()
        }
    }
    
    @Published var hasCapturedDefault: Bool = false {
        didSet {
            guard isInitialized else { return }
            saveTiltState()
        }
    }
    
    // MARK: - Tilt Bar Value (newly added for persistence)
    @Published var tiltBarValue: Double = 0.0 {
        didSet {
            // Only save after init is done
            guard isInitialized else { return }
            saveTiltBarValue()
        }
    }
    
    // Global factor intensity
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    
    var inputManager: PersistentInputManager?
    
    @Published var userIsActuallyTogglingAll = false
    @Published var isOnboarding: Bool = false
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet {
            guard isInitialized else { return }
            print("didSet: periodUnit changed to \(periodUnit)")
        }
    }
    
    @Published var userPeriods: Int = 52
    @Published var initialBTCPriceUSD: Double = 58000.0
    @Published var startingBalance: Double = 0.0
    @Published var averageCostBasis: Double = 25000.0
    @Published var currencyPreference: PreferredCurrency = .eur {
        didSet {
            guard isInitialized else { return }
            print("didSet: currencyPreference changed to \(currencyPreference)")
            UserDefaults.standard.set(currencyPreference.rawValue, forKey: "currencyPreference")
        }
    }
    @Published var contributionCurrencyWhenBoth: PreferredCurrency = .eur
    @Published var startingBalanceCurrencyWhenBoth: PreferredCurrency = .usd
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    var isInitialized = false
    var isUpdating = false
    
    // MARK: - Settings Toggles
    @Published var useLognormalGrowth: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useLognormalGrowth changed to \(useLognormalGrowth)")
            UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
            
            // Force annualStep true whenever lognormalGrowth is turned off
            if !useLognormalGrowth {
                useAnnualStep = true
            }
        }
    }
    
    @Published var useAnnualStep: Bool = false {
        didSet {
            guard isInitialized else { return }
            print("didSet: useAnnualStep changed to \(useAnnualStep)")
            UserDefaults.standard.set(useAnnualStep, forKey: "useAnnualStep")
        }
    }
    
    @Published var lockedRandomSeed: Bool = false {
        didSet {
            guard isInitialized else { return }
            print("didSet: lockedRandomSeed changed to \(lockedRandomSeed)")
            UserDefaults.standard.set(lockedRandomSeed, forKey: "lockedRandomSeed")
        }
    }
    
    @Published var seedValue: UInt64 = 0 {
        didSet {
            guard isInitialized else { return }
            print("didSet: seedValue changed to \(seedValue)")
            UserDefaults.standard.set(seedValue, forKey: "seedValue")
        }
    }
    
    @Published var useRandomSeed: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useRandomSeed changed to \(useRandomSeed)")
            UserDefaults.standard.set(useRandomSeed, forKey: "useRandomSeed")
        }
    }
    
    @Published var useHistoricalSampling: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useHistoricalSampling changed to \(useHistoricalSampling)")
            UserDefaults.standard.set(useHistoricalSampling, forKey: "useHistoricalSampling")
        }
    }
    
    @Published var useExtendedHistoricalSampling: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useExtendedHistoricalSampling changed to \(useExtendedHistoricalSampling)")
            UserDefaults.standard.set(useExtendedHistoricalSampling, forKey: "useExtendedHistoricalSampling")
        }
    }
    
    @Published var useVolShocks: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useVolShocks changed to \(useVolShocks)")
            UserDefaults.standard.set(useVolShocks, forKey: "useVolShocks")
        }
    }
    
    @Published var useGarchVolatility: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useGarchVolatility changed to \(useGarchVolatility)")
            UserDefaults.standard.set(useGarchVolatility, forKey: "useGarchVolatility")
        }
    }
    
    @Published var useAutoCorrelation: Bool = false {
        didSet {
            guard isInitialized else { return }
            print("didSet: useAutoCorrelation changed to \(useAutoCorrelation)")
            UserDefaults.standard.set(useAutoCorrelation, forKey: "useAutoCorrelation")
            
            // Force meanReversion off whenever autocorrelation is turned off
            if !useAutoCorrelation {
                useMeanReversion = false
            }
        }
    }
    
    @Published var autoCorrelationStrength: Double = 0.2 {
        didSet {
            guard isInitialized else { return }
            print("didSet: autoCorrelationStrength changed to \(autoCorrelationStrength)")
            UserDefaults.standard.set(autoCorrelationStrength, forKey: "autoCorrelationStrength")
        }
    }
    
    @Published var meanReversionTarget: Double = 0.0 {
        didSet {
            guard isInitialized else { return }
            print("didSet: meanReversionTarget changed to \(meanReversionTarget)")
            UserDefaults.standard.set(meanReversionTarget, forKey: "meanReversionTarget")
        }
    }
    
    @Published var useMeanReversion: Bool = true {
        didSet {
            guard isInitialized else { return }
            print("didSet: useMeanReversion changed to \(useMeanReversion)")
            UserDefaults.standard.set(useMeanReversion, forKey: "useMeanReversion")
        }
    }
    
    @Published var lastUsedSeed: UInt64 = 0
    @Published var lockHistoricalSampling: Bool = false {
        didSet {
            guard isInitialized else { return }
            print("didSet: lockHistoricalSampling changed to \(lockHistoricalSampling)")
            UserDefaults.standard.set(lockHistoricalSampling, forKey: "lockHistoricalSampling")
        }
    }
    
    // MARK: - Regime Switching Toggle
    @Published var useRegimeSwitching: Bool = false {
        didSet {
            guard isInitialized else { return }
            print("didSet: useRegimeSwitching changed to \(useRegimeSwitching)")
            UserDefaults.standard.set(useRegimeSwitching, forKey: "useRegimeSwitching")
        }
    }
    
    // MARK: - Private keys
    private let factorEnableFracKey = "factorEnableFrac"
    private let defaultTiltKey = "defaultTilt"
    private let maxSwingKey = "maxSwing"
    private let hasCapturedDefaultKey = "capturedTilt"
    private let tiltBarValueKey = "tiltBarValue" // new
    
    // MARK: - Init
    init() {
        isUpdating = false
        isInitialized = false
        
        // Load user defaults
        loadFromUserDefaults()
        
        // If there's no baseline set yet, provide a default so tilt bar can move
        if !hasCapturedDefault {
            defaultTilt = 0.0
            maxSwing = 1.0
            hasCapturedDefault = true
            saveTiltState()
        }
        
        // Now ready to respond to changes
        isInitialized = true
    }
    
    func finalizeToggleStateAfterLoad() {
        isUpdating = false
    }
    
    // MARK: - Example helpers
    private func turnOffMonthlyToggles() { /* omitted for brevity */ }
    private func turnOffWeeklyToggles() { /* omitted for brevity */ }
    
    // MARK: - UserDefaults Handling
    
    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        
        // Temporarily mark as not initialized
        isInitialized = false
        
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
        
        // Extended sampling
        if defaults.object(forKey: "useExtendedHistoricalSampling") == nil {
            useExtendedHistoricalSampling = true
        } else {
            useExtendedHistoricalSampling = defaults.bool(forKey: "useExtendedHistoricalSampling")
        }
        
        // factorEnableFrac
        loadFactorEnableFrac()
        
        // Autocorrelation default
        if defaults.object(forKey: "autoCorrelationStrength") == nil {
            autoCorrelationStrength = 0.05
        } else {
            autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        }
        
        // Mean reversion default
        if defaults.object(forKey: "meanReversionTarget") == nil {
            meanReversionTarget = 0.03
        } else {
            meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
        }
        
        // Mean reversion toggle default
        if defaults.object(forKey: "useMeanReversion") == nil {
            useMeanReversion = true
        } else {
            useMeanReversion = defaults.bool(forKey: "useMeanReversion")
        }
        
        // Load tilt properties
        if defaults.object(forKey: defaultTiltKey) != nil {
            defaultTilt = defaults.double(forKey: defaultTiltKey)
        }
        if defaults.object(forKey: maxSwingKey) != nil {
            maxSwing = defaults.double(forKey: maxSwingKey)
        }
        if defaults.object(forKey: hasCapturedDefaultKey) != nil {
            hasCapturedDefault = defaults.bool(forKey: hasCapturedDefaultKey)
        }
        
        // Load tiltBarValue
        if defaults.object(forKey: tiltBarValueKey) != nil {
            tiltBarValue = defaults.double(forKey: tiltBarValueKey)
        } else {
            tiltBarValue = 0.0
        }
        
        // Mark as initialized now that we've loaded everything
        isInitialized = true
    }
    
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
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
        
        defaults.synchronize()
    }
    
    // Save the tilt baseline to UserDefaults
    private func saveTiltState() {
        let defaults = UserDefaults.standard
        defaults.set(defaultTilt, forKey: defaultTiltKey)
        defaults.set(maxSwing, forKey: maxSwingKey)
        defaults.set(hasCapturedDefault, forKey: hasCapturedDefaultKey)
    }
    
    private func loadFactorEnableFrac() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: factorEnableFracKey),
           let loaded = try? JSONDecoder().decode([String: Double].self, from: data) {
            factorEnableFrac = loaded
        }
    }
    
    private func saveFactorEnableFrac() {
        let defaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(factorEnableFrac) {
            defaults.set(encoded, forKey: factorEnableFracKey)
        }
    }
    
    // Save the tilt bar value
    private func saveTiltBarValue() {
        UserDefaults.standard.set(tiltBarValue, forKey: tiltBarValueKey)
    }
}

// MARK: - Factor Range Helpers (Fraction <-> Value)
// ------------------------------------------------
// Example approach: for each factor, define the numeric range in weeks vs. monthly.
// We do a simple linear map of [minVal..maxVal] onto [0..1] for the tilt fraction.

extension SimulationSettings {
    
    /// Converts a real numeric value into a 0..1 fraction for the tilt.
    /// If factor is unknown, we default to clamping in [0..1].
    func fractionFromValue(_ factorName: String, value: Double, isWeekly: Bool) -> Double {
        let (minVal, maxVal) = factorRange(for: factorName, isWeekly: isWeekly)
        
        // linear mapping to 0..1
        if maxVal <= minVal { return 0.0 }
        let rawFraction = (value - minVal) / (maxVal - minVal)
        return max(0.0, min(1.0, rawFraction))
    }
    
    /// Converts a 0..1 fraction back to a real numeric value for the model.
    func valueFromFraction(_ factorName: String, fraction: Double, isWeekly: Bool) -> Double {
        let (minVal, maxVal) = factorRange(for: factorName, isWeekly: isWeekly)
        
        // linear mapping from fraction to value
        let clippedFrac = max(0.0, min(1.0, fraction))
        return (clippedFrac * (maxVal - minVal)) + minVal
    }
    
    /// Return (minVal, maxVal) for the factor depending on weekly vs. monthly.
    /// You can fill in all your factors here.
    func factorRange(for factorName: String, isWeekly: Bool) -> (Double, Double) {
        switch factorName {
        // ------ Bullish Factors ------
        case "Halving":
            return isWeekly
                ? (0.2773386887, 0.3823386887)
                : (0.2975, 0.4025)
            
        case "InstitutionalDemand":
            return isWeekly
                ? (0.00105315, 0.00142485)
                : (0.0048101384, 0.0065078326)
            
        case "CountryAdoption":
            return isWeekly
                ? (0.0009882799977, 0.0012868959977)
                : (0.004688188952320099, 0.006342842952320099)
            
        case "RegulatoryClarity":
            return isWeekly
                ? (0.0005979474861605167, 0.0008361034861605167)
                : (0.0034626727, 0.0046847927)
            
        case "EtfApproval":
            return isWeekly
                ? (0.0014880183160305023, 0.0020880183160305023)
                : (0.0048571421, 0.0065714281)
            
        case "TechBreakthrough":
            return isWeekly
                ? (0.0005015753579173088, 0.0007150633579173088)
                : (0.0024129091, 0.0032645091)
            
        case "ScarcityEvents":
            return isWeekly
                ? (0.00035112353681182863, 0.00047505153681182863)
                : (0.0027989405475521085, 0.0037868005475521085)
            
        case "GlobalMacroHedge":
            return isWeekly
                ? (0.0002868789724932909, 0.0004126829724932909)
                : (0.0027576037, 0.0037308757)
            
        case "StablecoinShift":
            return isWeekly
                ? (0.0002704809116327763, 0.0003919609116327763)
                : (0.0019585255, 0.0026497695)
            
        case "DemographicAdoption":
            return isWeekly
                ? (0.0008661432036626339, 0.0012578432036626339)
                : (0.006197455714649915, 0.008384793714649915)
            
        case "AltcoinFlight":
            return isWeekly
                ? (0.0002381864461803342, 0.0003222524461803342)
                : (0.0018331797, 0.0024801837)
            
        case "AdoptionFactor":
            return isWeekly
                ? (0.0013638349088897705, 0.0018451869088897705)
                : (0.012461815934071304, 0.016860103934071304)
            
        // ------ Bearish Factors ------
        case "RegClampdown":
            return isWeekly
                ? (-0.0014273392243542672, -0.0008449512243542672)
                : (-0.023, -0.017)
            
        case "CompetitorCoin":
            return isWeekly
                ? (-0.0011842141746411323, -0.0008454221746411323)
                : (-0.0092, -0.0068)
            
        case "SecurityBreach":
            return isWeekly
                ? (-0.0012819675168380737, -0.0009009755168380737)
                : (-0.00805, -0.00595)
            
        case "BubblePop":
            return isWeekly
                ? (-0.002244817890762329, -0.001280529890762329)
                : (-0.0115, -0.0085)
            
        case "StablecoinMeltdown":
            return isWeekly
                ? (-0.0009681346159477233, -0.0004600706159477233)
                : (-0.013, -0.007)
            
        case "BlackSwan":
            // Big negative range
            return isWeekly
                ? (-0.478662, -0.319108)
                : (-0.48, -0.32)
            
        case "BearMarket":
            return isWeekly
                ? (-0.0010278802752494812, -0.0007278802752494812)
                : (-0.013, -0.007)
            
        case "MaturingMarket":
            return isWeekly
                ? (-0.0020343461055486196, -0.0010537001055486196)
                : (-0.013, -0.007)
            
        case "Recession":
            return isWeekly
                ? (-0.0010516462467487811, -0.0007494520467487811)
                : (-0.0015958890, -0.0013057270)
            
        default:
            // Fallback
            return (0.0, 1.0)
        }
    }
}
