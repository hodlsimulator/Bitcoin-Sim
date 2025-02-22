//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import SwiftUI
import UIKit

struct PinnedColumnBridgeRepresentable: UIViewControllerRepresentable {
    /// A binding so SwiftUI can toggle this screen on/off.
    @Binding var isPresented: Bool

    /// ObservedObjects from your environment
    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var simSettings: SimulationSettings

    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let vc = PinnedColumnBridgeViewController()

        // 1) Provide references so your bridging VC can do its job
        vc.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )

        // 2) Pass the SwiftUI binding so the VC can set isPresented = false
        //    when the user taps back.
        vc.dismissBinding = $isPresented

        return vc
    }

    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                context: Context) {
        // If settings or data changes, refresh references
        uiViewController.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
    }
}
