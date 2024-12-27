//
//  VisualEffectBlur.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper around UIVisualEffectView for applying a blur effect.
struct VisualEffectBlur: UIViewRepresentable {
    let blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        // If you want to dynamically change the blur style,
        // you could implement that here. Otherwise, this can remain empty.
    }
}
