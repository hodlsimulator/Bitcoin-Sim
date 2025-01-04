//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI
import Charts
import Combine

// MARK: - Data Models

struct WeekPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Double // We'll treat 'value' as BTC price in USD
}

struct SimulationRun: Identifiable {
    let id = UUID()
    let points: [WeekPoint]
}

// MARK: - View Model

class ChartViewModel: ObservableObject {
    @Published var simulations: [SimulationRun]
    @Published var isLoading: Bool = false
    
    init(simulations: [SimulationRun]) {
        print("// DEBUG: ChartViewModel init -> Created. Simulations count: \(simulations.count)")
        self.simulations = simulations
    }
    
    // Example of a median line, used by medianLines(...)
    var medianLine: [WeekPoint] {
        guard let firstRun = simulations.first else {
            print("// DEBUG: medianLine -> No simulations present.")
            return []
        }
        let countPerRun = firstRun.points.count
        var medianPoints: [WeekPoint] = []
        
        for index in 0..<countPerRun {
            let week = firstRun.points[index].week
            let allValues = simulations.map { $0.points[index].value }.sorted()
            
            let middle = allValues.count / 2
            let median: Double
            if allValues.count.isMultiple(of: 2) {
                median = (allValues[middle] + allValues[middle - 1]) / 2
            } else {
                median = allValues[middle]
            }
            
            medianPoints.append(WeekPoint(week: week, value: median))
        }
        return medianPoints
    }
}

// MARK: - Number Formatting

func formatSuffix(_ value: Double) -> String {
    if value >= 1_000_000_000_000_000 { return "\(Int(value / 1_000_000_000_000_000))Q" }  // Quadrillion
    if value >= 1_000_000_000_000 { return "\(Int(value / 1_000_000_000_000))T" }         // Trillion
    if value >= 1_000_000_000 { return "\(Int(value / 1_000_000_000))B" }                 // Billion
    if value >= 1_000_000 { return "\(Int(value / 1_000_000))M" }                         // Million
    if value >= 1_000 { return "\(Int(value / 1_000))k" }                                 // Thousand
    return String(Int(value))
}

// Convert weeks to approximate years
fileprivate func weeksToYears(_ weeks: Int) -> Double {
    Double(weeks) / 52.0
}

// MARK: - Chart Content Builders (rainbow logic)

@ChartContentBuilder
func simulationLines(simulations: [SimulationRun]) -> some ChartContent {
    let customPalette: [Color] = [
        Color(hue: 0.0,  saturation: 1.0, brightness: 0.8),
        Color(hue: 0.0,  saturation: 0.3, brightness: 1.0),
        Color(hue: 0.08, saturation: 1.0, brightness: 1.0),
        Color(hue: 0.08, saturation: 0.3, brightness: 1.0),
        Color(hue: 0.13, saturation: 1.0, brightness: 1.0),
        Color(hue: 0.13, saturation: 0.3, brightness: 1.0),
        Color(hue: 0.55, saturation: 1.0, brightness: 0.9),
        Color(hue: 0.55, saturation: 0.3, brightness: 0.9),
        Color(hue: 0.7,  saturation: 0.6, brightness: 0.8),
        Color(hue: 0.7,  saturation: 0.3, brightness: 0.9),
        Color(hue: 0.28, saturation: 0.7, brightness: 0.8),
        Color(hue: 0.28, saturation: 0.3, brightness: 0.9),
        Color(hue: 0.47, saturation: 0.7, brightness: 0.8),
        Color(hue: 0.47, saturation: 0.3, brightness: 0.9),
    ]
    
    ForEach(simulations.indices, id: \.self) { index in
        let sim = simulations[index]
        let colour = customPalette[index % customPalette.count]
        
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Year", weeksToYears(pt.week)),
                y: .value("BTC Price (USD)", pt.value)
            )
            .foregroundStyle(colour.opacity(0.3))
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
func medianLines(simulations: [SimulationRun], medianLine: [WeekPoint]) -> some ChartContent {
    let iterationCount = Double(simulations.count)
    let startDarkeningAt = 70.0
    let maxDarkeningAt   = 1000.0
    
    let fraction = max(0, min(1, (iterationCount - startDarkeningAt) / (maxDarkeningAt - startDarkeningAt)))
    let brightness = 1.0 - 0.6 * fraction
    let darkeningOrange = Color(hue: 0.08, saturation: 1.0, brightness: brightness)
    
    ForEach(medianLine) { pt in
        LineMark(
            x: .value("Year", weeksToYears(pt.week)),
            y: .value("BTC Price (USD)", pt.value)
        )
        .foregroundStyle(darkeningOrange)
        .lineStyle(StrokeStyle(lineWidth: 1.5))
        .interpolationMethod(.monotone)
    }
}

// MARK: - Chart Subview

struct MonteCarloChartView: View {
    @ObservedObject var viewModel: ChartViewModel
    @EnvironmentObject var orientationObserver: OrientationObserver

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
            } else {
                if orientationObserver.isLandscape {
                    // Fullscreen in landscape with scaleEffect to avoid clipping
                    GeometryReader { geo in
                        ZStack {
                            Color.black.ignoresSafeArea()
                            
                            Chart {
                                simulationLines(simulations: viewModel.simulations)
                                medianLines(simulations: viewModel.simulations, medianLine: viewModel.medianLine)
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
                            .chartYAxis {
                                AxisMarks(position: .leading) { axisValue in
                                    AxisGridLine()
                                        .foregroundStyle(.white.opacity(0.3))
                                    AxisTick()
                                        .foregroundStyle(.white.opacity(0.3))
                                    AxisValueLabel {
                                        if let val = axisValue.as(Double.self) {
                                            Text(formatSuffix(val))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            // Make the chart 10% wider; anchor right side
                            .frame(width: geo.size.width * 1.1, height: geo.size.height, alignment: .trailing)
                            .offset(x: -(geo.size.width * 0.04))   // Shift left by 4% of width
                            .scaleEffect(x: 1.0, y: 0.98, anchor: .bottom)
                            // Removed .clipped() so it won't cut off the wider chart
                        }
                    }
                    .navigationBarHidden(true)
                } else {
                    // Portrait layout
                    Chart {
                        simulationLines(simulations: viewModel.simulations)
                        medianLines(simulations: viewModel.simulations, medianLine: viewModel.medianLine)
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
                    .chartYAxis {
                        AxisMarks(position: .leading) { axisValue in
                            AxisGridLine()
                                .foregroundStyle(.white.opacity(0.3))
                            AxisTick()
                                .foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let val = axisValue.as(Double.self) {
                                    Text(formatSuffix(val))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.2))
                    )
                    .navigationBarHidden(false)
                }
            }
        }
    }
}

// MARK: - Snapshot & Squish

struct SquishedLandscapePlaceholderView: View {
    let image: UIImage
    
    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                // Shift/scale to emulate a wide view
                .frame(width: geo.size.width * 1.25,
                       height: geo.size.height * 1.15)
                .offset(x: -(geo.size.width * 0.12),
                        y: geo.size.height * 0.05)
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

/// Squish the portrait snapshot into a pseudo-landscape image
func squishPortraitImage(_ portraitImage: UIImage) -> UIImage {
    let targetSize = CGSize(width: 800, height: 400)
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    
    return renderer.image { _ in
        // e.g. shift left ~12%, scale 1.25x
        portraitImage.draw(
            in: CGRect(x: -(targetSize.width * 0.12),
                       y: 0,
                       width: targetSize.width * 1.25,
                       height: targetSize.height * 1.25)
        )
    }
}

// MARK: - Main Results View

struct MonteCarloResultsView: View {
    @StateObject private var viewModel: ChartViewModel
    @EnvironmentObject var chartDataCache: ChartDataCache
    
    @StateObject private var orientationObserver = OrientationObserver()
    
    @State private var squishedLandscape: UIImage? = nil
    @State private var brandNewLandscapeSnapshot: UIImage? = nil
    @State private var isGeneratingLandscape = false
    
    init(simulations: [SimulationRun]) {
        _viewModel = StateObject(wrappedValue: ChartViewModel(simulations: simulations))
    }
    
    var body: some View {
        let isLandscape = orientationObserver.isLandscape
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 1) Landscape logic
            if isLandscape {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
                    if let freshLandscape = brandNewLandscapeSnapshot {
                        Image(uiImage: freshLandscape)
                            .resizable()
                            .scaledToFit()
                    }
                    else if let squished = squishedLandscape {
                        Image(uiImage: squished)
                            .resizable()
                            .scaledToFit()
                    }
                    else if let portrait = chartDataCache.chartSnapshot {
                        SquishedLandscapePlaceholderView(image: portrait)
                    } else {
                        MonteCarloChartView(viewModel: viewModel)
                            .environmentObject(orientationObserver)
                    }
                }
            }
            // 2) Portrait logic
            else {
                if let portrait = chartDataCache.chartSnapshot {
                    SnapshotView(snapshot: portrait)
                } else {
                    MonteCarloChartView(viewModel: viewModel)
                        .environmentObject(orientationObserver)
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
        .navigationTitle(isLandscape ? "" : "Monte Carlo – BTC Price (USD)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(isLandscape)
        .onAppear {
            // If we start in landscape
            if isLandscape {
                if let portrait = chartDataCache.chartSnapshot {
                    squishedLandscape = squishPortraitImage(portrait)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isGeneratingLandscape = true
                    buildTrueLandscapeSnapshot { newSnapshot in
                        brandNewLandscapeSnapshot = newSnapshot
                        isGeneratingLandscape = false
                    }
                }
            }
        }
        .onChange(of: isLandscape) { newVal in
            if newVal {
                if let portrait = chartDataCache.chartSnapshot {
                    DispatchQueue.main.async {
                        squishedLandscape = squishPortraitImage(portrait)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isGeneratingLandscape = true
                    buildTrueLandscapeSnapshot { newSnapshot in
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
    
    // Build the “true” snapshot in a wide frame
    private func buildTrueLandscapeSnapshot(completion: @escaping (UIImage) -> Void) {
        let wideChart = MonteCarloChartView(viewModel: viewModel)
            .environmentObject(orientationObserver)
            .frame(width: 800, height: 400)
            .background(Color.black)
        
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
