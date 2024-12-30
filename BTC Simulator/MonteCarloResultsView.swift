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

// MARK: - Random Colour Generator

func randomColor() -> Color {
    let hue = Double.random(in: 0...1)
    let saturation = Double.random(in: 0.5...1)
    let brightness = Double.random(in: 0.7...1)
    return Color(hue: hue, saturation: saturation, brightness: brightness)
}

// MARK: - Chart Content Builders

@ChartContentBuilder
func simulationLines(simulations: [SimulationRun]) -> some ChartContent {
    ForEach(simulations.indices, id: \.self) { index in
        let sim = simulations[index]
        
        // Pick a random colour for this entire simulation run
        let runColor = randomColor()
        
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Week", pt.week),
                y: .value("BTC Price (USD)", pt.value)
            )
            // We'll explicitly give each run a random color...
            .foregroundStyle(runColor)
            // ...and also let Swift Charts see each run as a distinct "Series."
            .foregroundStyle(by: .value("SeriesIndex", index))
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
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.monotone)
    }
}

// MARK: - Chart Subview

struct MonteCarloChartView: View {
    let simulations: [SimulationRun]
    let medianLine: [WeekPoint]
    
    var body: some View {
        Chart {
            simulationLines(simulations: simulations)
            medianLines(medianLine)
        }
        // Hide default legend, or show it if you like
        .chartLegend(.hidden)
        .frame(height: 350)
        .chartYScale(domain: .automatic(includesZero: false), type: .log)
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 10, through: 1040, by: 10))) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { axisValue in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let val = axisValue.as(Double.self) {
                        Text(formatSuffix(val))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
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
        let medianLine = computeMedianLine(simulations: simulations)
        
        ScrollView {
            VStack(spacing: 20) {
                Text("Monte Carlo – BTC Price (USD)")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                MonteCarloChartView(
                    simulations: simulations,
                    medianLine: medianLine
                )
            }
            .padding(.horizontal)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
