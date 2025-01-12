//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI

private let halvingWeeks    = [210, 420, 630, 840]
private let blackSwanWeeks  = [150, 500]

private let useWeightedSampling = false
private var useSeededRandom = false
private var seededGen: SeededGenerator?

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    
    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

private func setRandomSeed(_ seed: UInt64?) {
    if let s = seed {
        useSeededRandom = true
        seededGen = SeededGenerator(seed: s)
    } else {
        useSeededRandom = false
        seededGen = nil
    }
}

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

/// Instead of a fixed “shrinkFactor = 0.46”, we do a small percent cut per toggle.
private func lumpsumAdjustFactor(
    settings: SimulationSettings,
    annualVolatility: Double
) -> Double {
    // Start at 1.0 => no dampening at all
    var factor = 1.0
    var toggles = 0
    
    // 1) Approx increment for volatility
    //    e.g. 0–5% => toggles = 0
    //         5–10% => toggles = 1
    //         10–15% => toggles = 2
    //         etc.
    if annualVolatility > 5.0 {
        toggles += Int((annualVolatility - 5.0) / 5.0) + 1
    }
    
    // 2) If volShocks is on (for lumpsum), bump toggles by 1
    if settings.useVolShocks {
        toggles += 1
    }
    
    // 3) If any bullish or bearish factor is on, bump toggles by 1
    let bullishCount = [
        settings.useHalving,
        settings.useInstitutionalDemand,
        settings.useCountryAdoption,
        settings.useRegulatoryClarity,
        settings.useEtfApproval,
        settings.useTechBreakthrough,
        settings.useScarcityEvents,
        settings.useGlobalMacroHedge,
        settings.useStablecoinShift,
        settings.useDemographicAdoption,
        settings.useAltcoinFlight,
        settings.useAdoptionFactor
    ].filter { $0 }.count
    
    let bearishCount = [
        settings.useRegClampdown,
        settings.useCompetitorCoin,
        settings.useSecurityBreach,
        settings.useBubblePop,
        settings.useStablecoinMeltdown,
        settings.useBlackSwan,
        settings.useBearMarket,
        settings.useMaturingMarket,
        settings.useRecession
    ].filter { $0 }.count
    
    if bullishCount + bearishCount > 0 {
        toggles += 1
    }
    
    // For each toggle, cut lumpsum growth by 2% (adjust to taste)
    // So if toggles = 5 => lumpsumGrowth * 0.90 => a 10% cut
    let maxCutPerToggle = 0.02 // 2%
    let totalCut = Double(toggles) * maxCutPerToggle
    
    factor -= totalCut
    // Don’t drop below 80% => lumpsumGrowth * 0.80
    factor = max(factor, 0.80)
    
    return factor
}

/// Our old “dampen outliers” approach — you can keep or remove
func dampenArctan(_ rawReturn: Double) -> Double {
    let factor = 3.0
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// Historical arrays
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

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
        static var didPrintStandardDeviation: Bool = false
    }

    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        settings.printAllSettings()
        PrintOnce.didPrintFactorSettings = true
    }

    let parsedSD: Double
    if let standardDeviationString = settings.inputManager?.standardDeviation {
        if let sdValue = Double(standardDeviationString) {
            parsedSD = sdValue
        } else {
            parsedSD = 15.0
        }
    } else {
        parsedSD = 15.0
    }

    if !PrintOnce.didPrintStandardDeviation {
        print("User-input standard deviation (once): \(parsedSD)")
        PrintOnce.didPrintStandardDeviation = true
    }

    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD
    let userStartingBalanceBTC: Double
    switch settings.currencyPreference {
    case .usd:
        userStartingBalanceBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur, .both:
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    }

    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD
    
    let cagrDecimal = annualCAGR / 100.0
    let logDrift = cagrDecimal / 52.0

    let weeklyVol = (annualVolatility / 100.0) / sqrt(52.0)
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

    for week in 2...userWeeks {
        let useHist = settings.useHistoricalSampling
        let useLog = settings.useLognormalGrowth
        let lumpsum = (!useHist && !useLog)

        if lumpsum {
            if week % 52 == 0 {
                var lumpsumGrowth = cagrDecimal

                if settings.useVolShocks && annualVolatility > 0.0 {
                    let shockVol: Double
                    if useSeededRandom, var localRNG = seededGen {
                        shockVol = seededRandomNormal(mean: 0, stdDev: weeklyVol, rng: &localRNG)
                        seededGen = localRNG
                    } else {
                        shockVol = randomNormal(mean: 0, standardDeviation: weeklyVol)
                    }

                    var shockSD: Double = 0
                    if weeklySD > 0 {
                        if useSeededRandom, var rng = seededGen {
                            shockSD = seededRandomNormal(mean: 0, stdDev: weeklySD, rng: &rng)
                            seededGen = rng
                        } else {
                            shockSD = randomNormal(mean: 0, standardDeviation: weeklySD)
                        }
                        shockSD = max(min(shockSD, 2.0), -1.0)
                    }

                    let combinedShocks = exp(shockVol + shockSD)
                    lumpsumGrowth = (1.0 + lumpsumGrowth) * combinedShocks - 1.0
                }

                lumpsumGrowth = applyFactorToggles(baseReturn: lumpsumGrowth, week: week, settings: settings)
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                previousBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }

        } else {
            var totalWeeklyReturn = 0.0
            if useHist {
                totalWeeklyReturn += pickRandomReturn(from: historicalBTCWeeklyReturns)
            }
            if useLog {
                totalWeeklyReturn += logDrift
            }
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

            totalWeeklyReturn = applyFactorToggles(baseReturn: totalWeeklyReturn, week: week, settings: settings)
            let baseShrinkFactor = 0.46
            totalWeeklyReturn *= baseShrinkFactor
            previousBTCPriceUSD *= exp(totalWeeklyReturn)
        }

        previousBTCPriceUSD = max(1.0, previousBTCPriceUSD)
        let currentBTCPriceEUR = previousBTCPriceUSD / exchangeRateEURUSD

        // Corrected Contribution Logic
        let isFirstYear = (week <= 52)
        let typedContrib: Double
        if isFirstYear {
            if let firstYearContributionString = settings.inputManager?.firstYearContribution,
               let firstYearContribution = Double(firstYearContributionString) {
                typedContrib = firstYearContribution
            } else {
                typedContrib = 0.0
            }
        } else {
            if let subsequentContributionString = settings.inputManager?.subsequentContribution,
               let subsequentContribution = Double(subsequentContributionString) {
                typedContrib = subsequentContribution
            } else {
                typedContrib = 0.0
            }
        }

        let feeUSD = typedContrib * 0.006
        let netUSD = typedContrib - feeUSD
        let netBTC = netUSD / previousBTCPriceUSD

        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR = hypotheticalHoldings * currentBTCPriceEUR
        var withdrawalEUR = 0.0

        if hypotheticalValueEUR > settings.inputManager?.threshold2 ?? 0.0 {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0.0
        } else if hypotheticalValueEUR > settings.inputManager?.threshold1 ?? 0.0 {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0.0
        }

        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

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

private func applyFactorToggles(
    baseReturn: Double,
    week: Int,
    settings: SimulationSettings
) -> Double {
    var r = baseReturn

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
    
    setRandomSeed(seed)
    var allRuns = [[SimulationData]]()
    
    print("// DEBUG: runMonteCarloSimulationsWithProgress => Starting loop. iterations=\(iterations)")
    
    for i in 0..<iterations {
        if isCancelled() {
            print("// DEBUG: CANCELLED at iteration \(i). Breaking out.")
            break
        }
        
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
        
        progressCallback(i + 1)
    }
    
    if allRuns.isEmpty {
        print("// DEBUG: allRuns is empty => returning ([], [])")
        return ([], [])
    }
    
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    finalValues.sort { $0.0 < $1.0 }

    let medianRun = finalValues[finalValues.count / 2].1
    
    print("// DEBUG: loop ended => built \(allRuns.count) runs. Returning median & allRuns.")
    return (medianRun, allRuns)
}

private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
