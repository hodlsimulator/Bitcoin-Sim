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

// MARK: - Number Formatting (k, M, B, T, Q)

func formatSuffix(_ value: Double) -> String {
    let absVal = abs(value)
    let sign = value < 0 ? "-" : ""

    switch absVal {
    case 1_000_000_000_000_000_000_000_000_000...:
        // 10^27 => 1 Octillion => "Oc"
        return "\(sign)\(Int(absVal / 1_000_000_000_000_000_000_000_000_000))Oc"
    case 1_000_000_000_000_000_000_000_000...:
        // 10^24 => 1 Septillion => "Sp"
        return "\(sign)\(Int(absVal / 1_000_000_000_000_000_000_000_000))Sp"
    case 1_000_000_000_000_000_000_000...:
        // 10^21 => 1 Sextillion => "Sx"
        return "\(sign)\(Int(absVal / 1_000_000_000_000_000_000_000))Sx"
    case 1_000_000_000_000_000_000...:
        // 10^18 => 1 Quintillion => "Qt"
        return "\(sign)\(Int(absVal / 1_000_000_000_000_000_000))Qt"
    case 1_000_000_000_000_000...:
        // 10^15 => 1 Quadrillion => "Q"
        return "\(sign)\(Int(absVal / 1_000_000_000_000_000))Q"
    case 1_000_000_000_000...:
        // 10^12 => 1 Trillion => "T"
        return "\(sign)\(Int(absVal / 1_000_000_000_000))T"
    case 1_000_000_000...:
        // 10^9 => 1 Billion => "B"
        return "\(sign)\(Int(absVal / 1_000_000_000))B"
    case 1_000_000...:
        // 10^6 => 1 Million => "M"
        return "\(sign)\(Int(absVal / 1_000_000))M"
    case 1_000...:
        // 10^3 => 1 Thousand => "k"
        return "\(sign)\(Int(absVal / 1_000))k"
    default:
        // No suffix => integer as-is
        return "\(sign)\(Int(absVal))"
    }
}

// MARK: - Chart Content Builders

@ChartContentBuilder
func simulationLines(simulations: [SimulationRun]) -> some ChartContent {
    // Mixed bright + pastel palette (including yellow/red, fewer greens/purples).
    // Feel free to customise the hue/saturation/brightness as needed.
    let customPalette: [Color] = [
        // Reds/oranges/yellows
        Color(hue: 0.0,  saturation: 1.0, brightness: 0.8),  // bright red
        Color(hue: 0.0,  saturation: 0.3, brightness: 1.0),  // pastel pink
        Color(hue: 0.08, saturation: 1.0, brightness: 1.0),  // bright orange
        Color(hue: 0.08, saturation: 0.3, brightness: 1.0),  // pastel orange
        Color(hue: 0.13, saturation: 1.0, brightness: 1.0),  // bright yellow
        Color(hue: 0.13, saturation: 0.3, brightness: 1.0),  // pastel yellow
        
        // Some blues/purples but not too many
        Color(hue: 0.55, saturation: 1.0, brightness: 0.9),  // bright blue
        Color(hue: 0.55, saturation: 0.3, brightness: 0.9),  // pastel blue
        Color(hue: 0.7,  saturation: 0.6, brightness: 0.8),  // purple
        Color(hue: 0.7,  saturation: 0.3, brightness: 0.9),  // pastel purple
        
        // Greens/cyans but muted
        Color(hue: 0.28, saturation: 0.7, brightness: 0.8),  // mild green
        Color(hue: 0.28, saturation: 0.3, brightness: 0.9),  // pastel green
        Color(hue: 0.47, saturation: 0.7, brightness: 0.8),  // teal
        Color(hue: 0.47, saturation: 0.3, brightness: 0.9),  // pastel teal
    ]
    
    ForEach(simulations.indices, id: \.self) { index in
        let sim = simulations[index]
        let colour = customPalette[index % customPalette.count]
        
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Week", pt.week),
                y: .value("BTC Price (USD)", pt.value)
            )
            .foregroundStyle(colour.opacity(0.2))
            .foregroundStyle(by: .value("SeriesIndex", index))
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
        // Reduced opacity on the median line’s orange
        .foregroundStyle(.orange.opacity(0.7))
        .lineStyle(StrokeStyle(lineWidth: 1.5))
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
                                .font(.system(size: 14))
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
                                .font(.system(size: 14))
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
