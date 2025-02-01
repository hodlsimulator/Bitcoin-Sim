//
//  TiltBarView.swift
//  BTCMonteCarlo
//
//  Created by . . on 01/02/2025.
//

import SwiftUI

struct TiltBarView: View {
    // tiltValue ranges from -1.0 (full left) to 1.0 (full right)
    var tiltValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            // Calculate widths for each side:
            let redWidth = tiltValue > 0 ? totalWidth * CGFloat(tiltValue) : 0
            let blueWidth = tiltValue < 0 ? totalWidth * CGFloat(abs(tiltValue)) : 0
            
            ZStack {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                
                // Blue bar (left side) for negative tilt
                HStack {
                    if blueWidth > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: blueWidth)
                            .animation(.easeInOut(duration: 0.3), value: blueWidth)
                    }
                    Spacer()
                }
                
                // Red bar (right side) for positive tilt
                HStack {
                    Spacer()
                    if redWidth > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: redWidth)
                            .animation(.easeInOut(duration: 0.3), value: redWidth)
                    }
                }
            }
        }
        .frame(height: 20)
    }
}

struct TiltBarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            TiltBarView(tiltValue: -0.5)
            TiltBarView(tiltValue: 0)
            TiltBarView(tiltValue: 0.5)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
