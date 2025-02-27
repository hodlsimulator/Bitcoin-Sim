//
//  MetalChartUIView.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import UIKit
import MetalKit

/// Subclass of MTKView (or a UIView that contains an MTKView), ready for advanced gestures.
class MetalChartUIView: MTKView {
    
    /// The Metal renderer that handles drawing.
    let renderer = MetalChartRenderer()
    
    override init(frame: CGRect, device: MTLDevice?) {
        let defaultDevice = device ?? MTLCreateSystemDefaultDevice()
        super.init(frame: frame, device: defaultDevice)
        
        self.device = defaultDevice
        self.delegate = renderer
        self.clearColor = MTLClearColorMake(0, 0, 0, 1)
        self.preferredFramesPerSecond = 60
        self.sampleCount = 4
        
        // If you need any special init logic, do it here.
        // For example: renderer.setupMetal(...) once the size is known, etc.
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Optionally override layoutSubviews if you want to update viewport on size changes:
    override func layoutSubviews() {
        super.layoutSubviews()
        renderer.updateViewport(to: bounds.size)
    }
}
