//
//  BitcoinShapes.swift
//  BTCMonteCarlo
//
//  Created by . . on 28/12/2024.
//

import SwiftUI
import PocketSVG

extension CGPath {
    /// Utility for converting an SVG path string into a CGPath
    static func create(fromSVGPath svgString: String) -> CGPath {
        let paths = SVGBezierPath.paths(fromSVGString: svgString)
        let combined = CGMutablePath()
        for p in paths {
            combined.addPath(p.cgPath)
        }
        return combined
    }
}

// MARK: - Bitcoin Circle
struct BitcoinCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pathString = """
        <path d="M4030.06 2540.77 \
        c-273.24,1096.01 -1383.32,1763.02 -2479.46,1489.71 \
        -1095.68,-273.24 -1762.69,-1383.39 -1489.33,-2479.31 \
        273.12,-1096.13 1383.2,-1763.19 2479,-1489.95 \
        1096.06,273.24 1763.03,1383.51 1489.76,2479.57 \
        l0.02 -0.02z" />
        """
        
        let original = CGPath.create(fromSVGPath: pathString)
        let box = original.boundingBox
        let baseScale = min(rect.width / box.width, rect.height / box.height)
        let circleScale = baseScale * 1.08

        var transform = CGAffineTransform.identity
        transform = transform
            .translatedBy(x: rect.midX, y: rect.midY)
            .scaledBy(x: circleScale, y: circleScale)
            .translatedBy(x: -box.midX, y: -box.midY)

        let scaledPath = original.copy(using: &transform) ?? original
        return Path(scaledPath)
    }
}

// MARK: - Bitcoin B
struct BitcoinBShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pathString = """
        <path d="M2947.77 1754.38
        c40.72,-272.26 -166.56,-418.61 -450,-516.24
        l91.95 -368.8 -224.5 -55.94 -89.51 359.09
        c-59.02,-14.72 -119.63,-28.59 -179.87,-42.34
        l90.16 -361.46 -224.36 -55.94 -92 368.68
        c-48.84,-11.12 -96.81,-22.11 -143.35,-33.69
        l0.26 -1.16 -309.59 -77.31 -59.72 239.78
        c0,0 166.56,38.18 163.05,40.53 90.91,22.69 107.35,82.87 104.62,130.57
        l-104.74 420.15
        c6.26,1.59 14.38,3.89 23.34,7.49
        -7.49,-1.86 -15.46,-3.89 -23.73,-5.87
        l-146.81 588.57
        c-11.11,27.62 -39.31,69.07 -102.87,53.33
        2.25,3.26 -163.17,-40.72 -163.17,-40.72
        l-111.46 256.98 292.15 72.83
        c54.35,13.63 107.61,27.89 160.06,41.3
        l-92.9 373.03 224.24 55.94 92 -369.07
        c61.26,16.63 120.71,31.97 178.91,46.43
        l-91.69 367.33 224.51 55.94 92.89 -372.33
        c382.82,72.45 670.67,43.24 791.83,-303.02
        97.63,-278.78 -4.86,-439.58 -206.26,-544.44
        146.69,-33.83 257.18,-130.31 286.64,-329.61
        l-0.07 -0.05
        zm-512.93 719.26
        c-69.38,278.78 -538.76,128.08 -690.94,90.29
        l123.28 -494.2
        c152.17,37.99 640.17,113.17 567.67,403.91
        zm69.43 -723.3
        c-63.29,253.58 -453.96,124.75 -580.69,93.16
        l111.77 -448.21
        c126.73,31.59 534.85,90.55 468.94,355.05
        l-0.02 0z" />
        """
        
        let original = CGPath.create(fromSVGPath: pathString)
        let box = original.boundingBox
        let baseScale = min(rect.width / box.width, rect.height / box.height)
        let bScale = baseScale * 0.7

        var transform = CGAffineTransform.identity
        transform = transform
            .translatedBy(x: rect.midX, y: rect.midY)
            .scaledBy(x: bScale, y: bScale)
            .translatedBy(x: -box.midX, y: -box.midY)

        let scaledPath = original.copy(using: &transform) ?? original
        return Path(scaledPath)
    }
}

// MARK: - Combined official Bitcoin Logo
struct OfficialBitcoinLogo: View {
    /// The current rotation (in degrees) around the Y-axis.
    @State private var angle: Double = 0
    
    /// Degrees per second (positive = one direction, negative = the other).
    @State private var angleDelta: Double = 20
    
    /// Whether rotation is paused right now.
    @State private var isPaused: Bool = false
    
    /// Used to detect 2-tap vs 3-tap without clashing gesture recognisers.
    @State private var tapCount: Int = 0
    @State private var lastTapTime = Date.distantPast

    var body: some View {
        ZStack {
            // Orange circle
            BitcoinCircleShape()
                .fill(Color.orange)
            
            // White “B”
            BitcoinBShape()
                .fill(Color.white)
        }
        .frame(width: 120, height: 120)
        
        // Rotate the entire logo around the Y-axis (like a coin flip).
        // Using perspective = 0 removes the “stretching” effect.
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0)
        
        // Make the entire region tappable.
        .contentShape(Rectangle())
        
        // Single tap handler — we check how many times user tapped in quick succession.
        .onTapGesture {
            let now = Date()
            if now.timeIntervalSince(lastTapTime) < 0.3 {
                tapCount += 1
            } else {
                tapCount = 1
            }
            lastTapTime = now
            
            if tapCount == 2 {
                // Double-tap => flip rotation direction & unpause if needed
                angleDelta = -angleDelta
                isPaused = false
                
            } else if tapCount == 3 {
                // Triple-tap => pause or unpause
                isPaused.toggle()
                tapCount = 0  // reset after triple-tap
            }
        }
        
        // Update angle ~60 times/sec as long as we're not paused.
        .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
            guard !isPaused else { return }
            angle += angleDelta * (1.0 / 60.0)
            // We do NOT clamp or reset 'angle' to 0..360,
            // so it keeps rotating smoothly without a “snap.”
        }
    }
}
