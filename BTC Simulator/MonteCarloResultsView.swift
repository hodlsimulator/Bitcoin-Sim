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
    
    var body: some View {
        let isLandscape = orientationObserver.isLandscape
        
        // We'll read from chartDataCache.allRuns
        let simulations = chartDataCache.allRuns ?? []
        
        if !simulations.isEmpty {
            let firstRun = simulations[0].points
            if !firstRun.isEmpty {
                print("// DEBUG: ADDED PRINT => first BTC run sample => week=\(firstRun[0].week), val=\(firstRun[0].value)")
            }
        }
        
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLandscape {
                    // LANDSCAPE layout
                    ZStack {
                        Chart {
                            simulationLines(simulations: simulations)
                            medianLines(simulations: simulations)
                        }
                        .chartLegend(.hidden)
                        .chartXScale(domain: 0.0...20.0, type: .linear)
                        .chartYScale(domain: .automatic(includesZero: false), type: .log)
                        
                        // X-axis
                        .chartXAxis {
                            let yearMarkers = [5.0, 10.0, 15.0, 20.0]
                            AxisMarks(values: yearMarkers) { axisValue in
                                AxisGridLine(centered: false)
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisTick(centered: false)
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel(centered: false) {
                                    if let yearVal = axisValue.as(Double.self) {
                                        Text("\(Int(yearVal))")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        // Y-axis on the left with abbreviations
                        .chartYAxis {
                            AxisMarks(position: .leading) { axisValue in
                                AxisGridLine()
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisTick()
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel {
                                    if let doubleVal = axisValue.as(Double.self) {
                                        let decimalVal = Decimal(doubleVal)
                                        Text(formatSuffix(decimalVal))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        // Make the chart a bit wider
                        .frame(width: geo.size.width * 1.1, height: geo.size.height)
                        .offset(x: -(geo.size.width * 0.04))
                        .scaleEffect(x: 1.0, y: 0.98, anchor: .bottom)
                    }
                } else {
                    // PORTRAIT layout
                    VStack {
                        Spacer().frame(height: 30)
                        
                        Chart {
                            simulationLines(simulations: simulations)
                            medianLines(simulations: simulations)
                        }
                        .chartLegend(.hidden)
                        .chartXScale(domain: 0.0...20.0, type: .linear)
                        .chartYScale(domain: .automatic(includesZero: false), type: .log)
                        
                        .chartXAxis {
                            let yearMarkers = [5.0, 10.0, 15.0, 20.0]
                            AxisMarks(values: yearMarkers) { axisValue in
                                AxisGridLine(centered: false)
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisTick(centered: false)
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel(centered: false) {
                                    if let yearVal = axisValue.as(Double.self) {
                                        Text("\(Int(yearVal))")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        // Again, Y-axis on the left
                        .chartYAxis {
                            AxisMarks(position: .leading) { axisValue in
                                AxisGridLine()
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisTick()
                                    .foregroundStyle(.white.opacity(0.3))
                                AxisValueLabel {
                                    if let doubleVal = axisValue.as(Double.self) {
                                        let decimalVal = Decimal(doubleVal)
                                        Text(formatSuffix(decimalVal))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .scaleEffect(x: 1.0, y: 0.95, anchor: .bottom)
                        .frame(width: geo.size.width, height: geo.size.height * 0.94)
                        
                        Spacer().frame(height: 10)
                    }
                }
            }
        }
        .navigationBarHidden(false)
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

    // Define your chart types
    enum ChartType {
        case btcPrice
        case cumulativePortfolio
    }

    // Computed property for portrait snapshot
    // private var portraitSnapshot: UIImage? becomes:
        private var portraitSnapshot: UIImage? {
            switch chartSelection.selectedChart {
            case .btcPrice:
                return chartDataCache.chartSnapshot
            case .cumulativePortfolio:
                return chartDataCache.chartSnapshotPortfolio
            }
        }
    
    // Computed property for fresh landscape snapshot
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
                // If we’re already in landscape, immediately produce a "squished" version
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
