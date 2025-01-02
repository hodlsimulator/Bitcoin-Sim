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
    let factor = 5.5
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Historical Arrays
// If you load from CSV or so, just populate these before running:
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

// MARK: - pickRandomReturn
/// Helper function for random pick with optional seeding
private func pickRandomReturn(from arr: [Double]) -> Double {
    guard !arr.isEmpty else {
        return 0.0
    }
    
    if useSeededRandom, var rng = seededGen {
        let val = arr.randomElement(using: &rng) ?? 0.0
        seededGen = rng
        return val
    } else {
        let val = arr.randomElement() ?? 0.0
        return val
    }
}

// MARK: - runOneFullSimulation
/// Single-run simulation referencing your “userWeeks”, “initialBTCPriceUSD”, etc.
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    /*
    // A nested struct so we only print factor settings once
    struct PrintOnce {
        static var didPrintFactorSettings: Bool = false
    }
    
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
    } */

    // We typically rely on runMonteCarloSimulationsWithProgress to call `setRandomSeed(...)`
    // If you want to forcibly set it here, you could do:
    //   setRandomSeed(seed)

    // 1) Initial BTC price in EUR
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD
    
    // 2) Convert user’s typed startingBalance (EUR) into BTC
    let userStartingBalanceEUR = settings.startingBalance
    let userStartingBalanceBTC = userStartingBalanceEUR / firstEURPrice

    // Track last week's data
    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD

    // Annual CAGR => weekly portion
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
    let weeklyVol = annualVolatility / sqrt(52.0)

    var results: [SimulationData] = []

    // 3) Record for week 1
    let initialPortfolioValueEUR = userStartingBalanceBTC * firstEURPrice
    results.append(
        SimulationData(
            week: 1,
            startingBTC: 0.0,
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

    // 4) Main loop from week=2 to userWeeks
    for week in 2...userWeeks {
        
        // Pick a random historical return
        let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
        let histReturn = pickRandomReturn(from: btcArr)
        
        // Dampen extremes
        let dampenedReturn = dampenArctan(histReturn)
        
        // Combine with base CAGR
        var combinedWeeklyReturn = dampenedReturn + baseWeeklyGrowth
        
        // Insert an annualVolatility "shock", seeded if locked
        if useSeededRandom, var localRNG = seededGen {
            let shock = seededRandomNormal(mean: 0, stdDev: weeklyVol, rng: &localRNG)
            seededGen = localRNG
            combinedWeeklyReturn += shock
        } else {
            let shock = randomNormal(mean: 0, standardDeviation: weeklyVol)
            combinedWeeklyReturn += shock
        }
        
        // Example toggles (halving, etc.)
        if settings.useHalving, halvingWeeks.contains(week) {
            combinedWeeklyReturn += settings.halvingBump
        }
        if settings.useAdoptionFactor {
            let adoptionFactor = settings.adoptionBaseFactor * Double(week)
            combinedWeeklyReturn += adoptionFactor
        }
        
        // *** Additional bullish toggles (all default RNG calls) ***
        if settings.useInstitutionalDemand {
            let randBoost = Double.random(in: 0 ... settings.maxDemandBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useCountryAdoption {
            let randBoost = Double.random(in: 0 ... settings.maxCountryAdBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useRegulatoryClarity {
            let randBoost = Double.random(in: 0 ... settings.maxClarityBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useEtfApproval {
            let randBoost = Double.random(in: 0 ... settings.maxEtfBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useTechBreakthrough {
            let randBoost = Double.random(in: 0 ... settings.maxTechBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useScarcityEvents {
            let randBoost = Double.random(in: 0 ... settings.maxScarcityBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useGlobalMacroHedge {
            let randBoost = Double.random(in: 0 ... settings.maxMacroBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useStablecoinShift {
            let randBoost = Double.random(in: 0 ... settings.maxStablecoinBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useDemographicAdoption {
            let randBoost = Double.random(in: 0 ... settings.maxDemoBoost)
            combinedWeeklyReturn += randBoost
        }
        if settings.useAltcoinFlight {
            let randBoost = Double.random(in: 0 ... settings.maxAltcoinBoost)
            combinedWeeklyReturn += randBoost
        }

        // *** Additional bearish toggles (default RNG except for steady drift) ***
        if settings.useBearMarket {
            combinedWeeklyReturn += settings.bearWeeklyDrift
        }
        if settings.useRegClampdown {
            let randDrop = Double.random(in: settings.maxClampDown ... 0)
            combinedWeeklyReturn += randDrop
        }
        if settings.useCompetitorCoin {
            let randDrop = Double.random(in: settings.maxCompetitorBoost ... 0)
            combinedWeeklyReturn += randDrop
        }
        if settings.useSecurityBreach {
            let breachCheck = Double.random(in: 0...1)
            if breachCheck < 0.01 {
                combinedWeeklyReturn += settings.breachImpact
            }
        }
        if settings.useBubblePop {
            let randDrop = Double.random(in: settings.maxPopDrop ... 0)
            combinedWeeklyReturn += randDrop
        }
        if settings.useStablecoinMeltdown {
            let randDrop = Double.random(in: settings.maxMeltdownDrop ... 0)
            combinedWeeklyReturn += randDrop
        }
        if settings.useBlackSwan {
            let blackSwanRoll = Double.random(in: 0...1)
            if blackSwanRoll < 0.005 {
                let drop = Double.random(in: settings.blackSwanDrop ... 0)
                combinedWeeklyReturn += drop
            }
        }
        if settings.useMaturingMarket {
            let randDrop = Double.random(in: settings.maxMaturingDrop ... 0)
            combinedWeeklyReturn += randDrop
        }
        if settings.useRecession {
            let randDrop = Double.random(in: settings.maxRecessionDrop ... 0)
            combinedWeeklyReturn += randDrop
        }

        // 5) Price update
        var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0)  // clamp to min 1.0
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD
        
        // 6) Contribution logic
        let contributionEUR = (week <= 52) ? 60.0 : 100.0
        let fee = contributionEUR * 0.0035
        let netBTC = (contributionEUR - fee) / btcPriceEUR
        
        // Hypothetical holdings
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

// MARK: - randomNormal (fallback if not seeded)
/// Default normal distribution if no locked seed
private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
