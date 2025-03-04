//
//  TestHarnessView.swift
//  BTCMonteCarlo
//
//  Created by . . on 04/03/2025.
//

#if DEBUG
import SwiftUI

/// A SwiftUI view that creates minimal/fake data and shows the chart in a test harness.
/// Include this in your project, then navigate to it in Debug mode or replace your main content.
struct TestHarnessView: View {

    // Create the environment objects the chart expects:
    @StateObject private var chartDataCache = ChartDataCache()
    @StateObject private var simSettings = SimulationSettings()
    @StateObject private var idleManager = IdleManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Chart Test Harness")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(.top)

                // The actual chart, referencing your real SwiftUI chart view
                InteractiveMonteCarloChartView()
                    // Provide environment objects:
                    .environmentObject(chartDataCache)
                    .environmentObject(simSettings)
                    .environmentObject(idleManager)
            }
        }
        .onAppear {
            setupFakeData()
        }
    }

    /// Builds some fake data and puts it in chartDataCache
    private func setupFakeData() {
        // Example with three WeekPoints
        let samplePoints = [
            WeekPoint(week: 0,  value: Decimal(100)),
            WeekPoint(week: 10, value: Decimal(120)),
            WeekPoint(week: 20, value: Decimal(180))
        ]
        // 1) Create a single SimulationRun with a UUID for the id
        let fakeRun = SimulationRun(id: UUID(), points: samplePoints)

        // 2) Put it in the cache
        chartDataCache.allRuns = [fakeRun]

        // 3) Also mark it as the best fit
        chartDataCache.bestFitRun = [fakeRun]

        // If your chart or sim settings need anything else, set it up here
        // e.g. simSettings.periodUnit = .weeks
    }
}
#endif
