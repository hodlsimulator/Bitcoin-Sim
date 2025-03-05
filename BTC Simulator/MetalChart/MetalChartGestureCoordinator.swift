//
//  MetalChartGestureCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based approach with corrected function labels.
//  Single-finger pan with inertia, plus two-finger pinch+pan simultaneously.
//  Revised to reduce "jumping" when pinch & zoom starts/ends with smooth blending and animation cleanup.
//  Enhanced for smoother transitions by anchoring zoom deceleration to the final pinch midpoint.
//

import Foundation
import UIKit

class MetalChartGestureCoordinator: NSObject {

    private let idleManager: IdleManager

    // MARK: - Single-Finger Pan / Inertia
    private var baseOffsetX: Float = 0
    private var baseOffsetY: Float = 0
    // Store finger’s domain coords at the start of the pan
    private var panStartDomainX: Float = 0
    private var panStartDomainY: Float = 0

    private var decelerationDisplayLink: CADisplayLink?
    private var decelerationVelocityX: Float = 0
    private var decelerationVelocityY: Float = 0
    private var isDecelerating: Bool = false
    private let decelerationRate: Float = 0.90
    private weak var chartViewForDeceleration: MetalChartUIView?

    // MARK: - Two-Finger Pinch+Pan
    /// Stores the scale at pinch start
    private var pinchBaseScale: Float = 1.0
    /// Domain coords of the initial pinch midpoint
    private var pinchBaseMidDomainX: Float = 0
    private var pinchBaseMidDomainY: Float = 0
    /// Lower => slower (more precise) zoom
    private let pinchSensitivity: Float = 0.5

    // Smooth transition for quick repeated pinches
    /// Track the last pinch midpoint to gently transition
    private var lastPinchMidX: Float = 0
    private var lastPinchMidY: Float = 0
    private var lastPinchTime: TimeInterval = 0
    /// If a new pinch occurs quickly (e.g., within 0.2s), smoothly blend anchors
    private let pinchReentryThreshold: TimeInterval = 0.2

    // MARK: - Zoom Deceleration
    private var zoomDecelerationDisplayLink: CADisplayLink?
    private var zoomDecelerationVelocity: Float = 0
    private var isZoomDecelerating: Bool = false
    private let zoomDecelerationRate: Float = 0.95
    private weak var chartViewForZoomDeceleration: MetalChartUIView?

    // MARK: - Double-Tap Smooth Zoom
    private var zoomAnimationDisplayLink: CADisplayLink?
    private var zoomAnimationStartTime: CFTimeInterval = 0
    private var zoomAnimationDuration: CFTimeInterval = 0.25
    private var initialScaleForZoomAnimation: Float = 1
    private var targetScaleForZoomAnimation: Float = 1
    private var zoomAnchorX: Float = 0
    private var zoomAnchorY: Float = 0
    private weak var chartViewForZoom: MetalChartUIView?

    // MARK: - Double-Tap-Slide
    private var baseScale: Float = 1.0
    private var doubleTapSlideStartPoint: CGPoint = .zero
    private let doubleTapSlideSensitivity: CGFloat = 0.01

    // MARK: - Basic Limits
    private let minScale: Float = 0.5
    private let maxScale: Float = 100.0

    // MARK: - Trackpad pinch-to-zoom
    private var baseScaleForTwoFingerPan: Float = 1.0
    private let twoFingerZoomFactor: Float = 0.005

    // MARK: - Double-Tap Zoom Factor
    private let doubleTapZoomFactor: Float = 1.5

    // MARK: - Final Pinch Midpoint for Deceleration
    private var finalPinchMidScreenX: Float = 0
    private var finalPinchMidScreenY: Float = 0
    private var finalPinchDomainX: Float = 0
    private var finalPinchDomainY: Float = 0
    
    private var panStartScreenPt: CGPoint = .zero

    init(idleManager: IdleManager) {
        self.idleManager = idleManager
        super.init()
    }

    @objc func resetIdleTimer() {
        idleManager.resetIdleTimer()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MetalChartGestureCoordinator: UIGestureRecognizerDelegate {
    func configureRecognizerForSimultaneous(_ recognizer: UIGestureRecognizer) {
        recognizer.delegate = self
    }

    /// Decide which gestures can run simultaneously. If you want to avoid
    /// conflicts, you can fine-tune logic here.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Gesture Handlers
extension MetalChartGestureCoordinator {

    // MARK: Single-Finger Pan (domain-based)
    /// In handleSingleFingerPan, store velocities and no clamp calls there
    @objc func handleSingleFingerPan(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer

        switch recognizer.state {
        case .began:
            // Stop all ongoing animations to prevent interference
            stopAllAnimations()
            
            // Save offsets + initial finger position
            baseOffsetX = renderer.offsetX
            baseOffsetY = renderer.offsetY
            panStartScreenPt = recognizer.location(in: chartView)

        case .changed:
            let currentPt = recognizer.location(in: chartView)
            let dxPx = Float(currentPt.x - panStartScreenPt.x)
            let dyPx = Float(currentPt.y - panStartScreenPt.y)

            // Convert pixel dx/dy to domain offsets
            let domainW = renderer.domainMaxX - renderer.domainMinX
            let visW = domainW / renderer.chartScale
            let domainPerPxX = visW / Float(chartView.bounds.width)

            let domainH = renderer.domainMaxY - renderer.domainMinY
            let visH = domainH / renderer.chartScale
            let domainPerPxY = visH / Float(chartView.bounds.height)

            renderer.offsetX = baseOffsetX - (dxPx * domainPerPxX)
            renderer.offsetY = baseOffsetY + (dyPx * domainPerPxY)

            renderer.updateOrthographic()

        case .ended, .cancelled:
            let velocityPoints = recognizer.velocity(in: chartView)
            let domainW = renderer.domainMaxX - renderer.domainMinX
            let visW = domainW / renderer.chartScale
            let domainPerPxX = visW / Float(chartView.bounds.width)

            let domainH = renderer.domainMaxY - renderer.domainMinY
            let visH = domainH / renderer.chartScale
            let domainPerPxY = visH / Float(chartView.bounds.height)

            decelerationVelocityX = -Float(velocityPoints.x) * domainPerPxX
            decelerationVelocityY = Float(velocityPoints.y) * domainPerPxY

            startDeceleration()

        default:
            break
        }
    }

    // MARK: Two-Finger Pinch+Pan (Apple Maps style)
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        idleManager.resetIdleTimer()

        switch recognizer.state {
        case .began:
            // Stop all ongoing animations for a clean start
            stopAllAnimations()
            
            let currentTime = CACurrentMediaTime()
            let timeDiff = currentTime - lastPinchTime
            let blendFactor = min(1.0, timeDiff / pinchReentryThreshold)
            let blendAlpha = Float(blendFactor)

            let midScreen = midpointOfTouches(recognizer, in: chartView)
            let dom = renderer.screenToDomain(midScreen, viewSize: chartView.bounds.size)

            pinchBaseMidDomainX = (Float(dom.x) * blendAlpha) + (lastPinchMidX * (1.0 - blendAlpha))
            pinchBaseMidDomainY = (Float(dom.y) * blendAlpha) + (lastPinchMidY * (1.0 - blendAlpha))

            pinchBaseScale = renderer.chartScale
            recognizer.scale = 1.0

        case .changed:
            applyPinchZoom(recognizer, chartView: chartView)

        case .ended, .cancelled:
            applyPinchZoom(recognizer, chartView: chartView)

            let finalMidScreen = midpointOfTouches(recognizer, in: chartView)
            finalPinchMidScreenX = Float(finalMidScreen.x)
            finalPinchMidScreenY = Float(finalMidScreen.y)
            finalPinchDomainX = pinchBaseMidDomainX
            finalPinchDomainY = pinchBaseMidDomainY

            let velocity = Float(recognizer.velocity)
            if abs(velocity) > 0.1 {
                startZoomDeceleration(withVelocity: velocity, chartView: chartView)
            }
            lastPinchMidX = pinchBaseMidDomainX
            lastPinchMidY = pinchBaseMidDomainY
            lastPinchTime = CACurrentMediaTime()

        default:
            break
        }
    }

    private func applyPinchZoom(_ recognizer: UIPinchGestureRecognizer, chartView: MetalChartUIView) {
        let renderer = chartView.renderer
        let rawPinch = Float(recognizer.scale) - 1.0
        let scaledPinch = rawPinch * pinchSensitivity
        let finalFactor = 1.0 + scaledPinch

        let proposedScale = pinchBaseScale * finalFactor
        let newScale = clamp(proposedScale, minScale, maxScale)
        renderer.chartScale = newScale

        let midScreen = midpointOfTouches(recognizer, in: chartView)
        let fullW = renderer.domainMaxX - renderer.domainMinX
        let fullH = renderer.domainMaxY - renderer.domainMinY
        let visW_new = fullW / newScale
        let visH_new = fullH / newScale

        let fracX = Float(midScreen.x) / Float(chartView.bounds.width)
        let fracY = Float(midScreen.y) / Float(chartView.bounds.height)

        renderer.offsetX = pinchBaseMidDomainX - fracX * visW_new
        renderer.offsetY = pinchBaseMidDomainY - fracY * visH_new

        clampOffsets(renderer: renderer, view: chartView)
        renderer.updateOrthographic()
    }

    // MARK: Double Tap (Smooth Zoom)
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer

        idleManager.resetIdleTimer()

        if recognizer.state == .ended {
            // Stop only zoom deceleration and zoom animation so double-tap can override them.
            if isZoomDecelerating {
                stopZoomDeceleration()
            }
            stopZoomAnimation()

            let location = recognizer.location(in: chartView)
            let domainCoord = renderer.screenToDomain(location, viewSize: chartView.bounds.size)

            let oldScale = renderer.chartScale
            let desiredScale = oldScale * doubleTapZoomFactor
            let clampedScale = clamp(desiredScale, minScale, maxScale)

            animateZoom(
                from: oldScale,
                to: clampedScale,
                anchorDomainX: Float(domainCoord.x),
                anchorDomainY: Float(domainCoord.y),
                duration: 0.25,
                chartView: chartView
            )
        }
    }

    // MARK: Double-Tap-Slide
    @objc func handleDoubleTapSlide(_ recognizer: UILongPressGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer

        idleManager.resetIdleTimer()

        switch recognizer.state {
        case .began:
            // Stop only zoom deceleration and zoom animation; keep pan deceleration alive.
            if isZoomDecelerating {
                stopZoomDeceleration()
            }
            stopZoomAnimation()

            baseScale = renderer.chartScale
            doubleTapSlideStartPoint = recognizer.location(in: chartView)

        case .changed:
            let currentPoint = recognizer.location(in: chartView)
            let dy = currentPoint.y - doubleTapSlideStartPoint.y

            let factor = 1.0 + (-dy * doubleTapSlideSensitivity)
            let rawScale = baseScale * Float(factor)
            let clamped = clamp(rawScale, minScale, maxScale)
            renderer.chartScale = clamped

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
            // Stop only zoom deceleration and zoom animation; keep pan deceleration alive.
            if isZoomDecelerating {
                stopZoomDeceleration()
            }
            stopZoomAnimation()

            baseScaleForTwoFingerPan = renderer.chartScale

        case .changed:
            let translation = recognizer.translation(in: chartView)
            let deltaY = Float(-translation.y)
            let factor = 1.0 + (deltaY * twoFingerZoomFactor)
            let rawScale = baseScaleForTwoFingerPan * factor
            let clampedScale = clamp(rawScale, minScale, maxScale)
            renderer.chartScale = clampedScale

            let t0 = recognizer.location(ofTouch: 0, in: chartView)
            let t1 = recognizer.location(ofTouch: 1, in: chartView)
            let mx = (t0.x + t1.x) * 0.5
            let my = (t0.y + t1.y) * 0.5

            let dom = renderer.screenToDomain(CGPoint(x: mx, y: my), viewSize: chartView.bounds.size)
            preserveDomainPointOnScreen(
                renderer: renderer,
                domainX: Float(dom.x),
                domainY: Float(dom.y),
                oldScale: baseScaleForTwoFingerPan,
                newScale: renderer.chartScale,
                view: chartView
            )

            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()

        default:
            break
        }
    }
}

// MARK: - Private / Shared Helpers
extension MetalChartGestureCoordinator {

    private func clamp(_ value: Float, _ minVal: Float, _ maxVal: Float) -> Float {
        return max(minVal, min(maxVal, value))
    }

    private func midpointOfTouches(_ recognizer: UIGestureRecognizer, in view: UIView) -> CGPoint {
        guard recognizer.numberOfTouches > 0 else { return .zero }
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        let count = recognizer.numberOfTouches
        for i in 0..<count {
            let pt = recognizer.location(ofTouch: i, in: view)
            sumX += pt.x
            sumY += pt.y
        }
        return CGPoint(x: sumX / CGFloat(count), y: sumY / CGFloat(count))
    }

    private func clampOffsets(renderer: MetalChartRenderer, view: UIView) {
        let fullW = renderer.domainMaxX - renderer.domainMinX
        let visW = fullW / renderer.chartScale

        let oldOffsetX = renderer.offsetX
        if renderer.offsetX < 0 {
            renderer.offsetX = 0
        }
        let maxOffX = renderer.domainMaxX - visW
        if maxOffX > 0, renderer.offsetX > maxOffX {
            renderer.offsetX = maxOffX
        }

        let fullH = renderer.domainMaxY - renderer.domainMinY
        let visH = fullH / renderer.chartScale

        let oldOffsetY = renderer.offsetY
        if renderer.offsetY < 0 {
            renderer.offsetY = 0
        }
        let maxOffY = renderer.domainMaxY - visH
        if maxOffY > 0, renderer.offsetY > maxOffY {
            renderer.offsetY = maxOffY
        }

        // DEBUG: show if offsets got clamped
        if oldOffsetX != renderer.offsetX || oldOffsetY != renderer.offsetY {
        }
    }

    private func stopAllAnimations() {
        stopDeceleration()
        stopZoomDeceleration()
        stopZoomAnimation()
    }
}

// MARK: - Inertia Deceleration
extension MetalChartGestureCoordinator {

    private func startDeceleration() {
        guard !isDecelerating else { return }
        isDecelerating = true

        decelerationDisplayLink = CADisplayLink(target: self, selector: #selector(handleDecelerationTick))
        decelerationDisplayLink?.add(to: .current, forMode: .common)
    }

    private func stopDeceleration() {
        isDecelerating = false
        decelerationDisplayLink?.invalidate()
        decelerationDisplayLink = nil
    }

    // Now the deceleration tick, which clamps + kills velocity if out of range
    @objc private func handleDecelerationTick() {
        guard let chartView = chartViewForDeceleration else {
            stopDeceleration()
            return
        }
        let renderer = chartView.renderer
        
        // 1) figure out next offsets
        let wantedX = renderer.offsetX + decelerationVelocityX
        let wantedY = renderer.offsetY + decelerationVelocityY
        
        // 2) decay velocity
        decelerationVelocityX *= decelerationRate
        decelerationVelocityY *= decelerationRate
        
        // 3) compute min/max offset
        let domainW = renderer.domainMaxX - renderer.domainMinX
        let visW = domainW / renderer.chartScale
        let minX: Float = 0
        let maxX = max(0, renderer.domainMaxX - visW)

        let domainH = renderer.domainMaxY - renderer.domainMinY
        let visH = domainH / renderer.chartScale
        let minY: Float = 0
        let maxY = max(0, renderer.domainMaxY - visH)

        // 4) clamp + kill velocity if we clamp
        if wantedX < minX {
            renderer.offsetX = minX
            decelerationVelocityX = 0
        } else if wantedX > maxX {
            renderer.offsetX = maxX
            decelerationVelocityX = 0
        } else {
            renderer.offsetX = wantedX
        }

        if wantedY < minY {
            renderer.offsetY = minY
            decelerationVelocityY = 0
        } else if wantedY > maxY {
            renderer.offsetY = maxY
            decelerationVelocityY = 0
        } else {
            renderer.offsetY = wantedY
        }

        // 5) apply
        renderer.updateOrthographic()
        
        // 6) stop if velocity is very small
        let speed = sqrt(decelerationVelocityX * decelerationVelocityX +
                         decelerationVelocityY * decelerationVelocityY)
        if speed < 0.001 {
            stopDeceleration()
        }
    }

    private func clampToDomainX(_ x: Float, renderer: MetalChartRenderer, view: UIView) -> Float {
        // For example, you can do something like this:
        let domainWidth = renderer.domainMaxX - renderer.domainMinX
        let visibleWidth = domainWidth / renderer.chartScale
        let minX: Float = 0
        let maxX = max(0, renderer.domainMaxX - visibleWidth)
        return max(minX, min(maxX, x))
    }

    private func clampToDomainY(_ y: Float, renderer: MetalChartRenderer, view: UIView) -> Float {
        let domainHeight = renderer.domainMaxY - renderer.domainMinY
        let visibleHeight = domainHeight / renderer.chartScale
        let minY: Float = 0
        let maxY = max(0, renderer.domainMaxY - visibleHeight)
        return max(minY, min(maxY, y))
    }
}

// MARK: - Zoom Deceleration
extension MetalChartGestureCoordinator {

    private func startZoomDeceleration(withVelocity velocity: Float, chartView: MetalChartUIView) {
        guard !isZoomDecelerating else { return }
        isZoomDecelerating = true
        zoomDecelerationVelocity = velocity
        chartViewForZoomDeceleration = chartView
        zoomDecelerationDisplayLink = CADisplayLink(target: self, selector: #selector(handleZoomDecelerationTick))
        zoomDecelerationDisplayLink?.add(to: .current, forMode: .common)
    }

    private func stopZoomDeceleration() {
        isZoomDecelerating = false
        zoomDecelerationDisplayLink?.invalidate()
        zoomDecelerationDisplayLink = nil
    }

    @objc private func handleZoomDecelerationTick() {
        guard let chartView = chartViewForZoomDeceleration else {
            stopZoomDeceleration()
            return
        }

        let renderer = chartView.renderer
        let dt = Float(zoomDecelerationDisplayLink?.duration ?? 0.016)
        let dScale = zoomDecelerationVelocity * dt
        let oldScale = renderer.chartScale
        let newScale = oldScale * (1.0 + dScale)
        let clampedScale = clamp(newScale, minScale, maxScale)
        renderer.chartScale = clampedScale

        let fullW = renderer.domainMaxX - renderer.domainMinX
        let visW_new = fullW / clampedScale
        let fracX = finalPinchMidScreenX / Float(chartView.bounds.width)
        renderer.offsetX = finalPinchDomainX - fracX * visW_new

        let fullH = renderer.domainMaxY - renderer.domainMinY
        let visH_new = fullH / clampedScale
        let fracY = finalPinchMidScreenY / Float(chartView.bounds.height)
        renderer.offsetY = finalPinchDomainY - fracY * visH_new

        clampOffsets(renderer: renderer, view: chartView)
        renderer.updateOrthographic()

        zoomDecelerationVelocity *= zoomDecelerationRate
        if abs(zoomDecelerationVelocity) < 0.001 {
            stopZoomDeceleration()
        }
    }
}

// MARK: - Smooth Zoom Animation
extension MetalChartGestureCoordinator {

    private func animateZoom(from oldScale: Float,
                             to newScale: Float,
                             anchorDomainX: Float,
                             anchorDomainY: Float,
                             duration: CFTimeInterval,
                             chartView: MetalChartUIView) {
        stopZoomAnimation()

        chartViewForZoom = chartView
        initialScaleForZoomAnimation = oldScale
        targetScaleForZoomAnimation = newScale
        zoomAnchorX = anchorDomainX
        zoomAnchorY = anchorDomainY
        zoomAnimationDuration = duration
        zoomAnimationStartTime = CACurrentMediaTime()

        zoomAnimationDisplayLink = CADisplayLink(target: self, selector: #selector(handleZoomAnimationTick))
        zoomAnimationDisplayLink?.add(to: .current, forMode: .common)
    }

    private func stopZoomAnimation() {
        zoomAnimationDisplayLink?.invalidate()
        zoomAnimationDisplayLink = nil
    }

    @objc private func handleZoomAnimationTick() {
        guard let chartView = chartViewForZoom else {
            stopZoomAnimation()
            return
        }

        let renderer = chartView.renderer
        let now = CACurrentMediaTime()
        let elapsed = now - zoomAnimationStartTime
        let progress = CGFloat(min(1.0, elapsed / zoomAnimationDuration))

        let currentScale = initialScaleForZoomAnimation
            + Float(progress) * (targetScaleForZoomAnimation - initialScaleForZoomAnimation)

        let oldScale = renderer.chartScale
        renderer.chartScale = currentScale

        preserveDomainPointOnScreen(
            renderer: renderer,
            domainX: zoomAnchorX,
            domainY: zoomAnchorY,
            oldScale: oldScale,
            newScale: currentScale,
            view: chartView
        )

        clampOffsets(renderer: renderer, view: chartView)
        renderer.updateOrthographic()

        if progress >= 1.0 {
            stopZoomAnimation()
        }
    }

    private func preserveDomainPointOnScreen(renderer: MetalChartRenderer,
                                             domainX: Float,
                                             domainY: Float,
                                             oldScale: Float,
                                             newScale: Float,
                                             view: UIView) {
        let fullW = renderer.domainMaxX - renderer.domainMinX
        let oldVisW = fullW / oldScale
        let fracX = (domainX - renderer.offsetX) / oldVisW

        let fullH = renderer.domainMaxY - renderer.domainMinY
        let oldVisH = fullH / oldScale
        let fracY = (domainY - renderer.offsetY) / oldVisH

        let newVisW = fullW / newScale
        let newVisH = fullH / newScale

        let newOffsetX = domainX - fracX * newVisW
        let newOffsetY = domainY - fracY * newVisH

        renderer.offsetX = newOffsetX
        renderer.offsetY = newOffsetY
    }
}
