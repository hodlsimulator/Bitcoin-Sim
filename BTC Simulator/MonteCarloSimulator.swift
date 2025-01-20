//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI

extension Double {
    func withThousandsSeparator(decimalPlaces: Int = 8) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

// ──────────────────────────────────────────────────────────────────────────
// Global arrays for weekly/monthly historical returns
// ──────────────────────────────────────────────────────────────────────────
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []
var weightedBTCWeeklyReturns: [Double] = []

var historicalBTCMonthlyReturns: [Double] = []
var sp500MonthlyReturns: [Double] = []

// ──────────────────────────────────────────────────────────────────────────
// Probability thresholds & intervals
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
// Random seed & normal distributions
// ──────────────────────────────────────────────────────────────────────────
private var useSeededRandom = false
private var seededGen: SeededGenerator?

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        self.state = seed
    }
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

private func randomNormal(mean: Double, standardDeviation: Double) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}

// ──────────────────────────────────────────────────────────────────────────
// Dampening outliers
// ──────────────────────────────────────────────────────────────────────────
func dampenArctanWeekly(_ rawReturn: Double) -> Double {
    let factor = 0.6
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened * 0.5
}

func dampenArctanMonthly(_ rawReturn: Double) -> Double {
    let factor = 0.65
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened * 0.5
}

// ──────────────────────────────────────────────────────────────────────────
// lumpsumAdjustFactor, deposit calculations, toggles, etc.
// ──────────────────────────────────────────────────────────────────────────
private func lumpsumAdjustFactor(
    settings: SimulationSettings,
    annualVolatility: Double
) -> Double {
    var factor = 1.0
    var toggles = 0
    
    if annualVolatility > 5.0 {
        toggles += Int((annualVolatility - 5.0) / 5.0) + 1
    }
    if settings.useVolShocks {
        toggles += 1
    }
    
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
    
    let maxCutPerToggle = 0.02
    let totalCut = Double(toggles) * maxCutPerToggle
    factor -= totalCut
    
    factor = max(factor, 0.80)
    return factor
}

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
        return (0, 0, 0, 0, 0)
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

private func applyFactorToggles(
    baseReturn: Double,
    week: Int,
    settings: SimulationSettings,
    halvingWeeks: [Int],
    blackSwanWeeks: [Int]
) -> Double {
    var r = baseReturn
    let isWeekly = (settings.periodUnit == .weeks)
    
    // Bullish toggles
    if settings.useHalving {
        if isWeekly && settings.useHalvingWeekly && halvingWeeks.contains(week) {
            r += settings.halvingBumpWeekly
        } else if !isWeekly && settings.useHalvingMonthly && halvingWeeks.contains(week) {
            r += settings.halvingBumpMonthly
        }
    }
    if settings.useInstitutionalDemand {
        if isWeekly && settings.useInstitutionalDemandWeekly {
            r += settings.maxDemandBoostWeekly
        } else if !isWeekly && settings.useInstitutionalDemandMonthly {
            r += settings.maxDemandBoostMonthly
        }
    }
    if settings.useCountryAdoption {
        if isWeekly && settings.useCountryAdoptionWeekly {
            r += settings.maxCountryAdBoostWeekly
        } else if !isWeekly && settings.useCountryAdoptionMonthly {
            r += settings.maxCountryAdBoostMonthly
        }
    }
    if settings.useRegulatoryClarity {
        if isWeekly && settings.useRegulatoryClarityWeekly {
            r += settings.maxClarityBoostWeekly
        } else if !isWeekly && settings.useRegulatoryClarityMonthly {
            r += settings.maxClarityBoostMonthly
        }
    }
    if settings.useEtfApproval {
        if isWeekly && settings.useEtfApprovalWeekly {
            r += settings.maxEtfBoostWeekly
        } else if !isWeekly && settings.useEtfApprovalMonthly {
            r += settings.maxEtfBoostMonthly
        }
    }
    if settings.useTechBreakthrough {
        if isWeekly && settings.useTechBreakthroughWeekly {
            r += settings.maxTechBoostWeekly
        } else if !isWeekly && settings.useTechBreakthroughMonthly {
            r += settings.maxTechBoostMonthly
        }
    }
    if settings.useScarcityEvents {
        if isWeekly && settings.useScarcityEventsWeekly {
            r += settings.maxScarcityBoostWeekly
        } else if !isWeekly && settings.useScarcityEventsMonthly {
            r += settings.maxScarcityBoostMonthly
        }
    }
    if settings.useGlobalMacroHedge {
        if isWeekly && settings.useGlobalMacroHedgeWeekly {
            r += settings.maxMacroBoostWeekly
        } else if !isWeekly && settings.useGlobalMacroHedgeMonthly {
            r += settings.maxMacroBoostMonthly
        }
    }
    if settings.useStablecoinShift {
        if isWeekly && settings.useStablecoinShiftWeekly {
            r += settings.maxStablecoinBoostWeekly
        } else if !isWeekly && settings.useStablecoinShiftMonthly {
            r += settings.maxStablecoinBoostMonthly
        }
    }
    if settings.useDemographicAdoption {
        if isWeekly && settings.useDemographicAdoptionWeekly {
            r += settings.maxDemoBoostWeekly
        } else if !isWeekly && settings.useDemographicAdoptionMonthly {
            r += settings.maxDemoBoostMonthly
        }
    }
    if settings.useAltcoinFlight {
        if isWeekly && settings.useAltcoinFlightWeekly {
            r += settings.maxAltcoinBoostWeekly
        } else if !isWeekly && settings.useAltcoinFlightMonthly {
            r += settings.maxAltcoinBoostMonthly
        }
    }
    if settings.useAdoptionFactor {
        if isWeekly && settings.useAdoptionFactorWeekly {
            r += settings.adoptionBaseFactorWeekly
        } else if !isWeekly && settings.useAdoptionFactorMonthly {
            r += settings.adoptionBaseFactorMonthly
        }
    }

    // Bearish toggles
    if settings.useRegClampdown {
        if isWeekly && settings.useRegClampdownWeekly {
            r += settings.maxClampDownWeekly
        } else if !isWeekly && settings.useRegClampdownMonthly {
            r += settings.maxClampDownMonthly
        }
    }
    if settings.useCompetitorCoin {
        if isWeekly && settings.useCompetitorCoinWeekly {
            r += settings.maxCompetitorBoostWeekly
        } else if !isWeekly && settings.useCompetitorCoinMonthly {
            r += settings.maxCompetitorBoostMonthly
        }
    }
    if settings.useSecurityBreach {
        if isWeekly && settings.useSecurityBreachWeekly {
            r += settings.breachImpactWeekly
        } else if !isWeekly && settings.useSecurityBreachMonthly {
            r += settings.breachImpactMonthly
        }
    }
    if settings.useBubblePop {
        if isWeekly && settings.useBubblePopWeekly {
            r += settings.maxPopDropWeekly
        } else if !isWeekly && settings.useBubblePopMonthly {
            r += settings.maxPopDropMonthly
        }
    }
    if settings.useStablecoinMeltdown {
        if isWeekly && settings.useStablecoinMeltdownWeekly {
            r += settings.maxMeltdownDropWeekly
        } else if !isWeekly && settings.useStablecoinMeltdownMonthly {
            r += settings.maxMeltdownDropMonthly
        }
    }
    if settings.useBlackSwan {
        if isWeekly && settings.useBlackSwanWeekly && blackSwanWeeks.contains(week) {
            r += settings.blackSwanDropWeekly
        } else if !isWeekly && settings.useBlackSwanMonthly && blackSwanWeeks.contains(week) {
            r += settings.blackSwanDropMonthly
        }
    }
    if settings.useBearMarket {
        if isWeekly && settings.useBearMarketWeekly {
            r += settings.bearWeeklyDriftWeekly
        } else if !isWeekly && settings.useBearMarketMonthly {
            r += settings.bearWeeklyDriftMonthly
        }
    }
    if settings.useMaturingMarket {
        if isWeekly && settings.useMaturingMarketWeekly {
            r += settings.maxMaturingDropWeekly
        } else if !isWeekly && settings.useMaturingMarketMonthly {
            r += settings.maxMaturingDropMonthly
        }
    }
    if settings.useRecession {
        if isWeekly && settings.useRecessionWeekly {
            r += settings.maxRecessionDropWeekly
        } else if !isWeekly && settings.useRecessionMonthly {
            r += settings.maxRecessionDropMonthly
        }
    }
    
    return r
}

// MARK: - WEEKLY SIM
private func runWeeklySimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeklySteps: Int,
    initialBTCPriceUSD: Double,
    halvingWeeks: [Int],
    blackSwanWeeks: [Int],
    iterationIndex: Int,
    verboseLog: Bool = false
) -> [SimulationData] {
    
    var results = [SimulationData]()
    
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    let cagrDecimal = annualCAGR / 100.0
    let periodVol   = (annualVolatility / 100.0) / sqrt(52.0)

    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0

    for currentWeek in 1...totalWeeklySteps {
        
        let oldPriceUSD = prevBTCPriceUSD
        let oldHoldings = prevBTCHoldings
        
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        if lumpsum {
            // Only apply lumpsum approach once per year (every 52 weeks)
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
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
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
            }
        } else {
            // For historical sampling or lognormal approach
            if settings.useHistoricalSampling {
                var weeklySample = pickRandomReturn(from: historicalBTCWeeklyReturns)
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                totalReturn += shockVol
            }
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                week: currentWeek,
                settings: settings,
                halvingWeeks: halvingWeeks,
                blackSwanWeeks: blackSwanWeeks
            )
            prevBTCPriceUSD *= exp(toggled)
        }
        
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Contribution logic
        var typedDeposit = 0.0
        if currentWeek == 1 {
            typedDeposit = settings.startingBalance
        } else if currentWeek <= 52 {
            typedDeposit = firstYearVal
        } else {
            typedDeposit = secondYearVal
        }
        
        let (feeEUR, feeUSD, cEur, cUsd, depositBTC) = computeNetDeposit(
            typedDeposit: typedDeposit,
            settings: settings,
            btcPriceUSD: newPriceUSD,
            btcPriceEUR: newPriceEUR
        )
        let holdingsAfterDeposit = oldHoldings + depositBTC
        
        // Check thresholds for withdrawals
        let hypotheticalValueEUR = holdingsAfterDeposit * newPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0
        }
        let withdrawalBTC = withdrawalEUR / newPriceEUR
        let finalHoldings = max(0.0, holdingsAfterDeposit - withdrawalBTC)
        
        let portfolioValueEUR = finalHoldings * newPriceEUR
        let portfolioValueUSD = finalHoldings * newPriceUSD
        
        let dataPoint = SimulationData(
            week: currentWeek,
            startingBTC: oldHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(newPriceUSD),
            btcPriceEUR: Decimal(newPriceEUR),
            portfolioValueEUR: Decimal(portfolioValueEUR),
            portfolioValueUSD: Decimal(portfolioValueUSD),
            contributionEUR: cEur,
            contributionUSD: cUsd,
            transactionFeeEUR: feeEUR,
            transactionFeeUSD: feeUSD,
            netContributionBTC: depositBTC,
            withdrawalEUR: withdrawalEUR,
            withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
        )
        results.append(dataPoint)
        
        prevBTCHoldings = finalHoldings
    }
    
    return results
}

// MARK: - MONTHLY SIM
private func runMonthlySimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalMonths: Int,
    initialBTCPriceUSD: Double,
    halvingMonths: [Int],
    blackSwanMonths: [Int],
    iterationIndex: Int,
    verboseLog: Bool = false // NEW CODE
) -> [SimulationData] {

    var results = [SimulationData]()
    
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    // Convert annual CAGR into a monthly fraction
    let cagrDecimal = annualCAGR / 100.0
    let periodVol   = (annualVolatility / 100.0) / sqrt(12.0)

    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0

    // OPTIONAL: A quick log line before we start
    if verboseLog {
        print("// VERBOSE: runMonthlySimulation => iteration=\(iterationIndex), totalMonths=\(totalMonths), initialBTC=\(prevBTCPriceUSD)")
    }

    for currentMonth in 1...totalMonths {
        
        let oldPriceUSD = prevBTCPriceUSD
        let oldHoldings = prevBTCHoldings
        
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        // ──────────────────────────────────────────────────────────
        // 1) Determine the final BTC price for this month, after toggles
        // ──────────────────────────────────────────────────────────
        if lumpsum {
            // Lumpsum approach once per year => every 12 months
            if Double(currentMonth).truncatingRemainder(dividingBy: 12.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    week: currentMonth,
                    settings: settings,
                    halvingWeeks: halvingMonths, // reusing param name
                    blackSwanWeeks: blackSwanMonths
                )
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
            }
        } else {
            // Historical sampling or lognormal approach
            if settings.useHistoricalSampling {
                var monthlySample = pickRandomReturn(from: historicalBTCMonthlyReturns)
                monthlySample = dampenArctanMonthly(monthlySample)
                totalReturn += monthlySample
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 12.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormal(mean: 0, standardDeviation: periodVol)
                totalReturn += shockVol
            }
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                week: currentMonth,
                settings: settings,
                halvingWeeks: halvingMonths,
                blackSwanWeeks: blackSwanMonths
            )
            prevBTCPriceUSD *= exp(toggled)
        }
        
        // Price floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // ──────────────────────────────────────────────────────────
        // 2) Now that we have the new final monthly BTC price, do the deposit
        // ──────────────────────────────────────────────────────────
        var typedDeposit = 0.0
        if currentMonth == 1 {
            typedDeposit = settings.startingBalance
        } else if currentMonth <= 12 {
            typedDeposit = firstYearVal
        } else {
            typedDeposit = secondYearVal
        }
        
        let (feeEUR, feeUSD, cEur, cUsd, depositBTC) = computeNetDeposit(
            typedDeposit: typedDeposit,
            settings: settings,
            btcPriceUSD: newPriceUSD,
            btcPriceEUR: newPriceEUR
        )
        let holdingsAfterDeposit = oldHoldings + depositBTC
        
        // ──────────────────────────────────────────────────────────
        // 3) Handle threshold-based withdrawals
        // ──────────────────────────────────────────────────────────
        let hypotheticalValueEUR = holdingsAfterDeposit * newPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > (settings.inputManager?.threshold2 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount2 ?? 0
        } else if hypotheticalValueEUR > (settings.inputManager?.threshold1 ?? 0) {
            withdrawalEUR = settings.inputManager?.withdrawAmount1 ?? 0
        }
        let withdrawalBTC = withdrawalEUR / newPriceEUR
        let finalHoldings = max(0.0, holdingsAfterDeposit - withdrawalBTC)
        
        let portfolioValueEUR = finalHoldings * newPriceEUR
        let portfolioValueUSD = finalHoldings * newPriceUSD

        // ──────────────────────────────────────────────────────────
        // 4) Verbose logging
        // ──────────────────────────────────────────────────────────
        if verboseLog {
            let oldPortfolioUSD = oldHoldings * oldPriceUSD
            let depositInUSD    = (cUsd > 0.0 ? cUsd : 0.0)
            let portfolioChange = portfolioValueUSD - oldPortfolioUSD
            
            print("""
            // [Iter=\(iterationIndex) Month=\(currentMonth)]
            //   oldBTC=\(oldPriceUSD), newBTC=\(newPriceUSD)
            //   oldHoldings=\(oldHoldings), finalHoldings=\(finalHoldings)
            //   typedDeposit=\(typedDeposit), depositBTC=\(depositBTC),
            //   depositUSD=\(depositInUSD), feeUSD=\(feeUSD)
            //   withdrawalUSD=\(withdrawalEUR / exchangeRateEURUSD)
            //   oldPortUSD=\(oldPortfolioUSD), newPortUSD=\(portfolioValueUSD)
            //   portChange=\(portfolioChange)
            """)
        }

        // ──────────────────────────────────────────────────────────
        // 5) Build SimulationData for this month
        // ──────────────────────────────────────────────────────────
        let dataPoint = SimulationData(
            week: currentMonth, // reusing 'week' to store month index
            startingBTC: oldHoldings,
            netBTCHoldings: finalHoldings,
            btcPriceUSD: Decimal(newPriceUSD),
            btcPriceEUR: Decimal(newPriceEUR),
            portfolioValueEUR: Decimal(portfolioValueEUR),
            portfolioValueUSD: Decimal(portfolioValueUSD),
            contributionEUR: cEur,
            contributionUSD: cUsd,
            transactionFeeEUR: feeEUR,
            transactionFeeUSD: feeUSD,
            netContributionBTC: depositBTC,
            withdrawalEUR: withdrawalEUR,
            withdrawalUSD: withdrawalEUR / exchangeRateEURUSD
        )
        results.append(dataPoint)
        
        // 6) Move on to the next iteration
        prevBTCHoldings = finalHoldings
    }
    
    return results
}

// Main runner for a single simulation
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int = 0,
    seed: UInt64? = nil,
    verboseLog: Bool = false // NEW CODE
) -> [SimulationData] {

    if settings.periodUnit == .months {
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
            blackSwanMonths: randomBlackSwanMonths,
            iterationIndex: iterationIndex,
            verboseLog: verboseLog // NEW CODE
        )
    } else {
        let totalWeeks = userWeeks
        let randomHalvingWeeks = generateRandomEventWeeks(
            totalWeeks: totalWeeks,
            intervalGuess: halvingIntervalGuess
        )
        let randomBlackSwanWeeks = generateRandomEventWeeks(
            totalWeeks: totalWeeks,
            intervalGuess: blackSwanIntervalGuess
        )
        
        return runWeeklySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeklySteps: totalWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            halvingWeeks: randomHalvingWeeks,
            blackSwanWeeks: randomBlackSwanWeeks,
            iterationIndex: iterationIndex,
            verboseLog: verboseLog // NEW CODE
        )
    }
}

// NEW CODE: Helper to compute median BTC price at each step across all runs.
fileprivate func computeMedianBTCPriceByStep(allRuns: [[SimulationData]]) -> [Decimal] {
    // If no runs, or no data, return empty
    guard let steps = allRuns.first?.count, steps > 0 else { return [] }
    
    var medians = [Decimal](repeating: 0, count: steps)
    
    for stepIndex in 0..<steps {
        // Gather the BTC price from each run at this stepIndex
        let pricesAtStep = allRuns.compactMap { run -> Decimal? in
            // If a run didn't have that many steps, safely check
            guard run.indices.contains(stepIndex) else { return nil }
            return run[stepIndex].btcPriceUSD
        }
        
        guard !pricesAtStep.isEmpty else {
            medians[stepIndex] = 0
            continue
        }
        
        let sorted = pricesAtStep.sorted()
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            // even number => average the middle two
            let p1 = sorted[mid - 1]
            let p2 = sorted[mid]
            medians[stepIndex] = (p1 + p2) / 2
        } else {
            medians[stepIndex] = sorted[mid]
        }
    }
    return medians
}

// Runs multiple simulations with progress callback
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
) -> (
    medianRun: [SimulationData],
    allRuns: [[SimulationData]],
    stepMedianPrices: [Decimal] // The new median BTC price per step
) {
    
    setRandomSeed(seed)
    var allRuns = [[SimulationData]]()

    for i in 0..<iterations {
        if isCancelled() {
            break
        }
        
        // optional small delay
        Thread.sleep(forTimeInterval: 0.01)

        let simRun = runOneFullSimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: userWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: i+1,
            verboseLog: true
        )
        allRuns.append(simRun)
        
        if isCancelled() {
            break
        }
        progressCallback(i + 1)
    }
    
    if allRuns.isEmpty {
        // Return empty everything
        return ([], [], [])
    }
    
    // Pick "median" run by final portfolioValueEUR
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    
    // For each step, compute the median BTC price across all runs
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)

    return (medianRun, allRuns, stepMedians)
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
