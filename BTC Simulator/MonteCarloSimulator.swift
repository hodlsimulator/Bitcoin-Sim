//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI

// MARK: - Factor windows
private let halvingWeeks    = [210, 420, 630, 840]
private let blackSwanWeeks  = [150, 500]

// Weighted sampling / seeded generator toggles
private let useWeightedSampling = false
private var useSeededRandom = false
private var seededGen: SeededGenerator?

/// A simple seeded RNG
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    
    mutating func next() -> UInt64 {
        // A simple LCG progression
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

/// Lock or unlock the seed.
private func setRandomSeed(_ seed: UInt64?) {
    if let s = seed {
        useSeededRandom = true
        seededGen = SeededGenerator(seed: s)
    } else {
        useSeededRandom = false
        seededGen = nil
    }
}

/// If you want a seeded normal distribution, define it here:
fileprivate func seededRandomNormal<G: RandomNumberGenerator>(
    mean: Double,
    stdDev: Double,
    rng: inout G
) -> Double {
    let u1 = Double(rng.next()) / Double(UInt64.max)
    let u2 = Double(rng.next()) / Double(UInt64.max)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * stdDev + mean
}

/// A gentle dampening function to soften extreme outliers
func dampenArctan(_ rawReturn: Double) -> Double {
    // Same factor as before
    let factor = 3.0
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Historical Arrays
// If you load from CSV or so, just populate these before running:
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

// MARK: - runOneFullSimulation (Lognormal Version)
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    struct PrintOnce {
        static var didPrintFactorSettings: Bool = false
    }
    
    // Print the factor toggles only once
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        // ... same prints as before ...
        PrintOnce.didPrintFactorSettings = true
    }

    // 1) Convert USD → EUR for the initial price
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD

    // 2) Convert the user’s typed `startingBalance` depending on currencyPreference
    let userStartingBalanceBTC: Double
    switch settings.currencyPreference {
    case .usd:
        // typed in USD => convert from USD to BTC
        userStartingBalanceBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur:
        // typed in EUR => convert from EUR to BTC
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    case .both:
        // If "both," treat typed as EUR if user selected both
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    }

    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD

    // ---------------------------
    // LOGNORMAL LOGIC BELOW
    // ---------------------------
    let cagrAsDecimal = annualCAGR / 100.0
    let logDrift = cagrAsDecimal / 52.0  // simplified approach

    // 4) weeklyVol for log-returns
    let weeklyVol = (annualVolatility / 100.0) / sqrt(52.0)

    // 5) Standard Deviation (if you want a 2nd shock)
    let parsedSD = Double(settings.inputManager?.standardDeviation ?? "15.0") ?? 15.0
    let weeklySD = (parsedSD / 100.0) / sqrt(52.0)

    var results: [SimulationData] = []

    // Record the initial portfolio
    let initialPortfolioValueEUR = userStartingBalanceBTC * firstEURPrice
    let initialPortfolioValueUSD = userStartingBalanceBTC * initialBTCPriceUSD
    results.append(
        SimulationData(
            week: 1,
            startingBTC: 0.0,
            netBTCHoldings: userStartingBalanceBTC,
            btcPriceUSD: Decimal(initialBTCPriceUSD),
            btcPriceEUR: Decimal(firstEURPrice),
            portfolioValueEUR: Decimal(initialPortfolioValueEUR),
            portfolioValueUSD: Decimal(initialPortfolioValueUSD),
            contributionEUR: 0.0,
            contributionUSD: 0.0,
            transactionFeeEUR: 0.0,
            transactionFeeUSD: 0.0,
            netContributionBTC: 0.0,
            withdrawalEUR: 0.0,
            withdrawalUSD: 0.0
        )
    )

    // Grab user’s thresholds, contributions, etc.
    let firstYearContribString  = settings.inputManager?.firstYearContribution
    let subsequentContribString = settings.inputManager?.subsequentContribution
    let threshold1              = settings.inputManager?.threshold1
    let withdraw1               = settings.inputManager?.withdrawAmount1
    let threshold2              = settings.inputManager?.threshold2
    let withdraw2               = settings.inputManager?.withdrawAmount2

    let firstYearContrib   = Double(firstYearContribString ?? "") ?? 0.0
    let subsequentContrib  = Double(subsequentContribString ?? "") ?? 0.0
    let finalThreshold1    = threshold1 ?? 0.0
    let finalWithdraw1     = withdraw1  ?? 0.0
    let finalThreshold2    = threshold2 ?? 0.0
    let finalWithdraw2     = withdraw2  ?? 0.0

    let transactionFeePct  = 0.006
    
    // 6) Main loop using log-returns
    // Extra scale factor to dampen historical picks even further
    let shrinkFactor = 0.05

    for week in 2...userWeeks {
        
        // Historical return
        let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
        let histReturn = pickRandomReturn(from: btcArr)
        // Hard shrink factor:
        let scaledReturn = histReturn * shrinkFactor
        // Then apply arctan dampening
        let dampenedReturn = dampenArctan(scaledReturn)

        // Combine that with logDrift
        var logReturn = logDrift + dampenedReturn

        // Vol shock
        let shockVol: Double
        if useSeededRandom, var localRNG = seededGen {
            shockVol = seededRandomNormal(mean: 0, stdDev: weeklyVol, rng: &localRNG)
            seededGen = localRNG
        } else {
            shockVol = randomNormal(mean: 0, standardDeviation: weeklyVol)
        }
        logReturn += shockVol

        // Optional 2nd SD shock
        if weeklySD > 0.0 {
            var shockSD: Double
            if useSeededRandom, var localRNG = seededGen {
                shockSD = seededRandomNormal(mean: 0, stdDev: weeklySD, rng: &localRNG)
                seededGen = localRNG
            } else {
                shockSD = randomNormal(mean: 0, standardDeviation: weeklySD)
            }
            shockSD = max(min(shockSD, 2.0), -1.0)
            logReturn += shockSD
        }

        // 7) Factor toggles => now add them to logReturn
        if settings.useHalving, halvingWeeks.contains(week) {
            logReturn += settings.halvingBump
        }
        // (And so on for other toggles.)

        // 8) Price update with exp(logReturn)
        var btcPriceUSD = previousBTCPriceUSD * exp(logReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0)
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD
        
        // 9) Contributions & thresholds
        let isFirstYear = (week <= 52)
        let typedContrib = isFirstYear ? firstYearContrib : subsequentContrib
        
        let feeInUsd = typedContrib * transactionFeePct
        let netUsd   = typedContrib - feeInUsd
        let netBTC   = netUsd / btcPriceUSD
        
        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueUSD  = hypotheticalHoldings * btcPriceUSD
        let hypotheticalValueEUR  = hypotheticalHoldings * btcPriceEUR
        
        var withdrawalEur = 0.0
        if hypotheticalValueEUR > finalThreshold2 {
            withdrawalEur = finalWithdraw2
        } else if hypotheticalValueEUR > finalThreshold1 {
            withdrawalEur = finalWithdraw1
        }
        
        let withdrawalBTC = withdrawalEur / btcPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)
        
        let portfolioValEUR = finalHoldings * btcPriceEUR
        let portfolioValUSD = finalHoldings * btcPriceUSD

        // 10) Append results
        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: Decimal(btcPriceUSD),
                btcPriceEUR: Decimal(btcPriceEUR),
                portfolioValueEUR: Decimal(portfolioValEUR),
                portfolioValueUSD: Decimal(portfolioValUSD),
                contributionEUR: 0.0,
                contributionUSD: 0.0,
                transactionFeeEUR: 0.0,
                transactionFeeUSD: 0.0,
                netContributionBTC: netBTC,
                withdrawalEUR: withdrawalEur,
                withdrawalUSD: withdrawalEur / exchangeRateEURUSD
            )
        )

        // Update for next iteration
        previousBTCHoldings = finalHoldings
        previousBTCPriceUSD = btcPriceUSD
    }

    return results
}

// MARK: - pickRandomReturn
fileprivate func pickRandomReturn(from arr: [Double]) -> Double {
    guard !arr.isEmpty else { return 0.0 }
    if useSeededRandom, var rng = seededGen {
        let val = arr.randomElement(using: &rng) ?? 0.0
        seededGen = rng
        return val
    } else {
        return arr.randomElement() ?? 0.0
    }
}

// MARK: - runMonteCarloSimulationsWithProgress
/// Example multi-run method (like 1000 Monte Carlo runs).
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
    seed: UInt64? = nil
) -> ([SimulationData], [[SimulationData]]) {
    
    // Lock or unlock the random seed
    setRandomSeed(seed)
    
    var allRuns = [[SimulationData]]()
    
    print("// DEBUG: runMonteCarloSimulationsWithProgress => Starting loop. iterations=\(iterations)")
    
    for i in 0..<iterations {
        if isCancelled() {
            print("// DEBUG: CANCELLED at iteration \(i). Breaking out.")
            break
        }
        
        // Optional tiny delay
        Thread.sleep(forTimeInterval: 0.01)
        
        let simRun = runOneFullSimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: userWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD
        )
        allRuns.append(simRun)
        
        if isCancelled() {
            print("// DEBUG: CANCELLED after building iteration \(i+1). Breaking out.")
            break
        }
        
        // Fire the progress callback
        progressCallback(i + 1)
    }
    
    if allRuns.isEmpty {
        print("// DEBUG: allRuns is empty => returning ([], [])")
        return ([], [])
    }
    
    // Sort final runs by last week's (EUR) portfolio value
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    finalValues.sort { $0.0 < $1.0 }

    // Median run
    let medianRun = finalValues[finalValues.count / 2].1
    
    print("// DEBUG: loop ended => built \(allRuns.count) runs. Returning median & allRuns.")
    return (medianRun, allRuns)
}

// MARK: - randomNormal (fallback if not seeded)
private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
