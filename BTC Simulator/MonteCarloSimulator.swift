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

// MARK: - runOneFullSimulation
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
    
    // Print factor toggles once
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        // ... same prints as before ...
        PrintOnce.didPrintFactorSettings = true
    }

    // 1) Convert USD → EUR
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD

    // 2) Convert user’s typed `startingBalance`
    let userStartingBalanceBTC: Double
    switch settings.currencyPreference {
    case .usd:
        userStartingBalanceBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur, .both:
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    }

    // Track BTC holdings & last known price
    var previousBTCHoldings = userStartingBalanceBTC
    var currentBTCPriceUSD   = initialBTCPriceUSD

    // Record initial portfolio
    let initialPortfolioEUR = userStartingBalanceBTC * firstEURPrice
    let initialPortfolioUSD = userStartingBalanceBTC * initialBTCPriceUSD

    var results: [SimulationData] = []
    results.append(
        SimulationData(
            week: 1,
            startingBTC: 0.0,
            netBTCHoldings: userStartingBalanceBTC,
            btcPriceUSD: Decimal(initialBTCPriceUSD),
            btcPriceEUR: Decimal(firstEURPrice),
            portfolioValueEUR: Decimal(initialPortfolioEUR),
            portfolioValueUSD: Decimal(initialPortfolioUSD),
            contributionEUR: 0.0,
            contributionUSD: 0.0,
            transactionFeeEUR: 0.0,
            transactionFeeUSD: 0.0,
            netContributionBTC: 0.0,
            withdrawalEUR: 0.0,
            withdrawalUSD: 0.0
        )
    )

    // Grab user’s thresholds & contributions
    let firstYearContrib  = Double(settings.inputManager?.firstYearContribution ?? "") ?? 0.0
    let subsequentContrib = Double(settings.inputManager?.subsequentContribution ?? "") ?? 0.0
    let threshold1        = settings.inputManager?.threshold1 ?? 0.0
    let withdraw1         = settings.inputManager?.withdrawAmount1 ?? 0.0
    let threshold2        = settings.inputManager?.threshold2 ?? 0.0
    let withdraw2         = settings.inputManager?.withdrawAmount2 ?? 0.0

    let transactionFeePct = 0.006

    // For the lognormal path, you still might have weeklyVol, etc.
    let cagrDecimal = annualCAGR / 100.0
    let weeklyBase  = cagrDecimal / 52.0

    for week in 2...userWeeks {

        // (A) Figure out how much user contributes
        let isFirstYear  = (week <= 52)
        let typedContrib = isFirstYear ? firstYearContrib : subsequentContrib

        // (B) Adjust BTC Price
        if settings.useLognormalGrowth {
            // Normal log-based weekly approach
            // e.g. currentBTCPriceUSD *= exp( weeklyBase ) or add your factor toggles
            let finalReturn = weeklyBase  // + factor toggles if desired
            currentBTCPriceUSD *= exp(finalReturn)
        } else {
            // ============================
            // Simple "Annual Lump" Approach
            // ============================
            // Every 52 weeks (i.e. when week % 52 == 0), we multiply by (1 + annualCAGR).
            // This ensures lumps at week=52, 104, 156, …, 1040 for a full 20 lumps in 20 years.
            let isYearBoundary = (week % 52 == 0)
            if isYearBoundary {
                currentBTCPriceUSD *= (1.0 + cagrDecimal)
            } else {
                // Otherwise, leave the BTC price alone this week.
            }
        }

        // Safety clamp
        currentBTCPriceUSD = max(1.0, currentBTCPriceUSD)

        // (C) Convert price to EUR
        let currentBTCPriceEUR = currentBTCPriceUSD / exchangeRateEURUSD

        // (D) Contribute
        let feeUSD = typedContrib * transactionFeePct
        let netUsd = typedContrib - feeUSD
        let netBtc = netUsd / currentBTCPriceUSD
        let holdingsAfterContrib = previousBTCHoldings + netBtc

        // (E) Check thresholds => withdrawals
        let hypotheticalValueEUR = holdingsAfterContrib * currentBTCPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > threshold2 {
            withdrawalEUR = withdraw2
        } else if hypotheticalValueEUR > threshold1 {
            withdrawalEUR = withdraw1
        }
        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, holdingsAfterContrib - withdrawalBTC)

        // (F) Final portfolio
        let finalPortfolioEUR = finalHoldings * currentBTCPriceEUR
        let finalPortfolioUSD = finalHoldings * currentBTCPriceUSD

        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: Decimal(currentBTCPriceUSD),
                btcPriceEUR: Decimal(currentBTCPriceEUR),
                portfolioValueEUR: Decimal(finalPortfolioEUR),
                portfolioValueUSD: Decimal(finalPortfolioUSD),
                contributionEUR: 0.0,
                contributionUSD: 0.0,
                transactionFeeEUR: 0.0,
                transactionFeeUSD: 0.0,
                netContributionBTC: netBtc,
                withdrawalEUR: withdrawalEUR,
                withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
            )
        )

        // (G) Update for next iteration
        previousBTCHoldings = finalHoldings
    }

    return results
}   

// -----------------------------------------
// Helper to apply factor toggles
// -----------------------------------------
private func applyFactorToggles(
    baseReturn: Double,
    week: Int,
    settings: SimulationSettings
) -> Double {
    var r = baseReturn
    
    // BULLISH
    if settings.useHalving, halvingWeeks.contains(week) {
        r += settings.halvingBump
    }
    if settings.useInstitutionalDemand {
        r += settings.maxDemandBoost
    }
    if settings.useCountryAdoption {
        r += settings.maxCountryAdBoost
    }
    if settings.useRegulatoryClarity {
        r += settings.maxClarityBoost
    }
    if settings.useEtfApproval {
        r += settings.maxEtfBoost
    }
    if settings.useTechBreakthrough {
        r += settings.maxTechBoost
    }
    if settings.useScarcityEvents {
        r += settings.maxScarcityBoost
    }
    if settings.useGlobalMacroHedge {
        r += settings.maxMacroBoost
    }
    if settings.useStablecoinShift {
        r += settings.maxStablecoinBoost
    }
    if settings.useDemographicAdoption {
        r += settings.maxDemoBoost
    }
    if settings.useAltcoinFlight {
        r += settings.maxAltcoinBoost
    }
    if settings.useAdoptionFactor {
        r += settings.adoptionBaseFactor
    }

    // BEARISH
    if settings.useRegClampdown {
        r += settings.maxClampDown
    }
    if settings.useCompetitorCoin {
        r += settings.maxCompetitorBoost
    }
    if settings.useSecurityBreach {
        r += settings.breachImpact
    }
    if settings.useBubblePop {
        r += settings.maxPopDrop
    }
    if settings.useStablecoinMeltdown {
        r += settings.maxMeltdownDrop
    }
    if settings.useBlackSwan {
        r += settings.blackSwanDrop
    }
    if settings.useBearMarket {
        r += settings.bearWeeklyDrift
    }
    if settings.useMaturingMarket {
        r += settings.maxMaturingDrop
    }
    if settings.useRecession {
        r += settings.maxRecessionDrop
    }
    
    return r
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
    
    // Lock/unlock the seed
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
    
