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
    
    var idleManager: IdleManager?

    /// Custom top bar UI
    private let customTopBar = UIView()
    private let titleLabel   = UILabel()
    private let backButton   = UIButton(type: .system)
    private let chartButton  = UIButton(type: .system)

    /// We’ll use these constraints for dynamic adjustments
    private var customTopBarTopConstraint: NSLayoutConstraint?
    private var summaryCardTopConstraint:  NSLayoutConstraint?

    /// Layout constants
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

        let bottomBg = UIView()
        bottomBg.backgroundColor = .red  // or .yellow
        bottomBg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBg)
        view.sendSubviewToBack(bottomBg)

        NSLayoutConstraint.activate([
            bottomBg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBg.topAnchor.constraint(equalTo: view.topAnchor),
            bottomBg.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
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
            vc.previousColumnIndex = newIndex
            
            // <-- ADDED HERE: Store the new column index in the SwiftUI binding so row/column memory persists
            if let rep = vc.representable {
                rep.lastViewedColumnIndex = newIndex
            }
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
        print("DEBUG: PinnedColumnBridgeViewController viewWillAppear => Refreshing summary card and pinned table.")
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
        customTopBarTopConstraint = customTopBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
        customTopBarTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            customTopBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTopBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTopBar.heightAnchor.constraint(equalToConstant: customNavBarHeight),
        ])

        // Back Button using UIButtonConfiguration (contentEdgeInsets is deprecated)
        var backConfig = UIButton.Configuration.plain()
        backConfig.image = UIImage(systemName: "chevron.left")
        backConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        backButton.configuration = backConfig
        backButton.tintColor = .white
        backButton.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: customTopBar.leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: customTopBar.safeAreaLayoutGuide.topAnchor, constant: 4.5)
        ])
        backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)

        // Title Label
        titleLabel.text = "Simulation Results"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: customTopBar.centerXAnchor, constant: -2.5),
            titleLabel.topAnchor.constraint(equalTo: customTopBar.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])

        // Chart Button
        chartButton.setImage(UIImage(systemName: "chart.line.uptrend.xyaxis"), for: .normal)
        chartButton.tintColor = .white
        chartButton.translatesAutoresizingMaskIntoConstraints = false
        customTopBar.addSubview(chartButton)
        NSLayoutConstraint.activate([
            chartButton.trailingAnchor.constraint(equalTo: customTopBar.trailingAnchor, constant: -16),
            chartButton.topAnchor.constraint(equalTo: customTopBar.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
        chartButton.addTarget(self, action: #selector(handleChartButton), for: .touchUpInside)
    }

    private func setupSummaryCardUI() {
        summaryCardContainer.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        summaryCardContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(summaryCardContainer)

        summaryCardTopConstraint =
            summaryCardContainer.topAnchor.constraint(equalTo: customTopBar.bottomAnchor, constant: 0)
        summaryCardTopConstraint?.isActive = true

        NSLayoutConstraint.activate([
            summaryCardContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            summaryCardContainer.widthAnchor.constraint(equalTo: view.widthAnchor),
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
        guard let container = representableContainer,
              let nav = navigationController,
              let manager = self.idleManager
        else {
            return
        }

        // 1) Build the closure first, storing a placeholder weak reference to chartHostingController
        var portfolioClosure: (() -> Void)!

        // 2) Create the SwiftUI view, referencing that closure (we'll assign it below)
        let chartView = MonteCarloResultsView(onSwitchToPortfolio: {
            // This will run after we assign the hosting controller to the weak variable
            portfolioClosure()
        })
        .environmentObject(container.coordinator)
        .environmentObject(container.simSettings)
        .environmentObject(container.simChartSelection)
        .environmentObject(container.chartDataCache)
        .environmentObject(manager)

        // 3) Initialize the ChartHostingController with 'chartView'
        let chartHostingController = ChartHostingController(
            coordinator: container.coordinator,
            chartDataCache: container.chartDataCache,
            simSettings: container.simSettings,
            idleManager: manager,
            content: chartView
        )

        // 4) Now that we have chartHostingController, define the real closure
        portfolioClosure = { [weak chartHostingController] in
            print("Portfolio button tapped from bridging screen. Pushing portfolio chart.")
            chartHostingController?.pushPortfolioChart()
        }

        // 5) Push the hosting controller
        nav.pushViewController(chartHostingController, animated: true)
    }

    @objc private func handleScrollToBottom() {
        pinnedColumnTablesVC.scrollToBottom()
    }

    // MARK: - Handling "isAtBottom"
    private func updateScrollToBottomButton(isAtBottom: Bool) {
        if isAtBottom {
            if !scrollToBottomButton.isHidden {
                UIView.animate(withDuration: 0.3) {
                    self.scrollToBottomButton.alpha = 0.0
                } completion: { finished in
                    if finished { self.scrollToBottomButton.isHidden = true }
                }
            }
        } else {
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
        
        // 1) Must have results
        guard !coord.monteCarloResults.isEmpty,
              let lastRow = coord.monteCarloResults.last else {
            return
        }
        
        // 2) Check if monthly or weekly
        let isMonthlyMode = coord.useMonthly
        
        // 3) Use monthlySimSettings.currencyPreferenceMonthly vs. simSettings.currencyPreference
        let currencyPref: PreferredCurrency = isMonthlyMode
            ? container.monthlySimSettings.currencyPreferenceMonthly
            : container.simSettings.currencyPreference
        
        // 4) BTC price for display.
        //    (Still using USD price for the card, but you can swap in btcPriceEUR if you prefer in EUR mode.)
        let finalBTC = lastRow.btcPriceUSD
        
        switch currencyPref {
            
        case .usd:
            // Portfolio in USD
            let finalPortfolio = lastRow.portfolioValueUSD
            
            // Sum up all contributions in USD
            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionUSD)
            }
            
            // Add either monthly or weekly startingBalance
            let actualStartBalance = Decimal(
                isMonthlyMode
                ? container.monthlySimSettings.startingBalanceMonthly
                : container.simSettings.startingBalance
            )
            totalContributed += actualStartBalance
            
            // Calculate growth
            let (growthPercentDouble, currencySymbol) =
                growthCalcWithContributions(finalPortfolio, totalContributed, symbol: "$")
            
            // Build SwiftUI summary card
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
            // Portfolio in EUR
            let finalPortfolio = lastRow.portfolioValueEUR
            
            // Sum up all contributions in EUR
            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionEUR)
            }
            
            // Add either monthly or weekly startingBalance
            let actualStartBalance = Decimal(
                isMonthlyMode
                ? container.monthlySimSettings.startingBalanceMonthly
                : container.simSettings.startingBalance
            )
            totalContributed += actualStartBalance
            
            // Calculate growth
            let (growthPercentDouble, currencySymbol) =
                growthCalcWithContributions(finalPortfolio, totalContributed, symbol: "€")
            
            // Build SwiftUI summary card
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
            // If user chooses "both," you appear to display USD portfolio in the card
            // but might show both in the pinned table. We'll keep it matching your existing code:
            let finalPortfolio = lastRow.portfolioValueUSD
            
            // Sum up all contributions in USD
            var totalContributed = Decimal(0)
            for row in coord.monteCarloResults {
                totalContributed += Decimal(row.contributionUSD)
            }
            
            // Add either monthly or weekly startingBalance
            let actualStartBalance = Decimal(
                isMonthlyMode
                ? container.monthlySimSettings.startingBalanceMonthly
                : container.simSettings.startingBalance
            )
            totalContributed += actualStartBalance
            
            // Calculate growth
            let (growthPercentDouble, currencySymbol) =
                growthCalcWithContributions(finalPortfolio, totalContributed, symbol: "$")
            
            // Build SwiftUI summary card
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
        let coord = container.coordinator
        
        // 1) The final Monte Carlo results
        let data = coord.monteCarloResults
        
        // 2) Check if monthly or weekly
        let isMonthlyMode = coord.useMonthly
        
        // 3) Pick the correct currency preference
        let pref: PreferredCurrency = isMonthlyMode
            ? container.monthlySimSettings.currencyPreferenceMonthly
            : container.simSettings.currencyPreference
        
        // 4) Decide pinned column title
        let pinnedColumnTitle = isMonthlyMode ? "Month" : "Week"
        
        // 5) Build an array of columns depending on the chosen currency
        let columns: [(String, PartialKeyPath<SimulationData>)]
        switch pref {
        case .usd:
            columns = [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)",      \SimulationData.netBTCHoldings),
                ("BTC Price (USD)",    \SimulationData.btcPriceUSD),
                ("Portfolio (USD)",    \SimulationData.portfolioValueUSD),
                ("Contrib (USD)",      \SimulationData.contributionUSD),
                ("Fee (USD)",          \SimulationData.transactionFeeUSD),
                ("Net Contrib (BTC)",  \SimulationData.netContributionBTC),
                ("Withdraw (USD)",     \SimulationData.withdrawalUSD)
            ]
            
        case .eur:
            columns = [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)",      \SimulationData.netBTCHoldings),
                ("BTC Price (EUR)",    \SimulationData.btcPriceEUR),
                ("Portfolio (EUR)",    \SimulationData.portfolioValueEUR),
                ("Contrib (EUR)",      \SimulationData.contributionEUR),
                ("Fee (EUR)",          \SimulationData.transactionFeeEUR),
                ("Net Contrib (BTC)",  \SimulationData.netContributionBTC),
                ("Withdraw (EUR)",     \SimulationData.withdrawalEUR)
            ]
            
        case .both:
            columns = [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC (BTC)",      \SimulationData.netBTCHoldings),
                ("BTC Price (USD)",    \SimulationData.btcPriceUSD),
                ("BTC Price (EUR)",    \SimulationData.btcPriceEUR),
                ("Portfolio (USD)",    \SimulationData.portfolioValueUSD),
                ("Portfolio (EUR)",    \SimulationData.portfolioValueEUR),
                ("Contrib (USD)",      \SimulationData.contributionUSD),
                ("Contrib (EUR)",      \SimulationData.contributionEUR),
                ("Fee (USD)",          \SimulationData.transactionFeeUSD),
                ("Fee (EUR)",          \SimulationData.transactionFeeEUR),
                ("Net Contrib (BTC)",  \SimulationData.netContributionBTC),
                ("Withdraw (USD)",     \SimulationData.withdrawalUSD),
                ("Withdraw (EUR)",     \SimulationData.withdrawalEUR)
            ]
        }
        
        // 6) Assign representable to pinnedColumnTablesVC
        pinnedColumnTablesVC.representable = PinnedColumnTablesRepresentable(
            displayedData: data,
            pinnedColumnTitle: pinnedColumnTitle,
            pinnedColumnKeyPath: \.week,  // <-- Make sure you actually have 'week' in SimulationData
            columns: columns,
            lastViewedRow: lastViewedRowBinding ?? .constant(0),
            lastViewedColumnIndex: lastViewedColumnIndexBinding ?? .constant(0),
            scrollToBottomFlag: .constant(false),
            isAtBottom: .constant(false)
        )

        // 7) Force a layout pass
        DispatchQueue.main.async {
            self.pinnedColumnTablesVC.view.setNeedsLayout()
            self.pinnedColumnTablesVC.view.layoutIfNeeded()
        }
        
        // Debug
        print("DEBUG: populatePinnedTable => data count = \(data.count). "
              + "Passing row=\(lastViewedRowBinding?.wrappedValue ?? -999), "
              + "col=\(lastViewedColumnIndexBinding?.wrappedValue ?? -999) to pinnedColumnTablesVC.")
    }

    private func growthCalcWithContributions(
        _ finalValue: Decimal,
        _ totalContributed: Decimal,
        symbol: String
    ) -> (Double, String) {
        guard totalContributed > 0 else { return (0.0, symbol) }
        let ratio = NSDecimalNumber(decimal: finalValue / totalContributed).doubleValue
        let growthDouble = (ratio - 1.0) * 100.0
        return (growthDouble, symbol)
    }

    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}
