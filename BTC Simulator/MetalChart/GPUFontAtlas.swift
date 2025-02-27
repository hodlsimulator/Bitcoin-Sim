//
//  GPUFontAtlas.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import MetalKit

/// Stores the final Metal texture containing all the SDF glyphs,
/// plus per-glyph metadata for rendering quads.
public struct GPUFontGlyph {
    public let char: Character
    
    // The subregion in the atlas
    public let uMin: Float
    public let vMin: Float
    public let uMax: Float
    public let vMax: Float
    
    // The actual glyph size + offsets for layout
    public let width: Float
    public let height: Float
    public let xAdvance: Float
    public let xOffset: Float
    public let yOffset: Float
}

public class GPUFontAtlas {
    public let texture: MTLTexture
    public let glyphs: [Character: GPUFontGlyph]
    
    public init(texture: MTLTexture, glyphs: [Character: GPUFontGlyph]) {
        self.texture = texture
        self.glyphs = glyphs
    }
}
