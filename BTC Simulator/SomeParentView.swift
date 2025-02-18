//
//  SomeParentView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import SwiftUI

/// A SwiftUI view that demonstrates how to embed the pinned-column UIKit layout.
/// We pass data in, show a "Scroll to Bottom" button, etc.
struct SomeParentView: View {

    // Example: your final array of rows
    @EnvironmentObject var coordinator: SimulationCoordinator

    // The state to remember the last row scrolled
    @State private var lastViewedRow = 0

    // A flag that triggers scrolling to bottom
    @State private var scrollToBottomFlag = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                HStack {
                    Button("Scroll to Bottom") {
                        scrollToBottomFlag = true
                    }
                    .padding()

                    Spacer()
                }

                // Our bridging view
                PinnedColumnTablesRepresentable(
                    displayedData: coordinator.monteCarloResults,
                    pinnedColumnTitle: "Week",          // Not strictly displayed, but you can
                    pinnedColumnKeyPath: \SimulationData.week,  // The property for pinned col
                    columns: myColumns,                 // We'll define this below
                    lastViewedRow: $lastViewedRow,
                    scrollToBottomFlag: $scrollToBottomFlag
                )
                .edgesIgnoringSafeArea(.bottom)
            }
            .navigationBarTitle("Pinned Column Table", displayMode: .inline)
        }
    }

    // Example columns
    private var myColumns: [(String, PartialKeyPath<SimulationData>)] {
        return [
            ("BTC Price (USD)", \SimulationData.btcPriceUSD),
            ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
            ("Contrib (USD)", \SimulationData.contributionUSD),
            // etc...
        ]
    }
}
