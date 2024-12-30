//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI
import Charts

// MARK: - Data Models

/// A single data point (e.g. for a single “week” & numeric “value”).
struct WeekPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Double
}

/// One simulation run, containing multiple WeekPoints.
struct SimulationRun: Identifiable {
    let id = UUID()
    let points: [WeekPoint]
}

// MARK: - Median Calculation

func computeMedianLine(simulations: [SimulationRun]) -> [WeekPoint] {
    // If no simulations, return empty
    guard let firstRun = simulations.first else { return [] }
    let countPerRun = firstRun.points.count
    var medianPoints: [WeekPoint] = []
    
    for index in 0..<countPerRun {
        let week = firstRun.points[index].week
        // Gather the value at this index from every simulation
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

// MARK: - Number Formatting (10k, 1M, 1B)

func formatSuffix(_ value: Double) -> String {
    let absVal = abs(value)
    let sign = value < 0 ? "-" : ""
    
    switch absVal {
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
    ForEach(simulations) { sim in
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Week", pt.week),
                y: .value("Value", pt.value)
            )
            .foregroundStyle(by: .value("Simulation", sim.id.uuidString))
            .opacity(0.2)
            .interpolationMethod(.monotone)
            .lineStyle(StrokeStyle(lineWidth: 0.1))
        }
    }
}

@ChartContentBuilder
func medianLines(_ medianLine: [WeekPoint]) -> some ChartContent {
    ForEach(medianLine) { pt in
        LineMark(
            x: .value("Week", pt.week),
            y: .value("Value", pt.value)
        )
        .foregroundStyle(.black)
        .lineStyle(StrokeStyle(lineWidth: 3))
        .interpolationMethod(.monotone)
    }
}

// MARK: - The Chart Sub-View

struct MonteCarloChartView: View {
    let simulations: [SimulationRun]
    let medianLine: [WeekPoint]
    
    var body: some View {
        Chart {
            simulationLines(simulations: simulations)
            medianLines(medianLine)
        }
        .chartLegend(.hidden)  // Hide the giant legend
        .frame(height: 350)
        // Use a log scale on the Y-axis
        .chartYScale(domain: .automatic(includesZero: false), type: .log)
        // Custom X-axis ticks: 10, 20, ... 520
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 10, through: 520, by: 10))) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        // Custom Y-axis suffix labels
        .chartYAxis {
            AxisMarks(position: .leading) { axisValue in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let val = axisValue.as(Double.self) {
                        Text(formatSuffix(val)).foregroundColor(.white)
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
    let simulations: [SimulationRun] // Called from ContentView
    
    var body: some View {
        let medianLine = computeMedianLine(simulations: simulations)
        
        ScrollView {
            VStack(spacing: 20) {
                Text("Cumulative Returns of Monte Carlo Simulations")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                
                // Subview for the Swift Charts
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
