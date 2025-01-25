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
        get { return true }
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

// MARK: - WEEKLY SIM
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
    
    // Turn e.g. "30.0" into 0.30
    let cagrDecimal = annualCAGR / 100.0
    // The base volatility if needed
    var baseWeeklyVol = (annualVolatility / 100.0) / sqrt(52.0)

    // GARCH init
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
    
    // For turning on/off higher or lower CAGR/Vol in different "regimes"
    var regimeModel = RegimeSwitchingModel()
    
    // The deposit amounts for first year vs second year
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    // If extended sampling is on, build a random block from extendedWeeklyReturns
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

    // Instead of a single lumpsum at year-end, we'll do "smooth" weekly growth
    // so that the total growth over 52 weeks approximates the annualCAGR.
    // For example, if cagrDecimal=0.30 => about +0.52% each week => (1.0052^52) ~1.30
    let weeklyGrowth = pow(1.0 + cagrDecimal, 1.0 / 52.0) - 1.0
    
    for currentWeek in 1...totalWeeklySteps {
        
        // If RegimeSwitching is on, adjust base CAGR & Vol each iteration
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
        }
        
        // Start fresh each loop
        var totalReturn = 0.0
        
        // Possibly scale your base volatility if regime switching is on
        var currentVol = baseWeeklyVol
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }
        if settings.useGarchVolatility {
            currentVol = garchModelToUse.currentStdDev()
        }
        
        // Historical sampling approach
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            var sample = extendedBlock[currentWeek - 1]
            sample = dampenArctanWeekly(sample)
            totalReturn += sample
        }
        else if settings.useHistoricalSampling {
            var sample = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
            sample = dampenArctanWeekly(sample)
            totalReturn += sample
        }
        
        // If the user wants a "smooth" (non-lognormal) approach that still yields ~30% a year,
        // then each week we do a small fraction so that after 52 it compounds to 30%.
        if settings.useAnnualStep {
            // Instead of lumpsum, let's do partial increments:
            totalReturn += weeklyGrowth
        }
        else if settings.useLognormalGrowth {
            // The old approach: each week just add 30%/52 => ~0.5769%,
            // but gets exponentiated => actual >30% year
            totalReturn += (cagrDecimal / 52.0)
        }
        
        // Optional volatility shocks
        if settings.useVolShocks && annualVolatility > 0 {
            let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
            totalReturn += shockVol
        }
        
        // Mean reversion
        if settings.useMeanReversion {
            let reversionFactor = 0.1
            let distance = (settings.meanReversionTarget - totalReturn)
            totalReturn += (reversionFactor * distance)
        }
        
        // AutoCorrelation
        if settings.useAutoCorrelation {
            let phi = settings.autoCorrelationStrength
            totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
        }
        
        // Factor toggles
        let toggled = applyFactorToggles(
            baseReturn: totalReturn,
            stepIndex: currentWeek,
            settings: settings,
            mempoolDataManager: mempoolDataManager,
            rng: rng
        )
        
        // Apply final step: multiply price by exp(toggled)
        prevBTCPriceUSD *= exp(toggled)
        
        // Keep track for next loop
        lastStepLogReturn = toggled
        lastAutoReturn    = toggled
        
        // Floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }

        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // DCA contributions
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
        
        // Withdraw thresholds
        let hypotheticalValueEUR = holdingsAfterDeposit * newPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0
        }
        let withdrawalBTC = withdrawalEUR / newPriceEUR
        let finalHoldings = max(0.0, holdingsAfterDeposit - withdrawalBTC)
        
        let portfolioValueEUR = finalHoldings * newPriceEUR
        let portfolioValueUSD = finalHoldings * newPriceUSD
        
        // Update GARCH
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

// MARK: - MONTHLY SIM
private func runMonthlySimulation(
    settings: SimulationSettings,
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
    
    let cagrDecimal = annualCAGR / 100.0
    let baseMonthlyVol = (annualVolatility / 100.0) / sqrt(12.0)

    // GARCH
    var garchModelToUse: GarchModel
    if let fitted = garchModel, settings.useGarchVolatility {
        let initialVol = baseMonthlyVol
        var copy = fitted
        copy.currentVariance = initialVol * initialVol
        garchModelToUse = copy
    } else {
        garchModelToUse = GarchModel(
            omega: 0.00001,
            alpha: 0.1,
            beta: 0.85,
            initialVariance: baseMonthlyVol * baseMonthlyVol
        )
    }
    
    var regimeModel = RegimeSwitchingModel()
    
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    // Extended sample if needed
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
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

    // Instead of lumpsum once/year, do monthly increments so 12 increments => ~30% total
    let monthlyGrowth = pow(1.0 + cagrDecimal, 1.0 / 12.0) - 1.0

    for currentMonth in 1...totalMonths {
        
        // Regime switching
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
        }
        
        var totalReturn = 0.0
        var currentVol = baseMonthlyVol
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }
        if settings.useGarchVolatility {
            currentVol = garchModelToUse.currentStdDev()
        }

        // Historical sample
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            var sample = extendedBlock[currentMonth - 1]
            sample = dampenArctanMonthly(sample)
            totalReturn += sample
        }
        else if settings.useHistoricalSampling {
            var sample = pickRandomReturn(from: historicalBTCMonthlyReturns, rng: rng)
            sample = dampenArctanMonthly(sample)
            totalReturn += sample
        }

        // If userAnnualStep => we do smaller monthly increments
        // so that after 12 months total is ~30%:
        if settings.useAnnualStep {
            totalReturn += monthlyGrowth
        }
        else if settings.useLognormalGrowth {
            // old monthly approach => cagr/12 each month (slightly different compounding)
            totalReturn += (cagrDecimal / 12.0)
        }
        
        if settings.useVolShocks && annualVolatility > 0 {
            let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
            totalReturn += shockVol
        }
        
        if settings.useMeanReversion {
            let reversionFactor = 0.1
            let distance = (settings.meanReversionTarget - totalReturn)
            totalReturn += (reversionFactor * distance)
        }
        if settings.useAutoCorrelation {
            let phi = settings.autoCorrelationStrength
            totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
        }
        
        let toggled = applyFactorToggles(
            baseReturn: totalReturn,
            stepIndex: currentMonth,
            settings: settings,
            mempoolDataManager: mempoolDataManager,
            rng: rng
        )
        
        // update price
        prevBTCPriceUSD *= exp(toggled)
        
        lastStepLogReturn = toggled
        lastAutoReturn    = toggled
        
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // DCA deposit
        var typedDeposit = 0.0
        if currentMonth == 1 {
            typedDeposit = settings.startingBalance
        } else if currentMonth <= 12 {
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
        
        // Withdraw thresholds
        let hypotheticalValueEUR = holdingsAfterDeposit * newPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0
        }
        let withdrawalBTC = withdrawalEUR / newPriceEUR
        let finalHoldings = max(0.0, holdingsAfterDeposit - withdrawalBTC)
        
        let portfolioValueEUR = finalHoldings * newPriceEUR
        let portfolioValueUSD = finalHoldings * newPriceUSD
        
        if settings.useGarchVolatility {
            garchModelToUse.updateVariance(lastReturn: lastStepLogReturn)
        }

        let dataPoint = SimulationData(
            week: currentMonth,
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

// MARK: - Single Simulation Entry
func runOneFullSimulation(
    settings: SimulationSettings,
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
            settings: settings,
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

// MARK: - Compute median BTC
fileprivate func computeMedianBTCPriceByStep(allRuns: [[SimulationData]]) -> [Decimal] {
    guard let steps = allRuns.first?.count, steps > 0 else { return [] }
    var medians = [Decimal](repeating: 0, count: steps)
    
    for stepIndex in 0..<steps {
        let pricesAtStep = allRuns.compactMap { run -> Decimal? in
            guard run.indices.contains(stepIndex) else { return nil }
            return run[stepIndex].btcPriceUSD
        }
        
        guard !pricesAtStep.isEmpty else {
            medians[stepIndex] = 0
            continue
        }
        
        let sortedPrices = pricesAtStep.sorted()
        let mid = sortedPrices.count / 2
        if sortedPrices.count % 2 == 0 {
            let p1 = sortedPrices[mid - 1]
            let p2 = sortedPrices[mid]
            medians[stepIndex] = (p1 + p2) / 2
        } else {
            medians[stepIndex] = sortedPrices[mid]
        }
    }
    return medians
}

// MARK: - runMonteCarloSimulationsWithProgress
func runMonteCarloSimulationsWithProgress(
    settings: SimulationSettings,
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
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: userWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: i + 1,
            rng: rng,
            mempoolDataManager: mempoolDataManager,
            garchModel: fittedGarchModel
        )
        allRuns.append(simRun)
        
        if isCancelled() { break }
        progressCallback(i + 1)
    }
    
    if allRuns.isEmpty {
        return ([], [], [])
    }
    
    // Sort runs by final EUR value, pick median
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    
    // Compute step-by-step median BTC
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)

    return (medianRun, allRuns, stepMedians)
}

// MARK: - Aligners for SP500 (optional)
func alignWeeklyData() {
    let minCount = min(historicalBTCWeeklyReturns.count, sp500WeeklyReturns.count)
    let partialBTC = Array(historicalBTCWeeklyReturns.prefix(minCount))
    let partialSP  = Array(sp500WeeklyReturns.prefix(minCount))
    
    combinedWeeklyData = zip(partialBTC, partialSP).map { (btc, sp) in
        (btc, sp)
    }
}

func alignMonthlyData() {
    let minCount = min(historicalBTCMonthlyReturns.count, sp500MonthlyReturns.count)
    let partialBTC = Array(historicalBTCMonthlyReturns.prefix(minCount))
    let partialSP  = Array(sp500MonthlyReturns.prefix(minCount))
    
    combinedMonthlyData = zip(partialBTC, partialSP).map { (btc, sp) in
        (btc, sp)
    }
}
