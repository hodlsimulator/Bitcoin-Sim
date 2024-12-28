//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI

// MARK: - Example: Factor "startWeek"/"endWeek" constants (adjust or remove if you wish)
private let halvingWeeks         = [210, 420, 630, 840]
private let blackSwanWeeks       = [150, 500]

// In a user-driven approach, you can keep or remove these hardcoded
// factor windows if you want dynamic factor windows. For now, we’ll
// leave them for illustration. They can still be relevant if
// userWeeks >= the highest factor event (e.g. 840).

// MARK: - Weighted sampling / seeded generator toggles
private let useWeightedSampling  = false

/// Whether to use a seeded random approach instead of default random
private var useSeededRandom      = false
private var seededGen: SeededGenerator?

// A simple linear RNG for seeded randomness
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // A simple linear approach or LCG-like progression
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

/// Sets or clears the seed for reproducible runs
private func setRandomSeed(_ seed: UInt64?) {
    if let s = seed {
        print("[SEED] setRandomSeed called with \(s) – locking seed.")
        useSeededRandom = true
        seededGen = SeededGenerator(seed: s)
    } else {
        print("[SEED] setRandomSeed called with nil – using default random.")
        useSeededRandom = false
        seededGen = nil
    }
}

// MARK: - dampenArctan
/// Gentle dampening function so extreme outliers are softened
func dampenArctan(_ rawReturn: Double) -> Double {
    let factor = 5.5
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Historical Arrays
/// Populated from CSVs, presumably elsewhere:
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

// MARK: - pickRandomReturn
/// Helper function for random pick with optional seeding
private func pickRandomReturn(from arr: [Double]) -> Double {
    guard !arr.isEmpty else { return 0.0 }
    if useSeededRandom, var rng = seededGen {
        let val = arr.randomElement(using: &rng) ?? 0.0
        // “Store back” the updated generator
        seededGen = rng
        return val
    } else {
        return arr.randomElement() ?? 0.0
    }
}

// MARK: - runOneFullSimulation
/// A user-driven approach that starts from the user’s chosen BTC price and week count.
/// This replaces the prior “hardcoded 7-week” block approach.
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,              // e.g. 52, 1040, etc. from the user
    initialBTCPriceUSD: Double   // from onboarding (fetched or user typed)
) -> [SimulationData] {
    
    var results: [SimulationData] = []

    // Suppose the user starts with 0 BTC holdings.
    // If you want them to start with some BTC, add an argument or read from settings.
    var previousBTCHoldings = 0.0

    // The user’s chosen BTC price => Week 1
    // e.g. 27,654.12 USD => convert to EUR with exchangeRateEURUSD
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD

    results.append(
        SimulationData(
            week: 1,
            startingBTC: 0.0,
            netBTCHoldings: previousBTCHoldings,  // 0.0 to start
            btcPriceUSD: initialBTCPriceUSD,
            btcPriceEUR: firstEURPrice,
            portfolioValueEUR: previousBTCHoldings * firstEURPrice,
            contributionEUR: 0.0,
            transactionFeeEUR: 0.0,
            netContributionBTC: 0.0,
            withdrawalEUR: 0.0
        )
    )

    // Convert annual CAGR to a weekly growth portion
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0

    // Weekly volatility if you want it; not currently used below,
    // but you can incorporate random normal draws if you like.
    let weeklyVol = annualVolatility / sqrt(52.0)

    var previousBTCPriceUSD = initialBTCPriceUSD

    // Main simulation loop from week 2..userWeeks
    for week in 2...userWeeks {

        // 1) Pick a random historical weekly return
        let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
        let histReturn = pickRandomReturn(from: btcArr)
        
        // 2) Dampen extremes
        let dampenedReturn = dampenArctan(histReturn)
        
        // 3) Combine with base CAGR
        var combinedWeeklyReturn = dampenedReturn + baseWeeklyGrowth

        // 4) Add your factor toggles (bullish + bearish) same as before:

        // Example: Halving
        if settings.useHalving, halvingWeeks.contains(week) {
            combinedWeeklyReturn += settings.halvingBump
        }

        // Example: “Adoption Factor” => incremental drift
        if settings.useAdoptionFactor {
            // A simplistic approach: the further the week, the bigger the drift
            let adoptionFactor = settings.adoptionBaseFactor * Double(week)
            combinedWeeklyReturn += adoptionFactor
        }

        // ... Repeat for each factor, e.g. useInstitutionalDemand, useScarcityEvents,
        // useBlackSwan, etc.
        // If you had “startWeek”/“endWeek” logic, you can still apply it here
        // if (week >= startWeek && week <= endWeek) { ... }.

        // 5) Calculate updated BTC price
        var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0) // floor at $1
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD

        // 6) Contribution logic (example)
        // You can adapt this to user inputs, e.g. “Weekly DCA = 60 EUR for first 52 weeks”
        let contributionEUR = (week <= 52) ? 60.0 : 100.0
        let fee = contributionEUR * 0.0035
        let netBTC = (contributionEUR - fee) / btcPriceEUR

        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR = hypotheticalHoldings * btcPriceEUR

        // 7) Example “withdrawal” logic
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > 60_000 {
            withdrawalEUR = 200.0
        } else if hypotheticalValueEUR > 30_000 {
            withdrawalEUR = 100.0
        }
        let withdrawalBTC = withdrawalEUR / btcPriceEUR

        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)
        let portfolioValEUR = finalHoldings * btcPriceEUR

        // 8) Append the data for this week
        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: btcPriceUSD,
                btcPriceEUR: btcPriceEUR,
                portfolioValueEUR: portfolioValEUR,
                contributionEUR: contributionEUR,
                transactionFeeEUR: fee,
                netContributionBTC: netBTC,
                withdrawalEUR: withdrawalEUR
            )
        )

        // Update for next iteration
        previousBTCHoldings = finalHoldings
        previousBTCPriceUSD = btcPriceUSD
    }

    return results
}

// MARK: - runMonteCarloSimulationsWithProgress
/// The main entry point for multiple iterations (like 1,000 runs).
/// We pass the userWeeks + user’s initial BTC price in to replicate
/// their scenario multiple times with random draws.
func runMonteCarloSimulationsWithProgress(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,               // user’s chosen total weeks
    iterations: Int,
    initialBTCPriceUSD: Double,   // user-provided from onboarding
    isCancelled: () -> Bool,
    progressCallback: @escaping (Int) -> Void,
    seed: UInt64? = nil
) -> ([SimulationData], [[SimulationData]]) {

    // Lock or unlock seed
    setRandomSeed(seed)

    var allRuns = [[SimulationData]]()

    for i in 0..<iterations {
        // Check if user cancelled
        if isCancelled() {
            print("[CANCEL] Stopping mid-iterations at \(i) / \(iterations).")
            break
        }

        let simRun = runOneFullSimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: userWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD
        )

        allRuns.append(simRun)

        // Optional second check
        if isCancelled() {
            print("[CANCEL] Stopping mid-iterations at \(i) / \(iterations).")
            break
        }

        // Update progress
        progressCallback(i + 1)
    }

    // If allRuns is empty => cancelled immediately
    if allRuns.isEmpty {
        return ([], [])
    }

    // Sort final runs by last week's portfolioValue
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? 0.0, $0) }
    finalValues.sort { $0.0 < $1.0 }

    // median run
    let medianRun = finalValues[finalValues.count / 2].1
    return (medianRun, allRuns)
}

// MARK: - Optional normal distribution usage
/// Not used by default, but you could incorporate it
private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
