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
            .transition(.move(edge: .bottom))
            .animation(.easeInOut(duration: 0.5), value: snapshot)
    }
}

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

func computeMedianLine(_ simulations: [SimulationRun]) -> [WeekPoint] {
    guard let firstRun = simulations.first else { return [] }
    let countPerRun = firstRun.points.count
    
    var medianPoints: [WeekPoint] = []
    
    for index in 0..<countPerRun {
        let allValues = simulations.compactMap { run -> Decimal? in
            guard index < run.points.count else { return nil }
            return run.points[index].value
        }
        if allValues.isEmpty { continue }
        
        let sortedVals = allValues.sorted(by: <)
        let mid = sortedVals.count / 2
        let median: Decimal
        if sortedVals.count.isMultiple(of: 2) {
            let sum = sortedVals[mid] + sortedVals[mid - 1]
            median = sum / Decimal(2)
        } else {
            median = sortedVals[mid]
        }
        
        let week = firstRun.points[index].week
        medianPoints.append(WeekPoint(week: week, value: median))
    }
    return medianPoints
}

// MARK: - BTC Chart Subview

struct MonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    /// How far to shift the entire chart after squishing (up = negative)
    private let topOffset: CGFloat = 0
    
    /// Vertical “squish” factor (1.0 = no squish; e.g. 0.9 = 90% original height)
    private let scaleY: CGFloat = 0.92
    
    var body: some View {
        
        // 1) Do domain logic outside the ViewBuilder
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
        
        // Y ticks
        let intBottom = Int(bottomExp)
        let intTop    = Int(topExp)
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        // X domain => weeks->years
        let totalWeeks = Double(simSettings.userWeeks)
        let totalYears = totalWeeks / 52.0
        let xStride = (totalYears == 0.0) ? 1.0 : (totalYears / 4.0)
        
        // 2) Return the SwiftUI View
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Chart {
                        simulationLines(simulations: simulations)
                        medianLines(simulations: simulations)
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: domainMin...domainMax, type: .log)
                    
                    .chartPlotStyle { plotArea in
                        // bottom padding so data doesn’t overlap x-axis
                        plotArea
                            .padding(.top, 0)
                            .padding(.bottom, 20)
                    }
                    
                    // Y-axis => powers of ten
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
                    
                    // X-axis => ~4 ticks
                    .chartXAxis {
                        AxisMarks(values: Array(stride(from: 0.0, through: totalYears, by: xStride))) { axisValue in
                            AxisGridLine(centered: false)
                                .foregroundStyle(.white.opacity(0.3))
                            AxisTick(centered: false)
                                .foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel(centered: false) {
                                if let dblVal = axisValue.as(Double.self) {
                                    Text("\(Int(dblVal))")
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                // Squish vertically from the bottom
                .scaleEffect(x: 1.0, y: scaleY, anchor: .bottom)
                // Additional offset if you want to push it up or down more
                .offset(y: -topOffset)
            }
        }
        .navigationBarHidden(false)
    }
}
    
    // MARK: - Format suffix on log scale
    /// Convert an integer exponent to its short suffix label (1, 10, 100, 1k, …, 1Q, etc.).
    /// Covers up to 1e48 = quattuordecillion in your list.
    func formatPowerOfTenExponent(_ exponent: Int) -> String {
        switch exponent {
        case 0:  return "1"
        case 1:  return "10"
        case 2:  return "100"
        case 3:  return "1k"         // 1×10^3
        case 4:  return "10k"        // 1×10^4
        case 5:  return "100k"       // 1×10^5
        case 6:  return "1M"         // 1×10^6
        case 7:  return "10M"        // 1×10^7
        case 8:  return "100M"       // 1×10^8
        case 9:  return "1B"         // 1×10^9
        case 10: return "10B"
        case 11: return "100B"
        case 12: return "1T"         // 1×10^12 (trillion)
        case 13: return "10T"
        case 14: return "100T"
        case 15: return "1Q"         // 1×10^15 (quadrillion)
        case 16: return "10Q"
        case 17: return "100Q"
        case 18: return "1Qn"        // 1×10^18 (quintillion)
        case 19: return "10Qn"
        case 20: return "100Qn"
        case 21: return "1Se"        // 1×10^21 (sextillion)
        case 22: return "10Se"
        case 23: return "100Se"
        case 24: return "1S"         // 1×10^24 (septillion)
        case 25: return "10S"
        case 26: return "100S"
        case 27: return "1O"         // 1×10^27 (octillion)
        case 28: return "10O"
        case 29: return "100O"
        case 30: return "1N"         // 1×10^30 (nonillion)
        case 31: return "10N"
        case 32: return "100N"
        case 33: return "1D"         // 1×10^33 (decillion)
        case 34: return "10D"
        case 35: return "100D"
        case 36: return "1U"         // 1×10^36 (undecillion)
        case 37: return "10U"
        case 38: return "100U"
        case 39: return "1Do"        // 1×10^39 (duodecillion)
        case 40: return "10Do"
        case 41: return "100Do"
        case 42: return "1Td"        // 1×10^42 (tredecillion)
        case 43: return "10Td"
        case 44: return "100Td"
        case 45: return "1Qd"        // 1×10^45 (quattuordecillion)
        case 46: return "10Qd"
        case 47: return "100Qd"
        case 48: return "1…"         // You can extend further if needed
        default:
            // If beyond your known range, fallback:
            return "10^\(exponent)"
        }
    }

/// For exponents like 0->"1", 1->"10", 2->"100", 3->"1K", 4->"10K", 5->"100K", etc.
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
    // ...and so forth, or fallback:
    default:
        return "10^\(exponent)"
    }
}

// MARK: - Main Results View

struct MonteCarloResultsView: View {
    @EnvironmentObject var chartSelection: ChartSelection
    @EnvironmentObject var chartDataCache: ChartDataCache
    @StateObject private var orientationObserver = OrientationObserver()
    
    @State private var squishedLandscape: UIImage? = nil
    @State private var brandNewLandscapeSnapshot: UIImage? = nil
    @State private var isGeneratingLandscape = false
    
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
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLandscape {
                // LANDSCAPE
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
                        // No snapshots -> show the actual Swift Charts
                        if chartSelection.selectedChart == .btcPrice {
                            MonteCarloChartView()
                                .environmentObject(orientationObserver)
                                .environmentObject(chartDataCache)
                        } else {
                            PortfolioChartView()
                                .environmentObject(orientationObserver)
                                .environmentObject(chartDataCache)
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
                    }
                } else {
                    if let portfolioSnapshot = chartDataCache.chartSnapshotPortfolio {
                        SnapshotView(snapshot: portfolioSnapshot)
                    } else {
                        PortfolioChartView()
                            .environmentObject(orientationObserver)
                            .environmentObject(chartDataCache)
                    }
                }
                
                // Show chart menu in portrait
                if showChartMenu {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 130)
                        
                        VStack(spacing: 0) {
                            Button {
                                print("// DEBUG: User selected BTC price chart from chart menu.")
                                chartSelection.selectedChart = .btcPrice
                                showChartMenu = false
                            } label: {
                                Text("BTC Price Chart")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color.black)
                            
                            Button {
                                print("// DEBUG: User selected Portfolio chart from chart menu.")
                                chartSelection.selectedChart = .cumulativePortfolio
                                showChartMenu = false
                            } label: {
                                Text("Cumulative Portfolio")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(Color.black)
                        }
                        .frame(maxWidth: 240)
                        
                        Spacer()
                    }
                    .transition(.opacity)
                    .zIndex(3)
                }
            }
            
            // Spinner if generating
            if isGeneratingLandscape {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView("Generating Landscape…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                        .foregroundColor(.white)
                }
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
            // If we’re already in landscape, produce a "squished" version
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
                // Just switched to landscape
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
                // Just switched back to portrait
                squishedLandscape = nil
                brandNewLandscapeSnapshot = nil
                isGeneratingLandscape = false
            }
        }
    }
    
    private func buildTrueLandscapeSnapshot(completion: @escaping (UIImage) -> Void) {
        let wideChart: AnyView
        switch chartSelection.selectedChart {
        case .btcPrice:
            wideChart = AnyView(
                MonteCarloChartView()
                    .environmentObject(orientationObserver)
                    .environmentObject(chartDataCache)
                    .frame(width: 800, height: 400)
                    .background(Color.black)
            )
        case .cumulativePortfolio:
            wideChart = AnyView(
                PortfolioChartView()
                    .environmentObject(orientationObserver)
                    .environmentObject(chartDataCache)
                    .frame(width: 800, height: 400)
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
    
