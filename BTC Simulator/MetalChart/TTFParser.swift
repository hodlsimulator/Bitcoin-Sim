//
//  TTFParser.swift
//  BTCMonteCarlo
//
//  NOTE: Despite the filename, we no longer load TTF data from the bundle.
//        We now parse the system SF font outlines at runtime.
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
    public let curves: [BezierCurve]    // A list of cubic Beziers (p0->p1->p2->p3)
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

/// Renamed from TTFParser to something more general but the class name can stay.
public class TTFParser {
    public init() { }

    // -------------------------------------------------------------------------
    //  New method: parseGlyphOutlinesFromSystemFont
    // -------------------------------------------------------------------------
    /// Creates a large system font (SF) at `baseSize` (e.g. 1024),
    /// then extracts the outline (curves, bounding box) for each requested character.
    public func parseGlyphOutlinesFromSystemFont(
        characters: [Character],
        baseSize: CGFloat = 1024.0
    ) -> [GlyphOutline] {
        
        // 1) Create a system font at the desired base size
        let uiFont = UIFont.systemFont(ofSize: baseSize)
        // 2) Convert that to a CTFont
        let ctFont = uiFont as CTFont

        var results: [GlyphOutline] = []
        for ch in characters {
            guard let scalar = ch.unicodeScalars.first else {
                continue
            }

            // Map character to a glyph
            let glyphChar = UniChar(scalar.value)
            var glyph: CGGlyph = 0
            if !CTFontGetGlyphsForCharacters(ctFont, [glyphChar], &glyph, 1) {
                // If the character isn't in SF, skip
                continue
            }

            // Create a CGPath for this glyph
            guard let path = CTFontCreatePathForGlyph(ctFont, glyph, nil) else {
                // No outline (like space)
                continue
            }

            // Convert the path to cubic Béziers
            let (curves, minX, minY, maxX, maxY) = convertCGPathToCubicBeziers(path)

            // Build and store the outline
            let outline = GlyphOutline(
                character: ch,
                curves: curves,
                bbox: (minX, minY, maxX, maxY)
            )
            results.append(outline)
        }

        return results
    }

    // -------------------------------------------------------------------------
    //  The original convertCGPathToCubicBeziers helper
    // -------------------------------------------------------------------------
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
                // Quadratic Bézier: we have control point (points[0]) + end (points[1])
                let p0 = currentPoint
                let pc = points[0]
                let p3 = points[1]
                updateBounds(pc)
                updateBounds(p3)
                // Approx conversion to cubic
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
                // Cubic Bézier
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
                break

            @unknown default:
                break
            }
        }

        if bezierCurves.isEmpty {
            return ([], 0, 0, 0, 0)
        }

        if minX == .infinity { minX = 0 }
        if minY == .infinity { minY = 0 }
        if maxX == -.infinity { maxX = 0 }
        if maxY == -.infinity { maxY = 0 }

        return (
            bezierCurves,
            Float(minX),
            Float(minY),
            Float(maxX),
            Float(maxY)
        )
    }
}
