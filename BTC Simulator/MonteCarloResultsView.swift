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
                    
                    // MARK: - The Chart
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
    
    // MARK: - The Chart
    @ViewBuilder
    private var chartSection: some View {
        Chart {
            // ---- Error Band (Area) ----
            ForEach(data) { item in
                let yearValue = item.year
                let yStart = item.tenth
                let yEnd = item.ninetieth
                
                AreaMark(
                    x: .value("Year", yearValue),
                    yStart: .value("10th", yStart),
                    yEnd: .value("90th", yEnd)
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
                let yearValue = item.year
                let medianValue = item.median
                
                LineMark(
                    x: .value("Year", yearValue),
                    y: .value("Median", medianValue)
                )
                .foregroundStyle(.orange)
                .interpolationMethod(.cardinal)
                .lineStyle(StrokeStyle(lineWidth: 3))
            }
            
            // ---- Optional Points on the Median ----
            ForEach(data) { item in
                let yearValue = item.year
                let medianValue = item.median
                
                PointMark(
                    x: .value("Year", yearValue),
                    y: .value("Median", medianValue)
                )
                .foregroundStyle(.orange)
                .symbolSize(30)
            }
        }
        .frame(height: 300)
        .chartXAxis {
            AxisMarks(values: .stride(by: 1)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel() // default text
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
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
        .init(year: 1,  tenth: 10000, median: 15000, ninetieth: 30000),
        .init(year: 2,  tenth: 11000, median: 17000, ninetieth: 34000),
        .init(year: 3,  tenth: 13000, median: 20000, ninetieth: 45000),
        .init(year: 4,  tenth: 15000, median: 25000, ninetieth: 60000),
        .init(year: 5,  tenth: 18000, median: 30000, ninetieth: 72000),
        .init(year: 6,  tenth: 21000, median: 35000, ninetieth: 90000),
        .init(year: 7,  tenth: 25000, median: 42000, ninetieth: 110000),
        .init(year: 8,  tenth: 28000, median: 50000, ninetieth: 130000),
        .init(year: 9,  tenth: 32000, median: 56000, ninetieth: 150000),
        .init(year: 10, tenth: 37000, median: 62000, ninetieth: 180000),
        .init(year: 11, tenth: 42000, median: 69000, ninetieth: 210000),
        .init(year: 12, tenth: 50000, median: 78000, ninetieth: 250000),
        .init(year: 13, tenth: 54000, median: 85000, ninetieth: 300000),
        .init(year: 14, tenth: 59000, median: 95000, ninetieth: 350000),
        .init(year: 15, tenth: 65000, median: 110000, ninetieth: 420000),
        .init(year: 16, tenth: 70000, median: 130000, ninetieth: 480000),
        .init(year: 17, tenth: 78000, median: 150000, ninetieth: 600000),
        .init(year: 18, tenth: 85000, median: 170000, ninetieth: 750000),
        .init(year: 19, tenth: 95000, median: 200000, ninetieth: 900000),
        .init(year: 20, tenth: 110000, median: 250000, ninetieth: 1200000),
    ]
    
    static var previews: some View {
        NavigationStack {
            MonteCarloResultsView(data: sampleData)
        }
        .preferredColorScheme(.dark)
    }
}
