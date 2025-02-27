//
//  SDFGenerator.metal
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

#include <metal_stdlib>
using namespace metal;

struct BezierCurve {
    float2 p0;
    float2 p1;
    float2 p2;
    float2 p3;
};

/// For each glyph, we'll provide the bounding box and a list of Bezier curves
struct GlyphOutlineInfo {
    uint  glyphID;
    float2 bboxMin;
    float2 bboxMax;
    uint   curveOffset;  // index in a global curve buffer
    uint   curveCount;
    // etc.
};

kernel void generateGlyphSDF(
    device GlyphOutlineInfo* glyphInfos    [[ buffer(0) ]],
    device BezierCurve*      allCurves     [[ buffer(1) ]],
    texture2d<float, access::write> outAtlasTexture [[texture(0)]],
    uint2 gid [[thread_position_in_grid]])
{
    // The idea: each thread writes one pixel in the atlas
    // We need to figure out which glyph cell (and pixel in that cell) we are
    // in. Or you might run a separate dispatch per glyph region. Many ways.

    // PSEUDO:
    // 1) Identify which glyph bounding box this gid falls into, or skip if none.
    // 2) For that glyph, gather all curves from allCurves + curveOffset.
    // 3) Calculate distance from the pixel to each curve, store the minimal distance.
    // 4) Possibly encode distance in the red channel or create an alpha threshold.

    // This is advanced. For demonstration, let's do a trivial approach:
    
    // We'll just set a constant color to prove the pipeline works.
    if (gid.x < outAtlasTexture.get_width() &&
        gid.y < outAtlasTexture.get_height()) {
        
        // This is obviously not a real SDF.
        // You’d have to do the distance math to the shape edges, etc.
        outAtlasTexture.write(float4(0.5, 0.5, 0.5, 1.0), gid);
    }
}
