//
//  CSVLoaderBTC.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

// MARK: - BTC Weekly
func loadBTCWeeklyReturnsAsDict() -> [Date: Double] {
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data Weekly", ofType: "csv") else {
        return [:]
    }
    
    var weeklyDict: [Date: Double] = [:]
    
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (index, row) in rows.enumerated() {
            // Skip header
            if index == 0 { continue }
            
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 { continue }
            
            let dateString   = cols[0]
            let changeString = cols[6]
            
            guard
                let date = csvDateFormatter.date(from: dateString),
                let rawChange = parseDouble(
                    changeString
                        .replacingOccurrences(of: "%", with: "")
                        .replacingOccurrences(of: "+", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                )
            else {
                continue
            }
            
            weeklyDict[date] = rawChange / 100.0
        }
        
        return weeklyDict
        
    } catch {
        return [:]
    }
}

func alignBTCandSPWeekly(
    btcDict: [Date: Double],
    spDict: [Date: Double]
) -> [(Date, Double, Double)] {
    
    let commonDates = Set(btcDict.keys).intersection(spDict.keys)
    var aligned: [(Date, Double, Double)] = []
    
    for date in commonDates {
        if let btcRet = btcDict[date], let spRet = spDict[date] {
            aligned.append((date, btcRet, spRet))
        }
    }
    
    // Sort by ascending date
    aligned.sort { $0.0 < $1.0 }
    return aligned
}

func alignBTCandSPMonthly(
    btcDict: [Date: Double],
    spDict: [Date: Double]
) -> [(Date, Double, Double)] {
    
    let commonDates = Set(btcDict.keys).intersection(spDict.keys)
    var aligned: [(Date, Double, Double)] = []
    
    for date in commonDates {
        if let btcRet = btcDict[date], let spRet = spDict[date] {
            aligned.append((date, btcRet, spRet))
        }
    }
    
    aligned.sort { $0.0 < $1.0 }  // Sort by ascending date
    return aligned
}

// MARK: - BTC Monthly
func loadBTCMonthlyReturnsAsDict() -> [Date: Double] {
    guard let filePath = Bundle.main.path(forResource: "Bitcoin Historical Data Monthly", ofType: "csv") else {
        return [:]
    }
    
    var monthlyDict: [Date: Double] = [:]
    
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 { continue }
            
            let dateString   = cols[0]
            let changeString = cols[6]
            
            guard
                let date = csvDateFormatter.date(from: dateString),
                let rawChange = parseDouble(
                    changeString
                        .replacingOccurrences(of: "%", with: "")
                        .replacingOccurrences(of: "+", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                )
            else {
                continue
            }
            
            monthlyDict[date] = rawChange / 100.0
        }
        
        return monthlyDict
        
    } catch {
        return [:]
    }
}

// MARK: - S&P 500 Weekly
func loadSP500WeeklyReturnsAsDict() -> [Date: Double] {
    guard let filePath = Bundle.main.path(forResource: "S&P 500 Historical Data Weekly", ofType: "csv") else {
        return [:]
    }
    
    var weeklyDict: [Date: Double] = [:]
    
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 { continue }
            
            let dateString   = cols[0]
            let changeString = cols[6]
            
            guard
                let date = csvDateFormatter.date(from: dateString),
                let rawChange = parseDouble(
                    changeString
                        .replacingOccurrences(of: "%", with: "")
                        .replacingOccurrences(of: "+", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                )
            else {
                continue
            }
            
            weeklyDict[date] = rawChange / 100.0
        }
        
        return weeklyDict
        
    } catch {
        return [:]
    }
}

// MARK: - S&P 500 Monthly
func loadSP500MonthlyReturnsAsDict() -> [Date: Double] {
    guard let filePath = Bundle.main.path(forResource: "S&P 500 Historical Data Monthly", ofType: "csv") else {
        return [:]
    }
    
    var monthlyDict: [Date: Double] = [:]
    
    do {
        let content = try String(contentsOfFile: filePath, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (index, row) in rows.enumerated() {
            if index == 0 { continue }
            
            let cols = parseCSVRowNoPadding(row)
            if cols.count < 7 { continue }
            
            let dateString   = cols[0]
            let changeString = cols[6]
            
            guard
                let date = csvDateFormatter.date(from: dateString),
                let rawChange = parseDouble(
                    changeString
                        .replacingOccurrences(of: "%", with: "")
                        .replacingOccurrences(of: "+", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                )
            else {
                continue
            }
            
            monthlyDict[date] = rawChange / 100.0
        }
        
        return monthlyDict
        
    } catch {
        return [:]
    }
}

// MARK: - CSV Date Formatter
fileprivate let csvDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd/MM/yyyy"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

// MARK: - Return Just BTC Returns (Weekly & Monthly)
/// Returns an array of BTC weekly returns as [Double].
// The single “weekly” function that does everything:
func loadAndAlignWeeklyData() -> [Double] {
    let btcWeeklyDict = loadBTCWeeklyReturnsAsDict()
    let spWeeklyDict  = loadSP500WeeklyReturnsAsDict()
    let alignedWeekly = alignBTCandSPWeekly(btcDict: btcWeeklyDict, spDict: spWeeklyDict)
    
    // Return the BTC portion
    let justBtcWeekly = alignedWeekly.map { $0.1 }

    // Also store (btc, sp) if needed for block bootstrap
    combinedWeeklyData = alignedWeekly.map { (_, btc, sp) in (btc, sp) }
    
    return justBtcWeekly
}

/// Returns an array of BTC monthly returns as [Double].
func loadAndAlignMonthlyData() -> [Double] {
    let btcMonthlyDict = loadBTCMonthlyReturnsAsDict()
    let spMonthlyDict  = loadSP500MonthlyReturnsAsDict()
    let alignedMonthly = alignBTCandSPMonthly(btcDict: btcMonthlyDict, spDict: spMonthlyDict)
    let justBtcMonthly = alignedMonthly.map { $0.1 } // index 1 is BTC
    return justBtcMonthly
}
