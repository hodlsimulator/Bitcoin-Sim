//
//  PortfolioChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/01/2025.
//

import SwiftUI
import Charts

/// This chart is nearly identical to the BTC one, but uses `portfolioValueEUR` data.
/// It now includes dynamic X and Y logic, while clamping invalid values to avoid crashes.
struct PortfolioChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    /// Vertical "squish" factor (1.0 = no squish)
    private let scaleY: CGFloat = 0.92

    var body: some View {
        let isLandscape = orientationObserver.isLandscape

        // 1) Grab the portfolio runs
        let simulations = chartDataCache.portfolioRuns ?? []
        let allValues = simulations.flatMap { $0.points.map(\.value) }

        // 2) Convert all min & max to Double
        var rawMin = allValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        var rawMax = allValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0

        // 3) Clamp any invalid or non-positive values so log10 won't crash
        if !rawMin.isFinite || rawMin <= 0 {
            rawMin = 1.0
        }
        if !rawMax.isFinite || rawMax <= 0 {
            rawMax = rawMin + 1.0
        }

        // 4) Compute log-based domain bounds
        var bottomExp = floor(log10(rawMin))
        var topExp    = floor(log10(rawMax))
        if rawMax >= pow(10.0, topExp) {
            topExp += 1
        }

        // 5) Construct the domain from powers of ten
        let domainMin = pow(10.0, bottomExp)
        let domainMax = pow(10.0, topExp)

        // If you want at least 1.0 for the bottom:
        let finalDomainMin = max(1.0, domainMin)
        // Ensure we have at least some range
        let finalDomainMax = max(finalDomainMin + 1.0, domainMax)

        // 6) Build power-of-ten tick marks for Y
        let intBottom = Int(floor(log10(finalDomainMin)))
        let intTop    = Int(floor(log10(finalDomainMax)))
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }

        // 7) Convert weeks -> years for X scale & choose stride
        let totalWeeks = Double(simSettings.userWeeks)
        let totalYears = totalWeeks / 52.0
        let xStride = dynamicXStride(for: totalYears)

        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Chart {
                        // Below calls rely on your existing helper functions
                        // (simulationLines, medianLines) — don't redeclare them here.
                        simulationLines(simulations: simulations)
                        medianLines(simulations: simulations)
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: finalDomainMin...finalDomainMax, type: .log)

                    .chartPlotStyle { plotArea in
                        plotArea
                            // Extra padding so data doesn’t overlap x-axis
                            .padding(.top, 0)
                            .padding(.bottom, 20)
                    }

                    // Y-axis => powers of ten
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yTickValues) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let dblVal = axisValue.as(Double.self) {
                                    let exponent = Int(log10(dblVal))
                                    // formatPowerOfTenLabel is also presumably declared elsewhere
                                    Text(formatPowerOfTenLabel(exponent))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }

                    // X-axis => months/years
                    .chartXAxis {
                        AxisMarks(values: Array(stride(from: 0.0, through: totalYears, by: xStride))) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let dblVal = axisValue.as(Double.self), dblVal > 0 {
                                    // For short time spans, show months
                                    if totalYears <= 2.0 {
                                        Text("\(Int(dblVal * 12))M")
                                            .foregroundColor(.white)
                                    } else {
                                        // For longer, show years
                                        Text("\(Int(dblVal))Y")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }

                    // Slightly squash vertically, anchored at bottom
                    .scaleEffect(x: 1.0, y: scaleY, anchor: .bottom)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .navigationBarHidden(false)
    }
}

// MARK: - Helper for choosing an X-axis stride
/// Avoid too many X ticks by picking a decent stride.
private func dynamicXStride(for totalYears: Double) -> Double {
    switch totalYears {
    case ..<1.01:
        return 0.25 // ~3-month intervals
    case ..<2.01:
        return 0.5  // ~6-month intervals
    case ..<5.01:
        return 1.0
    case ..<10.01:
        return 2.0
    case ..<25.01:
        return 5.0
    case ..<50.01:
        return 10.0
    default:
        return 25.0
    }
}
