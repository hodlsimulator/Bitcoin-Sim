//
//  BlockBootstrapSimulator.swift
//  BTCMonteCarlo
//
//  Created by Conor on 24/01/2025.
//

import Foundation
import GameplayKit

/// Holds weekly pairs of (BTC return, SP500 return)
public var combinedWeeklyData: [(btc: Double, sp: Double)] = []

/// Holds monthly pairs of (BTC return, SP500 return)
public var combinedMonthlyData: [(btc: Double, sp: Double)] = []

/// Example geometric distribution for random block sizes.
/// Mean block size = 1/p. If meanBlockSize = 10, then p = 0.1.
fileprivate func geometricBlockSize(rng: GKRandomSource, meanBlockSize: Double) -> Int {
    let p = 1.0 / max(1.0, meanBlockSize) // p is a Double
    var count = 1
    while true {
        // Convert the Float returned by nextUniform() into Double
        let u = Double(rng.nextUniform())
        if u < p { // Now both sides are Double
            break
        }
        count += 1
        if count > 1000 { break } // safety
    }
    return count
}

/// Performs a variable-length block bootstrap on an array of (BTC, SP).
/// - parameter data: e.g. combinedWeeklyData or combinedMonthlyData
/// - parameter rng: your random source
/// - parameter totalSteps: total time steps desired
/// - parameter meanBlockSize: average block length
/// - parameter circular: if true, wrap around at array end
/// - returns: array of (btc, sp) pairs length `totalSteps`
func variableBlockBootstrap(
    data: [(Double, Double)],
    rng: GKRandomSource,
    totalSteps: Int,
    meanBlockSize: Double = 10.0,
    circular: Bool = true
) -> [(Double, Double)] {
    guard !data.isEmpty else { return [] }
    
    var results: [(Double, Double)] = []
    results.reserveCapacity(totalSteps)
    let dataCount = data.count
    
    // Start at a random position
    var currentIndex = rng.nextInt(upperBound: dataCount)
    
    while results.count < totalSteps {
        // Pick a random block length
        let blockSize = geometricBlockSize(rng: rng, meanBlockSize: meanBlockSize)
        
        for _ in 0..<blockSize {
            if results.count >= totalSteps { break }
            
            results.append(data[currentIndex])
            
            currentIndex += 1
            if currentIndex >= dataCount {
                if circular {
                    currentIndex = 0
                } else {
                    // If not circular, pick new random start
                    currentIndex = rng.nextInt(upperBound: dataCount)
                }
            }
        }
    }
    
    return results
}

// MARK: - Example usage in Weekly sim
/// Example function to generate a weekly time-series of length `totalWeeklySteps`.
func runWeeklySimulationWithBootstrap(
    settings: SimulationSettings,
    totalWeeklySteps: Int,
    rng: GKRandomSource
) -> [(btc: Double, sp: Double)] {
    // Use the global combinedWeeklyData
    let series = variableBlockBootstrap(
        data: combinedWeeklyData,
        rng: rng,
        totalSteps: totalWeeklySteps,
        meanBlockSize: 10.0, // tweak to taste
        circular: true
    )
    
    // Integrate (btc, sp) data into your simulator, e.g.:
    // for i in 0..<totalWeeklySteps {
    //     let (btcRet, spRet) = series[i]
    //     // do something with these...
    // }
    return series
}

// MARK: - Example usage in Monthly sim
/// Example function to generate a monthly time-series of length `totalMonths`.
func runMonthlySimulationWithBootstrap(
    settings: SimulationSettings,
    totalMonths: Int,
    rng: GKRandomSource
) -> [(btc: Double, sp: Double)] {
    let series = variableBlockBootstrap(
        data: combinedMonthlyData,
        rng: rng,
        totalSteps: totalMonths,
        meanBlockSize: 8.0, // maybe smaller for monthly
        circular: true
    )
    return series
}
