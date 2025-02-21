//
//  PinnedColumnTablesRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import SwiftUI

/// A SwiftUI wrapper around the UIKit-based pinned-column table layout.
///
/// Usage example inside SwiftUI:
///
///     PinnedColumnTablesRepresentable(
///         displayedData: mySimulationDataArray,
///         pinnedColumnTitle: "Week",
///         pinnedColumnKeyPath: \SimulationData.week,
///         columns: [
///             ("BTC Price (USD)", \SimulationData.btcPriceUSD),
///             ("Portfolio (USD)", \SimulationData.portfolioValueUSD)
///         ],
///         lastViewedRow: $lastViewedRow,
///         scrollToBottomFlag: $scrollToBottomFlag,
///         isAtBottom: $isAtBottom
///     )
///
struct PinnedColumnTablesRepresentable: UIViewControllerRepresentable {

    // MARK: - Inputs from SwiftUI

    /// The array of rows you'll display (e.g. coordinator.monteCarloResults)
    let displayedData: [SimulationData]

    /// Title for the pinned column (e.g. "Week", "Month")
    let pinnedColumnTitle: String

    /// A key path to the pinned value in each SimulationData (e.g. \.week)
    /// This pinned column is shown on the left and does NOT need to be
    /// included in 'columns' below.
    let pinnedColumnKeyPath: KeyPath<SimulationData, Int>

    /// The list of additional columns you want on the right side.
    /// Each tuple is (columnTitle, keyPath).
    /// IMPORTANT: If you want these columns to appear in the pager,
    /// each partial key path must point to a Decimal property.
    let columns: [(String, PartialKeyPath<SimulationData>)]

    /// Where we store or retrieve the user’s last viewed row.
    @Binding var lastViewedRow: Int

    /// If set to true from SwiftUI, we scroll to the bottom row.
    @Binding var scrollToBottomFlag: Bool
    
    /// Whether or not the user is currently scrolled near the bottom
    @Binding var isAtBottom: Bool

    // MARK: - UIViewControllerRepresentable Requirements

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PinnedColumnTablesViewController {
        let vc = PinnedColumnTablesViewController()
        vc.representable = self
        
        // Whenever the pinned VC detects near-bottom scrolling, update SwiftUI's binding
        vc.onIsAtBottomChanged = { newValue in
            self.isAtBottom = newValue
        }
        
        return vc
    }

    func updateUIViewController(_ uiViewController: PinnedColumnTablesViewController,
                                context: Context) {
        uiViewController.representable = self

        // Hook up again in case the VC is re-used
        uiViewController.onIsAtBottomChanged = { newValue in
            self.isAtBottom = newValue
        }

        // If SwiftUI sets scrollToBottomFlag:
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
