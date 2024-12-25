//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by ... on 20/11/2024.
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import PocketSVG

extension CGPath {
    static func create(fromSVGPath svgString: String) -> CGPath {
        // PocketSVG parses the path string into an array of UIBezierPaths
        let paths = SVGBezierPath.paths(fromSVGString: svgString)

        // Merge all the UIBezierPaths into one CGPath
        let combined = CGMutablePath()
        for p in paths {
            combined.addPath(p.cgPath)
        }

        return combined
    }
}

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
        Int(iterations.replacingOccurrences(of: ",", with: ""))
    }

    func getParsedAnnualCAGR() -> Double {
        let rawValue = annualCAGR.replacingOccurrences(of: ",", with: "")
        guard let parsedValue = Double(rawValue) else {
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

// MARK: - Official Shapes for the Logo
struct BitcoinCircleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pathString = """
        <path d="M4030.06 2540.77 \
        c-273.24,1096.01 -1383.32,1763.02 -2479.46,1489.71 \
        -1095.68,-273.24 -1762.69,-1383.39 -1489.33,-2479.31 \
        273.12,-1096.13 1383.2,-1763.19 2479,-1489.95 \
        1096.06,273.24 1763.03,1383.51 1489.76,2479.57 \
        l0.02 -0.02z" />
        """

        let original = CGPath.create(fromSVGPath: pathString)
        let box = original.boundingBox

        let baseScale = min(rect.width / box.width, rect.height / box.height)
        let circleScale = baseScale * 1.08
        
        var transform = CGAffineTransform.identity
        transform = transform
            .translatedBy(x: rect.midX, y: rect.midY)
            .scaledBy(x: circleScale, y: circleScale)
            .translatedBy(x: -box.midX, y: -box.midY)

        let scaledPath = original.copy(using: &transform) ?? original
        return Path(scaledPath)
    }
}

struct BitcoinBShape: Shape {
    func path(in rect: CGRect) -> Path {
        let pathString = """
        <path d="M2947.77 1754.38
        c40.72,-272.26 -166.56,-418.61 -450,-516.24
        l91.95 -368.8 -224.5 -55.94 -89.51 359.09
        c-59.02,-14.72 -119.63,-28.59 -179.87,-42.34
        l90.16 -361.46 -224.36 -55.94 -92 368.68
        c-48.84,-11.12 -96.81,-22.11 -143.35,-33.69
        l0.26 -1.16 -309.59 -77.31 -59.72 239.78
        c0,0 166.56,38.18 163.05,40.53 90.91,22.69 107.35,82.87 104.62,130.57
        l-104.74 420.15
        c6.26,1.59 14.38,3.89 23.34,7.49
        -7.49,-1.86 -15.46,-3.89 -23.73,-5.87
        l-146.81 588.57
        c-11.11,27.62 -39.31,69.07 -102.87,53.33
        2.25,3.26 -163.17,-40.72 -163.17,-40.72
        l-111.46 256.98 292.15 72.83
        c54.35,13.63 107.61,27.89 160.06,41.3
        l-92.9 373.03 224.24 55.94 92 -369.07
        c61.26,16.63 120.71,31.97 178.91,46.43
        l-91.69 367.33 224.51 55.94 92.89 -372.33
        c382.82,72.45 670.67,43.24 791.83,-303.02
        97.63,-278.78 -4.86,-439.58 -206.26,-544.44
        146.69,-33.83 257.18,-130.31 286.64,-329.61
        l-0.07 -0.05
        zm-512.93 719.26
        c-69.38,278.78 -538.76,128.08 -690.94,90.29
        l123.28 -494.2
        c152.17,37.99 640.17,113.17 567.67,403.91
        zm69.43 -723.3
        c-63.29,253.58 -453.96,124.75 -580.69,93.16
        l111.77 -448.21
        c126.73,31.59 534.85,90.55 468.94,355.05
        l-0.02 0z" />
        """

        let original = CGPath.create(fromSVGPath: pathString)
        let box = original.boundingBox

        let baseScale = min(rect.width / box.width, rect.height / box.height)
        let bScale = baseScale * 0.7

        var transform = CGAffineTransform.identity
        transform = transform
            .translatedBy(x: rect.midX, y: rect.midY)
            .scaledBy(x: bScale, y: bScale)
            .translatedBy(x: -box.midX, y: -box.midY)

        let scaledPath = original.copy(using: &transform) ?? original
        return Path(scaledPath)
    }
}

// A combined official logo
struct OfficialBitcoinLogo: View {
    var body: some View {
        ZStack {
            BitcoinCircleShape()
                .fill(Color.orange)
            BitcoinBShape()
                .fill(Color.white)
        }
        .frame(width: 120, height: 120)  // or whatever size
    }
}

// MARK: - 3D Spinner of the Official Logo
struct InteractiveBitcoinSymbol3DSpinner: View {
    @State private var rotationAngle = 0.0

    var body: some View {
        OfficialBitcoinLogo()
            .frame(width: 120, height: 120)
            .offset(y: 20)
            .rotation3DEffect(
                .degrees(rotationAngle),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 12)
                        .repeatForever(autoreverses: false)
                ) {
                    rotationAngle = 360
                }
            }
    }
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

    // For multi-tip fade in/out
    @State private var currentTip: String = ""
    @State private var showTip: Bool = false
    @State private var tipsIndex: Int = 0
    @State private var tipTimer: Timer? = nil

    let loadingTips = [
        "Gathering historical data from CSV files...",
        "Running thousands of random draws...",
        "Applying real BTC & S&P returns to the simulator...",
        "If it’s taking too long, reduce the number of iterations...",
        "Calculating weekly bear market triggers and penalties...",
        // etc...
    ]

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

    @State private var hideScrollIndicators = true
    @State private var lastScrollTime = Date()

    var body: some View {
        ZStack {
            Color(white: 0.12).ignoresSafeArea()

            VStack(spacing: 10) {
                if !isSimulationRun {
                    // Push the form down a bit for easier reach
                    Spacer().frame(height: 80)

                    // --- MODERN FORM LAYOUT ---
                    Form {
                        Section(
                            header: Text("SIMULATION PARAMETERS")
                                .foregroundColor(.white)
                        ) {
                            // Iterations row
                            HStack {
                                Text("Iterations")
                                    .foregroundColor(.white)
                                TextField("1000", text: $inputManager.iterations)
                                    .keyboardType(.numberPad)
                                    .foregroundColor(.white)
                            }
                            
                            // Annual CAGR row
                            HStack {
                                Text("Annual CAGR (%)")
                                    .foregroundColor(.white)
                                TextField("40.0", text: $inputManager.annualCAGR)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                            }

                            // Volatility row
                            HStack {
                                Text("Annual Volatility (%)")
                                    .foregroundColor(.white)
                                TextField("80.0", text: $inputManager.annualVolatility)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color(white: 0.15))
                        
                        Section {
                            Button(action: {
                                if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                                    currentPage = usdIndex
                                }
                                runSimulation()
                            }) {
                                Text("Run Simulation")
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color.blue)
                            
                            Button("Reset Saved Data") {
                                UserDefaults.standard.removeObject(forKey: "lastViewedWeek")
                                UserDefaults.standard.removeObject(forKey: "lastViewedPage")
                                lastViewedWeek = 0
                                lastViewedPage = 0
                                print("DEBUG: Reset user defaults and state.")
                            }
                            .foregroundColor(.red)
                            .listRowBackground(Color(white: 0.15))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(white: 0.12))
                    .listStyle(GroupedListStyle())
                    // --- END OF FORM LAYOUT ---
                } else {
                    // RESULTS
                    ScrollViewReader { scrollProxy in
                        ZStack {
                            VStack {
                                Spacer().frame(height: 40)
                                VStack(spacing: 0) {
                                    // Header
                                    HStack(spacing: 0) {
                                        Text("Week")
                                            .frame(width: 60, alignment: .leading)
                                            .font(.headline)
                                            .padding(.leading, 50)
                                            .padding(.vertical, 8)
                                            .background(Color.black)
                                            .foregroundColor(.white)

                                        ZStack {
                                            Text(columns[currentPage].0)
                                                .font(.headline)
                                                .padding(.leading, 100)
                                                .padding(.vertical, 8)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                                .frame(maxWidth: .infinity, alignment: .leading)

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

                                    // Scroll area
                                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                                        HStack(spacing: 0) {
                                            // Weeks column
                                            VStack(spacing: 0) {
                                                ForEach(monteCarloResults.indices, id: \.self) { index in
                                                    let result = monteCarloResults[index]
                                                    let rowBackground = index.isMultiple(of: 2)
                                                        ? Color(white: 0.10)
                                                        : Color(white: 0.14)

                                                    Text("\(result.week)")
                                                        .frame(width: 70, alignment: .leading)
                                                        .padding(.leading, 50)
                                                        .padding(.vertical, 12)
                                                        .padding(.horizontal, 8)
                                                        .background(rowBackground)
                                                        .foregroundColor(.white)
                                                        .id("week-\(result.week)")
                                                        .background(RowOffsetReporter(week: result.week))
                                                }
                                            }

                                            // TabView of columns
                                            TabView(selection: $currentPage) {
                                                ForEach(0..<columns.count, id: \.self) { index in
                                                    ZStack {
                                                        VStack(spacing: 0) {
                                                            ForEach(monteCarloResults.indices, id: \.self) { rowIndex in
                                                                let rowResult = monteCarloResults[rowIndex]
                                                                let rowBackground = rowIndex.isMultiple(of: 2)
                                                                    ? Color(white: 0.10)
                                                                    : Color(white: 0.14)

                                                                Text(getValue(rowResult, columns[index].1))
                                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                                    .padding(.leading, 80)
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
                                            let filtered = offsets.filter { (week, _) in week != 1040 }
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
                                    .onReceive(
                                        Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
                                    ) { _ in
                                        if Date().timeIntervalSince(lastScrollTime) > 1.5 {
                                            hideScrollIndicators = true
                                        }
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

                            // Back button
                            VStack {
                                HStack {
                                    Button(action: {
                                        UserDefaults.standard.set(lastViewedWeek, forKey: "lastViewedWeek")
                                        UserDefaults.standard.set(currentPage, forKey: "lastViewedPage")
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

                            // Scroll-to-bottom
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

            // Forward button
            if !isSimulationRun && !monteCarloResults.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            isSimulationRun = true
                            currentPage = lastViewedPage
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if let scrollProxy = contentScrollProxy {
                                    let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
                                    if savedWeek != 0 {
                                        lastViewedWeek = savedWeek
                                    }
                                    if let target = monteCarloResults.first(where: { $0.week == lastViewedWeek }) {
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

            // Loading overlay
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 30) {
                        InteractiveBitcoinSymbol3DSpinner()
                        VStack {
                            if showTip {
                                Text(currentTip)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .frame(maxWidth: 300)
                                    .transition(.opacity)
                            }
                        }
                        .frame(height: 80)
                    }
                    .offset(y: 220)
                }
                .onAppear {
                    startTipCycle()
                }
                .onDisappear {
                    stopTipCycle()
                }
            }
        }
        .onAppear {
            let savedWeek = UserDefaults.standard.integer(forKey: "lastViewedWeek")
            if savedWeek != 0 {
                lastViewedWeek = savedWeek
            }

            let savedPage = UserDefaults.standard.integer(forKey: "lastViewedPage")
            if savedPage < columns.count {
                lastViewedPage = savedPage
                currentPage = savedPage
            } else if let usdIndex = columns.firstIndex(where: { $0.0 == "BTC Price USD" }) {
                currentPage = usdIndex
                lastViewedPage = usdIndex
            }

            if monteCarloResults.isEmpty {
                isSimulationRun = false
            } else {
                isSimulationRun = true
            }
        }
    }

    // The custom spinner you had before, if you still need it for the loading overlay
    struct InteractiveBitcoinSymbol3DSpinner: View {
        @State private var angle: Double = 0
        @State private var spinRate: Double = 30.0
        @State private var lastUpdate = Date()
        @State private var flipAngleX: Double = 0
        @State private var flipAngleZ: Double = 0
        private let defaultSpinRate: Double = 30.0
        
        var body: some View {
            OfficialBitcoinLogo()
                .frame(width: 120, height: 120)
                .offset(y: 20)
                .rotation3DEffect(.degrees(angle),
                                  axis: (x: 0, y: 1, z: 0),
                                  anchor: .center)
                .rotation3DEffect(.degrees(flipAngleX), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(flipAngleZ), axis: (x: 0, y: 0, z: 1))
                .gesture(dragGesture())
                .onAppear {
                    lastUpdate = Date()
                    Timer.scheduledTimer(withTimeInterval: 1.0/60, repeats: true) { _ in
                        let now = Date()
                        let dt = now.timeIntervalSince(lastUpdate)
                        lastUpdate = now
                        angle += spinRate * dt
                    }
                }
        }
        
        private func dragGesture() -> some Gesture {
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    
                    if abs(dx) > abs(dy) {
                        if dx > 0 {
                            speedUpTemporarily()
                        } else {
                            slowDownTemporarily()
                        }
                    } else {
                        if dy < 0 {
                            flipXLogo()
                        } else {
                            flipZLogo()
                        }
                    }
                }
        }
        
        private func speedUpTemporarily() {
            withAnimation(.easeInOut(duration: 0.3)) {
                spinRate = 100
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 1)) {
                    spinRate = defaultSpinRate
                }
            }
        }
        
        private func slowDownTemporarily() {
            withAnimation(.easeInOut(duration: 0.3)) {
                spinRate = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 1)) {
                    spinRate = defaultSpinRate
                }
            }
        }
        
        private func flipXLogo() {
            let flipAnimation = Animation.easeInOut(duration: 0.6)
            withAnimation(flipAnimation) {
                flipAngleX += 180
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(flipAnimation) {
                    flipAngleX -= 180
                }
            }
        }
        
        private func flipZLogo() {
            let flipAnimation = Animation.easeInOut(duration: 0.6)
            withAnimation(flipAnimation) {
                flipAngleZ += 180
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(flipAnimation) {
                    flipAngleZ -= 180
                }
            }
        }
    }

    // MARK: - Simulation
    private func runSimulation() {
        isLoading = true
        monteCarloResults = []

        DispatchQueue.global(qos: .userInitiated).async {
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(self.inputManager.annualVolatility) ?? 1.0) / 100.0

            guard let totalIterations = self.inputManager.getParsedIterations(), totalIterations > 0 else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            // Dummy logic
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

                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allIterations)
                }
            }
        }
    }

    private func processAllResults(_ allResults: [[SimulationData]]) {
        let portfolioValues = allResults.flatMap { $0.map { $0.portfolioValueEUR } }
        // do something with it...
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

    // MARK: - Tip Cycling
    private func startTipCycle() {
        showTip = false
        tipTimer?.invalidate()
        tipTimer = nil

        // Show first tip after 5s
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            currentTip = loadingTips[tipsIndex]
            withAnimation(.easeInOut(duration: 2)) {
                showTip = true
            }
        }

        // Cycle tips every 25s
        tipTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 2)) {
                showTip = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                currentTip = loadingTips.randomElement() ?? ""
                withAnimation(.easeInOut(duration: 2)) {
                    showTip = true
                }
            }
        }
    }

    private func stopTipCycle() {
        tipTimer?.invalidate()
        tipTimer = nil
        showTip = false
    }
}
