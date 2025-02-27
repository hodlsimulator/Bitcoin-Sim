//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import SwiftUI
import UIKit

struct PinnedColumnBridgeRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var lastViewedRow: Int  // Tracks the last viewed row
    @Binding var lastViewedColumnIndex: Int

    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var simSettings: SimulationSettings
    @ObservedObject var simChartSelection: SimChartSelection
    @ObservedObject var chartDataCache: ChartDataCache

    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let pinnedVC = PinnedColumnBridgeViewController()
        pinnedVC.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings,
            simChartSelection: simChartSelection,
            chartDataCache: chartDataCache
        )
        pinnedVC.dismissBinding              = $isPresented
        pinnedVC.lastViewedRowBinding        = $lastViewedRow
        pinnedVC.lastViewedColumnIndexBinding = $lastViewedColumnIndex
        return pinnedVC
    }

    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController, context: Context) {
        // Always keep references up to date
        uiViewController.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings,
            simChartSelection: simChartSelection,
            chartDataCache: chartDataCache
        )
        uiViewController.lastViewedRowBinding         = $lastViewedRow
        uiViewController.lastViewedColumnIndexBinding = $lastViewedColumnIndex

        // EXAMPLE: If your coordinator sets a flag after each new simulation,
        // we can reset the row/column memory here:
        if coordinator.shouldResetMemory {
            print("[PinnedColumnBridgeRepresentable] Resetting memory now.")
            // Reset row to 0, column to -1 (meaning "no memory" => fallback logic)
            lastViewedRow = 0
            lastViewedColumnIndex = -1

            // Clear the flag so we don't keep resetting
            coordinator.shouldResetMemory = false

            print("[PinnedColumnBridgeRepresentable] Reset row/column memory after new simulation.")
        }
    }
}

extension PinnedColumnBridgeRepresentable {
    func fullBleedStyle() -> some View {
        self
            .navigationBarHidden(true)           // Hide SwiftUI's navigation bar
            .navigationBarBackButtonHidden(true) // Prevent back button interference
            .ignoresSafeArea(.all, edges: .top)  // Extend content under the top edge
    }
}
