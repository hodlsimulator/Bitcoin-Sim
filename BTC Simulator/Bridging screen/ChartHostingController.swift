//
//  ChartHostingController.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/02/2025.
//

import SwiftUI
import UIKit

/// A generic UIHostingController subclass that can wrap any SwiftUI view.
/// It takes a "content: Content" (some View), then injects environment objects
/// like SimulationCoordinator, etc., before calling super.init.
class ChartHostingController<Content: View>: UIHostingController<AnyView> {

    // Keep references to any environment objects you need:
    let coordinator: SimulationCoordinator
    let chartDataCache: ChartDataCache
    let simSettings: SimulationSettings
    let idleManager: IdleManager

    /// The designated initialiser.
    /// - Parameters:
    ///   - coordinator: A SimulationCoordinator to inject
    ///   - chartDataCache: A ChartDataCache to inject
    ///   - simSettings: The user’s SimulationSettings
    ///   - idleManager: The IdleManager for screen dim
    ///   - content: **some** SwiftUI View (e.g. InteractiveMonteCarloChartView)
    init(
        coordinator: SimulationCoordinator,
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings,
        idleManager: IdleManager,
        content: Content
    ) {
        self.coordinator    = coordinator
        self.chartDataCache = chartDataCache
        self.simSettings    = simSettings
        self.idleManager    = idleManager

        // 1) Wrap the SwiftUI Content in environment objects, then wrap in AnyView
        let finalView = AnyView(
            content
                .environmentObject(coordinator)
                .environmentObject(chartDataCache)
                .environmentObject(simSettings)
                .environmentObject(idleManager)
        )

        // 2) Pass that final SwiftUI view to super
        super.init(rootView: finalView)
    }

    /// Required for storyboard / XIB
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear

        let itemAppearance = UIBarButtonItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = itemAppearance
        appearance.backButtonAppearance = itemAppearance
        
        // Hide default back text
        appearance.backButtonAppearance.normal.titlePositionAdjustment =
            UIOffset(horizontal: -2000, vertical: 0)
        
        navigationItem.standardAppearance   = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.backButtonDisplayMode = .minimal
        
        navigationController?.navigationBar.tintColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}
