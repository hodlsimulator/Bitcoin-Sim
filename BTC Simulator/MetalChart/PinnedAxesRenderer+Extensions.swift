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
        
        // General text config once per call
        let labelScale: Float = 0.33
        let letterSpacing: Float = 4.0

        for val in xTicks {
            let sx = dataXtoScreenX(dataX: Float(val), transform: chartTransform)
            
            // Skip ticks left of pinned axis
            if sx < pinned { continue }
            
            // Draw the small vertical tick
            let y0 = pinnedScreenY
            let y1 = pinnedScreenY + tickLen
            verts.append(contentsOf: makeQuadList(
                x0: sx - halfT,
                y0: y0,
                x1: sx + halfT,
                y1: y1,
                color: tickColor
            ))
            
            // Decide label text
            var label = ""
            if range > 2.0 {
                label = "\(Int(val))y"
            } else if range > 0.5 {
                label = "\(Int(val * 12.0))m"
            } else {
                label = "\(Int(val * 52.0))w"
            }
            
            // Measure width (for “left of centre”)
            let labelWidth = textRenderer.measureStringWidth(
                label,
                scale: labelScale,
                letterSpacing: letterSpacing
            )
            // Pen X so label is left of tick
            let penX = sx - labelWidth - 10
            
            // Place label below the axis line
            let penY = pinnedScreenY + tickLen // top of text at tick tip
            // If you want a bit more space, add e.g. "+ 2"

            let textColor = SIMD4<Float>(1, 1, 1, 1)
            let (tBuf, vCount) = textRenderer.buildTextVertices(
                string: label,
                x: penX,
                y: penY,
                color: textColor,
                scale: labelScale,
                screenWidth: Float(viewportSize.width),
                screenHeight: Float(viewportSize.height),
                letterSpacing: letterSpacing
            )
            if let buf = tBuf {
                textBuffers.append((buf, vCount))
            }
        }
        
        return (verts, textBuffers)
    }
    
    // UPDATED buildYTicks FUNCTION
    // - Always uses round integers for the label (no decimals).
    // - Real value = 10^(logVal). Then we do Int(round(...)) for the label.
    func buildYTicks(
        _ yTicks: [Double],
        pinnedScreenX: Float,
        chartTransform: matrix_float4x4,
        maxDataValue: Double
    ) -> ([Float], [(MTLBuffer, Int)]) {
        
        var verts: [Float] = []
        var textBuffers: [(MTLBuffer, Int)] = []
        
        let tickLen: Float = 6
        let halfT: Float = 0.5
        let pinnedScreenY = Float(viewportSize.height) - 40
        let labelScale: Float = 0.33
        let letterSpacing: Float = 4.0
        let verticalOffset: Float = 0.0 // Adjust if labels are misaligned vertically (e.g., 2.0 to shift down)

        for logVal in yTicks {
            let sy = dataYtoScreenY(dataY: Float(logVal), transform: chartTransform)
            
            // Skip if off-screen or below the pinned axis line
            if sy < 0 || sy > Float(viewportSize.height) { continue }
            if sy > pinnedScreenY { continue }

            // Draw tick from (x0..x1)
            let x1 = pinnedScreenX
            let x0 = pinnedScreenX - tickLen
            verts.append(contentsOf: makeQuadList(
                x0: x0,
                y0: sy - halfT,
                x1: x1,
                y1: sy + halfT,
                color: tickColor
            ))

            // Format label
            let realVal = pow(10.0, logVal)
            let formatted = realVal.formattedGroupedSuffixNoDecimals()

            // Measure label dimensions
            let textWidth = textRenderer.measureStringWidth(
                formatted,
                scale: labelScale,
                letterSpacing: letterSpacing
            )
            let textHeight = textRenderer.measureStringHeight(
                formatted,
                scale: labelScale
            )

            // Option 1: Standard - Label to the left of tick
            let penX = x0 - textWidth - 5
            
            // Option 2: Horizontally centered over tick (uncomment if desired)
            // let tickMidX = (x0 + x1) / 2
            // let penX = tickMidX - (textWidth / 2)

            // Vertically center around sy with optional offset
            let penY = sy - (textHeight * 0.5) + verticalOffset

            let textColor = SIMD4<Float>(1, 1, 1, 1)
            let (tBuf, vCount) = textRenderer.buildTextVertices(
                string: formatted,
                x: penX,
                y: penY,
                color: textColor,
                scale: labelScale,
                screenWidth: Float(viewportSize.width),
                screenHeight: Float(viewportSize.height),
                letterSpacing: letterSpacing
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
    func buildYGridLines(
        _ yTicks: [Double],
        minX: Float,
        maxX: Float,
        chartTransform: matrix_float4x4
    ) {
        var verts: [Float] = []
        let thickness: Float = 1
        let halfT = thickness * 0.5
        
        // The pinned X-axis is 40 points from bottom => pinnedScreenY = height - 40
        let pinnedScreenY = Float(viewportSize.height) - 40
        
        for logVal in yTicks {
            let sy = dataYtoScreenY(dataY: Float(logVal), transform: chartTransform)
            
            // Skip if the line is off-screen
            if sy < 0 || sy > Float(viewportSize.height) {
                continue
            }
            
            // **Also skip if it's below the pinned X-axis**:
            if sy > pinnedScreenY {
                continue
            }
            
            // Build horizontal grid line
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

    /// Converts data Y (log scale or otherwise) to screen Y
    /// WITHOUT forcibly clamping to `[pinnedTop..pinnedBottom]`.
    func dataYtoScreenY(dataY: Float, transform: matrix_float4x4) -> Float {
        // Map domain->NDC, then NDC->screen
        let clip = transform * SIMD4<Float>(0, dataY, 0, 1)
        let ndcY = clip.y / clip.w
        let rawScreenY = (1.0 - (ndcY * 0.5 + 0.5)) * Float(viewportSize.height)
        return rawScreenY
    }
    
    /// X axis triangle strip
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
    
    // Y axis triangle strip:
    // pinned at x = pinnedScreenX, from screen Y=0 up to Y=viewport height (or however you like).
    func buildYAxisQuad(
        minDataY: Float,
        maxDataY: Float,
        transform: matrix_float4x4,
        pinnedScreenX: Float,
        pinnedScreenY: Float, // <-- Pass in so we can clamp
        thickness: Float,
        color: SIMD4<Float>
    ) -> [Float] {
        // Convert data space -> screen coords
        let topY = dataYtoScreenY(dataY: maxDataY, transform: transform)
        let botY = dataYtoScreenY(dataY: minDataY, transform: transform)
        
        let halfT = thickness * 0.5
        let x0 = pinnedScreenX - halfT
        let x1 = pinnedScreenX + halfT
        
        // In screen coords, smaller Y is visually "up"
        let scrTop = min(topY, botY)
        let scrBot = max(topY, botY)
        
        // Clamp the bottom so it won’t go below the x-axis line:
        let clampedBottom = min(scrBot, pinnedScreenY)
        
        // If the top is also below pinnedScreenY, it’s fine.
        // But if somehow scrTop is bigger than pinnedScreenY, clamp that too:
        let clampedTop = min(scrTop, pinnedScreenY)
        
        // If they end up reversed, no axis to draw:
        if clampedTop >= clampedBottom {
            return []
        }
        
        // Build a triangle strip from clampedTop..clampedBottom
        return [
            x0, clampedTop, 0, 1,  color.x, color.y, color.z, color.w,
            x1, clampedTop, 0, 1,  color.x, color.y, color.z, color.w,
            x0, clampedBottom, 0, 1, color.x, color.y, color.z, color.w,
            x1, clampedBottom, 0, 1, color.x, color.y, color.z, color.w
        ]
    }
}
