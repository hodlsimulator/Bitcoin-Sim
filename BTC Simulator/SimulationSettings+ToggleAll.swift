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
            // 'true' if all factors are enabled
            factors.values.allSatisfy { $0.isEnabled }
        }
        set {
            if newValue {
                // Turn all factors ON without resetting their slider values
                for name in factors.keys {
                    setFactorEnabled(factorName: name, enabled: true)
                    // Removed lines that forcibly reset currentValue, internalOffset, etc.
                }
            } else {
                // Turn all factors OFF
                for name in factors.keys {
                    setFactorEnabled(factorName: name, enabled: false)
                    // Optionally lock them if you want them unadjustable while off
                    if var factor = factors[name] {
                        factor.isLocked = true
                        factors[name] = factor
                    }
                }
            }
        }
    }
}
