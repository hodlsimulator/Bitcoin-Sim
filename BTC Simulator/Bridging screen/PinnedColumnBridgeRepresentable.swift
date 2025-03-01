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
    @Binding var lastViewedRow: Int  // Added to track the last viewed row
    @Binding var lastViewedColumnIndex: Int
    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var simSettings: SimulationSettings
    @ObservedObject var simChartSelection: SimChartSelection
    @ObservedObject var chartDataCache: ChartDataCache
    
    @EnvironmentObject var idleManager: IdleManager

    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let pinnedVC = PinnedColumnBridgeViewController()
        pinnedVC.idleManager = idleManager

        pinnedVC.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings,
            simChartSelection: simChartSelection,
            chartDataCache: chartDataCache
        )
        pinnedVC.dismissBinding = $isPresented
        pinnedVC.lastViewedRowBinding = $lastViewedRow
        pinnedVC.lastViewedColumnIndexBinding = $lastViewedColumnIndex

        return pinnedVC
    }

    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController, context: Context) {
        uiViewController.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings,
            simChartSelection: simChartSelection,
            chartDataCache: chartDataCache
        )
        uiViewController.lastViewedRowBinding = $lastViewedRow  // Update the binding
        uiViewController.lastViewedColumnIndexBinding = $lastViewedColumnIndex
    }
}

extension PinnedColumnBridgeRepresentable {
    func fullBleedStyle() -> some View {
        self
            .navigationBarHidden(true)           // Hide SwiftUI's navigation bar
            .navigationBarBackButtonHidden(true) // Prevent back button interference
            .ignoresSafeArea(.all, edges: .top)  // Allow content to extend to top edge
    }
}
