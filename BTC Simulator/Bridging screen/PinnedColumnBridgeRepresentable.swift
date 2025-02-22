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

    func makeUIViewController(context: Context) -> UIViewController {
        // Create your pinned VC
        let pinnedVC = PinnedColumnBridgeViewController()
        pinnedVC.representableContainer = .init(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
        pinnedVC.dismissBinding = $isPresented

        // Embed it in a UINavigationController
        let navController = UINavigationController(rootViewController: pinnedVC)
        
        // Optional: configure nav bar tints etc.
        navController.navigationBar.tintColor = .white
        
        return navController
    }

    func updateUIViewController(_ uiViewController: UIViewController,
                                context: Context) {
        // Update references if needed
        if let navController = uiViewController as? UINavigationController,
           let pinnedVC = navController.viewControllers.first as? PinnedColumnBridgeViewController {
            
            pinnedVC.representableContainer = .init(
                coordinator: coordinator,
                inputManager: inputManager,
                monthlySimSettings: monthlySimSettings,
                simSettings: simSettings
            )
        }
    }
}
