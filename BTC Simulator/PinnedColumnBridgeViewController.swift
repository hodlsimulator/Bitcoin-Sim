//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 18/02/2025.
//

import UIKit
import SwiftUI

/// A UIViewController that shows:
///  - The default SwiftUI back button (white chevron) in the nav bar.
///  - A right bar button item with a "chart.line.uptrend.xyaxis" icon.
///  - A SwiftUI summary card below the nav bar.
///  - A placeholder for the pinned table area.
class PinnedColumnBridgeViewController: UIViewController {

    // Set by the SwiftUI bridge (PinnedColumnBridgeRepresentable).
    var representable: PinnedColumnBridgeRepresentable?
    
    var representableContainer: PinnedColumnBridgeRepresentable.BridgeContainer?

    // Container for the summary card (UIHostingController)
    private let summaryHostingContainer = UIView()

    // Placeholder for pinned table
    private let pinnedTablePlaceholder = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // 1) Add a chart icon to the nav bar (right side).
        setupChartBarButton()

        // 2) Setup the summary card (SwiftUI hosting).
        setupSummaryCardHosting()

        // 3) Placeholder for pinned table
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)

        // 4) Lay out the summary card + placeholder in a vertical stack
        let mainStack = UIStackView(arrangedSubviews: [
            summaryHostingContainer,
            pinnedTablePlaceholder
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Chart bar button

    private func setupChartBarButton() {
        // Create a UIBarButtonItem with system icon "chart.line.uptrend.xyaxis"
        let chartIconItem = UIBarButtonItem(
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            style: .plain,
            target: self,
            action: #selector(handleChartButton)
        )
        chartIconItem.tintColor = .white // or .orange, your preference
        navigationItem.rightBarButtonItem = chartIconItem
    }

    @objc private func handleChartButton() {
        // Show or navigate to your chart
        print("Chart icon tapped!")
    }

    // MARK: - Setup summary card
    private func setupSummaryCardHosting() {
        // Suppose we read final BTC price & portfolio from coordinator
        let finalBTC = representable?.coordinator.monteCarloResults.last?.btcPriceUSD ?? 9999
        let finalPortfolio = representable?.coordinator.monteCarloResults.last?.portfolioValueUSD ?? 12345
        let startPortfolio = representable?.coordinator.monteCarloResults.first?.portfolioValueUSD ?? 10000
        let growth = (finalPortfolio - startPortfolio) / max(startPortfolio, 1) * 100

        // Currency symbol
        let symbol = (representable?.simSettings.currencyPreference == .eur) ? "€" : "$"

        // Create the SwiftUI summary card
        let summaryCard = SimulationSummaryCardView(
            finalBTCPrice: Double(truncating: finalBTC as NSNumber),
            finalPortfolioValue: Double(truncating: finalPortfolio as NSNumber),
            growthPercent: Double(truncating: growth as NSNumber),
            currencySymbol: symbol
        )

        // Embed in a hosting controller
        let hostingController = UIHostingController(rootView: summaryCard)
        addChild(hostingController)
        summaryHostingContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Layout
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: summaryHostingContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: summaryHostingContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: summaryHostingContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: summaryHostingContainer.bottomAnchor),
            summaryHostingContainer.heightAnchor.constraint(equalToConstant: 90)
        ])
    }
}
