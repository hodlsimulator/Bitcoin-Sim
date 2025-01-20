//
//  GARCHHelper.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/01/2025.
//

import Foundation

/// A lightweight GARCH(1,1) model to update volatility step by step.
struct GarchModel {
    /// ω (omega): long-term average variance
    let omega: Double
    /// α (alpha): reaction to last period’s squared returns
    let alpha: Double
    /// β (beta): persistence of previous volatility
    let beta: Double
    
    /// The current variance (σ²). We'll update this each step.
    private(set) var currentVariance: Double
    
    init(omega: Double, alpha: Double, beta: Double, initialVariance: Double) {
        self.omega = omega
        self.alpha = alpha
        self.beta = beta
        self.currentVariance = initialVariance
    }
    
    /// Update the variance using GARCH(1,1) => σ²(t+1) = ω + α * r(t)² + β * σ²(t)
    /// - Parameter lastReturn: the last return (like daily, weekly, monthly).
    mutating func updateVariance(lastReturn: Double) {
        let squaredReturn = lastReturn * lastReturn
        currentVariance = omega + alpha * squaredReturn + beta * currentVariance
    }
    
    /// The current standard deviation is the sqrt of variance.
    func currentStdDev() -> Double {
        return sqrt(currentVariance)
    }
}
