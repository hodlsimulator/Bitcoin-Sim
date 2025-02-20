//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 18/02/2025.
//

import UIKit
import SwiftUI

class PinnedColumnBridgeViewController: UIViewController {
    
    // 1) Reference back to your bridging container
    var representableContainer: PinnedColumnBridgeRepresentable.BridgeContainer?

    // 2) Hosting controller for the summary card
    private let hostingController = UIHostingController(rootView: AnyView(EmptyView()))

    // Container for the summary card
    private let summaryCardContainer = UIView()

    // Placeholder for pinned table
    private let pinnedTablePlaceholder = UIView()

    // NEW: Child pinned table VC
    private let pinnedColumnTablesVC = PinnedColumnTablesViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // If you want a chart button in the Nav bar:
        setupChartBarButton()

        // Use a vertical stack to hold summaryCardContainer + pinnedTablePlaceholder
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        let mainStack = UIStackView(arrangedSubviews: [
            summaryCardContainer,
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

        // Attach the hosting controller’s view (summary card)
        addChild(hostingController)
        summaryCardContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: summaryCardContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: summaryCardContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: summaryCardContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: summaryCardContainer.bottomAnchor),
            
            // Give the summary card a fixed height, adjust as desired
            summaryCardContainer.heightAnchor.constraint(equalToConstant: 90)
        ])

        // NEW: Embed the pinned table VC inside pinnedTablePlaceholder
        addChild(pinnedColumnTablesVC)
        pinnedTablePlaceholder.addSubview(pinnedColumnTablesVC.view)
        pinnedColumnTablesVC.didMove(toParent: self)

        pinnedColumnTablesVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pinnedColumnTablesVC.view.topAnchor.constraint(equalTo: pinnedTablePlaceholder.topAnchor),
            pinnedColumnTablesVC.view.leadingAnchor.constraint(equalTo: pinnedTablePlaceholder.leadingAnchor),
            pinnedColumnTablesVC.view.trailingAnchor.constraint(equalTo: pinnedTablePlaceholder.trailingAnchor),
            pinnedColumnTablesVC.view.bottomAnchor.constraint(equalTo: pinnedTablePlaceholder.bottomAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSummaryCard()
        populatePinnedTable()
    }
    
    /// Builds/updates the SwiftUI summary card at the top
    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }

        let finalBTCDecimal = container.coordinator.monteCarloResults.last?.btcPriceUSD ?? Decimal(9999)
        let finalBTC = NSDecimalNumber(decimal: finalBTCDecimal).doubleValue

        let finalPortfolioDecimal = container.coordinator.monteCarloResults.last?.portfolioValueUSD ?? Decimal(12345)
        let finalPortfolio = NSDecimalNumber(decimal: finalPortfolioDecimal).doubleValue

        let startPortfolioDecimal = container.coordinator.monteCarloResults.first?.portfolioValueUSD ?? Decimal(10000)
        let startPortfolio = NSDecimalNumber(decimal: startPortfolioDecimal).doubleValue

        let growth = (finalPortfolio - startPortfolio) / max(startPortfolio, 1) * 100

        let symbol = (container.simSettings.currencyPreference == .eur) ? "€" : "$"

        let summaryCard = SimulationSummaryCardView(
            finalBTCPrice: finalBTC,
            finalPortfolioValue: finalPortfolio,
            growthPercent: growth,
            currencySymbol: symbol
        )

        hostingController.rootView = AnyView(
                SimulationSummaryCardView(
                    finalBTCPrice: 1234.56,
                    finalPortfolioValue: 1234567.89,
                    growthPercent: 12.34,
                    currencySymbol: "$"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor(white: 0.12, alpha: 1.0)))  // <— Make sure this matches your nav bar
            )
    }

    /// NEW: Set up the pinned table with two columns: pinned "Week/Month" + "BTC Price (USD)"
    private func populatePinnedTable() {
        guard let container = representableContainer else { return }

        // Decide pinned column title: "Week" or "Month"
        let pinnedTitle = (container.simSettings.periodUnit == .months) ? "Month" : "Week"

        // Pass your coordinator's simulation results to the table
        pinnedColumnTablesVC.representable = PinnedColumnTablesRepresentable(
            displayedData: container.coordinator.monteCarloResults,
            pinnedColumnTitle: pinnedTitle,
            // For monthly you’d have something like \.month if your data has it,
            // or if your data only has “week”, you can adapt your code. We'll assume .week for now.
            pinnedColumnKeyPath: \.week,
            columns: [
                // This shows "BTC Price (USD)"
                ("BTC Price (USD)", \SimulationData.btcPriceUSD)
            ],
            // For now, we’ll just bind these to temporary constants.
            // You can store them in your coordinator or user defaults if desired.
            lastViewedRow: .constant(0),
            scrollToBottomFlag: .constant(false)
        )
    }
    
    // Optional chart button on the nav bar
    private func setupChartBarButton() {
        let chartIconItem = UIBarButtonItem(
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            style: .plain,
            target: self,
            action: #selector(handleChartButton)
        )
        chartIconItem.tintColor = .white
        navigationItem.rightBarButtonItem = chartIconItem
    }

    @objc private func handleChartButton() {
        print("Chart icon tapped!")
        // Possibly show a chart screen
    }
}
