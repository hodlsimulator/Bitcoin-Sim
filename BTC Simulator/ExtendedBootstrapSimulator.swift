//
//  ExtendedBootstrapSimulator.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/01/2025.
//

import Foundation
import GameplayKit

// Public arrays to hold your extended BTC+macro returns.
// You can populate them however you like from CSV, JSON, etc.
public var extendedWeeklyReturns: [Double] = []
public var extendedMonthlyReturns: [Double] = []

/// Grabs a contiguous slice from the historical array.
fileprivate func pickContiguousBlock(
    from source: [Double],
    count: Int,
    rng: GKRandomSource
) -> [Double] {
    guard source.count >= count else {
        return []
    }
    let maxStart = source.count - count
    let startIndex = rng.nextInt(upperBound: maxStart)
    let endIndex = startIndex + count
    return Array(source[startIndex..<endIndex])
}

/// Example function showing how to inject contiguous sampling
/// into a weekly simulation run.
func runWeeklySimulationWithExtendedSampling(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeklySteps: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int,
    rng: GKRandomSource
) -> [SimulationData] {
    // If user requested extended historical sampling, fetch a contiguous block
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        extendedBlock = pickContiguousBlock(
            from: extendedWeeklyReturns,
            count: totalWeeklySteps,
            rng: rng
        )
    }

    // Create an empty array for results
    var results = [SimulationData]()
    // We'll do a quick placeholder for price evolution
    var currentPriceUSD = initialBTCPriceUSD

    // Loop over the desired steps
    for weekIndex in 0..<totalWeeklySteps {
        
        var totalReturn = 0.0
        
        // If using extended sampling AND we got enough data, use that
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            let weeklySample = extendedBlock[weekIndex]
            // Apply any dampening or adjustments from your existing code
            // e.g. weeklySample = dampenArctanWeekly(weeklySample)
            totalReturn += weeklySample
        }
        else if settings.useHistoricalSampling {
            // or do your normal random pick from historical returns
            // let randomReturn = pickRandomReturn(...)
            // totalReturn += randomReturn
        }
        
        // If user wants lognormal or lumpsum logic, GARCH updates, etc.,
        // call your existing lumpsum or GARCH code here.
        // e.g. totalReturn += lognormal component, vol shocks, etc.
        
        // For demonstration, just exponentiate totalReturn for the new price
        currentPriceUSD *= exp(totalReturn)
        
        // Create a dummy SimulationData. In real usage,
        // you'd compute net holdings, deposits, etc.
        let dataPoint = SimulationData(
            week: weekIndex + 1,      // 1-based
            startingBTC: 0.0,        // e.g. track from your code
            netBTCHoldings: 0.0,     // e.g. track from your code
            btcPriceUSD: Decimal(currentPriceUSD),
            btcPriceEUR: Decimal(currentPriceUSD / exchangeRateEURUSD),
            portfolioValueEUR: 0,
            portfolioValueUSD: 0,
            contributionEUR: 0,
            contributionUSD: 0,
            transactionFeeEUR: 0,
            transactionFeeUSD: 0,
            netContributionBTC: 0,
            withdrawalEUR: 0,
            withdrawalUSD: 0
        )
        results.append(dataPoint)
    }
    return results
}

/// Example function showing how to inject contiguous sampling
/// into a monthly simulation run.
func runMonthlySimulationWithExtendedSampling(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalMonths: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int,
    rng: GKRandomSource
) -> [SimulationData] {
    // If user requested extended historical sampling, fetch a contiguous block
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        extendedBlock = pickContiguousBlock(
            from: extendedMonthlyReturns,
            count: totalMonths,
            rng: rng
        )
    }

    var results = [SimulationData]()
    var currentPriceUSD = initialBTCPriceUSD

    for monthIndex in 0..<totalMonths {
        
        var totalReturn = 0.0
        
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            let monthlySample = extendedBlock[monthIndex]
            // e.g. monthlySample = dampenArctanMonthly(monthlySample)
            totalReturn += monthlySample
        }
        else if settings.useHistoricalSampling {
            // fallback: pick random monthly return from your normal data
        }
        
        // Insert your existing monthly lumpsum or GARCH logic here, if any
        currentPriceUSD *= exp(totalReturn)
        
        let dataPoint = SimulationData(
            week: monthIndex + 1,  // storing months in 'week' property
            startingBTC: 0.0,
            netBTCHoldings: 0.0,
            btcPriceUSD: Decimal(currentPriceUSD),
            btcPriceEUR: Decimal(currentPriceUSD / exchangeRateEURUSD),
            portfolioValueEUR: 0,
            portfolioValueUSD: 0,
            contributionEUR: 0,
            contributionUSD: 0,
            transactionFeeEUR: 0,
            transactionFeeUSD: 0,
            netContributionBTC: 0,
            withdrawalEUR: 0,
            withdrawalUSD: 0
        )
        results.append(dataPoint)
    }
    return results
}
