import SwiftUI

class SimulationSettings: ObservableObject {
    
    @Published var chartExtremeBearish: Bool = false
    @Published var chartExtremeBullish: Bool = false
    @Published var isRestoringDefaults: Bool = false
    
    /// Our one dictionary of factors
    @Published var factors: [String: FactorState] = [:]
    
    /// Which factors are 'locked' so they won’t be changed by the global slider
    @Published var lockedFactors: Set<String> = []
    
    /// The global factor intensity slider (0..1)
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    
    // Tilt bar stuff
    @Published var defaultTilt: Double = 0.0
    @Published var maxSwing: Double = 1.0
    @Published var hasCapturedDefault: Bool = false
    @Published var tiltBarValue: Double = 0.0
    
    // Toggling everything on/off in one go
    @Published var userIsActuallyTogglingAll = false {
        didSet {
            // When toggling finishes, reset the tilt bar
            if !userIsActuallyTogglingAll {
                resetTiltBar()
            }
        }
    }
    
    @Published var isOnboarding: Bool = false
    @Published var periodUnit: PeriodUnit = .weeks {
        didSet { if isInitialized { print("didSet: periodUnit changed to \(periodUnit)") } }
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
    @Published var lastRunResults: [SimulationData] = []
    @Published var allRuns: [[SimulationData]] = []
    
    var isInitialized = false
    var isUpdating = false
    
    // MARK: - Settings Toggles
    @Published var useLognormalGrowth: Bool = true {
        didSet {
            if isInitialized {
                print("didSet: useLognormalGrowth changed to \(useLognormalGrowth)")
                UserDefaults.standard.set(useLognormalGrowth, forKey: "useLognormalGrowth")
                // If not using lognormal, force annual step
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
                // If autocorrelation is turned off, also turn off mean reversion
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
    
    private let defaultTiltKey = "defaultTilt"
    private let maxSwingKey = "maxSwing"
    private let hasCapturedDefaultKey = "capturedTilt"
    private let tiltBarValueKey = "tiltBarValue"
    
    init() {
        isUpdating = false
        isInitialized = false
        
        loadFromUserDefaults()
        
        // If no baseline was captured, set some defaults so the tilt bar can move
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
        
        // Tilt values
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
        
        // Load any saved userPeriods, initialBTCPrice, etc.
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
        
        // Finally, build the factors dictionary from FactorCatalog
        factors.removeAll()
        for (factorName, def) in FactorCatalog.all {
            // We can decide whether to enable each factor by default.
            // For simplicity, let’s set isEnabled = false until user toggles.
            // Or we can store an "isEnabled" boolean in UserDefaults keyed by factorName if you want.
            let isEnabled = false
            
            // Choose period-based range
            let (minVal, midVal, maxVal) = (periodUnit == .weeks)
                ? (def.minWeekly, def.midWeekly, def.maxWeekly)
                : (def.minMonthly, def.midMonthly, def.maxMonthly)
            
            // Just use midVal as the starting currentValue
            let fs = FactorState(
                name: factorName,
                isEnabled: isEnabled,
                isLocked: false,
                currentValue: midVal,
                minValue: minVal,
                maxValue: maxVal,
                defaultValue: midVal
            )
            factors[factorName] = fs
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
        
        // If you want to persist factor isEnabled/currentValue, do so here.
        // e.g. using a dictionary keyed by factorName. Example:
        /*
        var storedStates: [String: (Bool, Double)] = [:]
        for (name, factor) in factors {
            storedStates[name] = (factor.isEnabled, factor.currentValue)
        }
        if let encoded = try? JSONEncoder().encode(storedStates) {
            defaults.set(encoded, forKey: "factorStates")
        }
        */
        
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
    
    // MARK: - Toggling All Example
    func toggleAllFactors(on: Bool) {
        for (name, var factor) in factors {
            factor.isEnabled = on
            if on {
                // If turning on, reset to defaultValue
                factor.currentValue = factor.defaultValue
                factor.isLocked = false
            }
            factors[name] = factor
        }
    }
}
