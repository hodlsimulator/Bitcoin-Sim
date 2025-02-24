//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import UIKit
import SwiftUI

// MARK: - BridgeContainer
struct BridgeContainer {
    let coordinator: SimulationCoordinator
    let inputManager: PersistentInputManager
    let monthlySimSettings: MonthlySimulationSettings
    let simSettings: SimulationSettings
    let simChartSelection: SimChartSelection
    let chartDataCache: ChartDataCache
}

// MARK: - PinnedColumnBridgeViewController
class PinnedColumnBridgeViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Properties
    var representableContainer: BridgeContainer?
    var dismissBinding: Binding<Bool>?
    var previousColumnIndex: Int? = nil

    private let customTopBar = UIView()
    private let titleLabel   = UILabel()
    private let backButton   = UIButton(type: .system)
    private let chartButton  = UIButton(type: .system)

    private let customNavBarHeight: CGFloat = 30
    private let summaryCardHeight:  CGFloat = 88

    // We use our own hosting controller for the summary card
    private let hostingController      = UIHostingController(rootView: AnyView(EmptyView()))
    private let summaryCardContainer   = UIView()
    private let pinnedTablePlaceholder = UIView()
    private let pinnedColumnTablesVC   = PinnedColumnTablesViewController()

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

    private var wasAtBottom = false

    /// Store the system's original pop gesture delegate
    private weak var originalGestureDelegate: UIGestureRecognizerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove any 'Back' text for the NEXT screen:
        let emptyItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = emptyItem
        
        // Hide the system nav bar on THIS screen, so we only see our custom top bar
        navigationController?.isNavigationBarHidden = true
        
        // Also remove the "Back" text on next pushes
        navigationItem.backButtonDisplayMode = .minimal

        // Extend layout behind status bar and bottom safe area
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true
        
        setupCustomTopBar()

        // 1) SummaryCard container
        summaryCardContainer.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        summaryCardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryCardContainer)
        NSLayoutConstraint.activate([
            summaryCardContainer.topAnchor.constraint(equalTo: customTopBar.bottomAnchor),
            summaryCardContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            summaryCardContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            summaryCardContainer.heightAnchor.constraint(equalToConstant: summaryCardHeight)
        ])

        addChild(hostingController)
        summaryCardContainer.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: summaryCardContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: summaryCardContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: summaryCardContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: summaryCardContainer.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)

        // 2) Pinned table area
        pinnedTablePlaceholder.backgroundColor = UIColor.darkGray.withAlphaComponent(0.2)
        pinnedTablePlaceholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTablePlaceholder)
        NSLayoutConstraint.activate([
            pinnedTablePlaceholder.topAnchor.constraint(equalTo: summaryCardContainer.bottomAnchor),
            pinnedTablePlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTablePlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pinnedTablePlaceholder.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        addChild(pinnedColumnTablesVC)
        pinnedTablePlaceholder.addSubview(pinnedColumnTablesVC.view)
        pinnedColumnTablesVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pinnedColumnTablesVC.view.topAnchor.constraint(equalTo: pinnedTablePlaceholder.topAnchor),
            pinnedColumnTablesVC.view.leadingAnchor.constraint(equalTo: pinnedTablePlaceholder.leadingAnchor),
            pinnedColumnTablesVC.view.trailingAnchor.constraint(equalTo: pinnedTablePlaceholder.trailingAnchor),
            pinnedColumnTablesVC.view.bottomAnchor.constraint(equalTo: pinnedTablePlaceholder.bottomAnchor)
        ])
        pinnedColumnTablesVC.didMove(toParent: self)

        if let tableView = pinnedColumnTablesVC.view.subviews.first as? UITableView {
            tableView.contentInsetAdjustmentBehavior = .never
            tableView.contentInset.bottom = 0
            tableView.verticalScrollIndicatorInsets.bottom = 0
        }

        // 3) Scroll-to-bottom button
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.addTarget(self, action: #selector(handleScrollToBottom), for: .touchUpInside)
        NSLayoutConstraint.activate([
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollToBottomButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

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
                            if finished { self.scrollToBottomButton.isHidden = true }
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
        
        // --- New: Slide-based column header changes ---
        // Listen for centered column changes from the child’s collection view.
        pinnedColumnTablesVC.columnsCollectionVC.onCenteredColumnChanged = { [weak pinnedColumnTablesVC] newIndex in
            guard let vc = pinnedColumnTablesVC else { return }
            let direction: CGFloat
            if let oldIndex = vc.previousColumnIndex {
                direction = (newIndex > oldIndex) ? -1 : 1
            } else {
                direction = -1
            }
            vc.previousColumnIndex = newIndex

            let allCols = vc.columnsCollectionVC.columnsData
            let newText1 = (newIndex < allCols.count) ? allCols[newIndex].0 : nil
            let newText2 = (newIndex + 1 < allCols.count) ? allCols[newIndex + 1].0 : nil

            // vc.slideHeaders(newText1: newText1, newText2: newText2, direction: direction)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Force the pinned table VC to layout now.
        pinnedColumnTablesVC.view.setNeedsLayout()
        pinnedColumnTablesVC.view.layoutIfNeeded()
    }

    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Hide system nav bar on this screen
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Enable edge-swipe
        if let nav = navigationController, let popGesture = nav.interactivePopGestureRecognizer {
            if originalGestureDelegate == nil {
                originalGestureDelegate = popGesture.delegate
            }
            popGesture.delegate = self
            popGesture.isEnabled = true
        }

        refreshSummaryCard()
        populatePinnedTable()
    }

    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // If we are popped off the nav stack, restore default swipe behaviour
        if let nav = navigationController, !nav.viewControllers.contains(self) {
            if let popGesture = nav.interactivePopGestureRecognizer {
                popGesture.delegate = originalGestureDelegate
                popGesture.isEnabled = true
            }
        }
    }

    // MARK: - Setup Custom Bar
    private func setupCustomTopBar() {
        customTopBar.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        customTopBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTopBar)

        NSLayoutConstraint.activate([
            customTopBar.topAnchor.constraint(equalTo: view.topAnchor),
            customTopBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTopBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTopBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                 constant: customNavBarHeight)
        ])

        // Back button (our custom one)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: customTopBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: customTopBar.centerYAnchor, constant: 30)
        ])
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        // Title label
        titleLabel.text = "Simulation Results"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: customTopBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
        ])

        // Chart button
        chartButton.setImage(UIImage(systemName: "chart.line.uptrend.xyaxis"), for: .normal)
        chartButton.tintColor = .white
        chartButton.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(chartButton)
        NSLayoutConstraint.activate([
            chartButton.trailingAnchor.constraint(equalTo: customTopBar.trailingAnchor, constant: -16),
            chartButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor)
        ])
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)
    }

    // MARK: - Gesture Delegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow edge-swipe if there's more than 1 VC on the stack
        return (navigationController?.viewControllers.count ?? 0) > 1
    }

    // MARK: - Button Handlers
    @objc private func handleBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleChartButton() {
        guard let container = representableContainer,
              let nav = navigationController else { return }

        // Restore default edge-swipe for next screen
        if let popGesture = nav.interactivePopGestureRecognizer {
            popGesture.delegate = originalGestureDelegate
            popGesture.isEnabled = true
        }

        // Clear bridging VC's back text so the next screen’s arrow has no label
        if let items = nav.navigationBar.items, items.count >= 1 {
            let bridgingItem = items[items.count - 1]
            bridgingItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }

        // Build the chart view
        let chartView = MonteCarloResultsView()
            .environmentObject(container.coordinator)
            .environmentObject(container.simSettings)
            .environmentObject(container.simChartSelection)
            .environmentObject(container.chartDataCache)

        // Wrap in ChartHostingController
        let chartHostingController = ChartHostingController(rootView: chartView)

        // Push it
        nav.pushViewController(chartHostingController, animated: true)
    }

    @objc private func handleScrollToBottom() {
        pinnedColumnTablesVC.scrollToBottom()
    }

    // MARK: - Populate / Refresh
    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }
        let coord = container.coordinator

        // Make sure we have any results
        guard !coord.monteCarloResults.isEmpty else { return }
        guard let lastRow = coord.monteCarloResults.last else { return }

        // We'll show final BTC in USD for the card's price display
        let finalBTC = lastRow.btcPriceUSD

        switch coord.simSettings.currencyPreference {

        // -------------------------------------------------------------
        // 1) USD branch
        // -------------------------------------------------------------
        case .usd:
            let finalPortfolio = lastRow.portfolioValueUSD
            
            // Sum all weekly contributions (USD) as Decimal
            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionUSD)
            }
            
            // Convert the Double startingBalance to Decimal
            totalContributed += Decimal(coord.simSettings.startingBalance)
            
            let (growthPercentDouble, currencySymbol) =
                growthCalcWithContributions(finalPortfolio, totalContributed, symbol: "$")
            
            // Pass the computed growth into SwiftUI
            hostingController.rootView = AnyView(
                SimulationSummaryCardView(
                    finalBTCPrice: Double(truncating: finalBTC as NSNumber),
                    finalPortfolioValue: Double(truncating: finalPortfolio as NSNumber),
                    growthPercent: growthPercentDouble,
                    currencySymbol: currencySymbol
                )
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor(white: 0.12, alpha: 1.0)))
            )

        // -------------------------------------------------------------
        // 2) EUR branch
        // -------------------------------------------------------------
        case .eur:
            let finalPortfolio = lastRow.portfolioValueEUR
            
            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionEUR)
            }
            
            // If startingBalance is in USD, you might convert it,
            // but here's a direct Decimal() for simplicity:
            totalContributed += Decimal(coord.simSettings.startingBalance)
            
            let (growthPercentDouble, currencySymbol) =
                growthCalcWithContributions(finalPortfolio, totalContributed, symbol: "€")

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

        // -------------------------------------------------------------
        // 3) Both branch
        // -------------------------------------------------------------
        case .both:
            // We'll just display USD for the final portfolio
            let finalPortfolio = lastRow.portfolioValueUSD

            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionUSD)
            }
            
            totalContributed += Decimal(coord.simSettings.startingBalance)
            
            let (growthPercentDouble, currencySymbol) =
                growthCalcWithContributions(finalPortfolio, totalContributed, symbol: "$")

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

    // MARK: - Growth Calculation Helper
    private func growthCalcWithContributions(
        _ finalValue: Decimal,
        _ totalContributed: Decimal,
        symbol: String
    ) -> (Double, String) {
        guard totalContributed > 0 else {
            // Avoid divide by zero if user contributed nothing
            return (0.0, symbol)
        }
        // ratio = final / total
        let ratio = NSDecimalNumber(decimal: finalValue / totalContributed).doubleValue
        let growthDouble = (ratio - 1.0) * 100.0
        return (growthDouble, symbol)
    }

    private func populatePinnedTable() {
        guard let container = representableContainer else { return }
        let data = container.coordinator.monteCarloResults
        let pref = container.simSettings.currencyPreference

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
        
        // Force layout on next tick:
        DispatchQueue.main.async {
            self.pinnedColumnTablesVC.view.setNeedsLayout()
            self.pinnedColumnTablesVC.view.layoutIfNeeded()
        }
    }

    // MARK: - Growth Calculation (Legacy)
    private func growthCalc(_ finalPortfolio: Decimal,
                            _ initialPortfolio: Decimal,
                            _ symbol: String) -> (Double, String) {
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
}
