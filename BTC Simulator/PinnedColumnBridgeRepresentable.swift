//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import SwiftUI
import UIKit

// 1) Make sure to remove the default SwiftUI bar or hide it.
//    For example, wrap the view in a NavigationView, but hide that nav bar:
struct PinnedColumnBridgeRepresentable: View {

    // Dummy ObservedObjects
    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var simSettings: SimulationSettings

    var body: some View {
        // If you wrap this in a NavigationView, hide the bar:
        NavigationView {
            BridgeContainer(
                coordinator: coordinator,
                inputManager: inputManager,
                monthlySimSettings: monthlySimSettings,
                simSettings: simSettings
            )
            // 2) Let your UIKit view stretch under the safe areas:
            .ignoresSafeArea(.all)
            .navigationBarHidden(true)
        }
        // Or remove NavigationView altogether if you don’t need SwiftUI nav management
        .navigationViewStyle(StackNavigationViewStyle())
    }

    struct BridgeContainer: UIViewControllerRepresentable {
        let coordinator: SimulationCoordinator
        let inputManager: PersistentInputManager
        let monthlySimSettings: MonthlySimulationSettings
        let simSettings: SimulationSettings

        func makeCoordinator() -> Coordinator { Coordinator(self) }

        func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
            let vc = PinnedColumnBridgeViewController()
            vc.representableContainer = self
            return vc
        }
        
        func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                    context: Context) {
            uiViewController.representableContainer = self
        }
        
        class Coordinator: NSObject {
            var parent: BridgeContainer
            init(_ parent: BridgeContainer) {
                self.parent = parent
            }
        }
    }
}
