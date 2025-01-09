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

// MARK: - runOneFullSimulation (Modified lumpsum path to include volatility + factor toggles)
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,       // e.g. 30%
    annualVolatility: Double, // e.g. 80%
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    struct PrintOnce {
        static var didPrintFactorSettings: Bool = false
    }
    
    // Print toggles only once
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        settings.printAllSettings()
        PrintOnce.didPrintFactorSettings = true
    }
    
    // ---------------------------------------
    // OLD shrinkFactor code restored:
    // ---------------------------------------
    let shrinkFactor = 0.46  // further dampening

    // 1) Convert USD → EUR for the initial price
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD

    // 2) Convert user’s typed `startingBalance` to BTC
    let userStartingBalanceBTC: Double
    switch settings.currencyPreference {
    case .usd:
        userStartingBalanceBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur, .both:
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    }

    // 3) Initialise
    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD
    
    // For lognormal drift
    let cagrDecimal = annualCAGR / 100.0
    let logDrift = cagrDecimal / 52.0

    // For volatility shocks
    let weeklyVol = (annualVolatility / 100.0) / sqrt(52.0)
    let parsedSD = Double(settings.inputManager?.standardDeviation ?? "15.0") ?? 15.0
    let weeklySD = (parsedSD / 100.0) / sqrt(52.0)

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

    // 4) Thresholds, contributions, etc.
    let firstYearContrib  = Double(settings.inputManager?.firstYearContribution ?? "") ?? 0.0
    let subsequentContrib = Double(settings.inputManager?.subsequentContribution ?? "") ?? 0.0
    let threshold1        = settings.inputManager?.threshold1 ?? 0.0
    let withdraw1         = settings.inputManager?.withdrawAmount1 ?? 0.0
    let threshold2        = settings.inputManager?.threshold2 ?? 0.0
    let withdraw2         = settings.inputManager?.withdrawAmount2 ?? 0.0
    let transactionFeePct = 0.006

    for week in 2...userWeeks {
        
        // Decide path: lumpsum if both historical & lognormal are off
        let useHist = settings.useHistoricalSampling
        let useLog  = settings.useLognormalGrowth
        let lumpsum = (!useHist && !useLog)

        if lumpsum {
            // Annual lumpsum each year
            if week % 52 == 0 {
                var lumpsumGrowth = cagrDecimal
                
                // If volatility is toggled on, apply random shock once/year
                if settings.useVolShocks {
                    let shockVol: Double
                    if useSeededRandom, var localRNG = seededGen {
                        shockVol = seededRandomNormal(mean: 0, stdDev: weeklyVol, rng: &localRNG)
                        seededGen = localRNG
                    } else {
                        shockVol = randomNormal(mean: 0, standardDeviation: weeklyVol)
                    }
                    
                    var shockSD: Double = 0.0
                    if weeklySD > 0 {
                        if useSeededRandom, var rng = seededGen {
                            shockSD = seededRandomNormal(mean: 0, stdDev: weeklySD, rng: &rng)
                            seededGen = rng
                        } else {
                            shockSD = randomNormal(mean: 0, standardDeviation: weeklySD)
                        }
                        shockSD = max(min(shockSD, 2.0), -1.0)
                    }
                    
                    // Combine lumpsum + volatility
                    let combinedShocks = exp(shockVol + shockSD)
                    lumpsumGrowth = (1.0 + lumpsumGrowth) * combinedShocks - 1.0
                }
                
                // >>> APPLY FACTOR TOGGLES (bullish/bearish) to lumpsumGrowth
                lumpsumGrowth = applyFactorToggles(baseReturn: lumpsumGrowth, week: week, settings: settings)
                
                // Multiply lumpsumGrowth by shrinkFactor
                lumpsumGrowth *= shrinkFactor
                
                previousBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }

        } else {
            // Weekly path
            var totalWeeklyReturn = 0.0
            
            // Historical returns
            if useHist {
                totalWeeklyReturn += pickRandomReturn(from: historicalBTCWeeklyReturns)
            }
            // Lognormal
            if useLog {
                totalWeeklyReturn += logDrift
            }
            // Vol shocks
            if settings.useVolShocks {
                let shockVol: Double
                if useSeededRandom, var localRNG = seededGen {
                    shockVol = seededRandomNormal(mean: 0, stdDev: weeklyVol, rng: &localRNG)
                    seededGen = localRNG
                } else {
                    shockVol = randomNormal(mean: 0, standardDeviation: weeklyVol)
                }
                totalWeeklyReturn += shockVol

                if weeklySD > 0 {
                    var shockSD: Double
                    if useSeededRandom, var rng = seededGen {
                        shockSD = seededRandomNormal(mean: 0, stdDev: weeklySD, rng: &rng)
                        seededGen = rng
                    } else {
                        shockSD = randomNormal(mean: 0, standardDeviation: weeklySD)
                    }
                    shockSD = max(min(shockSD, 2.0), -1.0)
                    totalWeeklyReturn += shockSD
                }
            }
            
            // >>> APPLY FACTOR TOGGLES (bullish/bearish) to totalWeeklyReturn
            totalWeeklyReturn = applyFactorToggles(baseReturn: totalWeeklyReturn, week: week, settings: settings)
            
            // Multiply weekly returns by shrinkFactor
            totalWeeklyReturn *= shrinkFactor
            
            previousBTCPriceUSD *= exp(totalWeeklyReturn)
        }
        
        // Safeguard
        previousBTCPriceUSD = max(1.0, previousBTCPriceUSD)
        let currentBTCPriceEUR = previousBTCPriceUSD / exchangeRateEURUSD
        
        // Contributions & threshold logic
        let isFirstYear  = (week <= 52)
        let typedContrib = isFirstYear ? firstYearContrib : subsequentContrib
        
        let feeUSD = typedContrib * transactionFeePct
        let netUSD = typedContrib - feeUSD
        let netBTC = netUSD / previousBTCPriceUSD

        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR  = hypotheticalHoldings * currentBTCPriceEUR
        
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > threshold2 {
            withdrawalEUR = withdraw2
        } else if hypotheticalValueEUR > threshold1 {
            withdrawalEUR = withdraw1
        }
        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

        // Final portfolio
        let portfolioEUR = finalHoldings * currentBTCPriceEUR
        let portfolioUSD = finalHoldings * previousBTCPriceUSD

        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: Decimal(previousBTCPriceUSD),
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
