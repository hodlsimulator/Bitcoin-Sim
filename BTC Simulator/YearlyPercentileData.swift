//
//  YearlyPercentileData.swift
//  BTCMonteCarlo
//
//  Created by . . on 30/12/2024.
//

import SwiftUI

struct YearlyPercentileData: Identifiable {
    let id = UUID()
    let year: Int
    let tenth: Double
    let median: Double
    let ninetieth: Double
}
