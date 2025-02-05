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
    var internalOffset: Double = 0.0
    var savedGlobalIntensity: Double? = nil
    var frozenValue: Double? = nil
}
