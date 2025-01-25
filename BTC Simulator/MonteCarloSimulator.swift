//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI
import GameplayKit // for GKARC4RandomSource

// MARK: - Extend SimulationSettings to include our new toggle
extension SimulationSettings {
    /// If true, annualStepFactor mode will *ignore* mean reversion (even if useMeanReversion is on).
    /// If false, annualStepFactor mode will apply mean reversion as well.
    var disableMeanReversionWhenannualStepFactor: Bool {
        // You can store this in your persistent settings or just define a default here.
        // For demonstration, I return true by default to skip mean reversion in annualStepFactor mode.
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
    
    var cagrDecimal = annualCAGR / 100.0
    var baseWeeklyVol = (annualVolatility / 100.0) / sqrt(52.0)

    // GARCH
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
    
    var regimeModel = RegimeSwitchingModel()
    
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    // Extended historical sample
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        if totalWeeklySteps <= extendedWeeklyReturns.count {
            extendedBlock = pickContiguousBlock(
                from: extendedWeeklyReturns,
                count: totalWeeklySteps,
                rng: rng
            )
        } else {
            extendedBlock = pickMultiChunkBlock(
                from: extendedWeeklyReturns,
                totalNeeded: totalWeeklySteps,
                rng: rng,
                chunkSize: 52
            )
        }
    }

    // Read our new toggle for single annual step
    let useAnnualStep = settings.useAnnualStep
    
    for currentWeek in 1...totalWeeklySteps {
        
        // Regime Switching
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
            cagrDecimal = (annualCAGR / 100.0) * regimeModel.currentRegime.cagrMultiplier
            baseWeeklyVol = ((annualVolatility / 100.0) / sqrt(52.0)) * regimeModel.currentRegime.volMultiplier
        }
        
        var totalReturn = 0.0
        var currentVol = settings.useGarchVolatility
            ? garchModelToUse.currentStdDev()
            : baseWeeklyVol
        
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }

        // ─── Single Annual Step ──────────────────────────────────────────
        if useAnnualStep {
            // Only apply the annual CAGR jump once a year => the final week of each year (52, 104, etc.)
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                let yearIndex = currentWeek / 52
                var annualGrowth = cagrDecimal  // e.g. 0.30 for 30%
                
                // Optional vol shock
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                    annualGrowth = (1 + annualGrowth) * exp(shockVol) - 1
                }
                
                // Mean reversion
                if settings.useMeanReversion {
                    let reversionFactor = 0.1
                    let distance = (settings.meanReversionTarget - annualGrowth)
                    annualGrowth += (reversionFactor * distance)
                }
                
                // Autocorrelation
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    annualGrowth = (1 - phi) * annualGrowth + phi * lastAutoReturn
                }

                // Factor toggles (bull/bear toggles)
                annualGrowth = applyFactorToggles(
                    baseReturn: annualGrowth,
                    stepIndex: currentWeek,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    rng: rng
                )

                // Additional annual step factor (if any)
                let factor = annualStepAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                annualGrowth *= factor

                print("  annualGrowth after toggles => \(annualGrowth)")
                
                // Apply the growth
                prevBTCPriceUSD *= (1 + annualGrowth)

                lastStepLogReturn = log(1 + annualGrowth)
                lastAutoReturn    = annualGrowth
            }
        }
        // ─── Weekly Step ────────────────────────────────────────────────
        else {
            // extended historical
            if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
                var weeklySample = extendedBlock[currentWeek - 1]
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
            }
            // basic historical
            else if settings.useHistoricalSampling {
                var weeklySample = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
            }
            // lognormal
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            // volatility shock
            if settings.useVolShocks {
                let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                totalReturn += shockVol
            }
            // mean reversion
            if settings.useMeanReversion {
                let reversionFactor = 0.1
                let distance = (settings.meanReversionTarget - totalReturn)
                totalReturn += (reversionFactor * distance)
            }
            // auto-corr
            if settings.useAutoCorrelation {
                let phi = settings.autoCorrelationStrength
                totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
            }
            
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                stepIndex: currentWeek,
                settings: settings,
                mempoolDataManager: mempoolDataManager,
                rng: rng
            )
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn    = toggled
        }
        
        // Floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }

        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Contributions (DCA)
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
    
    var cagrDecimal = annualCAGR / 100.0
    var baseMonthlyVol = (annualVolatility / 100.0) / sqrt(12.0)

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

    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        if totalMonths <= extendedMonthlyReturns.count {
            extendedBlock = pickContiguousBlock(
                from: extendedMonthlyReturns,
                count: totalMonths,
                rng: rng
            )
        } else {
            extendedBlock = pickMultiChunkBlock(
                from: extendedMonthlyReturns,
                totalNeeded: totalMonths,
                rng: rng,
                chunkSize: 12
            )
        }
    }

    let useAnnualStep = settings.useAnnualStep

    for currentMonth in 1...totalMonths {
        
        // Regime Switching
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
            cagrDecimal = (annualCAGR / 100.0) * regimeModel.currentRegime.cagrMultiplier
            baseMonthlyVol = ((annualVolatility / 100.0) / sqrt(12.0)) * regimeModel.currentRegime.volMultiplier
        }
        
        var totalReturn = 0.0
        var currentVol = settings.useGarchVolatility
            ? garchModelToUse.currentStdDev()
            : baseMonthlyVol
        
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }

        // ─── Single Annual Step (once a year => every 12 mo) ────────────
        if useAnnualStep {
            if Double(currentMonth).truncatingRemainder(dividingBy: 12.0) == 0 {
                let yearIndex = currentMonth / 12
                print("=== Year \(yearIndex) START ===")
                print("Price before step => \(prevBTCPriceUSD)")

                var annualGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                    annualGrowth = (1 + annualGrowth) * exp(shockVol) - 1
                }
                if settings.useMeanReversion {
                    let reversionFactor = 0.5
                    let distance = (settings.meanReversionTarget - annualGrowth)
                    annualGrowth += (reversionFactor * distance)
                }
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    annualGrowth = (1 - phi) * annualGrowth + phi * lastAutoReturn
                }
                
                annualGrowth = applyFactorToggles(
                    baseReturn: annualGrowth,
                    stepIndex: currentMonth,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    rng: rng
                )
                
                let factor = annualStepAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                annualGrowth *= factor
                
                print("  annualGrowth after toggles => \(annualGrowth)")
                
                prevBTCPriceUSD *= (1 + annualGrowth)
                
                print("Price after step => \(prevBTCPriceUSD)")
                print("=== Year \(yearIndex) END ===\n")

                lastStepLogReturn = log(1 + annualGrowth)
                lastAutoReturn    = annualGrowth
            }
        }
        // ─── Normal Monthly Step ────────────────────────────────────────
        else {
            if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
                var monthlySample = extendedBlock[currentMonth - 1]
                monthlySample = dampenArctanMonthly(monthlySample)
                totalReturn += monthlySample
            }
            else if settings.useHistoricalSampling {
                var monthlySample = pickRandomReturn(from: historicalBTCMonthlyReturns, rng: rng)
                monthlySample = dampenArctanMonthly(monthlySample)
                totalReturn += monthlySample
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 12.0)
            }
            if settings.useVolShocks {
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
            
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn    = toggled
        }
        
        // Floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Contributions
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
    
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)

    return (medianRun, allRuns, stepMedians)
}

/// Example aligners (unchanged)
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
