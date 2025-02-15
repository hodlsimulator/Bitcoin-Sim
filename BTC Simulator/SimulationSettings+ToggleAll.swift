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

            // Done toggling all
            userIsActuallyTogglingAll = false

            // REMOVE this to avoid jumping:
            // syncFactorsToGlobalIntensity()

            applyDictionaryFactorsToSim()
        }
    }
}
