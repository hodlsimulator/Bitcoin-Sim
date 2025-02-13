//
//  ParallelSimulationRunner.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/02/2025.
//

import Foundation
import GameplayKit

class ParallelSimulationRunner {
    static func runSimulationsConcurrently(
        settings: SimulationSettings,
        monthlySettings: MonthlySimulationSettings,
        annualCAGR: Double,
        annualVolatility: Double,
        correlationWithSP500: Double,
        exchangeRateEURUSD: Double,
        userWeeks: Int,
        iterations: Int,
        initialBTCPriceUSD: Double,
        seed: UInt64? = nil,
        mempoolDataManager: MempoolDataManager? = nil,
        fittedGarchModel: GarchModel? = nil,
        progressCallback: @escaping (Int) -> Void,
        completion: @escaping ([SimulationData], [[SimulationData]], [Decimal]) -> Void
    ) {
        let queue = DispatchQueue(label: "simulation.queue", attributes: .concurrent)
        let group = DispatchGroup()
        
        // Array to hold each simulation run.
        var allRuns = [[SimulationData]](repeating: [], count: iterations)
        
        for i in 0..<iterations {
            group.enter()
            queue.async {
                // Create a unique random source for thread safety.
                let rng: GKRandomSource
                if let validSeed = seed {
                    let seedValue = validSeed + UInt64(i)
                    let seedData = withUnsafeBytes(of: seedValue) { Data($0) }
                    rng = GKARC4RandomSource(seed: seedData)
                } else {
                    rng = GKARC4RandomSource()
                }
                
                let simRun = runOneFullSimulation(
                    settings: settings,
                    monthlySettings: monthlySettings,
                    annualCAGR: annualCAGR,
                    annualVolatility: annualVolatility,
                    exchangeRateEURUSD: exchangeRateEURUSD,
                    userWeeks: userWeeks,
                    initialBTCPriceUSD: initialBTCPriceUSD,
                    iterationIndex: i + 1,
                    rng: rng,
                    mempoolDataManager: mempoolDataManager ?? MempoolDataManager(mempoolData: []),
                    garchModel: fittedGarchModel
                )
                
                allRuns[i] = simRun
                DispatchQueue.main.async {
                    progressCallback(i + 1)
                }
                group.leave()
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            // Sort runs by final EUR portfolio value and pick the median run.
            let finalValues = allRuns.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
            let sorted = finalValues.sorted { $0.0 < $1.0 }
            let medianRun = sorted[sorted.count / 2].1
            
            let stepMedians = computeMedianBTCPriceByStep(allRuns: allRuns)
            
            completion(medianRun, allRuns, stepMedians)
        }
    }
}
