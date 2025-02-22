//
//  PinnedColumnBridgeRepresentableUIKit.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import SwiftUI
import UIKit

struct PinnedColumnBridgeRepresentableUIKit: UIViewControllerRepresentable {

    // A binding to track whether this screen is presented in SwiftUI
    @Binding var isPresented: Bool

    let coordinator: SimulationCoordinator
    let inputManager: PersistentInputManager
    let monthlySimSettings: MonthlySimulationSettings
    let simSettings: SimulationSettings

    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let vc = PinnedColumnBridgeViewController()

        // Match the order: (coordinator, inputManager, monthlySimSettings, simSettings)
        vc.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )

        // Provide the SwiftUI binding for dismiss
        vc.dismissBinding = $isPresented

        return vc
    }

    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                context: Context) {
        // Same order here if you’re updating references
        uiViewController.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
    }
}
