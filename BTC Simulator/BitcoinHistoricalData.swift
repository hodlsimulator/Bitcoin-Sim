//
//  BitcoinHistoricalData.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/12/2024.
//

import Foundation

struct BitcoinHistoricalData: Identifiable {
    /// `id` for SwiftUI's "Identifiable" conformance (if needed)
    let id = UUID()
    
    // Raw string from the CSV, e.g. "Dec 24, 2024"
    // If you want to parse to Swift's `Date`, see notes below.
    let date: String
    
    // Numeric columns
    let price: Double
    let open: Double
    let high: Double
    let low: Double
    
    // Keep volume as a `String` since it might have suffixes (e.g. "9.56K")
    let volume: String
    
    // The CSV might store something like "+1.50%" or "-0.75%"
    // We'll parse out the "%" and store as a Double, e.g. 1.50 or -0.75
    let changePercent: Double
}
