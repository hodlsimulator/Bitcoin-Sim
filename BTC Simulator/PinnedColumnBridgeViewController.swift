//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 18/02/2025.
//

import UIKit
import SwiftUI

/// A UIViewController that shows:
///  - A top summary card (using your old SimulationSummaryCardView in a UIHostingController),
///  - A back arrow + chart button on the top-right,
///  - Then (later) the pinned-column table, and
///  - Possibly a floating scroll-to-bottom button.
class PinnedColumnBridgeViewController: UIViewController {
    
    // This is set by PinnedColumnBridgeRepresentable (our SwiftUI wrapper).
    // It gives us access to environment objects via representable.* if needed.
    var representable: PinnedColumnBridgeRepresentable?
    
    // MARK: - Subviews
    private let topBarStack = UIStackView() // Holds back arrow, chart button
    private let backButton = UIButton(type: .system)
    private let chartButton = UIButton(type: .system)
    
    // Container for summary card
    private let summaryHostingContainer = UIView()

    // Example pinned container for the pinned table (we’ll fill it in the next step).
    // For now, it’s just a grey placeholder to see the layout.
    private let pinnedTablePlaceholder = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // 1) Setup top bar (with back arrow + chart button)
        setupTopBar()
        
        // 2) Setup the summary card (SwiftUI hosting)
        setupSummaryCardHosting()
        
        // 3) Placeholder for pinned table
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        
        // 4) Lay out everything in a vertical stack
        let mainStack = UIStackView(arrangedSubviews: [
            topBarStack,
            summaryHostingContainer,
            pinnedTablePlaceholder
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainStack)
        
        // Constrain the main stack to fill the view
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Setup top bar
    private func setupTopBar() {
        topBarStack.axis = .horizontal
        topBarStack.distribution = .equalSpacing
        topBarStack.alignment = .center
        topBarStack.layoutMargins = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        topBarStack.isLayoutMarginsRelativeArrangement = true
        
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(.orange, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        
        chartButton.setTitle("Chart", for: .normal)
        chartButton.setTitleColor(.orange, for: .normal)
        chartButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)
        
        // Put them in the horizontal stack
        topBarStack.addArrangedSubview(backButton)
        topBarStack.addArrangedSubview(chartButton)
    }
    
    // MARK: - Setup summary card
    private func setupSummaryCardHosting() {
        // Suppose we read final BTC price & portfolio from coordinator
        // (If none exist, just show some placeholder).
        let finalBTC = representable?.coordinator.monteCarloResults.last?.btcPriceUSD ?? 9999
        let finalPortfolio = representable?.coordinator.monteCarloResults.last?.portfolioValueUSD ?? 12345
        let startPortfolio = representable?.coordinator.monteCarloResults.first?.portfolioValueUSD ?? 10000
        let growth = (finalPortfolio - startPortfolio) / (startPortfolio == 0 ? 1 : startPortfolio) * 100
        
        // Pick the currency symbol from simSettings
        let symbol = (representable?.simSettings.currencyPreference == .eur) ? "€" : "$"
        
        // Create the SwiftUI view:
        let summaryCard = SimulationSummaryCardView(
            finalBTCPrice: Double(truncating: finalBTC as NSNumber),
            finalPortfolioValue: Double(truncating: finalPortfolio as NSNumber),
            growthPercent: Double(truncating: growth as NSNumber),
            currencySymbol: symbol
        )
        
        // Embed in hosting controller
        let hostingController = UIHostingController(rootView: summaryCard)
        
        // Add as child to self
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
            summaryHostingContainer.heightAnchor.constraint(equalToConstant: 90) // a bit taller than the 80 in your SwiftUI code
        ])
    }
    
    // MARK: - Actions
    @objc private func handleBackButton() {
        // If using SwiftUI Navigation, we can pop the stack:
        // We'll call representable’s SwiftUI environment to dismiss,
        // or you can pop yourself if you have a navigationController.
        // For now, we can simply do:
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleChartButton() {
        // Show or navigate to chart screen
        print("Chart button tapped!")
        // Possibly use representable?.coordinator to show histograms, etc.
    }
}
