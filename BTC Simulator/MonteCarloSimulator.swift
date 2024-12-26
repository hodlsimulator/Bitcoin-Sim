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

// MARK: - Global Historical Arrays
var historicalBTCWeeklyReturns: [Double] = []
var sp500WeeklyReturns: [Double] = []

// Weighted BTC array (optional)
var weightedBTCWeeklyReturns: [Double] = []

// Simple struct to hold daily data
struct DailyDataPoint {
    let date: Date
    let price: Double
}

// MARK: - Load all historical data
func loadAllHistoricalData() {
    // 1) Parse BTC CSV -> weekly
    let btcDaily = parseDailyDataCSV(filename: "Bitcoin Historical Data.csv")
    historicalBTCWeeklyReturns = convertDailyToWeeklyReturns(btcDaily)

    // 2) Parse S&P CSV -> weekly
    let spDaily = parseDailyDataCSV(filename: "SP500 Historical Data.csv")
    sp500WeeklyReturns = convertDailyToWeeklyReturns(spDaily)

    // 3) Weighted BTC array
    weightedBTCWeeklyReturns = buildWeightedReturns(historicalBTCWeeklyReturns)

    print("Weeks loaded: BTC=\(historicalBTCWeeklyReturns.count), SP500=\(sp500WeeklyReturns.count)")
}

// MARK: - CSV -> Daily
func parseDailyDataCSV(filename: String) -> [DailyDataPoint] {
    var results: [DailyDataPoint] = []

    guard let filePath = Bundle.main.path(
        forResource: filename.replacingOccurrences(of: ".csv", with: ""),
        ofType: "csv"
    ) else {
        return []
    }

    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // skip header
            let cols = parseCSVRowNoPadding(line)
            guard cols.count >= 7 else { continue }

            let dateString  = cols[0]
            let priceString = cols[1]
            guard
                let date  = dateFromString(dateString),
                let price = parseDouble(priceString.replacingOccurrences(of: ",", with: ""))
            else { continue }

            results.append(.init(date: date, price: price))
        }

    } catch {
        return []
    }

    // Sort ascending
    results.sort { $0.date < $1.date }
    print("\(filename) -> \(results.count) rows.")
    return results
}

// MARK: - Convert daily -> weekly
func convertDailyToWeeklyReturns(_ dailyData: [DailyDataPoint]) -> [Double] {
    var weeklyReturns: [Double] = []
    let chunkSize = 7
    var index = 0

    while index < dailyData.count {
        let end = min(index + chunkSize, dailyData.count)
        let slice = dailyData[index..<end]
        if slice.count < chunkSize { break }

        let startPrice = slice.first!.price
        let endPrice   = slice.last!.price
        let weeklyChange = (endPrice / startPrice) - 1.0
        weeklyReturns.append(weeklyChange)
        index += chunkSize
    }

    return weeklyReturns
}

// MARK: - Weighted approach (optional)
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
        for _ in 0..<w {
            weighted.append(r)
        }
    }
    return weighted
}

// MARK: - CSV Row Parser
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

// MARK: - String->Double & Date
func parseDouble(_ s: String) -> Double? {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.numberStyle = .decimal
    formatter.decimalSeparator = "."
    return formatter.number(from: s)?.doubleValue
}

func dateFromString(_ str: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "MM/dd/yyyy"
    return formatter.date(from: str)
}

// MARK: - Gentle Dampening: arctan
/// This function gently dampens large positive/negative returns so they don't explode.
func dampenArctan(_ rawReturn: Double) -> Double {
    // 'factor' is how aggressively to flatten.
    // Larger factor => more flattening of big outliers.
    let factor = 5.0
    // arctan approach => range is roughly -0.636..+0.636 for factor=5
    let scaled = rawReturn * factor
    // scale to [-pi/2 .. +pi/2], then normalise
    // (2/pi) maps [-pi/2..+pi/2] to [-1..+1]
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened
}

// MARK: - Utility Stats

/// Returns the median of an array of Doubles.
func calculateMedian(values: [Double]) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let sortedValues = values.sorted()
    let mid = sortedValues.count / 2
    if sortedValues.count.isMultiple(of: 2) {
        // Even number of items, average the middle two
        return (sortedValues[mid - 1] + sortedValues[mid]) / 2.0
    } else {
        // Odd number of items, pick the middle
        return sortedValues[mid]
    }
}

/// Returns the standard deviation of an array of Doubles, given the mean.
func calculateStandardDeviation(values: [Double], mean: Double) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let variance = values.reduce(0.0) { $0 + pow($1 - mean, 2) } / Double(values.count)
    return sqrt(variance)
}

/// Returns the specified percentile (0–100) from an array of Doubles.
func calculatePercentile(values: [Double], percentile: Double) -> Double {
    guard !values.isEmpty else { return 0.0 }
    let sortedValues = values.sorted()
    let index = Int(Double(sortedValues.count - 1) * percentile / 100.0)
    return sortedValues[max(0, min(index, sortedValues.count - 1))]
}

/// Aggregates results across all runs to produce stats for each week: Mean, Median, Standard Deviation, etc.
func aggregateResults(allIterations: [[SimulationData]]) -> [String: [String: Double]] {
    var stats = [String: [String: Double]]()
    let totalIters = allIterations.count
    guard totalIters > 0 else { return stats }

    // Assume all runs have the same number of weeks
    let weeks = allIterations[0].count

    for i in 0..<weeks {
        var weekValues = [Double]()
        for run in allIterations {
            weekValues.append(run[i].portfolioValueEUR)
        }
        let meanVal = weekValues.reduce(0, +) / Double(totalIters)
        let medVal  = calculateMedian(values: weekValues)
        let stdVal  = calculateStandardDeviation(values: weekValues, mean: meanVal)
        let p90Val  = calculatePercentile(values: weekValues, percentile: 90)
        let p10Val  = calculatePercentile(values: weekValues, percentile: 10)

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
