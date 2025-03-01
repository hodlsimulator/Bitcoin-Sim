//
//  MetalChartUIView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import UIKit
import MetalKit

/// A plain UIView that hosts the MTKView and holds a reference to your renderer.
class MetalChartUIView: UIView {
    let renderer: MetalChartRenderer
    let mtkView: MTKView
    
    // Provide a callback instead of a separate manager
    var onUserInteraction: (() -> Void)?
    
    init(frame: CGRect, renderer: MetalChartRenderer, textRendererManager: TextRendererManager) {
        self.renderer = renderer
        
        // Pass textRendererManager to the renderer
        renderer.textRendererManager = textRendererManager
        
        mtkView = MTKView(frame: frame, device: renderer.device ?? MTLCreateSystemDefaultDevice())
        super.init(frame: frame)
        
        mtkView.delegate = renderer
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.sampleCount = 4
        mtkView.preferredFramesPerSecond = 60
        
        // Add gesture recognizers to reset idle timer on user interaction
        addGestureRecognizers()
        
        addSubview(mtkView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        mtkView.frame = self.bounds
    }
    
    // Add gesture recognizers to reset idle timer on interaction
    private func addGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleUserInteraction))
        self.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleUserInteraction))
        self.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleUserInteraction))
        self.addGestureRecognizer(pinchGesture)
    }
    
    // Method to reset the idle timer on user interaction
    @objc private func handleUserInteraction() {
        // Instead of idleManager.resetIdleTimer(),
        // call our callback so the environment manager is reset
        onUserInteraction?()
    }
}
