//
//  TiltBarView.swift
//  BTCMonteCarlo
//
//  Created by . . on 01/02/2025.
//
/*
import SwiftUI

struct TiltBarView: View {
    // tiltValue ranges from -1.0 (full left) to 1.0 (full right)
    var tiltValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            ZStack {
                    // Gradient background: blue at left, grey in centre, red at right
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.blue, location: 0),
                            .init(color: Color.gray.opacity(0.3), location: 0.5),
                            .init(color: Color.red, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                
                // A centre line for reference
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2)
                    .offset(x: 0)
                
                // Indicator that moves with tiltValue
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 2)
                    .offset(x: indicatorOffset(width: width))
                    .animation(.easeInOut(duration: 0.3), value: tiltValue)
            }
        }
        .frame(height: 30)
    }
    
    // Calculate the x offset for the indicator.
    func indicatorOffset(width: CGFloat) -> CGFloat {
        // Convert tiltValue (-1...1) to a normalized value (0...1)
        let normalized = (tiltValue + 1) / 2
        // Place the indicator so its centre aligns correctly.
        return (width * CGFloat(normalized)) - (width / 2)
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
*/
