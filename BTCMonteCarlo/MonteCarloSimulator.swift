//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

/// Calculates the median value from an array of doubles.
func calculateMedian(values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }

    let sortedValues = values.sorted()
    let count = sortedValues.count

    if count % 2 == 0 {
        // Even number of elements: return the average of the two middle values
        return (sortedValues[count / 2 - 1] + sortedValues[count / 2]) / 2.0
    } else {
        // Odd number of elements: return the middle value
        return sortedValues[count / 2]
    }
}

func runMonteCarloSimulationsWithSpreadsheetData(
    spreadsheetData: [SimulationData],
    initialBTCPriceUSD: Double,
    iterations: Int,
    btcGrowthRate: Double
) -> ([SimulationData], [[SimulationData]]) {
    let batchSize = 1_000
    let totalBatches = (iterations + batchSize - 1) / batchSize
    print("Total Batches: \(totalBatches), Batch Size: \(batchSize), Total Iterations: \(iterations)")
    
    var bestIteration: [SimulationData] = []
    var closestDistance = Double.greatestFiniteMagnitude
    var allIterations: [[SimulationData]] = []
    let lock = NSLock()
    let dispatchGroup = DispatchGroup()

    print("Starting Monte Carlo simulation with \(iterations) iterations across \(totalBatches) batches...")

    for batchIndex in 0..<totalBatches {
        let startIteration = batchIndex * batchSize
        let endIteration = min(startIteration + batchSize, iterations)

        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            print("Batch \(batchIndex + 1) of \(totalBatches) started (Iterations \(startIteration + 1) to \(endIteration))...")

            var localBestIteration: [SimulationData] = []
            var localClosestDistance = Double.greatestFiniteMagnitude
            var localIterations: [[SimulationData]] = []

            for _ in startIteration..<endIteration {
                let currentIteration = simulateSingleRun(
                    spreadsheetData: spreadsheetData,
                    initialBTCPriceUSD: initialBTCPriceUSD,
                    btcGrowthRate: btcGrowthRate
                )
                localIterations.append(currentIteration)

                let distance = zip(currentIteration, spreadsheetData).reduce(0.0) { acc, pair in
                    acc + abs(pair.0.portfolioValueEUR - pair.1.portfolioValueEUR)
                }

                if distance < localClosestDistance {
                    localClosestDistance = distance
                    localBestIteration = currentIteration
                }
            }

            lock.lock()
            if localClosestDistance < closestDistance {
                closestDistance = localClosestDistance
                bestIteration = localBestIteration
            }
            allIterations.append(contentsOf: localIterations)
            lock.unlock()

            print("Batch \(batchIndex + 1) of \(totalBatches) completed.")
            dispatchGroup.leave()
        }
    }

    dispatchGroup.wait()
    print("Monte Carlo simulation completed with \(iterations) iterations across \(totalBatches) batches.")
    return (bestIteration, allIterations)
}

private func simulateSingleRun(
    spreadsheetData: [SimulationData],
    initialBTCPriceUSD: Double,
    btcGrowthRate: Double
) -> [SimulationData] {
    var results: [SimulationData] = []

    let week1Data = spreadsheetData[0]
    results.append(week1Data)

    var previousBTCPriceUSD = week1Data.btcPriceUSD
    var previousNetBTCHoldings = week1Data.netBTCHoldings

    for weekIndex in 1..<spreadsheetData.count {
        let weekData = spreadsheetData[weekIndex]
        let btcPriceUSD = previousBTCPriceUSD * (1.0 + btcGrowthRate)
        let btcPriceEUR = btcPriceUSD / 1.06

        let btcGrowth = previousNetBTCHoldings * btcGrowthRate
        let contributionEUR = weekData.contributionEUR
        let contributionFeeEUR = contributionEUR * 0.0025
        let netContributionBTC = (contributionEUR - contributionFeeEUR) / btcPriceEUR

        let withdrawalEUR = weekData.withdrawalEUR
        let portfolioPreWithdrawalEUR = (previousNetBTCHoldings + btcGrowth + netContributionBTC) * btcPriceEUR
        let netBTCHoldings = (previousNetBTCHoldings + btcGrowth + netContributionBTC) - (withdrawalEUR / btcPriceEUR)
        let portfolioValueEUR = netBTCHoldings * btcPriceEUR

        let data = SimulationData(
            id: UUID(),
            week: weekData.week,
            cyclePhase: weekData.cyclePhase,
            startingBTC: previousNetBTCHoldings,
            btcGrowth: btcGrowth,
            netBTCHoldings: netBTCHoldings,
            btcPriceUSD: btcPriceUSD,
            btcPriceEUR: btcPriceEUR,
            portfolioValueEUR: portfolioValueEUR,
            contributionEUR: contributionEUR,
            contributionFeeEUR: contributionFeeEUR,
            netContributionBTC: netContributionBTC,
            withdrawalEUR: withdrawalEUR,
            portfolioPreWithdrawalEUR: portfolioPreWithdrawalEUR
        )

        results.append(data)
        previousBTCPriceUSD = btcPriceUSD
        previousNetBTCHoldings = netBTCHoldings
    }

    return results
}

// let spreadsheetData = loadCSV() // Ensure this function is available and returns data

// let results = runMonteCarloSimulationsWithSpreadsheetData(
//    spreadsheetData: spreadsheetData,
//        initialBTCPriceUSD: 1000.0,
//    iterations: 1_000_000
// )

/// Calculate BTC price in USD for the current week based on the previous week's price
func calculateBTCPriceUSD(previousBTCPriceUSD: Double) -> Double {
    // Define parameters
    let baselineGrowthRate = 0.005 // 0.5% weekly growth
    let volatilityFactor = 0.1    // Normal weekly price fluctuation
    let extremeEventProbability = 0.01 // 1% chance of extreme event
    let extremeEventImpact = -0.25 // Extreme event reduces price by up to 25%

    // Calculate random volatility using a normal distribution
    let randomVolatility = NORMSINV(Double.random(in: 1e-10..<1.0 - 1e-10)) * volatilityFactor

    // Check if a rare extreme event occurs
    let extremeEvent = Double.random(in: 0.0..<1.0) < extremeEventProbability
        ? log(1 - (0.2 * Double.random(in: 0.0..<1.0))) * extremeEventImpact
        : 0.0

    // Calculate the new BTC price
    let btcPriceUSD = max(100.0, previousBTCPriceUSD * exp(baselineGrowthRate + randomVolatility + extremeEvent))
    return btcPriceUSD
}

/// Helper function to calculate the inverse cumulative distribution function (CDF) of the standard normal distribution
func NORMSINV(_ p: Double) -> Double {
    // Guard against invalid inputs
    if p <= 0.0 {
        return -Double.infinity
    } else if p >= 1.0 {
        return Double.infinity
    }
    // Approximation for the inverse of the normal distribution
    let a1 = -39.6968302866538
    let a2 = 220.946098424521
    let a3 = -275.928510446969
    let a4 = 138.357751867269
    let a5 = -30.6647980661472
    let a6 = 2.50662827745924

    let b1 = -54.4760987982241
    let b2 = 161.585836858041
    let b3 = -155.698979859887
    let b4 = 66.8013118877197
    let b5 = -13.2806815528857

    let c1 = -0.007784894002430293
    let c2 = -0.3223964580411365
    let c3 = -2.400758277161838
    let c4 = -2.549732539343734
    let c5 = 4.374664141464968
    let c6 = 2.938163982698783

    let d1 = 0.007784695709041462
    let d2 = 0.3224671290700398
    let d3 = 2.445134137142996
    let d4 = 3.754408661907416

    let pLow = 0.02425
    let pHigh = 1 - pLow

    if p < pLow {
        let q = sqrt(-2 * log(p))
        return (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
               ((((d1 * q + d2) * q + d3) * q + d4) * q + 1)
    } else if p <= pHigh {
        let q = p - 0.5
        let r = q * q
        return (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
               (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1)
    } else {
        let q = sqrt(-2 * log(1 - p))
        return -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
                ((((d1 * q + d2) * q + d3) * q + d4) * q + 1)
    }
}

func aggregateResults(allIterations: [[SimulationData]]) -> [String: [String: Double]] {
    // Dictionary to store aggregated statistics for each week
    var statistics: [String: [String: Double]] = [:]

    let totalIterations = allIterations.count
    guard totalIterations > 0 else { return statistics }

    let weeks = allIterations[0].count

    for weekIndex in 0..<weeks {
        var portfolioValues: [Double] = []

        // Collect portfolio values for the current week across all iterations
        for iteration in allIterations {
            portfolioValues.append(iteration[weekIndex].portfolioValueEUR)
        }

        // Calculate statistics for the current week
        let mean = portfolioValues.reduce(0, +) / Double(totalIterations)
        let median = calculateMedian(values: portfolioValues)
        let standardDeviation = calculateStandardDeviation(values: portfolioValues, mean: mean)
        let percentile90 = calculatePercentile(values: portfolioValues, percentile: 90)
        let percentile10 = calculatePercentile(values: portfolioValues, percentile: 10)

        statistics["Week \(weekIndex + 1)"] = [
            "Mean": mean,
            "Median": median,
            "Standard Deviation": standardDeviation,
            "90th Percentile": percentile90,
            "10th Percentile": percentile10
        ]
    }

    return statistics
}

func calculateStandardDeviation(values: [Double], mean: Double) -> Double {
    let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
}

func calculatePercentile(values: [Double], percentile: Double) -> Double {
    let sortedValues = values.sorted()
    let index = Int(Double(sortedValues.count - 1) * (percentile / 100.0))
    return sortedValues[index]
}
