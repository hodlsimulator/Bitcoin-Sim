//
//  TextRendererManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 28/02/2025.
//

import Metal
import UIKit

class TextRendererManager: ObservableObject {
    private var fontAtlas: RuntimeFontAtlas?
    private var textRenderer: GPUTextRenderer?

    // Generate font atlas and initialize the renderer
    func generateFontAtlasAndRenderer(device: MTLDevice) {
        print("Generating font atlas and initializing text renderer...")
        if let atlas = generateFontAtlas(device: device, font: UIFont.systemFont(ofSize: 16)) {
            self.fontAtlas = atlas
            // Create a text renderer with the generated atlas
            self.textRenderer = GPUTextRenderer(
                device: device,
                atlas: atlas,
                library: device.makeDefaultLibrary()!
            )
            print("Font atlas generated and text renderer initialized successfully.")
        } else {
            print("Failed to generate font atlas.")
        }
    }

    // Expose the text renderer for other views/classes to use
    func getTextRenderer() -> GPUTextRenderer? {
        if let renderer = textRenderer {
            print("Returning existing TextRenderer.")
            return renderer
        } else {
            print("TextRenderer is nil. (You might call generateFontAtlasAndRenderer first?)")
            return nil
        }
    }
    
    /// Update the existing renderer’s atlas, or store it for future use
    func updateRuntimeAtlas(_ atlas: RuntimeFontAtlas) {
        // Store the new atlas
        self.fontAtlas = atlas
        
        if let existingRenderer = textRenderer {
            // Reassign the atlas on our existing text renderer
            existingRenderer.atlas = atlas
            print("Updated existing textRendffunc draw(in view: MTKViewerer's atlas.")
        } else {
            // If there's no renderer yet, consider creating it here
            print("No textRenderer to update. Create it now or skip.")
            // e.g.:
            // textRenderer = GPUTextRenderer(device: someDevice, atlas: atlas, library: someLibrary)
        }
    }
}
