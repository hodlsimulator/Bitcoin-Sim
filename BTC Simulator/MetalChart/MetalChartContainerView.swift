//
//  MetalChartContainerView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import SwiftUI
import UIKit
import MetalKit

/// A UIViewRepresentable that hosts our Metal chart and adds custom UIKit gestures.
struct MetalChartContainerView: UIViewRepresentable {
    let metalChart: MetalChartRenderer
    
    func makeUIView(context: Context) -> MetalChartUIView {
        let metalView = MetalChartUIView(frame: .zero, renderer: metalChart)
        let coordinator = context.coordinator
        
        //
        // 1) Single-finger pan gesture
        //
        let singleFingerPan = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleSingleFingerPan(_:))
        )
        // Restrict it to exactly one finger
        singleFingerPan.maximumNumberOfTouches = 1
        
        //
        // 2) Two-finger pan for trackpad-like zoom
        //
        let twoFingerPan = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleTwoFingerPanToZoom(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        
        //
        // 3) Pinch to zoom
        //
        let pinchGR = UIPinchGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handlePinch(_:))
        )
        
        //
        // 4) Double-tap to zoom
        //
        let doubleTapGR = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleDoubleTap(_:))
        )
        doubleTapGR.numberOfTapsRequired = 2
        
        //
        // 5) Double-tap-and-slide (long press, 2 taps, zero duration)
        //
        let doubleTapSlideGR = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleDoubleTapSlide(_:))
        )
        doubleTapSlideGR.numberOfTapsRequired = 2
        doubleTapSlideGR.minimumPressDuration = 0 // triggers immediately on second tap
        
        //
        // Allow them to recognize simultaneously
        //
        coordinator.configureRecognizerForSimultaneous(singleFingerPan)
        coordinator.configureRecognizerForSimultaneous(twoFingerPan)
        coordinator.configureRecognizerForSimultaneous(pinchGR)
        coordinator.configureRecognizerForSimultaneous(doubleTapGR)
        coordinator.configureRecognizerForSimultaneous(doubleTapSlideGR)
        
        // Add them all
        metalView.addGestureRecognizer(singleFingerPan)
        metalView.addGestureRecognizer(twoFingerPan)
        metalView.addGestureRecognizer(pinchGR)
        metalView.addGestureRecognizer(doubleTapGR)
        metalView.addGestureRecognizer(doubleTapSlideGR)
        
        return metalView
    }
    
    func updateUIView(_ uiView: MetalChartUIView, context: Context) {
        // Update if needed, e.g. pass new data or settings to uiView.renderer
    }
    
    func makeCoordinator() -> MetalChartGestureCoordinator {
        MetalChartGestureCoordinator()
    }
}
