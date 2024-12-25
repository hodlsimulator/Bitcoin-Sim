//
//  ContentView.swift
//  BTCMonteCarlo
//
//  Created by ... on 20/11/2024.
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

// MARK: - OfficialBitcoinLogo3DSpinner
//
// Renders the orange circle + tilted white “B,” then spins around the Y-axis.
struct OfficialBitcoinLogo3DSpinner: View {
    @State private var rotation: Double = 0.0

    var body: some View {
        OfficialBitcoinLogoShape()
            .rotation3DEffect(
                .degrees(rotation),
                axis: (x: 0, y: 1, z: 0),  // coin-flip around vertical axis
                anchor: .center
            )
            .frame(width: 150, height: 150) // or whatever size you like
            .onAppear {
                withAnimation(
                    .linear(duration: 6)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - OfficialBitcoinLogoShape
//
// Draws an orange circle with a white “B” in it, tilted ~14°.
// The entire shape is built in a 1000×1000 coordinate space, then SwiftUI scales it.
// The “B” is subpath inside the circle, using even-odd fill so the orange shows behind it.
struct OfficialBitcoinLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        // We'll define everything in a 1000×1000 coordinate space,
        // then scale to the actual 'rect' at render time.

        // STEP 1) We create a Path in that 1000×1000 space.
        let scale = min(rect.width, rect.height) / 1000
        let xOffset = (rect.width - 1000 * scale) / 2
        let yOffset = (rect.height - 1000 * scale) / 2

        var path = Path()

        // Helper to scale points from 1000-space to SwiftUI rect.
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: xOffset + x * scale, y: yOffset + y * scale)
        }

        // The circle is easy: center = (500, 500), radius = 500
        // We'll draw it as one big shape (the orange),
        // but we'll also add the white "B" as a subpath that “cuts out” via even-odd fill.

        // 1) ORANGE CIRCLE
        path.addEllipse(in: CGRect(
            x: pt(0, 0).x,
            y: pt(0, 0).y,
            width: 1000 * scale,
            height: 1000 * scale
        ))

        // 2) WHITE “B” SUBPATH
        //
        // Official brand tilt is about -14°, so we'll define the “B” upright at a
        // local coordinate system, then rotate it around (500, 500).
        // We'll do a manual rotation transform on the subpath points.

        let tiltAngle = -14.0 * .pi / 180.0 // in radians
        let sinA = sin(tiltAngle)
        let cosA = cos(tiltAngle)

        // A function to rotate a point (x,y) around center (500,500) by tiltAngle
        func rotate(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            // Translate so center is at (0,0)
            let dx = x - 500
            let dy = y - 500
            // Rotate
            let rx = dx * cosA - dy * sinA
            let ry = dx * sinA + dy * cosA
            // Translate back
            return CGPoint(x: 500 + rx, y: 500 + ry)
        }

        // The “B” geometry is roughly:
        // - bounding box: x: 320..680, y: 200..800 (centered in circle).
        // - We'll define arcs & bars to replicate the official shape.

        // Spine positions, bars, etc. This is a more “official” layout gleaned from references.
        // Tweak if you see misalignment:
        let leftX: CGFloat   = 320
        let rightX: CGFloat  = 680
        let topY: CGFloat    = 200
        let bottomY: CGFloat = 800
        let bar1Y: CGFloat   = 380
        let bar2Y: CGFloat   = 620

        // Spine thickness
        let spineX: CGFloat  = 420
        let spineW: CGFloat  = 60

        // We'll define arcs for top, mid, bottom lumps.
        // The “B” in official brand guidelines has slight differences, but let's approximate:
        let arcTopCtrlY: CGFloat = (topY + bar1Y) * 0.5 - 20
        let arcMidCtrlY: CGFloat = (bar1Y + bar2Y) * 0.5
        let arcBotCtrlY: CGFloat = (bar2Y + bottomY) * 0.5 + 20

        // We'll build subpaths for each “lump” in the B, then rotate them.

        // Build an array of line/arc segments, then apply rotation to each point.
        // Finally, we'll add them to `path` with .move(to:), .addLine(to:), .addQuadCurve(...).
        var bSubpaths: [Path] = []

        // 2A) Vertical spine
        do {
            var p = Path()
            p.move(to: rotate(spineX, topY))
            p.addLine(to: rotate(spineX, bottomY))
            p.addLine(to: rotate(spineX + spineW, bottomY))
            p.addLine(to: rotate(spineX + spineW, topY))
            p.closeSubpath()
            bSubpaths.append(p)
        }

        // 2B) Top lump
        do {
            var p = Path()
            p.move(to: rotate(spineX + spineW, topY))
            p.addQuadCurve(
                to: rotate(spineX + spineW, bar1Y),
                control: rotate(rightX, arcTopCtrlY)
            )
            p.closeSubpath()
            bSubpaths.append(p)
        }

        // 2C) Middle lump
        do {
            var p = Path()
            p.move(to: rotate(spineX + spineW, bar1Y))
            p.addQuadCurve(
                to: rotate(spineX + spineW, bar2Y),
                control: rotate(rightX, arcMidCtrlY)
            )
            p.closeSubpath()
            bSubpaths.append(p)
        }

        // 2D) Bottom lump
        do {
            var p = Path()
            p.move(to: rotate(spineX + spineW, bar2Y))
            p.addQuadCurve(
                to: rotate(spineX + spineW, bottomY),
                control: rotate(rightX, arcBotCtrlY)
            )
            p.closeSubpath()
            bSubpaths.append(p)
        }

        // 2E) The horizontal “double bar” chunks (the short lines crossing the spine).
        // Official brand has them near bar1Y & bar2Y.
        let barThickness: CGFloat = 20
        let barIndent: CGFloat    = 60
        // top bar
        do {
            var p = Path()
            p.move(to: rotate(spineX - barIndent, bar1Y - barThickness / 2))
            p.addLine(to: rotate(spineX - barIndent, bar1Y + barThickness / 2))
            p.addLine(to: rotate(spineX + spineW * 0.8, bar1Y + barThickness / 2))
            p.addLine(to: rotate(spineX + spineW * 0.8, bar1Y - barThickness / 2))
            p.closeSubpath()
            bSubpaths.append(p)
        }
        // bottom bar
        do {
            var p = Path()
            p.move(to: rotate(spineX - barIndent, bar2Y - barThickness / 2))
            p.addLine(to: rotate(spineX - barIndent, bar2Y + barThickness / 2))
            p.addLine(to: rotate(spineX + spineW * 0.8, bar2Y + barThickness / 2))
            p.addLine(to: rotate(spineX + spineW * 0.8, bar2Y - barThickness / 2))
            p.closeSubpath()
            bSubpaths.append(p)
        }

        // Now we add all subpaths (the “B” lumps, spine, bars) to the main path using .addPath(...).
        // We’ll do so in “even-odd” fill style, meaning the white B will “cut out” from the orange circle.
        for subP in bSubpaths {
            path.addPath(subP)
        }

        // By default, SwiftUI uses “non-zero winding” for fill. We want “even-odd” so the B is a hole in the circle.
        // We can set that at render time, or we can combine them. Here, we just rely on SwiftUI's .fill(style:eoFill:).
        return path
    }
    
    // We want to fill with .orange for the circle, and .white for the “B.”
    // But we can do it by returning the same path for both layers (circle + B),
    // and fill it with .eoFill style. Then in the final view, we do:
    // .fill( evenOddFillOfOrangeAndWhite ) - but that's more complex in SwiftUI.
    //
    // Easiest approach: We'll do a specialized “View” below that just uses this shape
    // twice with different fill styles. But let's keep it simpler:
}

// MARK: - OfficialBitcoinLogoView
//
// One approach is to overlay two fills: an orange fill with normal mode, plus a white fill using .eoFill.
// But simpler is: We can fill the entire shape with orange, THEN re-draw the shape in white with .eoFill
// so it “carves out” the B. We'll build that into a single SwiftUI view:

struct OfficialBitcoinLogoView: View {
    var body: some View {
        ZStack {
            OfficialBitcoinLogoShape()
                .fill(Color(hex: "#F7931A")) // brand orange
            OfficialBitcoinLogoShape()
                .fill(Color.white, style: FillStyle(eoFill: true))
        }
        .frame(width: 200, height: 200)
    }
}

// Then apply the 3D rotation if we want the coin-flip look:
struct OfficialBitcoinLogo3DView: View {
    @State private var rotation: Double = 0.0

    var body: some View {
        ZStack {
            OfficialBitcoinLogoView()
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center
        )
        .onAppear {
            withAnimation(
                .linear(duration: 6)
                    .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }
}

// MARK: - Optional: Color(hex:) extension
// If you want #F7931A as "BitcoinOrange," you can do:
extension Color {
    init(hex: String) {
        let noHash = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var hexInt: UInt64 = 0
        Scanner(string: noHash).scanHexInt64(&hexInt)
        
        let r, g, b: Double
        if noHash.count == 6 {
            r = Double((hexInt & 0xFF0000) >> 16) / 255
            g = Double((hexInt & 0x00FF00) >> 8) / 255
            b = Double(hexInt & 0x0000FF) / 255
            self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
        } else {
            // fallback
            self.init(.sRGB, red: 1, green: 0.5, blue: 0)
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

    // Double the original set of statements (30 total)
    let loadingTips = [
        "Gathering historical data from CSV files...",
        "Running thousands of random draws...",
        "Applying real BTC & S&P returns to the simulator...",
        "If it’s taking too long, reduce the number of iterations...",
        "Calculating weekly bear market triggers and penalties...",
        "Reading CSV files to load thousands of historical points...",
        "Computing correlated returns each iteration...",
        "Adding random shocks to simulate volatility...",
        "Compounding weekly growth from your annual CAGR...",
        "Tracking bear slumps when triggered...",
        "Applying negative penalties during bear markets...",
        "Merging results to generate a final median run...",
        "Sorting final portfolio values across all iterations...",
        "Checking normal distributions via Box-Muller transform...",
        "Ensuring CSV file names and content format match exactly...",
        "Verifying concurrency settings to speed up simulations...",
        "Evaluating historical outliers to test extreme volatility...",
        "Cross-checking S&P 500 correlation logic with real data...",
        "Testing different iteration sizes for performance tuning...",
        "Saving user inputs to maintain continuity between runs...",
        "Validating CSV columns match the parser's expectations...",
        "Trying new date-based offsets in weekly data segments...",
        "Analysing potential halving effects on future returns...",
        "Generating histograms for visual insight into final values...",
        "Auto-adjusting portfolio contributions under volatility...",
        "Comparing median results across multiple simulation sets...",
        "Simulating multi-year expansions and drawdowns in code...",
        "Ensuring no forced unwrapped options in file reads...",
        "Finalising user interface for smoother user experience...",
        "Storing final iteration logs in background threads..."
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

    // Scroll indicator states
    @State private var hideScrollIndicators = true
    @State private var lastScrollTime = Date()

    var body: some View {
        ZStack {
            // Entire background
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
                                    // HEADER
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

                                    // SCROLL AREA
                                    ScrollView(.vertical, showsIndicators: !hideScrollIndicators) {
                                        HStack(spacing: 0) {
                                            // WEEKS COLUMN
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

                                            // TABVIEW OF COLUMNS
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

                                                        // Invisible tap zones for left/right column navigation
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
                                                return Color(white: 0.12)
                                            }
                                        )
                                        // Detect scrolling: show indicators
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
                                    // Timer to hide scroll indicators after 1.5s
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

            // LOADING OVERLAY (Flower spinner + multi-tip fade)
            if isLoading {
                ZStack {
                    Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)

                    VStack(spacing: 30) {
                        // Use our new Bitcoin spinner here
                        OfficialBitcoinLogo3DSpinner()

                        // Reserve space for your tip text so the spinner won’t shift
                        VStack {
                            if showTip {
                                Text(currentTip)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .frame(maxWidth: 300, alignment: .center)
                                    .transition(.opacity)
                            }
                        }
                        .frame(height: 80)
                    }
                    .offset(y: 220)  // or your preferred vertical offset
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
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(self.inputManager.annualVolatility) ?? 1.0) / 100.0

            print("DEBUG: Using CAGR = \(userInputCAGR), Volatility = \(userInputVolatility)")

            guard let totalIterations = self.inputManager.getParsedIterations(), totalIterations > 0 else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Invalid number of iterations.")
                }
                return
            }

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

                print("Simulation complete (Median). Final BTC Price (USD): \(medianRun.last?.btcPriceUSD ?? 0.0)")

                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allIterations)
                    self.generateHistogramForResults(
                        results: medianRun,
                        filePath: "/Users/Desktop/portfolio_growth_histogram.png"
                    )
                }
            }
        }
    }

    private func processAllResults(_ allResults: [[SimulationData]]) {
        let portfolioValues = allResults.flatMap { $0.map { $0.portfolioValueEUR } }
        createHistogramWithLogBins(
            data: portfolioValues,
            title: "Portfolio Growth",
            fileName: "/Users/Desktop/portfolio_growth_histogram.png"
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

    func randomNormal(mean: Double = 0, standardDeviation: Double = 1) -> Double {
        let u1 = Double.random(in: 0..<1)
        let u2 = Double.random(in: 0..<1)
        let z0 = sqrt(-2.0 * log(u1)) * cos(2 * .pi * u2)
        return z0 * standardDeviation + mean
    }

    // MARK: - Tip Cycling (calming fade with a longer gap)
    private func startTipCycle() {
        showTip = false
        tipTimer?.invalidate()
        tipTimer = nil

        // Wait 5 seconds before showing the first tip (fade in over 2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            currentTip = loadingTips[tipsIndex]
            withAnimation(.easeInOut(duration: 2)) {
                showTip = true
            }
        }

        // Each cycle is 25 seconds:
        // - 10 seconds displayed
        // - 2 seconds fade out
        // - 5 seconds gap
        // - 2 seconds fade in
        // (adjust as needed, but total ~25)
        tipTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { _ in
            // Fade out over 2s
            withAnimation(.easeInOut(duration: 2)) {
                showTip = false
            }
            // After fade out completes, wait 5 more seconds, then fade in next tip
            DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                tipsIndex = (tipsIndex + 1) % loadingTips.count
                currentTip = loadingTips[tipsIndex]
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
