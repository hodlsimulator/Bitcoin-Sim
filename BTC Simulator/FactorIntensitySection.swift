//
//  FactorIntensitySection.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI

/// A reusable view showing the Extreme Bearish/Bullish buttons + main slider,
/// automatically handling either weekly simSettings or monthlySimSettings.
struct FactorIntensitySection: View {
    @ObservedObject var simSettings: SimulationSettings
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    
    /// The value we use to draw the green/red bar in the background (e.g. displayedTilt).
    let displayedTilt: Double
    
    /// Which factors are bullish and which are bearish.
    let bullishKeys: [String]
    let bearishKeys: [String]

    /// A binding controlling whether we've manually overridden the tilt.
    @Binding var isManualOverride: Bool

    /// Functions for locking/unlocking factors at min or max for weekly usage.
    let lockFactorAtMin: (String) -> Void
    let lockFactorAtMax: (String) -> Void
    let unlockFactorAndSetMin: (String) -> Void
    let unlockFactorAndSetMax: (String) -> Void

    /// A combined slider binding that decides if we're in monthly or weekly mode.
    private var factorIntensityBinding: Binding<Double> {
        Binding(
            get: {
                if monthlySimSettings.periodUnitMonthly == .months {
                    return monthlySimSettings.factorIntensityMonthlyComputed
                } else {
                    return simSettings.getFactorIntensity()
                }
            },
            set: { newVal in
                if monthlySimSettings.periodUnitMonthly == .months {
                    monthlySimSettings.factorIntensityMonthlyComputed = newVal
                } else {
                    simSettings.setFactorIntensity(newVal)
                    simSettings.syncFactorsToGlobalIntensity()
                }
            }
        )
    }

    var body: some View {
        Section {
            HStack {
                // ------------------------------------------------
                // EXTREME BEARISH BUTTON
                // ------------------------------------------------
                Button {
                    if monthlySimSettings.periodUnitMonthly == .months {
                        // --- MONTHLY mode ---
                        if monthlySimSettings.chartExtremeBearishMonthly {
                            // Switch OFF extreme-bearish
                            monthlySimSettings.chartExtremeBearishMonthly = false
                            monthlySimSettings.recalcTiltBarValueMonthly(
                                bullishKeys: bullishKeys,
                                bearishKeys: bearishKeys
                            )
                            // monthlySimSettings.applyDictionaryFactorsToSimMonthly()
                        } else {
                            // Switch ON extreme-bearish
                            isManualOverride = true
                            monthlySimSettings.setFactorIntensityMonthly(0.0)
                            monthlySimSettings.tiltBarValueMonthly = -1.0
                            
                            // Turn OFF all bullish; lock them at MIN
                            for key in bullishKeys {
                                monthlySimSettings.setFactorEnabledMonthly(factorName: key, enabled: false)
                                monthlySimSettings.lockFactorAtMinMonthly(key)
                            }
                            // Turn ON all bearish; unlock them at MIN
                            for key in bearishKeys {
                                monthlySimSettings.setFactorEnabledMonthly(factorName: key, enabled: true)
                                monthlySimSettings.unlockFactorAndSetMinMonthly(key)
                            }
                            
                            monthlySimSettings.chartExtremeBearishMonthly = true
                            monthlySimSettings.chartExtremeBullishMonthly = false
                            monthlySimSettings.recalcTiltBarValueMonthly(
                                bullishKeys: bullishKeys,
                                bearishKeys: bearishKeys
                            )
                            // monthlySimSettings.applyDictionaryFactorsToSimMonthly()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isManualOverride = false
                            }
                        }
                    } else {
                        // --- WEEKLY mode ---
                        if simSettings.chartExtremeBearish {
                            // Switch OFF extreme-bearish
                            simSettings.chartExtremeBearish = false
                            simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                            simSettings.applyDictionaryFactorsToSim()
                        } else {
                            // Switch ON extreme-bearish
                            isManualOverride = true
                            simSettings.setFactorIntensity(0.0)
                            simSettings.tiltBarValue = -1.0
                            
                            // Turn OFF all bullish; lock at MIN
                            for key in bullishKeys {
                                simSettings.setFactorEnabled(factorName: key, enabled: false)
                                lockFactorAtMin(key)
                            }
                            // Turn ON all bearish; unlock at MIN
                            for key in bearishKeys {
                                simSettings.setFactorEnabled(factorName: key, enabled: true)
                                unlockFactorAndSetMin(key)
                            }
                            
                            simSettings.chartExtremeBearish = true
                            simSettings.chartExtremeBullish = false
                            simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                            simSettings.applyDictionaryFactorsToSim()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isManualOverride = false
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .disabled(
                    (monthlySimSettings.periodUnitMonthly == .months
                     ? (monthlySimSettings.chartExtremeBearishMonthly && factorIntensityBinding.wrappedValue <= 0.0001)
                     : (simSettings.chartExtremeBearish && factorIntensityBinding.wrappedValue <= 0.0001))
                )
                .opacity(
                    (monthlySimSettings.periodUnitMonthly == .months
                     ? (monthlySimSettings.chartExtremeBearishMonthly && factorIntensityBinding.wrappedValue <= 0.0001)
                     : (simSettings.chartExtremeBearish && factorIntensityBinding.wrappedValue <= 0.0001))
                    ? 0.5
                    : 1.0
                )

                // ------------------------------------------------
                // MAIN INTENSITY SLIDER
                // ------------------------------------------------
                Slider(
                    value: factorIntensityBinding,
                    in: 0...1,
                    step: 0.01
                )
                .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                .disabled(
                    monthlySimSettings.periodUnitMonthly == .months
                    ? lockedAllMonthly()
                    : simSettings.isGlobalSliderDisabled
                )
                .onChange(of: factorIntensityBinding.wrappedValue) { _ in
                    if monthlySimSettings.periodUnitMonthly == .months {
                        monthlySimSettings.recalcTiltBarValueMonthly(
                            bullishKeys: bullishKeys,
                            bearishKeys: bearishKeys
                        )
                        // monthlySimSettings.applyDictionaryFactorsToSimMonthly()
                    } else {
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                        simSettings.applyDictionaryFactorsToSim()
                    }
                }

                // ------------------------------------------------
                // EXTREME BULLISH BUTTON
                // ------------------------------------------------
                Button {
                    if monthlySimSettings.periodUnitMonthly == .months {
                        // --- MONTHLY mode ---
                        if monthlySimSettings.chartExtremeBullishMonthly {
                            // Switch OFF extreme-bullish
                            monthlySimSettings.chartExtremeBullishMonthly = false
                            monthlySimSettings.recalcTiltBarValueMonthly(
                                bullishKeys: bullishKeys,
                                bearishKeys: bearishKeys
                            )
                            // monthlySimSettings.applyDictionaryFactorsToSimMonthly()
                        } else {
                            // Switch ON extreme-bullish
                            isManualOverride = true
                            monthlySimSettings.setFactorIntensityMonthly(1.0)
                            monthlySimSettings.tiltBarValueMonthly = 1.0
                            
                            // Turn OFF all bearish; lock them at MAX
                            for key in bearishKeys {
                                monthlySimSettings.setFactorEnabledMonthly(factorName: key, enabled: false)
                                monthlySimSettings.lockFactorAtMaxMonthly(key)
                            }
                            // Turn ON all bullish; unlock at MAX
                            for key in bullishKeys {
                                monthlySimSettings.setFactorEnabledMonthly(factorName: key, enabled: true)
                                monthlySimSettings.unlockFactorAndSetMaxMonthly(key)
                            }
                            
                            monthlySimSettings.chartExtremeBullishMonthly = true
                            monthlySimSettings.chartExtremeBearishMonthly = false
                            monthlySimSettings.recalcTiltBarValueMonthly(
                                bullishKeys: bullishKeys,
                                bearishKeys: bearishKeys
                            )
                            //  monthlySimSettings.applyDictionaryFactorsToSimMonthly()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isManualOverride = false
                            }
                        }
                    } else {
                        // --- WEEKLY mode ---
                        if simSettings.chartExtremeBullish {
                            // Switch OFF extreme-bullish
                            simSettings.chartExtremeBullish = false
                            simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                            simSettings.applyDictionaryFactorsToSim()
                        } else {
                            // Switch ON extreme-bullish
                            isManualOverride = true
                            simSettings.setFactorIntensity(1.0)
                            simSettings.tiltBarValue = 1.0
                            
                            // Turn OFF all bearish; lock at MAX
                            for key in bearishKeys {
                                simSettings.setFactorEnabled(factorName: key, enabled: false)
                                lockFactorAtMax(key)
                            }
                            // Turn ON all bullish; unlock at MAX
                            for key in bullishKeys {
                                simSettings.setFactorEnabled(factorName: key, enabled: true)
                                unlockFactorAndSetMax(key)
                            }
                            
                            simSettings.chartExtremeBullish = true
                            simSettings.chartExtremeBearish = false
                            simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                            simSettings.applyDictionaryFactorsToSim()

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isManualOverride = false
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .disabled(
                    (monthlySimSettings.periodUnitMonthly == .months
                     ? (monthlySimSettings.chartExtremeBullishMonthly && factorIntensityBinding.wrappedValue >= 0.9999)
                     : (simSettings.chartExtremeBullish && factorIntensityBinding.wrappedValue >= 0.9999))
                )
                .opacity(
                    (monthlySimSettings.periodUnitMonthly == .months
                     ? (monthlySimSettings.chartExtremeBullishMonthly && factorIntensityBinding.wrappedValue >= 0.9999)
                     : (simSettings.chartExtremeBullish && factorIntensityBinding.wrappedValue >= 0.9999))
                    ? 0.5
                    : 1.0
                )
            }
        } footer: {
            Text("Press a chart icon to force extreme factor settings.")
                .foregroundColor(.white)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    /// Helper that returns true if **all** monthly factors are locked/disabled,
    /// so we disable the main slider in monthly mode.
    private func lockedAllMonthly() -> Bool {
        // If every factor is locked or not enabled, there is nothing to slide.
        let allLockedOrDisabled = monthlySimSettings.factorsMonthly.values.allSatisfy {
            !$0.isEnabled || $0.isLocked
        }
        return allLockedOrDisabled
    }
}
