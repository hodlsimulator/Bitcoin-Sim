//
//  AdvancedSettingsSection.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import SwiftUI

struct AdvancedSettingsSection: View {
    @EnvironmentObject var simSettings: SimulationSettings
    @Binding var showAdvancedSettings: Bool

    @AppStorage("advancedSettingsUnlocked") var advancedSettingsUnlocked: Bool = false
    @State private var showUnlockAlert = false

    var body: some View {
        Section {
            // Header row with two separate buttons.
            HStack {
                Button(action: {
                    withAnimation {
                        showAdvancedSettings.toggle()
                    }
                }) {
                    HStack {
                        Text("Advanced Settings")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: showAdvancedSettings ? "chevron.down" : "chevron.forward")
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle()) // Only applies to this button.
                }
                .buttonStyle(.plain)
                
                // Lock icon only shows if the feature is locked.
                if !advancedSettingsUnlocked {
                    Button(action: {
                        showUnlockAlert = true
                    }) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
            .alert(isPresented: $showUnlockAlert) {
                Alert(
                    title: Text("Unlock Advanced Settings"),
                    message: Text("Do you want to unlock advanced settings for £0.99?"),
                    primaryButton: .default(Text("Unlock"), action: {
                        purchaseAdvancedSettings()
                    }),
                    secondaryButton: .cancel()
                )
            }
            
            // Collapsible advanced settings content.
            if showAdvancedSettings {
                Group {
                    // RANDOM SEED Section
                    Section {
                        Toggle("Lock Random Seed", isOn: $simSettings.lockedRandomSeed)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .onChange(of: simSettings.lockedRandomSeed) { _ in
                                if simSettings.lockedRandomSeed {
                                    let newSeed = UInt64.random(in: 0..<UInt64.max)
                                    simSettings.seedValue = newSeed
                                    simSettings.useRandomSeed = false
                                } else {
                                    simSettings.seedValue = 0
                                    simSettings.useRandomSeed = true
                                }
                            }
                        
                        if simSettings.lockedRandomSeed {
                            Text("Current Seed (Locked): \(simSettings.seedValue)")
                                .font(.footnote)
                                .foregroundColor(.white)
                        } else {
                            if simSettings.lastUsedSeed == 0 {
                                Text("Current Seed: (no run yet)")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            } else {
                                Text("Current Seed (Unlocked): \(simSettings.lastUsedSeed)")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("Locking this seed ensures consistent simulation results every run. Unlock for new randomness.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("RANDOM SEED")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Growth Model Section
                    Section {
                        Toggle("Use Lognormal Growth", isOn: $simSettings.useLognormalGrowth)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .onChange(of: simSettings.useLognormalGrowth) { _ in
                                simSettings.useAnnualStep = !simSettings.useLognormalGrowth
                            }
                        
                        Text("Uses a lognormal model for Bitcoin’s price distribution. Uncheck to use an alternative approach (annual step).")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Growth Model")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Historical Sampling Section
                    Section {
                        Toggle("Use Historical Sampling", isOn: $simSettings.useHistoricalSampling)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .onChange(of: simSettings.useHistoricalSampling) { newValue in
                                if !newValue {
                                    simSettings.useExtendedHistoricalSampling = false
                                }
                            }
                        Toggle("Use Extended Historical Sampling", isOn: $simSettings.useExtendedHistoricalSampling)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .disabled(!simSettings.useHistoricalSampling)
                        Toggle("Lock Historical Sampling", isOn: $simSettings.lockHistoricalSampling)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Pulls contiguous historical blocks from BTC + S&P data, preserving volatility clustering. Lock it to avoid random draws.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Historical Sampling")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Autocorrelation Section
                    Section {
                        Toggle("Use Autocorrelation", isOn: $simSettings.useAutoCorrelation)
                            .tint(simSettings.useAutoCorrelation ? .orange : .gray)
                            .foregroundColor(.white)
                        
                        HStack {
                            Button {
                                simSettings.autoCorrelationStrength = 0.05
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                            
                            Text("Autocorrelation Strength")
                                .foregroundColor(.white)
                            
                            Slider(
                                value: $simSettings.autoCorrelationStrength,
                                in: 0.01...0.09,
                                step: 0.01
                            )
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        }
                        .disabled(!simSettings.useAutoCorrelation)
                        .opacity(simSettings.useAutoCorrelation ? 1.0 : 0.4)
                        
                        HStack {
                            Button {
                                simSettings.meanReversionTarget = 0.03
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                            
                            Text("Mean Reversion Target")
                                .foregroundColor(.white)
                            
                            Slider(
                                value: $simSettings.meanReversionTarget,
                                in: 0.01...0.05,
                                step: 0.001
                            )
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        }
                        .disabled(!simSettings.useAutoCorrelation)
                        .opacity(simSettings.useAutoCorrelation ? 1.0 : 0.4)
                        
                        Text("Autocorrelation makes returns partially follow their previous trend, while mean reversion nudges them back toward a target.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Autocorrelation")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Volatility Section
                    Section {
                        Toggle("Use Volatility Shocks", isOn: $simSettings.useVolShocks)
                            .tint(.orange)
                            .foregroundColor(.white)
                        Toggle("Use GARCH Volatility", isOn: $simSettings.useGarchVolatility)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Volatility Shocks can randomly spike or dampen volatility. GARCH models let volatility evolve based on recent price moves.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Volatility")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Regime Switching Section
                    Section {
                        Toggle("Use Regime Switching", isOn: $simSettings.useRegimeSwitching)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Dynamically shifts between bull, bear, and hype states using a Markov chain to create more realistic cyclical patterns.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Regime Switching")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                }
                .disabled(!advancedSettingsUnlocked)
                .opacity(advancedSettingsUnlocked ? 1.0 : 0.5)
            }
        }
        .listRowBackground(Color(white: 0.15))
    }

    func purchaseAdvancedSettings() {
        // Replace with your StoreKit in-app purchase logic.
        advancedSettingsUnlocked = true
    }
}
