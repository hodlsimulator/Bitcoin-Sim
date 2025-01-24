//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI
import GameplayKit // for GKARC4RandomSource

// ──────────────────────────────────────────────────────────────────────────
// Global arrays for weekly/monthly historical returns
// (Populated elsewhere; used here by the simulator.)
// ──────────────────────────────────────────────────────────────────────────
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

var historicalBTCMonthlyReturns: [Double] = []
var sp500MonthlyReturns: [Double] = []

// ──────────────────────────────────────────────────────────────────────────
// Probability thresholds & intervals (legacy constants)
// ──────────────────────────────────────────────────────────────────────────
private let halvingIntervalGuess = 210.0
private let blackSwanIntervalGuess = 400.0
private let halvingIntervalGuessMonths: Double = 48.0
private let blackSwanIntervalGuessMonths: Double = 92.0

// MARK: - Historical Return Picker
/// We make this non-fileprivate so it can be used across files if needed.
func pickRandomReturn(from arr: [Double], rng: GKRandomSource) -> Double {
    guard !arr.isEmpty else { return 0.0 }
    let idx = rng.nextInt(upperBound: arr.count)
    return arr[idx]
}

// MARK: - Contiguous Slice
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

// MARK: - Multi-Chunk Stitching
/// Stitches multiple contiguous chunks to get `totalNeeded` data points.
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
            // If the chunk is bigger than the entire dataset, just append all
            stitched.append(contentsOf: source)
        } else {
            // Random contiguous slice of length `chunkSize`
            let maxStart = source.count - chunkSize
            let startIndex = rng.nextInt(upperBound: maxStart + 1)
            let endIndex = startIndex + chunkSize
            let chunk = Array(source[startIndex..<endIndex])
            stitched.append(contentsOf: chunk)
        }
    }

    // Trim to the exact length we need
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
    
    // Convert user’s CAGR: e.g. 30 => 0.30
    var cagrDecimal = annualCAGR / 100.0
    // Base weekly volatility if NOT using GARCH
    var baseWeeklyVol = (annualVolatility / 100.0) / sqrt(52.0)

    // Decide whether to use a "fitted" GARCH model or old defaults
    var garchModelToUse: GarchModel
    if let fittedModel = garchModel, settings.useGarchVolatility {
        // Use the fitted GARCH(1,1) model
        let initialVol = baseWeeklyVol
        var copy = fittedModel
        copy.currentVariance = initialVol * initialVol
        garchModelToUse = copy
    } else {
        // Fallback to basic parameters
        garchModelToUse = GarchModel(
            omega: 0.000001,
            alpha: 0.1,
            beta: 0.85,
            initialVariance: baseWeeklyVol * baseWeeklyVol
        )
    }
    
    // Regime model
    var regimeModel = RegimeSwitchingModel()
    
    // Retrieve deposit info
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    // ──────────────────────────────────────────────────────────────────────
    // Extended historical sampling logic: if user picks more steps than we have,
    // we do multi-chunk. Otherwise, single contiguous block.
    // ──────────────────────────────────────────────────────────────────────
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        if totalWeeklySteps <= extendedWeeklyReturns.count {
            extendedBlock = pickContiguousBlock(
                from: extendedWeeklyReturns,
                count: totalWeeklySteps,
                rng: rng
            )
        } else {
            // multi-chunk approac
            extendedBlock = pickMultiChunkBlock(
                from: extendedWeeklyReturns,
                totalNeeded: totalWeeklySteps,
                rng: rng,
                chunkSize: 52
            )
        }
    }

    for currentWeek in 1...totalWeeklySteps {
        
        // If user wants regime switching, update it
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
            // Multiply your annualCAGR & baseWeeklyVol accordingly
            cagrDecimal = (annualCAGR / 100.0) * regimeModel.currentRegime.cagrMultiplier
            baseWeeklyVol = ((annualVolatility / 100.0) / sqrt(52.0)) * regimeModel.currentRegime.volMultiplier
        }
        
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        // Current volatility from GARCH or base
        var currentVol = settings.useGarchVolatility
            ? garchModelToUse.currentStdDev()
            : baseWeeklyVol
        
        // Additional scaling if regime switching is on
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }

        // ─── LUMPSUM LOGIC (Yearly) ─────────────────────────────────────────────
        if lumpsum {
            // Only do lumpsum once a year => every 52 weeks
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                
                // Mean reversion
                if settings.useMeanReversion {
                    let reversionFactor = 0.1
                    let distanceFromTarget = (settings.meanReversionTarget - lumpsumGrowth)
                    lumpsumGrowth += (reversionFactor * distanceFromTarget)
                }

                // Autocorrelation
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    lumpsumGrowth = (1 - phi) * lumpsumGrowth + phi * lastAutoReturn
                }

                // Factor toggles
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    stepIndex: currentWeek,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    rng: rng
                )
                
                // Possibly scale lumpsum
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor

                // Apply lumpsum growth
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
                
                lastStepLogReturn = log(1 + lumpsumGrowth)
                lastAutoReturn    = lumpsumGrowth
            }

        // ─── WEEKLY SAMPLING LOGIC ─────────────────────────────────────────────
        } else {
            // Extended block or random picks from historical
            if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
                // get the next sample from the block
                var weeklySample = extendedBlock[currentWeek - 1]
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
            }
            else if settings.useHistoricalSampling {
                // fallback: pick from historical
                var weeklySample = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
            }

            // Optional lognormal drift
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            // Vol shocks
            if settings.useVolShocks {
                let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                totalReturn += shockVol
            }
            
            // Mean reversion
            if settings.useMeanReversion {
                let reversionFactor = 0.1
                let distanceFromTarget = (settings.meanReversionTarget - totalReturn)
                totalReturn += (reversionFactor * distanceFromTarget)
            }

            // Auto-correlation
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
            
            // Exponential growth
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn    = toggled
        }
        
        // Floor at 1.0
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }

        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Contributions
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
        
        // Update GARCH if on
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

    // GARCH model setup
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
    
    // Regime switching
    var regimeModel = RegimeSwitchingModel()
    
    // Contribution logic
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    // ──────────────────────────────────────────────────────────────────────
    // Extended sampling: single slice vs multi-chunk
    // ──────────────────────────────────────────────────────────────────────
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

    for currentMonth in 1...totalMonths {
        
        // If regime switching is on, update it
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
            cagrDecimal = (annualCAGR / 100.0) * regimeModel.currentRegime.cagrMultiplier
            baseMonthlyVol = ((annualVolatility / 100.0) / sqrt(12.0)) * regimeModel.currentRegime.volMultiplier
        }
        
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        // Current volatility (GARCH or base)
        var currentVol = settings.useGarchVolatility
            ? garchModelToUse.currentStdDev()
            : baseMonthlyVol
        
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }

        // ─── LUMPSUM LOGIC (annual lumpsum every 12 months) ─────────────────────
        if lumpsum {
            if Double(currentMonth).truncatingRemainder(dividingBy: 12.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                
                // Mean reversion
                if settings.useMeanReversion {
                    let reversionFactor = 0.5
                    let distanceFromTarget = (settings.meanReversionTarget - lumpsumGrowth)
                    lumpsumGrowth += (reversionFactor * distanceFromTarget)
                }
                
                // Autocorrelation
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    lumpsumGrowth = (1 - phi) * lumpsumGrowth + phi * lastAutoReturn
                }
                
                // Factor toggles
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    stepIndex: currentMonth,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    rng: rng
                )
                
                // Possibly scale lumpsum
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                
                // Apply lumpsum
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
                
                lastStepLogReturn = log(1 + lumpsumGrowth)
                lastAutoReturn    = lumpsumGrowth
            }

        // ─── MONTHLY SAMPLING LOGIC ─────────────────────────────────────────────
        } else {
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
            
            // Mean reversion
            if settings.useMeanReversion {
                let reversionFactor = 0.1
                let distanceFromTarget = (settings.meanReversionTarget - totalReturn)
                totalReturn += (reversionFactor * distanceFromTarget)
            }
            
            // Autocorrelation
            if settings.useAutoCorrelation {
                let phi = settings.autoCorrelationStrength
                totalReturn = (1 - phi) * totalReturn + (phi * lastAutoReturn)
            }
            
            // Factor toggles
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                stepIndex: currentMonth,
                settings: settings,
                mempoolDataManager: mempoolDataManager,
                rng: rng
            )
            
            // Exponential growth
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn    = toggled
        }
        
        // Floor at 1.0
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
        
        // Update GARCH if on
        if settings.useGarchVolatility {
            garchModelToUse.updateVariance(lastReturn: lastStepLogReturn)
        }

        let dataPoint = SimulationData(
            week: currentMonth, // reusing 'week' property
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

// MARK: - Compute median BTC across all runs
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

// MARK: - Run Multiple Simulations With Progress
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
    // Create RNG
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
    
    // Choose median run by final portfolio value (in EUR)
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    
    // Compute step-by-step median BTC price
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)

    return (medianRun, allRuns, stepMedians)
}

/// Aligns weekly BTC and S&P arrays by taking only up to the minimum length.
func alignWeeklyData() {
    let minCount = min(historicalBTCWeeklyReturns.count, sp500WeeklyReturns.count)
    let partialBTC = Array(historicalBTCWeeklyReturns.prefix(minCount))
    let partialSP  = Array(sp500WeeklyReturns.prefix(minCount))
    
    // Convert them into (btc, sp) tuples
    combinedWeeklyData = zip(partialBTC, partialSP).map { (btc, sp) in
        (btc, sp)
    }
}

/// Aligns monthly BTC and S&P arrays similarly.
func alignMonthlyData() {
    let minCount = min(historicalBTCMonthlyReturns.count, sp500MonthlyReturns.count)
    let partialBTC = Array(historicalBTCMonthlyReturns.prefix(minCount))
    let partialSP  = Array(sp500MonthlyReturns.prefix(minCount))
    
    combinedMonthlyData = zip(partialBTC, partialSP).map { (btc, sp) in
        (btc, sp)
    }
}
