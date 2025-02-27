//
//  MetalChartGestureCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import UIKit

/// A Coordinator that handles UIPinchGestureRecognizer, UIPanGestureRecognizer, etc.
class MetalChartGestureCoordinator: NSObject {
    
    // Example state for scale/translation
    private var baseScale: Float = 1.0
    private var baseTranslation = SIMD2<Float>(0, 0)
    
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        
        let renderer = chartView.renderer
        
        switch recognizer.state {
        case .began:
            baseScale = renderer.scale
        case .changed:
            let newScale = baseScale * Float(recognizer.scale)
            let scaleRatio = newScale / renderer.scale
            
            // Anchor around pinch centre
            let location = recognizer.location(in: chartView)
            let anchorNDC = renderer.convertPointToNDC(location, viewSize: chartView.bounds.size)
            
            renderer.translation.x -= anchorNDC.x * (scaleRatio - 1)
            renderer.translation.y -= anchorNDC.y * (scaleRatio - 1)
            
            renderer.scale = newScale
            renderer.updateTransform()
        case .ended, .cancelled:
            // Done with pinch; new scale is locked in
            break
        default:
            break
        }
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        
        let renderer = chartView.renderer
        let translation = recognizer.translation(in: chartView)
        
        switch recognizer.state {
        case .began:
            baseTranslation = renderer.translation
        case .changed:
            // Convert the translation in points to NDC
            let dx = Float(translation.x / chartView.bounds.width) * 2.0
            let dy = Float(translation.y / chartView.bounds.height) * 2.0
            
            renderer.translation.x = baseTranslation.x + dx
            renderer.translation.y = baseTranslation.y - dy
            renderer.updateTransform()
        case .ended, .cancelled:
            // Lock in final translation
            break
        default:
            break
        }
    }
}
