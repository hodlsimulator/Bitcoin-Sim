//
//  SDFGenerator.metal
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

#include <metal_stdlib>
using namespace metal;

// Represents one cubic Bézier in 2D
struct BezierCurve {
    float2 p0;
    float2 p1;
    float2 p2;
    float2 p3;
};

// Info for one glyph in the atlas
struct GlyphOutlineInfo {
    uint    glyphID;
    float2  bboxMin;
    float2  bboxMax;
    uint    curveOffset;  // index into the global curve buffer
    uint    curveCount;

    // Also store the "top-left" in the atlas if you’re packing glyph cells.
    // For a real multi-glyph atlas, you might do:
    // float2 atlasOrigin;
    // float2 atlasSize;
};

// Forward-declare a function to approximate distance from a point to a cubic curve
float distanceToCubicBezier(float2 point, BezierCurve curve);

// Forward-declare a function to see if a pixel is inside the glyph
bool isInsideGlyph(float2 point, device BezierCurve* curves, uint start, uint count);

kernel void generateGlyphSDF(
    device GlyphOutlineInfo* glyphInfos          [[ buffer(0) ]],
    device BezierCurve*      allCurves           [[ buffer(1) ]],
    constant uint&           glyphCount          [[ buffer(2) ]],
    texture2d<float, access::write> outAtlasTex  [[ texture(0) ]],
    uint2 gid [[ thread_position_in_grid ]]
)
{
    if (gid.x >= outAtlasTex.get_width() || gid.y >= outAtlasTex.get_height()) {
        return; // outside the texture
    }

    // Convert pixel coord to float2
    float2 pixelPos = float2(gid.x, gid.y);

    // We’ll default to storing 0.0
    float finalDistance = 0.0;
    bool  foundGlyph    = false;

    // 1) Identify if this pixel belongs to any glyph bounding box
    //    In a real atlas, you could quickly skip using a “which cell are we in?” approach,
    //    but here we’ll just brute force for demonstration.

    for (uint g = 0; g < glyphCount; g++) {
        float2 bbMin = glyphInfos[g].bboxMin;
        float2 bbMax = glyphInfos[g].bboxMax;

        // If your SDF uses per-glyph sub-rects in the atlas, you’d offset pixelPos accordingly
        // e.g., pixelPos - glyphInfos[g].atlasOrigin.
        // For now, assume the bounding boxes match screen coords.

        if (pixelPos.x >= bbMin.x && pixelPos.x < bbMax.x &&
            pixelPos.y >= bbMin.y && pixelPos.y < bbMax.y)
        {
            // This pixel is within the bounding box for glyph g
            // 2) Gather the glyph’s Bezier curves from allCurves + curveOffset
            uint start = glyphInfos[g].curveOffset;
            uint count = glyphInfos[g].curveCount;

            // 3) Compute minimal distance to all curves
            float minDist = 9999999.0;
            for (uint i = 0; i < count; i++) {
                BezierCurve curve = allCurves[start + i];
                float d = distanceToCubicBezier(pixelPos, curve);
                if (d < minDist) {
                    minDist = d;
                }
            }

            // Optional sign: negative if pixel is inside the path, positive if outside
            bool inside = isInsideGlyph(pixelPos, allCurves, start, count);
            float signedDist = inside ? -minDist : minDist;

            finalDistance = signedDist;
            foundGlyph    = true;
            break;  // We found our glyph, break out for this example
        }
    }

    // 4) Convert that distance to some 0..1 alpha or greyscale
    //    E.g., scale by some factor so you have a decent falloff
    float spread     = 4.0;  // how many pixels wide is the “soft edge”?
    float midVal     = 0.5;  // mid grey
    float distScaled = finalDistance / spread;
    float sdfVal     = clamp(midVal - distScaled, 0.0, 1.0);

    // If it’s outside all glyphs, just store 0 alpha
    if (!foundGlyph) {
        sdfVal = 0.0;
    }

    // Write out as float4 (just store in red for now)
    outAtlasTex.write(float4(sdfVal, sdfVal, sdfVal, 1.0), gid);
}

// MARK: - Distances

// A quick-and-dirty approach to get approximate distance to a cubic curve
// We sample a few "t" values and find the closest approach
// In production, you'd do a real nearest-point-on-curve search or a root-finding approach
float distanceToCubicBezier(float2 p, BezierCurve c)
{
    const int STEPS = 16;
    float2 prevPos = c.p0;
    float minDist = distance(p, prevPos);

    for (int i = 1; i <= STEPS; i++) {
        float t = (float)(i) / (float)(STEPS);
        // Evaluate cubic with De Casteljau or direct formula
        float2 a = mix(c.p0, c.p1, t);
        float2 b = mix(c.p1, c.p2, t);
        float2 c2 = mix(c.p2, c.p3, t);

        float2 ab = mix(a, b, t);
        float2 bc = mix(b, c2, t);
        float2 pointOnCurve = mix(ab, bc, t);

        float d = distance(p, pointOnCurve);
        if (d < minDist) {
            minDist = d;
        }
    }
    return minDist;
}

// A naive winding-based inside test for the glyph (assuming it’s closed).
bool isInsideGlyph(float2 point, device BezierCurve* curves, uint start, uint count)
{
    // For brevity, we just do a simple ray test horizontally
    // counting how many times we intersect edges
    // Real code would handle edge cases carefully.

    int winding = 0;
    float2 rayEnd = float2(999999.0, point.y);

    for (uint i = 0; i < count; i++) {
        BezierCurve curve = curves[start + i];

        // We'll approximate each cubic with small line segments again
        const int SEGMENTS = 16;
        float2 lastPos = curve.p0;
        for (int s = 1; s <= SEGMENTS; s++) {
            float t = (float)s / (float)(SEGMENTS);
            float2 a = mix(curve.p0, curve.p1, t);
            float2 b = mix(curve.p1, curve.p2, t);
            float2 c2 = mix(curve.p2, curve.p3, t);
            float2 ab = mix(a, b, t);
            float2 bc = mix(b, c2, t);
            float2 currPos = mix(ab, bc, t);

            // Check if line (lastPos->currPos) intersects with (point->rayEnd)
            // Simplify by ignoring vertical/horizontal special cases
            bool intersects = false;
            // Basic approach: see if lines overlap in the y-range, then solve for intersection
            if (((lastPos.y > point.y) != (currPos.y > point.y))) {
                // Solve for the x of intersection
                float2 edgeDir = currPos - lastPos;
                float tEdge = (point.y - lastPos.y) / edgeDir.y;
                if (tEdge >= 0.0 && tEdge <= 1.0) {
                    float xHit = lastPos.x + tEdge * edgeDir.x;
                    if (xHit >= point.x) {
                        intersects = true;
                    }
                }
            }
            if (intersects) {
                winding++;
            }
            lastPos = currPos;
        }
    }
    return (winding % 2) != 0;
}
