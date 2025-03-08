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
        
        // Just get the user's preferred SF style (for size).
        // We'll pass its pointSize into the new generateFontAtlas.
        let chosenFont = UIFont.preferredFont(forTextStyle: .title2)
        let baseSize   = chosenFont.pointSize // e.g. might be ~22, depending on device settings

        // We'll still do a 2× or 4× scale in the atlas if we want extra crispness.
        let scaleFactor: CGFloat = 2.0

        // NOTE: The new generateFontAtlas(...) does *not* accept a UIFont.
        // Instead it creates Apple’s SF internally at `baseSize`.
        if let atlas = generateFontAtlas(
            device: device,
            baseSize: baseSize,
            scaleFactor: scaleFactor
            // characters: ... if you want a custom list, otherwise it uses the default
        ) {
            self.fontAtlas = atlas
            self.textRenderer = GPUTextRenderer(
                device: device,
                atlas: atlas,
                library: device.makeDefaultLibrary()!
            )
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
            print("Updated existing textRenderer’s atlas.")
        } else {
            // If there's no renderer yet, consider creating it here
            print("No textRenderer to update. Create it now or skip.")
            // e.g.:
            // textRenderer = GPUTextRenderer(device: someDevice, atlas: atlas, library: someLibrary)
        }
    }
}
