//
//  RNGHelpers.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation
import GameplayKit

/// A standard normal draw using a seeded GKRandomSource.
func randomNormalWithRNG(
    mean: Double,
    standardDeviation: Double,
    rng: GKRandomSource
) -> Double {
    let u1 = Double(rng.nextUniform())
    let u2 = Double(rng.nextUniform())
    let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * .pi * u2)
    return z0 * standardDeviation + mean
}
