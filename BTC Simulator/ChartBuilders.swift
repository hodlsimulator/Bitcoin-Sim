//
//  ChartBuilders.swift
//  BTCMonteCarlo
//
//  Created by . . on 10/01/2025.
//

import SwiftUI
import Charts

@ChartContentBuilder
func simulationLines(
    simulations: [SimulationRun],
    simSettings: SimulationSettings
) -> some ChartContent {
    let customPalette: [Color] = [
        // Near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        Color(hue: 0.33, saturation: 0.05, brightness: 1.0), // Slight greenish-white
        Color(hue: 0.66, saturation: 0.05, brightness: 1.0), // Slight bluish-white
        Color(hue: 0.83, saturation: 0.05, brightness: 1.0), // Slight purplish-white

        // More near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white

        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        
        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        
        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white
        
        // Extra near-white
        Color(hue: 0.00, saturation: 0.00, brightness: 1.0), // Pure white
        Color(hue: 0.10, saturation: 0.05, brightness: 1.0), // Warm off-white

        // **New bright pastel colours**
        Color(hue: 0.56, saturation: 0.65, brightness: 1.0), // Pastel teal
        Color(hue: 0.33, saturation: 0.65, brightness: 1.0), // Pastel green
        Color(hue: 0.83, saturation: 0.65, brightness: 1.0), // Pastel purple
        Color(hue: 0.95, saturation: 0.65, brightness: 1.0), // Pastel pink
        Color(hue: 0.58, saturation: 0.65, brightness: 1.0), // Pastel aqua

        // Strong reds/oranges
        Color(hue: 0.0000, saturation: 0.8, brightness: 1.0), // Red
        Color(hue: 0.0167, saturation: 0.8, brightness: 1.0), // Reddish-Orange
        Color(hue: 0.0333, saturation: 0.8, brightness: 1.0), // Orange
        Color(hue: 0.0500, saturation: 0.8, brightness: 1.0), // Soft Orange
        Color(hue: 0.0667, saturation: 0.8, brightness: 1.0), // Golden Yellow
        Color(hue: 0.0833, saturation: 0.8, brightness: 1.0), // Yellow-Gold
        Color(hue: 0.1000, saturation: 0.8, brightness: 1.0), // Light Yellow
        Color(hue: 0.1167, saturation: 0.6, brightness: 1.0), // Pale Yellow
        Color(hue: 0.1333, saturation: 0.4, brightness: 1.0), // Lime Yellow
        Color(hue: 0.1500, saturation: 0.8, brightness: 1.0), // Warm Yellow
        Color(hue: 0.1667, saturation: 0.8, brightness: 1.0), // Pure Yellow
        Color(hue: 0.1833, saturation: 0.8, brightness: 1.0), // Yellow-Green
        Color(hue: 0.2000, saturation: 0.6, brightness: 1.0), // Light Yellow-Green
        Color(hue: 0.2167, saturation: 0.8, brightness: 1.0), // Pastel Green
        Color(hue: 0.2333, saturation: 0.6, brightness: 1.0), // Soft Green
        Color(hue: 0.2500, saturation: 0.6, brightness: 1.0), // Spring Green
        
        // Extra strong reds/oranges
        Color(hue: 0.0000, saturation: 0.6, brightness: 1.0), // Red
        Color(hue: 0.0167, saturation: 0.6, brightness: 1.0), // Reddish-Orange
        Color(hue: 0.0333, saturation: 0.6, brightness: 1.0), // Orange
        Color(hue: 0.0500, saturation: 0.6, brightness: 1.0), // Soft Orange
        Color(hue: 0.0667, saturation: 0.6, brightness: 1.0), // Golden Yellow
        Color(hue: 0.0833, saturation: 0.6, brightness: 1.0), // Yellow-Gold
        Color(hue: 0.1000, saturation: 0.6, brightness: 1.0), // Light Yellow
        Color(hue: 0.1167, saturation: 0.6, brightness: 1.0), // Pale Yellow
        Color(hue: 0.1333, saturation: 0.4, brightness: 1.0), // Lime Yellow
        Color(hue: 0.1500, saturation: 0.6, brightness: 1.0), // Warm Yellow
        Color(hue: 0.1667, saturation: 0.6, brightness: 1.0), // Pure Yellow
        Color(hue: 0.1833, saturation: 0.6, brightness: 1.0), // Yellow-Green
        Color(hue: 0.2000, saturation: 0.6, brightness: 1.0), // Light Yellow-Green
        Color(hue: 0.2167, saturation: 0.6, brightness: 1.0), // Pastel Green
        Color(hue: 0.2333, saturation: 0.6, brightness: 1.0), // Soft Green
        Color(hue: 0.2500, saturation: 0.6, brightness: 1.0), // Spring Green

        // Commented-out greens/cyans
        // Color(hue: 0.2667, saturation: 0.6, brightness: 1.0), // Green
        // Color(hue: 0.2833, saturation: 0.6, brightness: 1.0), // Sea Green
        // Color(hue: 0.3000, saturation: 0.6, brightness: 1.0), // Greenish-Cyan
        // Color(hue: 0.3167, saturation: 0.6, brightness: 1.0), // Cyan-Green
        // Color(hue: 0.3333, saturation: 0.6, brightness: 1.0), // Cyanish-Green
        // Color(hue: 0.3500, saturation: 0.6, brightness: 1.0), // Soft Turquoise

        Color(hue: 0.3667, saturation: 0.6, brightness: 1.0), // Turquoise
        Color(hue: 0.3833, saturation: 0.6, brightness: 1.0), // Teal
        Color(hue: 0.4000, saturation: 0.6, brightness: 1.0), // Blue-Teal
        Color(hue: 0.4167, saturation: 0.6, brightness: 1.0), // Light Aqua
        Color(hue: 0.4333, saturation: 0.6, brightness: 1.0), // Aqua

        // Commented-out aquas/blues
        // Color(hue: 0.4500, saturation: 0.6, brightness: 1.0), // Soft Aqua
        // Color(hue: 0.4667, saturation: 0.6, brightness: 1.0), // Pale Aqua
        // Color(hue: 0.4833, saturation: 0.6, brightness: 1.0), // Greenish-Blue
        
        // Blues
        Color(hue: 0.5000, saturation: 0.8, brightness: 1.0), // Cyan
        Color(hue: 0.5167, saturation: 0.8, brightness: 1.0), // Soft Cyan
        Color(hue: 0.5333, saturation: 0.8, brightness: 1.0), // Light Teal
        Color(hue: 0.5500, saturation: 0.6, brightness: 1.0), // Pale Turquoise
        Color(hue: 0.5667, saturation: 0.6, brightness: 1.0), // Bluish-Turquoise
        Color(hue: 0.5833, saturation: 0.8, brightness: 1.0), // Light Blue
        Color(hue: 0.6000, saturation: 0.8, brightness: 1.0), // Sky Blue
        Color(hue: 0.6167, saturation: 0.8, brightness: 1.0), // Soft Sky Blue
        Color(hue: 0.6333, saturation: 0.8, brightness: 1.0), // Medium Blue
        Color(hue: 0.6500, saturation: 0.8, brightness: 1.0), // Blue
        Color(hue: 0.6667, saturation: 0.8, brightness: 1.0), // True Blue
        // Color(hue: 0.6833, saturation: 0.6, brightness: 1.0), // Indigo-Blue
        
        // Extra blues
        Color(hue: 0.5000, saturation: 0.8, brightness: 1.0), // Cyan
        Color(hue: 0.5167, saturation: 0.8, brightness: 1.0), // Soft Cyan
        Color(hue: 0.5333, saturation: 0.8, brightness: 1.0), // Light Teal
        Color(hue: 0.5500, saturation: 0.6, brightness: 1.0), // Pale Turquoise
        Color(hue: 0.5667, saturation: 0.6, brightness: 1.0), // Bluish-Turquoise
        Color(hue: 0.5833, saturation: 0.8, brightness: 1.0), // Light Blue
        Color(hue: 0.6000, saturation: 0.8, brightness: 1.0), // Sky Blue
        Color(hue: 0.6167, saturation: 0.8, brightness: 1.0), // Soft Sky Blue
        Color(hue: 0.6333, saturation: 0.8, brightness: 1.0), // Medium Blue
        Color(hue: 0.6500, saturation: 0.8, brightness: 1.0), // Blue
        Color(hue: 0.6667, saturation: 0.8, brightness: 1.0), // True Blue
        // Color(hue: 0.6833, saturation: 0.6, brightness: 1.0), // Indigo-Blue

        // Commented-out purples/indigos
        // Color(hue: 0.7000, saturation: 0.6, brightness: 1.0), // Indigo
        // Color(hue: 0.7167, saturation: 0.6, brightness: 1.0), // Soft Indigo
        // Color(hue: 0.7333, saturation: 0.6, brightness: 1.0), // Periwinkle
        // Color(hue: 0.7500, saturation: 0.6, brightness: 1.0), // Purple
        // Color(hue: 0.7667, saturation: 0.6, brightness: 1.0), // Violet
        // Color(hue: 0.7833, saturation: 0.6, brightness: 1.0), // Lavender
        // Color(hue: 0.8000, saturation: 0.6, brightness: 1.0), // Light Purple
        // Color(hue: 0.8167, saturation: 0.6, brightness: 1.0), // Soft Magenta
        // Color(hue: 0.8333, saturation: 0.6, brightness: 1.0), // Magenta
        // Color(hue: 0.8500, saturation: 0.6, brightness: 1.0), // Pinkish-Magenta

        // Pinks/reds
        Color(hue: 0.8667, saturation: 0.8, brightness: 1.0), // Pink
        Color(hue: 0.8833, saturation: 0.6, brightness: 1.0), // Soft Pink
        Color(hue: 0.9000, saturation: 0.6, brightness: 1.0), // Light Pink
        Color(hue: 0.9167, saturation: 0.6, brightness: 1.0), // Pinkish-Red
        Color(hue: 0.9333, saturation: 0.8, brightness: 1.0), // Light Red
        Color(hue: 0.9500, saturation: 0.8, brightness: 1.0), // Pale Red
        Color(hue: 0.9667, saturation: 0.8, brightness: 1.0), // Reddish-Pink
        Color(hue: 0.9833, saturation: 0.8, brightness: 1.0)  // Very Pale Red
    ]
    
    return ForEach(simulations.indices, id: \.self) { index in
        let sim = simulations[index]
        // Use modulo so we can safely index into the palette no matter how many simulations
        let colour = customPalette[index % customPalette.count]
        
        ForEach(sim.points) { pt in
            LineMark(
                x: .value("Year", convertPeriodToYears(pt.week, simSettings)),
                y: .value("Value", NSDecimalNumber(decimal: pt.value).doubleValue)
            )
            .foregroundStyle(colour.opacity(0.3))
            .foregroundStyle(by: .value("SeriesIndex", index))
            .lineStyle(
                StrokeStyle(
                    lineWidth: 0.5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
    }
}

@ChartContentBuilder
func medianLines(
    simulations: [SimulationRun],
    simSettings: SimulationSettings
) -> some ChartContent {
    let medianLine = computeMedianLine(simulations)
    
    // 1) Figure out how many total runs we have (70..1000).
    let iterationCount = simulations.count
    let clamped = max(70, min(iterationCount, 1000))
    
    // 2) fraction goes from 0.0 (at 70) up to 1.0 (at 1000).
    let fraction = Double(clamped - 70) / Double(1000 - 70)
    
    // 3) Keep the orange line at full opacity (1.0),
    //    but reduce brightness from 1.0 down to 0.6
    let minBrightness: CGFloat = 1.0
    let maxDarkBrightness: CGFloat = 0.6
    let dynamicBrightness = minBrightness - fraction * (minBrightness - maxDarkBrightness)
    
    // 4) Also thicken line from 1.5 up to 3.0
    let minWidth: CGFloat = 1.5
    let maxWidth: CGFloat = 3.0
    let lineWidth = minWidth + fraction * (maxWidth - minWidth)
    
    // 5) Build the median line with dynamic brightness & thickness
    return ForEach(medianLine) { pt in
        LineMark(
            x: .value("Year", convertPeriodToYears(pt.week, simSettings)),
            y: .value("Value", NSDecimalNumber(decimal: pt.value).doubleValue)
        )
        .foregroundStyle(
            // Hue ~0.08 is an orange-ish hue, saturate around 0.9
            Color(hue: 0.08, saturation: 0.9, brightness: dynamicBrightness)
        )
        .interpolationMethod(.monotone)
        .lineStyle(
            StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round
            )
        )
    }
}

func computeMedianLine(_ simulations: [SimulationRun]) -> [WeekPoint] {
    guard let firstRun = simulations.first else { return [] }
    let countPerRun = firstRun.points.count
    
    var medianPoints: [WeekPoint] = []
    
    for index in 0..<countPerRun {
        let allValues = simulations.compactMap { run -> Decimal? in
            guard index < run.points.count else { return nil }
            return run.points[index].value
        }
        if allValues.isEmpty { continue }
        
        let sortedVals = allValues.sorted(by: <)
        let mid = sortedVals.count / 2
        let median: Decimal
        if sortedVals.count.isMultiple(of: 2) {
            let sum = sortedVals[mid] + sortedVals[mid - 1]
            median = sum / Decimal(2)
        } else {
            median = sortedVals[mid]
        }
        
        let week = firstRun.points[index].week
        medianPoints.append(WeekPoint(week: week, value: median))
    }
    return medianPoints
}

/// Conditionally divides by 52 if user selected `.weeks`, or 12 if user selected `.months`.
func convertPeriodToYears(
    _ periodIndex: Int,
    _ simSettings: SimulationSettings
) -> Double {
    if simSettings.periodUnit == .weeks {
        return Double(periodIndex) / 52.0
    } else {
        return Double(periodIndex) / 12.0
    }
}
    
