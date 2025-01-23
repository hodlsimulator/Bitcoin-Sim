//
//  MarketRegime.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation
import GameplayKit

// MARK: - Regime Switching Model
enum MarketRegime: CaseIterable {
    case bull
    case bear
    case hype
    case neutral
    
    var cagrMultiplier: Double {
        switch self {
        case .bull:   return 1.2
        case .bear:   return 0.7
        case .hype:   return 1.5
        case .neutral:return 1.0
        }
    }
    
    var volMultiplier: Double {
        switch self {
        case .bull:   return 0.9
        case .bear:   return 1.2
        case .hype:   return 1.5
        case .neutral:return 1.0
        }
    }
}

struct RegimeSwitchingModel {
    /// transitionMatrix[fromRegime][toRegime]
    /// Must match the order in MarketRegime.allCases
    let transitionMatrix: [[Double]]
    var currentRegime: MarketRegime
    
    init() {
        // Example 4x4 matrix for [bull, bear, hype, neutral]
        self.transitionMatrix = [
            /* bull ->   */ [0.70, 0.10, 0.10, 0.10],
            /* bear ->   */ [0.15, 0.70, 0.05, 0.10],
            /* hype ->   */ [0.10, 0.10, 0.60, 0.20],
            /* neutral-> */ [0.20, 0.20, 0.10, 0.50]
        ]
        self.currentRegime = .neutral
    }
    
    mutating func updateRegime(rng: GKRandomSource) {
        let rowIndex = MarketRegime.allCases.firstIndex(of: currentRegime)!
        let row = transitionMatrix[rowIndex]
        
        let roll = rng.nextUniform()
        var cumulative: Float = 0.0
        for (i, prob) in row.enumerated() {
            cumulative += Float(prob)
            if roll <= cumulative {
                currentRegime = MarketRegime.allCases[i]
                break
            }
        }
    }
}
