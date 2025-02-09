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
                    let effectiveTilt = displayedTilt
                    let absTilt = abs(effectiveTilt)
                    let barWidth = geo.size.width
                    let computedWidth = barWidth * absTilt

                    ZStack(alignment: .leading) {
                        // Background
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        // Green bar for positive tilt, anchored on the left
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: effectiveTilt > 0 ? computedWidth : 0, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: effectiveTilt)
                        
                        // Red bar for negative tilt, anchored on the right
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: effectiveTilt < 0 ? computedWidth : 0, height: 8)
                            .offset(x: effectiveTilt < 0 ? (barWidth - computedWidth) : barWidth)
                            .animation(.easeInOut(duration: 0.3), value: effectiveTilt)
                    }
                    .contentShape(Rectangle())
                    // No drag gesture here—tilt bar is display-only.
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
                    if simSettings.chartExtremeBearish {
                        // Cancel forced extreme if tapped again.
                        simSettings.chartExtremeBearish = false
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                    } else {
                        // Force Bearish:
                        isManualOverride = true
                        simSettings.setFactorIntensity(0.0)
                        simSettings.tiltBarValue = -1.0

                        // Turn OFF all bullish factors and force them to their minimum.
                        for key in bullishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: false)
                            lockFactorAtMin(key)
                        }
                        // Turn ON all bearish factors and force them to their minimum.
                        for key in bearishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: true)
                            unlockFactorAndSetMin(key)
                        }

                        simSettings.chartExtremeBearish = true
                        simSettings.chartExtremeBullish = false
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isManualOverride = false
                        }
                    }
                } label: {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .disabled(
                    simSettings.chartExtremeBearish && factorIntensityBinding.wrappedValue <= 0.0001
                )
                .opacity(
                    simSettings.chartExtremeBearish && factorIntensityBinding.wrappedValue <= 0.0001
                    ? 0.5
                    : 1.0
                )

                // MAIN INTENSITY SLIDER with Haptic Feedback
                Slider(
                    value: factorIntensityBinding,
                    in: 0...1,
                    step: 0.01
                )
                .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                .disabled(simSettings.isGlobalSliderDisabled)
                .onChange(of: factorIntensityBinding.wrappedValue) { newValue in
                    // Trigger haptic feedback when the intensity changes significantly.
                    if abs(newValue - oldFactorIntensity) > 0.05 {
                        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                        feedbackGenerator.prepare()
                        feedbackGenerator.impactOccurred()
                        oldFactorIntensity = newValue
                    }
                    simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                }

                // EXTREME BULLISH BUTTON
                Button {
                    if simSettings.chartExtremeBullish {
                        simSettings.chartExtremeBullish = false
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)
                    } else {
                        isManualOverride = true
                        simSettings.setFactorIntensity(1.0)
                        simSettings.tiltBarValue = 1.0

                        // Turn OFF all bearish factors and force them to their maximum.
                        for key in bearishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: false)
                            lockFactorAtMax(key)
                        }
                        // Turn ON all bullish factors and force them to their maximum.
                        for key in bullishKeys {
                            simSettings.setFactorEnabled(factorName: key, enabled: true)
                            unlockFactorAndSetMax(key)
                        }

                        simSettings.chartExtremeBullish = true
                        simSettings.chartExtremeBearish = false
                        simSettings.recalcTiltBarValue(bullishKeys: bullishKeys, bearishKeys: bearishKeys)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isManualOverride = false
                        }
                    }
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .disabled(
                    simSettings.chartExtremeBullish && factorIntensityBinding.wrappedValue >= 0.9999
                )
                .opacity(
                    simSettings.chartExtremeBullish && factorIntensityBinding.wrappedValue >= 0.9999
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

    // MARK: - Toggle All Section
    var toggleAllSection: some View {
        Section {
            Toggle("Toggle All Factors", isOn:
                Binding<Bool>(
                    get: { simSettings.toggleAll },
                    set: { newValue in
                        simSettings.userIsActuallyTogglingAll = true
                        simSettings.toggleAll = newValue
                        simSettings.toggleAllFactors(on: newValue)
                        if newValue {
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
        Section(footer: Text("Resetting all criteria will revert your custom settings to their default values and restart the onboarding process.")
                    .foregroundColor(.white)
                    .font(.footnote)
        ) {
            Button(action: {
                showResetCriteriaConfirmation = true
            }) {
                HStack {
                    Text("Reset All Criteria")
                        .foregroundColor(.red)  // Or your desired color/style
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableDestructiveButtonStyle())
            .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation, actions: {
                Button("Reset", role: .destructive) {
                    simSettings.restoreDefaults()
                    didFinishOnboarding = false
                    simSettings.setFactorIntensity(0.5)
                    simSettings.tiltBarValue = 0.0
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("This will restore default settings and restart onboarding. Do you want to proceed?")
            })
        }
        .listRowBackground(Color(white: 0.15))
    }
}
