//
//  BTC_SimulatorApp.swift
//  BTC Simulator
//
//  Created by . . on 28/11/2024.
//

import SwiftUI

@main
struct BTCMoteCarloApp: App {
    @StateObject private var simSettings = SimulationSettings()
    
    init() {
        // Load your CSVs here if needed
        // loadAllHistoricalData()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                // Your main ContentView or root view
                ContentView()
            }
            // Provide SimulationSettings to all child views in the NavigationStack
            .environmentObject(simSettings)
        }
    }
}
