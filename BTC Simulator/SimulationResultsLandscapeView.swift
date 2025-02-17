//
//  SimulationResultsLandscapeView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import SwiftUI

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
    
    // If you need orientation logic, keep your OrientationObserver or remove it entirely:
    // @ObservedObject var orientationObserver = OrientationObserver()

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                // Background colour
                Color(white: 0.12)
                    .edgesIgnoringSafeArea(.bottom)
                
                VStack(spacing: 0) {
                    topSummaryBar
                    headerRow
                    mainScrollableContent(scrollProxy)
                }
                .onAppear {
                    contentScrollProxy = scrollProxy
                    currentPage = 0
                }
                .onDisappear {
                    // If you want to remember page/week:
                    // UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    // UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                // Scroll-to-bottom floating button
                if !isAtBottom {
                    VStack {
                        Spacer()
                        Button(action: {
                            scrollToBottom = true
                        }) {
                            Image(systemName: "chevron.down")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding()
                                .background(Color(white: 0.2).opacity(0.9))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Subviews

extension SimulationResultsLandscapeView {
    
    /// Top bar with summary card, back button, histogram button, etc.
    private var topSummaryBar: some View {
        ZStack(alignment: .topLeading) {
            let (finalBTCPrice, finalPortfolioValue, growthPercent, currencySymbol) = calculateSummaryValues()
            
            // Summary Card
            SimulationSummaryCardView(
                finalBTCPrice: finalBTCPrice,
                finalPortfolioValue: finalPortfolioValue,
                growthPercent: growthPercent,
                currencySymbol: currencySymbol
            )
            .frame(height: 80)
            .padding(.horizontal, 20)
            .background(Color(white: 0.15))
            .cornerRadius(8)

            HStack {
                // Back arrow
                Button(action: {
                    lastViewedPage = currentPage
                    coordinator.isSimulationRun = false
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .imageScale(.large)
                        .frame(width: 40, height: 40)
                }
                .padding(.leading, 10)

                Spacer()
                
                // Chart/histogram button
                Button(action: {
                    showHistograms = true
                }) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(inputManager.generateGraphs ? .white : .gray)
                        .imageScale(.large)
                        .frame(width: 40, height: 40)
                }
                .disabled(!inputManager.generateGraphs)
                .padding(.trailing, 80)
            }
            .padding(.top, 5)
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }
    
    /// Black header row with pinned "Week"/"Month" label + visible columns.
    private var headerRow: some View {
        HStack(spacing: 0) {
            Text(simSettings.periodUnit == .weeks ? "Week" : "Month")
                .font(.headline)
                .foregroundColor(.orange)
                .frame(width: 70, alignment: .leading)
                .padding(.leading, 10)
                .padding(.vertical, 8)

            // We show the "visible columns" if you prefer. But since we have a horizontal scroll for them,
            // you might just show a placeholder or partial. For simplicity, let's do the first chunk's titles:
            let visibleColumns = columnsChunks.first ?? []
            HStack(spacing: 60) {
                ForEach(visibleColumns.indices, id: \.self) { index in
                    let (title, _) = visibleColumns[index]
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.leading, 40)
                        .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black)
    }
    
    /// The main scrollable content area: pinned "Week" column + horizontally scrolling columns
    private func mainScrollableContent(_ scrollProxy: ScrollViewProxy) -> some View {
        ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
            let displayedResults = coordinator.monteCarloResults

            HStack(spacing: 0) {
                // Pinned "Week" column on the left
                VStack(spacing: 0) {
                    ForEach(displayedResults.indices, id: \.self) { rowIndex in
                        let result = displayedResults[rowIndex]
                        let rowBackground = rowIndex.isMultiple(of: 2) ? Color(white: 0.10) : Color(white: 0.14)
                        
                        Text("\(result.week)")
                            .frame(width: 70, alignment: .leading)
                            .padding(.leading, 10)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(rowBackground)
                            .foregroundColor(.white)
                            .id("week-\(result.week)")
                            .background(RowOffsetReporter(week: result.week))
                    }
                }
                .frame(width: 70)
                
                // Now the horizontally scrollable "pages" of columns
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            // Each chunk of 3 columns is its own "page"
                            ForEach(columnsChunks.indices, id: \.self) { chunkIndex in
                                let chunk = columnsChunks[chunkIndex]
                                
                                // Each chunk is a vertical stack of row data
                                VStack(spacing: 0) {
                                    ForEach(displayedResults.indices, id: \.self) { rowIndex in
                                        let rowResult = displayedResults[rowIndex]
                                        let rowBackground = rowIndex.isMultiple(of: 2) ? Color(white: 0.10) : Color(white: 0.14)
                                        
                                        HStack(spacing: 0) {
                                            ForEach(chunk.indices, id: \.self) { colIndex in
                                                let (title, keyPath) = chunk[colIndex]
                                                
                                                Text(getValueForTable(rowResult, keyPath))
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
                                // If you want each chunk to match the screen width, do this:
                                .frame(width: geometry.size.width)
                            }
                        }
                    }
                }
            }
            .coordinateSpace(name: "scrollArea")
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
            .onChange(of: scrollToBottom, initial: false) { _, value in
                if value, let lastResult = coordinator.monteCarloResults.last {
                    withAnimation {
                        scrollProxy.scrollTo("week-\(lastResult.week)", anchor: .bottom)
                    }
                    scrollToBottom = false
                }
            }
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
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            if Date().timeIntervalSince(lastScrollTime) > 1.5 {
                hideScrollIndicators = true
            }
        }
    }
}

// MARK: - Supporting Logic

extension SimulationResultsLandscapeView {
    
    // Instead of a TabView, we define our columns in "chunks" of size 3.
    private var columnsChunks: [[(String, PartialKeyPath<SimulationData>)]] {
        let chunkSize = 3
        let cols = allColumns
        var result = [[(String, PartialKeyPath<SimulationData>)]]()
        var current = [(String, PartialKeyPath<SimulationData>)]()
        
        for item in cols {
            current.append(item)
            if current.count == chunkSize {
                result.append(current)
                current.removeAll()
            }
        }
        // If there's a remainder not exactly chunkSize, add it too:
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
    
    private var allColumns: [(String, PartialKeyPath<SimulationData>)] {
        switch simSettings.currencyPreference {
        case .usd:
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
    
    /// Calculate final BTC price, portfolio, etc. for the top summary card
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
    
    /// Formats table data for any row/column
    private func getValueForTable(_ item: SimulationData,
                                  _ keyPath: PartialKeyPath<SimulationData>) -> String {
        if let decimalVal = item[keyPath: keyPath] as? Decimal {
            let doubleValue = NSDecimalNumber(decimal: decimalVal).doubleValue
            switch keyPath {
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.portfolioValueUSD:
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
    