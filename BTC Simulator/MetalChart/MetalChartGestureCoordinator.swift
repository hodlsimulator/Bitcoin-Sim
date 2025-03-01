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
    private let idleManager: IdleManager // Use 'let' since it won’t change after initialization

    // Initializer to accept idleManager from MetalChartContainerView
    init(idleManager: IdleManager) {
        self.idleManager = idleManager
        super.init()
    }

    // Method for gesture recognizers to reset the idle timer
    @objc func resetIdleTimer() {
        idleManager.resetIdleTimer()
    }

    // Existing properties (unchanged)
    private var baseScale: Float = 1.0
    private var baseTranslation = SIMD2<Float>(0, 0)
    private var baseScaleForTwoFingerPan: Float = 1.0
    private var initialPinchAnchorData: SIMD2<Float>?
    private var baseScaleX: Float = 1.0
    private var baseScaleY: Float = 1.0
    private var doubleTapSlideStartPoint: CGPoint = .zero
    private let doubleTapSlideSensitivity: CGFloat = 0.01
    private let doubleTapZoomFactor: Float = 1.5
    private let twoFingerZoomFactor: Float = 0.005
}

// MARK: - New Double-Tap-Slide
extension MetalChartGestureCoordinator {
    
    /// Called when the user double-taps and immediately slides up or down to
    /// scale the y-axis or x-axis.
    @objc func handleDoubleTapSlide(_ recognizer: UILongPressGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        // Reset the idle timer whenever there's gesture interaction
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            // Store the initial scale
            baseScaleX = renderer.scaleX
            baseScaleY = renderer.scaleY
            
            // Where did the user first press?
            doubleTapSlideStartPoint = recognizer.location(in: chartView)
            
        case .changed:
            // Current finger location
            let currentPoint = recognizer.location(in: chartView)
            
            // We'll do an example: vertical movement => scale Y, horizontal => scale X
            let dy = currentPoint.y - doubleTapSlideStartPoint.y
            let dx = currentPoint.x - doubleTapSlideStartPoint.x
            
            let factorY = 1.0 + (-dy * doubleTapSlideSensitivity)
            let newScaleY = max(0.0001, baseScaleY * Float(factorY))
            
            let factorX = 1.0 + (dx * doubleTapSlideSensitivity)
            let newScaleX = max(0.0001, baseScaleX * Float(factorX))
            
            // Decide if you want to scale only Y or only X or both
            if abs(dy) > abs(dx) {
                renderer.scaleY = newScaleY
            } else {
                renderer.scaleX = newScaleX
            }
            
            renderer.updateTransform()
            
        case .ended, .cancelled:
            renderer.anchorEdges()
            
        default:
            break
        }
    }
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
        print("Tap/pan recognized!")
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        let translationPoint = recognizer.translation(in: chartView)
        
        // Reset the idle timer whenever there's gesture interaction
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
        case .changed:
            renderer.scale = baseScale
            renderer.translation = baseTranslation
            
            let dx = Float(translationPoint.x / chartView.bounds.width) * 2.0
            let dy = Float(translationPoint.y / chartView.bounds.height) * 2.0
            
            renderer.translation.x += dx
            renderer.translation.y -= dy
            renderer.updateTransform()
            
        case .ended, .cancelled:
            renderer.anchorEdges()
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
        
        // Reset the idle timer whenever there's gesture interaction
        idleManager.resetIdleTimer()
        
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
            renderer.anchorEdges()
            
        default:
            break
        }
    }
    
    // MARK: Pinch
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        // Reset the idle timer whenever there's gesture interaction
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            baseScale = renderer.scale
            baseTranslation = renderer.translation
            
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
        
        renderer.scale = scale
        renderer.translation = translation
        
        let screenPt = renderer.convertDataToPoint(dataCoord, viewSize: chartView.bounds.size)
        
        renderer.scale = oldScale
        renderer.translation = oldTrans
        
        return screenPt
    }
    
    // MARK: Double Tap
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        // Reset the idle timer whenever there's gesture interaction
        idleManager.resetIdleTimer()
        
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
            
            renderer.anchorEdges()
            
            baseScale = newScale
            baseTranslation = renderer.translation
        }
    }
}
