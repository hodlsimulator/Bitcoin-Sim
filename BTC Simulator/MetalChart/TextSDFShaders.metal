//
//  TextShaders.metal
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

#include <metal_stdlib>
using namespace metal;

struct TextVertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float4 color    [[attribute(2)]];
};

struct TextVertexOut {
    float4 position [[position]];
    float2 uv;
    float4 color;
};


struct TransformUniforms {
    float4x4 mvp;  // The transformation matrix
};

vertex TextVertexOut textVertexShader(TextVertexIn in [[stage_in]],
                                      constant TransformUniforms& uniforms [[buffer(1)]]) {
    TextVertexOut out;
    float4 pos = float4(in.position, 0.0, 1.0);
    out.position = uniforms.mvp * pos;  // Apply transformation
    out.uv = in.texCoord;
    out.color = in.color;
    return out;
}

fragment float4 textFragmentShader(TextVertexOut in [[stage_in]],
                                   texture2d<float, access::sample> fontTexture [[texture(0)]])
{
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    
    // In this approach, we assume the red channel in the atlas is our alpha.
    float sampledAlpha = fontTexture.sample(s, in.uv).r;
    
    // Multiply the sampled alpha by the vertex color’s alpha.
    float finalAlpha = in.color.a * sampledAlpha;
    
    // Return the color with the combined alpha.
    return float4(in.color.rgb, finalAlpha);
}
