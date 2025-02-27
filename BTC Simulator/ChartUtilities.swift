//
//  ChartUtilities.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import SwiftUI
import Charts

/// Renders a best-fit line for a simulation run on a chart.
func bestFitLine(
    _ run: SimulationRun,
    simSettings: SimulationSettings,
    iterationCount: Int
) -> some ChartContent {
    // Clamp iterationCount to [70..700] for styling purposes
    let clamped = max(70, min(iterationCount, 700))
    let fraction = Double(clamped - 70) / Double(700 - 70)
    
    // Adjust brightness from 1.0 (bright) to 0.65 (darker) based on iteration count
    let minBrightness: CGFloat = 1.0
    let maxDarkBrightness: CGFloat = 0.65
    let dynamicBrightness = minBrightness - fraction * (minBrightness - maxDarkBrightness)
    
    // Adjust line thickness from 2.0 to 4.0 based on iteration count
    let minWidth: CGFloat = 2.0
    let maxWidth: CGFloat = 4.0
    let lineWidth = minWidth + fraction * (maxWidth - minWidth)
    
    return ForEach(run.points) { pt in
        LineMark(
            x: .value("Year", convertPeriodToYears(pt.week, simSettings)),
            y: .value("Value", NSDecimalNumber(decimal: pt.value).doubleValue)
        )
        .foregroundStyle(
            Color(hue: 0.08, saturation: 1.0, brightness: dynamicBrightness)
        )
        .lineStyle(
            StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }
}
