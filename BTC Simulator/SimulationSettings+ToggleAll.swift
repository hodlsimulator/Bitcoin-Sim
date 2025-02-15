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
            // 'true' if all factors are currently enabled
            factors.values.allSatisfy { $0.isEnabled }
        }
        set {
            // Prevent individual toggles from incrementally shifting extendedGlobalValue
            userIsActuallyTogglingAll = true
            
            if newValue {
                // Turn all factors ON
                for factorName in factors.keys {
                    setFactorEnabled(factorName: factorName, enabled: true)
                }
            } else {
                // Turn all factors OFF
                for factorName in factors.keys {
                    setFactorEnabled(factorName: factorName, enabled: false)
                    if var factor = factors[factorName] {
                        factor.isLocked = true
                        factors[factorName] = factor
                    }
                }
            }

            // Done toggling all, so let normal sync resume
            userIsActuallyTogglingAll = false

            // Perform one final sync so everything lines up with the global slider
            syncFactorsToGlobalIntensity()
            applyDictionaryFactorsToSim()
        }
    }
}
