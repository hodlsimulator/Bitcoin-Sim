//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI
import Charts
import Combine
import Foundation
import UIKit

// MARK: - Data Models

struct WeekPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Decimal
}

struct SimulationRun: Identifiable {
    let id = UUID()
    let points: [WeekPoint]
}

// MARK: - SquishedLandscapePlaceholderView

struct SquishedLandscapePlaceholderView: View {
    let image: UIImage
    
    var body: some View {
        GeometryReader { geo in
            let scaleX: CGFloat = 1.25
            let scaleY: CGFloat = 1.10
            
            let newWidth = geo.size.width * scaleX
            let newHeight = geo.size.height * scaleY
            let xOffset = (geo.size.width - newWidth) / 2
            
            Image(uiImage: image)
                .resizable()
                .frame(width: newWidth, height: newHeight, alignment: .top)
                .offset(x: xOffset, y: 0)
        }
        .ignoresSafeArea()
    }
}

// MARK: - SnapshotView

struct SnapshotView: View {
    let snapshot: UIImage
    
    var body: some View {
        Image(uiImage: snapshot)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .padding(.bottom, 90)
            .ignoresSafeArea(edges: .top)
    }
}

// MARK: - squishPortraitImage

func squishPortraitImage(_ portraitImage: UIImage) -> UIImage {
    let targetSize = CGSize(width: 800, height: 400)
    let scaleFactorX: CGFloat = 1.25
    let scaleFactorY: CGFloat = 1.05
    
    let scaledWidth = targetSize.width * scaleFactorX
    let scaledHeight = targetSize.height * scaleFactorY
    let xOffset = (targetSize.width - scaledWidth) / 2
    let yOffset: CGFloat = 0
    
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    return renderer.image { _ in
        portraitImage.draw(
            in: CGRect(
                x: xOffset,
                y: yOffset,
                width: scaledWidth,
                height: scaledHeight
            )
        )
    }
}

// MARK: - ChartType

enum ChartType {
    case btcPrice
    case cumulativePortfolio
}

// MARK: - MonteCarloChartView (Static)

struct MonteCarloChartView: View {
    @EnvironmentObject var orientationObserver: OrientationObserver
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    
    var verticalScale: CGFloat {
        orientationObserver.isLandscape ? 1.0 : 0.92
    }
    
    var body: some View {
        let simulations = chartDataCache.allRuns ?? []
        let bestFit = chartDataCache.bestFitRun?.first
        
        let normalSimulations = simulations.filter { $0.id != bestFit?.id }
        let allPoints = simulations.flatMap { $0.points }
        let decimalValues = allPoints.map { $0.value }
        
        let minVal = decimalValues.min().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 1.0
        let maxVal = decimalValues.max().map { NSDecimalNumber(decimal: $0).doubleValue } ?? 2.0
        
        // Build log-scale domain
        var bottomExp = floor(log10(minVal))
        if minVal <= pow(10, bottomExp), bottomExp > 0 {
            bottomExp -= 1
        }
        let domainMin = max(pow(10.0, bottomExp), 1.0)
        
        var topExp = floor(log10(maxVal))
        if maxVal >= pow(10.0, topExp) {
            topExp += 1
        }
        let domainMax = pow(10.0, topExp)
        
        let intBottom = Int(bottomExp)
        let intTop    = Int(topExp)
        let yTickValues = (intBottom...intTop).map { pow(10.0, Double($0)) }
        
        let totalPeriods = Double(simSettings.userPeriods)
        let totalYears = (simSettings.periodUnit == .weeks)
            ? totalPeriods / 52.0
            : totalPeriods / 12.0
        
        func dynamicXStride(_ yrs: Double) -> Double {
            switch yrs {
            case ..<1.01:  return 0.25
            case ..<2.01:  return 0.5
            case ..<5.01:  return 1.0
            case ..<10.01: return 2.0
            case ..<25.01: return 5.0
            case ..<50.01: return 10.0
            default:       return 25.0
            }
        }
        let xStride = dynamicXStride(totalYears)
        
        let iterationCount = normalSimulations.count + 1
        let xAxisStrideValues = Array(stride(from: 0.0, through: totalYears, by: xStride))
        
        return GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Chart {
                        // Faint lines for normal runs
                        simulationLines(simulations: normalSimulations, simSettings: simSettings)
                        
                        // Bold orange best-fit
                        if let bestFitRun = bestFit {
                            bestFitLine(bestFitRun, simSettings: simSettings, iterationCount: iterationCount)
                        }
                    }
                    .chartLegend(.hidden)
                    .chartXScale(domain: 0.0...totalYears, type: .linear)
                    .chartYScale(domain: domainMin...domainMax, type: .log)
                    .chartPlotStyle { plotArea in
                        plotArea
                            .padding(.horizontal, 0)
                            .padding(.vertical, 10)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: yTickValues) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                if let dblVal = axisValue.as(Double.self) {
                                    let exponent = Int(log10(dblVal))
                                    Text(formatPowerOfTenLabel(exponent))
                                        .foregroundColor(.white)
                                } else {
                                    Text("")
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: xAxisStrideValues) { axisValue in
                            AxisGridLine().foregroundStyle(.white.opacity(0.3))
                            AxisTick().foregroundStyle(.white.opacity(0.3))
                            AxisValueLabel {
                                Text(xAxisLabel(for: axisValue, totalYears: totalYears))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .padding(.top, orientationObserver.isLandscape ? 20 : 0)
                .scaleEffect(x: 1.0, y: verticalScale, anchor: .bottom)
            }
        }
    }
    
    func xAxisLabel(for axisValue: AxisValue, totalYears: Double) -> String {
        if let dblVal = axisValue.as(Double.self), dblVal > 0 {
            if totalYears <= 2.0 {
                return "\(Int(dblVal * 12))M"
            } else {
                return "\(Int(dblVal))Y"
            }
        } else {
            return ""
        }
    }
}

// MARK: - MonteCarloResultsView

struct MonteCarloResultsView: View {
    @EnvironmentObject var simChartSelection: SimChartSelection
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @State private var showMetalChart = true  // Toggle for Metal chart
    
    var body: some View {
        ZStack {
            if showMetalChart {
                InteractiveMonteCarloChartView()
                    .environmentObject(simSettings)
                    .environmentObject(chartDataCache)
                    .environmentObject(simSettings)
            } else {
                // Fallback to regular chart view if needed
            }
        }
    }
}

// MARK: - formatPowerOfTenLabel

func formatPowerOfTenLabel(_ exponent: Int) -> String {
    switch exponent {
    case 0:  return "1"
    case 1:  return "10"
    case 2:  return "100"
    case 3:  return "1K"
    case 4:  return "10K"
    case 5:  return "100K"
    case 6:  return "1M"
    case 7:  return "10M"
    case 8:  return "100M"
    case 9:  return "1B"
    case 10: return "10B"
    case 11: return "100B"
    case 12: return "1T"
    case 13: return "10T"
    case 14: return "100T"
    case 15: return "1Q"
    case 16: return "10Q"
    case 17: return "100Q"
    case 18: return "1Qn"
    case 19: return "10Qn"
    case 20: return "100Qn"
    case 21: return "1Se"
    default:
        return "10^\(exponent)"
    }
}

// MARK: - ForceReflowView

struct ForceReflowView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    @State private var orientationID = UUID()
    
    var body: some View {
        content
            .id(orientationID)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIDevice.orientationDidChangeNotification
                )
            ) { _ in
                orientationID = UUID()
            }
    }
}

// MARK: - Helpers for drawing lines

func convertWeeksToYears(_ week: Int, simSettings: SimulationSettings) -> Double {
    if simSettings.periodUnit == .weeks {
        return Double(week) / 52.0
    } else {
        return Double(week) / 12.0
    }
}
