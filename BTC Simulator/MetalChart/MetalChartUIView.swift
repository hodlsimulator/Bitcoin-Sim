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
    
    init(frame: CGRect, renderer: MetalChartRenderer) {
        self.renderer = renderer
        
        // Create an MTKView, wire it to your renderer
        mtkView = MTKView(frame: frame, device: renderer.device ?? MTLCreateSystemDefaultDevice())
        super.init(frame: frame)
        
        mtkView.delegate = renderer
        mtkView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        mtkView.sampleCount = 4
        mtkView.preferredFramesPerSecond = 60
        
        // Add the MTKView as a subview
        addSubview(mtkView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Ensure MTKView always matches our bounds
        mtkView.frame = self.bounds
    }
}
