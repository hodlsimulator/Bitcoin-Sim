//
//  SnapshotExtensions.swift
//  BTCMonteCarlo
//
//  Created by . . on 08/01/2025.
//

import SwiftUI
import UIKit

// MARK: - Snapshot Debugging Extension
extension View {
    func snapshot(label: String? = nil) -> UIImage {
        let controller = UIHostingController(rootView: self)
        
        // Force a dark background to avoid white flashes
        controller.view.backgroundColor = UIColor.black
        controller.view.isOpaque = true
        
        // Force layout so SwiftUI knows its size
        controller.view.layoutIfNeeded()
        
        // Create a suitable size
        let targetSize = controller.sizeThatFits(in: UIScreen.main.bounds.size)
        controller.view.bounds = CGRect(origin: .zero, size: targetSize)
        
        // Render into UIImage
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        
        return image
    }
}
