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
            var boundingRect = CGRect.zero
            CTFontGetBoundingRectsForGlyphs(ctFont, .default, [glyph], &boundingRect, 1)
            
            // Add extra padding so we don’t clip the edges
            let extraBound: CGFloat = 2
            boundingRect = boundingRect.insetBy(dx: -extraBound, dy: -extraBound)
            
            maxGlyphWidth  = max(maxGlyphWidth,  boundingRect.width)
            maxGlyphHeight = max(maxGlyphHeight, boundingRect.height)
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
    
    print("Building atlas \(atlasWidth)x\(atlasHeight), baseSize=\(baseSize), scaleFactor=\(scaleFactor)")
    
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
        
        // Where we will eventually draw in the context
        let scaledOffsetX = boundingRect.minX * scaleFactor
        let scaledOffsetY = boundingRect.minY * scaleFactor
        let drawnX = originX + scaledOffsetX
        let drawnY = originY + scaledOffsetY
        
        context.saveGState()
        // Scale up the glyph so it’s physically larger in the bitmap
        context.translateBy(x: originX, y: originY)
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        
        let position = CGPoint(x: boundingRect.minX, y: boundingRect.minY)
        context.setFillColor(UIColor.white.cgColor)
        
        // Get the glyph ID again in case we didn’t store it
        var glyphID = CTFontGetGlyphWithName(ctFont, String(ch) as CFString)
        if glyphID == 0 {
            let uniScalar = ch.unicodeScalars.first!
            let glyphChar = UniChar(uniScalar.value)
            var tempGlyph: CGGlyph = 0
            if CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &tempGlyph, 1) {
                glyphID = tempGlyph
            }
        }
        
        // Draw the glyph in white
        CTFontDrawGlyphs(ctFont, [glyphID], [position], 1, context)
        context.restoreGState()
        
        // The final size in pixels
        let scaledWidth  = boundingRect.width  * scaleFactor
        let scaledHeight = boundingRect.height * scaleFactor
        
        // The unflipped rect
        let drawnRect = CGRect(
            x: drawnX,
            y: drawnY,
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
        
        // We can retrieve glyph advance in points
        var advances = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .default, [glyphID], &advances, 1)
        
        // Fill in the map
        let glyphW = Float(scaledWidth)
        let glyphH = Float(scaledHeight)
        let xAdvance = Float(advances.width)
        
        glyphMap[ch] = RuntimeGlyphMetrics(
            char: ch,
            uMin: uMin, vMin: vMin,
            uMax: uMax, vMax: vMax,
            width: glyphW,
            height: glyphH,
            xAdvance: xAdvance,
            xOffset: Float(boundingRect.minX),
            yOffset: Float(-boundingRect.minY)
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
            print("Atlas PNG saved to \(outURL.path)")
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
        print("Metal texture size: \(atlasTexture.width)x\(atlasTexture.height)")
        return RuntimeFontAtlas(texture: atlasTexture, glyphs: glyphMap)
    } catch {
        print("Error creating MTLTexture: \(error)")
        return nil
    }
}
