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

// MARK: - Multi-Chunk Picker
/// Stitches multiple contiguous blocks together until we have `totalNeeded` samples.
fileprivate func pickMultiChunkBlock(
    from source: [Double],
    totalNeeded: Int,
    rng: GKRandomSource,
    chunkSize: Int = 52
) -> [Double] {
    // If we have no data at all, return empty
    guard !source.isEmpty else {
        return []
    }

    var stitched = [Double]()

    while stitched.count < totalNeeded {
        // If the chunkSize is bigger than the entire source,
        // fallback to just appending the entire source
        if chunkSize > source.count {
            stitched.append(contentsOf: source)
        } else {
            // Pick a random contiguous slice of length `chunkSize`
            let maxStart = source.count - chunkSize
            let startIndex = rng.nextInt(upperBound: maxStart + 1)
            let endIndex = startIndex + chunkSize
            let chunk = Array(source[startIndex..<endIndex])
            stitched.append(contentsOf: chunk)
        }
    }

    // Trim the final array to exactly `totalNeeded` items
    return Array(stitched.prefix(totalNeeded))
}

// MARK: - Example Weekly Simulation Using Multi-Chunk Extended Sampling
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
        // Multi-chunk approach for weekly data
        extendedBlock = pickMultiChunkBlock(
            from: extendedWeeklyReturns,
            totalNeeded: totalWeeklySteps,
            rng: rng,
            chunkSize: 52 // e.g., 52 weeks (1 year) per chunk
        )
    }

    var results = [SimulationData]()
    var currentPriceUSD = initialBTCPriceUSD

    for weekIndex in 0..<totalWeeklySteps {
        
        var totalReturn = 0.0
        
        // If extended sampling is active and we have a stitched block
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            let sample = extendedBlock[weekIndex]
            // Possibly do something like:
            // totalReturn += dampenArctanWeekly(sample)
            totalReturn += sample
        }
        else if settings.useHistoricalSampling {
            // Fallback: pick from historicalBTCWeeklyReturns
            if !historicalBTCWeeklyReturns.isEmpty {
                let randomPick = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
                totalReturn += randomPick
            }
        }
        
        // (Optional) apply any lognormal or GARCH logic here, then exponentiate
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

// MARK: - Example Monthly Simulation Using Multi-Chunk Extended Sampling
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
        // Multi-chunk approach for monthly data
        extendedBlock = pickMultiChunkBlock(
            from: extendedMonthlyReturns,
            totalNeeded: totalMonths,
            rng: rng,
            chunkSize: 12 // e.g., 12 months (1 year) per chunk
        )
    }

    var results = [SimulationData]()
    var currentPriceUSD = initialBTCPriceUSD

    for monthIndex in 0..<totalMonths {
        
        var totalReturn = 0.0
        
        if settings.useExtendedHistoricalSampling, !extendedBlock.isEmpty {
            let sample = extendedBlock[monthIndex]
            // Possibly do something like:
            // totalReturn += dampenArctanMonthly(sample)
            totalReturn += sample
        }
        else if settings.useHistoricalSampling {
            // Fallback: pick from historicalBTCMonthlyReturns
            if !historicalBTCMonthlyReturns.isEmpty {
                let randomPick = pickRandomReturn(from: historicalBTCMonthlyReturns, rng: rng)
                totalReturn += randomPick
            }
        }
        
        // (Optional) add lognormal/GARCH/meanReversion logic here
        currentPriceUSD *= exp(totalReturn)
        
        let dataPoint = SimulationData(
            week: monthIndex + 1, // reusing 'week' property for months
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
