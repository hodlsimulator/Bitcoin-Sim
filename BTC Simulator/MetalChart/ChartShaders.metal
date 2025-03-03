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

/// We'll store a transformMatrix in this uniform struct.
struct TransformUniform {
    float4x4 transformMatrix;
};

/*
  Orthographic-based vertex function.
  If your Swift code calls library.makeFunction(name: "orthographicVertex"),
  it will find this function.
*/
vertex VertexOut orthographicVertex(
    VertexIn inVertex [[stage_in]],
    constant TransformUniform &uniforms [[buffer(1)]]
)
{
    VertexOut out;
    // Apply the transform to the vertex position
    out.position = uniforms.transformMatrix * inVertex.position;
    out.color    = inVertex.color;
    return out;
}

fragment float4 fragmentShader(VertexOut inVertex [[stage_in]])
{
    // Pass the color through as the fragment output
    return inVertex.color;
}
