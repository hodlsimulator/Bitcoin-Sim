//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI

// A helper extension to format numbers with commas.
extension Double {
    func withThousandsSeparator(decimalPlaces: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// ──────────────────────────────────────────────────────────────────────────
// 1) Global variables for weekly & monthly historical returns
// ──────────────────────────────────────────────────────────────────────────
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

var historicalBTCMonthlyReturns: [Double] = []
var sp500MonthlyReturns: [Double] = []

// ──────────────────────────────────────────────────────────────────────────
// 2) Probability thresholds for weekly vs. monthly events
// ──────────────────────────────────────────────────────────────────────────
private let halvingIntervalGuess = 210.0
private let blackSwanIntervalGuess = 400.0

private let halvingIntervalGuessMonths: Double = 48.0
private let blackSwanIntervalGuessMonths: Double = 92.0

func generateRandomEventWeeks(totalWeeks: Int, intervalGuess: Double) -> [Int] {
    let expectedCount = Double(totalWeeks) / intervalGuess
    let eventCount = Int(round(expectedCount))
    var eventWeeks: [Int] = []
    for _ in 0..<eventCount {
        let randomWeek = Int.random(in: 1...totalWeeks)
        eventWeeks.append(randomWeek)
    }
    return eventWeeks.sorted()
}

func generateRandomEventMonths(totalMonths: Int, intervalGuess: Double) -> [Int] {
    let expectedCount = Double(totalMonths) / intervalGuess
    let eventCount = Int(round(expectedCount))
    
    var eventMonths: [Int] = []
    for _ in 0..<eventCount {
        let randomMonth = Int.random(in: 1...totalMonths)
        eventMonths.append(randomMonth)
    }
    return eventMonths.sorted()
}

// ──────────────────────────────────────────────────────────────────────────
// 3) Random seed & normal distributions
// ──────────────────────────────────────────────────────────────────────────
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

/// Basic normal distribution generator (unseeded)
private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}

// ──────────────────────────────────────────────────────────────────────────
// 4) Dampening outliers function
// ──────────────────────────────────────────────────────────────────────────
func dampenArctanWeekly(_ rawReturn: Double) -> Double {
    // Maybe we want stronger dampening for weekly
    let factor = 0.6
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened * 0.5
}

func dampenArctanMonthly(_ rawReturn: Double) -> Double {
    // Maybe we want a mild dampening for monthly
    let factor = 0.8    
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened * 0.5
}

// ──────────────────────────────────────────────────────────────────────────
// 5) Lumpsum adjust factor, net deposit, factor toggles, etc.
// ──────────────────────────────────────────────────────────────────────────

private func lumpsumAdjustFactor(
    settings: SimulationSettings,
    annualVolatility: Double
) -> Double {
    var factor = 1.0
    var toggles = 0
    
    // (1) Increment for volatility if > 5
    if annualVolatility > 5.0 {
        toggles += Int((annualVolatility - 5.0) / 5.0) + 1
    }
    // (2) If volShocks is on
    if settings.useVolShocks {
        toggles += 1
    }
    // (3) If any bullish/bearish factor is on
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

/// Net Deposit calculation
private func computeNetDeposit(
    typedDeposit: Double,
    settings: SimulationSettings,
    btcPriceUSD: Double,
    btcPriceEUR: Double
) -> (
    feeEUR: Double,
    feeUSD: Double,
    netContribEUR: Double,
    netContribUSD: Double,
    netBTC: Double
) {
    if typedDeposit <= 0 {
        return (0.0, 0.0, 0.0, 0.0, 0.0)
    }
    
    switch settings.currencyPreference {
    case .usd:
        let fee = typedDeposit * 0.006
        let netUSD = typedDeposit - fee
        let netBTC = netUSD / btcPriceUSD
        return (0.0, fee, 0.0, netUSD, netBTC)
        
    case .eur:
        let fee = typedDeposit * 0.006
        let netEUR = typedDeposit - fee
        let netBTC = netEUR / btcPriceEUR
        return (fee, 0.0, netEUR, 0.0, netBTC)
        
    case .both:
        if settings.contributionCurrencyWhenBoth == .eur {
            let fee = typedDeposit * 0.006
            let netEUR = typedDeposit - fee
            let netBTC = netEUR / btcPriceEUR
            return (fee, 0.0, netEUR, 0.0, netBTC)
        } else {
            let fee = typedDeposit * 0.006
            let netUSD = typedDeposit - fee
            let netBTC = netUSD / btcPriceUSD
            return (0.0, fee, 0.0, netUSD, netBTC)
        }
    }
}

/// Applies toggles (bullish or bearish) to the baseReturn
private func applyFactorToggles(
    baseReturn: Double,
    week: Int,
    settings: SimulationSettings,
    halvingWeeks: [Int],
    blackSwanWeeks: [Int]
) -> Double {
    var r = baseReturn
    let isWeekly = (settings.periodUnit == .weeks)
    
    // Halving
    if settings.useHalving {
        // Only add halving bump if we match the current week/month
        if isWeekly && settings.useHalvingWeekly && halvingWeeks.contains(week) {
            r += settings.halvingBumpWeekly
        } else if !isWeekly && settings.useHalvingMonthly && halvingWeeks.contains(week) {
            r += settings.halvingBumpMonthly
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────────
    // BULLISH FACTORS
    // ──────────────────────────────────────────────────────────────────────────
    
    // Institutional Demand
    if settings.useInstitutionalDemand {
        if isWeekly && settings.useInstitutionalDemandWeekly {
            r += settings.maxDemandBoostWeekly
        } else if !isWeekly && settings.useInstitutionalDemandMonthly {
            r += settings.maxDemandBoostMonthly
        }
    }
    
    // Country Adoption
    if settings.useCountryAdoption {
        if isWeekly && settings.useCountryAdoptionWeekly {
            r += settings.maxCountryAdBoostWeekly
        } else if !isWeekly && settings.useCountryAdoptionMonthly {
            r += settings.maxCountryAdBoostMonthly
        }
    }
    
    // Regulatory Clarity
    if settings.useRegulatoryClarity {
        if isWeekly && settings.useRegulatoryClarityWeekly {
            r += settings.maxClarityBoostWeekly
        } else if !isWeekly && settings.useRegulatoryClarityMonthly {
            r += settings.maxClarityBoostMonthly
        }
    }
    
    // ETF Approval
    if settings.useEtfApproval {
        if isWeekly && settings.useEtfApprovalWeekly {
            r += settings.maxEtfBoostWeekly
        } else if !isWeekly && settings.useEtfApprovalMonthly {
            r += settings.maxEtfBoostMonthly
        }
    }
    
    // Tech Breakthrough
    if settings.useTechBreakthrough {
        if isWeekly && settings.useTechBreakthroughWeekly {
            r += settings.maxTechBoostWeekly
        } else if !isWeekly && settings.useTechBreakthroughMonthly {
            r += settings.maxTechBoostMonthly
        }
    }
    
    // Scarcity Events
    if settings.useScarcityEvents {
        if isWeekly && settings.useScarcityEventsWeekly {
            r += settings.maxScarcityBoostWeekly
        } else if !isWeekly && settings.useScarcityEventsMonthly {
            r += settings.maxScarcityBoostMonthly
        }
    }
    
    // Global Macro Hedge
    if settings.useGlobalMacroHedge {
        if isWeekly && settings.useGlobalMacroHedgeWeekly {
            r += settings.maxMacroBoostWeekly
        } else if !isWeekly && settings.useGlobalMacroHedgeMonthly {
            r += settings.maxMacroBoostMonthly
        }
    }
    
    // Stablecoin Shift
    if settings.useStablecoinShift {
        if isWeekly && settings.useStablecoinShiftWeekly {
            r += settings.maxStablecoinBoostWeekly
        } else if !isWeekly && settings.useStablecoinShiftMonthly {
            r += settings.maxStablecoinBoostMonthly
        }
    }
    
    // Demographic Adoption
    if settings.useDemographicAdoption {
        if isWeekly && settings.useDemographicAdoptionWeekly {
            r += settings.maxDemoBoostWeekly
        } else if !isWeekly && settings.useDemographicAdoptionMonthly {
            r += settings.maxDemoBoostMonthly
        }
    }
    
    // Altcoin Flight
    if settings.useAltcoinFlight {
        if isWeekly && settings.useAltcoinFlightWeekly {
            r += settings.maxAltcoinBoostWeekly
        } else if !isWeekly && settings.useAltcoinFlightMonthly {
            r += settings.maxAltcoinBoostMonthly
        }
    }
    
    // Adoption Factor
    if settings.useAdoptionFactor {
        if isWeekly && settings.useAdoptionFactorWeekly {
            r += settings.adoptionBaseFactorWeekly
        } else if !isWeekly && settings.useAdoptionFactorMonthly {
            r += settings.adoptionBaseFactorMonthly
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────────
    // BEARISH FACTORS
    // ──────────────────────────────────────────────────────────────────────────
    
    // Regulatory Clampdown
    if settings.useRegClampdown {
        if isWeekly && settings.useRegClampdownWeekly {
            r += settings.maxClampDownWeekly
        } else if !isWeekly && settings.useRegClampdownMonthly {
            r += settings.maxClampDownMonthly
        }
    }
    
    // Competitor Coin
    if settings.useCompetitorCoin {
        if isWeekly && settings.useCompetitorCoinWeekly {
            r += settings.maxCompetitorBoostWeekly
        } else if !isWeekly && settings.useCompetitorCoinMonthly {
            r += settings.maxCompetitorBoostMonthly
        }
    }
    
    // Security Breach
    if settings.useSecurityBreach {
        if isWeekly && settings.useSecurityBreachWeekly {
            r += settings.breachImpactWeekly
        } else if !isWeekly && settings.useSecurityBreachMonthly {
            r += settings.breachImpactMonthly
        }
    }
    
    // Bubble Pop
    if settings.useBubblePop {
        if isWeekly && settings.useBubblePopWeekly {
            r += settings.maxPopDropWeekly
        } else if !isWeekly && settings.useBubblePopMonthly {
            r += settings.maxPopDropMonthly
        }
    }
    
    // Stablecoin Meltdown
    if settings.useStablecoinMeltdown {
        if isWeekly && settings.useStablecoinMeltdownWeekly {
            r += settings.maxMeltdownDropWeekly
        } else if !isWeekly && settings.useStablecoinMeltdownMonthly {
            r += settings.maxMeltdownDropMonthly
        }
    }
    
    // Black Swan
    if settings.useBlackSwan {
        // Only trigger black swan if the random event array includes the current index
        if isWeekly && settings.useBlackSwanWeekly && blackSwanWeeks.contains(week) {
            r += settings.blackSwanDropWeekly
        } else if !isWeekly && settings.useBlackSwanMonthly && blackSwanWeeks.contains(week) {
            r += settings.blackSwanDropMonthly
        }
    }
    
    // Bear Market
    if settings.useBearMarket {
        if isWeekly && settings.useBearMarketWeekly {
            r += settings.bearWeeklyDriftWeekly
        } else if !isWeekly && settings.useBearMarketMonthly {
            r += settings.bearWeeklyDriftMonthly
        }
    }
    
    // Maturing Market
    if settings.useMaturingMarket {
        if isWeekly && settings.useMaturingMarketWeekly {
            r += settings.maxMaturingDropWeekly
        } else if !isWeekly && settings.useMaturingMarketMonthly {
            r += settings.maxMaturingDropMonthly
        }
    }
    
    // Recession
    if settings.useRecession {
        if isWeekly && settings.useRecessionWeekly {
            r += settings.maxRecessionDropWeekly
        } else if !isWeekly && settings.useRecessionMonthly {
            r += settings.maxRecessionDropMonthly
        }
    }
    
    return r
}

// ──────────────────────────────────────────────────────────────────────────
// 6) The “true monthly” simulation
// ──────────────────────────────────────────────────────────────────────────
private func runMonthlySimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalMonths: Int,
    initialBTCPriceUSD: Double,
    halvingMonths: [Int],
    blackSwanMonths: [Int]
) -> [SimulationData] {

    let cagrDecimal = annualCAGR / 100.0
    let monthlyMean = cagrDecimal / 12.0
    let monthlyVol  = (annualVolatility / 100.0) / sqrt(12.0)

    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    var monthlyResults = [SimulationData]()

    let firstYearVal  = (settings.inputManager?.firstYearContribution   as NSString?)?.doubleValue ?? 0.0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0.0

    for currentMonth in 1...totalMonths {
        // (A) Price update
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        if lumpsum {
            // If lumpsum => only “grow” once every 12 months
            if currentMonth % 12 == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormal(mean: 0, standardDeviation: monthlyVol)
                    var shockSD: Double = 0
                    if monthlyVol > 0 {
                        shockSD = randomNormal(mean: 0, standardDeviation: monthlyVol)
                        shockSD = max(min(shockSD, 2.0), -1.0)
                    }
                    let combinedShocks = exp(shockVol + shockSD)
                    lumpsumGrowth = (1.0 + lumpsumGrowth) * combinedShocks - 1.0
                }
                // Factor toggles
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    week: currentMonth,
                    settings: settings,
                    halvingWeeks: halvingMonths,
                    blackSwanWeeks: blackSwanMonths
                )
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                prevBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }
        } else {
            // Otherwise => historical monthly + lognormal + volShocks
            var totalReturn = 0.0

            if settings.useHistoricalSampling {
                // (1) pick the monthly sample
                var monthlySample = pickRandomReturn(from: historicalBTCMonthlyReturns)
                // (2) dampen it with the monthly function
                monthlySample = dampenArctanMonthly(monthlySample)
                // (3) convert from simple % to log
                totalReturn += log(1.0 + monthlySample)
            }
            if settings.useLognormalGrowth {
                totalReturn += monthlyMean
            }
            if settings.useVolShocks {
                let shockVol = randomNormal(mean: 0, standardDeviation: monthlyVol)
                totalReturn += shockVol
            }
            
            // Toggled once per month
            totalReturn = applyFactorToggles(
                baseReturn: totalReturn,
                week: currentMonth,
                settings: settings,
                halvingWeeks: halvingMonths,
                blackSwanWeeks: blackSwanMonths
            )
            
            // Normal monthly compounding
            prevBTCPriceUSD *= exp(totalReturn)
        }

        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let currentBTCPriceEUR = prevBTCPriceUSD / exchangeRateEURUSD

        // (B) Deposit once per month
        var typedDeposit = 0.0
        if currentMonth == 1 {
            typedDeposit += settings.startingBalance
        }
        if currentMonth <= 12 {
            typedDeposit += firstYearVal
        } else {
            typedDeposit += secondYearVal
        }
        
        let (feeEUR, feeUSD, nContribEUR, nContribUSD, depositBTC) =
            computeNetDeposit(
                typedDeposit: typedDeposit,
                settings: settings,
                btcPriceUSD: prevBTCPriceUSD,
                btcPriceEUR: currentBTCPriceEUR
            )
        let hypotheticalHoldings = prevBTCHoldings + depositBTC

        // (C) Withdrawals
        let hypotheticalValueEUR = hypotheticalHoldings * currentBTCPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0.0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0.0
        }
        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

        // (D) Build data row
        let portfolioEUR = finalHoldings * currentBTCPriceEUR
        let portfolioUSD = finalHoldings * prevBTCPriceUSD
        
        let thisMonthData = SimulationData(
            week: currentMonth,  // We call it 'week' but it's actually the month index
            startingBTC: prevBTCHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(prevBTCPriceUSD),
            btcPriceEUR: Decimal(currentBTCPriceEUR),
            portfolioValueEUR: Decimal(portfolioEUR),
            portfolioValueUSD: Decimal(portfolioUSD),
            contributionEUR: nContribEUR,
            contributionUSD: nContribUSD,
            transactionFeeEUR: feeEUR,
            transactionFeeUSD: feeUSD,
            netContributionBTC: depositBTC,
            withdrawalEUR: withdrawalEUR,
            withdrawalUSD: (withdrawalEUR / exchangeRateEURUSD)
        )
        monthlyResults.append(thisMonthData)

        prevBTCHoldings = finalHoldings
    }
    
    return monthlyResults
}

// ──────────────────────────────────────────────────────────────────────────
// 7) The “standard weekly” simulation
// ──────────────────────────────────────────────────────────────────────────
private func runWeeklySimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeklySteps: Int,
    initialBTCPriceUSD: Double,
    halvingWeeks: [Int],
    blackSwanWeeks: [Int]
) -> [SimulationData] {
    
    struct PrintOnce {
        static var didPrintFactorSettings: Bool = false
        static var didPrintStandardDeviation: Bool = false
    }

    // Print toggles once
    if !PrintOnce.didPrintFactorSettings {
        print("=== FACTOR SETTINGS (once only) ===")
        settings.printAllSettings()
        PrintOnce.didPrintFactorSettings = true
    }

    // Read standard deviation from user, else default
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

    let periodVol   = (annualVolatility / 100.0) / sqrt(52.0)
    let periodSD    = (parsedSD / 100.0) / sqrt(52.0)
    let cagrDecimal = annualCAGR / 100.0

    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    var weeklyResults  = [SimulationData]()

    let firstYearVal  = (settings.inputManager?.firstYearContribution   as NSString?)?.doubleValue ?? 0.0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0.0

    // Main weekly loop
    for currentWeek in 1...totalWeeklySteps {

        // 1) Price update
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        if lumpsum {
            // lumpsum => only grow once every 52 weeks
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                    var shockSD: Double = 0
                    if periodSD > 0 {
                        shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                        shockSD = max(min(shockSD, 2.0), -1.0)
                    }
                    let combinedShocks = exp(shockVol + shockSD)
                    lumpsumGrowth = (1.0 + lumpsumGrowth) * combinedShocks - 1.0
                }
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    week: currentWeek,
                    settings: settings,
                    halvingWeeks: halvingWeeks,
                    blackSwanWeeks: blackSwanWeeks
                )
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                prevBTCPriceUSD *= (1.0 + lumpsumGrowth)
            }
        } else {
            // historical + lognormal + shocks => weekly approach
            var totalReturn = 0.0
            if settings.useHistoricalSampling {
                // (1) pick a weekly sample
                var weeklySample = pickRandomReturn(from: historicalBTCWeeklyReturns)
                // (2) dampen outliers with the weekly function
                weeklySample = dampenArctanWeekly(weeklySample)
                // (3) add to totalReturn
                totalReturn += weeklySample
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                totalReturn += shockVol
                if periodSD > 0 {
                    var shockSD = randomNormal(mean: 0, standardDeviation: periodSD)
                    shockSD = max(min(shockSD, 2.0), -1.0)
                    totalReturn += shockSD
                }
            }
            // toggles
            totalReturn = applyFactorToggles(
                baseReturn: totalReturn,
                week: currentWeek,
                settings: settings,
                halvingWeeks: halvingWeeks,
                blackSwanWeeks: blackSwanWeeks
            )
            prevBTCPriceUSD *= exp(totalReturn)
        }

        // Price floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let currentBTCPriceEUR = prevBTCPriceUSD / exchangeRateEURUSD

        // 2) typedDeposit for each week
        var typedDeposit = 0.0
        if currentWeek == 1 {
            typedDeposit += settings.startingBalance
        }
        if Double(currentWeek) <= 52.0 {
            typedDeposit += firstYearVal
        } else {
            typedDeposit += secondYearVal
        }

        let (feeEUR, feeUSD, nContribEUR, nContribUSD, depositBTC) =
            computeNetDeposit(
                typedDeposit: typedDeposit,
                settings: settings,
                btcPriceUSD: prevBTCPriceUSD,
                btcPriceEUR: currentBTCPriceEUR
            )
        let hypotheticalHoldings = prevBTCHoldings + depositBTC

        // 3) Withdrawals
        let hypotheticalValueEUR = hypotheticalHoldings * currentBTCPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0.0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0.0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0.0
        }
        let withdrawalBTC = withdrawalEUR / currentBTCPriceEUR
        let finalHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)

        let portfolioEUR = finalHoldings * currentBTCPriceEUR
        let portfolioUSD = finalHoldings * prevBTCPriceUSD

        // Build weekly record
        let thisWeekData = SimulationData(
            week: currentWeek,
            startingBTC: prevBTCHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(prevBTCPriceUSD),
            btcPriceEUR: Decimal(currentBTCPriceEUR),
            portfolioValueEUR: Decimal(portfolioEUR),
            portfolioValueUSD: Decimal(portfolioUSD),
            contributionEUR: nContribEUR,
            contributionUSD: nContribUSD,
            transactionFeeEUR: feeEUR,
            transactionFeeUSD: feeUSD,
            netContributionBTC: depositBTC,
            withdrawalEUR: withdrawalEUR,
            withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
        )
        weeklyResults.append(thisWeekData)
        
        prevBTCHoldings = finalHoldings
    }

    return weeklyResults
}

// ──────────────────────────────────────────────────────────────────────────
// 8) The main function that decides monthly vs weekly
// ──────────────────────────────────────────────────────────────────────────
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    seed: UInt64? = nil
) -> [SimulationData] {
    
    if settings.periodUnit == .months {
        // userWeeks is the number of months
        let totalMonths = userWeeks
        let randomHalvingMonths = generateRandomEventMonths(
            totalMonths: totalMonths,
            intervalGuess: halvingIntervalGuessMonths
        )
        let randomBlackSwanMonths = generateRandomEventMonths(
            totalMonths: totalMonths,
            intervalGuess: blackSwanIntervalGuessMonths
        )
        
        return runMonthlySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalMonths: totalMonths,
            initialBTCPriceUSD: initialBTCPriceUSD,
            halvingMonths: randomHalvingMonths,
            blackSwanMonths: randomBlackSwanMonths
        )
    } else {
        // Weekly
        let totalSteps = userWeeks
        let randomHalvingWeeks = generateRandomEventWeeks(
            totalWeeks: totalSteps,
            intervalGuess: halvingIntervalGuess
        )
        let randomBlackSwanWeeks = generateRandomEventWeeks(
            totalWeeks: totalSteps,
            intervalGuess: blackSwanIntervalGuess
        )
        
        return runWeeklySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeklySteps: totalSteps,
            initialBTCPriceUSD: initialBTCPriceUSD,
            halvingWeeks: randomHalvingWeeks,
            blackSwanWeeks: randomBlackSwanWeeks
        )
    }
}

// ──────────────────────────────────────────────────────────────────────────
// 9) The multi-run function invoked from your coordinator
// ──────────────────────────────────────────────────────────────────────────
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
        
        Thread.sleep(forTimeInterval: 0.01) // simulate some processing time
        
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
