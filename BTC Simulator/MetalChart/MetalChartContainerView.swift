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
    
    @EnvironmentObject var idleManager: IdleManager
    
    func makeUIView(context: Context) -> MetalChartUIView {
        // Ensure textRendererManager is available
        guard let textRendererManager = metalChart.textRendererManager else {
            fatalError("textRendererManager is nil. Call setupMetal() first.")
        }
        
        // Create our custom UIView subclass that holds Metal
        let metalView = MetalChartUIView(
            frame: .zero,
            renderer: metalChart,
            textRendererManager: textRendererManager
        )
        
        // Store a reference to the MTKView in IdleManager, so we can pause it
        idleManager.metalView = metalView.mtkView
        
        // Access our coordinator
        let coordinator = context.coordinator
        
        // Set up gestures…
        let singleFingerPan = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleSingleFingerPan(_:))
        )
        singleFingerPan.maximumNumberOfTouches = 1
        
        let twoFingerPan = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleTwoFingerPanToZoom(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        
        let pinchGR = UIPinchGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handlePinch(_:))
        )
        
        let doubleTapGR = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleDoubleTap(_:))
        )
        doubleTapGR.numberOfTapsRequired = 2
        
        let doubleTapSlideGR = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.handleDoubleTapSlide(_:))
        )
        doubleTapSlideGR.numberOfTapsRequired = 2
        doubleTapSlideGR.minimumPressDuration = 0
        
        // Allow simultaneous recognition
        coordinator.configureRecognizerForSimultaneous(singleFingerPan)
        coordinator.configureRecognizerForSimultaneous(twoFingerPan)
        coordinator.configureRecognizerForSimultaneous(pinchGR)
        coordinator.configureRecognizerForSimultaneous(doubleTapGR)
        coordinator.configureRecognizerForSimultaneous(doubleTapSlideGR)
        
        // Add them
        metalView.addGestureRecognizer(singleFingerPan)
        metalView.addGestureRecognizer(twoFingerPan)
        metalView.addGestureRecognizer(pinchGR)
        metalView.addGestureRecognizer(doubleTapGR)
        metalView.addGestureRecognizer(doubleTapSlideGR)
        
        // Idle timer resets on any tap or pan
        let tapToReset = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.resetIdleTimer)
        )
        let panToReset = UIPanGestureRecognizer(
            target: coordinator,
            action: #selector(coordinator.resetIdleTimer)
        )
        metalView.addGestureRecognizer(tapToReset)
        metalView.addGestureRecognizer(panToReset)
        
        return metalView
    }
    
    func updateUIView(_ uiView: MetalChartUIView, context: Context) {
        // Update if needed
    }
    
    func makeCoordinator() -> MetalChartGestureCoordinator {
        // Pass the idleManager to the coordinator
        MetalChartGestureCoordinator(idleManager: idleManager)
    }
}
