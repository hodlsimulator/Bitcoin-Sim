//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import UIKit
import SwiftUI

class PinnedColumnBridgeViewController: UIViewController {

    var representableContainer: PinnedColumnBridgeRepresentable.BridgeContainer?

    private let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
    private let summaryCardContainer = UIView()
    private let pinnedTablePlaceholder = UIView()
    private let pinnedColumnTablesVC = PinnedColumnTablesViewController()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove extra safe-area fiddling, so we can fill the entire screen:
        // edgesForExtendedLayout = [] // Not needed anymore
        
        // 1) We do NOT rely on the system nav bar. We'll hide it in viewWillAppear.
        //    Let's build a custom top bar:
        let topBar = UIView()
        topBar.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        
        // For demonstration, a "Chart" button on the right:
        let chartButton = UIButton(type: .system)
        chartButton.setImage(UIImage(systemName: "chart.line.uptrend.xyaxis"), for: .normal)
        chartButton.tintColor = .white
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)
        chartButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(chartButton)
        
        NSLayoutConstraint.activate([
            chartButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            chartButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])

        // Optionally, a "Back" button on the left:
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])

        // We'll set the topBar's height to ~50:
        let topBarHeight: CGFloat = 50

        // 2) A vertical stack containing:
        //   [ topBar, summaryCardContainer + pinnedTablePlaceholder ]
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 0
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStack)

        // Fill the entire screen without negative safe-area offsets:
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.topAnchor),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 3) Add the topBar as the first arranged subview
        containerStack.addArrangedSubview(topBar)
        NSLayoutConstraint.activate([
            topBar.heightAnchor.constraint(equalToConstant: topBarHeight)
        ])

        // 4) Now your "main" stack for summary card + pinned table:
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        let mainStack = UIStackView(arrangedSubviews: [
            summaryCardContainer,
            pinnedTablePlaceholder
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 0

        // Add it as the second arranged subview:
        containerStack.addArrangedSubview(mainStack)

        // Attach hosting controller for your summary card
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

        // Pin the pinned table VC into pinnedTablePlaceholder
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
        
        // Hide the *system* nav bar so it doesn't show behind our custom bar.
        navigationController?.setNavigationBarHidden(true, animated: false)

        refreshSummaryCard()
        populatePinnedTable()
    }
    
    @objc private func handleBackButton() {
        // Pop or dismiss. e.g. pop if in a nav stack:
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleChartButton() {
        print("Chart icon tapped!")
        // Possibly push a chart screen or show a sheet
    }

    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }
        
        // For demonstration we’ll just show a placeholder:
        hostingController.rootView = AnyView(
            SimulationSummaryCardView(
                finalBTCPrice: 1234.56,
                finalPortfolioValue: 1234567.89,
                growthPercent: 12.34,
                currencySymbol: "$"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor(white: 0.12, alpha: 1.0)))
        )
    }

    private func populatePinnedTable() {
        guard let container = representableContainer else { return }
        pinnedColumnTablesVC.representable = PinnedColumnTablesRepresentable(
            displayedData: container.coordinator.monteCarloResults,
            pinnedColumnTitle: "Week",
            pinnedColumnKeyPath: \.week,
            columns: [
                ("BTC Price (USD)", \SimulationData.btcPriceUSD)
            ],
            lastViewedRow: .constant(0),
            scrollToBottomFlag: .constant(false)
        )
    }
}
