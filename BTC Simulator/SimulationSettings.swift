//
//  SimulationSettings.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

protocol FactorAccessor {
    func get() -> Double
    func set(_ newValue: Double)
}

class SimulationSettings: ObservableObject {
    
    @Published var chartExtremeBearish: Bool = false
    @Published var chartExtremeBullish: Bool = false

    @Published var isRestoringDefaults: Bool = false
    
    @Published var factorAccessors: [String: FactorAccessor] = [:]
    
    /// Which factors are 'locked' and must not be re-synced by global slider.
    @Published var lockedFactors: Set<String> = []
    
    @Published var factors: [String: FactorState] = [:]
        
    // The global slider’s 0..1 value:
    // @Published var factorIntensity: Double = 0.5

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
    
    // ----- NEW: manual offsets -----
    @Published var manualOffsets: [String: Double] = [:]
    
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
    
    // MARK: - Tilt Bar Value (persisted)
    @Published var tiltBarValue: Double = 0.0 {
        didSet {
            guard isInitialized else { return }
            saveTiltBarValue()
        }
    }
    
    // MARK: - Global factor intensity
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    
    var inputManager: PersistentInputManager?
    
    // MARK: - Toggle All
    @Published var userIsActuallyTogglingAll = false {
        didSet {
            // When toggling finishes (becomes false), reset the tilt bar.
            if !userIsActuallyTogglingAll {
                resetTiltBar()
            }
        }
    }
    
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
    private let tiltBarValueKey = "tiltBarValue"
    
    // MARK: - Init
    init() {
        isUpdating = false
        isInitialized = false
        
        // Load user defaults
        loadFromUserDefaults()
        
        // If there's no baseline yet, set defaults so the tilt bar can move
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
    
    // MARK: - Tilt Bar Reset
    func resetTiltBar() {
        // Remove any stored tiltBarValue from UserDefaults
        UserDefaults.standard.removeObject(forKey: tiltBarValueKey)
        // Reset tilt properties to neutral values
        tiltBarValue = 0.0
        defaultTilt = 0.0
        maxSwing = 1.0
        hasCapturedDefault = true
        saveTiltState()
        saveTiltBarValue()
    }
    
    /// Converts a numeric value into a fraction (0..1) based on the factor's range.
    func fractionFromValue(_ factorName: String, value: Double, isWeekly: Bool) -> Double {
        let (minVal, maxVal) = factorRange(for: factorName, isWeekly: isWeekly)
        if maxVal <= minVal { return 0.0 }
        let rawFraction = (value - minVal) / (maxVal - minVal)
        return max(0.0, min(1.0, rawFraction))
    }
    
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
        
        if defaults.object(forKey: "useExtendedHistoricalSampling") == nil {
            useExtendedHistoricalSampling = true
        } else {
            useExtendedHistoricalSampling = defaults.bool(forKey: "useExtendedHistoricalSampling")
        }
        
        loadFactorEnableFrac()
        
        if defaults.object(forKey: "autoCorrelationStrength") == nil {
            autoCorrelationStrength = 0.05
        } else {
            autoCorrelationStrength = defaults.double(forKey: "autoCorrelationStrength")
        }
        
        if defaults.object(forKey: "meanReversionTarget") == nil {
            meanReversionTarget = 0.03
        } else {
            meanReversionTarget = defaults.double(forKey: "meanReversionTarget")
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
        } else {
            tiltBarValue = 0.0
        }
        
        // ----------------------------
        // BULLISH toggles (Load booleans)
        // ----------------------------
        if defaults.object(forKey: "useHalvingWeekly") != nil {
            useHalvingWeekly = defaults.bool(forKey: "useHalvingWeekly")
        }
        if defaults.object(forKey: "useHalvingMonthly") != nil {
            useHalvingMonthly = defaults.bool(forKey: "useHalvingMonthly")
        }
        
        if defaults.object(forKey: "useInstitutionalDemandWeekly") != nil {
            useInstitutionalDemandWeekly = defaults.bool(forKey: "useInstitutionalDemandWeekly")
        }
        if defaults.object(forKey: "useInstitutionalDemandMonthly") != nil {
            useInstitutionalDemandMonthly = defaults.bool(forKey: "useInstitutionalDemandMonthly")
        }
        
        if defaults.object(forKey: "useCountryAdoptionWeekly") != nil {
            useCountryAdoptionWeekly = defaults.bool(forKey: "useCountryAdoptionWeekly")
        }
        if defaults.object(forKey: "useCountryAdoptionMonthly") != nil {
            useCountryAdoptionMonthly = defaults.bool(forKey: "useCountryAdoptionMonthly")
        }
        
        if defaults.object(forKey: "useRegulatoryClarityWeekly") != nil {
            useRegulatoryClarityWeekly = defaults.bool(forKey: "useRegulatoryClarityWeekly")
        }
        if defaults.object(forKey: "useRegulatoryClarityMonthly") != nil {
            useRegulatoryClarityMonthly = defaults.bool(forKey: "useRegulatoryClarityMonthly")
        }
        
        if defaults.object(forKey: "useEtfApprovalWeekly") != nil {
            useEtfApprovalWeekly = defaults.bool(forKey: "useEtfApprovalWeekly")
        }
        if defaults.object(forKey: "useEtfApprovalMonthly") != nil {
            useEtfApprovalMonthly = defaults.bool(forKey: "useEtfApprovalMonthly")
        }
        
        if defaults.object(forKey: "useTechBreakthroughWeekly") != nil {
            useTechBreakthroughWeekly = defaults.bool(forKey: "useTechBreakthroughWeekly")
        }
        if defaults.object(forKey: "useTechBreakthroughMonthly") != nil {
            useTechBreakthroughMonthly = defaults.bool(forKey: "useTechBreakthroughMonthly")
        }
        
        if defaults.object(forKey: "useScarcityEventsWeekly") != nil {
            useScarcityEventsWeekly = defaults.bool(forKey: "useScarcityEventsWeekly")
        }
        if defaults.object(forKey: "useScarcityEventsMonthly") != nil {
            useScarcityEventsMonthly = defaults.bool(forKey: "useScarcityEventsMonthly")
        }
        
        if defaults.object(forKey: "useGlobalMacroHedgeWeekly") != nil {
            useGlobalMacroHedgeWeekly = defaults.bool(forKey: "useGlobalMacroHedgeWeekly")
        }
        if defaults.object(forKey: "useGlobalMacroHedgeMonthly") != nil {
            useGlobalMacroHedgeMonthly = defaults.bool(forKey: "useGlobalMacroHedgeMonthly")
        }
        
        if defaults.object(forKey: "useStablecoinShiftWeekly") != nil {
            useStablecoinShiftWeekly = defaults.bool(forKey: "useStablecoinShiftWeekly")
        }
        if defaults.object(forKey: "useStablecoinShiftMonthly") != nil {
            useStablecoinShiftMonthly = defaults.bool(forKey: "useStablecoinShiftMonthly")
        }
        
        if defaults.object(forKey: "useDemographicAdoptionWeekly") != nil {
            useDemographicAdoptionWeekly = defaults.bool(forKey: "useDemographicAdoptionWeekly")
        }
        if defaults.object(forKey: "useDemographicAdoptionMonthly") != nil {
            useDemographicAdoptionMonthly = defaults.bool(forKey: "useDemographicAdoptionMonthly")
        }
        
        if defaults.object(forKey: "useAltcoinFlightWeekly") != nil {
            useAltcoinFlightWeekly = defaults.bool(forKey: "useAltcoinFlightWeekly")
        }
        if defaults.object(forKey: "useAltcoinFlightMonthly") != nil {
            useAltcoinFlightMonthly = defaults.bool(forKey: "useAltcoinFlightMonthly")
        }
        
        if defaults.object(forKey: "useAdoptionFactorWeekly") != nil {
            useAdoptionFactorWeekly = defaults.bool(forKey: "useAdoptionFactorWeekly")
        }
        if defaults.object(forKey: "useAdoptionFactorMonthly") != nil {
            useAdoptionFactorMonthly = defaults.bool(forKey: "useAdoptionFactorMonthly")
        }
        
        // ----------------------------
        // BEARISH toggles (Load booleans)
        // ----------------------------
        if defaults.object(forKey: "useRegClampdownWeekly") != nil {
            useRegClampdownWeekly = defaults.bool(forKey: "useRegClampdownWeekly")
        }
        if defaults.object(forKey: "useRegClampdownMonthly") != nil {
            useRegClampdownMonthly = defaults.bool(forKey: "useRegClampdownMonthly")
        }
        
        if defaults.object(forKey: "useCompetitorCoinWeekly") != nil {
            useCompetitorCoinWeekly = defaults.bool(forKey: "useCompetitorCoinWeekly")
        }
        if defaults.object(forKey: "useCompetitorCoinMonthly") != nil {
            useCompetitorCoinMonthly = defaults.bool(forKey: "useCompetitorCoinMonthly")
        }
        
        if defaults.object(forKey: "useSecurityBreachWeekly") != nil {
            useSecurityBreachWeekly = defaults.bool(forKey: "useSecurityBreachWeekly")
        }
        if defaults.object(forKey: "useSecurityBreachMonthly") != nil {
            useSecurityBreachMonthly = defaults.bool(forKey: "useSecurityBreachMonthly")
        }
        
        if defaults.object(forKey: "useBubblePopWeekly") != nil {
            useBubblePopWeekly = defaults.bool(forKey: "useBubblePopWeekly")
        }
        if defaults.object(forKey: "useBubblePopMonthly") != nil {
            useBubblePopMonthly = defaults.bool(forKey: "useBubblePopMonthly")
        }
        
        if defaults.object(forKey: "useStablecoinMeltdownWeekly") != nil {
            useStablecoinMeltdownWeekly = defaults.bool(forKey: "useStablecoinMeltdownWeekly")
        }
        if defaults.object(forKey: "useStablecoinMeltdownMonthly") != nil {
            useStablecoinMeltdownMonthly = defaults.bool(forKey: "useStablecoinMeltdownMonthly")
        }
        
        if defaults.object(forKey: "useBlackSwanWeekly") != nil {
            useBlackSwanWeekly = defaults.bool(forKey: "useBlackSwanWeekly")
        }
        if defaults.object(forKey: "useBlackSwanMonthly") != nil {
            useBlackSwanMonthly = defaults.bool(forKey: "useBlackSwanMonthly")
        }
        
        if defaults.object(forKey: "useBearMarketWeekly") != nil {
            useBearMarketWeekly = defaults.bool(forKey: "useBearMarketWeekly")
        }
        if defaults.object(forKey: "useBearMarketMonthly") != nil {
            useBearMarketMonthly = defaults.bool(forKey: "useBearMarketMonthly")
        }
        
        if defaults.object(forKey: "useMaturingMarketWeekly") != nil {
            useMaturingMarketWeekly = defaults.bool(forKey: "useMaturingMarketWeekly")
        }
        if defaults.object(forKey: "useMaturingMarketMonthly") != nil {
            useMaturingMarketMonthly = defaults.bool(forKey: "useMaturingMarketMonthly")
        }
        
        if defaults.object(forKey: "useRecessionWeekly") != nil {
            useRecessionWeekly = defaults.bool(forKey: "useRecessionWeekly")
        }
        if defaults.object(forKey: "useRecessionMonthly") != nil {
            useRecessionMonthly = defaults.bool(forKey: "useRecessionMonthly")
        }
        
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
    
    private func saveTiltState() {
        let defaults = UserDefaults.standard
        defaults.set(defaultTilt, forKey: defaultTiltKey)
        defaults.set(maxSwing, forKey: maxSwingKey)
        defaults.set(hasCapturedDefault, forKey: hasCapturedDefaultKey)
    }
    
    private func saveTiltBarValue() {
        UserDefaults.standard.set(tiltBarValue, forKey: tiltBarValueKey)
    }
    
    // MARK: - Factor Range Helpers
    func factorRange(for factorName: String, isWeekly: Bool) -> (Double, Double) {
        switch factorName {
        case "Halving":
            return isWeekly ? (0.2773386887, 0.3823386887) : (0.2975, 0.4025)
        case "InstitutionalDemand":
            return isWeekly ? (0.00105315, 0.00142485) : (0.0048101384, 0.0065078326)
        case "CountryAdoption":
            return isWeekly ? (0.0009882799977, 0.0012868959977) : (0.004688188952320099, 0.006342842952320099)
        case "RegulatoryClarity":
            return isWeekly ? (0.0005979474861605167, 0.0008361034861605167) : (0.0034626727, 0.0046847927)
        case "EtfApproval":
            return isWeekly ? (0.0014880183160305023, 0.0020880183160305023) : (0.0048571421, 0.0065714281)
        case "TechBreakthrough":
            return isWeekly ? (0.0005015753579173088, 0.0007150633579173088) : (0.0024129091, 0.0032645091)
        case "ScarcityEvents":
            return isWeekly ? (0.00035112353681182863, 0.00047505153681182863) : (0.0027989405475521085, 0.0037868005475521085)
        case "GlobalMacroHedge":
            return isWeekly ? (0.0002868789724932909, 0.0004126829724932909) : (0.0027576037, 0.0037308757)
        case "StablecoinShift":
            return isWeekly ? (0.0002704809116327763, 0.0003919609116327763) : (0.0019585255, 0.0026497695)
        case "DemographicAdoption":
            return isWeekly ? (0.0008661432036626339, 0.0012578432036626339) : (0.006197455714649915, 0.008384793714649915)
        case "AltcoinFlight":
            return isWeekly ? (0.0002381864461803342, 0.0003222524461803342) : (0.0018331797, 0.0024801837)
        case "AdoptionFactor":
            return isWeekly ? (0.0013638349088897705, 0.0018451869088897705) : (0.012461815934071304, 0.016860103934071304)
        case "RegClampdown":
            return isWeekly ? (-0.0014273392243542672, -0.0008449512243542672) : (-0.023, -0.017)
        case "CompetitorCoin":
            return isWeekly ? (-0.0011842141746411323, -0.0008454221746411323) : (-0.0092, -0.0068)
        case "SecurityBreach":
            return isWeekly ? (-0.0012819675168380737, -0.0009009755168380737) : (-0.00805, -0.00595)
        case "BubblePop":
            return isWeekly ? (-0.002244817890762329, -0.001280529890762329) : (-0.0115, -0.0085)
        case "StablecoinMeltdown":
            return isWeekly ? (-0.0009681346159477233, -0.0004600706159477233) : (-0.013, -0.007)
        case "BlackSwan":
            return isWeekly ? (-0.478662, -0.319108) : (-0.48, -0.32)
        case "BearMarket":
            return isWeekly ? (-0.0010278802752494812, -0.0007278802752494812) : (-0.013, -0.007)
        case "MaturingMarket":
            return isWeekly ? (-0.0020343461055486196, -0.0010537001055486196) : (-0.013, -0.007)
        case "Recession":
            return isWeekly ? (-0.0010516462467487811, -0.0007494520467487811) : (-0.0015958890, -0.0013057270)
        default:
            return (0.0, 1.0)
        }
    }
    
    /// Computes the base value for a factor based on the global factorIntensity.
    func baseValForFactor(_ factorName: String, intensity: Double) -> Double {
        let isWeekly = (periodUnit == .weeks)
        let (minVal, maxVal) = factorRange(for: factorName, isWeekly: isWeekly)
        let midVal = (minVal + maxVal) / 2.0
        
        if intensity < 0.5 {
            let ratio = intensity / 0.5
            return midVal - (midVal - minVal) * (1.0 - ratio)
        } else {
            let ratio = (intensity - 0.5) / 0.5
            return midVal + (maxVal - midVal) * ratio
        }
    }
    
    /// Syncs a factor's value to the global intensity plus any manual offset.
    func syncSingleFactorToIntensity(_ factorName: String) {
        guard let frac = factorEnableFrac[factorName], frac > 0 else { return }
        let base = baseValForFactor(factorName, intensity: factorIntensity)
        let offset = manualOffsets[factorName] ?? 0.0
        let newVal = base + offset
        setNumericValue(for: factorName, to: newVal)
    }
    
    /// Updates the manual offset when a factor's slider is changed.
    func updateManualOffset(factorName: String, actualValue: Double) {
        let base = baseValForFactor(factorName, intensity: factorIntensity)
        manualOffsets[factorName] = actualValue - base
    }
    
    /// Sets the new numeric value for a given factor.
    func setNumericValue(for factorName: String, to newVal: Double) {
        switch factorName {
        case "Halving":
            halvingBumpUnified = newVal
        case "InstitutionalDemand":
            maxDemandBoostUnified = newVal
        case "CountryAdoption":
            maxCountryAdBoostUnified = newVal
        case "RegulatoryClarity":
            maxClarityBoostUnified = newVal
        case "EtfApproval":
            maxEtfBoostUnified = newVal
        case "TechBreakthrough":
            maxTechBoostUnified = newVal
        case "ScarcityEvents":
            maxScarcityBoostUnified = newVal
        case "GlobalMacroHedge":
            maxMacroBoostUnified = newVal
        case "StablecoinShift":
            maxStablecoinBoostUnified = newVal
        case "DemographicAdoption":
            maxDemoBoostUnified = newVal
        case "AltcoinFlight":
            maxAltcoinBoostUnified = newVal
        case "AdoptionFactor":
            adoptionBaseFactorUnified = newVal
        case "RegClampdown":
            maxClampDownUnified = newVal
        case "CompetitorCoin":
            maxCompetitorBoostUnified = newVal
        case "SecurityBreach":
            breachImpactUnified = newVal
        case "BubblePop":
            maxPopDropUnified = newVal
        case "StablecoinMeltdown":
            maxMeltdownDropUnified = newVal
        case "BlackSwan":
            blackSwanDropUnified = newVal
        case "BearMarket":
            bearWeeklyDriftUnified = newVal
        case "MaturingMarket":
            maxMaturingDropUnified = newVal
        case "Recession":
            maxRecessionDropUnified = newVal
        default:
            break
        }
    }
}
