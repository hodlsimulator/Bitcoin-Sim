//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI
import Charts
import Combine
import Foundation
import UIKit

// MARK: - Data Models

struct WeekPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Decimal
}

struct SimulationRun: Identifiable {
    let id = UUID()
    let points: [WeekPoint]
}

// MARK: - SquishedLandscapePlaceholderView

struct SquishedLandscapePlaceholderView: View {
    let image: UIImage
    
    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = 1.25
            let scaleY: CGFloat = 1.10
            
            let newWidth = geo.size.width * scaleX
            let newHeight = geo.size.height * scaleY
            let xOffset = (geo.size.width - newWidth) / 2
            
            Image(uiImage: image)
                .resizable()
                .frame(width: newWidth, height: newHeight, alignment: .top)
                .offset(x: xOffset, y: 0)
        }
        .ignoresSafeArea()
    }
}

// MARK: - SnapshotView

struct SnapshotView: View {
    let snapshot: UIImage
    
    var body: some View {
        Image(uiImage: snapshot)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .padding(.bottom, 90)
            .ignoresSafeArea(edges: .top)
    }
}

// MARK: - squishPortraitImage

func squishPortraitImage(_ portraitImage: UIImage) -> UIImage {
    let targetSize = CGSize(width: 800, height: 400)
    let scaleFactorX: CGFloat = 1.25
    let scaleFactorY: CGFloat = 1.05
    
    let scaledWidth = targetSize.width * scaleFactorX
    let scaledHeight = targetSize.height * scaleFactorY
    let xOffset = (targetSize.width - scaledWidth) / 2
    let yOffset: CGFloat = 0
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        portraitImage.draw(
            in: CGRect(
                x: xOffset,
                y: yOffset,
                width: scaledWidth,
                height: scaledHeight
            )
        )
    }
}

// MARK: - Number Formatting

private let thousand          = Decimal(string: "1e3")!
private let million           = Decimal(string: "1e6")!
private let billion           = Decimal(string: "1e9")!
private let trillion          = Decimal(string: "1e12")!
private let quadrillion       = Decimal(string: "1e15")!
private let quintillion       = Decimal(string: "1e18")!
private let sextillion        = Decimal(string: "1e21")!
private let septillion        = Decimal(string: "1e24")!
private let octillion         = Decimal(string: "1e27")!
private let nonillion         = Decimal(string: "1e30")!
private let decillion         = Decimal(string: "1e33")!
private let undecillion       = Decimal(string: "1e36")!
private let duodecillion      = Decimal(string: "1e39")!
private let tredecillion      = Decimal(string: "1e42")!
private let quattuordecillion = Decimal(string: "1e45")!

func formatSuffix(_ value: Decimal) -> String {
    func wholeNumber(_ x: Decimal) -> Int {
        let rounded = NSDecimalNumber(decimal: x).rounding(accordingToBehavior: nil)
        return rounded.intValue
    }
    
    switch value {
    case _ where value >= quattuordecillion:
        return "\(wholeNumber(value / quattuordecillion))Qd"
    case _ where value >= tredecillion:
        return "\(wholeNumber(value / tredecillion))Td"
    case _ where value >= duodecillion:
        return "\(wholeNumber(value / duodecillion))Do"
    case _ where value >= undecillion:
        return "\(wholeNumber(value / undecillion))U"
    case _ where value >= decillion:
        return "\(wholeNumber(value / decillion))D"
    case _ where value >= nonillion:
        return "\(wholeNumber(value / nonillion))N"
    case _ where value >= octillion:
        return "\(wholeNumber(value / octillion))O"
    case _ where value >= septillion:
        return "\(wholeNumber(value / septillion))S"
    case _ where value >= sextillion:
        return "\(wholeNumber(value / sextillion))Se"
    case _ where value >= quintillion:
        return "\(wholeNumber(value / quintillion))Qn"
    case _ where value >= quadrillion:
        return "\(wholeNumber(value / quadrillion))Q"
    case _ where value >= trillion:
        return "\(wholeNumber(value / trillion))T"
    case _ where value >= billion:
        return "\(wholeNumber(value / billion))B"
    case _ where value >= million:
        return "\(wholeNumber(value / million))M"
    case _ where value >= thousand:
        return "\(wholeNumber(value / thousand))k"
    default:
        return "\(wholeNumber(value))"
    }
}

// MARK: - BTC Chart Subview

struct MonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    /// How far to shift the entire chart after squishing (up = negative)
    private let topOffset: CGFloat = 0
    
    /// Vertical "squish" factor (1.0 = no squish; e.g. 0.9 = 90% original height)
    private let scaleY: CGFloat = 0.92
    
    var body: some View {
        
        // 1) Domain logic
        let simulations = chartDataCache.allRuns ?? []
        let allValues = simulations.flatMap { $0.points.map(\.value) }
        
        let rawMin = allValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        let rawMax = allValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        // BOTTOM domain logic
        var bottomExp = floor(log10(rawMin))
        if rawMin <= pow(10, bottomExp), bottomExp > 0 {
            bottomExp -= 1
        }
        let domainMin = max(pow(10.0, bottomExp), 1.0)
        
        // TOP domain logic
        var topExp = floor(log10(rawMax))
        if rawMax >= pow(10, topExp) {
            topExp += 1
        }
        let domainMax = pow(10.0, topExp)
        
        // Y-axis ticks => powers of ten
        let intBottom = Int(bottomExp)
        let intTop    = Int(topExp)
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        // 2) X domain => interpret userPeriods in weeks/months
        let totalPeriods = Double(simSettings.userPeriods)
        let totalYears = (simSettings.periodUnit == .weeks)
            ? totalPeriods / 52.0
            : totalPeriods / 12.0
        
        // Helper to pick a 'nice' stride
        func dynamicXStride(for totalY: Double) -> Double {
            switch totalY {
            case ..<1.01:  return 0.25
            case ..<2.01:  return 0.5
            case ..<5.01:  return 1.0
            case ..<10.01: return 2.0
            case ..<25.01: return 5.0
            case ..<50.01: return 10.0
            default:       return 25.0
            }
        }
        
        let xStride = dynamicXStride(for: totalYears)
        
        // 3) Return the SwiftUI View
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Chart {
                        simulationLines(simulations: simulations, simSettings: simSettings)
                        medianLines(simulations: simulations, simSettings: simSettings)
                    }
                    // Important: DO NOT override .foregroundStyle here
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: domainMin...domainMax, type: .log)
                    .chartPlotStyle { plotArea in
                        plotArea
                            .padding(.top, 0)
                            .padding(.bottom, 20)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yTickValues) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let dblVal = axisValue.as(Double.self) {
                                    let exponent = Int(log10(dblVal))
                                    Text(formatPowerOfTenLabel(exponent))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: Array(stride(from: 0.0, through: totalYears, by: xStride))) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let dblVal = axisValue.as(Double.self), dblVal > 0 {
                                    if totalYears <= 2.0 {
                                        Text("\(Int(dblVal * 12))M")
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(Int(dblVal))Y")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .scaleEffect(x: 1.0, y: scaleY, anchor: .bottom)
                .offset(y: -topOffset)
            }
        }
        .navigationBarHidden(false)
    }
}

// MARK: - Chart content with per-run color (already included above)

// MARK: - Format suffix on log scale

func formatPowerOfTenLabel(_ exponent: Int) -> String {
    switch exponent {
    case 0:  return "1"
    case 1:  return "10"
    case 2:  return "100"
    case 3:  return "1K"
    case 4:  return "10K"
    case 5:  return "100K"
    case 6:  return "1M"
    case 7:  return "10M"
    case 8:  return "100M"
    case 9:  return "1B"
    case 10: return "10B"
    case 11: return "100B"
    case 12: return "1T"
    case 13: return "10T"
    case 14: return "100T"
    case 15: return "1Q"   // quadrillion
    case 16: return "10Q"
    case 17: return "100Q"
    case 18: return "1Qn"  // quintillion
    case 19: return "10Qn"
    case 20: return "100Qn"
    case 21: return "1Se"  // sextillion
    default:
        return "10^\(exponent)"
    }
}

// MARK: - Main Results View

struct MonteCarloResultsView: View {
    @EnvironmentObject var chartSelection: ChartSelection
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @StateObject private var orientationObserver = OrientationObserver()
    
    @State private var squishedLandscape: UIImage? = nil
    @State private var brandNewLandscapeSnapshot: UIImage? = nil
    @State private var isGeneratingLandscape = false
    
    // A custom top-drawer menu
    @State private var showChartMenu = false
    
    enum ChartType {
        case btcPrice
        case cumulativePortfolio
    }
    
    private var portraitSnapshot: UIImage? {
        switch chartSelection.selectedChart {
        case .btcPrice:
            return chartDataCache.chartSnapshot
        case .cumulativePortfolio:
            return chartDataCache.chartSnapshotPortfolio
        }
    }
    
    private var freshLandscapeSnapshot: UIImage? {
        switch chartSelection.selectedChart {
        case .btcPrice:
            return chartDataCache.chartSnapshotLandscape
        case .cumulativePortfolio:
            return chartDataCache.chartSnapshotPortfolioLandscape
        }
    }
    
    private var isLandscape: Bool {
        orientationObserver.isLandscape
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            
            contentView
            
            if isGeneratingLandscape {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView("Generating Landscape…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                        .foregroundColor(.white)
                }
            }
            
            if !isLandscape && showChartMenu {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showChartMenu = false
                        }
                    }
                    .zIndex(1)
                
                Button {
                    withAnimation {
                        if chartSelection.selectedChart == .cumulativePortfolio {
                            chartSelection.selectedChart = .btcPrice
                        } else {
                            chartSelection.selectedChart = .cumulativePortfolio
                        }
                        showChartMenu = false
                    }
                } label: {
                    Text(
                        chartSelection.selectedChart == .cumulativePortfolio
                        ? "BTC Price Chart"
                        : "Cumulative Portfolio"
                    )
                    .foregroundColor(.white)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.plain)
                .background(Color.black)
                .edgesIgnoringSafeArea(.horizontal)
                .padding(.top, 120)
                .transition(.move(edge: .top))
                .zIndex(2)
            }
        }
        .navigationTitle(
            isLandscape
            ? ""
            : (chartSelection.selectedChart == .btcPrice
               ? "Monte Carlo – BTC Price (USD)"
               : "Cumulative Portfolio Returns")
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(isLandscape)
        .toolbar {
            if !isLandscape {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation {
                            showChartMenu.toggle()
                        }
                    } label: {
                        Image(systemName: showChartMenu ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .onAppear {
            // If we start in landscape, create squished version + build snapshot
            if isLandscape, let portrait = portraitSnapshot {
                squishedLandscape = squishPortraitImage(portrait)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isGeneratingLandscape = true
                    buildTrueLandscapeSnapshot { newSnapshot in
                        switch chartSelection.selectedChart {
                        case .btcPrice:
                            chartDataCache.chartSnapshotLandscape = newSnapshot
                        case .cumulativePortfolio:
                            chartDataCache.chartSnapshotPortfolioLandscape = newSnapshot
                        }
                        brandNewLandscapeSnapshot = newSnapshot
                        isGeneratingLandscape = false
                    }
                }
            }
        }
        .onChange(of: isLandscape) { newVal in
            if newVal {
                // portrait->landscape
                if let portrait = portraitSnapshot {
                    DispatchQueue.main.async {
                        squishedLandscape = squishPortraitImage(portrait)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isGeneratingLandscape = true
                    buildTrueLandscapeSnapshot { newSnapshot in
                        switch chartSelection.selectedChart {
                        case .btcPrice:
                            chartDataCache.chartSnapshotLandscape = newSnapshot
                        case .cumulativePortfolio:
                            chartDataCache.chartSnapshotPortfolioLandscape = newSnapshot
                        }
                        brandNewLandscapeSnapshot = newSnapshot
                        isGeneratingLandscape = false
                    }
                }
            } else {
                // landscape->portrait
                squishedLandscape = nil
                brandNewLandscapeSnapshot = nil
                isGeneratingLandscape = false
            }
        }
    }
    
    // MARK: - Chart Content
    @ViewBuilder
    private var contentView: some View {
        if isLandscape {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                if let freshLandscape = freshLandscapeSnapshot {
                    Image(uiImage: freshLandscape)
                        .resizable()
                        .scaledToFit()
                    
                } else if let squished = squishedLandscape {
                    Image(uiImage: squished)
                        .resizable()
                        .scaledToFit()
                    
                } else if let portrait = portraitSnapshot {
                    SquishedLandscapePlaceholderView(image: portrait)
                    
                } else {
                    // If we haven't generated snapshots yet, show the chart
                    if chartSelection.selectedChart == .btcPrice {
                        MonteCarloChartView()
                            .environmentObject(orientationObserver)
                            .environmentObject(chartDataCache)
                            .environmentObject(simSettings)
                    } else {
                        PortfolioChartView()
                            .environmentObject(orientationObserver)
                            .environmentObject(chartDataCache)
                            .environmentObject(simSettings)
                    }
                }
            }
        } else {
            // PORTRAIT
            if chartSelection.selectedChart == .btcPrice {
                if let btcSnapshot = chartDataCache.chartSnapshot {
                    SnapshotView(snapshot: btcSnapshot)
                } else {
                    MonteCarloChartView()
                        .environmentObject(orientationObserver)
                        .environmentObject(chartDataCache)
                        .environmentObject(simSettings)
                }
            } else {
                if let portfolioSnapshot = chartDataCache.chartSnapshotPortfolio {
                    SnapshotView(snapshot: portfolioSnapshot)
                } else {
                    PortfolioChartView()
                        .environmentObject(orientationObserver)
                        .environmentObject(chartDataCache)
                        .environmentObject(simSettings)
                }
            }
        }
    }
    
    // MARK: - Build Landscape Snapshots
    private func buildTrueLandscapeSnapshot(completion: @escaping (UIImage) -> Void) {
        // Multiply by UIScreen scale so it’s not rendered tiny on high-res
        let scale = UIScreen.main.scale
        let w = 800.0 * scale
        let h = 400.0 * scale
        
        let wideChart: AnyView
        switch chartSelection.selectedChart {
        case .btcPrice:
            wideChart = AnyView(
                MonteCarloChartView()
                    .environmentObject(orientationObserver)
                    .environmentObject(chartDataCache)
                    .environmentObject(simSettings)
                    .frame(width: w, height: h)
                    .background(Color.black)
            )
        case .cumulativePortfolio:
            wideChart = AnyView(
                PortfolioChartView()
                    .environmentObject(orientationObserver)
                    .environmentObject(chartDataCache)
                    .environmentObject(simSettings)
                    .frame(width: w, height: h)
                    .background(Color.black)
            )
        }
        
        completion(wideChart.snapshot())
    }
}

// MARK: - ForceReflowView

struct ForceReflowView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    @State private var orientationID = UUID()

    var body: some View {
        content
            .id(orientationID)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                orientationID = UUID()
            }
    }
}
