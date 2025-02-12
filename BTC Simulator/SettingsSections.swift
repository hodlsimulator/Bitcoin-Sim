//
//  SettingsSections.swift
//  BTCMonteCarlo
//
//  Created by ... on 27/01/2025.
//

import SwiftUI

// A simple namespace struct
struct SettingsSections { }

extension SettingsSections {
    // MARK: - Toggle All Section
    static func toggleAllSection(
        simSettings: SimulationSettings,
        monthlySimSettings: MonthlySimulationSettings
    ) -> some View {
        Section {
            Toggle("Toggle All Factors", isOn:
                Binding<Bool>(
                    get: {
                        if monthlySimSettings.periodUnitMonthly == .months {
                            return monthlySimSettings.toggleAllMonthly
                        } else {
                            return simSettings.toggleAll
                        }
                    },
                    set: { newValue in
                        if monthlySimSettings.periodUnitMonthly == .months {
                            // Monthly path
                            monthlySimSettings.userIsActuallyTogglingAllMonthly = true
                            monthlySimSettings.toggleAllMonthly = newValue
                            monthlySimSettings.toggleAllFactorsMonthly(on: newValue)
                            if newValue {
                                monthlySimSettings.chartExtremeBearishMonthly = false
                                monthlySimSettings.chartExtremeBullishMonthly = false
                                monthlySimSettings.lockedFactorsMonthly.removeAll()
                            }
                        } else {
                            // Weekly path
                            simSettings.userIsActuallyTogglingAll = true
                            simSettings.toggleAll = newValue
                            simSettings.toggleAllFactors(on: newValue)
                            if newValue {
                                simSettings.chartExtremeBearish = false
                                simSettings.chartExtremeBullish = false
                                simSettings.lockedFactors.removeAll()
                            }
                        }
                    }
                )
            )
            .tint(.orange)
            .foregroundColor(.white)
        } footer: {
            Text("Switches ON or OFF all bullish/bearish factors.")
                .foregroundColor(.white)
        }
        .listRowBackground(Color(white: 0.15))
    }
}

extension SettingsView {
    func logistic(_ x: Double, steepness: Double, midpoint: Double) -> Double {
        1.0 / (1.0 + exp(-steepness * (x - midpoint)))
    }

    // -------------------------------------------------------
    // MARK: - A custom Binding for factorIntensity
    // -------------------------------------------------------
    private var factorIntensityBinding: Binding<Double> {
        Binding(
            get: {
                simSettings.getFactorIntensity()
            },
            set: { newVal in
                simSettings.setFactorIntensity(newVal)
                simSettings.syncFactorsToGlobalIntensity()
            }
        )
    }

    // -------------------------------------------------------
    // MARK: - Tilt Bar
    // -------------------------------------------------------
    var overallTiltSection: some View {
        Section {
            HStack {
                GeometryReader { geo in
                    let effectiveTilt = displayedTilt
                    let absTilt = abs(effectiveTilt)
                    let barWidth = geo.size.width
                    let computedWidth = barWidth * absTilt

                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        // Green bar for positive tilt
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: effectiveTilt > 0 ? computedWidth : 0, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: effectiveTilt)
                        
                        // Red bar for negative tilt
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: effectiveTilt < 0 ? computedWidth : 0, height: 8)
                            .offset(x: effectiveTilt < 0 ? (barWidth - computedWidth) : barWidth)
                            .animation(.easeInOut(duration: 0.3), value: effectiveTilt)
                    }
                }
                .frame(height: 8)
            }
        } footer: {
            Text("Green if bullish factors dominate, red if bearish factors dominate.")
                .foregroundColor(.white)
        }
        .listRowBackground(Color(white: 0.15))
    }

    // -------------------------------------------------------
    // MARK: - Universal Factor Intensity
    // -------------------------------------------------------
    var factorIntensitySection: some View {
            // Instead of the old chunk of Button/Slider code, just do:
        FactorIntensitySection(
                simSettings: simSettings,
                monthlySimSettings: monthlySimSettings,
                displayedTilt: displayedTilt,
                bullishKeys: bullishKeys,
                bearishKeys: bearishKeys,
                isManualOverride: $isManualOverride,
                lockFactorAtMin: lockFactorAtMin,
                lockFactorAtMax: lockFactorAtMax,
                unlockFactorAndSetMin: unlockFactorAndSetMin,
                unlockFactorAndSetMax: unlockFactorAndSetMax
            )
        }

    // MARK: - Helper Functions for Locking/Unlocking Factors
    func lockFactorAtMin(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.minValue
        let base = simSettings.globalBaseline(for: f)
        let range = f.maxValue - f.minValue
        f.internalOffset = (f.minValue - base) / range
        f.wasChartForced = true
        f.isEnabled = false
        f.isLocked = true
        simSettings.lockedFactors.insert(factorName)
        simSettings.factors[factorName] = f
    }

    func lockFactorAtMax(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.maxValue
        let base = simSettings.globalBaseline(for: f)
        let range = f.maxValue - f.minValue
        f.internalOffset = (f.maxValue - base) / range
        f.wasChartForced = true
        f.isEnabled = false
        f.isLocked = true
        simSettings.lockedFactors.insert(factorName)
        simSettings.factors[factorName] = f
    }

    func unlockFactorAndSetMin(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.minValue
        let base = simSettings.globalBaseline(for: f)
        let range = f.maxValue - f.minValue
        f.internalOffset = (f.minValue - base) / range
        f.wasChartForced = true
        f.isEnabled = true
        f.isLocked = false
        simSettings.lockedFactors.remove(factorName)
        simSettings.factors[factorName] = f
    }

    func unlockFactorAndSetMax(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.maxValue
        let base = simSettings.globalBaseline(for: f)
        let range = f.maxValue - f.minValue
        f.internalOffset = (f.maxValue - base) / range
        f.wasChartForced = true
        f.isEnabled = true
        f.isLocked = false
        simSettings.lockedFactors.remove(factorName)
        simSettings.factors[factorName] = f
    }

    // MARK: - Restore Defaults
    /*
    var restoreDefaultsSection: some View {
        Section {
            Button(action: {
                print("simSettings.periodUnit = \(simSettings.periodUnit)")
                if simSettings.periodUnit == .weeks {
                    print("Restoring weekly defaults")
                    simSettings.restoreDefaults()
                    simSettings.saveToUserDefaults()
                } else {
                    print("Restoring monthly defaults")
                    monthlySimSettings.restoreDefaultsMonthly()
                    monthlySimSettings.saveToUserDefaultsMonthly()
                }
            }) {
                HStack {    
                    Text("Restore Defaults")
                        .foregroundColor(.red)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(Color(white: 0.15))
    }
    */

    // MARK: - About
    var aboutSection: some View {
        Section {
            NavigationLink("About") {
                AboutView()
            }
        }
        .listRowBackground(Color(white: 0.15))
    }

    // MARK: - Reset All Criteria
    var resetCriteriaSection: some View {
        Section(footer: Text("Resetting all criteria will revert your custom settings to default and restart onboarding.")
                    .foregroundColor(.white)
                    .font(.footnote)
        ) {
            Button(action: {
                showResetCriteriaConfirmation = true
            }) {
                HStack {
                    Text("Reset All Criteria")
                        .foregroundColor(.red)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableDestructiveButtonStyle())
            .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation, actions: {
                Button("Reset", role: .destructive) {
                    if simSettings.periodUnit == .weeks {
                        simSettings.restoreDefaults()
                    } else {
                        monthlySimSettings.restoreDefaultsMonthly(whenIn: .months)
                    }
                    didFinishOnboarding = false
                    simSettings.setFactorIntensity(0.5)
                    simSettings.tiltBarValue = 0.0
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("This will restore default settings and restart onboarding. Proceed?")
            })
        }
        .listRowBackground(Color(white: 0.15))
    }
}
