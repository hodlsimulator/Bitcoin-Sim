//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on ... 2024.
//

import SwiftUI
import Charts

/// A simple model for each year’s simulation data.
struct YearlyPercentileData: Identifiable {
    let id = UUID()
    let year: Int
    let tenth: Double
    let median: Double
    let ninetieth: Double
}

/// A sleek results screen showing a line chart with an error band (10th–90th)
/// plus a scrolling list of stacked year “cards.”
struct MonteCarloResultsView: View {
    
    // Replace this with your actual simulation data
    let data: [YearlyPercentileData]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // Title above the chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("BTC Price Over 20 Years")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    
                    // MARK: - The Chart (with log scale)
                    chartSection
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                )
                .padding(.horizontal)
                
                // MARK: - The Yearly Cards
                yearCardsSection
                    .padding(.bottom, 40)
            }
        }
        .background(
            // A dark gradient backdrop (similar to your main screen)
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationBarTitle("Monte Carlo Results", displayMode: .inline)
    }
    
    // MARK: - The Chart (using log10 to avoid flat lines)
    @ViewBuilder
    private var chartSection: some View {
        Chart {
            // ---- Error Band (Area) ----
            ForEach(data) { item in
                let yearValue       = item.year
                let logTenth        = log10(max(item.tenth, 1))       // Avoid log10(0)
                let logNinetieth    = log10(max(item.ninetieth, 1))
                
                AreaMark(
                    x: .value("Year", yearValue),
                    yStart: .value("10th (log)", logTenth),
                    yEnd: .value("90th (log)", logNinetieth)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [
                            Color.orange.opacity(0.2),
                            Color.orange.opacity(0.01)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            
            // ---- Median Line ----
            ForEach(data) { item in
                let yearValue    = item.year
                let logMedian    = log10(max(item.median, 1))
                
                LineMark(
                    x: .value("Year", yearValue),
                    y: .value("Median (log)", logMedian)
                )
                .foregroundStyle(.orange)
                .interpolationMethod(.cardinal)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
            
            // ---- Optional Points on the Median ----
            ForEach(data) { item in
                let yearValue   = item.year
                let logMedian   = log10(max(item.median, 1))
                
                PointMark(
                    x: .value("Year", yearValue),
                    y: .value("Median (log)", logMedian)
                )
                .foregroundStyle(.orange)
                .symbolSize(30)
            }
        }
        .frame(height: 300)
        .chartXAxis {
            // Year labels
            AxisMarks(values: .stride(by: 1)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { axisValue in
                // Convert back from log to normal for display labels, if you want
                if let doubleValue = axisValue.as(Double.self) {
                    let exponent = pow(10, doubleValue)
                    AxisGridLine()
                    AxisTick()
                    // Format exponent as a short number:
                    AxisValueLabel {
                        Text(exponent.formatted(.number.precision(.fractionLength(0))))
                    }
                }
            }
        }
    }
    
    // MARK: - The Yearly Cards
    @ViewBuilder
    private var yearCardsSection: some View {
        VStack(spacing: 20) {
            ForEach(data) { item in
                // One "card" per year
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.15))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Year \(item.year)")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("10th:")
                                    .foregroundColor(.gray)
                                Text("\(item.tenth, format: .number.precision(.fractionLength(2)))")
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Median:")
                                    .foregroundColor(.gray)
                                Text("\(item.median, format: .number.precision(.fractionLength(2)))")
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("90th:")
                                    .foregroundColor(.gray)
                                Text("\(item.ninetieth, format: .number.precision(.fractionLength(2)))")
                                    .foregroundColor(.white)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                }
                .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview
struct MonteCarloResultsView_Previews: PreviewProvider {
    
    static let sampleData: [YearlyPercentileData] = [
        .init(year: 1,  tenth: 1.7e5,  median: 1.16e5,   ninetieth: 1.76e5),
        .init(year: 2,  tenth: 4486,   median: 6.38e5,   ninetieth: 1.98e5),
        .init(year: 3,  tenth: 1316,   median: 1.46e6,   ninetieth: 1.52e6),
        .init(year: 4,  tenth: 2000,   median: 3.00e6,   ninetieth: 3.50e7),
        .init(year: 5,  tenth: 1.2e4,  median: 1.80e7,   ninetieth: 3.00e9),
        // etc.
    ]
    
    static var previews: some View {
        NavigationStack {
            MonteCarloResultsView(data: sampleData)
        }
        .preferredColorScheme(.dark)
    }
}
