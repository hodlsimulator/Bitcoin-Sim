//
//  FactorState.swift
//  BTCMonteCarlo
//
//  Created by . . on 04/02/2025.
//

import Foundation
import SwiftUI

struct FactorState {
    var name: String
    var isEnabled: Bool
    var isLocked: Bool
    var currentValue: Double
    var minValue: Double
    var maxValue: Double
    var defaultValue: Double
    var internalOffset: Double = 0.0
    var savedGlobalIntensity: Double? = nil
    // New: store the value when the factor is toggled off
    var frozenValue: Double? = nil
}
