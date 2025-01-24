//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI
import GameplayKit // for GKARC4RandomSource
import os.log
import os.signpost

let myLog = OSLog(subsystem: "com.conor.hodlsim", category: "Performance")

// ──────────────────────────────────────────────────────────────────────────
// Global arrays for weekly/monthly historical returns
// ──────────────────────────────────────────────────────────────────────────
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

var historicalBTCMonthlyReturns: [Double] = []
var sp500MonthlyReturns: [Double] = []

// ──────────────────────────────────────────────────────────────────────────
// Probability thresholds & intervals (unused legacy constants, can remain or remove)
// ──────────────────────────────────────────────────────────────────────────
private let halvingIntervalGuess = 210.0
private let blackSwanIntervalGuess = 400.0
private let halvingIntervalGuessMonths: Double = 48.0
private let blackSwanIntervalGuessMonths: Double = 92.0

// MARK: - Historical Return Picker
/// Picks a random return from an array, using our seeded RNG.
fileprivate func pickRandomReturn(from arr: [Double], rng: GKRandomSource) -> Double {
    guard !arr.isEmpty else { return 0.0 }
    let idx = rng.nextInt(upperBound: arr.count)
    return arr[idx]
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
    rng: GKRandomSource
) -> [SimulationData] {

    let signpostID = OSSignpostID(log: myLog)
    os_signpost(.begin, log: myLog, name: "runWeeklySimulation", signpostID: signpostID)
    defer {
        os_signpost(.end, log: myLog, name: "runWeeklySimulation", signpostID: signpostID)
    }

    var results = [SimulationData]()
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    var cagrDecimal = annualCAGR / 100.0
    var baseWeeklyVol = (annualVolatility / 100.0) / sqrt(52.0)

    // GARCH model
    var garchModel = GarchModel(
        omega: 0.000001,
        alpha: 0.1,
        beta: 0.85,
        initialVariance: baseWeeklyVol * baseWeeklyVol
    )
    
    // Regime model
    var regimeModel = RegimeSwitchingModel()
    
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn    = 0.0

    for currentWeek in 1...totalWeeklySteps {
        
        // Update regime if user wants regime switching
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
            // Adjust CAGR and volatility for this new regime
            cagrDecimal = (annualCAGR / 100.0) * regimeModel.currentRegime.cagrMultiplier
            baseWeeklyVol = ((annualVolatility / 100.0) / sqrt(52.0)) * regimeModel.currentRegime.volMultiplier
        }
        
        // lumpsum means no lognormal or historical sampling => compounding once a year
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        var currentVol = settings.useGarchVolatility
            ? garchModel.currentStdDev()
            : baseWeeklyVol
        
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }

        if lumpsum {
            // Once every 52 weeks => do lumpsum growth
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(
                        mean: 0,
                        standardDeviation: currentVol,
                        rng: rng
                    )
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    let oldVal = lumpsumGrowth
                    lumpsumGrowth = (1 - phi) * lumpsumGrowth + phi * lastAutoReturn
                }

                // Factor toggles
                let beforeFactor = lumpsumGrowth
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    stepIndex: currentWeek,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    rng: rng
                )
                if lumpsumGrowth != beforeFactor {
                }
                
                let factor = lumpsumAdjustFactor(
                    settings: settings,
                    annualVolatility: annualVolatility
                )
                let oldLS = lumpsumGrowth
                lumpsumGrowth *= factor
                if factor != 1.0 {
                }

                // Multiply the price
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
                
                lastStepLogReturn = log(1 + lumpsumGrowth)
                lastAutoReturn    = lumpsumGrowth
            }
        } else {
            // Historical sampling or lognormal each step
            if settings.useHistoricalSampling {
                var weeklySample = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
                // print("[WeeklySim] Step\(currentWeek) historical sampling => \(weeklySample)")
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                totalReturn += shockVol
                // print("[WeeklySim] Step\(currentWeek) shockVol=\(shockVol)")
            }
            if settings.useAutoCorrelation {
                let phi = settings.autoCorrelationStrength
                let oldTR = totalReturn
                totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
                // print("[WeeklySim] Step\(currentWeek) autoCorr oldTR=\(oldTR), lastAuto=\(lastAutoReturn), newTR=\(totalReturn)")
            }
            
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                stepIndex: currentWeek,
                settings: settings,
                mempoolDataManager: mempoolDataManager,
                rng: rng
            )
            if toggled != totalReturn {
            }
            
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
        
        // Update GARCH variance
        if settings.useGarchVolatility {
            garchModel.updateVariance(lastReturn: lastStepLogReturn)
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
    rng: GKRandomSource
) -> [SimulationData] {

    var results = [SimulationData]()
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    var cagrDecimal = annualCAGR / 100.0
    var baseMonthlyVol = (annualVolatility / 100.0) / sqrt(12.0)

    var garchModel = GarchModel(
        omega: 0.00001,
        alpha: 0.1,
        beta: 0.85,
        initialVariance: baseMonthlyVol * baseMonthlyVol
    )
    
    var regimeModel = RegimeSwitchingModel()
    
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn = 0.0

    for currentMonth in 1...totalMonths {
        
        // Regime switching
        if settings.useRegimeSwitching {
            regimeModel.updateRegime(rng: rng)
            cagrDecimal = (annualCAGR / 100.0) * regimeModel.currentRegime.cagrMultiplier
            baseMonthlyVol = ((annualVolatility / 100.0) / sqrt(12.0)) * regimeModel.currentRegime.volMultiplier
        }
        
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        var currentVol = settings.useGarchVolatility
            ? garchModel.currentStdDev()
            : baseMonthlyVol
        if settings.useRegimeSwitching {
            currentVol *= regimeModel.currentRegime.volMultiplier
        }

        if lumpsum {
            // Once per year => every 12 months
            if Double(currentMonth).truncatingRemainder(dividingBy: 12.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    let oldVal = lumpsumGrowth
                    lumpsumGrowth = (1 - phi) * lumpsumGrowth + phi * lastAutoReturn
                }
                
                let beforeFactor = lumpsumGrowth
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    stepIndex: currentMonth,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    rng: rng
                )
                if lumpsumGrowth != beforeFactor {
                }
                
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                let oldLS = lumpsumGrowth
                lumpsumGrowth *= factor
                if factor != 1.0 {
                }
                
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
                
                lastStepLogReturn = log(1 + lumpsumGrowth)
                lastAutoReturn = lumpsumGrowth
            }
        } else {
            // Historical sampling or lognormal each month
            if settings.useHistoricalSampling {
                var monthlySample = pickRandomReturn(from: historicalBTCMonthlyReturns, rng: rng)
                monthlySample = dampenArctanMonthly(monthlySample)
                totalReturn += monthlySample
                // print("[MonthlySim] Month\(currentMonth) historical sampling => \(monthlySample)")
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 12.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                totalReturn += shockVol
                // print("[MonthlySim] Month\(currentMonth) shockVol=\(shockVol)")
            }
            if settings.useAutoCorrelation {
                let phi = settings.autoCorrelationStrength
                let oldTR = totalReturn
                totalReturn = (1 - phi) * totalReturn + (phi * lastAutoReturn)
                // print("[MonthlySim] Month\(currentMonth) autoCorr oldTR=\(oldTR), lastAuto=\(lastAutoReturn), newTR=\(totalReturn)")
            }
            
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                stepIndex: currentMonth,
                settings: settings,
                mempoolDataManager: mempoolDataManager,
                rng: rng
            )
            if toggled != totalReturn {
            }
            
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn = toggled
        }
        
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
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
            garchModel.updateVariance(lastReturn: lastStepLogReturn)
        }

        let dataPoint = SimulationData(
            week: currentMonth, // storing month in 'week' property
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
    mempoolDataManager: MempoolDataManager? = nil
) -> [SimulationData] {

    if settings.periodUnit == .months {
        let totalMonths = userWeeks
        let monthlyResult = runMonthlySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalMonths: totalMonths,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: iterationIndex,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            rng: rng
        )
        return monthlyResult
    } else {
        let totalWeeks = userWeeks
        let weeklyResult = runWeeklySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeklySteps: totalWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: iterationIndex,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            rng: rng
        )
        return weeklyResult
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
    mempoolDataManager: MempoolDataManager? = nil
) -> (
    medianRun: [SimulationData],
    allRuns: [[SimulationData]],
    stepMedianPrices: [Decimal]
) {
    // 1) Create a single RNG for all draws
    let rng: GKRandomSource
    if let validSeed = seed {
        let seedData = withUnsafeBytes(of: validSeed) { Data($0) }
        rng = GKARC4RandomSource(seed: seedData)
    } else {
        rng = GKARC4RandomSource() // unseeded => new each run
    }
    
    // 2) Array to store all runs
    var allRuns = [[SimulationData]]()
    
    // 3) Loop
    for i in 0..<iterations {
        if isCancelled() { break }
        
        // optional small delay
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
            mempoolDataManager: mempoolDataManager
        )
        allRuns.append(simRun)
        
        if isCancelled() { break }
        progressCallback(i + 1)
    }
    
    // If no runs, return empties
    if allRuns.isEmpty {
        return ([], [], [])
    }
    
    // 4) Pick a median run by final portfolioValueEUR
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    
    // 5) Compute median BTC price across steps
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)

    return (medianRun, allRuns, stepMedians)
}
