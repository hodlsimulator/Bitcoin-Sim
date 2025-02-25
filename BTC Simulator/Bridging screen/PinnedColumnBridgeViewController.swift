//
//  PinnedColumnBridgeViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 18/02/2025.
//

import UIKit
import SwiftUI

// MARK: - BridgeContainer
/// Used to pass your coordinator, settings, etc. into the Bridge VC.
struct BridgeContainer {
    let coordinator: SimulationCoordinator
    let inputManager: PersistentInputManager
    let monthlySimSettings: MonthlySimulationSettings
    let simSettings: SimulationSettings
    let simChartSelection: SimChartSelection
    let chartDataCache: ChartDataCache
}

// MARK: - PinnedColumnBridgeViewController
///
/// 1) Shows a custom top bar (with Back & Chart buttons).
/// 2) Shows a SwiftUI summary card just under the top bar.
/// 3) Embeds the pinned-column tables below that.
/// 4) Provides a button to scroll to bottom.
class PinnedColumnBridgeViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Properties
    var representableContainer: BridgeContainer?
    var dismissBinding: Binding<Bool>?
    
    /// External bindings, e.g. to store table row/column states
    var lastViewedRowBinding: Binding<Int>?
    var lastViewedColumnIndexBinding: Binding<Int>?

    /// Tracks the previously snapped column index to animate changes
    var previousColumnIndex: Int? = nil

    /// Custom top bar UI
    private let customTopBar = UIView()
    private let titleLabel   = UILabel()
    private let backButton   = UIButton(type: .system)
    private let chartButton  = UIButton(type: .system)

    /// We’ll use these constraints for dynamic adjustments
    private var customTopBarTopConstraint: NSLayoutConstraint?
    private var summaryCardTopConstraint:  NSLayoutConstraint?

    /// Layout constants
    /// (You can tweak these heights if you want the nav bar to be bigger/smaller.)
    private let customNavBarHeight: CGFloat = 110
    private let summaryCardHeight:  CGFloat = 80

    /// SwiftUI hosting for the summary card
    private let hostingController    = UIHostingController(rootView: AnyView(EmptyView()))
    private let summaryCardContainer = UIView()

    /// View placeholder for the pinned-column tables
    private let pinnedTablePlaceholder = UIView()
    private let pinnedColumnTablesVC    = PinnedColumnTablesViewController()

    /// Button to quickly jump to bottom
    private let scrollToBottomButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(
            UIImage(systemName: "chevron.down.circle.fill"),
            for: .normal
        )
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

    /// Tracks if we’re already at bottom
    private var wasAtBottom = false
    
    /// Keep track of the original edge-swipe gesture delegate
    private weak var originalGestureDelegate: UIGestureRecognizerDelegate?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Remove default "Back" text for the next screen
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        // Hide system nav bar on this screen
        navigationController?.isNavigationBarHidden = true
        // Also remove "Back" text on subsequent pushes
        navigationItem.backButtonDisplayMode = .minimal
        
        // Extend behind status bar & bottom
        edgesForExtendedLayout = .all
        extendedLayoutIncludesOpaqueBars = true

        setupCustomTopBar()
        setupSummaryCardUI()
        setupPinnedPlaceholder()
        setupScrollToBottomButton()

        // Listen for pinnedColumnTablesVC telling us we’re at bottom
        pinnedColumnTablesVC.onIsAtBottomChanged = { [weak self] isAtBottom in
            guard let self = self, isAtBottom != self.wasAtBottom else { return }
            self.wasAtBottom = isAtBottom
            self.updateScrollToBottomButton(isAtBottom: isAtBottom)
        }

        // Listen for pinned VC’s column snapping
        pinnedColumnTablesVC.columnsCollectionVC.onCenteredColumnChanged = { [weak pinnedColumnTablesVC] newIndex in
            guard let vc = pinnedColumnTablesVC else { return }

            let direction: CGFloat
            if let oldIndex = vc.previousColumnIndex {
                direction = (newIndex > oldIndex) ? -1 : 1
            } else {
                direction = -1
            }
            vc.previousColumnIndex = newIndex

            // Optional: animate column header text changes, etc.
            let allCols = vc.columnsCollectionVC.columnsData
            let newText1 = (newIndex < allCols.count) ? allCols[newIndex].0 : nil
            let newText2 = (newIndex + 1 < allCols.count) ? allCols[newIndex + 1].0 : nil
            // vc.slideHeaders(newText1: newText1, newText2: newText2, direction: direction)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Force a layout pass on pinned columns so sizing is correct
        pinnedColumnTablesVC.view.setNeedsLayout()
        pinnedColumnTablesVC.view.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        // Enable edge-swipe back
        if let nav = navigationController,
           let popGesture = nav.interactivePopGestureRecognizer {
            if originalGestureDelegate == nil {
                originalGestureDelegate = popGesture.delegate
            }
            popGesture.delegate = self
            popGesture.isEnabled = true
        }

        // Refresh data
        refreshSummaryCard()
        populatePinnedTable()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // If popped off the nav stack, restore swipe behaviour
        if let nav = navigationController, !nav.viewControllers.contains(self) {
            if let popGesture = nav.interactivePopGestureRecognizer {
                popGesture.delegate = originalGestureDelegate
                popGesture.isEnabled = true
            }
        }
    }

    /// Detect orientation and adjust constraints.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let isPortrait = view.bounds.height > view.bounds.width

        // Bring nav bar down in landscape, keep it at the top in portrait:
        customTopBarTopConstraint?.constant = isPortrait ? 0 : 0

        // For summary card: bring it up in landscape, keep it flush in portrait:
        summaryCardTopConstraint?.constant = isPortrait ? 0 : -70

        // Apply these changes
        view.layoutIfNeeded()
    }

    // MARK: - Setup UI
    private func setupCustomTopBar() {
        customTopBar.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        customTopBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customTopBar)

        // This constraint pins the nav bar to the top of the view.
        // We keep it at 0 so the nav bar itself doesn’t move.
        customTopBarTopConstraint = customTopBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        customTopBarTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            customTopBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTopBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Height of the nav bar; we keep this as-is.
            customTopBar.heightAnchor.constraint(equalToConstant: customNavBarHeight),
        ])

        // ==================
        // Back Button Setup
        // ==================
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        // Increase hit area
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        backButton.contentHorizontalAlignment = .leading
        backButton.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(backButton)

        // NOTE: The 'constant: 12' moves the button further down within the bar.
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: customTopBar.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: customTopBar.safeAreaLayoutGuide.topAnchor, constant: 4.5)
        ])
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)

        // ==================
        // Title Label Setup
        // ==================
        titleLabel.text = "Simulation Results"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(titleLabel)

        // NOTE: The 'constant: 12' means it lines up with the back button's top offset.
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: customTopBar.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: customTopBar.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])

        // ==================
        // Chart Button Setup
        // ==================
        chartButton.setImage(UIImage(systemName: "chart.line.uptrend.xyaxis"), for: .normal)
        chartButton.tintColor = .white
        chartButton.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(chartButton)

        // NOTE: The 'constant: 12' to keep it aligned horizontally with the title & back button.
        NSLayoutConstraint.activate([
            chartButton.trailingAnchor.constraint(equalTo: customTopBar.trailingAnchor, constant: -16),
            chartButton.topAnchor.constraint(equalTo: customTopBar.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)
    }

    private func setupSummaryCardUI() {
        // 1) Create the container view for the summary card
        //    We set a dark background colour to visually match the custom top bar.
        //    If you want a different colour or transparency, adjust the alpha or the .white component.
        summaryCardContainer.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        summaryCardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryCardContainer)

        // 2) This constraint (summaryCardTopConstraint) sets how far down
        //    the summary card appears from the bottom of the customTopBar.
        //    Currently set to 0, meaning it's flush. Increase to push it down (e.g. 10).
        //    Decrease (negative) to pull it up under the top bar.
        summaryCardTopConstraint =
            summaryCardContainer.topAnchor.constraint(equalTo: customTopBar.bottomAnchor, constant: 0)
        summaryCardTopConstraint?.isActive = true

        // 3) These constraints centre the summary card horizontally
        //    and make it the same width as the entire view.
        //    The height is defined by summaryCardHeight (80f at present).
        NSLayoutConstraint.activate([
            summaryCardContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            summaryCardContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
            summaryCardContainer.heightAnchor.constraint(equalToConstant: summaryCardHeight)
        ])

        // 4) Embed the SwiftUI hosting controller inside the summary card container.
        //    hostingController.view is pinned to all edges of summaryCardContainer,
        //    so any padding or spacing you want should be done inside your SwiftUI content.
        addChild(hostingController)
        summaryCardContainer.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: summaryCardContainer.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: summaryCardContainer.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: summaryCardContainer.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: summaryCardContainer.bottomAnchor)
        ])

        // 5) Finalise the embedding process in the parent view controller.
        hostingController.didMove(toParent: self)
    }

    private func setupPinnedPlaceholder() {
        pinnedTablePlaceholder.backgroundColor = .clear
        pinnedTablePlaceholder.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTablePlaceholder)

        NSLayoutConstraint.activate([
            pinnedTablePlaceholder.topAnchor.constraint(equalTo: summaryCardContainer.bottomAnchor),
            pinnedTablePlaceholder.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTablePlaceholder.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pinnedTablePlaceholder.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Embed pinnedColumnTablesVC (defined elsewhere) inside
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
    }

    private func setupScrollToBottomButton() {
        view.addSubview(scrollToBottomButton)
        scrollToBottomButton.addTarget(self, action: #selector(handleScrollToBottom), for: .touchUpInside)

        NSLayoutConstraint.activate([
            scrollToBottomButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollToBottomButton.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -16
            )
        ])
    }

    // MARK: - Button Actions
    @objc private func handleBackButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleChartButton() {
        guard let container = representableContainer, let nav = navigationController else {
            return
        }

        // Restore default edge-swipe for next screen
        if let popGesture = nav.interactivePopGestureRecognizer {
            popGesture.delegate = originalGestureDelegate
            popGesture.isEnabled = true
        }

        // Clear bridging VC’s back text for the next screen
        if let items = nav.navigationBar.items, items.count >= 1 {
            let bridgingItem = items[items.count - 1]
            bridgingItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }

        // Build the SwiftUI chart
        let chartView = MonteCarloResultsView()
            .environmentObject(container.coordinator)
            .environmentObject(container.simSettings)
            .environmentObject(container.simChartSelection)
            .environmentObject(container.chartDataCache)

        let chartHostingController = ChartHostingController(rootView: chartView)
        nav.pushViewController(chartHostingController, animated: true)
    }

    @objc private func handleScrollToBottom() {
        pinnedColumnTablesVC.scrollToBottom()
    }

    // MARK: - Handling "isAtBottom"
    private func updateScrollToBottomButton(isAtBottom: Bool) {
        if isAtBottom {
            // Hide
            if !scrollToBottomButton.isHidden {
                UIView.animate(withDuration: 0.3) {
                    self.scrollToBottomButton.alpha = 0.0
                } completion: { finished in
                    if finished { self.scrollToBottomButton.isHidden = true }
                }
            }
        } else {
            // Show
            if scrollToBottomButton.isHidden {
                scrollToBottomButton.isHidden = false
                scrollToBottomButton.alpha = 0.0
            }
            UIView.animate(withDuration: 0.3) {
                self.scrollToBottomButton.alpha = 0.3
            }
        }
    }

    // MARK: - Populate / Refresh
    private func refreshSummaryCard() {
        guard let container = representableContainer else { return }
        let coord = container.coordinator
        
        // Make sure we have final row
        guard !coord.monteCarloResults.isEmpty,
              let lastRow = coord.monteCarloResults.last else {
            return
        }

        // We'll show final BTC in USD for the card's price display
        let finalBTC = lastRow.btcPriceUSD

        // Check user's currency preference
        switch coord.simSettings.currencyPreference {
        case .usd:
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
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor(white: 0.12, alpha: 1.0)))
            )

        case .eur:
            let finalPortfolio = lastRow.portfolioValueEUR
            
            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionEUR)
            }
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

        case .both:
            // Example uses USD for final portfolio
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

    private func populatePinnedTable() {
        guard let container = representableContainer else { return }
        let data = container.coordinator.monteCarloResults
        let pref = container.simSettings.currencyPreference

        // Decide which columns to show
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

        // Assign them to pinnedColumnTablesVC
        pinnedColumnTablesVC.representable = PinnedColumnTablesRepresentable(
            displayedData: data,
            pinnedColumnTitle: "Week", // <<-- left-aligned pinned title
            pinnedColumnKeyPath: \.week,
            columns: columns,
            lastViewedRow: lastViewedRowBinding ?? .constant(0),
            lastViewedColumnIndex: lastViewedColumnIndexBinding ?? .constant(0),
            scrollToBottomFlag: .constant(false),
            isAtBottom: .constant(false)
        )

        // Force layout
        DispatchQueue.main.async {
            self.pinnedColumnTablesVC.view.setNeedsLayout()
            self.pinnedColumnTablesVC.view.layoutIfNeeded()
        }
    }

    // Simple helper for calculating growth
    private func growthCalcWithContributions(
        _ finalValue: Decimal,
        _ totalContributed: Decimal,
        symbol: String
    ) -> (Double, String) {
        guard totalContributed > 0 else {
            return (0.0, symbol)
        }
        let ratio = NSDecimalNumber(decimal: finalValue / totalContributed).doubleValue
        let growthDouble = (ratio - 1.0) * 100.0
        return (growthDouble, symbol)
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Only allow edge-swipe if there’s more than 1 VC
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}
