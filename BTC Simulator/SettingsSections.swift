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
                    // Use the drag override if active, else the computed displayedTilt.
                    let effectiveTilt = dragTiltOverride ?? displayedTilt
                    let absTilt = abs(effectiveTilt)
                    let barWidth = geo.size.width
                    let computedWidth = barWidth * absTilt
                    let fillWidth = (barWidth - computedWidth) < 1 ? barWidth : computedWidth

                    ZStack(alignment: .leading) {
                        // Background bar.
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                        
                        if effectiveTilt >= 0 {
                            // Green fill: anchored to the left.
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: computedWidth, height: 8)
                                .animation(.easeInOut(duration: 0.3), value: computedWidth)
                        } else {
                            // Red fill: anchored to the right.
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
                                // Map so that center = 0, right edge = +1, left edge = –1.
                                var newTilt = ((locationX - halfWidth) / halfWidth)
                                newTilt = min(max(newTilt, -1), 1)
                                dragTiltOverride = newTilt
                            }
                            .onEnded { _ in
                                if let newTilt = dragTiltOverride {
                                    simSettings.tiltBarValue = newTilt
                                    // Update the global slider by mapping [-1, 1] to [0, 1].
                                    simSettings.factorIntensity = (newTilt + 1) / 2
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

    // MARK: - Universal Factor Intensity (Slider + Extreme Icons)
    var factorIntensitySection: some View {
        Section {
            HStack {
                // EXTREME BEARISH BUTTON (LEFT / RED)
                Button {
                    isManualOverride = true
                    simSettings.factorIntensity = 0.0
                    simSettings.tiltBarValue = -1.0

                    // Force bullish factors off and lock them (set to domain min)
                    for key in bullishKeys {
                        setFactorEnabled(factorName: key, enabled: false)
                        simSettings.factorEnableFrac[key] = 0.0

                        let isWeekly = (simSettings.periodUnit == .weeks)
                        let (minVal, _) = simSettings.factorRange(for: key, isWeekly: isWeekly)
                        computedFactorAccessors[key]?.set(minVal)

                        let frac = simSettings.fractionFromValue(key, value: minVal, isWeekly: isWeekly)
                        simSettings.factorEnableFrac[key] = frac

                        simSettings.lockedFactors.insert(key) // Lock this factor
                    }

                    // Force bearish factors on and unlock them (set to domain min)
                    for key in bearishKeys {
                        setFactorEnabled(factorName: key, enabled: true)
                        simSettings.factorEnableFrac[key] = 1.0

                        let isWeekly = (simSettings.periodUnit == .weeks)
                        let (minVal, _) = simSettings.factorRange(for: key, isWeekly: isWeekly)
                        computedFactorAccessors[key]?.set(minVal)

                        let frac = simSettings.fractionFromValue(key, value: minVal, isWeekly: isWeekly)
                        simSettings.factorEnableFrac[key] = frac

                        simSettings.lockedFactors.remove(key) // Unlock this factor
                    }

                    // Set the chart button flag for extreme bearish
                    simSettings.chartExtremeBearish = true
                    simSettings.chartExtremeBullish = false

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

                // GLOBAL INTENSITY SLIDER
                Slider(
                    value: Binding(
                        get: { simSettings.factorIntensity },
                        set: { newVal in
                            simSettings.factorIntensity = newVal
                            simSettings.syncAllFactorsToIntensity(newVal, simSettings: simSettings)
                            // Clear the chart extreme flags when moving the slider manually
                            simSettings.chartExtremeBearish = false
                            simSettings.chartExtremeBullish = false
                        }
                    ),
                    in: 0...1,
                    step: 0.01
                )
                .tint(Color(red: 189/255, green: 213/255, blue: 234/255))

                // EXTREME BULLISH BUTTON (RIGHT / GREEN)
                Button {
                    isManualOverride = true
                    simSettings.factorIntensity = 1.0
                    simSettings.tiltBarValue = 1.0

                    // Force bearish factors off and lock them (set to domain max)
                    for key in bearishKeys {
                        setFactorEnabled(factorName: key, enabled: false)
                        simSettings.factorEnableFrac[key] = 0.0

                        let isWeekly = (simSettings.periodUnit == .weeks)
                        let (minVal, maxVal) = simSettings.factorRange(for: key, isWeekly: isWeekly)
                        computedFactorAccessors[key]?.set(maxVal)

                        let frac = simSettings.fractionFromValue(key, value: maxVal, isWeekly: isWeekly)
                        simSettings.factorEnableFrac[key] = frac
                        simSettings.manualOffsets[key] = 0.0

                        simSettings.lockedFactors.insert(key) // Lock this factor
                    }

                    // Force bullish factors on and unlock them (set to domain max)
                    for key in bullishKeys {
                        setFactorEnabled(factorName: key, enabled: true)
                        simSettings.factorEnableFrac[key] = 1.0

                        let isWeekly = (simSettings.periodUnit == .weeks)
                        let (minVal, maxVal) = simSettings.factorRange(for: key, isWeekly: isWeekly)
                        computedFactorAccessors[key]?.set(maxVal)

                        let frac = simSettings.fractionFromValue(key, value: maxVal, isWeekly: isWeekly)
                        simSettings.factorEnableFrac[key] = frac
                        simSettings.manualOffsets[key] = 0.0

                        simSettings.lockedFactors.remove(key) // Unlock this factor
                    }

                    oldFactorEnableFrac = simSettings.factorEnableFrac
                    lastFactorValue.removeAll()

                    // Set the chart button flag for extreme bullish
                    simSettings.chartExtremeBullish = true
                    simSettings.chartExtremeBearish = false

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
            Text("Press a chart icon to force the extreme factor settings. The icon will grey out only when pressed.")
                .foregroundColor(.white)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    func forceFactorNumeric(_ factorName: String, toIntensity t: Double) {
        // If you skip factors that are “off,” they stay at old midpoints. So we do it directly:
        let val = simSettings.baseValForFactor(factorName, intensity: t)
        
        // If your baseValForFactor returns a plain Double, just do:
        computedFactorAccessors[factorName]?.set(val)
        
        // If your baseValForFactor returns an optional, do:
        // factorAccessors[factorName]?.set(val ?? 0.5)
        
        // And also reset the manual offset to 0 so the new forced value “sticks”
        simSettings.manualOffsets[factorName] = 0.0
    }

    func setFactorEnabled(factorName: String, enabled: Bool) {
        switch factorName {
        case "RegClampdown":
            simSettings.useRegClampdownWeekly = enabled
            simSettings.useRegClampdownMonthly = enabled
            
        case "CompetitorCoin":
            simSettings.useCompetitorCoinWeekly = enabled
            simSettings.useCompetitorCoinMonthly = enabled
            
        case "SecurityBreach":
            simSettings.useSecurityBreachWeekly = enabled
            simSettings.useSecurityBreachMonthly = enabled
            
        case "BubblePop":
            simSettings.useBubblePopWeekly = enabled
            simSettings.useBubblePopMonthly = enabled
            
        case "StablecoinMeltdown":
            simSettings.useStablecoinMeltdownWeekly = enabled
            simSettings.useStablecoinMeltdownMonthly = enabled
            
        case "BlackSwan":
            simSettings.useBlackSwanWeekly = enabled
            simSettings.useBlackSwanMonthly = enabled
            
        case "BearMarket":
            simSettings.useBearMarketWeekly = enabled
            simSettings.useBearMarketMonthly = enabled
            
        case "MaturingMarket":
            simSettings.useMaturingMarketWeekly = enabled
            simSettings.useMaturingMarketMonthly = enabled
            
        case "Recession":
            simSettings.useRecessionWeekly = enabled
            simSettings.useRecessionMonthly = enabled

        // BULLISH
        case "Halving":
            simSettings.useHalvingWeekly = enabled
            simSettings.useHalvingMonthly = enabled

        case "InstitutionalDemand":
            simSettings.useInstitutionalDemandWeekly = enabled
            simSettings.useInstitutionalDemandMonthly = enabled

        case "CountryAdoption":
            simSettings.useCountryAdoptionWeekly = enabled
            simSettings.useCountryAdoptionMonthly = enabled

        case "RegulatoryClarity":
            simSettings.useRegulatoryClarityWeekly = enabled
            simSettings.useRegulatoryClarityMonthly = enabled

        case "EtfApproval":
            simSettings.useEtfApprovalWeekly = enabled
            simSettings.useEtfApprovalMonthly = enabled

        case "TechBreakthrough":
            simSettings.useTechBreakthroughWeekly = enabled
            simSettings.useTechBreakthroughMonthly = enabled

        case "ScarcityEvents":
            simSettings.useScarcityEventsWeekly = enabled
            simSettings.useScarcityEventsMonthly = enabled

        case "GlobalMacroHedge":
            simSettings.useGlobalMacroHedgeWeekly = enabled
            simSettings.useGlobalMacroHedgeMonthly = enabled

        case "StablecoinShift":
            simSettings.useStablecoinShiftWeekly = enabled
            simSettings.useStablecoinShiftMonthly = enabled

        case "DemographicAdoption":
            simSettings.useDemographicAdoptionWeekly = enabled
            simSettings.useDemographicAdoptionMonthly = enabled

        case "AltcoinFlight":
            simSettings.useAltcoinFlightWeekly = enabled
            simSettings.useAltcoinFlightMonthly = enabled

        case "AdoptionFactor":
            simSettings.useAdoptionFactorWeekly = enabled
            simSettings.useAdoptionFactorMonthly = enabled
                
        default:
            break
        }
        
        // Lock or unlock the factor:
        if enabled {
            // When enabled, ensure the factor is unlocked.
            simSettings.lockedFactors.remove(factorName)
        } else {
            // When disabled, lock the factor so it stays at its forced value.
            simSettings.lockedFactors.insert(factorName)
        }
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
                    simSettings.syncAllFactorsToIntensity(0.5, simSettings: simSettings)
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
