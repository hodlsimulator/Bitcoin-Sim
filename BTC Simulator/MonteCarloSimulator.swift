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
    var factor = 1.0
    var toggles = 0
    
    // (1) Approx increment for volatility
    if annualVolatility > 5.0 {
        toggles += Int((annualVolatility - 5.0) / 5.0) + 1
    }
    
    // (2) If volShocks is on (for lumpsum), bump toggles by 1
    if settings.useVolShocks {
        toggles += 1
    }
    
    // (3) If any bullish or bearish factor is on, bump toggles by 1
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
    
    // For each toggle, cut lumpsum growth by 2%
    let maxCutPerToggle = 0.02
    let totalCut = Double(toggles) * maxCutPerToggle
    factor -= totalCut
    
    // Don’t drop below 80%
    factor = max(factor, 0.80)
    
    return factor
}

/// “Dampen outliers” approach using atan
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
    userWeeks: Int,       // Actually 'userPeriods' => # of weeks or months
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    struct PrintOnce {
        static var didPrintFactorSettings: Bool = false
        static var didPrintStandardDeviation: Bool = false
    }

    // Print factor settings once
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        settings.printAllSettings()
        PrintOnce.didPrintFactorSettings = true
    }

    // Get user-specified or default standard deviation
    let parsedSD: Double
    if let standardDeviationString = settings.inputManager?.standardDeviation,
       let sdValue = Double(standardDeviationString) {
        parsedSD = sdValue
    } else {
        parsedSD = 15.0
    }

    if !PrintOnce.didPrintStandardDeviation {
        print("User-input standard deviation (once): \(parsedSD)")
        PrintOnce.didPrintStandardDeviation = true
    }

    // -------------------------------
    // NEW OR CHANGED:
    // Decide if each iteration is 1 week or 1 month
    let periodsPerYear = (settings.periodUnit == .weeks) ? 52.0 : 12.0
    
    // Convert annual CAGR to "per period"
    let cagrDecimal = annualCAGR / 100.0
    let logDrift    = cagrDecimal / periodsPerYear
    
    // Convert annualVolatility & standardDeviation to "per period"
    let periodVol = (annualVolatility / 100.0) / sqrt(periodsPerYear)
    let periodSD  = (parsedSD / 100.0) / sqrt(periodsPerYear)
    // -------------------------------

    // Convert the USD price to EUR
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD
    
    // Convert user’s starting balance to BTC, based on currency
    let userStartingBalanceBTC: Double
    switch settings.currencyPreference {
    case .usd:
        userStartingBalanceBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur, .both:
        userStartingBalanceBTC = settings.startingBalance / firstEURPrice
    }

    var previousBTCHoldings = userStartingBalanceBTC
    var previousBTCPriceUSD = initialBTCPriceUSD

    // Initial portfolio
    let initialPortfolioEUR = userStartingBalanceBTC * firstEURPrice
    let initialPortfolioUSD = userStartingBalanceBTC * initialBTCPriceUSD

    // Results array
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

    // Main loop
    // (Here 'week' is really "period"—one week or one month)
    for week in 2...userWeeks {
        let useHist = settings.useHistoricalSampling
        let useLog  = settings.useLognormalGrowth
        let lumpsum = (!useHist && !useLog)

        if lumpsum {
            // Lump sum => once per year
            // e.g. if months => apply lumpsum in the 12th, 24th, 36th iteration
            // if weeks => 52nd, 104th, 156th iteration, etc.
            
            if Double(week).truncatingRemainder(dividingBy: periodsPerYear) == 0 {
                var lumpsumGrowth = cagrDecimal

                if settings.useVolShocks && annualVolatility > 0.0 {
                    // Vol shock
                    let shockVol: Double
                    if useSeededRandom, var localRNG = seededGen {
                        shockVol = seededRandomNormal(mean: 0, stdDev: periodVol, rng: &localRNG)  // <-- changed weeklyVol => periodVol
                        seededGen = localRNG
                    } else {
                        shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                    }

                    // Additional standard deviation shock
                    var shockSD: Double = 0
                    if periodSD > 0 {
                        if useSeededRandom, var rng = seededGen {
                            shockSD = seededRandomNormal(mean: 0, stdDev: periodSD, rng: &rng)    // <-- changed weeklySD => periodSD
                            seededGen = rng
                        } else {
                            shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                        }
                        shockSD = max(min(shockSD, 2.0), -1.0)
                    }

                    // lumpsumGrowth = (1 + lumpsumGrowth) * e^(shockVol+shockSD) - 1
                    let combinedShocks = exp(shockVol + shockSD)
                    lumpsumGrowth = (1.0 + lumpsumGrowth) * combinedShocks - 1.0
                }

                lumpsumGrowth = applyFactorToggles(baseReturn: lumpsumGrowth, week: week, settings: settings)
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                previousBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }

        } else {
            // "Random draws" approach => log + historical + volShocks
            var totalReturn = 0.0
            if useHist {
                totalReturn += pickRandomReturn(from: historicalBTCWeeklyReturns)
            }
            if useLog {
                totalReturn += logDrift
            }
            if settings.useVolShocks {
                // Vol shock
                let shockVol: Double
                if useSeededRandom, var localRNG = seededGen {
                    shockVol = seededRandomNormal(mean: 0, stdDev: periodVol, rng: &localRNG) // <-- changed
                    seededGen = localRNG
                } else {
                    shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                }
                totalReturn += shockVol

                // Additional standard deviation shock
                if periodSD > 0 {
                    var shockSD: Double
                    if useSeededRandom, var rng = seededGen {
                        shockSD = seededRandomNormal(mean: 0, stdDev: periodSD, rng: &rng)     // <-- changed
                        seededGen = rng
                    } else {
                        shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                    }
                    shockSD = max(min(shockSD, 2.0), -1.0)
                    totalReturn += shockSD
                }
            }

            totalReturn = applyFactorToggles(baseReturn: totalReturn, week: week, settings: settings)
            
            // Original code had 0.46 as a "shrink factor"
            let baseShrinkFactor = 0.46
            totalReturn *= baseShrinkFactor
            
            previousBTCPriceUSD *= exp(totalReturn)
        }

        // Don’t let price go below $1
        previousBTCPriceUSD = max(1.0, previousBTCPriceUSD)
        let currentBTCPriceEUR = previousBTCPriceUSD / exchangeRateEURUSD

        // Figure out typed contributions
        // If user picks .months, then "week <= 52" doesn't make sense.
        // Instead, let's say "first year" means the first 'periodsPerYear' iterations.
        // (So if months => first 12; if weeks => first 52)
        
        // <-- NEW OR CHANGED:
        let isFirstYear = Double(week) <= periodsPerYear
        
        var typedContrib = 0.0
        if isFirstYear {
            if let firstYearContributionString = settings.inputManager?.firstYearContribution,
               let val = Double(firstYearContributionString) {
                typedContrib = val
            }
        } else {
            if let subsequentContributionString = settings.inputManager?.subsequentContribution,
               let val = Double(subsequentContributionString) {
                typedContrib = val
            }
        }

        // Split for USD / EUR / Both
        var typedContribUSD: Double = 0.0
        var typedContribEUR: Double = 0.0
        var netBTC             = 0.0
        var feeUSD: Double     = 0.0
        var feeEUR: Double     = 0.0

        switch settings.currencyPreference {
        case .usd:
            // Contribution is in USD
            typedContribUSD = typedContrib
            feeUSD = typedContribUSD * 0.006
            let netUSD = typedContribUSD - feeUSD
            netBTC = netUSD / previousBTCPriceUSD

        case .eur:
            // Contribution is in EUR
            typedContribEUR = typedContrib
            feeEUR = typedContribEUR * 0.006
            let netEUR = typedContribEUR - feeEUR
            netBTC = netEUR / currentBTCPriceEUR

        case .both:
            // Use whichever currency is selected by user
            if settings.contributionCurrencyWhenBoth == .eur {
                typedContribEUR = typedContrib
                feeEUR = typedContribEUR * 0.006
                let netEUR = typedContribEUR - feeEUR
                netBTC = netEUR / currentBTCPriceEUR
            } else {
                typedContribUSD = typedContrib
                feeUSD = typedContribUSD * 0.006
                let netUSD = typedContribUSD - feeUSD
                netBTC = netUSD / previousBTCPriceUSD
            }
        }

        // Hypothetical holdings => check if threshold triggered
        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR  = hypotheticalHoldings * currentBTCPriceEUR
        var withdrawalEUR         = 0.0
        
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0.0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0.0
        }

        // Subtract withdrawal
        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

        // Final portfolio
        let portfolioEUR = finalHoldings * currentBTCPriceEUR
        let portfolioUSD = finalHoldings * previousBTCPriceUSD
        
        // Store net contribution in the final data
        let netContribUSD = typedContribUSD - feeUSD
        let netContribEUR = typedContribEUR - feeEUR

        // Append simulation data
        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: Decimal(previousBTCPriceUSD),
                btcPriceEUR: Decimal(currentBTCPriceEUR),
                portfolioValueEUR: Decimal(portfolioEUR),
                portfolioValueUSD: Decimal(portfolioUSD),
                
                // Instead of the typedContrib, store the net (after fee)
                contributionEUR: netContribEUR,
                contributionUSD: netContribUSD,
                
                transactionFeeEUR: feeEUR,
                transactionFeeUSD: feeUSD,
                netContributionBTC: netBTC,
                withdrawalEUR: withdrawalEUR,
                withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
            )
        )

        // Update for next iteration
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
        
        // Just to simulate a bit of processing time
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
    
    // Sort runs by their final portfolio value
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    finalValues.sort { $0.0 < $1.0 }
    
    // The median run
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
