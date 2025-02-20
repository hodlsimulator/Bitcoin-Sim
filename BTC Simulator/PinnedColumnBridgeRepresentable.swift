//
//  PinnedColumnBridgeRepresentable.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import SwiftUI
import UIKit

/// 1) A SwiftUI "parent" struct that appears as a View in navigation.
///    It shows a toolbar item with a chart icon on the right side,
///    while letting SwiftUI's default back button (chevron.left) appear on the left.
///
/// 2) It internally uses `BridgeContainer`, which is a UIViewControllerRepresentable
///    that actually creates and updates the UIKit `PinnedColumnBridgeViewController`.
struct PinnedColumnBridgeRepresentable: View {
    
    // MARK: - Observed Objects (passed in from the parent SwiftUI view)
    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var simSettings: SimulationSettings

    // MARK: - Body
    var body: some View {
        BridgeContainer(
            coordinator: coordinator,
            inputManager: inputManager,
            monthlySimSettings: monthlySimSettings,
            simSettings: simSettings
        )
        .onAppear {
            print("PinnedColumnBridgeRepresentable onAppear => coordinator ID:",
                  ObjectIdentifier(coordinator))
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    print("Chart icon tapped!")
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Nested BridgeContainer
    /// This internal struct is the actual UIViewControllerRepresentable
    /// that creates/updates `PinnedColumnBridgeViewController`.
    struct BridgeContainer: UIViewControllerRepresentable {
        
        // Pass references down to the UIKit VC if needed
        let coordinator: SimulationCoordinator
        let inputManager: PersistentInputManager
        let monthlySimSettings: MonthlySimulationSettings
        let simSettings: SimulationSettings
        
        // MARK: - Make Coordinator
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        // MARK: - Make UIViewController
        func makeUIViewController(context: Context) -> PinnedColumnBridgeViewController {
            let vc = PinnedColumnBridgeViewController()
            // Provide them with a reference to this container
            vc.representableContainer = self
            return vc
        }
        
        // MARK: - Update UIViewController
        func updateUIViewController(_ uiViewController: PinnedColumnBridgeViewController,
                                    context: Context) {
            uiViewController.representableContainer = self
        }
        
        // MARK: - Coordinator
        class Coordinator: NSObject {
            var parent: BridgeContainer
            init(_ parent: BridgeContainer) {
                self.parent = parent
            }
        }
    }
}
