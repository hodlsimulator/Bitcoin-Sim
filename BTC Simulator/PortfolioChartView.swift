//
//  PortfolioChartView.swift
//  BTCMonteCarlo
//
//  Created by . . on 05/01/2025.
//

import SwiftUI
import Charts

struct PortfolioChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    // We'll conditionally "squish" the chart in portrait
    private var verticalScale: CGFloat {
        orientationObserver.isLandscape ? 1.0 : 0.92
    }
    
    var body: some View {
        // 1) Safely unwrap portfolioRuns:
        let simulations = chartDataCache.portfolioRuns ?? []
        
        // 2) Flatten all runs’ points => find min & max
        let allPoints = simulations.flatMap { $0.points }
        let decimalValues = allPoints.map { $0.value }
        
        // 3) Convert to Double, clamp invalid
        var rawMin = decimalValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        var rawMax = decimalValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        if !rawMin.isFinite || rawMin <= 0 { rawMin = 1.0 }
        if !rawMax.isFinite || rawMax <= 0 { rawMax = rawMin + 1.0 }
        
        // 4) Build log domain
        var bottomExp = floor(log10(rawMin))
        var topExp    = floor(log10(rawMax))
        if rawMax >= pow(10.0, topExp) {
            topExp += 1
        }
        let domainMin = max(pow(10.0, bottomExp), 1.0)
        let domainMax = pow(10.0, topExp)
        // Ensure domainMax > domainMin
        let finalDomainMax = max(domainMax, domainMin + 1.0)
        
        // 5) Build power-of-ten tick marks on Y axis
        let intBottom = Int(floor(log10(domainMin)))
        let intTop    = Int(floor(log10(finalDomainMax)))
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        // 6) Convert userPeriods => total years
        let totalUnits = Double(simSettings.userPeriods)
        let totalYears: Double = (simSettings.periodUnit == .weeks)
            ? totalUnits / 52.0
            : totalUnits / 12.0
        
        // 7) Decide X stride
        let xStride = dynamicXStride(for: totalYears)
        
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Chart {
                        // Multi-run lines
                        simulationLines(simulations: simulations, simSettings: simSettings)
                        
                        // If you want a highlight line for median, do below:
                        medianLines(simulations: simulations, simSettings: simSettings)
                        
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: domainMin...finalDomainMax, type: .log)
                    
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
                    
                    // X-axis => show months if totalYears <= 2, else years
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
                    // Slightly squash in portrait, anchored at bottom
                    .scaleEffect(x: 1.0, y: verticalScale, anchor: .bottom)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .navigationBarHidden(false)
    }
}


// MARK: - Logic for color picking
private func colorForIndex(_ idx: Int) -> Color {
    let hue = Double(idx % 12) / 12.0
    return Color(hue: hue, saturation: 0.8, brightness: 0.85)
}

// MARK: - A stride for X
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
