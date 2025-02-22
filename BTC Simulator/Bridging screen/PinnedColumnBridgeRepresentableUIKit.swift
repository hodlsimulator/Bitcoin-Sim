//
//  PinnedColumnBridgeRepresentableUIKit.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import SwiftUI
import UIKit

struct PinnedColumnBridgeRepresentableUIKit: UIViewControllerRepresentable {

    let coordinator: SimulationCoordinator
    let inputManager: PersistentInputManager
    let monthlySimSettings: MonthlySimulationSettings
    let simSettings: SimulationSettings

    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let vc = PinnedColumnBridgeViewController()
        
        // Make sure the parameter order matches how your BridgeContainer is defined.
        // For example, if BridgeContainer has:
        //   init(coordinator: SimulationCoordinator,
        //        inputManager: PersistentInputManager,
        //        monthlySimSettings: MonthlySimulationSettings,
        //        simSettings: SimulationSettings)
        // then call them in that exact order:
        vc.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
        return vc
    }

    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                context: Context) {
        uiViewController.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
    }
}
