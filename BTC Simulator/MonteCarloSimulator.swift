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
        return (sortedValues[count / 2 - 1] + sortedValues[count / 2]) / 2.0
    } else {
        return sortedValues[count / 2]
    }
}

/// Calculates weekly volatility from annual standard deviation.
func calculateWeeklyVolatility(annualStandardDeviation: Double) -> Double {
    return annualStandardDeviation / sqrt(52.0)
}

func runMonteCarloSimulationsWithSpreadsheetData(
    spreadsheetData: [SimulationData],
    initialBTCPriceUSD: Double,
    iterations: Int,
    annualCAGR: Double,
    annualVolatility: Double
) -> ([SimulationData], [[SimulationData]]) {
    let batchSize = 1_000
    let totalBatches = (iterations + batchSize - 1) / batchSize
    print("Total Batches: \(totalBatches), Batch Size: \(batchSize), Total Iterations: \(iterations)")

    var allIterations: [[SimulationData]] = []
    var finalPortfolioValues: [(portfolioValue: Double, iteration: [SimulationData])] = []
    let lock = NSLock()
    let finalValuesLock = NSLock()
    let dispatchGroup = DispatchGroup()

    print("Starting Monte Carlo simulation with \(iterations) iterations across \(totalBatches) batches...")

    for batchIndex in 0..<totalBatches {
        let startIteration = batchIndex * batchSize
        let endIteration = min(startIteration + batchSize, iterations)

        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            print("Batch \(batchIndex + 1) of \(totalBatches) started (Iterations \(startIteration + 1) to \(endIteration))...")

            var localIterations: [[SimulationData]] = []

            for _ in startIteration..<endIteration {
                let currentIteration = simulateSingleRun(
                    spreadsheetData: spreadsheetData,
                    initialBTCPriceUSD: initialBTCPriceUSD,
                    annualCAGR: annualCAGR,
                    annualVolatility: annualVolatility
                )
                localIterations.append(currentIteration)

                // Collect final portfolio value
                let finalPortfolioValue = currentIteration.last!.portfolioValueEUR
                finalValuesLock.lock()
                finalPortfolioValues.append((portfolioValue: finalPortfolioValue, iteration: currentIteration))
                finalValuesLock.unlock()
            }

            lock.lock()
            allIterations.append(contentsOf: localIterations)
            lock.unlock()

            print("Batch \(batchIndex + 1) of \(totalBatches) completed.")
            dispatchGroup.leave()
        }
    }

    dispatchGroup.wait()
    print("Monte Carlo simulation completed with \(iterations) iterations across \(totalBatches) batches.")

    // Sort the finalPortfolioValues by portfolioValue
    finalPortfolioValues.sort { $0.portfolioValue < $1.portfolioValue }

    let totalIterations = finalPortfolioValues.count
    let index90thPercentile = Int(Double(totalIterations - 1) * 0.90)
    let iteration90thPercentile = finalPortfolioValues[index90thPercentile].iteration

    return (iteration90thPercentile, allIterations)
}

func simulateSingleRun(
    spreadsheetData: [SimulationData],
    initialBTCPriceUSD: Double,
    annualCAGR: Double,
    annualVolatility: Double
) -> [SimulationData] {
    var results: [SimulationData] = []

    // Week 1 (Hardcoded)
    results.append(SimulationData(
        id: UUID(),
        week: 1,
        startingBTC: 0.00000000,
        netBTCHoldings: 0.00469014,
        btcPriceUSD: 76_532.03,
        btcPriceEUR: 71_177.69,
        portfolioValueEUR: 333.83,
        contributionEUR: 378.00,
        contributionFeeEUR: 2.46,
        netContributionBTC: 0.00527613,
        withdrawalEUR: 0.0
    ))

    // Week 2 (Hardcoded)
    results.append(SimulationData(
        id: UUID(),
        week: 2,
        startingBTC: 0.00469014,
        netBTCHoldings: 0.00530474,
        btcPriceUSD: 92_000.00,
        btcPriceEUR: 86_792.45,
        portfolioValueEUR: 465.00,
        contributionEUR: 60.00,
        contributionFeeEUR: 0.21,
        netContributionBTC: 0.00069130,
        withdrawalEUR: 0.0
    ))

    // Starting points for simulation from Week 3 onward
    var previousBTCPriceUSD = 92_000.00
    var previousNetBTCHoldings = 0.00530474

    // Simulate Weeks 3 to 1040
    for week in 3...1040 {
        // Deterministic weekly growth
        let weeklyDeterministicGrowth = pow(1 + annualCAGR / 100, 1.0 / 52) - 1

        // Random volatility using Box-Muller transform
        let randomShock = randomNormal(mean: 0, standardDeviation: annualVolatility / sqrt(52.0))

        // Mean reversion adjustment: BTC tends to revert to its exponential growth path
        let meanReversionFactor = 1.0 - 0.02 * (previousBTCPriceUSD / (initialBTCPriceUSD * pow(1 + weeklyDeterministicGrowth, Double(week))) - 1.0)

        // Adjusted growth factor with mean reversion
        let adjustedGrowthFactor = 1 + weeklyDeterministicGrowth + randomShock * meanReversionFactor

        // Calculate BTC price in USD with adjustments
        var btcPriceUSD = previousBTCPriceUSD * adjustedGrowthFactor

        // Rare crash event (1% chance of drawdown between 5% and 30%)
        if Double.random(in: 0..<1) < 0.01 {
            btcPriceUSD *= (1 - Double.random(in: 0.05...0.3))
        }

        // Enforce a minimum BTC price (e.g., $10,000)
        btcPriceUSD = max(btcPriceUSD, 10_000.0)

        // Convert USD price to EUR
        let btcPriceEUR = btcPriceUSD / 1.06

        // Contribution logic
        let contributionEUR: Double = week <= 52 ? 60.0 : 100.0 // Contributions increase after 1 year
        let contributionFeeEUR = contributionEUR * 0.0025 // 0.25% fee
        let netContributionBTC = (contributionEUR - contributionFeeEUR) / btcPriceEUR

        // Withdrawal logic
        let withdrawalEUR: Double = week > 156 ? 200.0 : 0.0 // Start withdrawals after 3 years

        // Calculate net BTC holdings and portfolio value
        let netBTCHoldings = previousNetBTCHoldings + netContributionBTC - (withdrawalEUR / btcPriceEUR)
        let portfolioValueEUR = max(0.0, netBTCHoldings * btcPriceEUR) // Prevent negative values

        // Append this week's data to results
        results.append(SimulationData(
            id: UUID(),
            week: week,
            startingBTC: previousNetBTCHoldings,
            netBTCHoldings: netBTCHoldings,
            btcPriceUSD: btcPriceUSD,
            btcPriceEUR: btcPriceEUR,
            portfolioValueEUR: portfolioValueEUR,
            contributionEUR: contributionEUR,
            contributionFeeEUR: contributionFeeEUR,
            netContributionBTC: netContributionBTC,
            withdrawalEUR: withdrawalEUR
        ))

        // Update for next iteration
        previousBTCPriceUSD = btcPriceUSD
        previousNetBTCHoldings = netBTCHoldings
    }

    return results
}
  
/// Generate a random value from a normal distribution using the Box-Muller Transform
/// Generate a random value from a normal distribution
func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
    return z0 * standardDeviation + mean
}

func aggregateResults(allIterations: [[SimulationData]]) -> [String: [String: Double]] {
    var statistics: [String: [String: Double]] = [:]

    let totalIterations = allIterations.count
    guard totalIterations > 0 else { return statistics }

    let weeks = allIterations[0].count

    for weekIndex in 0..<weeks {
        var portfolioValues: [Double] = []

        for iteration in allIterations {
            portfolioValues.append(iteration[weekIndex].portfolioValueEUR)
        }

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
