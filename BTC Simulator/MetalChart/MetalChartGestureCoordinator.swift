//
//  MetalChartGestureCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import UIKit

/// A Coordinator that handles advanced multi-touch gestures:
///  - Single-finger pan (drag)
///  - Two-finger pan (trackpad-like zoom)
///  - Pinch-to-zoom (anchor precisely at initial finger midpoint)
///  - Double-tap to zoom
class MetalChartGestureCoordinator: NSObject {
    
    // MARK: - Properties
    
    /// Base scale at the start of a gesture
    private var baseScale: Float = 1.0
    
    /// Base translation at the start of a gesture
    private var baseTranslation = SIMD2<Float>(0, 0)
    
    /// Base scale specific to the two-finger pan gesture
    private var baseScaleForTwoFingerPan: Float = 1.0
    
    /// Initial anchor point for pinch-to-zoom, fixed at the start of the gesture
    private var initialPinchAnchor: SIMD2<Float>?
    
    // MARK: - Customization
    
    /// Zoom factor applied on double-tap
    private let doubleTapZoomFactor: Float = 1.5
    
    /// Zoom sensitivity for two-finger pan
    private let twoFingerZoomFactor: Float = 0.005
    
    private var initialPinchAnchorData: SIMD2<Float>?
}

// MARK: - Configure to Allow Simultaneous Recognition
extension MetalChartGestureCoordinator: UIGestureRecognizerDelegate {
    
    /// Configures a gesture recognizer to allow simultaneous recognition with others.
    /// Call this in the container's `makeUIView` to enable all gestures to work together.
    func configureRecognizerForSimultaneous(_ recognizer: UIGestureRecognizer) {
        recognizer.delegate = self
    }
    
    /// Allows all gestures to recognize simultaneously by default.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Gesture Handlers
extension MetalChartGestureCoordinator {
    
    // MARK: - Single-finger Pan
    
    /// Handles single-finger panning to drag the chart.
    @objc func handleSingleFingerPan(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        let translationPoint = recognizer.translation(in: chartView)
        
        switch recognizer.state {
        case .began:
            // Store the current scale and translation
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
        case .changed:
            // Reset to base values to avoid cumulative drift
            renderer.scale = baseScale
            renderer.translation = baseTranslation
            
            // Calculate translation in NDC space
            let dx = Float(translationPoint.x / chartView.bounds.width) * 2.0
            let dy = Float(translationPoint.y / chartView.bounds.height) * 2.0
            
            // Apply translation
            renderer.translation.x += dx
            renderer.translation.y -= dy
            renderer.updateTransform()
            
        case .ended, .cancelled:
            // Update base values
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
        default:
            break
        }
    }
    
    // MARK: - Two-finger Pan (Trackpad-like Zoom)
    
    /// Handles two-finger panning to zoom in/out, anchoring at the current midpoint.
    @objc func handleTwoFingerPanToZoom(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        // Ensure exactly two touches are present
        guard recognizer.numberOfTouches == 2 else { return }
        
        switch recognizer.state {
        case .began:
            // Store the initial scale
            baseScaleForTwoFingerPan = renderer.scale
            
        case .changed:
            let translation = recognizer.translation(in: chartView)
            
            // Compute zoom factor based on vertical movement
            let deltaY = Float(-translation.y)
            let factor = 1.0 + (deltaY * twoFingerZoomFactor)
            let newScale = max(0.00001, baseScaleForTwoFingerPan * factor)
            let scaleRatio = newScale / renderer.scale
            
            // Calculate current midpoint of the two touches
            let touch1 = recognizer.location(ofTouch: 0, in: chartView)
            let touch2 = recognizer.location(ofTouch: 1, in: chartView)
            let midX = (touch1.x + touch2.x) / 2.0
            let midY = (touch1.y + touch2.y) / 2.0
            let anchorNDC = renderer.convertPointToNDC(CGPoint(x: midX, y: midY),
                                                       viewSize: chartView.bounds.size)
            
            // Adjust translation to keep the anchor fixed
            renderer.translation.x -= anchorNDC.x * (scaleRatio - 1)
            renderer.translation.y -= anchorNDC.y * (scaleRatio - 1)
            
            renderer.scale = newScale
            renderer.updateTransform()
            
        case .ended, .cancelled:
            // Base scale will be reset on next .began
            break
            
        default:
            break
        }
    }
    
    // MARK: - Pinch (Two-finger Zoom)
    
    /// Handles pinch-to-zoom, anchoring at the initial midpoint between fingers.
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        switch recognizer.state {
        case .began:
            // Save the current scale & translation
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
            // Get midpoint of the two touches in screen coords
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
            
            // Convert midpoint to data coordinates
            initialPinchAnchorData = renderer.convertPointToData(location,
                                                                 viewSize: chartView.bounds.size)
            
        case .changed:
            guard let anchorData = initialPinchAnchorData else { return }
            
            // Calculate the new scale
            let pinchScale = Float(recognizer.scale)
            let newScale   = baseScale * pinchScale
            
            // 1) Determine where the anchor was on screen at the *start* of pinch
            let anchorOldScreen = anchorScreenCoord(
                renderer: renderer,
                dataCoord: anchorData,
                scale: baseScale,
                translation: baseTranslation,
                in: chartView
            )
            
            // 2) If we only updated the scale (but not translation), where would
            //    that same data point end up on screen now?
            let anchorNewScreen = anchorScreenCoord(
                renderer: renderer,
                dataCoord: anchorData,
                scale: newScale,
                translation: baseTranslation,
                in: chartView
            )
            
            // 3) The difference is how far the anchor would "drift" on screen
            let dxScreen = anchorOldScreen.x - anchorNewScreen.x
            let dyScreen = anchorOldScreen.y - anchorNewScreen.y
            
            // 4) Convert that screen offset to NDC offset
            let ndcDx = Float(dxScreen / chartView.bounds.width)  * 2.0
            let ndcDy = -Float(dyScreen / chartView.bounds.height) * 2.0
            
            // 5) Apply the new scale + the needed translation offset
            renderer.scale = newScale
            renderer.translation.x = baseTranslation.x + ndcDx
            renderer.translation.y = baseTranslation.y + ndcDy
            
            renderer.updateTransform()
            
        case .ended, .cancelled:
            // Update base scale/translation for the next gesture
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            initialPinchAnchorData = nil
            
        default:
            break
        }
    }
    
    /// Given a data coordinate and a hypothetical (scale, translation),
    /// returns where that data point would appear on screen.
    private func anchorScreenCoord(
        renderer: MetalChartRenderer,
        dataCoord: SIMD2<Float>,
        scale: Float,
        translation: SIMD2<Float>,
        in chartView: UIView
    ) -> CGPoint {
        // Save real scale & translation
        let oldScale = renderer.scale
        let oldTrans = renderer.translation

        // Temporarily override
        renderer.scale = scale
        renderer.translation = translation
        
        // Convert data -> screen
        let screenPt = renderer.convertDataToPoint(dataCoord, viewSize: chartView.bounds.size)
        
        // Restore real scale & translation
        renderer.scale = oldScale
        renderer.translation = oldTrans
        
        return screenPt
    }

    // MARK: - Double Tap (Zoom In)
    
    /// Handles double-tap to zoom in around the tap location.
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        if recognizer.state == .ended {
            // Store current values
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
            // Calculate tap location in NDC
            let location = recognizer.location(in: chartView)
            let anchorNDC = renderer.convertPointToNDC(location, viewSize: chartView.bounds.size)
            
            // Reset to base values
            renderer.scale = baseScale
            renderer.translation = baseTranslation
            
            // Apply zoom
            let newScale = baseScale * doubleTapZoomFactor
            let scaleRatio = newScale / baseScale
            
            // Adjust translation to anchor at tap point
            renderer.translation.x -= anchorNDC.x * (scaleRatio - 1)
            renderer.translation.y -= anchorNDC.y * (scaleRatio - 1)
            
            renderer.scale = newScale
            renderer.updateTransform()
            
            // Update base values
            baseScale = newScale
            baseTranslation = renderer.translation
        }
    }
}
