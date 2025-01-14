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

/// Approx weeks-per-month factor (52 weeks / 12 months)
private let weeksPerMonthApprox: Double = 52.0 / 12.0

/// A generator that allows a repeatable random sequence if a seed is locked
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

/// A helper to do normal draws with a seeded generator (if present)
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

/// Core function that always runs "weekly steps" (even if the user selected months).
///
/// * If `periodUnit == .weeks`, we do `totalWeeks = userWeeks`.
/// * If `periodUnit == .months`, we do `totalWeeks = Int(round(Double(userWeeks) * 4.3333))`.
///   That means e.g. 240 months => ~1040 weeks behind the scenes.
/// After building the full weekly results, if the user wanted months, we resample it back
/// to 240 monthly points.
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,       // Could be 1040 if weeks, or 240 if months
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    // 1) Convert months → weeks if needed
    let isActuallyMonths = (settings.periodUnit == .months)
    let doublePeriods = Double(userWeeks) // e.g. 240 if months
    var totalWeeklySteps = userWeeks // e.g. 1040 if weeks
    if isActuallyMonths {
        // e.g. 240 months => ~ 240 * 4.3333 = ~1040
        let approxWeeks = doublePeriods * weeksPerMonthApprox
        totalWeeklySteps = Int(round(approxWeeks))
    }

    // We store each "weekly step" in an array
    var weeklyResults = runWeeklySimulation(
        settings: settings,
        annualCAGR: annualCAGR,
        annualVolatility: annualVolatility,
        exchangeRateEURUSD: exchangeRateEURUSD,
        totalWeeklySteps: totalWeeklySteps,
        initialBTCPriceUSD: initialBTCPriceUSD
    )

    // If user wanted weeks, just return weeklyResults
    if !isActuallyMonths {
        return weeklyResults
    }

    // Otherwise, the user asked for months => resample the weekly array
    // to produce "userWeeks" points, i.e. 240 monthly data points.
    // For each month M = 1..240 => pick the snapshot from weekly data
    // at index = round(M * 4.3333).
    
    var monthlyResults: [SimulationData] = []
    for monthIndex in 1...userWeeks {
        let approxWeek = Double(monthIndex) * weeksPerMonthApprox
        let bestWeekIndex = Int(round(approxWeek))
        let safeIndex = max(1, min(bestWeekIndex, weeklyResults.count))
        
        let snap = weeklyResults[safeIndex - 1]

        let monthData = SimulationData(
            week: monthIndex,
            startingBTC: snap.startingBTC,
            netBTCHoldings: snap.netBTCHoldings,
            btcPriceUSD: snap.btcPriceUSD,
            btcPriceEUR: snap.btcPriceEUR,
            portfolioValueEUR: snap.portfolioValueEUR,
            portfolioValueUSD: snap.portfolioValueUSD,
            contributionEUR: snap.contributionEUR,
            contributionUSD: snap.contributionUSD,
            transactionFeeEUR: snap.transactionFeeEUR,
            transactionFeeUSD: snap.transactionFeeUSD,
            netContributionBTC: snap.netContributionBTC,
            withdrawalEUR: snap.withdrawalEUR,
            withdrawalUSD: snap.withdrawalUSD
        )
        monthlyResults.append(monthData)
    }

    return monthlyResults
}

/// A helper that does the full weekly logic over totalWeeklySteps.
/// This is the same approach you'd normally do for weekly simulation:
/// lumpsum once a year (check step % 52 == 0), random draws each week, etc.
private func runWeeklySimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeklySteps: Int,
    initialBTCPriceUSD: Double
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

    let periodVol = (annualVolatility / 100.0) / sqrt(52.0)   // always treat as weekly
    let periodSD  = (parsedSD        / 100.0) / sqrt(52.0)    // always treat as weekly

    let cagrDecimal = annualCAGR / 100.0

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

    // Weekly results array
    var weeklyResults: [SimulationData] = []
    weeklyResults.append(
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

    for currentWeek in 2...totalWeeklySteps {
        let useHist = settings.useHistoricalSampling
        let useLog  = settings.useLognormalGrowth
        let lumpsum = (!useHist && !useLog)

        if lumpsum {
            // Lumpsum approach => once per year => if currentWeek % 52 == 0
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                // Add vol shocks if on
                if settings.useVolShocks && annualVolatility > 0.0 {
                    let shockVol: Double
                    if useSeededRandom, var localRNG = seededGen {
                        shockVol = seededRandomNormal(mean: 0, stdDev: periodVol, rng: &localRNG)
                        seededGen = localRNG
                    } else {
                        shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                    }
                    
                    var shockSD: Double = 0
                    if periodSD > 0 {
                        if useSeededRandom, var rng = seededGen {
                            shockSD = seededRandomNormal(mean: 0, stdDev: periodSD, rng: &rng)
                            seededGen = rng
                        } else {
                            shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                        }
                        shockSD = max(min(shockSD, 2.0), -1.0)
                    }

                    let combinedShocks = exp(shockVol + shockSD)
                    lumpsumGrowth = (1.0 + lumpsumGrowth) * combinedShocks - 1.0
                }
                
                lumpsumGrowth = applyFactorToggles(baseReturn: lumpsumGrowth, week: currentWeek, settings: settings)
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                previousBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }

        } else {
            // "Random draws" approach => user toggled historical or lognormal
            var totalReturn = 0.0
            
            // If historical is on => pick random from historical array
            if useHist {
                totalReturn += pickRandomReturn(from: historicalBTCWeeklyReturns)
            }
            
            // If lognormal is on => add weekly drift
            // (We treat log drift as cagrDecimal/52 for weekly)
            if useLog {
                totalReturn += (cagrDecimal / 52.0)
            }
            
            // If vol shocks on => add shockVol + shockSD
            if settings.useVolShocks {
                let shockVol: Double
                if useSeededRandom, var localRNG = seededGen {
                    shockVol = seededRandomNormal(mean: 0, stdDev: periodVol, rng: &localRNG)
                    seededGen = localRNG
                } else {
                    shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                }
                totalReturn += shockVol

                if periodSD > 0 {
                    var shockSD: Double
                    if useSeededRandom, var rng = seededGen {
                        shockSD = seededRandomNormal(mean: 0, stdDev: periodSD, rng: &rng)
                        seededGen = rng
                    } else {
                        shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                    }
                    shockSD = max(min(shockSD, 2.0), -1.0)
                    totalReturn += shockSD
                }
            }

            totalReturn = applyFactorToggles(baseReturn: totalReturn, week: currentWeek, settings: settings)
            
            // Original code had 0.46 as a "shrink factor" for the random draws
            let baseShrinkFactor = 0.46
            totalReturn *= baseShrinkFactor
            
            previousBTCPriceUSD *= exp(totalReturn)
        }

        // Don’t let price go below $1
        previousBTCPriceUSD = max(1.0, previousBTCPriceUSD)
        let currentBTCPriceEUR = previousBTCPriceUSD / exchangeRateEURUSD

        // “First year” means weeks <= 52
        let isFirstYear = Double(currentWeek) <= 52.0
        
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

        // Currency preference
        var typedContribUSD: Double = 0.0
        var typedContribEUR: Double = 0.0
        var netBTC             = 0.0
        var feeUSD: Double     = 0.0
        var feeEUR: Double     = 0.0

        switch settings.currencyPreference {
        case .usd:
            typedContribUSD = typedContrib
            feeUSD = typedContribUSD * 0.006
            let netUSD = typedContribUSD - feeUSD
            netBTC = netUSD / previousBTCPriceUSD

        case .eur:
            typedContribEUR = typedContrib
            feeEUR = typedContribEUR * 0.006
            let netEUR = typedContribEUR - feeEUR
            netBTC = netEUR / currentBTCPriceEUR

        case .both:
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

        // Check thresholds
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
        
        // Net contribution
        let netContribUSD = typedContribUSD - feeUSD
        let netContribEUR = typedContribEUR - feeEUR

        // Append simulation data
        weeklyResults.append(
            SimulationData(
                week: currentWeek,
                startingBTC: previousBTCHoldings,
                netBTCHoldings: finalHoldings,
                btcPriceUSD: Decimal(previousBTCPriceUSD),
                btcPriceEUR: Decimal(currentBTCPriceEUR),
                portfolioValueEUR: Decimal(portfolioEUR),
                portfolioValueUSD: Decimal(portfolioUSD),
                
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

    return weeklyResults
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

/// The main multi-run function, but behind the scenes we do "weeks" even if the user wants months.
func runMonteCarloSimulationsWithProgress(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,              // Might be 1040 if weeks, or 240 if months
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
        
        Thread.sleep(forTimeInterval: 0.01) // just to simulate some processing time
        
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
    
    // Sort runs by final portfolio value
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    finalValues.sort { $0.0 < $1.0 }
    
    // The median run
    let medianRun = finalValues[finalValues.count / 2].1
    
    print("// DEBUG: loop ended => built \(allRuns.count) runs. Returning median & allRuns.")
    return (medianRun, allRuns)
}

/// Basic normal distribution generator (unseeded)
private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
