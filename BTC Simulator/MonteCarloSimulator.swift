//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

// MARK: - Configuration toggles
/// If `true`, we use weighted sampling of weekly returns.
/// If `false`, we pick raw weekly returns as is.
private let useWeightedSampling = false

/// By default, we do not use a seeded generator (you can enable it if you want).
private var useSeededRandom = false

/// Our optional seeded generator (only used if `useSeededRandom = true`).
private var seededGen: SeededGenerator?

// MARK: - Private Seeded Generator
/// A simple pseudo-random generator for deterministic picks.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        // Minimal linear congruential generator (LCG).
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

/// If you want to enable/disable seeded randomness **internally**,
/// just call this from inside MonteCarloSimulator.swift:
private func setRandomSeed(_ seed: UInt64?) {
    if let s = seed {
        useSeededRandom = true
        seededGen = SeededGenerator(seed: s)
    } else {
        useSeededRandom = false
        seededGen = nil
    }
}

// MARK: - Gentle Dampening: arctan
func dampenArctan(_ rawReturn: Double) -> Double {
    // 'factor' is how aggressively to flatten big returns (positive or negative).
    let factor = 5.5
    let scaled = rawReturn * factor
    // arctan is then mapped from [-π/2..+π/2] to [-1..+1].
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Historical Arrays
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

// MARK: - Single Run
func runOneFullSimulation(
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeks: Int
) -> [SimulationData] {
    
    // Hardcoded starting weeks 1..7
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
    
    // Base weekly growth from annual CAGR
    let lastHardcoded = results.last
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
    let weeklyVol = annualVolatility / sqrt(52.0)

    var previousBTCPriceUSD = lastHardcoded?.btcPriceUSD ?? 76_532.03
    var previousBTCHoldings = lastHardcoded?.netBTCHoldings ?? 0.00469014

    for week in 8...totalWeeks {
        // 1) Pull a random weekly return from CSV
        let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
        let histReturn = pickRandomReturn(from: btcArr)
        
        // 2) Dampen extremes
        let dampenedReturn = dampenArctan(histReturn)
        
        // 3) Combine with CAGR
        var combinedWeeklyReturn = dampenedReturn + baseWeeklyGrowth
        
        // 4) Optional random shock
        //    If you want seeded or not, handle it here internally:
        // let shock = randomNormal(mean: 0.0, standardDeviation: weeklyVol)
        // combinedWeeklyReturn += shock

        // 5) Update BTC price
        var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0)
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD

        // Log every 50 weeks
        if week % 50 == 0 {
            print(
                "[Week \(week)] WeeklyReturn = "
                + String(format: "%.4f", combinedWeeklyReturn)
                + ", btcPriceUSD = "
                + String(format: "%.2f", btcPriceUSD)
            )
        }
        
        // Contribution
        let contributionEUR = (week <= 52) ? 60.0 : 100.0
        let fee = contributionEUR * 0.0035
        let netBTC = (contributionEUR - fee) / btcPriceEUR
        
        // Evaluate withdrawals
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

        // Append
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

/// Helper function to pick a random return from an array,
/// using seeded randomness if it’s enabled.
private func pickRandomReturn(from arr: [Double]) -> Double {
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
func runMonteCarloSimulationsWithProgress(
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double,
    exchangeRateEURUSD: Double,
    totalWeeks: Int,
    iterations: Int,
    progressCallback: @escaping (Int) -> Void
) -> ([SimulationData], [[SimulationData]]) {

    // If you want to use seeded randomness internally for testing, do so here:
    // setRandomSeed(12345)
    
    var allRuns = [[SimulationData]]()

    for i in 0..<iterations {
        let simRun = runOneFullSimulation(
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeks: totalWeeks
        )
        allRuns.append(simRun)
        progressCallback(i + 1)
    }

    // sort final results by last week's portfolioValue
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? 0.0, $0) }
    finalValues.sort { $0.0 < $1.0 }

    // median
    let medianRun = finalValues[finalValues.count / 2].1
    return (medianRun, allRuns)
}
