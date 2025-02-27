//
//  ChartShaders.metal
//  BTC Simulator
//
//  Created by . . on 27/02/2025.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertexShader(VertexIn inVertex [[stage_in]])
{
    VertexOut out;
    out.position = inVertex.position;
    out.color = inVertex.color;
    return out;
}

fragment float4 fragmentShader(VertexOut inVertex [[stage_in]])
{
    return inVertex.color;
}

