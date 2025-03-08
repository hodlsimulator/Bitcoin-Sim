//
//  FontAtlasGenerator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import MetalKit
import CoreText
import UIKit

public struct RuntimeGlyphMetrics {
    public let char: Character
    public let uMin, vMin, uMax, vMax: Float
    public let width, height: Float
    public let xAdvance: Float
    public let xOffset: Float
    public let yOffset: Float
}

public struct RuntimeFontAtlas {
    public let texture: MTLTexture
    public let glyphs: [Character: RuntimeGlyphMetrics]
}

/// Generates a texture containing all requested glyphs for the system SF font.
/// We manually upscale the glyphs when drawing so we get a big atlas.
public func generateFontAtlas(
    device: MTLDevice,
    // You can tweak this “native” SF font size:
    baseSize: CGFloat = 24.0,
    // Then further upscale by scaleFactor in the atlas:
    scaleFactor: CGFloat = 4.0,
    characters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,+-*/%()[]{}^$~:;?!_=<>'\"\\|&@#∞◊¥€£•π÷–…‰″′$฿∫∑√±≈≈≠≥≤§")
) -> RuntimeFontAtlas? {
    
    // 1) Create a system font at baseSize
    let uiFont = UIFont.systemFont(ofSize: baseSize)
    // 2) Convert that to a CTFont
    let ctFont = uiFont as CTFont
    
    // Collect unique characters
    let uniqueChars = Array(Set(characters)).sorted()
    guard !uniqueChars.isEmpty else { return nil }
    
    var glyphRects: [Character: CGRect] = [:]
    var maxGlyphWidth: CGFloat = 0
    var maxGlyphHeight: CGFloat = 0
    
    // Measure bounding rects in *points*
    for ch in uniqueChars {
        guard let uniScalar = ch.unicodeScalars.first else { continue }
        // Attempt to map char -> glyph
        var glyph = CTFontGetGlyphWithName(ctFont, "\(ch)" as CFString)
        if glyph == 0 {
            let glyphChar = UniChar(uniScalar.value)
            var tempGlyph: CGGlyph = 0
            if CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &tempGlyph, 1) {
                glyph = tempGlyph
            }
        }
        
        if glyph != 0 {
            // Get how wide this glyph is
            var tempRect = CGRect.zero
            CTFontGetBoundingRectsForGlyphs(ctFont, .default, [glyph], &tempRect, 1)
            let glyphWidth = tempRect.width

            // Overall font ascent + descent
            let ascent  = CTFontGetAscent(ctFont)
            let descent = CTFontGetDescent(ctFont)
            let lineHeight = ascent + descent

            // Make a top‐aligned bounding box of (width × lineHeight),
            // plus optional extra padding around all sides to avoid clipping.
            let extra: CGFloat = 2
            let fullWidth  = glyphWidth   + extra * 2
            let fullHeight = lineHeight   + extra * 2

            // We keep the origin at (0,0) so it’s top‐aligned in the cell:
            let boundingRect = CGRect(
                x: 0,
                y: 0,
                width: fullWidth,
                height: fullHeight
            )

            // Track the maximum needed cell size
            maxGlyphWidth  = max(maxGlyphWidth,  fullWidth)
            maxGlyphHeight = max(maxGlyphHeight, fullHeight)

            glyphRects[ch] = boundingRect
        }
    }
    
    if glyphRects.isEmpty {
        return nil
    }
    
    // Layout the glyph cells in a grid
    let totalGlyphCount = glyphRects.count
    let cols = Int(ceil(sqrt(Double(totalGlyphCount))))
    let rows = Int(ceil(Double(totalGlyphCount) / Double(cols)))
    
    let padding: CGFloat = 2
    let cellWidth  = (maxGlyphWidth  * scaleFactor) + padding
    let cellHeight = (maxGlyphHeight * scaleFactor) + padding
    let atlasWidth  = Int(cellWidth  * CGFloat(cols))
    let atlasHeight = Int(cellHeight * CGFloat(rows))
    
    // Create a 1-channel (grayscale) context, top-left origin
    let colorSpace = CGColorSpaceCreateDeviceGray()
    guard let context = CGContext(
        data: nil,
        width: atlasWidth,
        height: atlasHeight,
        bitsPerComponent: 8,
        bytesPerRow: atlasWidth,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else {
        return nil
    }
    
    // Fill black
    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: atlasWidth, height: atlasHeight))
    
    var glyphMap: [Character: RuntimeGlyphMetrics] = [:]
    var idx = 0
    
    for ch in uniqueChars {
        guard let boundingRect = glyphRects[ch] else { continue }
        
        let col = idx % cols
        let row = idx / cols
        
        // Cell’s top-left in pixel space
        let originX = CGFloat(col) * cellWidth  + padding/2
        let originY = CGFloat(row) * cellHeight + padding/2
        
        // Save state
        context.saveGState()
        
        // 1) Move to the top-left of this cell
        context.translateBy(x: originX, y: originY)
        
        // 2) Scale up for higher resolution
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        
        // 3) Shift downward to place the baseline wherever you want.
        //    This is the key line: increase baselineShift if you want letters lower.
        let baselineShift: CGFloat = 8
        context.translateBy(x: 0, y: baselineShift)
        
        // 4) Draw the glyph at (0,0).
        //    (No more boundingRect.minX/minY offset!)
        var glyphID = CTFontGetGlyphWithName(ctFont, String(ch) as CFString)
        if glyphID == 0 {
            if let uniScalar = ch.unicodeScalars.first {
                let glyphChar = UniChar(uniScalar.value)
                var tempGlyph: CGGlyph = 0
                if CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &tempGlyph, 1) {
                    glyphID = tempGlyph
                }
            }
        }
        context.setFillColor(UIColor.white.cgColor)
        CTFontDrawGlyphs(ctFont, [glyphID], [.zero], 1, context)
        
        context.restoreGState()
        
        // 5) The final size in pixels for this glyph cell
        let scaledWidth  = boundingRect.width  * scaleFactor
        let scaledHeight = boundingRect.height * scaleFactor
        
        // 6) Compute unflipped rect used for the texture coordinates
        let drawnRect = CGRect(
            x: originX,
            y: originY,
            width: scaledWidth,
            height: scaledHeight
        )
        
        // U coords
        let uMin = Float(drawnRect.minX / CGFloat(atlasWidth))
        let uMax = Float(drawnRect.maxX / CGFloat(atlasWidth))
        
        // Invert V coords for Metal
        let rawVMin = Float(drawnRect.minY / CGFloat(atlasHeight))
        let rawVMax = Float(drawnRect.maxY / CGFloat(atlasHeight))
        let vMin = 1.0 - rawVMax
        let vMax = 1.0 - rawVMin
        
        // Get glyph advance
        var advances = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .default, [glyphID], &advances, 1)
        let xAdvance = Float(advances.width)
        
        // Store in the map
        let glyphW = Float(scaledWidth)
        let glyphH = Float(scaledHeight)
        glyphMap[ch] = RuntimeGlyphMetrics(
            char: ch,
            uMin: uMin, vMin: vMin,
            uMax: uMax, vMax: vMax,
            width: glyphW,
            height: glyphH,
            xAdvance: xAdvance,
            xOffset: 0,      // now we always draw at .zero
            yOffset: 0
        )
        
        idx += 1
    }
    
    // Make final CGImage
    guard let cgImage = context.makeImage() else { return nil }
    
    // (Optional) Save to Documents for debugging
    let uiImage = UIImage(cgImage: cgImage)
    if let data = uiImage.pngData() {
        do {
            let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let outURL = docsDir.appendingPathComponent("atlas.png")
            try data.write(to: outURL)
        } catch {
            print("Failed to save atlas.png: \(error)")
        }
    }
    
    // Load into MTLTexture
    let loader = MTKTextureLoader(device: device)
    let textureOptions: [MTKTextureLoader.Option: Any] = [
        .SRGB: false,
        .textureStorageMode: MTLStorageMode.shared.rawValue
    ]
    
    do {
        let atlasTexture = try loader.newTexture(cgImage: cgImage, options: textureOptions)
        return RuntimeFontAtlas(texture: atlasTexture, glyphs: glyphMap)
    } catch {
        print("Error creating MTLTexture: \(error)")
        return nil
    }
}
