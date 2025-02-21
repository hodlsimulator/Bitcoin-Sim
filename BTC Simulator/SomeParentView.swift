//
//  SomeParentView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//
/*
import SwiftUI

/// A SwiftUI view that demonstrates how to embed the pinned-column UIKit layout.
/// We pass data in, show a floating "Scroll to Bottom" button, etc.
struct SomeParentView: View {

    @EnvironmentObject var coordinator: SimulationCoordinator

    // The state to remember the last row scrolled
    @State private var lastViewedRow = 0

    // A flag that triggers scrolling to bottom
    @State private var scrollToBottomFlag = false
    
    // Whether we're currently near the bottom of the pinned tables
    @State private var isAtBottom = false

    var body: some View {
        NavigationView {
            ZStack {
                // The UIKit bridging view
                PinnedColumnTablesRepresentable(
                    displayedData: coordinator.monteCarloResults,
                    pinnedColumnTitle: "Week",
                    pinnedColumnKeyPath: \SimulationData.week,
                    columns: myColumns,
                    lastViewedRow: $lastViewedRow,
                    scrollToBottomFlag: $scrollToBottomFlag,
                    // IMPORTANT: pass the new isAtBottom binding here
                    isAtBottom: $isAtBottom
                )
                .edgesIgnoringSafeArea(.bottom)

                // Floating “Scroll to Bottom” button if not already at bottom
                if !isAtBottom {
                    VStack {
                        Spacer()
                        Button(action: {
                            scrollToBottomFlag = true
                        }) {
                            Image(systemName: "chevron.down.circle")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(white: 0.2).opacity(0.9))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
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
*/
