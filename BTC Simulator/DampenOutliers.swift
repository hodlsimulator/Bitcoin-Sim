//
//  DampenOutliers.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation

/// Dampens extreme weekly returns using an arctan-based flattening.
func dampenArctanWeekly(_ rawReturn: Double) -> Double {
    let factor = 0.1
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened * 0.5
}

/// Dampens extreme monthly returns using an arctan-based flattening.
func dampenArctanMonthly(_ rawReturn: Double) -> Double {
    let factor = 0.65
    let scaled = rawReturn * factor
    let flattened = (2.0 / Double.pi) * atan(scaled)
    return flattened * 0.5
}
