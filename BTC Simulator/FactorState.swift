//
//  FactorState.swift
//  BTCMonteCarlo
//
//  Created by . . on 04/02/2025.
//

import Foundation
import SwiftUI

struct FactorState {
    let name: String
    var isEnabled: Bool
    var isLocked: Bool
    
    /// The factor’s *actual* current value (e.g. 0.003, or -0.0012, etc.)
    /// always stays within [minValue .. maxValue].
    var currentValue: Double
    
    /// Hard-coded or user-defined range.
    let minValue: Double
    let maxValue: Double
    
    /// The factor’s ‘default’ or ‘mid’ value (where t=0.5 would map).
    let defaultValue: Double
}
