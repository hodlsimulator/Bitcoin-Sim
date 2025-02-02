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

    // MARK: - Tilt Bar
    var overallTiltSection: some View {
        Section {
            HStack {
                GeometryReader { geo in
                    // Define your factor keys:
                    let bullishKeysLocal = ["Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
                                              "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
                                              "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"]
                    let bearishKeysLocal = ["RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
                                            "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket", "Recession"]
                    
                    // Average activation (0 to 1) on each side:
                    let normalizedBullish = bullishKeysLocal.reduce(0.0) { accum, key in
                        accum + (simSettings.factorEnableFrac[key] ?? 0)
                    } / Double(bullishKeysLocal.count)
                    let normalizedBearish = bearishKeysLocal.reduce(0.0) { accum, key in
                        accum + (simSettings.factorEnableFrac[key] ?? 0)
                    } / Double(bearishKeysLocal.count)
                    
                    // Compute a linear net tilt in the range roughly -1 to +1.
                    // (If all bullish are fully on, normalizedBullish=1; if none are on then 0. Same for bearish.)
                    let linearTilt = normalizedBullish - normalizedBearish
                    
                    // Now, apply a smooth arctan transform.
                    // Multiply the linear tilt by a scaling factor (here 5.0) to control sensitivity,
                    // then use (2.6/π)*atan(…) so that the tilt saturates around ±1.
                    let tilt = (2.6 / .pi) * atan(5.0 * linearTilt)
                    
                    // Draw the tilt bar:
                    let absTilt = abs(tilt)
                    let computedWidth = geo.size.width * absTilt
                    // Clamp if nearly full:
                    let fillWidth = (geo.size.width - computedWidth) < 1 ? geo.size.width : computedWidth

                    ZStack(alignment: .leading) {
                        // Background bar:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        if tilt >= 0 {
                            // Green fill (bullish): anchored to the left.
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: computedWidth, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: computedWidth)
                        } else {
                            // Red fill (bearish): anchored to the right.
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: fillWidth, height: 8)
                                .offset(x: geo.size.width - fillWidth)
                                .animation(.easeInOut(duration: 0.3), value: fillWidth)
                        }
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
                lastFactorValue = [:]  // Clear leftover values
                // Immediately set oldFactorEnableFrac to match the newly assigned factorEnableFrac
                // so that onChange doesn't see a difference after isRestoringDefaults = false
                oldFactorEnableFrac = simSettings.factorEnableFrac
                simSettings.factorIntensity = 0.5

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    simSettings.syncAllFactorsToIntensity(0.5)
                    let tiltNow = computeActiveNetTilt()
                    simSettings.defaultTilt = tiltNow
                    simSettings.hasCapturedDefault = true
                    let allBull = computeIfAllBullish() - tiltNow
                    let allBear = computeIfAllBearish() - tiltNow
                    simSettings.maxSwing = max(abs(allBull), abs(allBear), 0.00001)
                    simSettings.tiltBarValue = 0.0
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
