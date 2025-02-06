//
//  SettingsSections.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {

    func logistic(_ x: Double, steepness: Double, midpoint: Double) -> Double {
        1.0 / (1.0 + exp(-steepness * (x - midpoint)))
    }

    // -------------------------------------------------------
    // MARK: - A custom Binding for factorIntensity
    // -------------------------------------------------------
    /// This binding reads factorIntensity via simSettings.getFactorIntensity(),
    /// and writes it back via simSettings.setFactorIntensity(...).
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
                    let effectiveTilt = dragTiltOverride ?? displayedTilt
                    let absTilt = abs(effectiveTilt)
                    let barWidth = geo.size.width
                    let computedWidth = barWidth * absTilt
                    let fillWidth = (barWidth - computedWidth) < 1 ? barWidth : computedWidth

                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        // Foreground fill
                        if effectiveTilt >= 0 {
                            // Green fill from left
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: computedWidth, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: computedWidth)
                        } else {
                            // Red fill from right
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: fillWidth, height: 8)
                                .offset(x: barWidth - fillWidth)
                                .animation(.easeInOut(duration: 0.3), value: fillWidth)
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let locationX = value.location.x
                                let halfWidth = barWidth / 2
                                // Map so center=0, right=+1, left=–1
                                var newTilt = ((locationX - halfWidth) / halfWidth)
                                newTilt = min(max(newTilt, -1), 1)
                                dragTiltOverride = newTilt
                            }
                            .onEnded { _ in
                                if let newTilt = dragTiltOverride {
                                    // Update tiltBarValue
                                    simSettings.tiltBarValue = newTilt
                                    // If you want them in sync, also update factorIntensity
                                    simSettings.setFactorIntensity((newTilt + 1) / 2.0)
                                }
                                dragTiltOverride = nil
                            }
                    )
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
            Section {
                HStack {
                    // EXTREME BEARISH BUTTON
                    Button {
                        isManualOverride = true
                        simSettings.setFactorIntensity(0.0)
                        simSettings.tiltBarValue = -1.0

                        // Turn OFF bullish factors (lock them at minValue)
                        for key in bullishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: false)
                            lockFactorAtMin(key)
                        }

                        // Turn ON bearish factors (unlock them, set to minValue)
                        for key in bearishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: true)
                            unlockFactorAndSetMin(key)
                        }

                        // Update chart flags
                        simSettings.chartExtremeBearish = true
                        simSettings.chartExtremeBullish = false

                        // Recompute tilt bar so it respects enabled/disabled factors
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isManualOverride = false
                        }
                    } label: {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(simSettings.chartExtremeBearish)
                    .opacity(simSettings.chartExtremeBearish ? 0.3 : 1.0)

                    // The main intensity slider
                    // -- Instead of binding directly to simSettings.rawFactorIntensity,
                    //    we use factorIntensityBinding so we can call syncFactorsToGlobalIntensity.
                    Slider(
                        value: factorIntensityBinding,
                        in: 0...1,
                        step: 0.01
                    )
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .onChange(of: factorIntensityBinding.wrappedValue) { newVal in
                        // After the user adjusts the slider, recalc tilt so the bar updates
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                        
                        // If we move above ~0.0, turn off the 'extremeBearish' flag
                        if newVal > 0.01 && simSettings.chartExtremeBearish {
                            simSettings.chartExtremeBearish = false
                        }
                        // If we move below ~1.0, turn off the 'extremeBullish' flag
                        if newVal < 0.99 && simSettings.chartExtremeBullish {
                            simSettings.chartExtremeBullish = false
                        }
                    }

                    // EXTREME BULLISH BUTTON
                    Button {
                        isManualOverride = true
                        simSettings.setFactorIntensity(1.0)
                        simSettings.tiltBarValue = 1.0

                        // Turn OFF bearish factors (lock them at maxValue)
                        for key in bearishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: false)
                            lockFactorAtMax(key)
                        }

                        // Turn ON bullish factors (unlock them, set to maxValue)
                        for key in bullishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: true)
                            unlockFactorAndSetMax(key)
                        }

                        simSettings.chartExtremeBullish = true
                        simSettings.chartExtremeBearish = false

                        // Recompute tilt bar
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isManualOverride = false
                        }
                    } label: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(simSettings.chartExtremeBullish)
                    .opacity(simSettings.chartExtremeBullish ? 0.3 : 1.0)
                }
            } footer: {
                Text("Press a chart icon to force extreme factor settings.")
                    .foregroundColor(.white)
            }
            .listRowBackground(Color(white: 0.15))
        }

    // (Helper) Lock factor at its minValue
    func lockFactorAtMin(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.minValue
        f.isEnabled = false      // you might prefer to keep it 'enabled' but locked
        simSettings.lockedFactors.insert(factorName)
        simSettings.factors[factorName] = f
    }

    // (Helper) Lock factor at its maxValue
    func lockFactorAtMax(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.maxValue
        f.isEnabled = false
        simSettings.lockedFactors.insert(factorName)
        simSettings.factors[factorName] = f
    }

    // (Helper) Unlock factor and set it to minValue
    func unlockFactorAndSetMin(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.minValue
        f.isEnabled = true
        simSettings.lockedFactors.remove(factorName)
        simSettings.factors[factorName] = f
    }

    // (Helper) Unlock factor and set it to maxValue
    func unlockFactorAndSetMax(_ factorName: String) {
        guard var f = simSettings.factors[factorName] else { return }
        f.currentValue = f.maxValue
        f.isEnabled = true
        simSettings.lockedFactors.remove(factorName)
        simSettings.factors[factorName] = f
    }

    // MARK: - Toggle All Section
    var toggleAllSection: some View {
        Section {
            Toggle("Toggle All Factors", isOn:
                Binding<Bool>(
                    get: {
                        simSettings.toggleAll
                    },
                    set: { newValue in
                        simSettings.userIsActuallyTogglingAll = true
                        simSettings.toggleAll = newValue
                        
                        // Just call our model's method to handle enable/disable logic.
                        simSettings.toggleAllFactors(on: newValue)
                        
                        if newValue {
                            // If toggling on, clear these flags if needed
                            simSettings.chartExtremeBearish = false
                            simSettings.chartExtremeBullish = false
                            simSettings.lockedFactors.removeAll()
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

    // MARK: - Restore Defaults
    var restoreDefaultsSection: some View {
        Section {
            Button(action: {
                simSettings.restoreDefaults()
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
        Section {
            Button("Reset All Criteria") {
                showResetCriteriaConfirmation = true
            }
            .buttonStyle(PressableDestructiveButtonStyle())
            .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation, actions: {
                Button("Reset", role: .destructive) {
                    simSettings.restoreDefaults()
                    // Also reset onboarding or other states
                    didFinishOnboarding = false
                    simSettings.setFactorIntensity(0.5)
                    simSettings.tiltBarValue = 0.0
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("All custom criteria will be restored to default. This cannot be undone.")
            })
        }
        .listRowBackground(Color(white: 0.15))
    }
}
