//
//  ExtendedBootstrapSimulator.swift
//  BTCMonteCarlo
//
//  Created by Conor on 24/01/2025.
//

import Foundation
import GameplayKit

/// Public arrays for single‐asset extended returns (e.g. BTC).
/// Adjust how you fill these as you like.
public var extendedWeeklyReturns: [Double] = []
public var extendedMonthlyReturns: [Double] = []

/// Grabs a contiguous slice from the historical array.
fileprivate func pickContiguousBlock(
    from source: [Double],
    count: Int,
    rng: GKRandomSource
) -> [Double] {
    guard source.count >= count else { return [] }
    let maxStart = source.count - count
    let startIndex = rng.nextInt(upperBound: maxStart)
    let endIndex = startIndex + count
    return Array(source[startIndex..<endIndex])
}

/// Example usage in a weekly simulation context
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
    
    var extendedBlock = [Double]()
    if settings.useExtendedHistoricalSampling {
        extendedBlock = pickContiguousBlock(
            from: extendedWeeklyReturns,
            count: totalWeeklySteps,
            rng: rng
        )
    }

    var results = [SimulationData]()
    var currentPriceUSD = initialBTCPriceUSD

    for weekIndex in 0..<totalWeeklySteps {
        
        var totalReturn = 0.0
        
        // If we got a block and are using extended sampling
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            let sample = extendedBlock[weekIndex]
            // e.g. totalReturn += dampenArctanWeekly(sample)
            totalReturn += sample
        }
        else if settings.useHistoricalSampling {
            // fallback: random pick from historicalBTCWeeklyReturns
        }
        
        // (Optional) apply your lognormal or GARCH logic here

        currentPriceUSD *= exp(totalReturn)
        
        let dataPoint = SimulationData(
            week: weekIndex + 1,
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

/// Example usage in a monthly simulation context
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
            let sample = extendedBlock[monthIndex]
            // e.g. totalReturn += dampenArctanMonthly(sample)
            totalReturn += sample
        }
        else if settings.useHistoricalSampling {
            // fallback: random pick from historicalBTCMonthlyReturns
        }
        
        // (Optional) lognormal / GARCH logic
        currentPriceUSD *= exp(totalReturn)
        
        let dataPoint = SimulationData(
            week: monthIndex + 1, // reusing the 'week' property
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
