//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by . . on 18/02/2025.
//

import SwiftUI

/// A SwiftUI wrapper around a custom UIKit UIViewController.
/// This is where we’ll eventually display the pinned column layout.
struct PinnedColumnBridgeRepresentable: UIViewControllerRepresentable {
    
    // In the future, we’ll pass in all the data/objects we need
    // e.g. summary data, row memory, coordinator, etc.
    // For now, just a placeholder:
    
    // MARK: - Make Coordinator
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Make UIViewController
    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let vc = PinnedColumnBridgeViewController()
        // If we need to pass any references, we can do it here, e.g:
        // vc.coordinator = self.coordinator
        return vc
    }
    
    // MARK: - Update UIViewController
    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                context: Context) {
        // In the future, we’ll update the UI if SwiftUI changes something
    }
    
    // MARK: - Coordinator Class
    class Coordinator: NSObject {
        let parent: PinnedColumnBridgeRepresentable
        init(_ parent: PinnedColumnBridgeRepresentable) {
            self.parent = parent
        }
    }
}
