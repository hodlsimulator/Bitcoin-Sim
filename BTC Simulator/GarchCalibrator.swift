//
//  GarchAdamCalibrator.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/01/2025.
//

import Foundation

/// If you need to distinguish weekly vs monthly calibrations, you can use this:
enum TimeFrame {
    case weekly
    case monthly
}

/// A gradient-based GARCH(1,1) calibrator that uses Adam for better step-size adaptation.
class GarchAdamCalibrator {
    
    /// Calibrate (omega, alpha, beta) by maximising log-likelihood via Adam.
    /// - Parameters:
    ///   - returns: An array of historical returns
    ///   - initialOmega: Initial guess for ω
    ///   - initialAlpha: Initial guess for α
    ///   - initialBeta:  Initial guess for β
    ///   - iterations: How many Adam steps to run
    ///   - baseLR: The base learning rate
    ///   - beta1: Adam’s exponential decay rate for the first moment
    ///   - beta2: Adam’s exponential decay rate for the second moment
    ///   - epsilon: Adam’s small constant to avoid division by zero
    ///   - timeFrame: weekly or monthly. We can clamp more aggressively for monthly if needed.
    ///   - maxVarianceClamp: If > 0, we clamp the variance each step to this maximum
    ///   - scaleForMonthly: An optional factor to scale monthly returns down before calibrating
    /// - Returns: A GarchModel with calibrated parameters
    func calibrate(
        returns: [Double],
        initialOmega: Double = 1e-4,
        initialAlpha: Double = 0.1,
        initialBeta:  Double = 0.85,
        iterations: Int = 200,
        baseLR: Double = 1e-3,
        beta1: Double = 0.9,
        beta2: Double = 0.999,
        epsilon: Double = 1e-8,
        timeFrame: TimeFrame = .weekly,
        maxVarianceClamp: Double = 0.5,
        scaleForMonthly: Double = 0.01
    ) -> GarchModel {
        
        // If no returns, just return defaults:
        guard !returns.isEmpty else {
            return GarchModel(
                omega: initialOmega,
                alpha: initialAlpha,
                beta: initialBeta,
                initialVariance: 1e-4
            )
        }
        
        // Optionally scale monthly returns so GARCH doesn't see huge jumps:
        let finalReturns: [Double]
        if timeFrame == .monthly && scaleForMonthly != 0.2 {
            finalReturns = returns.map { $0 * scaleForMonthly }
        } else {
            finalReturns = returns
        }

        // Current parameters:
        var omega = initialOmega
        var alpha = initialAlpha
        var beta  = initialBeta
        
        // Adam moment estimates (m = first moment, v = second moment):
        var mOmega = 0.0, vOmega = 0.0
        var mAlpha = 0.0, vAlpha = 0.0
        var mBeta  = 0.0, vBeta  = 0.0
        
        // For bias correction:
        var t = 0

        for _ in 0..<iterations {
            t += 1  // Adam iteration count
            
            // 1) Compute numeric gradient of log-likelihood
            let (gradOmega, gradAlpha, gradBeta) = numericalGradient(
                returns: finalReturns,
                omega: omega,
                alpha: alpha,
                beta: beta
            )
            
            // 2) Update moments
            mOmega = beta1 * mOmega + (1 - beta1) * gradOmega
            vOmega = beta2 * vOmega + (1 - beta2) * gradOmega * gradOmega
            
            mAlpha = beta1 * mAlpha + (1 - beta1) * gradAlpha
            vAlpha = beta2 * vAlpha + (1 - beta2) * gradAlpha * gradAlpha
            
            mBeta  = beta1 * mBeta  + (1 - beta1) * gradBeta
            vBeta  = beta2 * vBeta  + (1 - beta2) * gradBeta * gradBeta
            
            // 3) Bias correction
            let mOmegaHat = mOmega / (1 - pow(beta1, Double(t)))
            let vOmegaHat = vOmega / (1 - pow(beta2, Double(t)))
            
            let mAlphaHat = mAlpha / (1 - pow(beta1, Double(t)))
            let vAlphaHat = vAlpha / (1 - pow(beta2, Double(t)))
            
            let mBetaHat  = mBeta  / (1 - pow(beta1, Double(t)))
            let vBetaHat  = vBeta  / (1 - pow(beta2, Double(t)))
            
            // 4) Adam update (we add because we want to ascend the log-likelihood)
            omega += baseLR * mOmegaHat / (sqrt(vOmegaHat) + epsilon)
            alpha += baseLR * mAlphaHat / (sqrt(vAlphaHat) + epsilon)
            beta  += baseLR * mBetaHat  / (sqrt(vBetaHat)  + epsilon)
            
            // 5) Basic constraints: positivity + stationarity
            if omega < 1e-12 { omega = 1e-12 }
            if alpha < 0     { alpha = 0 }
            if beta  < 0     { beta  = 0 }
            
            // If monthly, clamp alpha+beta to something smaller
            let upperLimit = (timeFrame == .monthly) ? 0.6 : 0.999
            if alpha + beta >= upperLimit {
                let sum = alpha + beta
                alpha *= upperLimit / sum
                beta  *= upperLimit / sum
            }
        }
        
        // We'll compute the final log-likelihood using the final parameters:
        _ = computeGarchLogLikelihood(
            returns: finalReturns,
            omega: omega,
            alpha: alpha,
            beta: beta,
            maxVarianceClamp: maxVarianceClamp
        )
        
        // Return final parameters as a GarchModel.
        return GarchModel(
            omega: omega,
            alpha: alpha,
            beta:  beta,
            initialVariance: 1e-4
        )
    }
    
    // MARK: - Numerical Gradient
    
    /// Approximates partial derivatives of log-likelihood wrt (omega, alpha, beta).
    private func numericalGradient(
        returns: [Double],
        omega: Double,
        alpha: Double,
        beta: Double,
        epsilon: Double = 1e-6
    ) -> (Double, Double, Double) {
        
        // d/dOmega
        let upOmega = computeGarchLogLikelihood(
            returns: returns,
            omega: omega + epsilon,
            alpha: alpha,
            beta: beta
        )
        let downOmega = computeGarchLogLikelihood(
            returns: returns,
            omega: omega - epsilon,
            alpha: alpha,
            beta: beta
        )
        let dOmega = (upOmega - downOmega) / (2 * epsilon)
        
        // d/dAlpha
        let upAlpha = computeGarchLogLikelihood(
            returns: returns,
            omega: omega,
            alpha: alpha + epsilon,
            beta: beta
        )
        let downAlpha = computeGarchLogLikelihood(
            returns: returns,
            omega: omega,
            alpha: alpha - epsilon,
            beta: beta
        )
        let dAlpha = (upAlpha - downAlpha) / (2 * epsilon)
        
        // d/dBeta
        let upBeta = computeGarchLogLikelihood(
            returns: returns,
            omega: omega,
            alpha: alpha,
            beta: beta + epsilon
        )
        let downBeta = computeGarchLogLikelihood(
            returns: returns,
            omega: omega,
            alpha: alpha,
            beta: beta - epsilon
        )
        let dBeta = (upBeta - downBeta) / (2 * epsilon)
        
        return (dOmega, dAlpha, dBeta)
    }
    
    // MARK: - GARCH Log-Likelihood
    
    /// Computes the log-likelihood of a GARCH(1,1) model (mean=0 assumption).
    /// - Parameter maxVarianceClamp: if > 0, we clamp variance each step
    private func computeGarchLogLikelihood(
        returns: [Double],
        omega: Double,
        alpha: Double,
        beta: Double,
        maxVarianceClamp: Double = 0.0
    ) -> Double {
        
        // Start variance estimate as sample variance of first few points
        let initialVariance = max(1e-10, sampleVariance(Array(returns.prefix(5))))
        
        var variance = initialVariance
        var logL = 0.0
        let c = -0.5 * log(2.0 * Double.pi) // repeated constant
        
        for r in returns {
            // log-likelihood increment
            logL += c
            logL += -0.5 * log(variance)
            logL += -(r * r) / (2.0 * variance)
            
            // GARCH update
            variance = omega + alpha * (r * r) + beta * variance
            
            // Always clamp to some tiny floor
            if variance < 1e-15 {
                variance = 1e-15
            }
            // If you want to clamp big variance, do so:
            if maxVarianceClamp > 0.0 && variance > maxVarianceClamp {
                variance = maxVarianceClamp
            }
        }
        
        return logL
    }
    
    /// Standard sample variance function
    private func sampleVariance(_ arr: [Double]) -> Double {
        guard arr.count > 1 else { return 1e-8 }
        let mean = arr.reduce(0.0, +) / Double(arr.count)
        let sqSum = arr.reduce(0.0) { $0 + pow($1 - mean, 2) }
        return sqSum / Double(arr.count - 1)
    }
}
