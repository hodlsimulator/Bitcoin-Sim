//
//  PortfolioChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/01/2025.
//

import SwiftUI
import Charts

/// This chart is nearly identical to the BTC one, but uses `portfolioValueEUR` data.
struct PortfolioChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    
    var body: some View {
        let isLandscape = orientationObserver.isLandscape
        
        // Pull the portfolio runs from the cache
        let simulations = chartDataCache.portfolioRuns ?? []
        
        Group {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if isLandscape {
                        // LANDSCAPE LAYOUT
                        ZStack {
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
                            // Make the chart 10% wider; anchor right
                            .frame(width: geo.size.width * 1.1, height: geo.size.height)
                            .offset(x: -(geo.size.width * 0.04))
                            .scaleEffect(x: 1.0, y: 0.98, anchor: .bottom)
                        }
                    } else {
                        // PORTRAIT LAYOUT
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
                            // Slight vertical squish, pinned at bottom
                            .scaleEffect(x: 1.0, y: 0.95, anchor: .bottom)
                            .frame(width: geo.size.width, height: geo.size.height * 0.94)

                            Spacer().frame(height: 10)
                        }
                    }
                }
            }
            .onAppear {
                // Debug printing the portfolio runs
                let count = simulations.count
                print("// DEBUG: PortfolioChartView => simulations count = \(count)")
                for (idx, run) in simulations.prefix(2).enumerated() {
                    if !run.points.isEmpty {
                        let snippet = run.points.prefix(2).map { "week=\($0.week), val=\($0.value)" }
                        print("// DEBUG: [\(idx)] sample => \(snippet.joined(separator: " | "))")
                    } else {
                        print("// DEBUG: [\(idx)] run => no points")
                    }
                }
            }
        }
        .navigationBarHidden(false)
    }
}

// MARK: - Local median line calculator
private func computeMedianLine(for runs: [SimulationRun]) -> [WeekPoint] {
    guard let firstRun = runs.first else { return [] }
    let weeksCount = firstRun.points.count
    var result: [WeekPoint] = []
    
    for w in 0..<weeksCount {
        let allValuesAtW = runs.compactMap { run -> Decimal? in
            guard w < run.points.count else { return nil }
            return run.points[w].value
        }
        if allValuesAtW.isEmpty { continue }
        
        let sortedVals = allValuesAtW.sorted()
        let mid = sortedVals.count / 2
        let median: Decimal
        if sortedVals.count.isMultiple(of: 2) {
            median = (sortedVals[mid] + sortedVals[mid - 1]) / Decimal(2)
        } else {
            median = sortedVals[mid]
        }
        
        result.append(WeekPoint(
            week: firstRun.points[w].week,
            value: median
        ))
    }
    return result
}
