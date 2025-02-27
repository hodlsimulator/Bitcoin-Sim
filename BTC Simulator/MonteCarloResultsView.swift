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

// MARK: - ChartType

enum ChartType {
    case btcPrice
    case cumulativePortfolio
}

// MARK: - MonteCarloChartView (Static)

struct MonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    var verticalScale: CGFloat {
        orientationObserver.isLandscape ? 1.0 : 0.92
    }
    
    var body: some View {
        let simulations = chartDataCache.allRuns ?? []
        let bestFit = chartDataCache.bestFitRun?.first
        
        let normalSimulations = simulations.filter { $0.id != bestFit?.id }
        
        let allPoints = simulations.flatMap { $0.points }
        let decimalValues = allPoints.map { $0.value }
        
        let minVal = decimalValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        let maxVal = decimalValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        var bottomExp = floor(log10(minVal))
        if minVal <= pow(10, bottomExp), bottomExp > 0 {
            bottomExp -= 1
        }
        let domainMin = max(pow(10.0, bottomExp), 1.0)
        
        var topExp = floor(log10(maxVal))
        if maxVal >= pow(10.0, topExp) {
            topExp += 1
        }
        let domainMax = pow(10.0, topExp)
        
        let intBottom = Int(bottomExp)
        let intTop    = Int(topExp)
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        let totalPeriods = Double(simSettings.userPeriods)
        let totalYears = (simSettings.periodUnit == .weeks)
        ? totalPeriods / 52.0
        : totalPeriods / 12.0
        
        func dynamicXStride(_ yrs: Double) -> Double {
            switch yrs {
            case ..<1.01:  return 0.25
            case ..<2.01:  return 0.5
            case ..<5.01:  return 1.0
            case ..<10.01: return 2.0
            case ..<25.01: return 5.0
            case ..<50.01: return 10.0
            default:       return 25.0
            }
        }
        let xStride = dynamicXStride(totalYears)
        
        let iterationCount = normalSimulations.count + 1
        
        let xAxisStrideValues = Array(stride(from: 0.0, through: totalYears, by: xStride))
        
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Chart {
                        // Faint lines for normal runs
                        simulationLines(simulations: normalSimulations, simSettings: simSettings)
                        
                        // Overlaid bold orange best-fit
                        if let bestFitRun = bestFit {
                            bestFitLine(bestFitRun, simSettings: simSettings, iterationCount: iterationCount)
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: domainMin...domainMax, type: .log)
                    .chartPlotStyle { plotArea in
                        plotArea
                            .padding(.horizontal, 0)
                            .padding(.vertical, 10)
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
                                } else {
                                    Text("")
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: xAxisStrideValues) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                Text(xAxisLabel(for: axisValue, totalYears: totalYears)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .padding(.top, orientationObserver.isLandscape ? 20 : 0)
                .scaleEffect(x: 1.0, y: verticalScale, anchor: .bottom)
            }
        }
    }
    
    func xAxisLabel(for axisValue: AxisValue, totalYears: Double) -> String {
        if let dblVal = axisValue.as(Double.self), dblVal > 0 {
            if totalYears <= 2.0 {
                return "\(Int(dblVal * 12))M"
            } else {
                return "\(Int(dblVal))Y"
            }
        } else {
            return ""
        }
    }
}

// MARK: - InteractiveMonteCarloChartView (Pinch-to-Zoom)

struct InteractiveMonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    // We’ll store the domain for the X-axis here and update it as the user pinches
    @State private var currentXDomain: ClosedRange<Double> = 0.0...1.0
    @State private var lastMagnificationValue: CGFloat = 1.0
    
    var body: some View {
        let simulations = chartDataCache.allRuns ?? []
        let bestFit = chartDataCache.bestFitRun?.first
        
        let normalSimulations = simulations.filter { $0.id != bestFit?.id }
        
        let allPoints = simulations.flatMap { $0.points }
        let decimalValues = allPoints.map { $0.value }
        
        let minVal = decimalValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        let maxVal = decimalValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        var bottomExp = floor(log10(minVal))
        if minVal <= pow(10, bottomExp), bottomExp > 0 {
            bottomExp -= 1
        }
        let domainMin = max(pow(10.0, bottomExp), 1.0)
        
        var topExp = floor(log10(maxVal))
        if maxVal >= pow(10.0, topExp) {
            topExp += 1
        }
        let domainMax = pow(10.0, topExp)
        
        let intBottom = Int(bottomExp)
        let intTop    = Int(topExp)
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        // We still calculate total years for an initial domain
        let totalPeriods = Double(simSettings.userPeriods)
        let totalYears = (simSettings.periodUnit == .weeks)
            ? totalPeriods / 52.0
            : totalPeriods / 12.0
        
        let iterationCount = normalSimulations.count + 1
        
        // Set the domain if not set yet
        // We do this once on appear, so we have a correct starting domain
        return GeometryReader { geo in
            Chart {
                // Faint lines for normal runs
                simulationLines(simulations: normalSimulations, simSettings: simSettings)
                
                // Overlaid bold orange best-fit
                if let bestFitRun = bestFit {
                    bestFitLine(bestFitRun, simSettings: simSettings, iterationCount: iterationCount)
                }
            }
            .chartLegend(.hidden)
            // Use the domain from our @State variable
            .chartXScale(domain: currentXDomain, type: .linear)
            .chartYScale(domain: domainMin...domainMax, type: .log)
            .chartYAxis {
                AxisMarks(position: .leading, values: yTickValues) { axisValue in
                    AxisGridLine().foregroundStyle(.white.opacity(0.3))
                    AxisTick().foregroundStyle(.white.opacity(0.3))
                    AxisValueLabel {
                        if let dblVal = axisValue.as(Double.self) {
                            let exponent = Int(log10(dblVal))
                            Text(formatPowerOfTenLabel(exponent))
                                .foregroundColor(.white)
                        } else {
                            Text("")
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks() { axisValue in
                    AxisGridLine().foregroundStyle(.white.opacity(0.3))
                    AxisTick().foregroundStyle(.white.opacity(0.3))
                    AxisValueLabel {
                        if let dblVal = axisValue.as(Double.self) {
                            if totalYears <= 2.0 {
                                Text("\(Int(dblVal * 12))M").foregroundColor(.white)
                            } else {
                                Text("\(Int(dblVal))Y").foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .background(Color.black)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        // value is the new pinch scale
                        let delta = value / lastMagnificationValue
                        
                        // Current range of the domain
                        let oldRange = currentXDomain.upperBound - currentXDomain.lowerBound
                        let mid = (currentXDomain.upperBound + currentXDomain.lowerBound) / 2
                        
                        // We shrink or expand the old range by delta
                        let newRange = oldRange / delta
                        let lower = mid - (newRange / 2)
                        let upper = mid + (newRange / 2)
                        
                        // Stop if we get too zoomed in or out
                        let maxRange = totalYears
                        let minRange = totalYears / 10000.0 // just a random floor so we don't over-zoom
                        
                        if newRange >= minRange && newRange <= maxRange {
                            currentXDomain = max(lower, 0.0)...min(upper, totalYears)
                        }
                        lastMagnificationValue = value
                    }
                    .onEnded { _ in
                        lastMagnificationValue = 1.0
                    }
            )
            .onAppear {
                // Only set the domain on first appear
                if currentXDomain == 0.0...1.0 {
                    currentXDomain = 0.0...totalYears
                }
            }
        }
    }
}

// MARK: - MonteCarloResultsView

struct MonteCarloResultsView: View {
    @EnvironmentObject var simChartSelection: SimChartSelection
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var orientationObserver = OrientationObserver()
    
    @State private var squishedLandscape: UIImage? = nil
    @State private var brandNewLandscapeSnapshot: UIImage? = nil
    @State private var isGeneratingLandscape = false
    @State private var showChartMenu = false
    
    // NEW: Toggle between static/snapshot chart and dynamic chart
    @State private var showDynamicChart = false
    
    private var portraitSnapshot: UIImage? {
        switch simChartSelection.selectedChart {
        case .btcPrice:
            return chartDataCache.chartSnapshot
        case .cumulativePortfolio:
            return chartDataCache.chartSnapshotPortfolio
        }
    }
    
    private var freshLandscapeSnapshot: UIImage? {
        switch simChartSelection.selectedChart {
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
            
            if showDynamicChart {
                // Show the new pinch-to-zoom chart
                if simChartSelection.selectedChart == .btcPrice {
                    InteractiveMonteCarloChartView()
                        .environmentObject(orientationObserver)
                        .environmentObject(chartDataCache)
                        .environmentObject(simSettings)
                } else {
                    InteractivePortfolioChartView()
                        .environmentObject(orientationObserver)
                        .environmentObject(chartDataCache)
                        .environmentObject(simSettings)
                }
            } else {
                // Original code
                contentView
            }
            
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
                        withAnimation { showChartMenu = false }
                    }
                    .zIndex(1)
                
                Button {
                    withAnimation {
                        simChartSelection.selectedChart =
                            (simChartSelection.selectedChart == .cumulativePortfolio
                             ? .btcPrice : .cumulativePortfolio)
                        showChartMenu = false
                    }
                } label: {
                    Text(simChartSelection.selectedChart == .cumulativePortfolio
                         ? "BTC Price Chart" : "Cumulative Portfolio")
                        .foregroundColor(.white)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.plain)
                .background(Color.black)
                .edgesIgnoringSafeArea(.horizontal)
                .padding(.top, 15)
                .transition(.move(edge: .top))
                .zIndex(2)
            }
        }
        .navigationTitle(
            isLandscape
            ? ""
            : (simChartSelection.selectedChart == .btcPrice
               ? "Monte Carlo – BTC Price (USD)"
               : "Cumulative Portfolio Returns")
        )
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(isLandscape)
        .toolbar {
            // Existing chart menu toggle (top trailing)
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
            
            // NEW: “Dynamic Chart” button (top leading)
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showDynamicChart.toggle()
                } label: {
                    Text(showDynamicChart ? "Static Chart" : "Dynamic Chart")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(
                UIOffset(horizontal: -1000, vertical: 0),
                for: .default
            )
            
            if isLandscape, let portrait = portraitSnapshot {
                squishedLandscape = squishPortraitImage(portrait)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isGeneratingLandscape = true
                    buildTrueLandscapeSnapshot { newSnapshot in
                        switch simChartSelection.selectedChart {
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
        .onChange(of: isLandscape, initial: false) { _, newVal in
            if newVal {
                if let portrait = portraitSnapshot {
                    DispatchQueue.main.async {
                        squishedLandscape = squishPortraitImage(portrait)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isGeneratingLandscape = true
                    buildTrueLandscapeSnapshot { newSnapshot in
                        switch simChartSelection.selectedChart {
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
                squishedLandscape = nil
                brandNewLandscapeSnapshot = nil
                isGeneratingLandscape = false
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if isLandscape {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                
                if let freshLandscape = freshLandscapeSnapshot {
                    Image(uiImage: freshLandscape)
                        .resizable()
                        .interpolation(.none)
                        .antialiased(false)
                        .aspectRatio(contentMode: .fill)
                } else if let squished = squishedLandscape {
                    Image(uiImage: squished)
                        .resizable()
                        .interpolation(.none)
                        .antialiased(false)
                        .aspectRatio(contentMode: .fill)
                } else if let portrait = portraitSnapshot {
                    SquishedLandscapePlaceholderView(image: portrait)
                } else {
                    if simChartSelection.selectedChart == .btcPrice {
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
            if simChartSelection.selectedChart == .btcPrice {
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
    
    private func buildTrueLandscapeSnapshot(completion: @escaping (UIImage) -> Void) {
        let desiredSize = CGSize(width: 800, height: 400)
        
        let chartToSnapshot: AnyView
        switch simChartSelection.selectedChart {
        case .btcPrice:
            chartToSnapshot = AnyView(
                MonteCarloChartView()
                    .environmentObject(orientationObserver)
                    .environmentObject(chartDataCache)
                    .environmentObject(simSettings)
                    .frame(width: desiredSize.width, height: desiredSize.height)
                    .background(Color.black)
            )
        case .cumulativePortfolio:
            chartToSnapshot = AnyView(
                PortfolioChartView()
                    .environmentObject(orientationObserver)
                    .environmentObject(chartDataCache)
                    .environmentObject(simSettings)
                    .frame(width: desiredSize.width, height: desiredSize.height)
                    .background(Color.black)
            )
        }
        
        let hostingController = UIHostingController(rootView: chartToSnapshot)
        hostingController.view.frame = CGRect(origin: .zero, size: desiredSize)
        
        let renderer = UIGraphicsImageRenderer(size: desiredSize)
        let image = renderer.image { _ in
            hostingController.view.drawHierarchy(
                in: hostingController.view.bounds,
                afterScreenUpdates: true
            )
        }
        
        completion(image)
    }
}

// MARK: - formatPowerOfTenLabel

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
    case 15: return "1Q"
    case 16: return "10Q"
    case 17: return "100Q"
    case 18: return "1Qn"
    case 19: return "10Qn"
    case 20: return "100Qn"
    case 21: return "1Se"
    default:
        return "10^\(exponent)"
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
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ) { _ in
                orientationID = UUID()
            }
    }
}

func convertWeeksToYears(_ week: Int, simSettings: SimulationSettings) -> Double {
    if simSettings.periodUnit == .weeks {
        return Double(week) / 52.0
    } else {
        return Double(week) / 12.0
    }
}

// MARK: - (Optional) Dynamic version of PortfolioChartView

struct InteractivePortfolioChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    // Do the same pinch-to-zoom logic or adapt as needed
    @State private var currentXDomain: ClosedRange<Double> = 0.0...1.0
    @State private var lastMagnificationValue: CGFloat = 1.0
    
    var body: some View {
        // If you have a separate dataset for portfolio, adapt as needed.
        // Here we just pretend it's the same data for demonstration.
        let simulations = chartDataCache.allRuns ?? []
        
        let totalPeriods = Double(simSettings.userPeriods)
        let totalYears = (simSettings.periodUnit == .weeks)
            ? totalPeriods / 52.0
            : totalPeriods / 12.0
        
        return Chart {
            // ... place your portfolio data lines here ...
            // For example:
            simulationLines(simulations: simulations, simSettings: simSettings)
        }
        .chartLegend(.hidden)
        .chartXScale(domain: currentXDomain)
        .chartYScale(domain: 1.0...10_000.0, type: .log) // example domain
        .background(Color.black)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastMagnificationValue
                    let oldRange = currentXDomain.upperBound - currentXDomain.lowerBound
                    let mid = (currentXDomain.upperBound + currentXDomain.lowerBound) / 2
                    let newRange = oldRange / delta
                    let lower = mid - (newRange / 2)
                    let upper = mid + (newRange / 2)
                    
                    let maxRange = totalYears
                    let minRange = totalYears / 10000.0
                    
                    if newRange >= minRange && newRange <= maxRange {
                        currentXDomain = max(lower, 0.0)...min(upper, totalYears)
                    }
                    lastMagnificationValue = value
                }
                .onEnded { _ in
                    lastMagnificationValue = 1.0
                }
        )
        .onAppear {
            if currentXDomain == 0.0...1.0 {
                currentXDomain = 0.0...totalYears
            }
        }
    }
}
