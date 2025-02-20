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
///         columns: [("BTC Price (USD)", \SimulationData.btcPriceUSD), ...],
///         lastViewedRow: $lastViewedRow,
///         scrollToBottomFlag: $scrollToBottomFlag
///     )
///
struct PinnedColumnTablesRepresentable: UIViewControllerRepresentable {

    // MARK: - Inputs from SwiftUI

    /// The array of rows you'll display (e.g. coordinator.monteCarloResults)
    let displayedData: [SimulationData]

    /// Title for the pinned column (e.g. "Week", "Month")
    let pinnedColumnTitle: String

    /// A key path to the pinned value in each SimulationData (e.g. \.week)
    let pinnedColumnKeyPath: KeyPath<SimulationData, Int>

    /// The list of additional columns you want on the right side.
    /// Each tuple is (columnTitle, keyPath).
    let columns: [(String, PartialKeyPath<SimulationData>)]

    /// Where we store or retrieve the user’s last viewed row.
    @Binding var lastViewedRow: Int

    /// If set to true from SwiftUI, we scroll to the bottom row.
    @Binding var scrollToBottomFlag: Bool
    
    @Binding var isAtBottom: Bool

    // MARK: - UIViewControllerRepresentable Requirements

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PinnedColumnTablesViewController {
        let vc = PinnedColumnTablesViewController()
        vc.representable = self
        return vc
    }

    func updateUIViewController(_ uiViewController: PinnedColumnTablesViewController,
                                context: Context) {
        uiViewController.representable = self

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
