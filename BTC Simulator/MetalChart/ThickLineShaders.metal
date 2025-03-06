//
//  ThickLineShaders.metal
//  BTC Simulator
//
//  Created by . . on 06/03/2025.
//
//  This file contains a vertex & fragment shader for drawing thick lines in screen space.
//  We offset each vertex based on a "side" (+1 or -1) and a thickness in pixels.
//
//  To use it, build a separate MTLRenderPipelineState in Swift that uses:
//    vertexFunction = library.makeFunction(name: "thickLineVertexShader")
//    fragmentFunction = library.makeFunction(name: "thickLineFragmentShader")
//  Then, in your Swift code, provide a vertex buffer of type ThickLineVertexIn
//  and a uniform buffer of type ThickLineUniforms. Draw with .triangleStrip or .triangle.
//
//  This is separate from ChartShaders.metal, which can remain as-is for normal lines.
//
//  Updated to use orthographic matrix plus post‐transform offset.
//

#include <metal_stdlib>
using namespace metal;

// CPU geometry struct (matching Swift)
struct ThickLineVertexIn {
    float2 pos;       // domain coords of current vertex
    float2 nextPos;   // domain coords of the next vertex
    float  side;      // +1 or -1
    float4 color;     // RGBA
};

// Uniforms with an orthographic transform plus thickness in pixels.
struct ThickLineMatrixUniforms {
    float4x4 transformMatrix;  // 64 bytes
    float2 viewportSize;       // 8 bytes
    float thicknessPixels;     // 4 bytes
    // Possibly alignment/padding => total ~80 bytes
};

// Vertex output
struct ThickLineVertexOut {
    float4 position [[position]];
    float4 color;
};

vertex ThickLineVertexOut thickLineVertexShader(
    // We'll do manual indexing:
    uint vid [[vertex_id]],
    device const ThickLineVertexIn* inVerts [[buffer(0)]],
    constant ThickLineMatrixUniforms& u [[buffer(1)]]
)
{
    // 1) fetch geometry
    ThickLineVertexIn V = inVerts[vid];

    // 2) transform domain coords -> clip space via orthographic matrix
    float4 p1clip = u.transformMatrix * float4(V.pos,     0.0, 1.0);
    float4 p2clip = u.transformMatrix * float4(V.nextPos, 0.0, 1.0);

    // 3) convert to Normalised Device Coords (NDC) => [-1..+1] in x,y
    float2 p1ndc = p1clip.xy / p1clip.w;   // e.g. [-1..+1]
    float2 p2ndc = p2clip.xy / p2clip.w;

    // 4) direction in NDC
    float2 dir = p2ndc - p1ndc;
    float len  = max(length(dir), 1e-9);
    float2 perp = float2(-dir.y, dir.x) / len;

    // 5) convert "pixels" to "NDC" scale:
    //    1 device pixel => (2 / viewportWidth) in X dimension
    //                      (2 / viewportHeight) in Y dimension
    float2 pxToNDC = float2(2.0 / u.viewportSize.x,
                            2.0 / u.viewportSize.y);

    // 6) offset in NDC
    float halfT = 0.5 * u.thicknessPixels; // half the line thickness
    float2 offsetNDC = perp * (V.side * halfT) * pxToNDC;

    // 7) final position in NDC
    float2 finalNDC = p1ndc + offsetNDC;

    // 8) we build a new clip-space position
    //    We'll keep the same z from p1clip in NDC
    float finalZ = p1clip.z / p1clip.w; // or 0 if you want
    float4 outPos = float4(finalNDC, finalZ, 1.0);

    // 9) pass color
    ThickLineVertexOut out;
    out.position = outPos;
    out.color    = V.color;
    return out;
}

fragment float4 thickLineFragmentShader(ThickLineVertexOut in [[stage_in]])
{
    return in.color;
}
