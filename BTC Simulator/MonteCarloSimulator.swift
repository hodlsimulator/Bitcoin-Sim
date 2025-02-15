//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI
import GameplayKit // for GKARC4RandomSource

// MARK: - Extend SimulationSettings to include our new toggle (example only)
extension SimulationSettings {
    /// If true, annualStepFactor mode will *ignore* mean reversion (even if useMeanReversion is on).
    /// If false, annualStepFactor mode will apply mean reversion as well.
    var disableMeanReversionWhenannualStepFactor: Bool {
        // If you still need logic here, implement it; otherwise keep returning true or false
        return true
    }
}

/// Hacky fix: if autocorr is on at startup, toggle it off/on once.
func fixAutocorrelationAtStartup(_ settings: SimulationSettings) {
    // Only do this if user actually has autocorr on
    if settings.useAutoCorrelation {
        print("Toggling autocorr off and on behind the scenes.")
        settings.useAutoCorrelation = false
        settings.useAutoCorrelation = true
    }
}

// MARK: - Global Arrays
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

var historicalBTCMonthlyReturns: [Double] = []
var sp500MonthlyReturns: [Double] = []

// MARK: - pickRandomReturn
public func pickRandomReturn(from arr: [Double], rng: GKRandomSource) -> Double {
    guard !arr.isEmpty else { return 0.0 }
    let idx = rng.nextInt(upperBound: arr.count)
    return arr[idx]
}

// MARK: - pickContiguousBlock
fileprivate func pickContiguousBlock(
    from source: [Double],
    count: Int,
    rng: GKRandomSource
) -> [Double] {
    guard source.count >= count else {
        return []
    }
    let maxStart = source.count - count
    let startIndex = rng.nextInt(upperBound: maxStart + 1)
    let endIndex = startIndex + count
    return Array(source[startIndex..<endIndex])
}

// MARK: - pickMultiChunkBlock
fileprivate func pickMultiChunkBlock(
    from source: [Double],
    totalNeeded: Int,
    rng: GKRandomSource,
    chunkSize: Int = 52
) -> [Double] {
    guard !source.isEmpty else {
        return []
    }
    var stitched = [Double]()
    while stitched.count < totalNeeded {
        if chunkSize > source.count {
            stitched.append(contentsOf: source)
        } else {
            let maxStart = source.count - chunkSize
            let startIndex = rng.nextInt(upperBound: maxStart + 1)
            let endIndex = startIndex + chunkSize
            let chunk = Array(source[startIndex..<endIndex])
            stitched.append(contentsOf: chunk)
        }
    }
    return Array(stitched.prefix(totalNeeded))
}

// MARK: - WEEKLY SIMULATION
private func runWeeklySimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeklySteps: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int,
    mempoolDataManager: MempoolDataManager,
    rng: GKRandomSource,
    garchModel: GarchModel? = nil
) -> [SimulationData] {
    var results = [SimulationData]()
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    // Convert CAGR percentage to decimal (e.g., 30.0% => 0.30)
    let cagrDecimal = annualCAGR / 100.0
    // Compute base weekly volatility (annual volatility scaled to weekly)
    var baseWeeklyVol = (annualVolatility / 100.0) / sqrt(52.0)
    
    // GARCH setup
    var garchModelToUse: GarchModel
    if let fitted = garchModel, settings.useGarchVolatility {
        let initialVol = baseWeeklyVol
        var copy = fitted
        copy.currentVariance = initialVol * initialVol
        garchModelToUse = copy
    } else {
        garchModelToUse = GarchModel(
            omega: 0.000001,
            alpha: 0.1,
            beta: 0.85,
            initialVariance: baseWeeklyVol * baseWeeklyVol
        )
    }
    
    // Regime switching
    var regimeModel = RegimeSwitchingModel()
    
    // DCA deposit amounts (example defaults)
    let firstYearVal  = 100.0
    let secondYearVal = 50.0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn = 0.0

    // Extended sampling if enabled
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        if totalWeeklySteps <= historicalBTCWeeklyReturns.count {
            extendedBlock = pickContiguousBlock(
                from: historicalBTCWeeklyReturns,
                count: totalWeeklySteps,
                rng: rng
            )
        } else {
            extendedBlock = pickMultiChunkBlock(
                from: historicalBTCWeeklyReturns,
                totalNeeded: totalWeeklySteps,
                rng: rng,
                chunkSize: 52
            )
        }
    }
    
    // Calculate weekly growth so that 52 increments yield the annual CAGR
    let weeklyGrowth = pow(1.0 + cagrDecimal, 1.0 / 52.0) - 1.0
    
    for currentWeek in 1...totalWeeklySteps {
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
        }
        
        var totalReturn = 0.0
        var currentVol = baseWeeklyVol
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }
        if settings.useGarchVolatility {
            currentVol = garchModelToUse.currentStdDev()
        }
        
        // Historical sampling
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            var sample = extendedBlock[currentWeek - 1]
            totalReturn += dampenArctanWeekly(sample)
        } else if settings.useHistoricalSampling {
            var sample = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
            totalReturn += dampenArctanWeekly(sample)
        }
        
        // Growth adjustments
        if settings.useAnnualStep {
            totalReturn += weeklyGrowth
        } else if settings.useLognormalGrowth {
            totalReturn += (cagrDecimal / 52.0)
        }
        
        // Volatility shocks
        if settings.useVolShocks && annualVolatility > 0 {
            let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
            totalReturn += shockVol
        }
        
        // Mean reversion adjustment
        if settings.useMeanReversion {
            let reversionFactor = 0.1
            let distance = (settings.meanReversionTarget - totalReturn)
            totalReturn += reversionFactor * distance
        }
        
        // AutoCorrelation
        if settings.useAutoCorrelation {
            let phi = settings.autoCorrelationStrength
            totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
        }
        
        // Apply additional factor toggles.
        let toggled = applyFactorToggles(
            baseReturn: totalReturn,
            stepIndex: currentWeek,
            settings: settings,
            mempoolDataManager: mempoolDataManager,
            rng: rng
        )
        
        // Update BTC price using log-return (i.e. exp(toggled))
        prevBTCPriceUSD *= exp(toggled)
        lastStepLogReturn = toggled
        lastAutoReturn = toggled
        
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // DCA contributions: use placeholder deposit amounts
        var typedDeposit = 0.0
        if currentWeek == 1 {
            typedDeposit = settings.startingBalance
        } else if currentWeek <= 52 {
            typedDeposit = firstYearVal
        } else {
            typedDeposit = secondYearVal
        }
        
        let (feeEUR, feeUSD, cEur, cUsd, depositBTC) = computeNetDeposit(
            typedDeposit: typedDeposit,
            settings: settings,
            btcPriceUSD: newPriceUSD,
            btcPriceEUR: newPriceEUR
        )
        
        let holdingsAfterDeposit = prevBTCHoldings + depositBTC
        
        // Withdrawal thresholds (placeholders)
        let hypotheticalValueEUR = holdingsAfterDeposit * newPriceEUR
        var withdrawalEUR = 0.0
        let threshold1 = 0.0
        let threshold2 = 0.0
        let withdrawAmount1 = 0.0
        let withdrawAmount2 = 0.0
        
        if hypotheticalValueEUR > threshold2 {
            withdrawalEUR = withdrawAmount2
        } else if hypotheticalValueEUR > threshold1 {
            withdrawalEUR = withdrawAmount1
        }
        let withdrawalBTC = withdrawalEUR / newPriceEUR
        let finalHoldings = max(0.0, holdingsAfterDeposit - withdrawalBTC)
        
        let portfolioValueEUR = finalHoldings * newPriceEUR
        let portfolioValueUSD = finalHoldings * newPriceUSD
        
        // Update GARCH variance
        if settings.useGarchVolatility {
            garchModelToUse.updateVariance(lastReturn: lastStepLogReturn)
        }
        
        let dataPoint = SimulationData(
            week: currentWeek,
            startingBTC: prevBTCHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(newPriceUSD),
            btcPriceEUR: Decimal(newPriceEUR),
            portfolioValueEUR: Decimal(portfolioValueEUR),
            portfolioValueUSD: Decimal(portfolioValueUSD),
            contributionEUR: cEur,
            contributionUSD: cUsd,
            transactionFeeEUR: feeEUR,
            transactionFeeUSD: feeUSD,
            netContributionBTC: depositBTC,
            withdrawalEUR: withdrawalEUR,
            withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
        )
        results.append(dataPoint)
        
        prevBTCHoldings = finalHoldings
    }
    
    return results
}

/// A version of runMonthlySimulation that reads from MonthlySimulationSettings directly.
private func runMonthlySimulation(
    monthlySettings: MonthlySimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalMonths: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int,
    mempoolDataManager: MempoolDataManager,
    rng: GKRandomSource,
    garchModel: GarchModel? = nil
) -> [SimulationData] {
    var results = [SimulationData]()
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    // Convert CAGR % to decimal
    let cagrDecimal = annualCAGR / 100.0
    // Base monthly volatility = annualVol / sqrt(12)
    let baseMonthlyVol = (annualVolatility / 100.0) / sqrt(12.0)
    
    // If monthlySettings.useGarchVolatilityMonthly == true, calibrate or apply a GARCH model
    var garchModelToUse: GarchModel
    if let fitted = garchModel, monthlySettings.useGarchVolatilityMonthly {
        var copy = fitted
        copy.currentVariance = baseMonthlyVol * baseMonthlyVol
        garchModelToUse = copy
    } else {
        garchModelToUse = GarchModel(
            omega: 0.00001,
            alpha: 0.1,
            beta:  0.85,
            initialVariance: baseMonthlyVol * baseMonthlyVol
        )
    }
    
    // If monthlySettings.useRegimeSwitchingMonthly == true, set up your regime switching model
    var regimeModel = RegimeSwitchingModel()
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    // Extended sampling if monthlySettings.useExtendedHistoricalSamplingMonthly == true
    var extendedBlock = [Double]()
    if monthlySettings.useExtendedHistoricalSamplingMonthly, !historicalBTCMonthlyReturns.isEmpty {
        if totalMonths <= historicalBTCMonthlyReturns.count {
            extendedBlock = pickContiguousBlock(
                from: historicalBTCMonthlyReturns,
                count: totalMonths,
                rng: rng
            )
        } else {
            extendedBlock = pickMultiChunkBlock(
                from: historicalBTCMonthlyReturns,
                totalNeeded: totalMonths,
                rng: rng,
                chunkSize: 12
            )
        }
    }

    // Compute monthly growth so 12 increments yield the annual CAGR
    let monthlyGrowth = pow(1.0 + cagrDecimal, 1.0 / 12.0) - 1.0
    
    for currentMonth in 1...totalMonths {
        
        // Optional: regime switching each month
        if monthlySettings.useRegimeSwitchingMonthly {
            regimeModel.updateRegime(rng: rng)
        }
        
        var totalReturn = 0.0
        var currentVol  = baseMonthlyVol
        
        // If regime switching is on, scale the base vol
        if monthlySettings.useRegimeSwitchingMonthly {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }
        if monthlySettings.useGarchVolatilityMonthly {
            currentVol = garchModelToUse.currentStdDev()
        }
        
        // Historical sampling if enabled
        if monthlySettings.useExtendedHistoricalSamplingMonthly, !extendedBlock.isEmpty {
            let sample = extendedBlock[currentMonth - 1]
            totalReturn += dampenArctanMonthly(sample)
        } else if monthlySettings.useHistoricalSamplingMonthly {
            let sample = pickRandomReturn(from: historicalBTCMonthlyReturns, rng: rng)
            totalReturn += dampenArctanMonthly(sample)
        }
        
        // Growth adjustments
        // (If you have a “useAnnualStepMonthly” or “useLognormalGrowthMonthly,” handle them)
        if monthlySettings.useLognormalGrowthMonthly {
            totalReturn += (cagrDecimal / 12.0)
        } else {
            // Example “annual step” approach
            totalReturn += monthlyGrowth
        }
        
        // Volatility shocks if monthlySettings.useVolShocksMonthly == true
        if monthlySettings.useVolShocksMonthly, annualVolatility > 0 {
            let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
            totalReturn += shockVol
        }
        
        // Mean reversion if monthlySettings.useMeanReversionMonthly == true
        if monthlySettings.useMeanReversionMonthly {
            let reversionFactor = 0.1
            let distance = (monthlySettings.meanReversionTargetMonthly - totalReturn)
            totalReturn += reversionFactor * distance
        }
        
        // Auto-correlation if monthlySettings.useAutoCorrelationMonthly == true
        if monthlySettings.useAutoCorrelationMonthly {
            let phi = monthlySettings.autoCorrelationStrengthMonthly
            totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
        }
        
        // Apply any monthly factor toggles (you need a monthly variant of this):
        let toggled = applyFactorTogglesMonthly(
            baseReturn: totalReturn,
            stepIndex: currentMonth,
            monthlySettings: monthlySettings,
            mempoolDataManager: mempoolDataManager,
            rng: rng
        )
        
        // Update BTC price with the final (log) return
        prevBTCPriceUSD *= exp(toggled)
        lastStepLogReturn = toggled
        lastAutoReturn    = toggled
        
        // Guard against negative or near-zero prices
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Example deposit logic (replace with actual monthlySimSettings)
        var typedDeposit = 0.0
        if currentMonth == 1 {
            typedDeposit = monthlySettings.startingBalanceMonthly
        } else if currentMonth <= 12 {
            typedDeposit = 100.0  // first-year deposit
        } else {
            typedDeposit = 50.0   // subsequent deposit
        }
        
        // Any function you have to compute deposit in BTC
        let (feeEUR, feeUSD, cEur, cUsd, depositBTC) = computeNetDepositMonthly(
            typedDeposit: typedDeposit,
            monthlySettings: monthlySettings,
            btcPriceUSD: newPriceUSD,
            btcPriceEUR: newPriceEUR
        )
        
        let holdingsAfterDeposit = prevBTCHoldings + depositBTC
        
        // Example withdrawal logic
        let hypotheticalValueEUR = holdingsAfterDeposit * newPriceEUR
        var withdrawalEUR = 0.0
        let threshold1 = 0.0
        let threshold2 = 0.0
        let withdrawAmount1 = 0.0
        let withdrawAmount2 = 0.0
        
        if hypotheticalValueEUR > threshold2 {
            withdrawalEUR = withdrawAmount2
        } else if hypotheticalValueEUR > threshold1 {
            withdrawalEUR = withdrawAmount1
        }
        let withdrawalBTC = withdrawalEUR / newPriceEUR
        let finalHoldings = max(0.0, holdingsAfterDeposit - withdrawalBTC)
        
        let portfolioValueEUR = finalHoldings * newPriceEUR
        let portfolioValueUSD = finalHoldings * newPriceUSD
        
        // Update GARCH variance
        if monthlySettings.useGarchVolatilityMonthly {
            garchModelToUse.updateVariance(lastReturn: lastStepLogReturn)
        }
        
        // Build up a SimulationData record
        let dataPoint = SimulationData(
            week: currentMonth,  // just reuse .week for indexing
            startingBTC: prevBTCHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(newPriceUSD),
            btcPriceEUR: Decimal(newPriceEUR),
            portfolioValueEUR: Decimal(portfolioValueEUR),
            portfolioValueUSD: Decimal(portfolioValueUSD),
            contributionEUR: cEur,
            contributionUSD: cUsd,
            transactionFeeEUR: feeEUR,
            transactionFeeUSD: feeUSD,
            netContributionBTC: depositBTC,
            withdrawalEUR: withdrawalEUR,
            withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
        )
        results.append(dataPoint)
        
        // Prepare for next iteration
        prevBTCHoldings = finalHoldings
    }
    
    return results
}

// MARK: - Single Simulation Entry
func runOneFullSimulation(
    settings: SimulationSettings,
    monthlySettings: MonthlySimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int = 0,
    rng: GKRandomSource,
    mempoolDataManager: MempoolDataManager? = nil,
    garchModel: GarchModel? = nil
) -> [SimulationData] {
    if settings.periodUnit == .months {
        let totalMonths = userWeeks
        return runMonthlySimulation(
            monthlySettings: monthlySettings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalMonths: totalMonths,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: iterationIndex,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            rng: rng,
            garchModel: garchModel
        )
    } else {
        let totalWeeks = userWeeks
        return runWeeklySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeklySteps: totalWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: iterationIndex,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            rng: rng,
            garchModel: garchModel
        )
    }
}

// MARK: - runMonteCarloSimulationsWithProgress
func runMonteCarloSimulationsWithProgress(
    settings: SimulationSettings,
    monthlySettings: MonthlySimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    iterations: Int,
    initialBTCPriceUSD: Double,
    isCancelled: () -> Bool,
    progressCallback: @escaping (Int) -> Void,
    seed: UInt64? = nil,
    mempoolDataManager: MempoolDataManager? = nil,
    fittedGarchModel: GarchModel? = nil
) -> (
    medianRun: [SimulationData],
    allRuns: [[SimulationData]],
    stepMedianPrices: [Decimal]
) {
    let rng: GKRandomSource
    if let validSeed = seed {
        let seedData = withUnsafeBytes(of: validSeed) { Data($0) }
        rng = GKARC4RandomSource(seed: seedData)
    } else {
        rng = GKARC4RandomSource()
    }
    
    var allRuns = [[SimulationData]]()
    
    for i in 0..<iterations {
        if isCancelled() { break }
        Thread.sleep(forTimeInterval: 0.01)
        
        let simRun = runOneFullSimulation(
            settings: settings,
            monthlySettings: monthlySettings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: userWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: i + 1,
            rng: rng,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            garchModel: fittedGarchModel
        )
        allRuns.append(simRun)
        if isCancelled() { break }
        progressCallback(i + 1)
    }
    
    if allRuns.isEmpty {
        return ([], [], [])
    }
    
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)
    
    return (medianRun, allRuns, stepMedians)
}

// MARK: - Aligners for SP500 Data (Optional)
func alignWeeklyData() {
    let minCount = min(historicalBTCWeeklyReturns.count, sp500WeeklyReturns.count)
    let partialBTC = Array(historicalBTCWeeklyReturns.prefix(minCount))
    let partialSP  = Array(sp500WeeklyReturns.prefix(minCount))
    combinedWeeklyData = zip(partialBTC, partialSP).map { (btc, sp) in (btc, sp) }
}

func alignMonthlyData() {
    let minCount = min(historicalBTCMonthlyReturns.count, sp500MonthlyReturns.count)
    let partialBTC = Array(historicalBTCMonthlyReturns.prefix(minCount))
    let partialSP  = Array(sp500MonthlyReturns.prefix(minCount))
    combinedMonthlyData = zip(partialBTC, partialSP).map { (btc, sp) in (btc, sp) }
}

// MARK: - Integration with Caching and Parallel Simulation Runner
func integrateSimulation() {
    HistoricalDataCache.shared.cacheWeeklyData(original: historicalBTCWeeklyReturns)
    HistoricalDataCache.shared.cacheMonthlyData(original: historicalBTCMonthlyReturns)
    
    let simulationSettings = SimulationSettings()
    let monthlySettings = MonthlySimulationSettings()
    let annualCAGR = 30.0
    let annualVolatility = 20.0
    let correlationWithSP500 = 0.0
    let exchangeRateEURUSD = 1.2
    let userWeeks = 52
    let initialBTCPriceUSD = 50000.0
    let iterations = 1000
    let seed: UInt64 = 12345
    let mempoolDataManager = MempoolDataManager(mempoolData: [])
    
    ParallelSimulationRunner.runSimulationsConcurrently(
        settings: simulationSettings,
        monthlySettings: monthlySettings,
        annualCAGR: annualCAGR,
        annualVolatility: annualVolatility,
        correlationWithSP500: correlationWithSP500,
        exchangeRateEURUSD: exchangeRateEURUSD,
        userWeeks: userWeeks,
        iterations: iterations,
        initialBTCPriceUSD: initialBTCPriceUSD,
        seed: seed,
        mempoolDataManager: mempoolDataManager,
        fittedGarchModel: nil,
        progressCallback: { progress in
            // Update progress UI here if needed.
        },
        completion: { medianRun, allRuns, stepMedians in
            // Process results or update the UI.
        }
    )
}

// Uncomment the line below to run the integrated simulation when appropriate
// integrateSimulation()
