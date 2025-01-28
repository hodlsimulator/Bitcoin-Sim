//
//  SimulationSettings+ToggleAll.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/01/2025.
//

import SwiftUI

extension SimulationSettings {
    
    /// A computed property that returns true if
    /// *all* factors have fraction == 1.0,
    /// and false otherwise.
    var toggleAll: Bool {
        get {
            // If *every* factor’s fraction is >= 1.0,
            // we consider them all “on.”
            return factorEnableFrac.values.allSatisfy { $0 >= 1.0 }
        }
        set {
            // If newValue == true => turn them all on (1.0)
            // else turn them all off (0.0)
            let newFrac = newValue ? 1.0 : 0.0
            for key in factorEnableFrac.keys {
                factorEnableFrac[key] = newFrac
            }
        }
    }
}
