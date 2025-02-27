//
//  FontAtlasGenerator.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import MetalKit
import CoreText
import UIKit

/// Stores the UV region for each character, plus layout info
public struct RuntimeGlyphMetrics {
    public let char: Character
    public let uMin, vMin, uMax, vMax: Float
    public let width, height: Float
    public let xAdvance: Float
    public let xOffset: Float
    public let yOffset: Float
}

/// The result of generating a font atlas at runtime.
public struct RuntimeFontAtlas {
    public let texture: MTLTexture
    public let glyphs: [Character: RuntimeGlyphMetrics]
}

/// Generates a texture containing all requested glyphs for the specified font.
/// Returns a `RuntimeFontAtlas` with the texture + a dictionary of glyph metrics.
public func generateFontAtlas(
    device: MTLDevice,
    font: UIFont,
    characters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,+-*/%()[]{}^$~:;?!_=<>'\"\\|&@#∞◊¥€£•π÷–…‰″′$฿∫∑√±≈≈≠≥≤§")
) -> RuntimeFontAtlas? {
    
    // 1) Unique sorted list of characters
    let uniqueChars = Array(Set(characters)).sorted()
    guard !uniqueChars.isEmpty else { return nil }
    
    // 2) Measure each glyph’s bounding rect
    let ctFont = CTFontCreateWithName(font.fontName as CFString, font.pointSize, nil)
    var glyphRects: [Character: CGRect] = [:]
    var maxGlyphWidth: CGFloat = 0
    var maxGlyphHeight: CGFloat = 0
    
    for ch in uniqueChars {
        guard let uniScalar = ch.unicodeScalars.first else { continue }
        
        var glyph = CTFontGetGlyphWithName(ctFont, "\(ch)" as CFString)
        if glyph == 0 {
            let glyphChar = UniChar(uniScalar.value)
            var tempGlyph: CGGlyph = 0
            if CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &tempGlyph, 1) {
                glyph = tempGlyph
            } else {
                glyph = 0
            }
        }
        
        if glyph != 0 {
            var boundingRect = CGRect.zero
            CTFontGetBoundingRectsForGlyphs(ctFont, .default, [glyph], &boundingRect, 1)
            maxGlyphWidth = max(maxGlyphWidth, boundingRect.width)
            maxGlyphHeight = max(maxGlyphHeight, boundingRect.height)
            glyphRects[ch] = boundingRect
        }
    }
    
    if glyphRects.isEmpty {
        return nil
    }
    
    // 3) Create a grid for glyphs
    let totalGlyphCount = glyphRects.count
    let cols = Int(ceil(sqrt(Double(totalGlyphCount))))
    let rows = Int(ceil(Double(totalGlyphCount) / Double(cols)))
    
    let padding: CGFloat = 2
    let cellWidth  = maxGlyphWidth  + padding
    let cellHeight = maxGlyphHeight + padding
    let atlasWidth  = Int(cellWidth * CGFloat(cols))
    let atlasHeight = Int(cellHeight * CGFloat(rows))
    
    // 4) Create a grayscale Core Graphics context
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
    
    // Flip context
    context.translateBy(x: 0, y: CGFloat(atlasHeight))
    context.scaleBy(x: 1, y: -1)
    
    // Fill black background
    context.setFillColor(UIColor.black.cgColor)
    context.fill(CGRect(x: 0, y: 0, width: atlasWidth, height: atlasHeight))
    
    var glyphMap: [Character: RuntimeGlyphMetrics] = [:]
    
    // 5) Draw each glyph
    var idx = 0
    for ch in uniqueChars {
        guard let boundingRect = glyphRects[ch] else { continue }
        let col = idx % cols
        let row = idx / cols
        
        let originX = CGFloat(col) * cellWidth  + padding / 2
        let originY = CGFloat(row) * cellHeight + padding / 2
        
        // Draw single character
        let attrString = NSAttributedString(
            string: String(ch),
            attributes: [
                .font: font,
                .foregroundColor: UIColor.white
            ]
        )
        let line = CTLineCreateWithAttributedString(attrString)
        
        context.saveGState()
        context.translateBy(x: originX, y: originY)
        context.translateBy(x: 0, y: -boundingRect.origin.y)
        CTLineDraw(line, context)
        context.restoreGState()
        
        // boundingRect in the atlas
        let drawnRect = CGRect(
            x: originX + boundingRect.origin.x,
            y: originY + boundingRect.origin.y,
            width: boundingRect.width,
            height: boundingRect.height
        )
        
        let uMin = Float(drawnRect.minX / CGFloat(atlasWidth))
        let vMin = Float(drawnRect.minY / CGFloat(atlasHeight))
        let uMax = Float(drawnRect.maxX / CGFloat(atlasWidth))
        let vMax = Float(drawnRect.maxY / CGFloat(atlasHeight))
        
        // measure advance
        var advances = CGSize.zero
        let glyph = CTFontGetGlyphWithName(ctFont, String(ch) as CFString)
        CTFontGetAdvancesForGlyphs(ctFont, .default, [glyph], &advances, 1)
        
        let glyphW = Float(boundingRect.width)
        let glyphH = Float(boundingRect.height)
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
    
    // 6) Make CGImage
    guard let cgImage = context.makeImage() else { return nil }
    
    // 7) Convert CGImage to MTLTexture
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
