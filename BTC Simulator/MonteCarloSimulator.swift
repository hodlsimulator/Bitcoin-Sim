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
    
    // Print factor toggles only once
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        settings.printAllSettings() // same prints as you had
        PrintOnce.didPrintFactorSettings = true
    }

    // 1) Convert USD → EUR
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD

    // 2) Convert user’s typed `startingBalance` to BTC
    let userStartingBalanceBTC: Double
    switch settings.currencyPreference {
    case .usd:
        userStartingBalanceBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur, .both:
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    }

    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD
    
    // 3) Lognormal parameters
    let cagrDecimal = annualCAGR / 100.0
    let logDrift = cagrDecimal / 52.0
    
    // Weekly vol from annualVolatility
    let weeklyVol = (annualVolatility / 100.0) / sqrt(52.0)
    
    // Optional second SD
    let parsedSD = Double(settings.inputManager?.standardDeviation ?? "15.0") ?? 15.0
    let weeklySD = (parsedSD / 100.0) / sqrt(52.0)

    // Record the initial portfolio
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

    // 4) Grab user’s thresholds etc.
    let firstYearContrib   = Double(settings.inputManager?.firstYearContribution ?? "") ?? 0.0
    let subsequentContrib  = Double(settings.inputManager?.subsequentContribution ?? "") ?? 0.0
    let threshold1         = settings.inputManager?.threshold1 ?? 0.0
    let withdraw1          = settings.inputManager?.withdrawAmount1 ?? 0.0
    let threshold2         = settings.inputManager?.threshold2 ?? 0.0
    let withdraw2          = settings.inputManager?.withdrawAmount2 ?? 0.0
    let transactionFeePct  = 0.006

    // Dampening factor for historical picks
    let shrinkFactor = 0.0001

    for week in 2...userWeeks {

        var logReturn = logDrift

        // (A) Historical return if toggled
        if settings.useHistoricalSampling {
            // If you want weighted, adapt accordingly
            let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
            var histReturn = pickRandomReturn(from: btcArr)
            histReturn *= shrinkFactor
            let dampenedReturn = dampenArctan(histReturn)
            logReturn += dampenedReturn
        }

        // (B) If using volatility shocks
        if settings.useVolShocks {
            // Main volatility shock
            let shockVol: Double
            if useSeededRandom, var localRNG = seededGen {
                shockVol = seededRandomNormal(mean: 0, stdDev: weeklyVol, rng: &localRNG)
                seededGen = localRNG
            } else {
                shockVol = randomNormal(mean: 0, standardDeviation: weeklyVol)
            }
            logReturn += shockVol

            // Second standard deviation shock
            if weeklySD > 0.0 {
                var shockSD: Double
                if useSeededRandom, var localRNG = seededGen {
                    shockSD = seededRandomNormal(mean: 0, stdDev: weeklySD, rng: &localRNG)
                    seededGen = localRNG
                } else {
                    shockSD = randomNormal(mean: 0, standardDeviation: weeklySD)
                }
                // Clip big outliers if you like
                shockSD = max(min(shockSD, 2.0), -1.0)
                logReturn += shockSD
            }
        }

        // (C) Factor toggles
        if settings.useHalving, halvingWeeks.contains(week) {
            logReturn += settings.halvingBump
        }
        if settings.useInstitutionalDemand {
            logReturn += settings.maxDemandBoost
        }
        if settings.useCountryAdoption {
            logReturn += settings.maxCountryAdBoost
        }
        if settings.useRegulatoryClarity {
            logReturn += settings.maxClarityBoost
        }
        if settings.useEtfApproval {
            logReturn += settings.maxEtfBoost
        }
        if settings.useTechBreakthrough {
            logReturn += settings.maxTechBoost
        }
        if settings.useScarcityEvents {
            logReturn += settings.maxScarcityBoost
        }
        if settings.useGlobalMacroHedge {
            logReturn += settings.maxMacroBoost
        }
        if settings.useStablecoinShift {
            logReturn += settings.maxStablecoinBoost
        }
        if settings.useDemographicAdoption {
            logReturn += settings.maxDemoBoost
        }
        if settings.useAltcoinFlight {
            logReturn += settings.maxAltcoinBoost
        }
        if settings.useAdoptionFactor {
            logReturn += settings.adoptionBaseFactor
        }
        // Bearish
        if settings.useRegClampdown {
            logReturn += settings.maxClampDown
        }
        if settings.useCompetitorCoin {
            logReturn += settings.maxCompetitorBoost
        }
        if settings.useSecurityBreach {
            logReturn += settings.breachImpact
        }
        if settings.useBubblePop {
            logReturn += settings.maxPopDrop
        }
        if settings.useStablecoinMeltdown {
            logReturn += settings.maxMeltdownDrop
        }
        if settings.useBlackSwan {
            logReturn += settings.blackSwanDrop
        }
        if settings.useBearMarket {
            logReturn += settings.bearWeeklyDrift
        }
        if settings.useMaturingMarket {
            logReturn += settings.maxMaturingDrop
        }
        if settings.useRecession {
            logReturn += settings.maxRecessionDrop
        }

        // (D) Update BTC price
        var currentBTCPriceUSD = previousBTCPriceUSD * exp(logReturn)
        currentBTCPriceUSD = max(1.0, currentBTCPriceUSD)
        let currentBTCPriceEUR = currentBTCPriceUSD / exchangeRateEURUSD

        // (E) Contribution & withdrawal
        let isFirstYear = (week <= 52)
        let typedContrib = isFirstYear ? firstYearContrib : subsequentContrib
        
        let feeUSD = typedContrib * transactionFeePct
        let netUSD = typedContrib - feeUSD
        let netBTC = netUSD / currentBTCPriceUSD

        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR = hypotheticalHoldings * currentBTCPriceEUR
        
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > threshold2 {
            withdrawalEUR = withdraw2
        } else if hypotheticalValueEUR > threshold1 {
            withdrawalEUR = withdraw1
        }
        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

        // (F) Final portfolio
        let portfolioEUR = finalHoldings * currentBTCPriceEUR
        let portfolioUSD = finalHoldings * currentBTCPriceUSD

        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: Decimal(currentBTCPriceUSD),
                btcPriceEUR: Decimal(currentBTCPriceEUR),
                portfolioValueEUR: Decimal(portfolioEUR),
                portfolioValueUSD: Decimal(portfolioUSD),
                contributionEUR: 0.0,
                contributionUSD: 0.0,
                transactionFeeEUR: 0.0,
                transactionFeeUSD: 0.0,
                netContributionBTC: netBTC,
                withdrawalEUR: withdrawalEUR,
                withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
            )
        )

        // Prepare for next iteration
        previousBTCHoldings = finalHoldings
        previousBTCPriceUSD = currentBTCPriceUSD
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
    
