//
//  MetalChartGestureCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//  Orthographic-based approach with corrected function labels.
//  Single-finger pan with inertia, plus two-finger pinch+pan simultaneously.
//  Revised to reduce "jumping" when pinch & zoom starts/ends.
//

import Foundation
import UIKit

class MetalChartGestureCoordinator: NSObject {

    private let idleManager: IdleManager

    // MARK: - Single-Finger Pan / Inertia
    private var baseOffsetX: Float = 0
    private var baseOffsetY: Float = 0

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

    // MARK: Single-Finger Pan (with inertia)
    @objc func handleSingleFingerPan(_ recognizer: UIPanGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer
        idleManager.resetIdleTimer()

        switch recognizer.state {
        case .began:
            stopDeceleration()
            chartViewForDeceleration = chartView

            baseOffsetX = renderer.offsetX
            baseOffsetY = renderer.offsetY

        case .changed:
            let translation = recognizer.translation(in: chartView)

            let domainWidth = renderer.domainMaxX - renderer.domainMinX
            let visibleWidth = domainWidth / renderer.chartScale
            let domainPerPixelX = visibleWidth / Float(chartView.bounds.width)

            let domainHeight = renderer.domainMaxY - renderer.domainMinY
            let visibleHeight = domainHeight / renderer.chartScale
            let domainPerPixelY = visibleHeight / Float(chartView.bounds.height)

            let dxInDomain = Float(translation.x) * domainPerPixelX
            let dyInDomain = Float(translation.y) * domainPerPixelY

            renderer.offsetX = baseOffsetX - dxInDomain
            renderer.offsetY = baseOffsetY + dyInDomain

            clampOffsets(renderer: renderer, view: chartView)
            renderer.updateOrthographic()

        case .ended, .cancelled:
            let velocity = recognizer.velocity(in: chartView)

            let domainWidth = renderer.domainMaxX - renderer.domainMinX
            let visibleWidth = domainWidth / renderer.chartScale
            let domainPerPixelX = visibleWidth / Float(chartView.bounds.width)

            let domainHeight = renderer.domainMaxY - renderer.domainMinY
            let visibleHeight = domainHeight / renderer.chartScale
            let domainPerPixelY = visibleHeight / Float(chartView.bounds.height)

            decelerationVelocityX = -Float(velocity.x) * domainPerPixelX
            decelerationVelocityY =  Float(velocity.y) * domainPerPixelY

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
            // Reset the gesture scale so it starts at 1.0
            recognizer.scale = 1.0

            // Stop single-finger deceleration if needed
            stopDeceleration()

            // Record starting scale and midpoint
            pinchBaseScale = renderer.chartScale

            let midScreen = midpointOfTouches(recognizer, in: chartView)
            let dom = renderer.screenToDomain(midScreen, viewSize: chartView.bounds.size)
            pinchBaseMidDomainX = dom.x
            pinchBaseMidDomainY = dom.y

        case .changed:
            applyPinchZoom(recognizer, chartView: chartView)

        case .ended, .cancelled:
            // Apply the same pinch logic one last time so there's no jump
            applyPinchZoom(recognizer, chartView: chartView)

        default:
            break
        }
    }

    private func applyPinchZoom(_ recognizer: UIPinchGestureRecognizer, chartView: MetalChartUIView) {
        let renderer = chartView.renderer

        // Convert the total pinch amount to a final multiplier
        let rawPinch = Float(recognizer.scale) - 1.0
        let scaledPinch = rawPinch * pinchSensitivity
        let finalFactor = 1.0 + scaledPinch

        // Proposed scale
        let proposedScale = pinchBaseScale * finalFactor
        let newScale = clamp(proposedScale, minScale, maxScale)
        renderer.chartScale = newScale

        // Keep pinchBaseMidDomain in the same visual midpoint
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
            let location = recognizer.location(in: chartView)
            let domainCoord = renderer.screenToDomain(location, viewSize: chartView.bounds.size)

            let oldScale = renderer.chartScale
            let desiredScale = oldScale * doubleTapZoomFactor
            let clampedScale = clamp(desiredScale, minScale, maxScale)

            animateZoom(from: oldScale,
                        to: clampedScale,
                        anchorDomainX: domainCoord.x,
                        anchorDomainY: domainCoord.y,
                        duration: 0.25,
                        chartView: chartView)
        }
    }

    // MARK: Double-Tap-Slide
    @objc func handleDoubleTapSlide(_ recognizer: UILongPressGestureRecognizer) {
        guard let chartView = recognizer.view as? MetalChartUIView else { return }
        let renderer = chartView.renderer

        idleManager.resetIdleTimer()

        switch recognizer.state {
        case .began:
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

// MARK: - Private / Shared Helpers
extension MetalChartGestureCoordinator {

    private func clamp(_ value: Float, _ minVal: Float, _ maxVal: Float) -> Float {
        return max(minVal, min(maxVal, value))
    }

    /// Returns the average location of all touches, so if it's a 2-finger pinch, it's the midpoint.
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

    @objc private func handleDecelerationTick() {
        guard let chartView = chartViewForDeceleration else {
            stopDeceleration()
            return
        }

        let renderer = chartView.renderer

        renderer.offsetX += decelerationVelocityX
        renderer.offsetY += decelerationVelocityY

        decelerationVelocityX *= decelerationRate
        decelerationVelocityY *= decelerationRate

        clampOffsets(renderer: renderer, view: chartView)
        renderer.updateOrthographic()

        let speed = sqrt(decelerationVelocityX * decelerationVelocityX +
                         decelerationVelocityY * decelerationVelocityY)
        if speed < 0.001 {
            stopDeceleration()
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
                             chartView: MetalChartUIView)
    {
        stopZoomAnimation()

        chartViewForZoom = chartView
        initialScaleForZoomAnimation = oldScale
        targetScaleForZoomAnimation  = newScale
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

        // Linear interpolation
        let currentScale = initialScaleForZoomAnimation
                         + Float(progress) * (targetScaleForZoomAnimation - initialScaleForZoomAnimation)

        let oldScale = renderer.chartScale
        renderer.chartScale = currentScale

        preserveDomainPointOnScreen(renderer: renderer,
                                    domainX: zoomAnchorX,
                                    domainY: zoomAnchorY,
                                    oldScale: oldScale,
                                    newScale: currentScale,
                                    view: chartView)

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
                                             view: UIView)
    {
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
