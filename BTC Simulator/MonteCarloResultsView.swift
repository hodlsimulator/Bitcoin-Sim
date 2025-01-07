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

fileprivate func weeksToYears(_ weeks: Int) -> Double {
    Double(weeks) / 52.0
}

// MARK: - Chart Content Builders

@ChartContentBuilder
func simulationLines(simulations: [SimulationRun]) -> some ChartContent {
    let customPalette: [Color] = [
        // Near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        Color(hue: 0.33, saturation: 0.05, brightness: 1.0), // Slight greenish-white
        Color(hue: 0.66, saturation: 0.05, brightness: 1.0), // Slight bluish-white
        Color(hue: 0.83, saturation: 0.05, brightness: 1.0), // Slight purplish-white

        // More near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white

        /* Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        
        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        
        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        
        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white */

        // Strong reds/oranges
        Color(hue: 0.0000, saturation: 0.8, brightness: 1.0), // Red
        Color(hue: 0.0167, saturation: 0.8, brightness: 1.0), // Reddish-Orange
        Color(hue: 0.0333, saturation: 0.8, brightness: 1.0), // Orange
        Color(hue: 0.0500, saturation: 0.8, brightness: 1.0), // Soft Orange
        Color(hue: 0.0667, saturation: 0.8, brightness: 1.0), // Golden Yellow
        Color(hue: 0.0833, saturation: 0.8, brightness: 1.0), // Yellow-Gold
        Color(hue: 0.1000, saturation: 0.8, brightness: 1.0), // Light Yellow
        Color(hue: 0.1167, saturation: 0.6, brightness: 1.0), // Pale Yellow
        Color(hue: 0.1333, saturation: 0.4, brightness: 1.0), // Lime Yellow
        Color(hue: 0.1500, saturation: 0.8, brightness: 1.0), // Warm Yellow
        Color(hue: 0.1667, saturation: 0.8, brightness: 1.0), // Pure Yellow
        Color(hue: 0.1833, saturation: 0.8, brightness: 1.0), // Yellow-Green
        Color(hue: 0.2000, saturation: 0.6, brightness: 1.0), // Light Yellow-Green
        Color(hue: 0.2167, saturation: 0.8, brightness: 1.0), // Pastel Green
        Color(hue: 0.2333, saturation: 0.6, brightness: 1.0), // Soft Green
        Color(hue: 0.2500, saturation: 0.6, brightness: 1.0), // Spring Green
        
        // Extra s  trong reds/oranges
        Color(hue: 0.0000, saturation: 0.8, brightness: 1.0), // Red
        Color(hue: 0.0167, saturation: 0.8, brightness: 1.0), // Reddish-Orange
        Color(hue: 0.0333, saturation: 0.8, brightness: 1.0), // Orange
        Color(hue: 0.0500, saturation: 0.8, brightness: 1.0), // Soft Orange
        Color(hue: 0.0667, saturation: 0.8, brightness: 1.0), // Golden Yellow
        Color(hue: 0.0833, saturation: 0.8, brightness: 1.0), // Yellow-Gold
        Color(hue: 0.1000, saturation: 0.8, brightness: 1.0), // Light Yellow
        Color(hue: 0.1167, saturation: 0.6, brightness: 1.0), // Pale Yellow
        Color(hue: 0.1333, saturation: 0.4, brightness: 1.0), // Lime Yellow
        Color(hue: 0.1500, saturation: 0.8, brightness: 1.0), // Warm Yellow
        Color(hue: 0.1667, saturation: 0.8, brightness: 1.0), // Pure Yellow
        Color(hue: 0.1833, saturation: 0.8, brightness: 1.0), // Yellow-Green
        Color(hue: 0.2000, saturation: 0.6, brightness: 1.0), // Light Yellow-Green
        Color(hue: 0.2167, saturation: 0.8, brightness: 1.0), // Pastel Green
        Color(hue: 0.2333, saturation: 0.6, brightness: 1.0), // Soft Green
        Color(hue: 0.2500, saturation: 0.6, brightness: 1.0), // Spring Green

        // Commented-out greens/cyans
        // Color(hue: 0.2667, saturation: 0.6, brightness: 1.0), // Green
        // Color(hue: 0.2833, saturation: 0.6, brightness: 1.0), // Sea Green
        // Color(hue: 0.3000, saturation: 0.6, brightness: 1.0), // Greenish-Cyan
        // Color(hue: 0.3167, saturation: 0.6, brightness: 1.0), // Cyan-Green
        // Color(hue: 0.3333, saturation: 0.6, brightness: 1.0), // Cyanish-Green
        // Color(hue: 0.3500, saturation: 0.6, brightness: 1.0), // Soft Turquoise

        Color(hue: 0.3667, saturation: 0.6, brightness: 1.0), // Turquoise
        Color(hue: 0.3833, saturation: 0.6, brightness: 1.0), // Teal
        Color(hue: 0.4000, saturation: 0.6, brightness: 1.0), // Blue-Teal
        Color(hue: 0.4167, saturation: 0.6, brightness: 1.0), // Light Aqua
        Color(hue: 0.4333, saturation: 0.6, brightness: 1.0), // Aqua

        // Commented-out aquas/blues
        // Color(hue: 0.4500, saturation: 0.6, brightness: 1.0), // Soft Aqua
        // Color(hue: 0.4667, saturation: 0.6, brightness: 1.0), // Pale Aqua
        // Color(hue: 0.4833, saturation: 0.6, brightness: 1.0), // Greenish-Blue
        
        // Blues
        Color(hue: 0.5000, saturation: 0.8, brightness: 1.0), // Cyan
        Color(hue: 0.5167, saturation: 0.8, brightness: 1.0), // Soft Cyan
        Color(hue: 0.5333, saturation: 0.8, brightness: 1.0), // Light Teal
        Color(hue: 0.5500, saturation: 0.6, brightness: 1.0), // Pale Turquoise
        Color(hue: 0.5667, saturation: 0.6, brightness: 1.0), // Bluish-Turquoise
        Color(hue: 0.5833, saturation: 0.8, brightness: 1.0), // Light Blue
        Color(hue: 0.6000, saturation: 0.8, brightness: 1.0), // Sky Blue
        Color(hue: 0.6167, saturation: 0.8, brightness: 1.0), // Soft Sky Blue
        Color(hue: 0.6333, saturation: 0.8, brightness: 1.0), // Medium Blue
        Color(hue: 0.6500, saturation: 0.8, brightness: 1.0), // Blue
        Color(hue: 0.6667, saturation: 0.8, brightness: 1.0), // True Blue
        // Color(hue: 0.6833, saturation: 0.6, brightness: 1.0), // Indigo-Blue
        
        // Extra blues
        Color(hue: 0.5000, saturation: 0.8, brightness: 1.0), // Cyan
        Color(hue: 0.5167, saturation: 0.8, brightness: 1.0), // Soft Cyan
        Color(hue: 0.5333, saturation: 0.8, brightness: 1.0), // Light Teal
        Color(hue: 0.5500, saturation: 0.6, brightness: 1.0), // Pale Turquoise
        Color(hue: 0.5667, saturation: 0.6, brightness: 1.0), // Bluish-Turquoise
        Color(hue: 0.5833, saturation: 0.8, brightness: 1.0), // Light Blue
        Color(hue: 0.6000, saturation: 0.8, brightness: 1.0), // Sky Blue
        Color(hue: 0.6167, saturation: 0.8, brightness: 1.0), // Soft Sky Blue
        Color(hue: 0.6333, saturation: 0.8, brightness: 1.0), // Medium Blue
        Color(hue: 0.6500, saturation: 0.8, brightness: 1.0), // Blue
        Color(hue: 0.6667, saturation: 0.8, brightness: 1.0), // True Blue
        // Color(hue: 0.6833, saturation: 0.6, brightness: 1.0), // Indigo-Blue

        // Commented-out purples/indigos
        // Color(hue: 0.7000, saturation: 0.6, brightness: 1.0), // Indigo
        // Color(hue: 0.7167, saturation: 0.6, brightness: 1.0), // Soft Indigo
        // Color(hue: 0.7333, saturation: 0.6, brightness: 1.0), // Periwinkle
        // Color(hue: 0.7500, saturation: 0.6, brightness: 1.0), // Purple
        // Color(hue: 0.7667, saturation: 0.6, brightness: 1.0), // Violet
        // Color(hue: 0.7833, saturation: 0.6, brightness: 1.0), // Lavender
        // Color(hue: 0.8000, saturation: 0.6, brightness: 1.0), // Light Purple
        // Color(hue: 0.8167, saturation: 0.6, brightness: 1.0), // Soft Magenta
        // Color(hue: 0.8333, saturation: 0.6, brightness: 1.0), // Magenta
        // Color(hue: 0.8500, saturation: 0.6, brightness: 1.0), // Pinkish-Magenta

        // Pinks/reds
        Color(hue: 0.8667, saturation: 0.8, brightness: 1.0), // Pink
        Color(hue: 0.8833, saturation: 0.6, brightness: 1.0), // Soft Pink
        Color(hue: 0.9000, saturation: 0.6, brightness: 1.0), // Light Pink
        Color(hue: 0.9167, saturation: 0.6, brightness: 1.0), // Pinkish-Red
        Color(hue: 0.9333, saturation: 0.8, brightness: 1.0), // Light Red
        Color(hue: 0.9500, saturation: 0.8, brightness: 1.0), // Pale Red
        Color(hue: 0.9667, saturation: 0.8, brightness: 1.0), // Reddish-Pink
        Color(hue: 0.9833, saturation: 0.8, brightness: 1.0)  // Very Pale Red
    ]
    
    ForEach(simulations.indices, id: \.self) { index in
        let sim = simulations[index]
        // Use modulo so we can safely index into the palette no matter how many simulations
        let colour = customPalette[index % customPalette.count]
        
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Year", weeksToYears(pt.week)),
                y: .value("Value", NSDecimalNumber(decimal: pt.value).doubleValue)
            )
            .foregroundStyle(colour.opacity(0.2))
            .foregroundStyle(by: .value("SeriesIndex", index))
            .lineStyle(
                StrokeStyle(
                    lineWidth: 0.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
    }
}

@ChartContentBuilder
func medianLines(simulations: [SimulationRun]) -> some ChartContent {
    let medianLine = computeMedianLine(simulations)
    
    // 1) Figure out how many total runs we have (70..1000).
    let iterationCount = simulations.count
    let clamped = max(70, min(iterationCount, 1000))
    
    // 2) fraction goes from 0.0 (at 70) up to 1.0 (at 1000).
    let fraction = Double(clamped - 70) / Double(1000 - 70)
    
    // 3) Keep the orange line at full opacity (1.0),
    //    but reduce brightness from 1.0 down to 0.6
    let minBrightness: CGFloat = 1.0
    let maxDarkBrightness: CGFloat = 0.6
    let dynamicBrightness = minBrightness - fraction * (minBrightness - maxDarkBrightness)
    
    // 4) Also thicken line from 1.5 up to 3.0
    let minWidth: CGFloat = 1.5
    let maxWidth: CGFloat = 3.0
    let lineWidth = minWidth + fraction * (maxWidth - minWidth)
    
    // 5) Build the median line with dynamic brightness & thickness
    ForEach(medianLine) { pt in
        LineMark(
            x: .value("Year", weeksToYears(pt.week)),
            y: .value("Value", NSDecimalNumber(decimal: pt.value).doubleValue)
        )
        .foregroundStyle(
            // Hue ~0.08 is an orange-ish hue, saturate around 0.9
            Color(hue: 0.08, saturation: 0.9, brightness: dynamicBrightness)
        )
        .interpolationMethod(.monotone)
        .lineStyle(
            StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
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
