//
//  TTFParser.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import Foundation
import CoreText
import CoreGraphics
import UIKit

/// A simple struct holding the outline data for one glyph
public struct GlyphOutline {
    public let character: Character
    public let curves: [BezierCurve]          // A list of cubic Beziers (p0->p1->p2->p3)
    public let bbox: (minX: Float, minY: Float, maxX: Float, maxY: Float)
}

/// A simple cubic Bézier curve
public struct BezierCurve {
    public let p0: (Float, Float)
    public let p1: (Float, Float)
    public let p2: (Float, Float)
    public let p3: (Float, Float)
}

public struct GlyphOutlineInfo {
    public var glyphID: UInt32
    public var bboxMin: SIMD2<Float>
    public var bboxMax: SIMD2<Float>
    public var curveOffset: UInt32
    public var curveCount: UInt32
}

public class TTFParser {
    public init() { }

    /// Loads the raw TTF file data from the main bundle
    public func loadFontData(named fontFileName: String) -> Data? {
        guard let url = Bundle.main.url(forResource: fontFileName, withExtension: "ttf") else {
            print("TTF file '\(fontFileName).ttf' not found in the app bundle.")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Failed to read TTF data: \(error)")
            return nil
        }
    }

    /// Parse the TTF data to extract glyph outlines for the given characters.
    /// Uses CoreText to map each character to a glyph, then extracts the path.
    /// Next, it enumerates each path element (move, line, quad, curve) and converts them to cubic Bézier segments.
    public func parseGlyphOutlines(fontData: Data, characters: [Character]) -> [GlyphOutline] {
        // 1) Create CGDataProvider & CGFont from raw TTF data
        guard let provider = CGDataProvider(data: fontData as CFData),
              let cgFont   = CGFont(provider) else {
            print("Failed to create CGFont from TTF data.")
            return []
        }

        // 2) Create a CTFont (CoreText) to get glyph IDs + paths
        //    The font size here impacts path scaling, so pick a "neutral" size (e.g. 1024) for max detail
        let ctFont = CTFontCreateWithGraphicsFont(cgFont, 1024, nil, nil)

        var results: [GlyphOutline] = []
        for ch in characters {
            guard let scalar = ch.unicodeScalars.first else {
                continue
            }

            // 3) Map character to a glyph
            let glyphChar = UniChar(scalar.value)
            var glyph: CGGlyph = 0
            if !CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &glyph, 1) {
                // If the character isn't in this font, skip
                continue
            }

            // 4) Create a CGPath for this glyph
            guard let path = CTFontCreatePathForGlyph(ctFont, glyph, nil) else {
                // No outline (like space)
                continue
            }

            // 5) Convert the path to our own array of cubic Bézier curves
            let (curves, minX, minY, maxX, maxY) = convertCGPathToCubicBeziers(path)

            // 6) Build and store the outline
            let outline = GlyphOutline(
                character: ch,
                curves: curves,
                bbox: (minX, minY, maxX, maxY)
            )
            results.append(outline)
        }

        return results
    }

    // MARK: - Convert a CGPath to an array of cubic Bézier curves
    /// This is a simplistic approach that:
    /// - Interprets lines as cubic segments (with control points = endpoints)
    /// - Approximates quad segments as cubic
    /// In a real scenario, you’d handle each path element carefully.
    private func convertCGPathToCubicBeziers(_ path: CGPath)
    -> ([BezierCurve], Float, Float, Float, Float)
    {
        var bezierCurves: [BezierCurve] = []
        var currentPoint: CGPoint = .zero
        var minX: CGFloat = .infinity, minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity, maxY: CGFloat = -.infinity

        path.applyWithBlock { elementPtr in
            let element = elementPtr.pointee
            let points  = element.points

            func updateBounds(_ p: CGPoint) {
                if p.x < minX { minX = p.x }
                if p.x > maxX { maxX = p.x }
                if p.y < minY { minY = p.y }
                if p.y > maxY { maxY = p.y }
            }

            switch element.type {
            case .moveToPoint:
                currentPoint = points[0]
                updateBounds(currentPoint)

            case .addLineToPoint:
                let p0 = currentPoint
                let p3 = points[0]
                updateBounds(p3)
                // For a line, treat as cubic with control points = endpoints
                let curve = BezierCurve(
                    p0: (Float(p0.x), Float(p0.y)),
                    p1: (Float(p0.x), Float(p0.y)),
                    p2: (Float(p3.x), Float(p3.y)),
                    p3: (Float(p3.x), Float(p3.y))
                )
                bezierCurves.append(curve)
                currentPoint = p3

            case .addQuadCurveToPoint:
                // Quadratic Bézier: we have control point (points[0]) and end (points[1])
                let p0 = currentPoint
                let pc = points[0]
                let p3 = points[1]
                updateBounds(pc)
                updateBounds(p3)
                // Approx conversion to cubic:
                // c1 = p0 + 2/3*(pc - p0), c2 = p3 + 2/3*(pc - p3)
                let c1x = p0.x + (2.0/3.0)*(pc.x - p0.x)
                let c1y = p0.y + (2.0/3.0)*(pc.y - p0.y)
                let c2x = p3.x + (2.0/3.0)*(pc.x - p3.x)
                let c2y = p3.y + (2.0/3.0)*(pc.y - p3.y)

                let curve = BezierCurve(
                    p0: (Float(p0.x), Float(p0.y)),
                    p1: (Float(c1x), Float(c1y)),
                    p2: (Float(c2x), Float(c2y)),
                    p3: (Float(p3.x), Float(p3.y))
                )
                bezierCurves.append(curve)
                currentPoint = p3

            case .addCurveToPoint:
                // Cubic Bézier: three points => control1 (points[0]),
                //                                  control2 (points[1]),
                //                                  end      (points[2])
                let p0  = currentPoint
                let p1c = points[0]
                let p2c = points[1]
                let p3  = points[2]
                updateBounds(p1c)
                updateBounds(p2c)
                updateBounds(p3)
                let curve = BezierCurve(
                    p0: (Float(p0.x),  Float(p0.y)),
                    p1: (Float(p1c.x), Float(p1c.y)),
                    p2: (Float(p2c.x), Float(p2c.y)),
                    p3: (Float(p3.x),  Float(p3.y))
                )
                bezierCurves.append(curve)
                currentPoint = p3

            case .closeSubpath:
                // Usually means back to start of the contour
                break

            @unknown default:
                break
            }
        }

        // If there was no path, minX = inf, etc. So clamp
        if bezierCurves.isEmpty {
            return ([], 0, 0, 0, 0)
        }

        if minX == .infinity { minX = 0 }
        if minY == .infinity { minY = 0 }
        if maxX == -.infinity { maxX = 0 }
        if maxY == -.infinity { maxY = 0 }

        return (bezierCurves,
                Float(minX), Float(minY),
                Float(maxX), Float(maxY))
    }
}
