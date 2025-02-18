//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 18/02/2025.
//

import UIKit
import SwiftUI

class PinnedColumnBridgeViewController: UIViewController {
    
    // 1) Reference back to your bridging container to access the coordinator
    var representableContainer: PinnedColumnBridgeRepresentable.BridgeContainer?

    // 2) Hosting controller property
    //    We’ll assign it a placeholder view in viewDidLoad, then update in viewWillAppear.
    private let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
    
    // Container for the summary card (subview).
    private let summaryCardContainer = UIView()
    
    // Placeholder for pinned table
    private let pinnedTablePlaceholder = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // If you want a chart button in the Nav bar:
        setupChartBarButton()

        // 3) Layout the summaryCardContainer & pinnedTablePlaceholder in a vertical stack
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

        // 4) Add the hostingController’s view to our summaryCardContainer
        addChild(hostingController)
        summaryCardContainer.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: summaryCardContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: summaryCardContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: summaryCardContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: summaryCardContainer.bottomAnchor),
            
            summaryCardContainer.heightAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    // MARK: - Refresh in viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshSummaryCard()
    }
    
    /// 5) Called every time the view appears. We rebuild the SwiftUI summary card
    ///    with the correct final BTC, final portfolio, etc.
    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }

        // Convert from Decimal to Double
        let finalBTCDecimal = container.coordinator.monteCarloResults.last?.btcPriceUSD ?? Decimal(9999)
        let finalBTC = NSDecimalNumber(decimal: finalBTCDecimal).doubleValue

        let finalPortfolioDecimal = container.coordinator.monteCarloResults.last?.portfolioValueUSD ?? Decimal(12345)
        let finalPortfolio = NSDecimalNumber(decimal: finalPortfolioDecimal).doubleValue

        let startPortfolioDecimal = container.coordinator.monteCarloResults.first?.portfolioValueUSD ?? Decimal(10000)
        let startPortfolio = NSDecimalNumber(decimal: startPortfolioDecimal).doubleValue

        let growth = (finalPortfolio - startPortfolio) / max(startPortfolio, 1) * 100

        let symbol = (container.simSettings.currencyPreference == .eur) ? "€" : "$"

        // Now pass these new variables to your SwiftUI view:
        let summaryCard = SimulationSummaryCardView(
            finalBTCPrice: finalBTC,
            finalPortfolioValue: finalPortfolio,
            growthPercent: growth,
            currencySymbol: symbol
        )

        hostingController.rootView = AnyView(summaryCard)
    }

    // MARK: - (Optional) Chart button on nav bar
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
