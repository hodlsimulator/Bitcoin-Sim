//
//  PinnedAxesRenderer+Extensions.swift
//  BTCMonteCarlo
//
//  Created by . . on 03/03/2025.
//

import MetalKit
import simd
import UIKit

extension PinnedAxesRenderer {
    
    // MARK: - Building the Ticks (Modified Y to show "real" log values)
    
    /// X Ticks remain the same, because we're still in linear X domain
    func buildXTicks(
        _ xTicks: [Double],
        pinnedScreenY: Float,
        chartTransform: matrix_float4x4,
        minX: Float,
        maxX: Float
    ) -> ([Float], [(MTLBuffer, Int)]) {
        
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []
        
        let pinned = pinnedAxisX
        let tickLen: Float = 6
        let halfT: Float = 0.5
        let range = Double(maxX - minX)
        
        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            
            // Skip ticks that are left of the pinned axis
            if sx < pinned {
                continue
            }
            
            // Build short tick line in grey (move it downward from the axis)
            let y0 = pinnedScreenY
            let y1 = pinnedScreenY + tickLen
            verts.append(contentsOf: makeQuadList(
                x0: sx - halfT,
                y0: y0,
                x1: sx + halfT,
                y1: y1,
                color: tickColor  // <-- Remains grey
            ))
            
            // Decide label format
            var label = ""
            if range > 2.0 {
                label = "\(Int(val))y"
            } else if range > 0.5 {
                let months = Int(val * 12.0)
                label = "\(months)m"
            } else {
                let weeks = Int(val * 52.0)
                label = "\(weeks)w"
            }
            
            // White text for label
            let textColor = SIMD4<Float>(1,1,1,1)
            
            // Place text below the axis
            let textY = pinnedScreenY + tickLen + 20
            let (tBuf, vCount) = textRenderer.buildTextVertices(
                string: label,
                x: sx,
                y: textY,
                color: textColor,   // <-- Use pure white
                scale: 0.35,
                screenWidth: Float(viewportSize.width),
                screenHeight: Float(viewportSize.height),
                letterSpacing: 4.0
            )
            if let buf = tBuf {
                textBuffers.append((buf, vCount))
            }
        }
        
        return (verts, textBuffers)
    }
    
    func buildYTicks(
        _ yTicksIn: [Double],
        pinnedScreenX: Float,
        pinnedScreenY: Float,
        chartTransform: matrix_float4x4
    ) -> ([Float], [(MTLBuffer, Int)]) {
        
        // 1) Make a local copy
        var yTicks = yTicksIn

        // 2) Check if we already have a tick above the top log domain
        //    If domainMaxLogY is 5.2, and we have no tick above 5.2, then add one.
        let hasTickAbove = yTicks.contains { $0 > Double(domainMaxLogY) }
        if !hasTickAbove {
            // Add 0.1 in log space or whatever offset you like:
            yTicks.append(Double(domainMaxLogY) + 0.1)
        }

        // 3) Normal Y‐tick rendering
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []

        let tickLen: Float = 6
        let halfT: Float = 0.5

        for logVal in yTicks {
            let sy = dataYtoScreenY(dataY: Float(logVal), transform: chartTransform)
            
            // clip to within the pinned area
            if sy < 0 || sy > pinnedScreenY { continue }

            // short tick
            let x1 = pinnedScreenX
            let x0 = pinnedScreenX - tickLen
            verts.append(contentsOf: makeQuadList(
                x0: x0,
                y0: sy - halfT,
                x1: x1,
                y1: sy + halfT,
                color: tickColor
            ))

            // label
            let realVal = pow(10.0, logVal)
            let formatted = realVal.formattedGroupedSuffixNoDecimals()
            let textColor = SIMD4<Float>(1,1,1,1)
            let textX = pinnedScreenX - tickLen - 30
            let textY = sy - 5

            let (tBuf, vCount) = textRenderer.buildTextVertices(
                string: formatted,
                x: textX,
                y: textY,
                color: textColor,
                scale: 0.35,
                screenWidth: Float(viewportSize.width),
                screenHeight: Float(viewportSize.height),
                letterSpacing: 4.0
            )
            if let buf = tBuf {
                textBuffers.append((buf, vCount))
            }
        }
        
        return (verts, textBuffers)
    }
}

// MARK: - Grid Lines

extension PinnedAxesRenderer {
    func buildXGridLines(
        _ xTicks: [Double],
        minY: Float,
        maxY: Float,
        pinnedScreenX: Float,
        chartTransform: matrix_float4x4
    ) {
        var verts: [Float] = []
        let thickness: Float = 1
        let halfT = thickness * 0.5
        
        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            if sx < pinnedScreenX { continue }
            if sx > Float(viewportSize.width) { continue }
            
            verts.append(
                contentsOf: makeQuadList(
                    x0: sx - halfT,
                    y0: minY,
                    x1: sx + halfT,
                    y1: maxY,
                    color: gridColor
                )
            )
        }
        
        xGridVertexCount = verts.count / 8
        
        if !verts.isEmpty {
            xGridBuffer = device.makeBuffer(
                bytes: verts,
                length: verts.count * MemoryLayout<Float>.size,
                options: .storageModeShared
            )
        } else {
            xGridBuffer = nil
        }
    }
    
    /// Horizontal lines from pinnedLeft..(viewport width)
    /// clipped to [pinnedTop..pinnedBottom]
    func buildYGridLines(
        _ yTicks: [Double],
        minX: Float,
        maxX: Float,
        pinnedScreenY: Float,   // we won’t actually use pinnedScreenY now
        chartTransform: matrix_float4x4
    ) {
        var verts: [Float] = []
        let thickness: Float = 1
        let halfT = thickness * 0.5
        
        let pinnedTop: Float = 50
        let pinnedBottom: Float = Float(viewportSize.height) - 40
        
        for logVal in yTicks {
            let sy = dataYtoScreenY(dataY: Float(logVal), transform: chartTransform)
            
            if sy < pinnedTop { continue }
            if sy > pinnedBottom { continue }
            
            verts.append(contentsOf: makeQuadList(
                x0: minX,
                y0: sy - halfT,
                x1: maxX,
                y1: sy + halfT,
                color: gridColor
            ))
        }
        
        yGridVertexCount = verts.count / 8
        
        if !verts.isEmpty {
            yGridBuffer = device.makeBuffer(
                bytes: verts,
                length: verts.count * MemoryLayout<Float>.size,
                options: .storageModeShared
            )
        } else {
            yGridBuffer = nil
        }
    }
}

// MARK: - Helpers

extension PinnedAxesRenderer {
    
    /// Build 2 triangles (6 vertices) for a filled quad
    func makeQuadList(
        x0: Float, y0: Float,
        x1: Float, y1: Float,
        color: SIMD4<Float>
    ) -> [Float] {
        return [
            // Triangle 1
            x0, y0, 0, 1, color.x, color.y, color.z, color.w,
            x0, y1, 0, 1, color.x, color.y, color.z, color.w,
            x1, y0, 0, 1, color.x, color.y, color.z, color.w,
            // Triangle 2
            x1, y0, 0, 1, color.x, color.y, color.z, color.w,
            x0, y1, 0, 1, color.x, color.y, color.z, color.w,
            x1, y1, 0, 1, color.x, color.y, color.z, color.w
        ]
    }
    
    /// Converts data X to screen X
    func dataXtoScreenX(dataX: Float, transform: matrix_float4x4) -> Float {
        let clip = transform * SIMD4<Float>(dataX, 0, 0, 1)
        let ndcX = clip.x / clip.w
        return (ndcX * 0.5 + 0.5) * Float(viewportSize.width)
    }

    /// Converts data Y to screen Y
    /// If your domain is log, dataY is log10(value).
    /// Converts dataY (log scale) -> pinned top..bottom
    func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        // original logic => rawScreenY in [0..height]
        let clip = transform * SIMD4<Float>(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        let rawScreenY = (1.0 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
        
        let pinnedTop: Float = 50
        let pinnedBottom: Float = Float(viewportSize.height) - 40
        let chartHeight = pinnedBottom - pinnedTop
        
        let ratio = rawScreenY / Float(viewportSize.height)
        let finalY = pinnedTop + ratio*chartHeight
        
        return finalY
    }
    
    // X axis triangle strip
    func buildXAxisQuad(
        minDataX: Float,
        maxDataX: Float,
        transform: matrix_float4x4,
        pinnedScreenX: Float,
        pinnedScreenY: Float,
        thickness: Float,
        color: SIMD4<Float>
    ) -> [Float] {
        var rightX = dataXtoScreenX(dataX: maxDataX, transform: transform)
        if rightX < pinnedScreenX {
            rightX = pinnedScreenX
        }
        
        let halfT = thickness * 0.5
        let y0 = pinnedScreenY - halfT
        let y1 = pinnedScreenY + halfT
        
        // Force the left side of the axis to pinnedScreenX
        var verts: [Float] = []
        verts.append(pinnedScreenX); verts.append(y0); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)

        verts.append(pinnedScreenX); verts.append(y1); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)

        verts.append(rightX);        verts.append(y0); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)

        verts.append(rightX);        verts.append(y1); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        return verts
    }
    
    // Y axis triangle strip
    /// The left axis from pinnedBottom..pinnedTop
    func buildYAxisQuad(
        minDataY: Float,
        maxDataY: Float,
        transform: matrix_float4x4,
        pinnedScreenX: Float,
        pinnedScreenY: Float,  // ignoring pinnedScreenY
        thickness: Float,
        color: SIMD4<Float>
    ) -> [Float] {
        let pinnedTop: Float = 50
        let pinnedBottom: Float = Float(viewportSize.height) - 40
        
        // The top in domain is maxDataY
        // The bottom in domain is minDataY
        var topY = dataYtoScreenY(dataY: maxDataY, transform: transform)
        var botY = dataYtoScreenY(dataY: minDataY, transform: transform)
        
        // clamp to [pinnedTop..pinnedBottom]
        if topY < pinnedTop { topY = pinnedTop }
        if topY > pinnedBottom { topY = pinnedBottom }
        if botY < pinnedTop { botY = pinnedTop }
        if botY > pinnedBottom { botY = pinnedBottom }
        
        let halfT = thickness * 0.5
        let x0 = pinnedScreenX - halfT
        let x1 = pinnedScreenX + halfT
        
        var verts: [Float] = []
        // We make a triangle strip from (x0,botY) -> (x0,topY)
        
        // 1
        verts.append(x0); verts.append(botY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        // 2
        verts.append(x1); verts.append(botY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        // 3
        verts.append(x0); verts.append(topY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        // 4
        verts.append(x1); verts.append(topY); verts.append(0); verts.append(1)
        verts.append(color.x); verts.append(color.y); verts.append(color.z); verts.append(color.w)
        
        return verts
    }
}
    
