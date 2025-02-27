//
//  AxisShaders.metal
//  BTC Simulator
//
//  Created by . . on 27/02/2025.
//

#include <metal_stdlib>
using namespace metal;

struct AxisVertexIn {
    float4 position [[attribute(0)]]; // x, y, z, w
    float4 color    [[attribute(1)]];
};

struct ViewportSize {
    float2 size; // width, height
};

struct AxisVertexOut {
    float4 position [[position]];
    float4 color;
};

/*
  1) If You're Storing Positions Already in CLIP SPACE ([-1..1]):
     Use This Vertex Function to Pass Them Straight Through.
*/
vertex AxisVertexOut axisVertexShader_clipSpace(AxisVertexIn in [[stage_in]])
{
    AxisVertexOut out;
    out.position = in.position;  // no transform needed
    out.color = in.color;
    return out;
}

/*
  2) If You're Storing Positions in SCREEN SPACE ([0..viewportWidth], [0..viewportHeight]):
     Convert to Clip Space in the Vertex Shader via the viewport size (passed as buffer(1)).
*/
vertex AxisVertexOut axisVertexShader_screenSpace(AxisVertexIn in [[stage_in]],
                                                  constant ViewportSize& vp [[buffer(1)]])
{
    float2 screenPos = float2(in.position.x, in.position.y);
    
    // Map screenPos.x in [0..vp.size.x] to clipX in [-1..1].
    float clipX = (screenPos.x / (vp.size.x / 2.0)) - 1.0;
    
    // Map screenPos.y in [0..vp.size.y] to clipY in [-1..1],
    // and flip y if needed (some coordinate systems want the origin at top-left).
    float clipY = 1.0 - (screenPos.y / (vp.size.y / 2.0));
    
    AxisVertexOut out;
    out.position = float4(clipX, clipY, 0.0, 1.0);
    out.color = in.color;
    return out;
}

fragment float4 axisFragmentShader(AxisVertexOut in [[stage_in]])
{
    // Simply output the color
    return in.color;
}
