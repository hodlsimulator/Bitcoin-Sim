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
        // Ensure textRendererManager is available from metalChart
        guard let textRendererManager = metalChart.textRendererManager else {
            fatalError("textRendererManager is nil in metalChart. Please ensure setupMetal() is called correctly.")
        }
        
        // Create MetalChartUIView with all required parameters
        let metalView = MetalChartUIView(frame: .zero, renderer: metalChart, textRendererManager: textRendererManager)
        let coordinator = context.coordinator
        
        // Gesture recognizers setup...
        // 1) Single-finger pan gesture
        let singleFingerPan = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleSingleFingerPan(_:))
        )
        singleFingerPan.maximumNumberOfTouches = 1
        
        // 2) Two-finger pan for trackpad-like zoom
        let twoFingerPan = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleTwoFingerPanToZoom(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        
        // 3) Pinch to zoom
        let pinchGR = UIPinchGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handlePinch(_:))
        )
        
        // 4) Double-tap to zoom
        let doubleTapGR = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleDoubleTap(_:))
        )
        doubleTapGR.numberOfTapsRequired = 2
        
        // 5) Double-tap-and-slide (long press, 2 taps, zero duration)
        let doubleTapSlideGR = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleDoubleTapSlide(_:))
        )
        doubleTapSlideGR.numberOfTapsRequired = 2
        doubleTapSlideGR.minimumPressDuration = 0
        
        // Add gesture recognizers to the metalView
        coordinator.configureRecognizerForSimultaneous(singleFingerPan)
        coordinator.configureRecognizerForSimultaneous(twoFingerPan)
        coordinator.configureRecognizerForSimultaneous(pinchGR)
        coordinator.configureRecognizerForSimultaneous(doubleTapGR)
        coordinator.configureRecognizerForSimultaneous(doubleTapSlideGR)
        
        metalView.addGestureRecognizer(singleFingerPan)
        metalView.addGestureRecognizer(twoFingerPan)
        metalView.addGestureRecognizer(pinchGR)
        metalView.addGestureRecognizer(doubleTapGR)
        metalView.addGestureRecognizer(doubleTapSlideGR)
        
        return metalView
    }
    
    func updateUIView(_ uiView: MetalChartUIView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> MetalChartGestureCoordinator {
        MetalChartGestureCoordinator()
    }
}
