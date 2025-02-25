//
//  PinnedColumnTablesRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import SwiftUI

/// A SwiftUI wrapper around the UIKit-based pinned-column table layout.
/// This shows the pinned column (e.g., Week or Month) on the left,
/// and swipable columns on the right via a ColumnsCollectionViewController.
struct PinnedColumnTablesRepresentable: UIViewControllerRepresentable {

    // MARK: - Inputs from SwiftUI

    /// The array of rows you'll display (e.g. coordinator.monteCarloResults)
    let displayedData: [SimulationData]

    /// Title for the pinned column (e.g. "Week", "Month")
    let pinnedColumnTitle: String

    /// A key path to the pinned value in each SimulationData (e.g. \.week).
    /// This pinned column is shown on the left.
    let pinnedColumnKeyPath: KeyPath<SimulationData, Int>

    /// The list of additional columns for the right side.
    /// Each tuple is (columnTitle, partial key path).
    /// PartialKeyPath can reference Decimal, Double, or Int.
    let columns: [(String, PartialKeyPath<SimulationData>)]

    /// Where we store or retrieve the user's last viewed row in the table.
    @Binding var lastViewedRow: Int
    
    @Binding var lastViewedColumnIndex: Int

    /// If set to true from SwiftUI, we scroll to the bottom row.
    @Binding var scrollToBottomFlag: Bool
    
    /// Whether or not the user is currently scrolled near the bottom
    @Binding var isAtBottom: Bool

    // MARK: - UIViewControllerRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PinnedColumnTablesViewController {
        let vc = PinnedColumnTablesViewController()
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
        
        // If the pinned VC detects near-bottom scrolling, update SwiftUI
        uiViewController.onIsAtBottomChanged = { newValue in
            self.isAtBottom = newValue
        }

        // If SwiftUI sets scrollToBottomFlag, scroll to bottom once and reset the flag
        if scrollToBottomFlag {
            uiViewController.scrollToBottom()
            // Reset the flag to avoid repeated scrolling
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
