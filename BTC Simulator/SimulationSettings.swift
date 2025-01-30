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
}
