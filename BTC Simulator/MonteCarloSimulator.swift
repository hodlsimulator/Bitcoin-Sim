//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

// MARK: - Configuration toggles
/// If `true`, we use weighted sampling of weekly returns.
/// If `false`, we pick raw weekly returns as is.
private let useWeightedSampling = false

/// By default, we do not use a seeded generator (you can enable it if you want).
private var useSeededRandom = false

/// Our optional seeded generator (only used if `useSeededRandom = true`).
private var seededGen: SeededGenerator?

// MARK: - Halving config
private let halvingWeeks = [210, 420, 630, 840]
private let halvingBump = 0.20

// MARK: - Institutional Demand Factor
private let useInstitutionalDemand = true
private let demandStartWeek = 0
private let demandEndWeek   = 1040
private let maxDemandBoost  = 0.004

// MARK: - Country Adoption Factor
private let useCountryAdoption = true
private let countryStartWeek = 30
private let countryEndWeek   = 1040
private let maxCountryAdoptionBoost = 0.0055

// MARK: - Regulatory Clarity Factor
private let useRegulatoryClarity = true
private let clarityStartWeek = 0
private let clarityEndWeek   = 200
private let maxClarityBoost = 0.0006

// MARK: - ETF Approval Factor
private let useEtfApproval = true
private let etfStartWeek   = 0
private let etfEndWeek     = 400
private let maxEtfBoost    = 0.0008

// MARK: - Technological Breakthrough Factor
private let useTechBreakthrough = true
private let techStartWeek = 500
private let techEndWeek   = 600
private let maxTechBoost  = 0.002

// MARK: - Scarcity Event Factor
private let useScarcityEvents = true
private let scarcityStartWeek = 700
private let scarcityEndWeek   = 1040
private let maxScarcityBoost  = 0.025

// MARK: - Global Macro Hedge Factor
private let useGlobalMacroHedge = true
private let macroStartWeek = 400
private let macroEndWeek   = 600
private let maxMacroBoost  = 0.0015

// MARK: - Stablecoin Shift Factor
private let useStablecoinShift = true
private let stablecoinStartWeek = 300
private let stablecoinEndWeek   = 320
private let maxStablecoinBoost  = 0.0006

// MARK: - Demographic Adoption Factor
private let useDemographicAdoption = true
private let demoStartWeek = 0
private let demoEndWeek   = 1040
private let maxDemoBoost  = 0.001

// MARK: - Altcoin Flight Factor
private let useAltcoinFlight = true
private let altcoinStartWeek = 600
private let altcoinEndWeek   = 620
private let maxAltcoinBoost  = 0.001

// MARK: - Adoption Factor (Simple Incremental Drift)
private let useAdoptionFactor = true
private let adoptionBaseFactor = 0.000005

// MARK: - NEGATIVE FACTORS
// 1) Regulatory Clampdown
private let useRegClampdown = true
private let clampStartWeek  = 200
private let clampEndWeek    = 220
private let maxClampDown    = -0.0002  // -0.02% weekly once fully ramped

// 2) Competitor Coin
private let useCompetitorCoin = true
private let competitorStartWeek = 800
private let competitorEndWeek   = 820
private let maxCompetitorBoost  = -0.0018

// 3) Security Breach / Hack
// A one-off negative event at a specific week
private let useSecurityBreach = true
private let breachWeek        = 350
private let breachImpact      = -0.1

// 4) Bubble Pop
private let useBubblePop = true
private let popStartWeek = 900
private let popEndWeek   = 920
private let maxPopDrop   = -0.005 // -0.5% weekly once fully ramped

// 5) Stablecoin Meltdown
private let useStablecoinMeltdown = true
private let meltdownStartWeek = 320
private let meltdownEndWeek   = 340
private let maxMeltdownDrop   = -0.001

// MARK: - NEW BEARISH FACTORS (all default to `false`)

// 6) Black Swan Events
// Example: big sudden drops on specific weeks.
private let useBlackSwan = true
/// Weeks where a black swan might occur
private let blackSwanWeeks = [150, 500]
/// Impact each time it happens
private let blackSwanDrop = -0.60

// 7) Bear Market Conditions
// Example: a multi-week negative drift.
private let useBearMarket = true
private let bearStartWeek = 600
private let bearEndWeek   = 800
private let bearWeeklyDrift = -0.01  // -0.1% per week

// 8) Declining ARR / Maturing Market
// We linearly apply an additional negative drift from 0 to -2% by the end.
private let useMaturingMarket = true
private let maturingStartWeek = 50
private let maturingEndWeek   = 1040
private let maxMaturingDrop   = -0.015

// 9) Recession / Macro Crash (any other negative scenario)
private let useRecession = true
private let recessionStartWeek = 250
private let recessionEndWeek   = 400
private let maxRecessionDrop   = -0.004  // -0.5% weekly once fully ramped

// MARK: - Private Seeded Generator
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

/// If you want a locked seed for deterministic runs, call this internally.
private func setRandomSeed(_ seed: UInt64?) {
    if let s = seed {
        print("[SEED] setRandomSeed was called with \(s) – locking seed.")
        useSeededRandom = true
        seededGen = SeededGenerator(seed: s)
    } else {
        print("[SEED] setRandomSeed was called with nil – random seed.")
        useSeededRandom = false
        seededGen = nil
    }
}

// MARK: - Gentle Dampening: arctan
func dampenArctan(_ rawReturn: Double) -> Double {
    let factor = 5.5
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Historical Arrays
/// We'll only use these two arrays, populated from "Bitcoin Historical Data" and "SP500 Historical Data" CSVs.
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []

/// If you don't have or need weighted sampling, you can remove or ignore this.
var weightedBTCWeeklyReturns: [Double] = []


// MARK: - runOneFullSimulation
func runOneFullSimulation(
    annualCAGR: Double,
    annualVolatility: Double,
    exchangeRateEURUSD: Double,
    totalWeeks: Int
) -> [SimulationData] {
    
    // Hardcoded initial data (weeks 1..7)
    var results: [SimulationData] = [
        .init(
            week: 1,
            startingBTC: 0.0,
            netBTCHoldings: 0.00469014,
            btcPriceUSD: 76_532.03,
            btcPriceEUR: 71_177.69,
            portfolioValueEUR: 333.83,
            contributionEUR: 378.00,
            transactionFeeEUR: 2.46,
            netContributionBTC: 0.00527613,
            withdrawalEUR: 0.0
        ),
        .init(
            week: 2,
            startingBTC: 0.00469014,
            netBTCHoldings: 0.00530474,
            btcPriceUSD: 92_000.00,
            btcPriceEUR: 86_792.45,
            portfolioValueEUR: 465.00,
            contributionEUR: 60.00,
            transactionFeeEUR: 0.21,
            netContributionBTC: 0.00066988,
            withdrawalEUR: 0.0
        ),
        .init(
            week: 3,
            startingBTC: 0.00530474,
            netBTCHoldings: 0.00608283,
            btcPriceUSD: 95_000.00,
            btcPriceEUR: 89_622.64,
            portfolioValueEUR: 547.00,
            contributionEUR: 70.00,
            transactionFeeEUR: 0.25,
            netContributionBTC: 0.00077809,
            withdrawalEUR: 0.0
        ),
        .init(
            week: 4,
            startingBTC: 0.00608283,
            netBTCHoldings: 0.00750280,
            btcPriceUSD: 95_741.15,
            btcPriceEUR: 90_321.84,
            portfolioValueEUR: 685.00,
            contributionEUR: 130.00,
            transactionFeeEUR: 0.46,
            netContributionBTC: 0.00141997,
            withdrawalEUR: 0.0
        ),
        .init(
            week: 5,
            startingBTC: 0.00745154,
            netBTCHoldings: 0.00745154,
            btcPriceUSD: 96_632.26,
            btcPriceEUR: 91_162.51,
            portfolioValueEUR: 679.30,
            contributionEUR: 0.00,
            transactionFeeEUR: 5.00,
            netContributionBTC: 0.00000000,
            withdrawalEUR: 0.0
        ),
        .init(
            week: 6,
            startingBTC: 0.00745154,
            netBTCHoldings: 0.00745154,
            btcPriceUSD: 106_000.00,
            btcPriceEUR: 100_000.00,
            portfolioValueEUR: 745.15,
            contributionEUR: 0.00,
            transactionFeeEUR: 0.00,
            netContributionBTC: 0.00000000,
            withdrawalEUR: 0.0
        ),
        .init(
            week: 7,
            startingBTC: 0.00745154,
            netBTCHoldings: 0.00959318,
            btcPriceUSD: 98_346.31,
            btcPriceEUR: 92_779.54,
            portfolioValueEUR: 890.05,
            contributionEUR: 200.00,
            transactionFeeEUR: 1.300,
            netContributionBTC: 0.00214164,
            withdrawalEUR: 0.0
        )
    ]
    
    // Convert annual CAGR to weekly growth
    let lastHardcoded = results.last
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
    let weeklyVol = annualVolatility / sqrt(52.0)

    var previousBTCPriceUSD = lastHardcoded?.btcPriceUSD ?? 76_532.03
    var previousBTCHoldings = lastHardcoded?.netBTCHoldings ?? 0.00469014

    // Main loop
    for week in 8...totalWeeks {
        
        // 1) Pick a random weekly return from CSV
        let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
        let histReturn = pickRandomReturn(from: btcArr)
        
        // 2) Dampen extremes
        let dampenedReturn = dampenArctan(histReturn)
        
        // 3) Combine with base CAGR
        var combinedWeeklyReturn = dampenedReturn + baseWeeklyGrowth

        // 3a) Adoption factor (incremental drift)
        if useAdoptionFactor {
            let adoptionFactor = adoptionBaseFactor * Double(week - 7)
            combinedWeeklyReturn += adoptionFactor
        }
        
        // 4) Halving
        if halvingWeeks.contains(week) {
            combinedWeeklyReturn += halvingBump
        }
        
        // 5) Institutional demand
        if useInstitutionalDemand {
            if week >= demandStartWeek && week <= demandEndWeek {
                let progress = Double(week - demandStartWeek) / Double(demandEndWeek - demandStartWeek)
                let demandFactor = maxDemandBoost * progress
                combinedWeeklyReturn += demandFactor
            } else if week > demandEndWeek {
                combinedWeeklyReturn += maxDemandBoost
            }
        }
        
        // 6) Country adoption
        if useCountryAdoption {
            if week >= countryStartWeek && week <= countryEndWeek {
                let progress = Double(week - countryStartWeek) / Double(countryEndWeek - countryStartWeek)
                let countryAdoptionFactor = maxCountryAdoptionBoost * progress
                combinedWeeklyReturn += countryAdoptionFactor
            } else if week > countryEndWeek {
                combinedWeeklyReturn += maxCountryAdoptionBoost
            }
        }

        // 7) Regulatory clarity
        if useRegulatoryClarity {
            if week >= clarityStartWeek && week <= clarityEndWeek {
                let progress = Double(week - clarityStartWeek) / Double(clarityEndWeek - clarityStartWeek)
                let clarityFactor = maxClarityBoost * progress
                combinedWeeklyReturn += clarityFactor
            } else if week > clarityEndWeek {
                combinedWeeklyReturn += maxClarityBoost
            }
        }

        // 8) ETF approval
        if useEtfApproval {
            if week >= etfStartWeek && week <= etfEndWeek {
                let progress = Double(week - etfStartWeek) / Double(etfEndWeek - etfStartWeek)
                let etfFactor = maxEtfBoost * progress
                combinedWeeklyReturn += etfFactor
            } else if week > etfEndWeek {
                combinedWeeklyReturn += maxEtfBoost
            }
        }

        // 9) Tech breakthroughs
        if useTechBreakthrough {
            if week >= techStartWeek && week <= techEndWeek {
                let progress = Double(week - techStartWeek) / Double(techEndWeek - techStartWeek)
                let techFactor = maxTechBoost * progress
                combinedWeeklyReturn += techFactor
            } else if week > techEndWeek {
                combinedWeeklyReturn += maxTechBoost
            }
        }

        // 10) Scarcity events
        if useScarcityEvents {
            if week >= scarcityStartWeek && week <= scarcityEndWeek {
                let progress = Double(week - scarcityStartWeek) / Double(scarcityEndWeek - scarcityStartWeek)
                let scarcityFactor = maxScarcityBoost * progress
                combinedWeeklyReturn += scarcityFactor
            } else if week > scarcityEndWeek {
                combinedWeeklyReturn += maxScarcityBoost
            }
        }

        // 11) Macro hedge
        if useGlobalMacroHedge {
            if week >= macroStartWeek && week <= macroEndWeek {
                let progress = Double(week - macroStartWeek) / Double(macroEndWeek - macroStartWeek)
                let macroFactor = maxMacroBoost * progress
                combinedWeeklyReturn += macroFactor
            } else if week > macroEndWeek {
                combinedWeeklyReturn += maxMacroBoost
            }
        }

        // 12) Stablecoin shift
        if useStablecoinShift {
            if week >= stablecoinStartWeek && week <= stablecoinEndWeek {
                let progress = Double(week - stablecoinStartWeek) / Double(stablecoinEndWeek - stablecoinStartWeek)
                let stablecoinFactor = maxStablecoinBoost * progress
                combinedWeeklyReturn += stablecoinFactor
            } else if week > stablecoinEndWeek {
                combinedWeeklyReturn += maxStablecoinBoost
            }
        }

        // 13) Demographic adoption
        if useDemographicAdoption {
            if week >= demoStartWeek && week <= demoEndWeek {
                let progress = Double(week - demoStartWeek) / Double(demoEndWeek - demoStartWeek)
                let demoFactor = maxDemoBoost * progress
                combinedWeeklyReturn += demoFactor
            } else if week > demoEndWeek {
                combinedWeeklyReturn += maxDemoBoost
            }
        }

        // 14) Altcoin flight
        if useAltcoinFlight {
            if week >= altcoinStartWeek && week <= altcoinEndWeek {
                let progress = Double(week - altcoinStartWeek) / Double(altcoinEndWeek - altcoinStartWeek)
                let altFactor = maxAltcoinBoost * progress
                combinedWeeklyReturn += altFactor
            } else if week > altcoinEndWeek {
                combinedWeeklyReturn += maxAltcoinBoost
            }
        }

        // NEGATIVE FACTORS:
        // 15) Regulatory clampdown
        if useRegClampdown {
            if week >= clampStartWeek && week <= clampEndWeek {
                let progress = Double(week - clampStartWeek) / Double(clampEndWeek - clampStartWeek)
                let clampFactor = maxClampDown * progress
                combinedWeeklyReturn += clampFactor
            } else if week > clampEndWeek {
                combinedWeeklyReturn += maxClampDown
            }
        }

        // 16) Competitor coin
        if useCompetitorCoin {
            if week >= competitorStartWeek && week <= competitorEndWeek {
                let progress = Double(week - competitorStartWeek) / Double(competitorEndWeek - competitorStartWeek)
                let competitorFactor = maxCompetitorBoost * progress
                combinedWeeklyReturn += competitorFactor
            } else if week > competitorEndWeek {
                combinedWeeklyReturn += maxCompetitorBoost
            }
        }

        // 17) Security breach (one-off)
        if useSecurityBreach {
            if week == breachWeek {
                combinedWeeklyReturn += breachImpact
            }
        }

        // 18) Bubble pop
        if useBubblePop {
            if week >= popStartWeek && week <= popEndWeek {
                let progress = Double(week - popStartWeek) / Double(popEndWeek - popStartWeek)
                let popFactor = maxPopDrop * progress
                combinedWeeklyReturn += popFactor
            } else if week > popEndWeek {
                combinedWeeklyReturn += maxPopDrop
            }
        }

        // 19) Stablecoin meltdown
        if useStablecoinMeltdown {
            if week >= meltdownStartWeek && week <= meltdownEndWeek {
                let progress = Double(week - meltdownStartWeek) / Double(meltdownEndWeek - meltdownStartWeek)
                let meltdownFactor = maxMeltdownDrop * progress
                combinedWeeklyReturn += meltdownFactor
            } else if week > meltdownEndWeek {
                combinedWeeklyReturn += maxMeltdownDrop
            }
        }
        
        // 20) Optional random shock (volatility)
        // let shock = randomNormal(mean: 0.0, standardDeviation: weeklyVol)
        // combinedWeeklyReturn += shock

        // 21) Bear Market Conditions
        if useBearMarket {
            if week >= bearStartWeek && week <= bearEndWeek {
                combinedWeeklyReturn += bearWeeklyDrift
            }
        }

        // 22) Black Swan Events (big sudden drops on specific weeks)
        if useBlackSwan {
            if blackSwanWeeks.contains(week) {
                combinedWeeklyReturn += blackSwanDrop
            }
        }

        // 23) Declining ARR / Maturing Market
        if useMaturingMarket {
            if week >= maturingStartWeek && week <= maturingEndWeek {
                let progress = Double(week - maturingStartWeek) / Double(maturingEndWeek - maturingStartWeek)
                // This gradually moves from 0 to -0.02 (or -0.015, in your code)
                let maturingFactor = maxMaturingDrop * progress
                combinedWeeklyReturn += maturingFactor
            } else if week > maturingEndWeek {
                combinedWeeklyReturn += maxMaturingDrop
            }
        }

        // 24) Recession / Macro Crash
        if useRecession {
            if week >= recessionStartWeek && week <= recessionEndWeek {
                let progress = Double(week - recessionStartWeek) / Double(recessionEndWeek - recessionStartWeek)
                let recessionFactor = maxRecessionDrop * progress
                combinedWeeklyReturn += recessionFactor
            } else if week > recessionEndWeek {
                combinedWeeklyReturn += maxRecessionDrop
            }
        }

        // 25) Update BTC price
        var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0)
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD

        // Log every 50 weeks (for convenience)
        if week % 50 == 0 {
            print(
                "[Week \(week)] WeeklyReturn = "
                + String(format: "%.4f", combinedWeeklyReturn)
                + ", btcPriceUSD = "
                + String(format: "%.2f", btcPriceUSD)
            )
        }
        
        // 26) Contribution
        let contributionEUR = (week <= 52) ? 60.0 : 100.0
        let fee = contributionEUR * 0.0035
        let netBTC = (contributionEUR - fee) / btcPriceEUR
        
        // 27) Withdrawals
        let hypotheticalHoldings = previousBTCHoldings + netBTC
        let hypotheticalValueEUR = hypotheticalHoldings * btcPriceEUR
        var withdrawalEUR = 0.0
        if hypotheticalValueEUR > 60_000 {
            withdrawalEUR = 200.0
        } else if hypotheticalValueEUR > 30_000 {
            withdrawalEUR = 100.0
        }
        let withdrawalBTC = withdrawalEUR / btcPriceEUR
        
        let netHoldings = max(0.0, hypotheticalHoldings - withdrawalBTC)
        let portfolioValEUR = netHoldings * btcPriceEUR

        results.append(
            SimulationData(
                week: week,
                startingBTC: previousBTCPriceUSD, // or previousBTCHoldings, depending on how you want to track
                netBTCHoldings: netHoldings,
                btcPriceUSD: btcPriceUSD,
                btcPriceEUR: btcPriceEUR,
                portfolioValueEUR: portfolioValEUR,
                contributionEUR: contributionEUR,
                transactionFeeEUR: fee,
                netContributionBTC: netBTC,
                withdrawalEUR: withdrawalEUR
            )
        )
        
        previousBTCPriceUSD = btcPriceUSD
        previousBTCHoldings = netHoldings
    }

    return results
}

/// Helper function for random pick with optional seeding.
private func pickRandomReturn(from arr: [Double]) -> Double {
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
func runMonteCarloSimulationsWithProgress(
    annualCAGR: Double,
    annualVolatility: Double,
    correlationWithSP500: Double,
    exchangeRateEURUSD: Double,
    totalWeeks: Int,
    iterations: Int,
    progressCallback: @escaping (Int) -> Void
) -> ([SimulationData], [[SimulationData]]) {

    // If you want a deterministic seed:
    setRandomSeed(nil)

    var allRuns = [[SimulationData]]()

    for i in 0..<iterations {
        let simRun = runOneFullSimulation(
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeks: totalWeeks
        )
        allRuns.append(simRun)
        progressCallback(i + 1)
    }

    // Sort final results by last week's portfolioValue
    var finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? 0.0, $0) }
    finalValues.sort { $0.0 < $1.0 }

    // median
    let medianRun = finalValues[finalValues.count / 2].1
    return (medianRun, allRuns)
}

// MARK: - Optional Box-Muller for volatility
private func randomNormal(
    mean: Double,
    standardDeviation: Double
) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
