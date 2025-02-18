//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import SwiftUI
import UIKit

/// A SwiftUI wrapper that hosts the UIKit-based PinnedColumnBridgeViewController.
/// This struct passes environment objects into the UIKit controller.
struct PinnedColumnBridgeRepresentable: UIViewControllerRepresentable {
    
    // EnvironmentObjects we want to make accessible in the UIViewController.
    @EnvironmentObject var coordinator: SimulationCoordinator
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var simSettings: SimulationSettings

    // MARK: - UIViewControllerRepresentable Requirements
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
        let vc = PinnedColumnBridgeViewController()
        // Give the VC a reference to this representable so it can access environment objects.
        vc.representable = self
        return vc
    }
    
    func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                context: Context) {
        // Keep the representable in sync if needed
        uiViewController.representable = self
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var parent: PinnedColumnBridgeRepresentable
        
        init(_ parent: PinnedColumnBridgeRepresentable) {
            self.parent = parent
        }
    }
}
