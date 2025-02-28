//
//  MetalChartGestureCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import UIKit

/// Multi-touch gestures: single-finger pan, two-finger pan, pinch, double-tap zoom.
class MetalChartGestureCoordinator: NSObject {
    
    private var baseScale: Float = 1.0
    private var baseTranslation = SIMD2<Float>(0, 0)
    
    private var baseScaleForTwoFingerPan: Float = 1.0
    
    private var initialPinchAnchorData: SIMD2<Float>?
    
    // Zoom factor for double-tap
    private let doubleTapZoomFactor: Float = 1.5
    
    // Zoom factor for two-finger pan
    private let twoFingerZoomFactor: Float = 0.005
}

// MARK: - Simultaneous Recognition
extension MetalChartGestureCoordinator: UIGestureRecognizerDelegate {
    func configureRecognizerForSimultaneous(_ recognizer: UIGestureRecognizer) {
        recognizer.delegate = self
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Gesture Handlers
extension MetalChartGestureCoordinator {
    
    // MARK: Single-finger Pan
    @objc func handleSingleFingerPan(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        let translationPoint = recognizer.translation(in: chartView)
        
        switch recognizer.state {
        case .began:
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
        case .changed:
            // Just do normal panning (no clamp in changed for Option A)
            renderer.scale = baseScale
            renderer.translation = baseTranslation
            
            let dx = Float(translationPoint.x / chartView.bounds.width) * 2.0
            let dy = Float(translationPoint.y / chartView.bounds.height) * 2.0
            
            renderer.translation.x += dx
            renderer.translation.y -= dy
            renderer.updateTransform()
            
        case .ended, .cancelled:
            // Now clamp once
            renderer.anchorEdges()
            
            // Update base
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
        default:
            break
        }
    }
    
    // MARK: Two-finger Pan (Trackpad Zoom)
    @objc func handleTwoFingerPanToZoom(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        guard recognizer.numberOfTouches == 2 else { return }
        
        switch recognizer.state {
        case .began:
            baseScaleForTwoFingerPan = renderer.scale
            
        case .changed:
            let translation = recognizer.translation(in: chartView)
            let deltaY = Float(-translation.y)
            let factor = 1.0 + (deltaY * twoFingerZoomFactor)
            let newScale = max(0.00001, baseScaleForTwoFingerPan * factor)
            let scaleRatio = newScale / renderer.scale
            
            // Midpoint
            let t1 = recognizer.location(ofTouch: 0, in: chartView)
            let t2 = recognizer.location(ofTouch: 1, in: chartView)
            let mx = (t1.x + t2.x) / 2.0
            let my = (t1.y + t2.y) / 2.0
            
            let anchorNDC = renderer.convertPointToNDC(CGPoint(x: mx, y: my),
                                                       viewSize: chartView.bounds.size)
            renderer.translation.x -= anchorNDC.x * (scaleRatio - 1)
            renderer.translation.y -= anchorNDC.y * (scaleRatio - 1)
            
            renderer.scale = newScale
            renderer.updateTransform()
            
        case .ended, .cancelled:
            // Single clamp at end
            renderer.anchorEdges()
            
        default:
            break
        }
    }
    
    // MARK: Pinch
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        switch recognizer.state {
        case .began:
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
            // Midpoint
            let location: CGPoint
            if recognizer.numberOfTouches >= 2 {
                let t1 = recognizer.location(ofTouch: 0, in: chartView)
                let t2 = recognizer.location(ofTouch: 1, in: chartView)
                location = CGPoint(
                    x: (t1.x + t2.x) / 2.0,
                    y: (t1.y + t2.y) / 2.0
                )
            } else {
                location = recognizer.location(in: chartView)
            }
            initialPinchAnchorData = renderer.convertPointToData(location,
                                                                 viewSize: chartView.bounds.size)
            
        case .changed:
            guard let anchorData = initialPinchAnchorData else { return }
            
            let pinchScale = Float(recognizer.scale)
            let newScale   = baseScale * pinchScale
            
            // Anchor logic
            let anchorOldScreen = anchorScreenCoord(
                renderer: renderer,
                dataCoord: anchorData,
                scale: baseScale,
                translation: baseTranslation,
                in: chartView
            )
            let anchorNewScreen = anchorScreenCoord(
                renderer: renderer,
                dataCoord: anchorData,
                scale: newScale,
                translation: baseTranslation,
                in: chartView
            )
            let dxScreen = anchorOldScreen.x - anchorNewScreen.x
            let dyScreen = anchorOldScreen.y - anchorNewScreen.y
            
            let ndcDx = Float(dxScreen / chartView.bounds.width)  * 2.0
            let ndcDy = -Float(dyScreen / chartView.bounds.height) * 2.0
            
            renderer.scale = newScale
            renderer.translation.x = baseTranslation.x + ndcDx
            renderer.translation.y = baseTranslation.y + ndcDy
            
            renderer.updateTransform()
            
        case .ended, .cancelled:
            // Once you release pinch, clamp
            renderer.anchorEdges()
            
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            initialPinchAnchorData = nil
            
        default:
            break
        }
    }
    
    /// Helper to see where a dataCoord would be on screen for a hypothetical (scale,translation).
    private func anchorScreenCoord(
        renderer: MetalChartRenderer,
        dataCoord: SIMD2<Float>,
        scale: Float,
        translation: SIMD2<Float>,
        in chartView: UIView
    ) -> CGPoint {
        let oldScale = renderer.scale
        let oldTrans = renderer.translation
        
        // Temporarily override
        renderer.scale = scale
        renderer.translation = translation
        
        let screenPt = renderer.convertDataToPoint(dataCoord, viewSize: chartView.bounds.size)
        
        // Restore
        renderer.scale = oldScale
        renderer.translation = oldTrans
        
        return screenPt
    }
    
    // MARK: Double Tap
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        if recognizer.state == .ended {
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
            let location = recognizer.location(in: chartView)
            let anchorNDC = renderer.convertPointToNDC(location, viewSize: chartView.bounds.size)
            
            let newScale = baseScale * doubleTapZoomFactor
            let scaleRatio = newScale / baseScale
            
            renderer.translation.x -= anchorNDC.x * (scaleRatio - 1)
            renderer.translation.y -= anchorNDC.y * (scaleRatio - 1)
            
            renderer.scale = newScale
            renderer.updateTransform()
            
            // Finally clamp
            renderer.anchorEdges()
            
            baseScale = newScale
            baseTranslation = renderer.translation
        }
    }
}
