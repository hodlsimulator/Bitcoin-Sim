//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import SwiftUI
import UIKit

struct PinnedColumnBridgeRepresentable: UIViewControllerRepresentable {

    // This binding controls whether SwiftUI considers this screen "presented."
    @Binding var isPresented: Bool

    // Any needed references
    let coordinator: SimulationCoordinator
    let inputManager: PersistentInputManager
    let monthlySimSettings: MonthlySimulationSettings
    let simSettings: SimulationSettings

    // Create the UIViewController
    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let vc = PinnedColumnBridgeViewController()

        // 1) Pass the SwiftUI binding to your UIKit VC
        vc.dismissBinding = $isPresented

        // 2) Pass the container with coordinator and settings
        //    (whatever your existing VC expects)
        vc.representableContainer = .init(
            coordinator: coordinator,
            simSettings: simSettings,
            monthlySimSettings: monthlySimSettings,
            inputManager: inputManager
        )

        return vc
    }

    // Update as needed if your data changes
    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                context: Context) {
        // E.g., if you need to refresh the container references:
        uiViewController.representableContainer = .init(
            coordinator: coordinator,
            simSettings: simSettings,
            monthlySimSettings: monthlySimSettings,
            inputManager: inputManager
        )
    }
}
