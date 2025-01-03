//
//  LandscapePlaceholderView.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/01/2025.
//

import SwiftUI

struct LandscapePlaceholderView: View {
    let image: UIImage

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                // Force it to fill the entire landscape frame,
                // which will "squish" if aspect ratios differ.
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
