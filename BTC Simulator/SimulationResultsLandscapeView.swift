//
//  SimulationResultsLandscapeView.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/02/2025.
//

import SwiftUI

// A PreferenceKey for tracking geometry changes (for “at bottom” detection).
private struct AtBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct SimulationResultsLandscapeView: View {

    // MARK: - Environment Objects
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var coordinator: SimulationCoordinator

    // MARK: - Bindings
    @Binding var lastViewedPage: Int
    @Binding var lastViewedWeek: Int
    @Binding var isAtBottom: Bool
    @Binding var showHistograms: Bool
    @Binding var scrollToBottom: Bool
    @Binding var lastScrollTime: Date
    @Binding var contentScrollProxy: ScrollViewProxy?
    @Binding var currentPage: Int
    @Binding var hideScrollIndicators: Bool

    // MARK: - Local State
    @State private var currentTip: String = ""
    @State private var showTip: Bool = false
    @State private var tipTimer: Timer? = nil

    // MARK: - Body
    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                // Overall background colour
                Color(white: 0.12)
                    .edgesIgnoringSafeArea(.bottom)

                VStack(spacing: 0) {
                    
                    // =========================================
                    // 1) TOP SUMMARY CARD WITH BUTTONS OVERLAY
                    // =========================================
                    ZStack(alignment: .topLeading) {

                        // Break tuple assignment so Swift can type-check easily
                        let summaryValues = calculateSummaryValues()
                        let finalBTCPrice = summaryValues.0
                        let finalPortfolioValue = summaryValues.1
                        let growthPercent = summaryValues.2
                        let currencySymbol = summaryValues.3

                        SimulationSummaryCardView(
                            finalBTCPrice: finalBTCPrice,
                            finalPortfolioValue: finalPortfolioValue,
                            growthPercent: growthPercent,
                            currencySymbol: currencySymbol
                        )
                        .frame(height: 80)                // <-- Adjust the summary card height
                        .padding(.horizontal, 20)         // <-- Horizontal padding around the card
                        .background(Color(white: 0.15))   // <-- Darker background for the summary card
                        .cornerRadius(8)                  // <-- Rounded corners

                        HStack {
                            // Back Arrow (left side)
                            Button(action: {
                                // Save last viewed page & week, then exit simulation
                                UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                                UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                                lastViewedPage = currentPage
                                coordinator.isSimulationRun = false
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.white)
                                    .imageScale(.large)
                                    .frame(width: 40, height: 40)
                            }
                            .padding(.leading, 10) // <-- Left padding for the back arrow

                            Spacer()

                            // Chart/Histogram Button (right side)
                            Button(action: {
                                showHistograms = true
                            }) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .foregroundColor(inputManager.generateGraphs ? .white : .gray)
                                    .imageScale(.large)
                                    .frame(width: 40, height: 40)
                            }
                            .disabled(!inputManager.generateGraphs)
                            .padding(.trailing, 80) // <-- Right padding for the chart button
                        }
                        .padding(.top, 5)            // <-- Padding from top of the summary card
                        .padding(.horizontal, 20)    // <-- Align with summary card's horizontal
                    }
                    .padding(.vertical, 10) // <-- Extra space above & below the top card

                    // =====================
                    // 2) HEADER ROW (BLACK)
                    // =====================
                    HStack(spacing: 0) {
                        // Left pinned label: “Week” or “Month”
                        Text(simSettings.periodUnit == .weeks ? "Week" : "Month")
                            .font(.headline)
                            .foregroundColor(.orange)
                            // The pinned label width & alignment
                            .frame(width: 70, alignment: .leading)
                            .padding(.leading, 10)    // <-- Adjust how far from left the text is
                            .padding(.vertical, 8)    // <-- Adjust vertical padding
                            // We'll rely on the outer background for black
                            .background(Color.black)

                        // Column titles stacked horizontally:
                        HStack(spacing: 60) {        // <-- Adjust spacing between each column title
                            let visibleColumns = columnsForCurrentPage
                            ForEach(visibleColumns, id: \.0) { (title, _) in
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                    .padding(.leading, 40) // <-- Moves titles further to the right
                                    .padding(.vertical, 8) // <-- Vertical space around each title
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black) // <-- The rest of the header also black
                    }
                    // This entire HStack is black, so there's a single black bar across the top

                    // ===========================
                    // 3) MAIN SCROLLABLE CONTENT
                    // ===========================
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {

                        let displayedResults = coordinator.monteCarloResults

                        HStack(spacing: 0) {

                            // Left pinned column for “Week #”
                            VStack(spacing: 0) {
                                ForEach(displayedResults.indices, id: \.self) { index in
                                    let result = displayedResults[index]
                                    // Alternate row background
                                    let rowBackground = (index % 2 == 0)
                                        ? Color(white: 0.10)
                                        : Color(white: 0.14)

                                    Text("\(result.week)")
                                        .frame(width: 70, alignment: .leading)
                                        .padding(.leading, 10)   // <-- Adjust pinned column left padding
                                        .padding(.vertical, 12)  // <-- Vertical space in pinned column
                                        .padding(.horizontal, 8) // <-- Extra horizontal space if needed
                                        .background(rowBackground)
                                        .foregroundColor(.white)
                                        .id("week-\(result.week)")
                                        .background(RowOffsetReporter(week: result.week))
                                }
                            }

                            // Swipeable TabView for columns
                            TabView(selection: $currentPage) {
                                ForEach(0..<allSlidingWindows.count, id: \.self) { pageIndex in
                                    let windowColumns = allSlidingWindows[pageIndex]

                                    VStack(spacing: 0) {
                                        ForEach(displayedResults.indices, id: \.self) { rowIndex in
                                            let rowResult = displayedResults[rowIndex]
                                            // Alternate row background
                                            let rowBackground = (rowIndex % 2 == 0)
                                                ? Color(white: 0.10)
                                                : Color(white: 0.14)

                                            HStack(spacing: 0) {
                                                // Show each column in the current 3-col window
                                                ForEach(Array(windowColumns.enumerated()), id: \.element.0) { (colIndex, colItem) in
                                                    Text(getValueForTable(rowResult, colItem.1))
                                                        // Move first two columns left more by using smaller left padding:
                                                        .padding(.leading, colIndex < 2 ? 20 : 50)
                                                        .padding(.vertical, 12)
                                                        .padding(.horizontal, 10)
                                                        .background(rowBackground)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .id("data-week-\(rowResult.week)")
                                            .background(RowOffsetReporter(week: rowResult.week))
                                        }
                                    }
                                    // Invisible “hotspots” for left/right taps
                                    .overlay(
                                        GeometryReader { geometry in
                                            HStack(spacing: 0) {
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        // Swipe left
                                                        if currentPage > 0 {
                                                            withAnimation {
                                                                currentPage -= 1
                                                            }
                                                        }
                                                    }
                                                Spacer()
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        // Swipe right
                                                        if currentPage < allSlidingWindows.count - 1 {
                                                            withAnimation {
                                                                currentPage += 1
                                                            }
                                                        }
                                                    }
                                            }
                                        }
                                    )
                                    .tag(pageIndex)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            // Fix rotation transition clipping bug:
                            .compositingGroup()
                            // Make room for pinned column:
                            .frame(width: UIScreen.main.bounds.width - 90)
                        }
                        .coordinateSpace(name: "scrollArea")
                        // Track row offset to see which week is near the top
                        .onPreferenceChange(RowOffsetPreferenceKey.self) { offsets in
                            let targetY: CGFloat = 160 + 120
                            let finalWeeks = simSettings.userPeriods
                            let filtered = offsets.filter { (week, _) in
                                week >= 0 && week <= finalWeeks
                            }
                            let mapped = filtered.mapValues { abs($0 - targetY) }
                            if let (closestWeek, _) = mapped.min(by: { $0.value < $1.value }) {
                                lastViewedWeek = closestWeek
                            }
                        }
                        // If triggered, scroll to the bottom
                        .onChange(of: scrollToBottom, initial: false) { _, value in
                            if value, let lastResult = coordinator.monteCarloResults.last {
                                withAnimation {
                                    scrollProxy.scrollTo("week-\(lastResult.week)", anchor: .bottom)
                                }
                                scrollToBottom = false
                            }
                        }
                        // Track geometry to detect if we are at bottom
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: AtBottomPreferenceKey.self,
                                                value: geometry.frame(in: .global).maxY)
                            }
                        )
                        .onPreferenceChange(AtBottomPreferenceKey.self) { maxY in
                            let atBottom = maxY <= UIScreen.main.bounds.height
                            if atBottom != isAtBottom {
                                isAtBottom = atBottom
                            }
                        }
                        // Show/hide scroll indicators on drag
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    hideScrollIndicators = false
                                    lastScrollTime = Date()
                                }
                                .onEnded { _ in
                                    lastScrollTime = Date()
                                }
                        )
                    }
                    // Timer to re-hide scroll indicators
                    .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
                        if Date().timeIntervalSince(lastScrollTime) > 1.5 {
                            hideScrollIndicators = true
                        }
                    }
                }
                // Capture the scrollProxy so we can programmatically scroll
                .onAppear {
                    contentScrollProxy = scrollProxy
                    currentPage = 0  // Force page=0 so default columns are Net BTC, BTC Price, Portfolio
                }
                .onDisappear {
                    // Save user’s last positions
                    UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                // Scroll-to-bottom floating button if not at bottom
                if !isAtBottom {
                    VStack {
                        Spacer()
                        Button(action: {
                            scrollToBottom = true
                        }) {
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding()                       // <-- Space around the icon inside circle
                                .background(Color(white: 0.2).opacity(0.9))
                                .clipShape(Circle())
                        }
                        .padding() // <-- Space around the button itself
                    }
                }
            }
        }
    }

    // MARK: - Columns & Sliding Window Logic

    /// For .usd, index 0 => Net BTC, 1 => BTC Price, 2 => Portfolio, etc.
    private var allColumns: [(String, PartialKeyPath<SimulationData>)] {
        switch simSettings.currencyPreference {
        case .usd:
            // Re-ordered so index 0,1,2 => Net BTC, BTC Price, Portfolio
            return [
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (USD)", \SimulationData.btcPriceUSD),
                ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
                ("Contrib (USD)", \SimulationData.contributionUSD),
                ("Fee (USD)", \SimulationData.transactionFeeUSD),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw (USD)", \SimulationData.withdrawalUSD),
            ]
        case .eur:
            return [
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (EUR)", \SimulationData.btcPriceEUR),
                ("Portfolio (EUR)", \SimulationData.portfolioValueEUR),
                ("Contrib (EUR)", \SimulationData.contributionEUR),
                ("Fee (EUR)", \SimulationData.transactionFeeEUR),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw (EUR)", \SimulationData.withdrawalEUR),
            ]
        case .both:
            return [
                ("Net BTC (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price USD", \SimulationData.btcPriceUSD),
                ("Portfolio USD", \SimulationData.portfolioValueUSD),
                ("BTC Price EUR", \SimulationData.btcPriceEUR),
                ("Portfolio EUR", \SimulationData.portfolioValueEUR),
                ("Contrib USD", \SimulationData.contributionUSD),
                ("Contrib EUR", \SimulationData.contributionEUR),
                ("Fee USD", \SimulationData.transactionFeeUSD),
                ("Fee EUR", \SimulationData.transactionFeeEUR),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw USD", \SimulationData.withdrawalUSD),
                ("Withdraw EUR", \SimulationData.withdrawalEUR),
            ]
        }
    }
    
    /// Creates sliding windows of size 3 columns (page 0 => columns[0..2])
    private var allSlidingWindows: [[(String, PartialKeyPath<SimulationData>)]] {
        let cols = allColumns
        let n = cols.count
        guard n > 3 else {
            // If there are ≤ 3 columns total, just show them in one “page”
            return [cols]
        }
        var result = [[(String, PartialKeyPath<SimulationData>)]]()
        for start in 0...(n - 3) {
            let slice = Array(cols[start..<(start + 3)])
            result.append(slice)
        }
        return result
    }

    /// The columns for the current page. Page 0 => Net BTC, BTC Price, Portfolio
    private var columnsForCurrentPage: [(String, PartialKeyPath<SimulationData>)] {
        let pages = allSlidingWindows
        guard currentPage >= 0 && currentPage < pages.count else {
            return pages.first ?? []
        }
        return pages[currentPage]
    }


    // MARK: - Summary Calculation
    private func calculateSummaryValues() -> (Double, Double, Double, String) {
        guard let lastRow = coordinator.monteCarloResults.last else {
            return (0, 0, 0, "$")
        }
        
        let finalBTC: Double
        let finalPortfolio: Double
        let totalContributions: Double
        let symbol: String
        
        switch simSettings.currencyPreference {
        case .usd:
            finalBTC = NSDecimalNumber(decimal: lastRow.btcPriceUSD).doubleValue
            finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueUSD).doubleValue
            totalContributions = coordinator.monteCarloResults.reduce(0.0) {
                $0 + $1.contributionUSD
            }
            symbol = "$"
        case .eur:
            finalBTC = NSDecimalNumber(decimal: lastRow.btcPriceEUR).doubleValue
            finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueEUR).doubleValue
            totalContributions = coordinator.monteCarloResults.reduce(0.0) {
                $0 + $1.contributionEUR
            }
            symbol = "€"
        case .both:
            let userPickedCurrencyForContrib = coordinator.useMonthly
                ? monthlySimSettings.contributionCurrencyWhenBothMonthly
                : simSettings.contributionCurrencyWhenBoth
            
            switch userPickedCurrencyForContrib {
            case .usd:
                finalBTC = NSDecimalNumber(decimal: lastRow.btcPriceUSD).doubleValue
                finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueUSD).doubleValue
                totalContributions = coordinator.monteCarloResults.reduce(0.0) {
                    $0 + $1.contributionUSD
                }
                symbol = "$"
            case .eur:
                finalBTC = NSDecimalNumber(decimal: lastRow.btcPriceEUR).doubleValue
                finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueEUR).doubleValue
                totalContributions = coordinator.monteCarloResults.reduce(0.0) {
                    $0 + $1.contributionEUR
                }
                symbol = "€"
            case .both:
                finalBTC = NSDecimalNumber(decimal: lastRow.btcPriceUSD).doubleValue
                finalPortfolio = NSDecimalNumber(decimal: lastRow.portfolioValueUSD).doubleValue
                totalContributions = coordinator.monteCarloResults.reduce(0.0) {
                    $0 + $1.contributionUSD
                }
                symbol = "$"
            }
        }
        
        var growth = 0.0
        if totalContributions > 0 {
            growth = (finalPortfolio - totalContributions) / totalContributions * 100.0
        }
        
        return (finalBTC, finalPortfolio, growth, symbol)
    }

    // MARK: - Table Value Formatter
    private func getValueForTable(
        _ item: SimulationData,
        _ keyPath: PartialKeyPath<SimulationData>
    ) -> String {
        if let decimalVal = item[keyPath: keyPath] as? Decimal {
            let doubleValue = NSDecimalNumber(decimal: decimalVal).doubleValue
            switch keyPath {
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.portfolioValueUSD:
                // For large numbers, show power-of-ten suffix
                if abs(doubleValue) < 1_000_000_000_000_000 {
                    return doubleValue.formattedCurrency()
                } else {
                    return doubleValue.formattedWithPowerOfTenSuffix()
                }
            default:
                return doubleValue.formattedCurrency()
            }
        }
        else if let doubleVal = item[keyPath: keyPath] as? Double {
            switch keyPath {
            case \SimulationData.startingBTC,
                 \SimulationData.netBTCHoldings,
                 \SimulationData.netContributionBTC:
                return doubleVal.formattedBTC()
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.portfolioValueUSD:
                if abs(doubleVal) < 1_000_000_000_000_000 {
                    return doubleVal.formattedCurrency()
                } else {
                    return doubleVal.formattedWithPowerOfTenSuffix()
                }
            case \SimulationData.contributionEUR,
                 \SimulationData.contributionUSD,
                 \SimulationData.transactionFeeEUR,
                 \SimulationData.transactionFeeUSD,
                 \SimulationData.withdrawalEUR,
                 \SimulationData.withdrawalUSD:
                return doubleVal.formattedCurrency()
            default:
                return String(format: "%.2f", doubleVal)
            }
        }
        else if let intVal = item[keyPath: keyPath] as? Int {
            return "\(intVal)"
        }
        else {
            return ""
        }
    }
}

// MARK: - Safe Subscript Helper
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
