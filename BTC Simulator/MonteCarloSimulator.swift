//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

// Global arrays to hold historical data loaded from CSV
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []

func loadAllHistoricalData() {
    historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
    sp500WeeklyReturns         = loadSP500WeeklyReturns()
    
    print("DEBUG: BTC weekly returns loaded: \(historicalBTCWeeklyReturns.count) entries")
    if let sample = historicalBTCWeeklyReturns.first {
        print("DEBUG: Sample BTC return = \(sample)")
    }
    
    print("DEBUG: SP500 weekly returns loaded: \(sp500WeeklyReturns.count) entries")
    if let sampleSP = sp500WeeklyReturns.first {
        print("DEBUG: Sample S&P500 return = \(sampleSP)")
    }
}

// --------------------------------------------------------------------------
// MARK: - Historical Data Arrays (use CSV data now)
// --------------------------------------------------------------------------
// These used to be hardcoded. We now load them via loadAllHistoricalData().
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// MARK: - Helpers for Correlation, Sampling, Normal Dist.
// --------------------------------------------------------------------------

/// Combine BTC & S&P returns given a correlation factor
func correlatedReturn(
    correlation: Double,
    sp500Return: Double,
    btcReturn: Double
) -> Double {
    // If correlation is 0, we just return btcReturn.
    // If correlation is 1, we basically mirror sp500Return.
    return correlation * sp500Return + sqrt(1 - correlation * correlation) * btcReturn
}

/// Randomly pick one weekly return from your newly loaded arrays
func sampleHistoricalReturns() -> (btcWeekly: Double, spWeekly: Double) {
    guard !historicalBTCWeeklyReturns.isEmpty,
          !sp500WeeklyReturns.isEmpty
    else {
        print("DEBUG: Historical arrays are empty, defaulting to 0.0 returns")
        return (0.0, 0.0)
    }
    let btcIdx = Int.random(in: 0..<historicalBTCWeeklyReturns.count)
    let spIdx  = Int.random(in: 0..<sp500WeeklyReturns.count)
    
    let chosenBTC = historicalBTCWeeklyReturns[btcIdx]
    let chosenSP = sp500WeeklyReturns[spIdx]
    
    return (chosenBTC, chosenSP)
}

/// Simple normal distribution generator (Box-Muller)
func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
    return z0 * standardDeviation + mean
}

// --------------------------------------------------------------------------
// MARK: - Basic Stats & Aggregation
// --------------------------------------------------------------------------

func calculateMedian(values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let sortedValues = values.sorted()
    let mid = sortedValues.count / 2
    if sortedValues.count % 2 == 0 {
        return (sortedValues[mid - 1] + sortedValues[mid]) / 2.0
    } else {
        return sortedValues[mid]
    }
}

func calculateStandardDeviation(values: [Double], mean: Double) -> Double {
    let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
}

func calculatePercentile(values: [Double], percentile: Double) -> Double {
    let sorted = values.sorted()
    let index = Int(Double(sorted.count - 1) * percentile / 100.0)
    return sorted[index]
}

/// Summaries across all iterations (mean, median, std, p90, p10, etc.)
func aggregateResults(allIterations: [[SimulationData]]) -> [String: [String: Double]] {
    var stats: [String: [String: Double]] = [:]
    let totalIters = allIterations.count
    guard totalIters > 0 else { return stats }

    let weeks = allIterations[0].count
    for i in 0..<weeks {
        var vals: [Double] = []
        for iteration in allIterations {
            vals.append(iteration[i].portfolioValueEUR)
        }
        let mean = vals.reduce(0, +) / Double(totalIters)
        let median = calculateMedian(values: vals)
        let std = calculateStandardDeviation(values: vals, mean: mean)
        let p90 = calculatePercentile(values: vals, percentile: 90)
        let p10 = calculatePercentile(values: vals, percentile: 10)
        stats["Week \(i+1)"] = [
            "Mean": mean,
            "Median": median,
            "Standard Deviation": std,
            "90th Percentile": p90,
            "10th Percentile": p10
        ]
    }
    return stats
}

// --------------------------------------------------------------------------
// MARK: - Halving & Start Date
// --------------------------------------------------------------------------

/// Approx. next halving date
let halvingDateComponents = DateComponents(year: 2028, month: 5, day: 1)
let halvingDate = Calendar.current.date(from: halvingDateComponents)!

/// Our "Week 1" is 13 Oct 2024
let startDateComponents = DateComponents(year: 2024, month: 10, day: 13)
let realStartDate = Calendar.current.date(from: startDateComponents)!

// --------------------------------------------------------------------------
// MARK: - Bear Market Logic
// --------------------------------------------------------------------------

/// Probability of triggering a bear slump each year after halving:
let halvingBearProbabilities: [Double] = [0.001, 0.003, 0.008, 0.015]

/// Negative penalty to weekly returns if in bear slump
let halvingBearPenalties: [Double] = [-0.01, -0.02, -0.03, -0.04]

/// Possible length (in weeks) of a bear slump once triggered
let bearMarketLengthRange = 4...8

/// Weeks from halving to current date
func weeksFromHalving(halvingDate: Date, currentWeekDate: Date) -> Int {
    guard currentWeekDate >= halvingDate else {
        return 0
    }
    let comps = Calendar.current.dateComponents([.weekOfYear], from: halvingDate, to: currentWeekDate)
    return comps.weekOfYear ?? 0
}

func halvingYearIndex(weeksAfterHalving: Int) -> Int {
    return weeksAfterHalving / 52
}

// --------------------------------------------------------------------------
// MARK: - Main Monte Carlo
// --------------------------------------------------------------------------

func runMonteCarloSimulationsWithSpreadsheetData(
    annualCAGR: Double,          // e.g. 0.29
    annualVolatility: Double,    // e.g. 0.8
    correlationWithSP500: Double = 0.0,
    exchangeRateEURUSD: Double = 1.06,
    totalWeeks: Int = 1040,
    iterations: Int
) -> ([SimulationData], [[SimulationData]]) {

    let batchSize = 1000
    let totalBatches = (iterations + batchSize - 1) / batchSize
    print("Total Batches: \(totalBatches), Batch Size: \(batchSize), Total Iterations: \(iterations)")

    var allIterations: [[SimulationData]] = []
    var finalPortfolioValues: [(value: Double, run: [SimulationData])] = []

    let lock = NSLock()
    let finalValuesLock = NSLock()
    let dispatchGroup = DispatchGroup()

    for batchIndex in 0..<totalBatches {
        let startIteration = batchIndex * batchSize
        let endIteration = min(startIteration + batchSize, iterations)

        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            var localIterations: [[SimulationData]] = []

            for _ in startIteration..<endIteration {

                var results = [SimulationData]()

                // Example of pre-filled weeks (replace with real logic if needed).
                results.append(SimulationData(
                    week: 1,
                    startingBTC: 0.0,
                    netBTCHoldings: 0.00469014,
                    btcPriceUSD: 76_532.03,
                    btcPriceEUR: 71_177.69,
                    portfolioValueEUR: 333.83,
                    contributionEUR: 378.00,
                    transactionFeeEUR: 2.46,
                    netContributionBTC: 0.00527613,
                    withdrawalEUR: 0.0
                ))
                results.append(SimulationData(
                    week: 2,
                    startingBTC: 0.00469014,
                    netBTCHoldings: 0.00530474,
                    btcPriceUSD: 92_000.00,
                    btcPriceEUR: 86_792.45,
                    portfolioValueEUR: 465.00,
                    contributionEUR: 60.00,
                    transactionFeeEUR: 0.21,
                    netContributionBTC: 0.00066988,
                    withdrawalEUR: 0.0
                ))
                results.append(SimulationData(
                    week: 3,
                    startingBTC: 0.00530474,
                    netBTCHoldings: 0.00608283,
                    btcPriceUSD: 95_000.00,
                    btcPriceEUR: 89_622.64,
                    portfolioValueEUR: 547.00,
                    contributionEUR: 70.00,
                    transactionFeeEUR: 0.25,
                    netContributionBTC: 0.00077809,
                    withdrawalEUR: 0.0
                ))
                results.append(SimulationData(
                    week: 4,
                    startingBTC: 0.00608283,
                    netBTCHoldings: 0.00750280,
                    btcPriceUSD: 95_741.15,
                    btcPriceEUR: 90_321.84,
                    portfolioValueEUR: 685.00,
                    contributionEUR: 130.00,
                    transactionFeeEUR: 0.46,
                    netContributionBTC: 0.00141997,
                    withdrawalEUR: 0.0
                ))
                results.append(SimulationData(
                    week: 5,
                    startingBTC: 0.00745154,
                    netBTCHoldings: 0.00745154,
                    btcPriceUSD: 96_632.26,
                    btcPriceEUR: 91_162.51,
                    portfolioValueEUR: 679.30,
                    contributionEUR: 0.00,
                    transactionFeeEUR: 5.00,
                    netContributionBTC: 0.00000000,
                    withdrawalEUR: 0.0
                ))
                results.append(SimulationData(
                    week: 6,
                    startingBTC: 0.00745154,
                    netBTCHoldings: 0.00745154,
                    btcPriceUSD: 106_000.00,
                    btcPriceEUR: 100_000.00,
                    portfolioValueEUR: 745.15,
                    contributionEUR: 0.00,
                    transactionFeeEUR: 0.00,
                    netContributionBTC: 0.00000000,
                    withdrawalEUR: 0.0
                ))

                var previousBTCPriceUSD = 106_000.00
                var previousBTCHoldings = 0.00745154
                var halvingHasOccurred = false

                var isBearMarketActive = false
                var weeksRemainingInBear = 0

                let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
                let weeklyVol = annualVolatility / sqrt(52.0)

                for week in 7...totalWeeks {
                    let offset = week - 1
                    guard let currentDate = Calendar.current.date(byAdding: .weekOfYear, value: offset, to: realStartDate)
                    else { continue }

                    if !halvingHasOccurred && currentDate >= halvingDate {
                        halvingHasOccurred = true
                    }

                    let weeksAfter = weeksFromHalving(halvingDate: halvingDate, currentWeekDate: currentDate)
                    let yearIdx = halvingYearIndex(weeksAfterHalving: weeksAfter)
                    let safeIdx = min(yearIdx, 3)

                    let bearProb = halvingBearProbabilities[safeIdx]
                    let bearPenalty = halvingBearPenalties[safeIdx]

                    let (histBTC, histSP) = sampleHistoricalReturns()

                    var combinedWeeklyReturn = correlatedReturn(
                        correlation: correlationWithSP500,
                        sp500Return: histSP,
                        btcReturn: histBTC
                    )

                    combinedWeeklyReturn += baseWeeklyGrowth
                    let shock = randomNormal(mean: 0, standardDeviation: weeklyVol)
                    combinedWeeklyReturn += shock

                    if !isBearMarketActive {
                        if Double.random(in: 0..<1) < bearProb {
                            isBearMarketActive = true
                            weeksRemainingInBear = Int.random(in: bearMarketLengthRange)
                        }
                    }
                    if isBearMarketActive {
                        combinedWeeklyReturn += bearPenalty
                        weeksRemainingInBear -= 1
                        if weeksRemainingInBear <= 0 {
                            isBearMarketActive = false
                        }
                    }

                    var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
                    btcPriceUSD = max(btcPriceUSD, 1.0)
                    let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD

                    let contributionEUR = (week <= 52) ? 60.0 : 100.0
                    let fee = contributionEUR * 0.0035
                    let netBTC = (contributionEUR - fee) / btcPriceEUR

                    let hypotheticalHoldings = previousBTCHoldings + netBTC
                    let hypotheticalValueEUR = hypotheticalHoldings * btcPriceEUR

                    var withdrawalEUR = 0.0
                    if hypotheticalValueEUR > 60_000 {
                        withdrawalEUR = 200.0
                    } else if hypotheticalValueEUR > 30_000 {
                        withdrawalEUR = 100.0
                    }
                    let withdrawalBTC = withdrawalEUR / btcPriceEUR

                    let netHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)
                    let portfolioValEUR = netHoldings * btcPriceEUR

                    results.append(SimulationData(
                        week: week,
                        startingBTC: previousBTCHoldings,
                        netBTCHoldings: netHoldings,
                        btcPriceUSD: btcPriceUSD,
                        btcPriceEUR: btcPriceEUR,
                        portfolioValueEUR: portfolioValEUR,
                        contributionEUR: contributionEUR,
                        transactionFeeEUR: fee,
                        netContributionBTC: netBTC,
                        withdrawalEUR: withdrawalEUR
                    ))

                    previousBTCPriceUSD = btcPriceUSD
                    previousBTCHoldings = netHoldings
                }

                if let final = results.last {
                    finalValuesLock.lock()
                    finalPortfolioValues.append((value: final.portfolioValueEUR, run: results))
                    finalValuesLock.unlock()
                }
                localIterations.append(results)
            }

            lock.lock()
            allIterations.append(contentsOf: localIterations)
            lock.unlock()
            dispatchGroup.leave()
        }
    }

    dispatchGroup.wait()
    finalPortfolioValues.sort { $0.value < $1.value }
    let medianRun = finalPortfolioValues[finalPortfolioValues.count / 2].run
    return (medianRun, allIterations)
}
