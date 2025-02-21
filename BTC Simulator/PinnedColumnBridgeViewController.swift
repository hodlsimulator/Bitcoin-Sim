//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import UIKit
import SwiftUI

class PinnedColumnBridgeViewController: UIViewController {

    // This container references your SwiftUI/Coordinator logic
    var representableContainer: PinnedColumnBridgeRepresentable.BridgeContainer?

    private let hostingController = UIHostingController(rootView: AnyView(EmptyView()))
    private let summaryCardContainer = UIView()
    private let pinnedTablePlaceholder = UIView()
    private let pinnedColumnTablesVC = PinnedColumnTablesViewController()

    // A custom back button for the top bar
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // A chart button for the top bar
    private let chartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chart.line.uptrend.xyaxis"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // A centred label for the top bar
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Simulation Results"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Larger scroll-to-bottom button with reduced opacity.
    private let scrollToBottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "chevron.down.circle.fill"), for: .normal)
        btn.setPreferredSymbolConfiguration(
            UIImage.SymbolConfiguration(pointSize: 40, weight: .regular),
            forImageIn: .normal
        )
        btn.alpha = 0.3
        btn.tintColor = .white
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = false
        return btn
    }()
    
    // Track previous "at bottom" state to avoid re-triggering fade repeatedly
    private var wasAtBottom = false

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 11.0, *) {
                self.additionalSafeAreaInsets = .zero
            } else {
                automaticallyAdjustsScrollViewInsets = false
            }
        
        // A custom top bar
        let topBar = UIView()
        topBar.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        topBar.translatesAutoresizingMaskIntoConstraints = false

        let topBarHeight: CGFloat = 100

        // Container stack: [topBar, summaryCardContainer + pinnedTablePlaceholder]
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 0
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerStack)

        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.topAnchor),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // 1) The top bar
        containerStack.addArrangedSubview(topBar)
        topBar.heightAnchor.constraint(equalToConstant: topBarHeight).isActive = true

        // Add buttons + title to top bar
        topBar.addSubview(backButton)
        topBar.addSubview(chartButton)
        topBar.addSubview(titleLabel)

        // Hook up button taps
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)

        // Position them towards the bottom of topBar
        let bottomOffset: CGFloat = -2

        NSLayoutConstraint.activate([
            // Back button on the left
            backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: bottomOffset),
            
            // Chart button on the right
            chartButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            chartButton.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: bottomOffset),
            
            // Title in the centre
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: bottomOffset)
        ])

        // 2) Main stack: [ summaryCardContainer, pinnedTablePlaceholder ]
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        let mainStack = UIStackView(arrangedSubviews: [
            summaryCardContainer,
            pinnedTablePlaceholder
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 0
        containerStack.addArrangedSubview(mainStack)
        
        mainStack.setCustomSpacing(0, after: summaryCardContainer)

        // Attach hosting controller for summary card
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

        // 3) Pin the pinned table VC inside pinnedTablePlaceholder
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

        // 4) Add the scroll-to-bottom button
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.addTarget(self, action: #selector(handleScrollToBottom), for: .touchUpInside)

        NSLayoutConstraint.activate([
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollToBottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        // 5) Hide/fade the button automatically if user is at bottom
        pinnedColumnTablesVC.onIsAtBottomChanged = { [weak self] isAtBottom in
            guard let self = self else { return }
            
            // Only animate if there's a change
            guard isAtBottom != self.wasAtBottom else { return }
            self.wasAtBottom = isAtBottom
            
            DispatchQueue.main.async {
                if isAtBottom {
                    if !self.scrollToBottomButton.isHidden {
                        UIView.animate(withDuration: 0.3, animations: {
                            self.scrollToBottomButton.alpha = 0.0
                        }, completion: { finished in
                            if finished {
                                self.scrollToBottomButton.isHidden = true
                            }
                        })
                    }
                } else {
                    // Fade in
                    if self.scrollToBottomButton.isHidden {
                        self.scrollToBottomButton.isHidden = false
                        self.scrollToBottomButton.alpha = 0.0
                    }
                    UIView.animate(withDuration: 0.3) {
                        self.scrollToBottomButton.alpha = 0.3
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Hide the system nav bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        refreshSummaryCard()
        populatePinnedTable()
    }

    @objc private func handleBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleChartButton() {
        print("Chart icon tapped!")
    }

    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }
        
        let coord = container.coordinator
        
        // Make sure we have at least one row
        guard let firstRow = coord.monteCarloResults.first,
              let lastRow  = coord.monteCarloResults.last else {
            return
        }
        
        // Figure out final BTC price
        let finalBTC = lastRow.btcPriceUSD
        
        // Decide on final portfolio in USD vs. EUR
        let finalPortfolio: Decimal = (coord.simSettings.currencyPreference == .eur)
            ? lastRow.portfolioValueEUR
            : lastRow.portfolioValueUSD
        
        // Also figure out the initial portfolio value
        let initialPortfolio: Decimal = (coord.simSettings.currencyPreference == .eur)
            ? firstRow.portfolioValueEUR
            : firstRow.portfolioValueUSD
        
        // Avoid dividing by zero
        let growthPercentDouble: Double
        if initialPortfolio == 0 {
            growthPercentDouble = 0
        } else {
            let finalD = Double(truncating: finalPortfolio as NSNumber)
            let initD  = Double(truncating: initialPortfolio as NSNumber)
            growthPercentDouble = (finalD / initD - 1) * 100
        }
        
        // Just assume "$" or "€", or read from simSettings if you prefer
        let currencySymbol: String = (coord.simSettings.currencyPreference == .eur) ? "€" : "$"
        
        hostingController.rootView = AnyView(
            SimulationSummaryCardView(
                finalBTCPrice: Double(truncating: finalBTC as NSNumber),
                finalPortfolioValue: Double(truncating: finalPortfolio as NSNumber),
                growthPercent: growthPercentDouble,
                currencySymbol: currencySymbol
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor(white: 0.12, alpha: 1.0)))
        )
    }

    private func populatePinnedTable() {
        guard let container = representableContainer else { return }

        // Instead of limiting to Decimal, pass any numeric partial key paths
        pinnedColumnTablesVC.representable = PinnedColumnTablesRepresentable(
            displayedData: container.coordinator.monteCarloResults,
            pinnedColumnTitle: "Week",
            pinnedColumnKeyPath: \.week,
            columns: [
                // You can have Decimal, Double, or Int partial key paths.
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (USD)", \SimulationData.btcPriceUSD),
                ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
                ("Contrib (USD)", \SimulationData.contributionUSD),
                // etc...
            ],
            lastViewedRow: .constant(0),
            scrollToBottomFlag: .constant(false),
            isAtBottom: .constant(false)
        )
    }

    @objc private func handleScrollToBottom() {
        pinnedColumnTablesVC.scrollToBottom()
    }
    
    // In PinnedColumnBridgeViewController.swift
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("pinnedTablePlaceholder constraints:")
        for c in pinnedTablePlaceholder.constraints {
            print("  -", c)
        }

        // If pinnedTablePlaceholder is inside a UIStackView or container
        if let placeholderSuperview = pinnedTablePlaceholder.superview {
            print("placeholderSuperview:", placeholderSuperview)
            print("placeholderSuperview constraints:")
            for c in placeholderSuperview.constraints {
                print("  -", c)
            }
        }
        
        // Also dump pinnedColumnTablesVC.view constraints
        let pinnedChildView = pinnedColumnTablesVC.view!
        print("pinnedColumnTablesVC.view constraints:")
        for c in pinnedChildView.constraints {
            print("  -", c)
        }
        if let childSuperview = pinnedChildView.superview {
            print("pinnedColumnTablesVC.view superview:", childSuperview)
            print("pinnedColumnTablesVC.view superview constraints:")
            for c in childSuperview.constraints {
                print("  -", c)
            }
        }
    }
}
