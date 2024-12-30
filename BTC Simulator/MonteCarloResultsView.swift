//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI
import Charts

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

// MARK: - Compute Median

func computeMedianLine(simulations: [SimulationRun]) -> [WeekPoint] {
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

// MARK: - Number Formatting (k, M, B, T)

func formatSuffix(_ value: Double) -> String {
    let absVal = abs(value)
    let sign = value < 0 ? "-" : ""
    
    switch absVal {
    case 1_000_000_000_000...:
        return "\(sign)\(Int(absVal / 1_000_000_000_000))T"
    case 1_000_000_000...:
        return "\(sign)\(Int(absVal / 1_000_000_000))B"
    case 1_000_000...:
        return "\(sign)\(Int(absVal / 1_000_000))M"
    case 1_000...:
        return "\(sign)\(Int(absVal / 1_000))k"
    default:
        return "\(sign)\(Int(absVal))"
    }
}

// MARK: - Chart Content Builders

@ChartContentBuilder
func simulationLines(simulations: [SimulationRun]) -> some ChartContent {
    ForEach(simulations.indices, id: \.self) { index in
        let sim = simulations[index]
        
        // Hue-based approach for distinct lines
        let hue = Double(index) / Double(max(simulations.count - 1, 1))
        let runColor = Color(hue: hue, saturation: 0.8, brightness: 0.8)
        
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Week", pt.week),
                y: .value("BTC Price (USD)", pt.value)
            )
            .foregroundStyle(runColor.opacity(0.2))             // 20% opacity
            .foregroundStyle(by: .value("SeriesIndex", index))  // Distinct series
            .lineStyle(StrokeStyle(lineWidth: 0.5,
                                   lineCap: .round,
                                   lineJoin: .round))
        }
    }
}

@ChartContentBuilder
func medianLines(_ medianLine: [WeekPoint]) -> some ChartContent {
    ForEach(medianLine) { pt in
        LineMark(
            x: .value("Week", pt.week),
            y: .value("BTC Price (USD)", pt.value)
        )
        .foregroundStyle(.orange)
        .lineStyle(StrokeStyle(lineWidth: 1.5))  // Thicker median
        .interpolationMethod(.monotone)
    }
}

// MARK: - Chart Subview

struct MonteCarloChartView: View {
    let simulations: [SimulationRun]
    let medianLine: [WeekPoint]
    
    var body: some View {
        GeometryReader { geo in
            Chart {
                simulationLines(simulations: simulations)
                medianLines(medianLine)
            }
            .chartLegend(.hidden)
            .chartYScale(domain: .automatic(includesZero: false), type: .log)
            .chartXAxis {
                let yearMarkers = [260, 520, 780, 1040]
                AxisMarks(values: yearMarkers) { axisValue in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let weeks = axisValue.as(Int.self) {
                            let years = weeks / 52
                            Text("\(years)")
                                .font(.system(size: 14))   // Slightly smaller X-axis font
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { axisValue in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let val = axisValue.as(Double.self) {
                            Text(formatSuffix(val))
                                .font(.system(size: 14))  // Slightly smaller Y-axis font
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
            )
        }
    }
}

// MARK: - Main View

struct MonteCarloResultsView: View {
    let simulations: [SimulationRun]
    
    init(simulations: [SimulationRun]) {
        self.simulations = simulations
        print("[DEBUG] simulations.count = \(simulations.count)")
    }
    
    var body: some View {
        NavigationStack {
            let medianLine = computeMedianLine(simulations: simulations)
            
            VStack(spacing: 0) {
                MonteCarloChartView(
                    simulations: simulations,
                    medianLine: medianLine
                )
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Monte Carlo – BTC Price (USD)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
