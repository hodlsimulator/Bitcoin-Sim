//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation
import SwiftUI
import GameplayKit // for GKARC4RandomSource

// MARK: - Utility Extension
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
// Probability thresholds & intervals (for halving or black swan events)
// ──────────────────────────────────────────────────────────────────────────
private let halvingIntervalGuess = 210.0
private let blackSwanIntervalGuess = 400.0
private let halvingIntervalGuessMonths: Double = 48.0
private let blackSwanIntervalGuessMonths: Double = 92.0

// MARK: - Unified Random Event Generators
/// Generates random event weeks based on an expected interval, using our seeded RNG.
func generateRandomEventWeeks(
    totalWeeks: Int,
    intervalGuess: Double,
    rng: GKRandomSource
) -> [Int] {
    let expectedCount = Double(totalWeeks) / intervalGuess
    let eventCount = Int(round(expectedCount))
    var eventWeeks: [Int] = []
    for _ in 0..<eventCount {
        // Use seeded RNG, not Swift’s Int.random(in:).
        let randomWeek = rng.nextInt(upperBound: totalWeeks) + 1
        eventWeeks.append(randomWeek)
    }
    return eventWeeks.sorted()
}

/// Generates random event months based on an expected interval, using seeded RNG.
func generateRandomEventMonths(
    totalMonths: Int,
    intervalGuess: Double,
    rng: GKRandomSource
) -> [Int] {
    let expectedCount = Double(totalMonths) / intervalGuess
    let eventCount = Int(round(expectedCount))
    var eventMonths: [Int] = []
    for _ in 0..<eventCount {
        let randomMonth = rng.nextInt(upperBound: totalMonths) + 1
        eventMonths.append(randomMonth)
    }
    return eventMonths.sorted()
}

// MARK: - Normal Draw with RNG
/// A standard normal draw using a seeded GKRandomSource.
private func randomNormalWithRNG(mean: Double, standardDeviation: Double, rng: GKRandomSource) -> Double {
    let u1 = Double(rng.nextUniform())
    let u2 = Double(rng.nextUniform())
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}

// MARK: - Historical Return Picker
/// Picks a random return from an array, using our seeded RNG.
fileprivate func pickRandomReturn(from arr: [Double], rng: GKRandomSource) -> Double {
    guard !arr.isEmpty else { return 0.0 }
    let idx = rng.nextInt(upperBound: arr.count)
    return arr[idx]
}

// MARK: - Dampen Outliers
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

// MARK: - Lump-sum Factor
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

// MARK: - Contribution / Deposit
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

// MARK: - Factor Toggles (Bullish/Bearish)
private func applyFactorToggles(
    baseReturn: Double,
    week: Int,
    settings: SimulationSettings,
    mempoolDataManager: MempoolDataManager,
    halvingWeeks: [Int],
    rng: GKRandomSource // needed for black swan probability
) -> Double {
    var r = baseReturn
    let isWeekly = (settings.periodUnit == .weeks)
    
    // ────────── BULLISH ──────────
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
    
    // ────────── BEARISH ──────────
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
        // Probability-based approach => seeded
        let stressLevel = mempoolDataManager.stressLevel(at: week)
        let baseProb = 0.028
        let dynamicProb = (stressLevel > 80.0) ? baseProb * 2 : baseProb
        // Instead of Double.random(in: 0...1), we do:
        let roll = Double(rng.nextUniform())
        if roll < dynamicProb {
            if isWeekly {
                r += settings.blackSwanDropWeekly
            } else {
                r += settings.blackSwanDropMonthly
            }
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
    iterationIndex: Int,
    mempoolDataManager: MempoolDataManager,
    rng: GKRandomSource
) -> [SimulationData] {
    
    var results = [SimulationData]()
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    let cagrDecimal = annualCAGR / 100.0
    let baseWeeklyVol = (annualVolatility / 100.0) / sqrt(52.0)

    // GARCH model
    var garchModel = GarchModel(
        omega: 0.000001,
        alpha: 0.1,
        beta: 0.85,
        initialVariance: baseWeeklyVol * baseWeeklyVol
    )
    
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn = 0.0 // for autocorrelation

    for currentWeek in 1...totalWeeklySteps {
        
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        // Current stdev (GARCH or fixed)
        let currentVol = settings.useGarchVolatility
            ? garchModel.currentStdDev()
            : baseWeeklyVol
        
        if lumpsum {
            // Once every 52 weeks
            if Double(currentWeek).truncatingRemainder(dividingBy: 52.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(
                        mean: 0,
                        standardDeviation: currentVol,
                        rng: rng
                    )
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    lumpsumGrowth = (1 - phi) * lumpsumGrowth + phi * lastAutoReturn
                }
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    week: currentWeek,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    halvingWeeks: halvingWeeks,
                    rng: rng
                )
                
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
                
                lastStepLogReturn = log(1 + lumpsumGrowth)
                lastAutoReturn = lumpsumGrowth
            }
        } else {
            // Historical sampling or lognormal each step
            if settings.useHistoricalSampling {
                var weeklySample = pickRandomReturn(from: historicalBTCWeeklyReturns, rng: rng)
                weeklySample = dampenArctanWeekly(weeklySample)
                totalReturn += weeklySample
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 52.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                totalReturn += shockVol
            }
            if settings.useAutoCorrelation {
                let phi = settings.autoCorrelationStrength
                totalReturn = (1 - phi) * totalReturn + phi * lastAutoReturn
            }
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                week: currentWeek,
                settings: settings,
                mempoolDataManager: mempoolDataManager,
                halvingWeeks: halvingWeeks,
                rng: rng
            )
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn = toggled
        }
        
        // Floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Contributions
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
        let holdingsAfterDeposit = prevBTCHoldings + depositBTC
        
        // Withdraw thresholds
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
        
        if settings.useGarchVolatility {
            garchModel.updateVariance(lastReturn: lastStepLogReturn)
        }

        let dataPoint = SimulationData(
            week: currentWeek,
            startingBTC: prevBTCHoldings,
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
    iterationIndex: Int,
    mempoolDataManager: MempoolDataManager,
    rng: GKRandomSource
) -> [SimulationData] {

    var results = [SimulationData]()
    var prevBTCPriceUSD = initialBTCPriceUSD
    var prevBTCHoldings = 0.0
    
    let cagrDecimal = annualCAGR / 100.0
    let baseMonthlyVol = (annualVolatility / 100.0) / sqrt(12.0)

    var garchModel = GarchModel(
        omega: 0.00001,
        alpha: 0.1,
        beta: 0.85,
        initialVariance: baseMonthlyVol * baseMonthlyVol
    )
    
    let firstYearVal  = (settings.inputManager?.firstYearContribution as NSString?)?.doubleValue ?? 0
    let secondYearVal = (settings.inputManager?.subsequentContribution as NSString?)?.doubleValue ?? 0
    
    var lastStepLogReturn = 0.0
    var lastAutoReturn = 0.0

    for currentMonth in 1...totalMonths {
        let lumpsum = (!settings.useHistoricalSampling && !settings.useLognormalGrowth)
        var totalReturn = 0.0
        
        let currentVol = settings.useGarchVolatility
            ? garchModel.currentStdDev()
            : baseMonthlyVol
        
        if lumpsum {
            // Once per year => every 12 months
            if Double(currentMonth).truncatingRemainder(dividingBy: 12.0) == 0 {
                var lumpsumGrowth = cagrDecimal
                if settings.useVolShocks && annualVolatility > 0 {
                    let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                    lumpsumGrowth = (1 + lumpsumGrowth) * exp(shockVol) - 1
                }
                if settings.useAutoCorrelation {
                    let phi = settings.autoCorrelationStrength
                    lumpsumGrowth = (1 - phi) * lumpsumGrowth + phi * lastAutoReturn
                }
                lumpsumGrowth = applyFactorToggles(
                    baseReturn: lumpsumGrowth,
                    week: currentMonth,
                    settings: settings,
                    mempoolDataManager: mempoolDataManager,
                    halvingWeeks: halvingMonths,
                    rng: rng
                )
                
                let factor = lumpsumAdjustFactor(settings: settings, annualVolatility: annualVolatility)
                lumpsumGrowth *= factor
                prevBTCPriceUSD *= (1 + lumpsumGrowth)
                
                lastStepLogReturn = log(1 + lumpsumGrowth)
                lastAutoReturn = lumpsumGrowth
            }
        } else {
            // Historical sampling or lognormal each month
            if settings.useHistoricalSampling {
                var monthlySample = pickRandomReturn(from: historicalBTCMonthlyReturns, rng: rng)
                monthlySample = dampenArctanMonthly(monthlySample)
                totalReturn += monthlySample
            }
            if settings.useLognormalGrowth {
                totalReturn += (cagrDecimal / 12.0)
            }
            if settings.useVolShocks {
                let shockVol = randomNormalWithRNG(mean: 0, standardDeviation: currentVol, rng: rng)
                totalReturn += shockVol
            }
            if settings.useAutoCorrelation {
                let phi = settings.autoCorrelationStrength
                totalReturn = (1 - phi) * totalReturn + (phi * lastAutoReturn)
            }
            let toggled = applyFactorToggles(
                baseReturn: totalReturn,
                week: currentMonth,
                settings: settings,
                mempoolDataManager: mempoolDataManager,
                halvingWeeks: halvingMonths,
                rng: rng
            )
            prevBTCPriceUSD *= exp(toggled)
            
            lastStepLogReturn = toggled
            lastAutoReturn = toggled
        }
        
        // Floor
        if prevBTCPriceUSD < 1.0 {
            prevBTCPriceUSD = 1.0
        }
        let newPriceUSD = prevBTCPriceUSD
        let newPriceEUR = newPriceUSD / exchangeRateEURUSD
        
        // Contribution
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
        let holdingsAfterDeposit = prevBTCHoldings + depositBTC
        
        // Withdraw thresholds
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
        
        if settings.useGarchVolatility {
            garchModel.updateVariance(lastReturn: lastStepLogReturn)
        }

        let dataPoint = SimulationData(
            week: currentMonth, // storing month in 'week' field
            startingBTC: prevBTCHoldings,
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

// MARK: - Single Simulation Entry
func runOneFullSimulation(
    settings: SimulationSettings,
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    userWeeks: Int,
    initialBTCPriceUSD: Double,
    iterationIndex: Int = 0,
    rng: GKRandomSource, // single seeded RNG
    mempoolDataManager: MempoolDataManager? = nil
) -> [SimulationData] {

    if settings.periodUnit == .months {
        let totalMonths = userWeeks
        
        // Generate random halving months with the same RNG
        let randomHalvingMonths = generateRandomEventMonths(
            totalMonths: totalMonths,
            intervalGuess: halvingIntervalGuessMonths,
            rng: rng
        )

        let monthlyResult = runMonthlySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalMonths: totalMonths,
            initialBTCPriceUSD: initialBTCPriceUSD,
            halvingMonths: randomHalvingMonths,
            iterationIndex: iterationIndex,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            rng: rng
        )
        return monthlyResult

    } else {
        let totalWeeks = userWeeks
        
        // Generate random halving weeks with the same RNG
        let randomHalvingWeeks = generateRandomEventWeeks(
            totalWeeks: totalWeeks,
            intervalGuess: halvingIntervalGuess,
            rng: rng
        )
        
        let weeklyResult = runWeeklySimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeklySteps: totalWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            halvingWeeks: randomHalvingWeeks,
            iterationIndex: iterationIndex,
            mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
            rng: rng
        )
        return weeklyResult
    }
}

// MARK: - Compute median BTC across all runs
fileprivate func computeMedianBTCPriceByStep(allRuns: [[SimulationData]]) -> [Decimal] {
    guard let steps = allRuns.first?.count, steps > 0 else { return [] }
    var medians = [Decimal](repeating: 0, count: steps)
    
    for stepIndex in 0..<steps {
        let pricesAtStep = allRuns.compactMap { run -> Decimal? in
            guard run.indices.contains(stepIndex) else { return nil }
            return run[stepIndex].btcPriceUSD
        }
        
        guard !pricesAtStep.isEmpty else {
            medians[stepIndex] = 0
            continue
        }
        
        let sortedPrices = pricesAtStep.sorted()
        let mid = sortedPrices.count / 2
        if sortedPrices.count % 2 == 0 {
            let p1 = sortedPrices[mid - 1]
            let p2 = sortedPrices[mid]
            medians[stepIndex] = (p1 + p2) / 2
        } else {
            medians[stepIndex] = sortedPrices[mid]
        }
    }
    return medians
}

// MARK: - Run Multiple Simulations With Progress
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
    seed: UInt64? = nil,
    mempoolDataManager: MempoolDataManager? = nil
) -> (
    medianRun: [SimulationData],
    allRuns: [[SimulationData]],
    stepMedianPrices: [Decimal]
) {
    // 1) Create a single RNG for all draws
    let rng: GKRandomSource
    if let validSeed = seed {
        let seedData = withUnsafeBytes(of: validSeed) { Data($0) }
        rng = GKARC4RandomSource(seed: seedData)
    } else {
        rng = GKARC4RandomSource() // unseeded => new each run
    }
    
    // 2) Array to store all runs
    var allRuns = [[SimulationData]]()
    
    // 3) Loop
    for i in 0..<iterations {
        if isCancelled() { break }
        
        // optional sim delay
        Thread.sleep(forTimeInterval: 0.01)

        // Each iteration -> runOneFullSimulation with the same rng (it advances each time)
        let simRun = runOneFullSimulation(
            settings: settings,
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            userWeeks: userWeeks,
            initialBTCPriceUSD: initialBTCPriceUSD,
            iterationIndex: i + 1,
            rng: rng,
            mempoolDataManager: mempoolDataManager
        )
        allRuns.append(simRun)
        
        if isCancelled() { break }
        progressCallback(i + 1)
    }
    
    // If no runs, return empties
    if allRuns.isEmpty {
        return ([], [], [])
    }
    
    // 4) Pick a median run by final portfolioValueEUR
    let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
    let sorted = finalValues.sorted { $0.0 < $1.0 }
    let medianRun = sorted[sorted.count / 2].1
    
    // 5) Compute median BTC price across steps
    let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)

    return (medianRun, allRuns, stepMedians)
}
