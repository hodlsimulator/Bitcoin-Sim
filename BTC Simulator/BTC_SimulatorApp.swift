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
        // Load your CSVs here
        // loadAllHistoricalData()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(simSettings) // Provide simSettings to all subviews
        }
    }
}
