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

/// Generates a texture containing all requested glyphs for the specified font.
/// We manually upscale the glyphs when drawing so we get a big atlas.
public func generateFontAtlas(
    device: MTLDevice,
    font: UIFont,
    scaleFactor: CGFloat = 4.0,
    characters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,+-*/%()[]{}^$~:;?!_=<>'\"\\|&@#∞◊¥€£•π÷–…‰″′$฿∫∑√±≈≈≠≥≤§")
) -> RuntimeFontAtlas? {
    
    let uniqueChars = Array(Set(characters)).sorted()
    guard !uniqueChars.isEmpty else { return nil }
    
    // CTFont with the base size
    let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
    
    var glyphRects: [Character: CGRect] = [:]
    var maxGlyphWidth: CGFloat = 0
    var maxGlyphHeight: CGFloat = 0
    
    // Measure bounding rects in *points*
    for ch in uniqueChars {
        guard let uniScalar = ch.unicodeScalars.first else { continue }
        var glyph = CTFontGetGlyphWithName(ctFont, "\(ch)" as CFString)
        if glyph == 0 {
            let glyphChar = UniChar(uniScalar.value)
            var tempGlyph: CGGlyph = 0
            if CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &tempGlyph, 1) {
                glyph = tempGlyph
            }
        }
        
        if glyph != 0 {
            // Right after we get boundingRect, we expand it slightly
            var boundingRect = CGRect.zero
            CTFontGetBoundingRectsForGlyphs(ctFont, .default, [glyph], &boundingRect, 1)

            // Add some extra padding to the glyph bounds
            let extraBound: CGFloat = 2  // You can tweak this
            boundingRect = boundingRect.insetBy(dx: -extraBound, dy: -extraBound)

            // Now boundingRect is guaranteed to have more space, so we don't clip
            maxGlyphWidth  = max(maxGlyphWidth,  boundingRect.width)
            maxGlyphHeight = max(maxGlyphHeight, boundingRect.height)
            glyphRects[ch] = boundingRect
        }
    }
    if glyphRects.isEmpty {
        return nil
    }
    
    let totalGlyphCount = glyphRects.count
    let cols = Int(ceil(sqrt(Double(totalGlyphCount))))
    let rows = Int(ceil(Double(totalGlyphCount) / Double(cols)))
    
    let padding: CGFloat = 2
    let cellWidth  = (maxGlyphWidth  * scaleFactor) + padding
    let cellHeight = (maxGlyphHeight * scaleFactor) + padding
    let atlasWidth  = Int(cellWidth  * CGFloat(cols))
    let atlasHeight = Int(cellHeight * CGFloat(rows))
    
    print("Building atlas \(atlasWidth)x\(atlasHeight) scaleFactor=\(scaleFactor)")
    
    // 1) DO NOT FLIP THE CONTEXT. We keep it in Apple’s default top-left origin.
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
        
        // The cell’s top-left in pixel space
        let originX = CGFloat(col) * cellWidth  + padding/2
        let originY = CGFloat(row) * cellHeight + padding/2
        
        // We'll scale from boundingRect’s top-left corner
        let scaledOffsetX = boundingRect.minX * scaleFactor
        let scaledOffsetY = boundingRect.minY * scaleFactor
        let drawnX = originX + scaledOffsetX
        let drawnY = originY + scaledOffsetY
        
        context.saveGState()
        // 2) We scale up by scaleFactor so glyph is physically larger in the bitmap
        context.translateBy(x: originX, y: originY)
        context.scaleBy(x: scaleFactor, y: scaleFactor)
        
        let position = CGPoint(x: boundingRect.minX, y: boundingRect.minY)
        
        context.setFillColor(UIColor.white.cgColor)
        
        var glyphID = CTFontGetGlyphWithName(ctFont, String(ch) as CFString)
        if glyphID == 0 {
            let uniScalar = ch.unicodeScalars.first!
            let glyphChar = UniChar(uniScalar.value)
            var tempGlyph: CGGlyph = 0
            if CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &tempGlyph, 1) {
                glyphID = tempGlyph
            }
        }
        
        CTFontDrawGlyphs(ctFont, [glyphID], [position], 1, context)
        context.restoreGState()
        
        let scaledWidth  = boundingRect.width  * scaleFactor
        let scaledHeight = boundingRect.height * scaleFactor
        
        // This is the “unflipped” final rect in the top-left coordinate system
        let drawnRect = CGRect(
            x: drawnX,
            y: drawnY,
            width: scaledWidth,
            height: scaledHeight
        )
        
        // We'll compute the U coords as normal:
        let uMin = Float(drawnRect.minX / CGFloat(atlasWidth))
        let uMax = Float(drawnRect.maxX / CGFloat(atlasWidth))
        
        // 3) Invert the V coords because in a typical Metal texture,
        //    v=0 is at the *bottom*, but Apple’s CG context has y=0 at the top.
        //    So we flip them here to ensure the text is upright in Metal.
        let rawVMin = Float(drawnRect.minY / CGFloat(atlasHeight))
        let rawVMax = Float(drawnRect.maxY / CGFloat(atlasHeight))
        
        let vMin = 1.0 - rawVMax  // invert
        let vMax = 1.0 - rawVMin  // invert
        
        var advances = CGSize.zero
        CTFontGetAdvancesForGlyphs(ctFont, .default, [glyphID], &advances, 1)
        
        let glyphW = Float(scaledWidth)
        let glyphH = Float(scaledHeight)
        let xAdvance = Float(advances.width) // unscaled points, scale in buildTextVertices if needed
        
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
    
    guard let cgImage = context.makeImage() else { return nil }
    
    // Convert to UIImage and save in Documents so you can check it
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
    
    // Now load into MTLTexture
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
