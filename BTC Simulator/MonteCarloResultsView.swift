//
//  MonteCarloResultsView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 30/12/2024.
//

import SwiftUI

// In MonteCarloResultsView, add a property for the closure and use it:
struct MonteCarloResultsView: View {
    // Closure passed down from the parent that tells us how to switch to Portfolio.
    let onSwitchToPortfolio: () -> Void

    @EnvironmentObject var simChartSelection: SimChartSelection
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var idleManager: IdleManager
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    @State private var showMetalChart = true

    var body: some View {
        ZStack {
            if showMetalChart {
                InteractiveMonteCarloChartView(
                    onSwitchToPortfolio: {
                        // Call the closure we got from the parent
                        onSwitchToPortfolio()
                    }
                )
                .environmentObject(simSettings)
                .environmentObject(chartDataCache)
                .environmentObject(simChartSelection)
                .environmentObject(idleManager)
                .environmentObject(coordinator)
            } else {
                Text("Fallback Chart")
                    .foregroundColor(.white)
                    .background(Color.black.ignoresSafeArea())
            }
        }
    }
}

// MARK: - formatPowerOfTenLabel(...)
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
