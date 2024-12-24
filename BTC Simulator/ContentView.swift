//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 20/11/2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - RowOffset Helpers
struct RowOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        for (week, offset) in nextValue() {
            value[week] = offset
        }
    }
}

struct RowOffsetReporter: View {
    let week: Int
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: RowOffsetPreferenceKey.self,
                    value: [week: geo.frame(in: .named("scrollArea")).midY]
                )
        }
    }
}

// MARK: - PersistentInputManager
class PersistentInputManager: ObservableObject {
    @Published var iterations: String {
        didSet { UserDefaults.standard.set(iterations, forKey: "iterations") }
    }
    @Published var annualCAGR: String {
        didSet { UserDefaults.standard.set(annualCAGR, forKey: "annualCAGR") }
    }
    @Published var annualVolatility: String {
        didSet { UserDefaults.standard.set(annualVolatility, forKey: "annualVolatility") }
    }
    @Published var selectedWeek: String
    @Published var btcPriceMinInput: String
    @Published var btcPriceMaxInput: String
    @Published var portfolioValueMinInput: String
    @Published var portfolioValueMaxInput: String
    @Published var btcHoldingsMinInput: String
    @Published var btcHoldingsMaxInput: String
    @Published var btcGrowthRate: String

    init() {
        self.iterations = UserDefaults.standard.string(forKey: "iterations") ?? "1000"
        self.annualCAGR = UserDefaults.standard.string(forKey: "annualCAGR") ?? "40.0"
        self.annualVolatility = UserDefaults.standard.string(forKey: "annualVolatility") ?? "80.0"
        self.selectedWeek = UserDefaults.standard.string(forKey: "selectedWeek") ?? "1"
        self.btcPriceMinInput = UserDefaults.standard.string(forKey: "btcPriceMinInput") ?? ""
        self.btcPriceMaxInput = UserDefaults.standard.string(forKey: "btcPriceMaxInput") ?? ""
        self.portfolioValueMinInput = UserDefaults.standard.string(forKey: "portfolioValueMinInput") ?? ""
        self.portfolioValueMaxInput = UserDefaults.standard.string(forKey: "portfolioValueMaxInput") ?? ""
        self.btcHoldingsMinInput = UserDefaults.standard.string(forKey: "btcHoldingsMinInput") ?? ""
        self.btcHoldingsMaxInput = UserDefaults.standard.string(forKey: "btcHoldingsMaxInput") ?? ""
        self.btcGrowthRate = UserDefaults.standard.string(forKey: "btcGrowthRate") ?? "0.005"
    }

    func saveToDefaults() {
        UserDefaults.standard.set(iterations, forKey: "iterations")
        UserDefaults.standard.set(annualCAGR, forKey: "annualCAGR")
        UserDefaults.standard.set(annualVolatility, forKey: "annualVolatility")
        UserDefaults.standard.set(selectedWeek, forKey: "selectedWeek")
        UserDefaults.standard.set(btcPriceMinInput, forKey: "btcPriceMinInput")
        UserDefaults.standard.set(btcPriceMaxInput, forKey: "btcPriceMaxInput")
        UserDefaults.standard.set(portfolioValueMinInput, forKey: "portfolioValueMinInput")
        UserDefaults.standard.set(portfolioValueMaxInput, forKey: "portfolioValueMaxInput")
        UserDefaults.standard.set(btcHoldingsMinInput, forKey: "btcHoldingsMinInput")
        UserDefaults.standard.set(btcHoldingsMaxInput, forKey: "btcHoldingsMaxInput")
        UserDefaults.standard.set(btcGrowthRate, forKey: "btcGrowthRate")
    }

    func updateValue<T>(_ keyPath: ReferenceWritableKeyPath<PersistentInputManager, T>, to newValue: T) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self[keyPath: keyPath] = newValue
            self.saveToDefaults()
        }
    }

    func getParsedIterations() -> Int? {
        return Int(iterations.replacingOccurrences(of: ",", with: ""))
    }

    func getParsedAnnualCAGR() -> Double {
        let rawValue = annualCAGR.replacingOccurrences(of: ",", with: "")
        print("Debug: Raw Annual CAGR String = \(rawValue)")
        guard let parsedValue = Double(rawValue) else {
            print("Debug: Parsing failed, returning default value.")
            return 40.0
        }
        return parsedValue
    }
}

// MARK: - Formatters
extension Double {
    func formattedCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    func formattedBTC() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension View {
    @ViewBuilder
    func syncWithScroll<T>(of value: T, perform action: @escaping (T) -> Void) -> some View where T: Equatable {
        if #available(iOS 17, *) {
            self.onChange(of: value) { _, newValue in
                action(newValue)
            }
        } else {
            self.onChange(of: value) { newValue in
                action(newValue)
            }
        }
    }
}

extension EnvironmentValues {
    var scrollProxy: ScrollViewProxy? {
        get { self[ScrollViewProxyKey.self] }
        set { self[ScrollViewProxyKey.self] = newValue }
    }
}

struct ScrollViewProxyKey: EnvironmentKey {
    static let defaultValue: ScrollViewProxy? = nil
}

// MARK: - ContentView
struct ContentView: View {
    @State private var monteCarloResults: [SimulationData] = []
    @State private var isLoading: Bool = false
    @State private var pdfData: Data?
    @State private var showFileExporter = false
    @StateObject var inputManager = PersistentInputManager()
    @State private var isSimulationRun: Bool = false

    @State private var scrollToBottom: Bool = false
    @State private var isAtBottom: Bool = false
    @State private var lastViewedWeek: Int = 0

    @Environment(\.scrollProxy) private var scrollProxy: ScrollViewProxy?
    @State private var contentScrollProxy: ScrollViewProxy?

    @State private var currentPage: Int = 0
    @State private var lastViewedPage: Int = 0

    @State private var userHasScrolled = false

    let columns: [(String, PartialKeyPath<SimulationData>)] = [
        ("Starting BTC (BTC)", \SimulationData.startingBTC),
        ("Net BTC Holdings (BTC)", \SimulationData.netBTCHoldings),
        ("BTC Price USD", \SimulationData.btcPriceUSD),
        ("BTC Price EUR", \SimulationData.btcPriceEUR),
        ("Portfolio Value EUR", \SimulationData.portfolioValueEUR),
        ("Contribution EUR", \SimulationData.contributionEUR),
        ("Transaction Fee EUR", \SimulationData.transactionFeeEUR),
        ("Net Contribution BTC", \SimulationData.netContributionBTC),
        ("Withdrawal EUR", \SimulationData.withdrawalEUR)
    ]

    var body: some View {
        ZStack {
            // Entire background is the same grey as your "first row" colour
            Color(white: 0.12).ignoresSafeArea()
            
            VStack(spacing: 10) {
                if !isSimulationRun {
                    // INPUT FORM
                    VStack(spacing: 10) {
                        InputField(title: "Iterations", text: $inputManager.iterations)
                        InputField(title: "Annual CAGR (%)", text: $inputManager.annualCAGR)
                        InputField(title: "Annual Volatility (%)", text: $inputManager.annualVolatility)
                        
                        Button(action: {
                            if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                                currentPage = usdIndex
                            }
                            runSimulation()
                        }) {
                            Text("Run Simulation")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        
                        Button("Reset Saved Data") {
                            UserDefaults.standard.removeObject(forKey: "lastViewedWeek")
                            UserDefaults.standard.removeObject(forKey: "lastViewedPage")
                            lastViewedWeek = 0
                            lastViewedPage = 0
                            print("DEBUG: Reset user defaults and state.")
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    // RESULTS VIEW
                    ScrollViewReader { scrollProxy in
                        ZStack {
                            VStack {
                                Spacer().frame(height: 40)
                                
                                VStack(spacing: 0) {
                                    HStack(spacing: 0) {
                                        Text("Week")
                                            .frame(width: 60, alignment: .leading)
                                            .font(.headline)
                                            .padding(.leading, 50)
                                            .padding(.vertical, 8)
                                            // Keep the header black (if you like)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                        
                                        ZStack {
                                            Text(columns[currentPage].0)
                                                .font(.headline)
                                                .padding()
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                            
                                            GeometryReader { geometry in
                                                HStack(spacing: 0) {
                                                    Color.clear
                                                        .frame(width: geometry.size.width * 0.2)
                                                        .contentShape(Rectangle())
                                                        .gesture(
                                                            TapGesture()
                                                                .onEnded {
                                                                    if currentPage > 0 {
                                                                        withAnimation {
                                                                            currentPage -= 1
                                                                        }
                                                                    }
                                                                }
                                                        )
                                                    
                                                    Spacer()
                                                    
                                                    Color.clear
                                                        .frame(width: geometry.size.width * 0.2)
                                                        .contentShape(Rectangle())
                                                        .gesture(
                                                            TapGesture()
                                                                .onEnded {
                                                                    if currentPage < columns.count - 1 {
                                                                        withAnimation {
                                                                            currentPage += 1
                                                                        }
                                                                    }
                                                                }
                                                        )
                                                }
                                            }
                                        }
                                        .frame(height: 50)
                                    }
                                    .background(Color.black)
                                    
                                    // SCROLL AREA + OFFSET DETECTION
                                    ScrollView(.vertical, showsIndicators: true) {
                                        HStack(spacing: 0) {
                                            // WEEKS COLUMN
                                            VStack(spacing: 0) {
                                                // We use indices so we can alternate row colours
                                                ForEach(monteCarloResults.indices, id: \.self) { index in
                                                    let result = monteCarloResults[index]
                                                    // Alternate row background
                                                    let rowBackground = index.isMultiple(of: 2)
                                                        ? Color(white: 0.10)  // even row
                                                        : Color(white: 0.14)  // odd row
                                                    
                                                    Text("\(result.week)")
                                                        .frame(width: 70, alignment: .leading)  // increased width from 60 to 70
                                                        .padding(.leading, 50)                  // optional extra leading padding
                                                        .padding(.vertical, 12)
                                                        .padding(.horizontal, 8)
                                                        .background(rowBackground)
                                                        .foregroundColor(.white)
                                                        .id("week-\(result.week)")
                                                        .background(RowOffsetReporter(week: result.week))
                                                }
                                            }
                                            
                                            // TABVIEW OF COLUMNS
                                            TabView(selection: $currentPage) {
                                                ForEach(0..<columns.count, id: \.self) { index in
                                                    ZStack {
                                                        VStack(spacing: 0) {
                                                            ForEach(monteCarloResults.indices, id: \.self) { rowIndex in
                                                                let rowResult = monteCarloResults[rowIndex]
                                                                // alternate row background
                                                                let rowBackground = rowIndex.isMultiple(of: 2)
                                                                    ? Color(white: 0.10)
                                                                    : Color(white: 0.14)
                                                                
                                                                Text(getValue(rowResult, columns[index].1))
                                                                    .frame(maxWidth: .infinity, alignment: .center)
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
                                                                    .gesture(
                                                                        TapGesture()
                                                                            .onEnded {
                                                                                if currentPage > 0 {
                                                                                    withAnimation {
                                                                                        currentPage -= 1
                                                                                    }
                                                                                }
                                                                            }
                                                                    )
                                                                Spacer()
                                                                Color.clear
                                                                    .frame(width: geometry.size.width * 0.2)
                                                                    .contentShape(Rectangle())
                                                                    .gesture(
                                                                        TapGesture()
                                                                            .onEnded {
                                                                                if currentPage < columns.count - 1 {
                                                                                    withAnimation {
                                                                                        currentPage += 1
                                                                                    }
                                                                                }
                                                                            }
                                                                    )
                                                            }
                                                        }
                                                    }
                                                    .tag(index)
                                                }
                                            }
                                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                                            .frame(width: UIScreen.main.bounds.width - 60)
                                        }
                                        .coordinateSpace(name: "scrollArea")
                                        .onPreferenceChange(RowOffsetPreferenceKey.self) { offsets in
                                            let targetY: CGFloat = 160
                                            let filtered = offsets.filter { (week, _) in
                                                week != 1040
                                            }
                                            let mapped = filtered.mapValues { abs($0 - targetY) }
                                            if let (closestWeek, _) = mapped.min(by: { $0.value < $1.value }) {
                                                lastViewedWeek = closestWeek
                                            }
                                        }
                                        .onChange(of: scrollToBottom) { value in
                                            if value, let lastResult = monteCarloResults.last {
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
                                                    if atBottom != self.isAtBottom {
                                                        self.isAtBottom = atBottom
                                                    }
                                                }
                                                // color behind the content => same as first row (0.12)
                                                return Color(white: 0.12)
                                            }
                                        )
                                    }
                                }
                            }
                            // onAppear only sets local scrollProxy
                            .onAppear {
                                contentScrollProxy = scrollProxy
                                print("DEBUG: Results onAppear - contentScrollProxy set.")
                            }
                            .onDisappear {
                                print("DEBUG: onDisappear triggered. lastViewedWeek = \(lastViewedWeek), currentPage = \(currentPage).")
                                UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                                UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                                print("DEBUG: Successfully saved lastViewedWeek: \(lastViewedWeek) and lastViewedPage: \(currentPage).")
                            }
                            
                            // BACK BUTTON
                            VStack {
                                HStack {
                                    Button(action: {
                                        UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                                        UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
                                        print("DEBUG: Back button pressed, saving lastViewedWeek: \(lastViewedWeek), lastViewedPage: \(currentPage)")
                                        lastViewedPage = currentPage
                                        isSimulationRun = false
                                    }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundColor(.white)
                                            .imageScale(.large)
                                            .padding(.leading, 50)
                                            .padding(.vertical, 8)
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            
                            // SCROLL-TO-BOTTOM BUTTON
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
                                            .background(Color.black.opacity(0.7))
                                            .clipShape(Circle())
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            
            // FORWARD BUTTON
            if !isSimulationRun && !monteCarloResults.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            print("DEBUG: Forward button pressed, lastViewedWeek = \(lastViewedWeek)")
                            isSimulationRun = true
                            currentPage = lastViewedPage
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let scrollProxy = contentScrollProxy {
                                    let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
                                    if savedWeek != 0 {
                                        lastViewedWeek = savedWeek
                                        print("DEBUG: Forward button pressed, loaded lastViewedWeek: \(lastViewedWeek)")
                                    }
                                    if let target = monteCarloResults.first(where: { $0.week == lastViewedWeek }) {
                                        print("DEBUG: Found target with week: \(target.week)")
                                        withAnimation {
                                            scrollProxy.scrollTo("week-\(target.week)", anchor: .top)
                                        }
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .imageScale(.large)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        // Main onAppear: handle userDefaults + decide if we show results
        .onAppear {
            let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
            if savedWeek != 0 {
                lastViewedWeek = savedWeek
                print("DEBUG: onAppear (main), loaded lastViewedWeek: \(savedWeek)")
            }
            
            let savedPage = UserDefaults.standard.integer(forKey: "lastViewedPage")
            if savedPage < columns.count {
                lastViewedPage = savedPage
                currentPage = savedPage
                print("DEBUG: onAppear (main), loaded lastViewedPage: \(savedPage)")
            } else if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                currentPage = usdIndex
                lastViewedPage = usdIndex
                print("DEBUG: onAppear (main), defaulting to BTC Price USD at index \(usdIndex)")
            }
            
            if monteCarloResults.isEmpty {
                isSimulationRun = false
            } else {
                isSimulationRun = true
            }
        }
    }

    // MARK: - InputField
    struct InputField: View {
        let title: String
        @Binding var text: String

        var body: some View {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .frame(width: 200, alignment: .leading)
                TextField("Enter \(title)", text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.white)
                    .cornerRadius(5)
                    .frame(width: 150)
            }
        }
    }

    // MARK: - Simulation
    private func runSimulation() {
        isLoading = true
        monteCarloResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            // Pull user inputs into local variables
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(self.inputManager.annualVolatility) ?? 1.0) / 100.0

            // Debug print right here, so we can confirm the user’s values
            print("DEBUG: Using CAGR = \(userInputCAGR), Volatility = \(userInputVolatility)")

            guard let totalIterations = self.inputManager.getParsedIterations(), totalIterations > 0 else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Invalid number of iterations.")
                }
                return
            }

            // Now pass those local variables to your Monte Carlo function
            let (medianRun, allIterations) = runMonteCarloSimulationsWithSpreadsheetData(
                annualCAGR: userInputCAGR,
                annualVolatility: userInputVolatility,
                exchangeRateEURUSD: 1.06,
                totalWeeks: 1040,
                iterations: totalIterations
            )

            DispatchQueue.main.async {
                self.isLoading = false
                self.monteCarloResults = medianRun
                self.isSimulationRun = true

                print("Simulation complete (Median). Final portfolio: \(medianRun.last?.portfolioValueEUR ?? 0.0)")

                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allIterations)
                    self.generateHistogramForResults(
                        results: medianRun,
                        filePath: "/Users/conor/Desktop/PS Batch/portfolio_growth_histogram.png"
                    )
                }
            }
        }
    }

    // Example helper
    private func computeMeanPath(allResults: [[SimulationData]]) -> [SimulationData] {
        guard let firstRun = allResults.first else { return [] }
        let weeks = firstRun.count
        let total = Double(allResults.count)
        var meanPath: [SimulationData] = []

        for w in 0..<weeks {
            let slice = allResults.map { $0[w] }
            let avgBTCUSD = slice.map { $0.btcPriceUSD }.reduce(0, +) / total
            let avgBTCEUR = slice.map { $0.btcPriceEUR }.reduce(0, +) / total
            let avgPortVal = slice.map { $0.portfolioValueEUR }.reduce(0, +) / total
            let avgStartBTC = slice.map { $0.startingBTC }.reduce(0, +) / total
            let avgNetBTC = slice.map { $0.netBTCHoldings }.reduce(0, +) / total
            let avgContrib = slice.map { $0.contributionEUR }.reduce(0, +) / total
            let avgFee = slice.map { $0.transactionFeeEUR }.reduce(0, +) / total
            let avgNetContribBTC = slice.map { $0.netContributionBTC }.reduce(0, +) / total
            let avgWithdrawal = slice.map { $0.withdrawalEUR }.reduce(0, +) / total

            meanPath.append(SimulationData(
                week: w + 1,
                startingBTC: avgStartBTC,
                netBTCHoldings: avgNetBTC,
                btcPriceUSD: avgBTCUSD,
                btcPriceEUR: avgBTCEUR,
                portfolioValueEUR: avgPortVal,
                contributionEUR: avgContrib,
                transactionFeeEUR: avgFee,
                netContributionBTC: avgNetContribBTC,
                withdrawalEUR: avgWithdrawal
            ))
        }
        return meanPath
    }

    func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
        return z0 * standardDeviation + mean
    }

    private func processAllResults(_ allResults: [[SimulationData]]) {
        let portfolioValues = allResults.flatMap { $0.map { $0.portfolioValueEUR } }
        createHistogramWithLogBins(
            data: portfolioValues,
            title: "Portfolio Growth",
            fileName: "/Users/conor/Desktop/PS Batch/portfolio_growth_histogram.png"
        )
    }

    func generateHistogramForResults(results: [SimulationData], filePath: String) {
        let portfolioValues = results.map { $0.portfolioValueEUR }
        createHistogramWithLogBins(
            data: portfolioValues,
            title: "Portfolio Value Distribution",
            fileName: filePath,
            lowerPercentile: 0.01,
            upperPercentile: 0.99,
            binCount: 20,
            rotateLabels: true
        )
    }

    private func createHistogramWithLogBins(
        data: [Double],
        title: String,
        fileName: String,
        lowerPercentile: Double = 0.01,
        upperPercentile: Double = 0.99,
        binCount: Int = 20,
        rotateLabels: Bool = true
    ) {
        // Placeholder for histogram logic
    }

    private func getValue(_ item: SimulationData, _ keyPath: PartialKeyPath<SimulationData>) -> String {
        if let value = item[keyPath: keyPath] as? Double {
            switch keyPath {
            case \SimulationData.startingBTC,
                 \SimulationData.netBTCHoldings,
                 \SimulationData.netContributionBTC:
                return value.formattedBTC()
            case \SimulationData.btcPriceUSD,
                 \SimulationData.btcPriceEUR,
                 \SimulationData.portfolioValueEUR,
                 \SimulationData.contributionEUR,
                 \SimulationData.transactionFeeEUR,
                 \SimulationData.withdrawalEUR:
                return value.formattedCurrency()
            default:
                return String(format: "%.2f", value)
            }
        } else if let value = item[keyPath: keyPath] as? Int {
            return "\(value)"
        } else {
            return ""
        }
    }
}
