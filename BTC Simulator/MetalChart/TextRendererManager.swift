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
    private var textRenderer: RuntimeGPUTextRenderer?

    // Generate font atlas and initialize the renderer
    func generateFontAtlasAndRenderer(device: MTLDevice) {
        // Generate the font atlas with the desired font
        print("Generating font atlas and initializing text renderer...")
        if let atlas = generateFontAtlas(device: device, font: UIFont.systemFont(ofSize: 16)) {
            self.fontAtlas = atlas
            // Create a text renderer with the generated atlas
            self.textRenderer = RuntimeGPUTextRenderer(device: device, atlas: atlas, library: device.makeDefaultLibrary()!)
            print("Font atlas generated and text renderer initialized successfully.")
        } else {
            print("Failed to generate font atlas.")
        }
    }

    // Expose the text renderer for other views to use
    func getTextRenderer() -> RuntimeGPUTextRenderer? {
        if let renderer = textRenderer {
            print("Returning existing TextRenderer.")
            return renderer
        } else {
            print("TextRenderer is nil. Initializing new TextRenderer.")
            return nil
        }
    }
}
