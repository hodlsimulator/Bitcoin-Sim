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
        print("// DEBUG: MonteCarloResultsView init -> I'm being created. chartDataCache not accessible yet here.")
        // Keep the data so it's not lost on rotation
        self.simulations = simulations
    }
    
    // Compute Median once, from the same data
    var medianLine: [WeekPoint] {
        guard let firstRun = simulations.first else { return [] }
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
    if value >= 1_000_000_000_000_000_000 { return "\(Int(value / 1_000_000_000_000_000_000))Q" } // Quadrillion etc.
    if value >= 1_000_000_000_000 { return "\(Int(value / 1_000_000_000_000))T" }                 // Trillion
    if value >= 1_000_000_000 { return "\(Int(value / 1_000_000_000))B" }                         // Billion
    if value >= 1_000_000 { return "\(Int(value / 1_000_000))M" }                                 // Million
    if value >= 1_000 { return "\(Int(value / 1_000))k" }                                         // Thousand
    return String(Int(value))
}

// MARK: - Convert Weeks to Years

fileprivate func weeksToYears(_ weeks: Int) -> Double {
    Double(weeks) / 52.0
}

// MARK: - Chart Content Builders

@ChartContentBuilder
func simulationLines(simulations: [SimulationRun]) -> some ChartContent {
    // The same customPalette & exact .foregroundStyle calls as your original
    let customPalette: [Color] = [
        // Reds / Oranges / Yellows
        Color(hue: 0.0,  saturation: 1.0, brightness: 0.8),
        Color(hue: 0.0,  saturation: 0.3, brightness: 1.0),
        Color(hue: 0.08, saturation: 1.0, brightness: 1.0),
        Color(hue: 0.08, saturation: 0.3, brightness: 1.0),
        Color(hue: 0.13, saturation: 1.0, brightness: 1.0),
        Color(hue: 0.13, saturation: 0.3, brightness: 1.0),
        
        // Some blues/purples
        Color(hue: 0.55, saturation: 1.0, brightness: 0.9),
        Color(hue: 0.55, saturation: 0.3, brightness: 0.9),
        Color(hue: 0.7,  saturation: 0.6, brightness: 0.8),
        Color(hue: 0.7,  saturation: 0.3, brightness: 0.9),
        
        // Greens / cyans but muted
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
            // EXACT order: .foregroundStyle(colour.opacity(0.3)), then .foregroundStyle(by: ...)
            .foregroundStyle(colour.opacity(0.3))
            .foregroundStyle(by: .value("SeriesIndex", index))
            .lineStyle(StrokeStyle(lineWidth: 0.5,
                                   lineCap: .round,
                                   lineJoin: .round))
        }
    }
}

// Instead of darkening from the first iteration, start it at iteration 70
// and only go as dark as brightness=0.4 at iteration 1000 (so it's not too dark).
// Everything else remains the same hue/sat logic, just adjusted to your new start/end points.

@ChartContentBuilder
func medianLines(simulations: [SimulationRun], medianLine: [WeekPoint]) -> some ChartContent {
    let iterationCount = Double(simulations.count)
    let startDarkeningAt = 70.0
    let maxDarkeningAt   = 1000.0
    
    // Calculate a fraction that stays at 0 for <70 iterations, then goes up to 1 at 1000
    let fraction = max(0, min(1, (iterationCount - startDarkeningAt) / (maxDarkeningAt - startDarkeningAt)))
    
    // We now go from brightness = 1.0 (for 70 or fewer iterations) down to 0.4 (not 0.3) at 1000
    let brightness = 1.0 - 0.6 * fraction
    
    // Same hue/saturation, just altered brightness
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
    
    var body: some View {
        // Show a loading indicator if isLoading = true,
        // otherwise the Chart
        if viewModel.isLoading {
            ProgressView("Loading…")
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
        } else {
            Chart {
                simulationLines(simulations: viewModel.simulations)
                medianLines(simulations: viewModel.simulations,
                            medianLine: viewModel.medianLine)
            }
            .chartLegend(.hidden)
            // X-axis in years, from 0..20
            .chartXScale(domain: 0.0...20.0, type: .linear)
            // Y-axis is log scale, auto domain
            .chartYScale(domain: .automatic(includesZero: false), type: .log)
            // Custom X-axis at 5, 10, 15, 20
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
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            // Y-axis with horizontal lines
            .chartYAxis {
                AxisMarks(position: .leading) { axisValue in
                    AxisGridLine()
                        .foregroundStyle(.white.opacity(0.3))
                    AxisTick()
                        .foregroundStyle(.white.opacity(0.3))
                    AxisValueLabel {
                        if let val = axisValue.as(Double.self) {
                            Text(formatSuffix(val))
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            // Vertical padding so it's not cramped
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
}

// MARK: - Main View

struct MonteCarloResultsView: View {
    // Keep data in a StateObject so it isn't re-fetched on rotation
    @StateObject private var viewModel: ChartViewModel
    
    // We'll grab the snapshot if it's cached
    @EnvironmentObject var chartDataCache: ChartDataCache
    
    init(simulations: [SimulationRun]) {
        _viewModel = StateObject(wrappedValue: ChartViewModel(simulations: simulations))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // If there's a snapshot in the cache, show it immediately.
                if let snapshotImage = chartDataCache.chartSnapshot {
                    Image(uiImage: snapshotImage)
                        .resizable()
                        .scaledToFit()
                        .background(Color.black.ignoresSafeArea())
                } else {
                    // Fallback: show the live SwiftUI Chart
                    VStack(spacing: 0) {
                        MonteCarloChartView(viewModel: viewModel)
                    }
                    .background(Color.black.ignoresSafeArea())
                }
                
                // If isLoading is true, overlay a spinner
                if viewModel.isLoading {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    ProgressView("Loading…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2.0)
                }
            }
            .navigationTitle("Monte Carlo – BTC Price (USD)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("// DEBUG: MonteCarloResultsView onAppear, chartDataCache =", chartDataCache)
            // Listen for orientation changes, show a quick loading spinner
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                // If we’re displaying the SwiftUI chart (no snapshot),
                // show the spinner briefly on orientation change
                if chartDataCache.chartSnapshot == nil {
                    viewModel.isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        viewModel.isLoading = false
                    }
                }
            }
        }
    }
}
