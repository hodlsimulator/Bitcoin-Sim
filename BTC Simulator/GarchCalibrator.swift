//
//  GarchAdamCalibrator.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/01/2025.
//

import Foundation

enum TimeFrame {
    case weekly
    case monthly
}

class GarchAdamCalibrator {
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
        timeFrame: TimeFrame = .weekly  // <--- NEW
    ) -> GarchModel {
        
        guard !returns.isEmpty else {
            return GarchModel(
                omega: initialOmega,
                alpha: initialAlpha,
                beta: initialBeta,
                initialVariance: 1e-4
            )
        }
        
        // Possibly do a quick scale if monthly (OPTIONAL):
        // let scaledReturns = timeFrame == .monthly ? returns.map { $0 * 0.5 } : returns
        // … then calibrate on scaledReturns ...
        // This helps reduce blow-ups from giant monthly jumps.

        var omega = initialOmega
        var alpha = initialAlpha
        var beta  = initialBeta
        
        var mOmega = 0.0, vOmega = 0.0
        var mAlpha = 0.0, vAlpha = 0.0
        var mBeta  = 0.0, vBeta  = 0.0
        
        var t = 0
        
        for _ in 0..<iterations {
            t += 1
            
            let (gradOmega, gradAlpha, gradBeta) = numericalGradient(
                returns: returns,
                omega: omega,
                alpha: alpha,
                beta: beta
            )
            
            mOmega = beta1 * mOmega + (1 - beta1) * gradOmega
            vOmega = beta2 * vOmega + (1 - beta2) * gradOmega * gradOmega
            
            mAlpha = beta1 * mAlpha + (1 - beta1) * gradAlpha
            vAlpha = beta2 * vAlpha + (1 - beta2) * gradAlpha * gradAlpha
            
            mBeta  = beta1 * mBeta  + (1 - beta1) * gradBeta
            vBeta  = beta2 * vBeta  + (1 - beta2) * gradBeta * gradBeta
            
            let mOmegaHat = mOmega / (1 - pow(beta1, Double(t)))
            let vOmegaHat = vOmega / (1 - pow(beta2, Double(t)))
            let mAlphaHat = mAlpha / (1 - pow(beta1, Double(t)))
            let vAlphaHat = vAlpha / (1 - pow(beta2, Double(t)))
            let mBetaHat  = mBeta  / (1 - pow(beta1, Double(t)))
            let vBetaHat  = vBeta  / (1 - pow(beta2, Double(t)))
            
            omega += baseLR * mOmegaHat / (sqrt(vOmegaHat) + epsilon)
            alpha += baseLR * mAlphaHat / (sqrt(vAlphaHat) + epsilon)
            beta  += baseLR * mBetaHat  / (sqrt(vBetaHat)  + epsilon)
            
            // Basic positivity constraints
            if omega < 1e-12 { omega = 1e-12 }
            if alpha < 0 { alpha = 0 }
            if beta  < 0 { beta  = 0 }
            
            // Tweak: stricter limit for monthly vs weekly
            let upperLimit = (timeFrame == .monthly) ? 0.9 : 0.999
            if alpha + beta >= upperLimit {
                let sum = alpha + beta
                alpha *= upperLimit / sum
                beta  *= upperLimit / sum
            }
        }
        
        let finalLogL = computeGarchLogLikelihood(returns: returns, omega: omega, alpha: alpha, beta: beta)
        print("Adam-based GARCH calibration done. Final log-likelihood: \(finalLogL)")
        print("Final (ω, α, β) = (\(omega), \(alpha), \(beta))")
        
        return GarchModel(
            omega: omega,
            alpha: alpha,
            beta:  beta,
            initialVariance: 1e-4
        )
    }
    
    private func numericalGradient(
        returns: [Double],
        omega: Double,
        alpha: Double,
        beta: Double,
        epsilon: Double = 1e-6
    ) -> (Double, Double, Double) {
        
        let base = computeGarchLogLikelihood(returns: returns, omega: omega, alpha: alpha, beta: beta)
        
        let upOmega   = computeGarchLogLikelihood(returns: returns, omega: omega + epsilon, alpha: alpha, beta: beta)
        let downOmega = computeGarchLogLikelihood(returns: returns, omega: omega - epsilon, alpha: alpha, beta: beta)
        let dOmega    = (upOmega - downOmega) / (2 * epsilon)
        
        let upAlpha   = computeGarchLogLikelihood(returns: returns, omega: omega, alpha: alpha + epsilon, beta: beta)
        let downAlpha = computeGarchLogLikelihood(returns: returns, omega: omega, alpha: alpha - epsilon, beta: beta)
        let dAlpha    = (upAlpha - downAlpha) / (2 * epsilon)
        
        let upBeta   = computeGarchLogLikelihood(returns: returns, omega: omega, alpha: alpha, beta: beta + epsilon)
        let downBeta = computeGarchLogLikelihood(returns: returns, omega: omega, alpha: alpha, beta: beta - epsilon)
        let dBeta    = (upBeta - downBeta) / (2 * epsilon)
        
        return (dOmega, dAlpha, dBeta)
    }
    
    private func computeGarchLogLikelihood(
        returns: [Double],
        omega: Double,
        alpha: Double,
        beta: Double
    ) -> Double {
        
        let initialVariance = max(1e-10, sampleVariance(Array(returns.prefix(5))))
        
        var variance = initialVariance
        var logL = 0.0
        let c = -0.5 * log(2.0 * Double.pi)
        
        for r in returns {
            logL += c
            logL += -0.5 * log(variance)
            logL += -(r * r) / (2.0 * variance)
            
            variance = omega + alpha * (r * r) + beta * variance
            if variance < 1e-15 { variance = 1e-15 }
        }
        
        return logL
    }
    
    private func sampleVariance(_ arr: [Double]) -> Double {
        guard arr.count > 1 else { return 1e-8 }
        let mean = arr.reduce(0.0, +) / Double(arr.count)
        let sqSum = arr.reduce(0.0) { $0 + pow($1 - mean, 2) }
        return sqSum / Double(arr.count - 1)
    }
}
