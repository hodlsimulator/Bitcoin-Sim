//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI

// MARK: - Factor windows (adjust or remove if you wish)
private let halvingWeeks    = [210, 420, 630, 840]
private let blackSwanWeeks  = [150, 500]

// Weighted sampling / seeded generator toggles
private let useWeightedSampling = false
private var useSeededRandom = false
private var seededGen: SeededGenerator?

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        // A simple LCG-like progression
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

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

/// A gentle dampening function so extreme outliers are softened
func dampenArctan(_ rawReturn: Double) -> Double {
    let factor = 5.5
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Historical Arrays
// These will presumably be populated from CSVs or data files:
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

// MARK: - pickRandomReturn
/// Helper function for random pick with optional seeding
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

// MARK: - runOneFullSimulation
/// Single-run simulation that references your “userWeeks”, “initialBTCPriceUSD”, etc.
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    // A nested struct to hold a static flag
    struct PrintOnce {
        static var didPrintFactorSettings: Bool = false
    }
    
    // Print toggles ONLY on the first call
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        print("useHalving: \(settings.useHalving), halvingBump: \(settings.halvingBump)")
        print("useInstitutionalDemand: \(settings.useInstitutionalDemand), maxDemandBoost: \(settings.maxDemandBoost)")
        print("useCountryAdoption: \(settings.useCountryAdoption), maxCountryAdBoost: \(settings.maxCountryAdBoost)")
        print("useRegulatoryClarity: \(settings.useRegulatoryClarity), maxClarityBoost: \(settings.maxClarityBoost)")
        print("useEtfApproval: \(settings.useEtfApproval), maxEtfBoost: \(settings.maxEtfBoost)")
        print("useTechBreakthrough: \(settings.useTechBreakthrough), maxTechBoost: \(settings.maxTechBoost)")
        print("useScarcityEvents: \(settings.useScarcityEvents), maxScarcityBoost: \(settings.maxScarcityBoost)")
        print("useGlobalMacroHedge: \(settings.useGlobalMacroHedge), maxMacroBoost: \(settings.maxMacroBoost)")
        print("useStablecoinShift: \(settings.useStablecoinShift), maxStablecoinBoost: \(settings.maxStablecoinBoost)")
        print("useDemographicAdoption: \(settings.useDemographicAdoption), maxDemoBoost: \(settings.maxDemoBoost)")
        print("useAltcoinFlight: \(settings.useAltcoinFlight), maxAltcoinBoost: \(settings.maxAltcoinBoost)")
        print("useAdoptionFactor: \(settings.useAdoptionFactor), adoptionBaseFactor: \(settings.adoptionBaseFactor)")
        
        // Bearish toggles
        print("useRegClampdown: \(settings.useRegClampdown), maxClampDown: \(settings.maxClampDown)")
        print("useCompetitorCoin: \(settings.useCompetitorCoin), maxCompetitorBoost: \(settings.maxCompetitorBoost)")
        print("useSecurityBreach: \(settings.useSecurityBreach), breachImpact: \(settings.breachImpact)")
        print("useBubblePop: \(settings.useBubblePop), maxPopDrop: \(settings.maxPopDrop)")
        print("useStablecoinMeltdown: \(settings.useStablecoinMeltdown), maxMeltdownDrop: \(settings.maxMeltdownDrop)")
        print("useBlackSwan: \(settings.useBlackSwan), blackSwanDrop: \(settings.blackSwanDrop)")
        print("useBearMarket: \(settings.useBearMarket), bearWeeklyDrift: \(settings.bearWeeklyDrift)")
        print("useMaturingMarket: \(settings.useMaturingMarket), maxMaturingDrop: \(settings.maxMaturingDrop)")
        print("useRecession: \(settings.useRecession), maxRecessionDrop: \(settings.maxRecessionDrop)")
        print("====================================")
        
        PrintOnce.didPrintFactorSettings = true
    }

    // We no longer reset the seed here; we rely on the caller (if at all)
    // setRandomSeed(seed)

    // 1) Figure out the initial BTC price in EUR
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD
    
    // 2) Convert user’s typed startingBalance (EUR) into BTC
    let userStartingBalanceEUR = settings.startingBalance
    let userStartingBalanceBTC = userStartingBalanceEUR / firstEURPrice

    // Instead of 0.0, we begin from the user’s typed BTC equivalent
    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD

    // Convert annual CAGR to a weekly portion
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
    let weeklyVol = annualVolatility / sqrt(52.0)

    var results: [SimulationData] = []

    // 3) Append an initial record for week 1 that reflects the user’s starting BTC
    let initialPortfolioValueEUR = userStartingBalanceBTC * firstEURPrice
    results.append(
        SimulationData(
            week: 1,
            startingBTC: 0.0, // or userStartingBalanceBTC if you prefer
            netBTCHoldings: userStartingBalanceBTC,
            btcPriceUSD: initialBTCPriceUSD,
            btcPriceEUR: firstEURPrice,
            portfolioValueEUR: initialPortfolioValueEUR,
            contributionEUR: 0.0,
            transactionFeeEUR: 0.0,
            netContributionBTC: 0.0,
            withdrawalEUR: 0.0
        )
    )

    // Main loop from week 2 to userWeeks
    for week in 2...userWeeks {
        
        // 1) Pick a random historical weekly return
        let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
        let histReturn = pickRandomReturn(from: btcArr)
        
        // 2) Dampen extremes
        let dampenedReturn = dampenArctan(histReturn)
        
        // 3) Combine with base CAGR
        var combinedWeeklyReturn = dampenedReturn + baseWeeklyGrowth
        
        // 4) Example toggles (halving, adoption factor, etc.)
        if settings.useHalving, halvingWeeks.contains(week) {
            combinedWeeklyReturn += settings.halvingBump
        }
        if settings.useAdoptionFactor {
            let adoptionFactor = settings.adoptionBaseFactor * Double(week)
            combinedWeeklyReturn += adoptionFactor
        }
        
        // 4a) Additional bullish toggles
        if settings.useInstitutionalDemand {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxDemandBoost)
        }
        if settings.useCountryAdoption {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxCountryAdBoost)
        }
        if settings.useRegulatoryClarity {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxClarityBoost)
        }
        if settings.useEtfApproval {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxEtfBoost)
        }
        if settings.useTechBreakthrough {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxTechBoost)
        }
        if settings.useScarcityEvents {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxScarcityBoost)
        }
        if settings.useGlobalMacroHedge {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxMacroBoost)
        }
        if settings.useStablecoinShift {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxStablecoinBoost)
        }
        if settings.useDemographicAdoption {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxDemoBoost)
        }
        if settings.useAltcoinFlight {
            combinedWeeklyReturn += Double.random(in: 0 ... settings.maxAltcoinBoost)
        }

        // 4b) Additional bearish toggles
        if settings.useBearMarket {
            // Maybe apply a steady bear drift each week
            combinedWeeklyReturn += settings.bearWeeklyDrift
        }
        if settings.useRegClampdown {
            // Negative random effect
            combinedWeeklyReturn += Double.random(in: settings.maxClampDown ... 0)
        }
        if settings.useCompetitorCoin {
            combinedWeeklyReturn += Double.random(in: settings.maxCompetitorBoost ... 0)
        }
        if settings.useSecurityBreach {
            // Could do a 1% chance each week to apply the full breach
            if Double.random(in: 0...1) < 0.01 {
                combinedWeeklyReturn += settings.breachImpact
            }
        }
        if settings.useBubblePop {
            combinedWeeklyReturn += Double.random(in: settings.maxPopDrop ... 0)
        }
        if settings.useStablecoinMeltdown {
            combinedWeeklyReturn += Double.random(in: settings.maxMeltdownDrop ... 0)
        }
        if settings.useBlackSwan {
            // Could do a 0.5% chance
            if Double.random(in: 0...1) < 0.005 {
                let drop = Double.random(in: settings.blackSwanDrop ... 0) // e.g. -0.60 to 0
                combinedWeeklyReturn += drop
            }
        }
        if settings.useMaturingMarket {
            combinedWeeklyReturn += Double.random(in: settings.maxMaturingDrop ... 0)
        }
        if settings.useRecession {
            combinedWeeklyReturn += Double.random(in: settings.maxRecessionDrop ... 0)
        }

        // 5) Price update
        var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0)   // clamp to min 1.0
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD
        
        // 6) Contribution logic
        let contributionEUR = (week <= 52) ? 60.0 : 100.0
        let fee = contributionEUR * 0.0035
        let netBTC = (contributionEUR - fee) / btcPriceEUR
        
        // Hypothetical holdings before withdrawal
        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR = hypotheticalHoldings * btcPriceEUR
        
        // 7) Withdrawal logic
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > 60_000 {
            withdrawalEUR = 200.0
        } else if hypotheticalValueEUR > 30_000 {
            withdrawalEUR = 100.0
        }
        let withdrawalBTC = withdrawalEUR / btcPriceEUR
        
        // Final holdings
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)
        let portfolioValEUR = finalHoldings * btcPriceEUR

        // 8) Append results
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

    // Lock or unlock seed
    setRandomSeed(seed)

    var allRuns = [[SimulationData]]()

    for i in 0..<iterations {
        if isCancelled() {
            print("[CANCEL] Stopping early at \(i) / \(iterations).")
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

        if isCancelled() {
            print("[CANCEL] Stopping early at \(i) / \(iterations).")
            break
        }
        progressCallback(i + 1)
    }

    if allRuns.isEmpty {
        return ([], [])
    }

    // Sort final runs by last week's portfolio value
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? 0.0, $0) }
    finalValues.sort { $0.0 < $1.0 }

    // median run
    let medianRun = finalValues[finalValues.count / 2].1
    return (medianRun, allRuns)
}

// MARK: - Optional normal distribution usage
/// Not used by default, but you could incorporate it.
private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
