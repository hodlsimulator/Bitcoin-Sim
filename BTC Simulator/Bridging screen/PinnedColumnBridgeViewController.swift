//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import UIKit
import SwiftUI

// A local struct that holds the references you need
struct BridgeContainer {
    let coordinator: SimulationCoordinator
    let inputManager: PersistentInputManager
    let monthlySimSettings: MonthlySimulationSettings
    let simSettings: SimulationSettings
}

class PinnedColumnBridgeViewController: UIViewController {

    // MARK: - Properties
    
    var representableContainer: BridgeContainer?
    
    // Binding to let SwiftUI drive the dismissal
    var dismissBinding: Binding<Bool>?

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

    // Larger scroll-to-bottom button with reduced opacity
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

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PinnedColumnBridgeViewController: viewDidLoad called")

        // 1) Re-enable swipe-to-go-back if on a real nav stack
        if let nav = navigationController {
            nav.interactivePopGestureRecognizer?.delegate = self
            nav.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        if #available(iOS 11.0, *) {
            self.additionalSafeAreaInsets = .zero
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        // 2) A custom top bar
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

        // 3) The top bar
        containerStack.addArrangedSubview(topBar)
        topBar.heightAnchor.constraint(equalToConstant: topBarHeight).isActive = true

        // 4) Create a container to enlarge the tap area
        let backContainer = UIView()
        backContainer.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(backContainer)
        backContainer.addSubview(backButton)

        // Also add the chart button + title label
        topBar.addSubview(chartButton)
        topBar.addSubview(titleLabel)

        // Hook up button taps
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)

        // Position them near the bottom of the top bar
        let bottomOffset: CGFloat = -2

        NSLayoutConstraint.activate([
            backContainer.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            backContainer.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: bottomOffset),
            backContainer.widthAnchor.constraint(equalToConstant: 44),
            backContainer.heightAnchor.constraint(equalToConstant: 44),

            backButton.leadingAnchor.constraint(equalTo: backContainer.leadingAnchor),
            backButton.bottomAnchor.constraint(equalTo: backContainer.bottomAnchor),
            
            chartButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            chartButton.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: bottomOffset),
            
            titleLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: bottomOffset)
        ])

        // 5) The main stack: [ summaryCardContainer, pinnedTablePlaceholder ]
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        let mainStack = UIStackView(arrangedSubviews: [
            summaryCardContainer,
            pinnedTablePlaceholder
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 0
        containerStack.addArrangedSubview(mainStack)
        
        mainStack.setCustomSpacing(0, after: summaryCardContainer)

        // Attach hosting controller for the summary card
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

        // 6) Pin the pinned table VC inside pinnedTablePlaceholder
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

        // 7) Add the scroll-to-bottom button
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.addTarget(self, action: #selector(handleScrollToBottom), for: .touchUpInside)

        NSLayoutConstraint.activate([
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollToBottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        // 8) Fade/hide the button if pinnedColumnTablesVC says user is at bottom
        pinnedColumnTablesVC.onIsAtBottomChanged = { [weak self] isAtBottom in
            guard let self = self else { return }
            guard isAtBottom != self.wasAtBottom else { return }
            self.wasAtBottom = isAtBottom
            
            DispatchQueue.main.async {
                if isAtBottom {
                    if !self.scrollToBottomButton.isHidden {
                        UIView.animate(withDuration: 0.3) {
                            self.scrollToBottomButton.alpha = 0.0
                        } completion: { finished in
                            if finished {
                                self.scrollToBottomButton.isHidden = true
                            }
                        }
                    }
                } else {
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

    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("PinnedColumnBridgeViewController: viewWillAppear called")

        // Hide the system nav bar
        navigationController?.setNavigationBarHidden(true, animated: false)

        refreshSummaryCard()
        populatePinnedTable()
    }

    // MARK: - Button Handlers
    @objc private func handleBackButton() {
        print("PinnedColumnBridgeViewController: Back button tapped")
        // Let SwiftUI handle the back nav:
        dismissBinding?.wrappedValue = false
    }

    @objc private func handleChartButton() {
        print("PinnedColumnBridgeViewController: Chart icon tapped!")
    }

    @objc private func handleScrollToBottom() {
        print("PinnedColumnBridgeViewController: Scroll-to-bottom button tapped")
        pinnedColumnTablesVC.scrollToBottom()
    }
    
    // MARK: - Refresh / Populate
    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }
        
        let coord = container.coordinator
        
        // Ensure we have at least one row
        guard let firstRow = coord.monteCarloResults.first,
              let lastRow  = coord.monteCarloResults.last else {
            return
        }
        
        // Figure out final BTC price
        let finalBTC = lastRow.btcPriceUSD
        
        // Decide on final portfolio in USD vs. EUR or both
        // PreferredCurrency is an enum with .usd, .eur, .both
        switch coord.simSettings.currencyPreference {
        case .usd:
            let finalPortfolio = lastRow.portfolioValueUSD
            let initialPortfolio = firstRow.portfolioValueUSD
            let (growthPercentDouble, currencySymbol) = growthCalc(finalPortfolio, initialPortfolio, "$")
            
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
            
        case .eur:
            let finalPortfolio = lastRow.portfolioValueEUR
            let initialPortfolio = firstRow.portfolioValueEUR
            let (growthPercentDouble, currencySymbol) = growthCalc(finalPortfolio, initialPortfolio, "€")
            
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
            
        case .both:
            // If "both," pick one or do logic for combined display. For now, just show USD:
            let finalPortfolio = lastRow.portfolioValueUSD
            let initialPortfolio = firstRow.portfolioValueUSD
            let (growthPercentDouble, currencySymbol) = growthCalc(finalPortfolio, initialPortfolio, "$")
            
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
    }

    private func populatePinnedTable() {
        guard let container = representableContainer else { return }
        
        let data = container.coordinator.monteCarloResults
        let pref = container.simSettings.currencyPreference
        
        // Build columns for each currency preference
        let columns: [(String, PartialKeyPath<SimulationData>)]
        switch pref {
        case .usd:
            columns = [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (USD)", \SimulationData.btcPriceUSD),
                ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
                ("Contrib (USD)", \SimulationData.contributionUSD),
                ("Fee (USD)", \SimulationData.transactionFeeUSD),
                ("Net Contrib (BTC)", \SimulationData.netContributionBTC),
                ("Withdraw (USD)", \SimulationData.withdrawalUSD)
            ]
            
        case .eur:
            columns = [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (EUR)", \SimulationData.btcPriceEUR),
                ("Portfolio (EUR)", \SimulationData.portfolioValueEUR),
                ("Contrib (EUR)", \SimulationData.contributionEUR),
                ("Fee (EUR)", \SimulationData.transactionFeeEUR),
                ("Net Contrib (BTC)", \SimulationData.netContributionBTC),
                ("Withdraw (EUR)", \SimulationData.withdrawalEUR)
            ]
            
        case .both:
            columns = [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (USD)", \SimulationData.btcPriceUSD),
                ("BTC Price (EUR)", \SimulationData.btcPriceEUR),
                ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
                ("Portfolio (EUR)", \SimulationData.portfolioValueEUR),
                ("Contrib (USD)", \SimulationData.contributionUSD),
                ("Contrib (EUR)", \SimulationData.contributionEUR),
                ("Fee (USD)", \SimulationData.transactionFeeUSD),
                ("Fee (EUR)", \SimulationData.transactionFeeEUR),
                ("Net Contrib (BTC)", \SimulationData.netContributionBTC),
                ("Withdraw (USD)", \SimulationData.withdrawalUSD),
                ("Withdraw (EUR)", \SimulationData.withdrawalEUR)
            ]
        }

        pinnedColumnTablesVC.representable = PinnedColumnTablesRepresentable(
            displayedData: data,
            pinnedColumnTitle: "Week",
            pinnedColumnKeyPath: \.week,
            columns: columns,
            lastViewedRow: .constant(0),
            scrollToBottomFlag: .constant(false),
            isAtBottom: .constant(false)
        )
    }
    
    // Helper to compute growth % and return (Double, symbol)
    private func growthCalc(_ finalPortfolio: Decimal, _ initialPortfolio: Decimal, _ symbol: String) -> (Double, String) {
        let growthPercentDouble: Double
        if initialPortfolio == 0 {
            growthPercentDouble = 0.0
        } else {
            let finalD = Double(truncating: finalPortfolio as NSNumber)
            let initD  = Double(truncating: initialPortfolio as NSNumber)
            growthPercentDouble = (finalD / initD - 1) * 100
        }
        return (growthPercentDouble, symbol)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PinnedColumnBridgeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        print("PinnedColumnBridgeViewController: Swipe-to-go-back gesture detected")
        let count = navigationController?.viewControllers.count ?? 0
        print("PinnedColumnBridgeViewController: nav stack count = \(count)")
        // Only allow swipe if there's more than one VC on the stack
        return count > 1
    }
}
