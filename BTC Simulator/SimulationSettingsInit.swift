import SwiftUI

extension SimulationSettings {
    convenience init(loadDefaults: Bool = true) {
        self.init()
        guard loadDefaults else { return }
        
        // If you want special “default” values different from
        // user defaults, you can set them here.
        // For example:
        if !UserDefaults.standard.bool(forKey: "didSetSomeInitialDefaults") {
            userPeriods = 52
            startingBalance = 0.0
            averageCostBasis = 25000.0
            // ...
            UserDefaults.standard.set(true, forKey: "didSetSomeInitialDefaults")
        }
        
        // You can also manipulate factor states here if you want:
        // e.g. turn on Halving by default:
        if var halving = factors["Halving"] {
            halving.isEnabled = true
            factors["Halving"] = halving
        }
        
        // Done
    }
}
