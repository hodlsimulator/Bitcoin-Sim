//
//  PinnedColumnTablesRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import SwiftUI

/// A SwiftUI wrapper around the UIKit-based pinned-column table layout.
struct PinnedColumnTablesRepresentable: UIViewControllerRepresentable {

    // MARK: - Inputs from SwiftUI

    let displayedData: [SimulationData]
    let pinnedColumnTitle: String
    let pinnedColumnKeyPath: KeyPath<SimulationData, Int>
    let columns: [(String, PartialKeyPath<SimulationData>)]

    @Binding var lastViewedRow: Int
    @Binding var lastViewedColumnIndex: Int
    @Binding var scrollToBottomFlag: Bool
    @Binding var isAtBottom: Bool

    // MARK: - UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PinnedColumnTablesViewController {
        // Decide which class to use at creation time, based on device orientation
        let isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        
        let vc: PinnedColumnTablesViewController
        if isLandscape {
            // Our subclass for landscape
            vc = PinnedColumnTablesLandscapeViewController()
        } else {
            // The original portrait class
            vc = PinnedColumnTablesViewController()
        }
        
        vc.representable = self
        
        // Update SwiftUI's isAtBottom whenever near-bottom changes
        vc.onIsAtBottomChanged = { newValue in
            self.isAtBottom = newValue
        }
        
        return vc
    }

    func updateUIViewController(_ uiViewController: PinnedColumnTablesViewController,
                                context: Context) {
        // Keep the representable in sync
        uiViewController.representable = self
        
        // If near-bottom changes, update SwiftUI
        uiViewController.onIsAtBottomChanged = { newValue in
            self.isAtBottom = newValue
        }

        // If SwiftUI sets scrollToBottomFlag, scroll once & reset
        if scrollToBottomFlag {
            uiViewController.scrollToBottom()
            DispatchQueue.main.async {
                self._scrollToBottomFlag.wrappedValue = false
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var parent: PinnedColumnTablesRepresentable
        init(_ parent: PinnedColumnTablesRepresentable) {
            self.parent = parent
        }
    }
}
