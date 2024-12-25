//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

// MARK: - Global Historical Arrays & Loading
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

// MARK: - Helpers for Correlation, Sampling, Normal Dist.
func correlatedReturn(
    correlation: Double,
    sp500Return: Double,
    btcReturn: Double
) -> Double {
    correlation * sp500Return + sqrt(1 - correlation * correlation) * btcReturn
}

func sampleHistoricalReturns() -> (btcWeekly: Double, spWeekly: Double) {
    guard !historicalBTCWeeklyReturns.isEmpty, !sp500WeeklyReturns.isEmpty else {
        print("DEBUG: Historical arrays empty, defaulting to 0.0 returns")
        return (0.0, 0.0)
    }
    let btcIdx = Int.random(in: 0..<historicalBTCWeeklyReturns.count)
    let spIdx  = Int.random(in: 0..<sp500WeeklyReturns.count)
    return (historicalBTCWeeklyReturns[btcIdx], sp500WeeklyReturns[spIdx])
}

func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
    return z0 * standardDeviation + mean
}

// MARK: - Basic Stats & Aggregation
func calculateMedian(values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count % 2 == 0 {
        return (sorted[mid - 1] + sorted[mid]) / 2.0
    } else {
        return sorted[mid]
    }
}

func calculateStandardDeviation(values: [Double], mean: Double) -> Double {
    let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
}

func calculatePercentile(values: [Double], percentile: Double) -> Double {
    let sorted = values.sorted()
    let index = Int(Double(sorted.count - 1) * percentile / 100.0)
    return sorted[max(0, min(index, sorted.count - 1))]
}

func aggregateResults(allIterations: [[SimulationData]]) -> [String: [String: Double]] {
    var stats = [String: [String: Double]]()
    let totalIters = allIterations.count
    guard totalIters > 0 else { return stats }

    let weeks = allIterations[0].count
    for i in 0..<weeks {
        var vals = [Double]()
        for iteration in allIterations {
            vals.append(iteration[i].portfolioValueEUR)
        }
        let meanVal = vals.reduce(0, +) / Double(totalIters)
        let medVal  = calculateMedian(values: vals)
        let stdVal  = calculateStandardDeviation(values: vals, mean: meanVal)
        let p90Val  = calculatePercentile(values: vals, percentile: 90)
        let p10Val  = calculatePercentile(values: vals, percentile: 10)

        stats["Week \(i+1)"] = [
            "Mean": meanVal,
            "Median": medVal,
            "Standard Deviation": stdVal,
            "90th Percentile": p90Val,
            "10th Percentile": p10Val
        ]
    }
    return stats
}

// MARK: - Single-run function (1 iteration)
func runOneFullSimulation(
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double,
    exchangeRateEURUSD: Double,
    totalWeeks: Int
) -> [SimulationData] {
    // Hardcoded weeks 1–7
    var results: [SimulationData] = [
        .init(
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
        ),
        .init(
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
        ),
        .init(
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
        ),
        .init(
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
        ),
        .init(
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
        ),
        .init(
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
        ),
        .init(
            week: 7,
            startingBTC: 0.00745154,
            netBTCHoldings: 0.00959318,
            btcPriceUSD: 98_346.31,
            btcPriceEUR: 92_779.54,
            portfolioValueEUR: 890.05,
            contributionEUR: 200.00,
            transactionFeeEUR: 1.300,
            netContributionBTC: 0.00214164,
            withdrawalEUR: 0.0
        )
    ]
    
    let lastHardcoded = results.last
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
    let weeklyVol = annualVolatility / sqrt(52.0)

    var previousBTCPriceUSD = lastHardcoded?.btcPriceUSD ?? 106_000.00
    var previousBTCHoldings = lastHardcoded?.netBTCHoldings ?? 0.00745154

    // Weeks 8..totalWeeks
    for week in 8...totalWeeks {
        // sample random or CSV-based returns
        let (histBTC, histSP) = sampleHistoricalReturns()
        var combinedWeeklyReturn = correlatedReturn(
            correlation: correlationWithSP500,
            sp500Return: histSP,
            btcReturn: histBTC
        )
        combinedWeeklyReturn += baseWeeklyGrowth

        let shock = randomNormal(mean: 0, standardDeviation: weeklyVol)
        combinedWeeklyReturn += shock

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

        results.append(
            SimulationData(
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
            )
        )

        previousBTCPriceUSD = btcPriceUSD
        previousBTCHoldings = netHoldings
    }

    return results
}

// MARK: - Concurrency-based approach that calls `runOneFullSimulation`
func runMonteCarloSimulationsWithProgress(
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double = 0.0,
    exchangeRateEURUSD: Double,
    totalWeeks: Int,
    iterations: Int,
    progressCallback: @escaping (Int) -> Void
) -> ([SimulationData], [[SimulationData]]) {

    let batchSize = 1000
    let totalBatches = (iterations + batchSize - 1) / batchSize
    print("DEBUG: totalBatches =", totalBatches, "batchSize =", batchSize, "iterations =", iterations)

    var allIterations = [[SimulationData]]()
    var finalPortfolioValues = [(value: Double, run: [SimulationData])]()

    let lock = NSLock()
    let finalValuesLock = NSLock()
    let dispatchGroup = DispatchGroup()

    var completed = 0

    for batchIndex in 0..<totalBatches {
        let startIter = batchIndex * batchSize
        let endIter   = min(startIter + batchSize, iterations)

        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            var localRuns = [[SimulationData]]()

            for _ in startIter..<endIter {
                // A single iteration => a single "full" run
                let run = runOneFullSimulation(
                    annualCAGR: annualCAGR,
                    annualVolatility: annualVolatility,
                    correlationWithSP500: correlationWithSP500,
                    exchangeRateEURUSD: exchangeRateEURUSD,
                    totalWeeks: totalWeeks
                )

                // Capture final portfolio
                if let final = run.last {
                    finalValuesLock.lock()
                    finalPortfolioValues.append((value: final.portfolioValueEUR, run: run))
                    finalValuesLock.unlock()
                }

                localRuns.append(run)

                // progress
                lock.lock()
                completed += 1
                lock.unlock()

                progressCallback(completed)
            }

            lock.lock()
            allIterations.append(contentsOf: localRuns)
            lock.unlock()
            dispatchGroup.leave()
        }
    }

    dispatchGroup.wait()

    // Sort by final portfolio
    finalPortfolioValues.sort { $0.value < $1.value }

    // median run
    let medianRun = finalPortfolioValues[finalPortfolioValues.count / 2].run
    return (medianRun, allIterations)
}
