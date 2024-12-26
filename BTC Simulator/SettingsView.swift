//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

// A SwiftUI view displaying these settings in a Form (or List).
//    Each Toggle is bound to a property in SimulationSettings via $settings.propertyName.
struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings   // or rename 'simSettings' to 'settings'

    var body: some View {
        NavigationView {
            Form {
                // Bullish section
                Section("Bullish Factors") {
                    Toggle("Halving", isOn: $simSettings.useHalving)
                    Toggle("Institutional Demand", isOn: $simSettings.useInstitutionalDemand)
                    Toggle("Country Adoption", isOn: $simSettings.useCountryAdoption)
                    Toggle("Regulatory Clarity", isOn: $simSettings.useRegulatoryClarity)
                    Toggle("ETF Approval", isOn: $simSettings.useEtfApproval)
                    Toggle("Tech Breakthrough", isOn: $simSettings.useTechBreakthrough)
                    Toggle("Scarcity Events", isOn: $simSettings.useScarcityEvents)
                    Toggle("Global Macro Hedge", isOn: $simSettings.useGlobalMacroHedge)
                    Toggle("Stablecoin Shift", isOn: $simSettings.useStablecoinShift)
                    Toggle("Demographic Adoption", isOn: $simSettings.useDemographicAdoption)
                    Toggle("Altcoin Flight", isOn: $simSettings.useAltcoinFlight)
                    Toggle("Adoption Factor (Incremental Drift)", isOn: $simSettings.useAdoptionFactor)
                    
                    // Example slider for halvingBump
                    VStack(alignment: .leading) {
                        Text("Halving Bump: \(simSettings.halvingBump, specifier: "%.2f")")
                        Slider(value: $simSettings.halvingBump, in: 0.0...1.0, step: 0.01)
                    }
                    
                    // Another slider example
                    VStack(alignment: .leading) {
                        Text("Max Demand Boost: \(simSettings.maxDemandBoost, specifier: "%.4f")")
                        Slider(value: $simSettings.maxDemandBoost, in: 0.0...0.01, step: 0.0001)
                    }
                }
                
                // Bearish section
                Section("Bearish Factors") {
                    Toggle("Regulatory Clampdown", isOn: $simSettings.useRegClampdown)
                    Toggle("Competitor Coin", isOn: $simSettings.useCompetitorCoin)
                    Toggle("Security Breach", isOn: $simSettings.useSecurityBreach)
                    Toggle("Bubble Pop", isOn: $simSettings.useBubblePop)
                    Toggle("Stablecoin Meltdown", isOn: $simSettings.useStablecoinMeltdown)
                    Toggle("Black Swan Events", isOn: $simSettings.useBlackSwan)
                    Toggle("Bear Market Conditions", isOn: $simSettings.useBearMarket)
                    Toggle("Declining ARR / Maturing Market", isOn: $simSettings.useMaturingMarket)
                    Toggle("Recession / Macro Crash", isOn: $simSettings.useRecession)
                }
            }
            .navigationTitle("Simulation Settings")
        }
    }
}

// 3) Example usage: You might provide this SimulationSettings object
//    as an EnvironmentObject or pass it into your simulation function.
    
// 4) Brief explanation of passing toggles into your simulator:
//
// In your MonteCarloSimulator.swift, remove the old `private let useInstitutionalDemand = true` etc.
// Then, when calling runOneFullSimulation, pass the simSettings (or store it globally).
// For example:
//
// func runOneFullSimulation(settings: SimulationSettings, ... ) -> [SimulationData] {
//     // Then replace any references to `useInstitutionalDemand` with `settings.useInstitutionalDemand`
//
//     var combinedWeeklyReturn = dampenedReturn + baseWeeklyGrowth
//
//     // If the user toggles 'useInstitutionalDemand' on in the SettingsView, it will be true here.
//     if settings.useInstitutionalDemand {
//         // ... apply your Institutional Demand logic
//     }
//
//     // ... same idea for your other toggles ...
//
//     return ...
// }
//
// By using an ObservableObject with @Published properties, the toggles automatically stay in sync
// across your app. Whenever a toggle is flipped, SwiftUI updates the property, and you can rerun
// your simulation code if needed.
