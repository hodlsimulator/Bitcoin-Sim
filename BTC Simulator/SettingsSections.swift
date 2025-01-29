//
//  SettingsSections.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension SettingsView {

    // MARK: - Tilt Bar
    var overallTiltSection: some View {
        Section {
            HStack {
                GeometryReader { geo in
                    let tilt = displayedTilt
                    ZStack(alignment: tilt >= 0 ? .leading : .trailing) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)

                        Rectangle()
                            .fill(tilt >= 0 ? .green : .red)
                            .frame(width: geo.size.width * abs(tilt), height: 8)
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

    // MARK: - Universal Factor Intensity (Slider)
    var factorIntensitySection: some View {
        Section {
            HStack {
                Button {
                    simSettings.factorIntensity = 0.0
                } label: {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Slider(value: $simSettings.factorIntensity, in: 0...1, step: 0.01)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))

                Button {
                    simSettings.factorIntensity = 1.0
                } label: {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Scales all bullish & bearish factors. Left (red) => minimum, right (green) => maximum.")
                .foregroundColor(.white)
        }
        .listRowBackground(Color(white: 0.15))
    }

    // MARK: - Toggle All Factors
    var toggleAllSection: some View {
        Section {
            Toggle("Toggle All Factors",
                   isOn: Binding<Bool>(
                    get: { simSettings.toggleAll },
                    set: { newValue in
                        simSettings.userIsActuallyTogglingAll = true
                        simSettings.toggleAll = newValue
                    }
                   )
            )
            .tint(.orange)
            .foregroundColor(.white)
        } footer: {
            Text("Switches ON or OFF all bullish and bearish factors at once.")
                .foregroundColor(.white)
        }
        .listRowBackground(Color(white: 0.15))
    }

    // MARK: - Restore Defaults
    var restoreDefaultsSection: some View {
        Section {
            Button(action: {
                simSettings.restoreDefaults()
                simSettings.factorIntensity = 0.5
                oldFactorIntensity = 0.5

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    simSettings.defaultTilt = computeActiveNetTilt()
                    let allBull = computeIfAllBullish() - simSettings.defaultTilt
                    let allBear = computeIfAllBearish() - simSettings.defaultTilt
                    simSettings.maxSwing = max(abs(allBull), abs(allBear), 0.00001)
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
                    
                    // "didFinishOnboarding" is in scope now:
                    didFinishOnboarding = false
                    
                    simSettings.factorIntensity = 0.5
                    oldFactorIntensity = 0.5
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("All custom criteria will be restored to default. This cannot be undone.")
            })
        }
        .listRowBackground(Color(white: 0.15))
    }
}
