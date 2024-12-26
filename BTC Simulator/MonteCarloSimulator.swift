//
//  MonteCarloSimulator.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

// MARK: - Configuration toggles
/// If `true`, we use weighted sampling of weekly returns
/// If `false`, we just pick raw weekly returns as before.
private let useWeightedSampling = true

// MARK: - Global Historical Arrays & Loading
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []

// Also store a "weighted" version for BTC, so we don't weigh S&P yet.
var weightedBTCWeeklyReturns: [Double] = []

// Simple struct to hold daily data from your CSV
struct DailyDataPoint {
    let date: Date
    let price: Double
}

// The main function you call to load and parse everything.
func loadAllHistoricalData() {
    // 1) Parse daily BTC CSV, convert it to weekly returns
    let btcDaily = parseDailyDataCSV(filename: "Bitcoin Historical Data.csv")
    historicalBTCWeeklyReturns = convertDailyToWeeklyReturns(btcDaily)

    // 2) Parse daily S&P 500 CSV, convert it to weekly returns
    let spDaily = parseDailyDataCSV(filename: "SP500 Historical Data.csv")
    sp500WeeklyReturns = convertDailyToWeeklyReturns(spDaily)

    // 3) Build a weighted BTC array so negative returns don’t dominate
    weightedBTCWeeklyReturns = buildWeightedReturns(historicalBTCWeeklyReturns)

    // Debug info
    print("DEBUG: BTC weekly returns loaded: \(historicalBTCWeeklyReturns.count) entries")
    if let sampleBTC = historicalBTCWeeklyReturns.first {
        print("DEBUG: Sample raw BTC weekly return = \(sampleBTC)")
    }
    print("DEBUG: Weighted BTC array size = \(weightedBTCWeeklyReturns.count)")

    print("DEBUG: SP500 weekly returns loaded: \(sp500WeeklyReturns.count) entries")
    if let sampleSP = sp500WeeklyReturns.first {
        print("DEBUG: Sample S&P500 weekly return = \(sampleSP)")
    }
}

// MARK: - CSV -> Daily
/// Reads a daily CSV file from the app bundle, returning an array of DailyDataPoint.
/// Expects columns like: Date, Price, Open, High, Low, Vol., Change %
func parseDailyDataCSV(filename: String) -> [DailyDataPoint] {
    var results: [DailyDataPoint] = []

    // 1) Attempt to locate the file in the app bundle
    guard let filePath = Bundle.main.path(forResource: filename.replacingOccurrences(of: ".csv", with: ""), ofType: "csv") else {
        print("DEBUG: \(filename) NOT FOUND in the main bundle.")
        return []
    }
    print("DEBUG: Found \(filename) at \(filePath)")

    do {
        // 2) Read the file contents
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        print("DEBUG: \(filename) read, length = \(content.count) characters")

        // 3) Split into lines, ignoring empties
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        print("DEBUG: \(filename) has \(lines.count) lines (including header)")

        // 4) Parse each line
        for (index, line) in lines.enumerated() {
            // If your CSV has a header, skip the first line
            if index == 0 {
                print("DEBUG: Skipping CSV header row: \(line)")
                continue
            }

            let cols = parseCSVRowNoPadding(line)
            // We expect at least 7 columns: Date, Price, Open, High, Low, Vol., Change %
            if cols.count < 7 {
                print("DEBUG: Not enough columns in row: \(line)")
                continue
            }

            let dateString  = cols[0]
            let priceString = cols[1]

            // Convert date & price
            guard
                let date  = dateFromString(dateString),
                let price = parseDouble(priceString.replacingOccurrences(of: ",", with: ""))
            else {
                print("DEBUG: Could not parse date/price in row: \(line)")
                continue
            }

            // Create the daily point
            let dp = DailyDataPoint(date: date, price: price)
            results.append(dp)
        }

    } catch {
        print("DEBUG: Error reading \(filename) - \(error)")
        return []
    }

    // Sort ascending (oldest first)
    results.sort { $0.date < $1.date }
    print("DEBUG: parseDailyDataCSV(\(filename)) returning \(results.count) daily rows.")
    return results
}

// Convert a sorted array of daily data into weekly returns
func convertDailyToWeeklyReturns(_ dailyData: [DailyDataPoint]) -> [Double] {
    var weeklyReturns: [Double] = []
    let chunkSize = 7
    var index = 0

    while index < dailyData.count {
        let end = min(index + chunkSize, dailyData.count)
        let slice = dailyData[index..<end]
        
        // If not a full 7-day block, you might decide to break or handle partial weeks
        if slice.count < chunkSize {
            break
        }
        
        let startPrice = slice.first!.price
        let endPrice   = slice.last!.price
        let weeklyChange = (endPrice / startPrice) - 1.0
        weeklyReturns.append(weeklyChange)
        
        index += chunkSize
    }
    
    return weeklyReturns
}

// MARK: - Weighted approach: buildWeightedReturns
/// We replicate or reduce entries based on the return's magnitude.
/// Negative or huge downturns can appear, but less frequently.
/// This is purely optional - you can adjust thresholds or multipliers as you like.
func buildWeightedReturns(_ rawReturns: [Double]) -> [Double] {
    var weighted = [Double]()
    
    for r in rawReturns {
        // Example weighting logic:
        //   big negative < -0.20 => weight = 1
        //   mild negative -0.20..0 => weight = 2
        //   mild positive 0..0.10 => weight = 3
        //   moderate positive 0.10..0.20 => weight = 4
        //   big positive > 0.20 => weight = 5
        //
        // Tweak these thresholds or multipliers as you see fit.
        
        let w: Int
        switch r {
        case ..<(-0.20):
            w = 1
        case (-0.20)..<0.0:
            w = 2
        case 0.0..<0.10:
            w = 3
        case 0.10..<0.20:
            w = 4
        default:
            w = 5
        }
        
        // Append 'r' 'w' times
        for _ in 0..<w {
            weighted.append(r)
        }
    }
    
    print("DEBUG: Weighted returns expanded from \(rawReturns.count) to \(weighted.count).")
    return weighted
}

// Helper to parse a CSV row, ignoring quotes/padding
func parseCSVRowNoPadding(_ row: String) -> [String] {
    var columns: [String] = []
    var current = ""
    var inQuotes = false

    for char in row {
        if char == "\"" {
            inQuotes.toggle()
        } else if char == "," && !inQuotes {
            columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
            current = ""
        } else {
            current.append(char)
        }
    }
    if !current.isEmpty {
        columns.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    return columns
}

// Convert string -> Double
func parseDouble(_ s: String) -> Double? {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    return formatter.number(from: s)?.doubleValue
}

// Convert "03/24/2024" -> Date
func dateFromString(_ str: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    return formatter.date(from: str)
}

// MARK: - Single-run function (1 iteration)
func runOneFullSimulation(
    annualCAGR: Double,
    annualVolatility: Double,
    /* correlationWithSP500: Double, */
    exchangeRateEURUSD: Double,
    totalWeeks: Int
) -> [SimulationData] {
    // Hardcoded weeks 1–7 (your initial known steps)
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
    
    let lastHardcoded = results.last
    let baseWeeklyGrowth = pow(1.0 + annualCAGR, 1.0 / 52.0) - 1.0
    let weeklyVol = annualVolatility / sqrt(52.0) // Not used if shock is disabled

    var previousBTCPriceUSD = lastHardcoded?.btcPriceUSD ?? 76_532.03
    var previousBTCHoldings = lastHardcoded?.netBTCHoldings ?? 0.00469014

    // Weeks 8..totalWeeks
    for week in 8...totalWeeks {
        // Sample random weekly moves from CSV
        let (histBTC, _) = sampleHistoricalReturns()
        
        // Combine CSV-based returns with user-defined CAGR
        var combinedWeeklyReturn = histBTC + baseWeeklyGrowth
        
        // Uncomment if you want to add the random shock:
        // let shock = randomNormal(mean: 0, standardDeviation: weeklyVol)
        // combinedWeeklyReturn += shock

        var btcPriceUSD = previousBTCPriceUSD * (1.0 + combinedWeeklyReturn)
        btcPriceUSD = max(btcPriceUSD, 1.0)  // Safety floor
        let btcPriceEUR = btcPriceUSD / exchangeRateEURUSD

        // Basic logic
        let contributionEUR = (week <= 52) ? 60.0 : 100.0
        let fee = contributionEUR * 0.0035
        let netBTC = (contributionEUR - fee) / btcPriceEUR

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
                startingBTC: previousBTCHoldings,
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

// MARK: - CSV Sampling
/// Randomly pick one weekly BTC return & one S&P weekly return
/// If `useWeightedSampling` is true, we pick from weightedBTCWeeklyReturns
func sampleHistoricalReturns() -> (btcWeekly: Double, spWeekly: Double) {
    guard !historicalBTCWeeklyReturns.isEmpty, !sp500WeeklyReturns.isEmpty else {
        print("DEBUG: Historical arrays empty, defaulting to 0.0 returns")
        return (0.0, 0.0)
    }
    
    // For BTC:
    let btcArr = useWeightedSampling ? weightedBTCWeeklyReturns : historicalBTCWeeklyReturns
    let btcIdx = Int.random(in: 0..<btcArr.count)
    let spIdx  = Int.random(in: 0..<sp500WeeklyReturns.count)

    return (btcArr[btcIdx], sp500WeeklyReturns[spIdx])
}

// Uncomment if you want random shocks
/*
func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
    let u1 = Double.random(in: 0..<1)
    let u2 = Double.random(in: 0..<1)
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
*/

// MARK: - Multiple Runs (with progress callback)
func runMonteCarloSimulationsWithProgress(
    annualCAGR: Double,
    annualVolatility: Double,
    /* correlationWithSP500: Double = 0.0, */
    exchangeRateEURUSD: Double,
    totalWeeks: Int,
    iterations: Int,
    progressCallback: @escaping (Int) -> Void
) -> ([SimulationData], [[SimulationData]]) {

    var allRuns = [[SimulationData]]()
    var finalValues = [(value: Double, run: [SimulationData])]()

    for i in 0..<iterations {
        let run = runOneFullSimulation(
            annualCAGR: annualCAGR,
            annualVolatility: annualVolatility,
            exchangeRateEURUSD: exchangeRateEURUSD,
            totalWeeks: totalWeeks
        )
        if let finalWeek = run.last {
            finalValues.append((finalWeek.portfolioValueEUR, run))
        }
        allRuns.append(run)

        // progress
        progressCallback(i + 1)
    }

    // Sort by final portfolio value
    finalValues.sort { $0.value < $1.value }

    // median run
    let medianRun = finalValues[finalValues.count / 2].run

    return (medianRun, allRuns)
}

// MARK: - Utility Stats
func calculateMedian(values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let sorted = values.sorted()
    let mid = sorted.count / 2
    if sorted.count % 2 == 0 {
        return (sorted[mid - 1] + sorted[mid]) / 2.0
    } else {
        return sorted[mid]
    }
}

func calculateStandardDeviation(values: [Double], mean: Double) -> Double {
    let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
}

func calculatePercentile(values: [Double], percentile: Double) -> Double {
    let sorted = values.sorted()
    let index = Int(Double(sorted.count - 1) * percentile / 100.0)
    return sorted[max(0, min(index, sorted.count - 1))]
}

/// Example aggregator if you want summary stats per week across many runs
func aggregateResults(allIterations: [[SimulationData]]) -> [String: [String: Double]] {
    var stats = [String: [String: Double]]()
    let totalIters = allIterations.count
    guard totalIters > 0 else { return stats }

    let weeks = allIterations[0].count
    for i in 0..<weeks {
        var vals = [Double]()
        for iteration in allIterations {
            vals.append(iteration[i].portfolioValueEUR)
        }
        let meanVal = vals.reduce(0, +) / Double(totalIters)
        let medVal  = calculateMedian(values: vals)
        let stdVal  = calculateStandardDeviation(values: vals, mean: meanVal)
        let p90Val  = calculatePercentile(values: vals, percentile: 90)
        let p10Val  = calculatePercentile(values: vals, percentile: 10)

        stats["Week \(i+1)"] = [
            "Mean": meanVal,
            "Median": medVal,
            "Standard Deviation": stdVal,
            "90th Percentile": p90Val,
            "10th Percentile": p10Val
        ]
    }
    return stats
}
