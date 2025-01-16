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

func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,          // If .weeks => e.g. 1040, if .months => e.g. 240
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    // (1) If .months => convert months → approximate # of weeks behind the scenes
    var totalSteps = userWeeks
    if settings.periodUnit == .months {
        // e.g. 240 months => ~ 240 * 4.333 => 1040
        let approx = Double(userWeeks) * weeksPerMonthApprox
        totalSteps = Int(round(approx))
    }
    
    // (2) Just call our runWeeklySimulation with lumpsum or random draws
    // plus the monthly “accumulator” approach if .months is chosen.
    let finalData = runWeeklySimulation(
        settings: settings,
        annualCAGR: annualCAGR,
        annualVolatility: annualVolatility,
        exchangeRateEURUSD: exchangeRateEURUSD,
        totalWeeklySteps: totalSteps,
        initialBTCPriceUSD: initialBTCPriceUSD
    )
    
    // (3) Because the function below returns:
    //     - weekly array if .weeks
    //     - monthly array if .months
    // we can just return finalData with no further resample.
    return finalData
}

/// This function does the actual “weekly” loop. But if `periodUnit == .months`,
/// we deposit once per month (via an accumulator) and store each deposit
/// iteration in `monthlyResults`. Then we only return monthlyResults in that scenario.
/// If `.weeks`, we deposit every iteration and return the full array of weekly results.
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
        settings.printAllSettings()  // e.g. toggles for halving, etc.
        PrintOnce.didPrintFactorSettings = true
    }

    // Get user-specified or default standard deviation
    let parsedSD: Double
    if let sdStr = settings.inputManager?.standardDeviation, let val = Double(sdStr) {
        parsedSD = val
    } else {
        parsedSD = 15.0
    }

    if !PrintOnce.didPrintStandardDeviation {
        print("User-input standard deviation (once): \(parsedSD)")
        PrintOnce.didPrintStandardDeviation = true
    }

    let periodVol = (annualVolatility / 100.0) / sqrt(52.0)
    let periodSD  = (parsedSD        / 100.0) / sqrt(52.0)
    let cagrDecimal = annualCAGR / 100.0
    
    // Convert USD price to EUR
    let firstEURPrice = initialBTCPriceUSD / exchangeRateEURUSD

    // Convert user’s starting balance to BTC
    let userStartingBTC: Double
    switch settings.currencyPreference {
    case .usd:
        userStartingBTC = settings.startingBalance / initialBTCPriceUSD
    case .eur, .both:
        userStartingBTC = settings.startingBalance / firstEURPrice
    }
    
    var prevBTCHoldings   = userStartingBTC
    var prevBTCPriceUSD   = initialBTCPriceUSD
    let initialPortEUR    = userStartingBTC * firstEURPrice
    let initialPortUSD    = userStartingBTC * initialBTCPriceUSD

    // We'll track “monthly” with an accumulator if .months is chosen
    var monthAccumulator = 0.0

    // For full “weekly” results
    var weeklyResults = [SimulationData]()
    // For “monthly” results if .months
    var monthlyResults = [SimulationData]()

    // seed data at week=1
    weeklyResults.append(
        SimulationData(
            week: 1,
            startingBTC: 0.0,
            netBTCHoldings: userStartingBTC,
            btcPriceUSD: Decimal(initialBTCPriceUSD),
            btcPriceEUR: Decimal(firstEURPrice),
            portfolioValueEUR: Decimal(initialPortEUR),
            portfolioValueUSD: Decimal(initialPortUSD),
            contributionEUR: 0.0,
            contributionUSD: 0.0,
            transactionFeeEUR: 0.0,
            transactionFeeUSD: 0.0,
            netContributionBTC: 0.0,
            withdrawalEUR: 0.0,
            withdrawalUSD: 0.0
        )
    )

    // Gather user’s typed input for contributions
    let firstYearVal  = (settings.inputManager?.firstYearContribution   as NSString?)?.doubleValue ?? 0.0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0.0

    // Main weekly loop
    for currentWeek in 2...totalWeeklySteps {
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)

        // 1) Price update
        if lumpsum {
            // once per year => if currentWeek % 52 == 0
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    // shockVol
                    let shockVol: Double
                    if useSeededRandom, var rng = seededGen {
                        shockVol = seededRandomNormal(mean: 0, stdDev: periodVol, rng: &rng)
                        seededGen = rng
                    } else {
                        shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                    }
                    var shockSD: Double = 0
                    if periodSD > 0 {
                        if useSeededRandom, var rng2 = seededGen {
                            shockSD = seededRandomNormal(mean: 0, stdDev: periodSD, rng: &rng2)
                            seededGen = rng2
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
                prevBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }
        } else {
            // "random draws" => historical or lognormal
            var totalReturn = 0.0
            if settings.useHistoricalSampling {
                totalReturn += pickRandomReturn(from: historicalBTCWeeklyReturns)
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            if settings.useVolShocks {
                let shockVol: Double
                if useSeededRandom, var rng = seededGen {
                    shockVol = seededRandomNormal(mean: 0, stdDev: periodVol, rng: &rng)
                    seededGen = rng
                } else {
                    shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                }
                totalReturn += shockVol

                if periodSD > 0 {
                    var shockSD: Double
                    if useSeededRandom, var rng2 = seededGen {
                        shockSD = seededRandomNormal(mean: 0, stdDev: periodSD, rng: &rng2)
                        seededGen = rng2
                    } else {
                        shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                    }
                    shockSD = max(min(shockSD, 2.0), -1.0)
                    totalReturn += shockSD
                }
            }
            totalReturn = applyFactorToggles(baseReturn: totalReturn, week: currentWeek, settings: settings)
            // Original shrink factor
            totalReturn *= 0.46
            prevBTCPriceUSD *= exp(totalReturn)
        }

        // don't let price < $1
        prevBTCPriceUSD = max(1.0, prevBTCPriceUSD)
        let currentBTCPriceEUR = prevBTCPriceUSD / exchangeRateEURUSD

        // 2) Contribution logic
        var typedContrib = 0.0
        let isFirstYear = Double(currentWeek) <= 52.0

        if settings.periodUnit == .weeks {
            // deposit each iteration
            typedContrib = isFirstYear ? firstYearVal : secondYearVal

        } else {
            // .months => aggregator approach
            monthAccumulator += (1.0 / weeksPerMonthApprox)

            if monthAccumulator >= 1.0 {
                typedContrib = isFirstYear ? firstYearVal : secondYearVal
                monthAccumulator -= 1.0
            }
        }

        // Convert typedContrib => BTC
        var typedContribUSD = 0.0
        var typedContribEUR = 0.0
        var feeUSD = 0.0
        var feeEUR = 0.0
        var netBTC = 0.0

        switch settings.currencyPreference {
        case .usd:
            typedContribUSD = typedContrib
            feeUSD = typedContribUSD * 0.006
            let netUSD = typedContribUSD - feeUSD
            netBTC = netUSD / prevBTCPriceUSD

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
                netBTC = netUSD / prevBTCPriceUSD
            }
        }

        // 3) Withdrawals
        let hypotheticalHoldings = prevBTCHoldings + netBTC
        let hypotheticalValueEUR  = hypotheticalHoldings * currentBTCPriceEUR
        var withdrawalEUR = 0.0

        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0.0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0.0
        }

        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

        // 4) Final portfolio
        let portfolioEUR = finalHoldings * currentBTCPriceEUR
        let portfolioUSD = finalHoldings * prevBTCPriceUSD

        let netContribUSD = typedContribUSD - feeUSD
        let netContribEUR = typedContribEUR - feeEUR

        // Build the record for this iteration
        let thisWeekData = SimulationData(
            week: currentWeek,
            startingBTC:  prevBTCHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(prevBTCPriceUSD),
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
        
        // Store in weekly array
        weeklyResults.append(thisWeekData)

        // If .months is chosen AND we just triggered a deposit => store monthly snapshot
        if settings.periodUnit == .months, typedContrib > 0 {
            print("// DEBUG => capturing monthly snapshot at week=\(currentWeek), portfolio=\(portfolioUSD)")
            monthlyResults.append(thisWeekData)
        }

        // update BTC holdings for next iteration
        prevBTCHoldings = finalHoldings
    }

    // Finally:
    // If the user picked .weeks, return the full weekly array.
    // If .months, return the monthly snapshot array.
    // => So you only see lines that actually had a deposit.
    if settings.periodUnit == .weeks {
        return weeklyResults
    } else {
        // This ensures your UI sees exactly those points
        // where a monthly deposit occurred, avoiding "partial months".
        return monthlyResults
    }
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
