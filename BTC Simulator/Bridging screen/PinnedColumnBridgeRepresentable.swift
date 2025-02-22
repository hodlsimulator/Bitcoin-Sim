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
    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var simSettings: SimulationSettings

    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        // Create your pinned VC
        let pinnedVC = PinnedColumnBridgeViewController()
        pinnedVC.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
        pinnedVC.dismissBinding = $isPresented

        // Return pinnedVC directly (no extra UINavigationController)
            return pinnedVC
    }

    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                     context: Context) {
        // Update references if needed
        uiViewController.representableContainer = .init(
                coordinator: coordinator,
                inputManager: inputManager,
                monthlySimSettings: monthlySimSettings,
                simSettings: simSettings
            )
        }
    }
