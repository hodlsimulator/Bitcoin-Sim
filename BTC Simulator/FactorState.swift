//
//  FactorState.swift
//  BTCMonteCarlo
//
//  Created by . . on 04/02/2025.
//

import Foundation
import SwiftUI
    
struct FactorState: Codable {
    var name: String
    var isEnabled: Bool
    var isLocked: Bool
    var currentValue: Double
    var minValue: Double
    var maxValue: Double
    var defaultValue: Double
    
    // The user’s “manual offset” from the baseline
    var internalOffset: Double = 0.0
    
    // Only used when toggling off so we can restore later
    var frozenValue: Double? = nil
    
    // NEW: indicates if we forcibly set it to extremes via chart icon
    var wasChartForced: Bool = false
}
