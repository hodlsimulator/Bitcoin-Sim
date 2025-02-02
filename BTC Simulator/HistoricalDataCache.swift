//
//  HistoricalDataCache.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/02/2025.
//

import Foundation

class HistoricalDataCache {
    static let shared = HistoricalDataCache()
    
    private(set) var cachedWeeklyDampened: [Double] = []
    private(set) var cachedMonthlyDampened: [Double] = []
    
    private init() { }
    
    func cacheWeeklyData(original: [Double]) {
        // Assumes dampenArctanWeekly is accessible globally.
        cachedWeeklyDampened = original.map { dampenArctanWeekly($0) }
    }
    
    func cacheMonthlyData(original: [Double]) {
        // Assumes dampenArctanMonthly is accessible globally.
        cachedMonthlyDampened = original.map { dampenArctanMonthly($0) }
    }
}
