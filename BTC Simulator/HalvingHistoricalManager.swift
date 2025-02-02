//
//  HalvingHistoricalManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/02/2025
//

import Foundation

class HalvingHistoricalManager {
    static let shared = HalvingHistoricalManager()
    
    /// Known halving dates in dd/MM/yyyy format.
    private let halvingDates: [String] = [
        "28/11/2012",
        "09/07/2016",
        "11/05/2020",
        "11/05/2024"
    ]
    
    /// Parsed halving dates as Date objects.
    private lazy var halvingDateObjects: [Date] = {
        halvingDates.compactMap { dateFromString($0) }
    }()
    
    /// Loaded monthly historical data.
    var historicalData: [BitcoinHistoricalData] = []
    
    /// Cached average halving bump computed once.
    lazy var cachedAverageHalvingBump: Double = {
        return computeAverageHalvingBumpInternal()
    }()
    
    private init() {
        historicalData = loadBTCMonthlyData()
    }
    
    /// Computes the average halving bump using all known halving events.
    private func computeAverageHalvingBumpInternal() -> Double {
        let calendar = Calendar.current
        var monthlyReturns: [Double] = []
        
        for halvingDate in halvingDateObjects {
            let halvingComponents = calendar.dateComponents([.year, .month], from: halvingDate)
            
            let matchingData = historicalData.filter { row in
                guard let rowDate = dateFromString(row.date) else { return false }
                let rowComponents = calendar.dateComponents([.year, .month], from: rowDate)
                return (rowComponents.year == halvingComponents.year &&
                        rowComponents.month == halvingComponents.month)
            }
            
            for row in matchingData {
                monthlyReturns.append(row.changePercent / 100.0)
            }
        }
        
        guard !monthlyReturns.isEmpty else {
            return 0.0
        }
        
        let total = monthlyReturns.reduce(0.0, +)
        return total / Double(monthlyReturns.count)
    }
    
    // Helper to convert a date string to Date.
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString)
    }
}
