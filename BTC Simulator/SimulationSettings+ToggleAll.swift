//
//  SimulationSettings+ToggleAll.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    var toggleAll: Bool {
        get {
            // Return 'true' if all factors are enabled
            factors.values.allSatisfy { $0.isEnabled }
        }
        set {
            if newValue {
                // Turn all factors ON via setFactorEnabled
                for name in factors.keys {
                    setFactorEnabled(factorName: name, enabled: true)
                    // Optionally, reset each factor's value to its default and clear its offset.
                    if var factor = factors[name] {
                        factor.currentValue = factor.defaultValue
                        factor.internalOffset = 0.0
                        factor.isLocked = false
                        factors[name] = factor
                    }
                }
            } else {
                // Turn all factors OFF via setFactorEnabled
                for name in factors.keys {
                    setFactorEnabled(factorName: name, enabled: false)
                    // Optionally, lock them (and, if desired, set currentValue to minValue)
                    if var factor = factors[name] {
                        factor.isLocked = true
                        // Uncomment the next line if you want to force them to the minimum.
                        // factor.currentValue = factor.minValue
                        factors[name] = factor
                    }
                }
            }
        }
    }
}
