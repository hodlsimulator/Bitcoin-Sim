//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI
import Charts

// MARK: - Data Models

/// Simple struct representing a single data point:
///  - `week` is your integer week number.
///  - `value` is the numeric data you want to plot.
struct WeekPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Double
}

/// One entire simulation run, containing multiple WeekPoint instances.
struct SimulationRun: Identifiable {
    let id = UUID()
    let points: [WeekPoint]
}

// MARK: - Main View

/// A SwiftUI chart that draws:
///  - Many faint orange lines for each simulation in `simulations`
///  - One bold blue line for the “original” run in `originalRun`
///  - Uses a **log scale** on the Y-axis
///  - Week numbers on the X-axis
struct MonteCarloResultsView: View {
    
    /// The “original” single run, displayed as a bold line
    let originalRun: [WeekPoint]
    
    /// Multiple simulations, each drawn as faint lines
    let simulations: [SimulationRun]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // Title + Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("BTC Price Over 20 Years")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    // The Chart (all marks inline, no separate sub-ViewBuilders)
                    Chart {
                        // 1) Faint lines for each simulation
                        ForEach(simulations) { sim in
                            ForEach(sim.points) { pt in
                                LineMark(
                                    x: .value("Week", pt.week),
                                    y: .value("Value", pt.value)
                                )
                                .foregroundStyle(.orange.opacity(0.2))
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                .interpolationMethod(.monotone)
                            }
                        }
                        
                        // 2) Bold line for the original run
                        ForEach(originalRun) { pt in
                            LineMark(
                                x: .value("Week", pt.week),
                                y: .value("Value", pt.value)
                            )
                            .foregroundStyle(.blue)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.monotone)
                        }
                    }
                    .frame(height: 350)
                    // Log scale on Y
                    .chartYScale(domain: .automatic(includesZero: false), type: .log)
                    // Mark X-axis weeks 10, 20, 30, ...
                    .chartXAxis {
                        AxisMarks(values: Array(stride(from: 10, through: 520, by: 10))) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    // Standard Y-axis on the left
                    .chartYAxis {
                        AxisMarks(position: .leading) { axisValue in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.2))
                    )
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}
