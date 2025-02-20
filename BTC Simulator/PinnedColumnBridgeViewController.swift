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
            
            // Title in centre
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

        // Pin the pinned table VC
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

        // 3) Add the scroll-to-bottom button
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.addTarget(self, action: #selector(handleScrollToBottom), for: .touchUpInside)

        NSLayoutConstraint.activate([
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollToBottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        // 4) Hide/fade the button automatically if user is at bottom
        pinnedColumnTablesVC.onIsAtBottomChanged = { [weak self] isAtBottom in
            guard let self = self else { return }
            
            // Only animate if there's an actual change in bottom state
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
        
        // Hide the system nav bar so it doesn't appear behind our custom bar.
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
        // The updated summary card no longer takes onBackTapped or onChartTapped.
        guard let container = representableContainer else { return }
        
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
            scrollToBottomFlag: .constant(false),
            isAtBottom: .constant(false)
        )
    }

    @objc private func handleScrollToBottom() {
        pinnedColumnTablesVC.scrollToBottom()
    }
}
