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
    iterations: Int
) -> [SimulationData] {
    let weeks = spreadsheetData.count
    var allPortfolioValues: [[Double]] = Array(repeating: [], count: weeks) // To track portfolio values for each week across iterations
    var allIterations: [[SimulationData]] = [] // Store all iterations

    for iteration in 0..<iterations {
        var currentIteration: [SimulationData] = []
        var previousBTCPriceUSD = initialBTCPriceUSD
        var previousNetBTCHoldings = 0.0
        var previousPortfolioValueEUR = 0.0

        for weekIndex in 0..<weeks {
            let currentWeek = weekIndex + 1

            // Hard-code weeks 1 and 2
            if currentWeek == 1 {
                let week1Data = SimulationData(
                    id: UUID(),
                    week: 1,
                    cyclePhase: "Bull",
                    startingBTC: 0.0,
                    btcGrowth: 0.00469014,
                    netBTCHoldings: 0.00469014,
                    btcPriceUSD: 76532.03,
                    btcPriceEUR: 71177.69,
                    portfolioValueEUR: 333.83,
                    contributionEUR: 378.00,
                    contributionFeeEUR: 2.46,
                    netContributionBTC: 0.00527613,
                    withdrawalEUR: 0.0,
                    portfolioPreWithdrawalEUR: 0.0
                )
                currentIteration.append(week1Data)
                allPortfolioValues[weekIndex].append(333.83)
                previousBTCPriceUSD = week1Data.btcPriceUSD
                previousNetBTCHoldings = week1Data.netBTCHoldings
                previousPortfolioValueEUR = week1Data.portfolioValueEUR
                continue
            }

            if currentWeek == 2 {
                let week2Data = SimulationData(
                    id: UUID(),
                    week: 2,
                    cyclePhase: "Bull",
                    startingBTC: 0.00469014,
                    btcGrowth: 0.00001721,
                    netBTCHoldings: 0.00538683,
                    btcPriceUSD: 93600.91,
                    btcPriceEUR: 88302.75,
                    portfolioValueEUR: 475.67,
                    contributionEUR: 60.00,
                    contributionFeeEUR: 0.21,
                    netContributionBTC: 0.00067948,
                    withdrawalEUR: 0.0,
                    portfolioPreWithdrawalEUR: 414.15
                )
                currentIteration.append(week2Data)
                allPortfolioValues[weekIndex].append(475.67)
                previousBTCPriceUSD = week2Data.btcPriceUSD
                previousNetBTCHoldings = week2Data.netBTCHoldings
                previousPortfolioValueEUR = week2Data.portfolioValueEUR
                continue
            }

            // Cycle Phase Calculation
            let cyclePhase = (weekIndex % 208) < 60 ? "Bull" : "Bear"

            // BTC Price USD Calculation
            let btcPriceUSD = calculateBTCPriceUSD(previousBTCPriceUSD: previousBTCPriceUSD)
            let btcPriceEUR = btcPriceUSD / 1.06

            // BTC Growth Calculation
            let growthMultiplier = cyclePhase == "Bull" ? 1.5 : 0.5
            var btcGrowth = previousNetBTCHoldings * 0.002 * (btcPriceUSD / previousBTCPriceUSD) * growthMultiplier
            if Double.random(in: 0.0..<1.0) >= 0.8 {
                btcGrowth *= -1
            }

            // Contribution and Fee
            let contributionEUR = currentWeek <= 52 ? 60.0 : 100.0
            let feeRate = previousPortfolioValueEUR >= 100000 ? 0.0007 :
                          previousPortfolioValueEUR >= 50000 ? 0.001 :
                          previousPortfolioValueEUR >= 5000 ? 0.0015 :
                          previousPortfolioValueEUR >= 1000 ? 0.0025 : 0.0035
            let contributionFeeEUR = contributionEUR * feeRate
            let netContributionBTC = (contributionEUR - contributionFeeEUR) / btcPriceEUR

            // Withdrawals and Portfolio Value
            let portfolioPreWithdrawalEUR = previousNetBTCHoldings * btcPriceEUR
            let withdrawalEUR = portfolioPreWithdrawalEUR > 60000 ? 200.0 :
                                portfolioPreWithdrawalEUR > 40000 ? 200.0 :
                                portfolioPreWithdrawalEUR > 30000 ? 100.0 : 0.0
            let netBTCHoldings = previousNetBTCHoldings + btcGrowth + netContributionBTC - (withdrawalEUR / btcPriceEUR)
            let portfolioValueEUR = netBTCHoldings * btcPriceEUR

            // Collect data
            let weekData = SimulationData(
                id: UUID(),
                week: currentWeek,
                cyclePhase: cyclePhase,
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
            currentIteration.append(weekData)

            // Update for next week
            previousBTCPriceUSD = btcPriceUSD
            previousNetBTCHoldings = netBTCHoldings
            previousPortfolioValueEUR = portfolioValueEUR

            // Add portfolio value to the aggregated data
            allPortfolioValues[weekIndex].append(portfolioValueEUR)
        }

        // Add current iteration
        allIterations.append(currentIteration)
    }

    // Calculate median portfolio values for each week
    let medianPortfolioValues = allPortfolioValues.map { calculateMedian(values: $0) }

    // Find the closest iteration to the median
    var mostProbableIteration: [SimulationData] = []
    var closestDistance = Double.greatestFiniteMagnitude

    for iteration in allIterations {
        let distance = zip(iteration, medianPortfolioValues).reduce(0.0) { acc, pair in
            acc + abs(pair.0.portfolioValueEUR - pair.1)
        }
        if distance < closestDistance {
            closestDistance = distance
            mostProbableIteration = iteration
        }
    }

    print("Most Probable Iteration Found.")
    return mostProbableIteration
}

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
