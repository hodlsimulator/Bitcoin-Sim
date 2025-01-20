//
//  PortfolioChartView.swift
//  BTCMonteCarlo
//
//  Created by Conor on ...
//

import SwiftUI
import Charts

/// This chart is nearly identical to the BTC one, but uses `portfolioValue` data.
/// It includes dynamic X and Y logic, clamps invalid values, and shows a best‐fit line
/// which gets darker and thicker as the iteration count grows.
struct PortfolioChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    // We'll squash it slightly in portrait
    private var scaleY: CGFloat {
        orientationObserver.isLandscape ? 1.0 : 0.92
    }
    
    var body: some View {
        let isLandscape = orientationObserver.isLandscape
        
        // 1) Grab all portfolio runs
        let simulations = chartDataCache.portfolioRuns ?? []
        
        // 2) Grab the best‐fit run (if any)
        let bestFit = chartDataCache.bestFitPortfolioRun?.first
        
        // Filter out the best‐fit so it’s drawn only once
        let normalSimulations = simulations.filter { $0.id != bestFit?.id }
        
        // Flatten to find min & max among all runs
        let allValues = simulations.flatMap { $0.points.map(\.value) }
        var rawMin = allValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        var rawMax = allValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        // Clamp invalid or non‐positive values so log10 won't crash
        if !rawMin.isFinite || rawMin <= 0 { rawMin = 1.0 }
        if !rawMax.isFinite || rawMax <= 0 { rawMax = rawMin + 1.0 }
        
        // Build log domain
        var bottomExp = floor(log10(rawMin))
        var topExp = floor(log10(rawMax))
        if rawMax >= pow(10.0, topExp) {
            topExp += 1
        }
        
        let domainMin = pow(10.0, bottomExp)
        let domainMax = pow(10.0, topExp)
        
        // Ensure at least 1.0 at the bottom, and at least a +1 range
        let finalDomainMin = max(1.0, domainMin)
        let finalDomainMax = max(finalDomainMin + 1.0, domainMax)
        
        // Build power‐of‐ten tick marks for Y
        let intBottom = Int(floor(log10(finalDomainMin)))
        let intTop    = Int(floor(log10(finalDomainMax)))
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        // Convert userPeriods => total years
        let totalUnits = Double(simSettings.userPeriods)
        let totalYears = (simSettings.periodUnit == .weeks)
            ? totalUnits / 52.0
            : totalUnits / 12.0
        
        // Decide an X-axis stride
        let xStride = dynamicXStride(for: totalYears)
        
        // We'll use normalSimulations.count + 1 to figure out how many runs exist
        // so we can scale the best‐fit line's thickness/brightness appropriately.
        let iterationCount = normalSimulations.count + 1
        
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Chart {
                        // 1) The “spaghetti” lines
                        simulationLines(simulations: normalSimulations, simSettings: simSettings)
                        
                        // 2) Optionally remove median lines if desired
                        // medianLines(simulations: normalSimulations, simSettings: simSettings)
                        
                        // 3) Overlaid bold best‐fit line (thickens/darkens with iterationCount)
                        if let bestFitRun = bestFit {
                            bestFitLine(
                                bestFitRun,
                                simSettings: simSettings,
                                iterationCount: iterationCount
                            )
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: finalDomainMin...finalDomainMax, type: .log)
                    .chartPlotStyle { plotArea in
                        plotArea
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
                                    Text(formatPowerOfTenLabel(exponent))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    
                    // X-axis => months if <=2 years, else years
                    .chartXAxis {
                        AxisMarks(values: Array(stride(from: 0.0, through: totalYears, by: xStride))) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let dblVal = axisValue.as(Double.self), dblVal > 0 {
                                    if totalYears <= 2.0 {
                                        Text("\(Int(dblVal * 12))M")
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(Int(dblVal))Y")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Slightly squash vertically if in portrait
                    .scaleEffect(x: 1.0, y: scaleY, anchor: .bottom)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .navigationBarHidden(false)
    }
}

// MARK: - Choose an X-axis stride
private func dynamicXStride(for totalYears: Double) -> Double {
    switch totalYears {
    case ..<1.01:
        return 0.25
    case ..<2.01:
        return 0.5
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
