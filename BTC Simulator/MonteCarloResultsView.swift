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
            .foregroundStyle(colour.opacity(0.3))
            .foregroundStyle(by: .value("SeriesIndex", index))
            .lineStyle(StrokeStyle(lineWidth: 0.5,
                                   lineCap: .round,
                                   lineJoin: .round))
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
    
    var body: some View {
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
                                .font(.system(size: 14))
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
                                .font(.system(size: 14))
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
        }
    }
}

// MARK: - Main View

struct MonteCarloResultsView: View {
    @StateObject private var viewModel: ChartViewModel
    @EnvironmentObject var chartDataCache: ChartDataCache
    
    init(simulations: [SimulationRun]) {
        _viewModel = StateObject(wrappedValue: ChartViewModel(simulations: simulations))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Make the entire underlying page black
                Color.black
                    .ignoresSafeArea()
                
                if let snapshotImage = chartDataCache.chartSnapshot {
                    Group {
                        Image(uiImage: snapshotImage)
                            .resizable()
                            .scaledToFill()
                            // Pin top, clip any spillover, but add space at bottom
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .clipped()
                            .padding(.bottom, 90) // Adjust as needed
                            .ignoresSafeArea(edges: .top)
                            .transition(.move(edge: .bottom))
                    }
                    .animation(.easeInOut(duration: 0.5), value: chartDataCache.chartSnapshot)
                } else {
                    // Fallback: show the live SwiftUI Chart
                    VStack(spacing: 0) {
                        MonteCarloChartView(viewModel: viewModel)
                    }
                    .background(Color.black.ignoresSafeArea())
                }
                
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
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
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
