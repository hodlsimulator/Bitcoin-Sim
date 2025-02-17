//
//  SimulationResultsLandscapeView.swift
//  BTCMonteCarlo
//
//  Created by . . on 17/02/2025.
//

import SwiftUI

struct SimulationResultsLandscapeView: View {

    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var coordinator: SimulationCoordinator

    @Binding var lastViewedPage: Int
    @Binding var lastViewedWeek: Int
    @Binding var isAtBottom: Bool
    @Binding var showHistograms: Bool
    @Binding var scrollToBottom: Bool
    @Binding var lastScrollTime: Date
    @Binding var contentScrollProxy: ScrollViewProxy?
    @Binding var currentPage: Int
    @Binding var hideScrollIndicators: Bool

    @State private var currentTip: String = ""
    @State private var showTip: Bool = false
    @State private var tipTimer: Timer? = nil

    var body: some View {
        ScrollViewReader { scrollProxy in
            ZStack {
                Color(white: 0.12).edgesIgnoringSafeArea(.bottom)

                VStack(spacing: 0) {
                    
                    // Example top bar
                    HStack {
                        Button(action: {
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
                        .padding(.leading, 60)
                        
                        Spacer()
                        
                        Button(action: {
                            showHistograms = true
                        }) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(inputManager.generateGraphs ? .white : .gray)
                                .imageScale(.large)
                                .frame(width: 40, height: 40)
                        }
                        .disabled(!inputManager.generateGraphs)
                        .padding(.trailing, 60)
                    }
                    .padding(.vertical, 10)
                    .background(Color(white: 0.12))

                    // Summary card
                    let (finalBTCPrice, finalPortfolioValue, growthPercent, currencySymbol) = calculateSummaryValues()
                    SimulationSummaryCardView(
                        finalBTCPrice: finalBTCPrice,
                        finalPortfolioValue: finalPortfolioValue,
                        growthPercent: growthPercent,
                        currencySymbol: currencySymbol
                    )
                    .padding(.horizontal, 60)

                    // Header row
                    HStack(spacing: 0) {
                        Text(simSettings.periodUnit == .weeks ? "Week" : "Month")
                            .frame(width: 60, alignment: .leading)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .foregroundColor(.orange)

                        ZStack {
                            Text(landscapeColumns[currentPage].0)
                                .font(.headline)
                                .padding(.vertical, 8)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.2)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if currentPage > 0 {
                                                withAnimation { currentPage -= 1 }
                                            }
                                        }
                                    Spacer()
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.2)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if currentPage < landscapeColumns.count - 1 {
                                                withAnimation { currentPage += 1 }
                                            }
                                        }
                                }
                            }
                        }
                        .frame(height: 50)
                    }
                    .padding(.horizontal, 60)
                    .background(Color.black)
                    
                    // Main scrollable table
                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                        
                        let displayedResults = coordinator.monteCarloResults
                        
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ForEach(displayedResults.indices, id: \.self) { index in
                                    let result = displayedResults[index]
                                    let rowBackground = index.isMultiple(of: 2)
                                        ? Color(white: 0.10)
                                        : Color(white: 0.14)
                                    
                                    Text("\(result.week)")
                                        .frame(width: 70, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(rowBackground)
                                        .foregroundColor(.white)
                                        .id("week-\(result.week)")
                                        .background(RowOffsetReporter(week: result.week))
                                }
                            }
                            
                            // PageTabView for multiple columns
                            TabView(selection: $currentPage) {
                                ForEach(0..<landscapeColumns.count, id: \.self) { idx in
                                    ZStack {
                                        VStack(spacing: 0) {
                                            ForEach(displayedResults.indices, id: \.self) { rowIndex in
                                                let rowResult = displayedResults[rowIndex]
                                                let rowBackground = rowIndex.isMultiple(of: 2)
                                                    ? Color(white: 0.10)
                                                    : Color(white: 0.14)
                                                
                                                Text(getValueForTable(rowResult, landscapeColumns[idx].1))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal, 8)
                                                    .background(rowBackground)
                                                    .foregroundColor(.white)
                                                    .id("data-week-\(rowResult.week)")
                                                    .background(RowOffsetReporter(week: rowResult.week))
                                            }
                                        }
                                        GeometryReader { geometry in
                                            HStack(spacing: 0) {
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        if currentPage > 0 {
                                                            withAnimation { currentPage -= 1 }
                                                        }
                                                    }
                                                Spacer()
                                                Color.clear
                                                    .frame(width: geometry.size.width * 0.2)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        if currentPage < landscapeColumns.count - 1 {
                                                            withAnimation { currentPage += 1 }
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                    .tag(idx)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(width: UIScreen.main.bounds.width - 90)
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
                            GeometryReader { geometry -> Color in
                                DispatchQueue.main.async {
                                    let atBottom = geometry.frame(in: .global).maxY <= UIScreen.main.bounds.height
                                    if atBottom != isAtBottom {
                                        isAtBottom = atBottom
                                    }
                                }
                                return Color(white: 0.12)
                            }
                        )
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
                .onAppear {
                    contentScrollProxy = scrollProxy
                }
                .onDisappear {
                    UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                    UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                }
                
                // “Scroll to bottom” button
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

    // Slightly different columns in landscape
    private var landscapeColumns: [(String, PartialKeyPath<SimulationData>)] {
        switch simSettings.currencyPreference {
        case .usd:
            return [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (USD)", \SimulationData.btcPriceUSD),
                ("Portfolio (USD)", \SimulationData.portfolioValueUSD),
                ("Contrib (USD)", \SimulationData.contributionUSD),
                ("Fee (USD)", \SimulationData.transactionFeeUSD),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw (USD)", \SimulationData.withdrawalUSD),
                ("Extra Col 1", \SimulationData.netContributionBTC),
                ("Extra Col 2", \SimulationData.netContributionBTC)
            ]
        case .eur:
            return [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price (EUR)", \SimulationData.btcPriceEUR),
                ("Portfolio (EUR)", \SimulationData.portfolioValueEUR),
                ("Contrib (EUR)", \SimulationData.contributionEUR),
                ("Fee (EUR)", \SimulationData.transactionFeeEUR),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw (EUR)", \SimulationData.withdrawalEUR),
                ("Extra Col 1", \SimulationData.netContributionBTC),
                ("Extra Col 2", \SimulationData.netContributionBTC)
            ]
        case .both:
            return [
                ("Starting BTC (BTC)", \SimulationData.startingBTC),
                ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
                ("BTC Price USD", \SimulationData.btcPriceUSD),
                ("BTC Price EUR", \SimulationData.btcPriceEUR),
                ("Portfolio USD", \SimulationData.portfolioValueUSD),
                ("Portfolio EUR", \SimulationData.portfolioValueEUR),
                ("Contrib USD", \SimulationData.contributionUSD),
                ("Contrib EUR", \SimulationData.contributionEUR),
                ("Fee USD", \SimulationData.transactionFeeUSD),
                ("Fee EUR", \SimulationData.transactionFeeEUR),
                ("Net Contrib BTC", \SimulationData.netContributionBTC),
                ("Withdraw USD", \SimulationData.withdrawalUSD),
                ("Withdraw EUR", \SimulationData.withdrawalEUR),
                ("Extra Col 1", \SimulationData.netContributionBTC),
                ("Extra Col 2", \SimulationData.netContributionBTC)
            ]
        }
    }

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
            
        } else if let doubleVal = item[keyPath: keyPath] as? Double {
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
        } else if let intVal = item[keyPath: keyPath] as? Int {
            return "\(intVal)"
        } else {
            return ""
        }
    }
}
