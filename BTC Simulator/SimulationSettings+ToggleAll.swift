//
//  SimulationSettings+ToggleAll.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// A computed property to toggle all factors on/off in our new FactorState system.
    ///
    /// - When toggled `true`:
    ///   - set `isEnabled = true` for every factor
    ///   - optionally set `currentValue = defaultValue` (or midpoint)
    ///   - optionally set `isLocked = false`
    /// - When toggled `false`:
    ///   - set `isEnabled = false` for every factor
    ///   - optionally lock them or set `currentValue` to minValue (your call)
    var toggleAll: Bool {
        get {
            // Return 'true' iff *all* factors are enabled
            factors.values.allSatisfy { $0.isEnabled }
        }
        set {
            if newValue {
                // Turn *all* factors ON
                for (name, var factor) in factors {
                    factor.isEnabled = true
                    factor.isLocked  = false
                    // Optionally reset to the factor's default or midpoint
                    factor.currentValue = factor.defaultValue
                    factors[name] = factor
                }
            } else {
                // Turn *all* factors OFF
                for (name, var factor) in factors {
                    factor.isEnabled = false
                    // Optionally lock them so global slider won't move them
                    factor.isLocked = true
                    // If you like, set currentValue = minValue
                    // factor.currentValue = factor.minValue
                    factors[name] = factor
                }
            }
        }
    }
}
