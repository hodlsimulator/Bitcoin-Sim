//
//  MetalChartGestureCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based approach with corrected function labels.
//  Full file, no placeholders/truncations.
//

import Foundation
import UIKit

class MetalChartGestureCoordinator: NSObject {
    
    private let idleManager: IdleManager
    
    // Base values for gestures
    private var baseOffsetX: Float = 0
    private var baseOffsetY: Float = 0
    private var baseScale: Float = 1.0
    
    // For double-tap-slide
    private var baseScaleX: Float = 1.0
    private var baseScaleY: Float = 1.0
    private var doubleTapSlideStartPoint: CGPoint = .zero
    private let doubleTapSlideSensitivity: CGFloat = 0.01
    private let doubleTapZoomFactor: Float = 1.5
    
    // For pinch anchor
    private var pinchAnchorDomainX: Float?
    private var pinchAnchorDomainY: Float?
    
    // For trackpad two-finger zoom
    private var baseScaleForTwoFingerPan: Float = 1.0
    private let twoFingerZoomFactor: Float = 0.005
    
    init(idleManager: IdleManager) {
        self.idleManager = idleManager
        super.init()
    }
    
    @objc func resetIdleTimer() {
        print("Gesture triggered, resetting idle timer now.")
        idleManager.resetIdleTimer()
    }
}

// MARK: - UIGestureRecognizerDelegate
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
    
    // MARK: Single-Finger Pan
    @objc func handleSingleFingerPan(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            baseOffsetX = renderer.offsetX
            baseOffsetY = renderer.offsetY
            
        case .changed:
            let translation = recognizer.translation(in: chartView)
            
            // domainPerPixel for X
            let domainWidth = renderer.domainMaxX - renderer.domainMinX
            let visibleWidth = domainWidth / renderer.chartScale
            let domainPerPixelX = visibleWidth / Float(chartView.bounds.width)
            
            // domainPerPixel for Y
            let domainHeight = renderer.domainMaxY - renderer.domainMinY
            let visibleHeight = domainHeight / renderer.chartScale
            let domainPerPixelY = visibleHeight / Float(chartView.bounds.height)
            
            // Pan in domain space
            let dxInDomain = Float(translation.x) * domainPerPixelX
            let dyInDomain = Float(translation.y) * domainPerPixelY
            
            // Negative for x if dragging to the right => offset goes up, or adjust sign as needed
            renderer.offsetX = baseOffsetX - dxInDomain
            // Typically "up" drag => offsetY increases, but see what you prefer
            renderer.offsetY = baseOffsetY + dyInDomain
            
            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()
            
        case .ended, .cancelled:
            break
        default:
            break
        }
    }
    
    // MARK: Pinch
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            baseScale = renderer.chartScale
            
            // If 2 touches, anchor in domain coords
            if recognizer.numberOfTouches >= 2 {
                let pt1 = recognizer.location(ofTouch: 0, in: chartView)
                let pt2 = recognizer.location(ofTouch: 1, in: chartView)
                let midX = (pt1.x + pt2.x) * 0.5
                let midY = (pt1.y + pt2.y) * 0.5
                
                let domainCoord = renderer.screenToDomain(CGPoint(x: midX, y: midY),
                                                          viewSize: chartView.bounds.size)
                pinchAnchorDomainX = domainCoord.x
                pinchAnchorDomainY = domainCoord.y
            } else {
                pinchAnchorDomainX = nil
                pinchAnchorDomainY = nil
            }
            
        case .changed:
            let scaleDelta = Float(recognizer.scale)
            let newScale   = baseScale * scaleDelta
            
            // clamp
            let minScale: Float = 0.5
            let maxScale: Float = 100.0
            let clampedScale = max(minScale, min(maxScale, newScale))
            renderer.chartScale = clampedScale
            
            // If anchor, keep it on-screen
            if let ax = pinchAnchorDomainX, let ay = pinchAnchorDomainY {
                preserveDomainPointOnScreen(renderer: renderer,
                                            domainX: ax,
                                            domainY: ay,
                                            oldScale: baseScale,
                                            newScale: clampedScale,
                                            view: chartView)
            }
            
            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()
            
        case .ended, .cancelled:
            pinchAnchorDomainX = nil
            pinchAnchorDomainY = nil
            
        default:
            break
        }
    }
    
    // MARK: Double Tap
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        idleManager.resetIdleTimer()
        
        if recognizer.state == .ended {
            let location = recognizer.location(in: chartView)
            let domainCoord = renderer.screenToDomain(location, viewSize: chartView.bounds.size)
            
            let oldScale = renderer.chartScale
            let newScale = oldScale * doubleTapZoomFactor
            
            let minScale: Float = 0.5
            let maxScale: Float = 100.0
            let clampedScale = max(minScale, min(maxScale, newScale))
            renderer.chartScale = clampedScale
            
            preserveDomainPointOnScreen(renderer: renderer,
                                        domainX: domainCoord.x,
                                        domainY: domainCoord.y,
                                        oldScale: oldScale,
                                        newScale: clampedScale,
                                        view: chartView)
            
            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()
        }
    }
    
    // MARK: Double-Tap-Slide
    @objc func handleDoubleTapSlide(_ recognizer: UILongPressGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            baseScaleX = renderer.chartScale
            baseScaleY = renderer.chartScale
            doubleTapSlideStartPoint = recognizer.location(in: chartView)
            
        case .changed:
            let currentPoint = recognizer.location(in: chartView)
            let dy = currentPoint.y - doubleTapSlideStartPoint.y
            let dx = currentPoint.x - doubleTapSlideStartPoint.x
            
            // Single scale approach
            if abs(dy) > abs(dx) {
                let factorY = 1.0 + (-dy * doubleTapSlideSensitivity)
                let rawScale = baseScaleY * Float(factorY)
                let minScale: Float = 0.5
                let maxScale: Float = 100.0
                renderer.chartScale = max(minScale, min(maxScale, rawScale))
            } else {
                let factorX = 1.0 + (dx * doubleTapSlideSensitivity)
                let rawScale = baseScaleX * Float(factorX)
                let minScale: Float = 0.5
                let maxScale: Float = 100.0
                renderer.chartScale = max(minScale, min(maxScale, rawScale))
            }
            
            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()
            
        default:
            break
        }
    }
    
    // MARK: Two-Finger Pan (Trackpad Zoom)
    @objc func handleTwoFingerPanToZoom(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        
        guard recognizer.numberOfTouches == 2 else { return }
        
        idleManager.resetIdleTimer()
        
        switch recognizer.state {
        case .began:
            baseScaleForTwoFingerPan = renderer.chartScale
            
        case .changed:
            let translation = recognizer.translation(in: chartView)
            let deltaY = Float(-translation.y)
            let factor = 1.0 + (deltaY * twoFingerZoomFactor)
            let rawScale = baseScaleForTwoFingerPan * factor
            
            let minScale: Float = 0.5
            let maxScale: Float = 100.0
            renderer.chartScale = max(minScale, min(maxScale, rawScale))
            
            // zoom about midpoint
            let t0 = recognizer.location(ofTouch: 0, in: chartView)
            let t1 = recognizer.location(ofTouch: 1, in: chartView)
            let mx = (t0.x + t1.x) * 0.5
            let my = (t0.y + t1.y) * 0.5
            
            let dom = renderer.screenToDomain(CGPoint(x: mx, y: my), viewSize: chartView.bounds.size)
            
            preserveDomainPointOnScreen(renderer: renderer,
                                        domainX: dom.x,
                                        domainY: dom.y,
                                        oldScale: baseScaleForTwoFingerPan,
                                        newScale: renderer.chartScale,
                                        view: chartView)
            
            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()
            
        default:
            break
        }
    }
}

// MARK: - Private Helpers
extension MetalChartGestureCoordinator {
    
    /// Keep (domainX, domainY) at same screen position when scale changes
    private func preserveDomainPointOnScreen(
        renderer: MetalChartRenderer,
        domainX: Float,
        domainY: Float,
        oldScale: Float,
        newScale: Float,
        view: UIView
    ) {
        // old visible
        let fullW = renderer.domainMaxX - renderer.domainMinX
        let oldVisW = fullW / oldScale
        
        let fullH = renderer.domainMaxY - renderer.domainMinY
        let oldVisH = fullH / oldScale
        
        let fracX = (domainX - renderer.offsetX) / oldVisW
        let fracY = (domainY - renderer.offsetY) / oldVisH
        
        // new visible
        let newVisW = fullW / newScale
        let newVisH = fullH / newScale
        
        let newOffsetX = domainX - fracX * newVisW
        let newOffsetY = domainY - fracY * newVisH
        
        renderer.offsetX = newOffsetX
        renderer.offsetY = newOffsetY
    }
    
    /// Ensure offsetX >= 0, offsetY >= 0, etc. so no negative domain.
    private func clampOffsets(renderer: MetalChartRenderer, view: UIView) {
        let fullW = renderer.domainMaxX - renderer.domainMinX
        let visW = fullW / renderer.chartScale
        
        if renderer.offsetX < 0 {
            renderer.offsetX = 0
        }
        let maxOffX = renderer.domainMaxX - visW
        if maxOffX > 0, renderer.offsetX > maxOffX {
            renderer.offsetX = maxOffX
        }
        
        let fullH = renderer.domainMaxY - renderer.domainMinY
        let visH = fullH / renderer.chartScale
        
        if renderer.offsetY < 0 {
            renderer.offsetY = 0
        }
        let maxOffY = renderer.domainMaxY - visH
        if maxOffY > 0, renderer.offsetY > maxOffY {
            renderer.offsetY = maxOffY
        }
    }
}
