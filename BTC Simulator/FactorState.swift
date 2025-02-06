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
    var currentValue: Double
    var defaultValue: Double
    var minValue: Double
    var maxValue: Double
    var isEnabled: Bool
    var isLocked: Bool
    var frozenValue: Double? = nil
    var internalOffset: Double = 0.0
    var wasChartForced: Bool = false
}
