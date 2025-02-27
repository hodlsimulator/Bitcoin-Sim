//
//  MetalChartContainerView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import SwiftUI
import UIKit

/// A UIViewRepresentable that hosts our Metal chart and adds custom UIKit gestures.
struct MetalChartContainerView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> MetalChartUIView {
        let metalView = MetalChartUIView()
        
        // Attach gesture recognizers
        let pinchGR = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handlePinch(_:))
        )
        let panGR = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handlePan(_:))
        )
        
        metalView.addGestureRecognizer(pinchGR)
        metalView.addGestureRecognizer(panGR)
        
        return metalView
    }
    
    func updateUIView(_ uiView: MetalChartUIView, context: Context) {
        // Update if needed, e.g. pass new data or settings to uiView.renderer
    }
    
    func makeCoordinator() -> MetalChartGestureCoordinator {
        MetalChartGestureCoordinator()
    }
}
