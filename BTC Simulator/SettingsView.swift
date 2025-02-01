//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    @AppStorage("hasOnboarded") var didFinishOnboarding = false
    @AppStorage("showAdvancedSettings") private var showAdvancedSettings: Bool = false
    
    // Global slider
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    @State var oldFactorIntensity: Double = 0.5
    
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    // Stores the actual numeric value of each factor (halvingBumpUnified, etc.) before toggling off
    @State var lastFactorValue: [String: Double] = [:]
    
    // Factor keys
    let bullishKeys: [String] = [
        "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
        "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
        "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
    ]
    let bearishKeys: [String] = [
        "RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
        "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket",
        "Recession"
    ]
    private var totalFactors: Int {
        bullishKeys.count + bearishKeys.count
    }
    
    // For weighting toggles
    private let factorWeight = 0.04
    
    // For toggling animations
    @State private var hasAppeared = false
    @State private var firstToggleOff = true
    @State private var disableAnimationNow = false
    @State private var oldFactorEnableFrac: [String: Double] = [:]
    
    // A helper dictionary to get/set each factor’s numeric property via your “unified” extension.
    private var factorAccessors: [String: (get: () -> Double, set: (Double) -> Void)] {
        [
            // ---------- BULLISH ----------
            "Halving": (
                { simSettings.halvingBumpUnified },
                { simSettings.halvingBumpUnified = $0 }
            ),
            "InstitutionalDemand": (
                { simSettings.maxDemandBoostUnified },
                { simSettings.maxDemandBoostUnified = $0 }
            ),
            "CountryAdoption": (
                { simSettings.maxCountryAdBoostUnified },
                { simSettings.maxCountryAdBoostUnified = $0 }
            ),
            "RegulatoryClarity": (
                { simSettings.maxClarityBoostUnified },
                { simSettings.maxClarityBoostUnified = $0 }
            ),
            "EtfApproval": (
                { simSettings.maxEtfBoostUnified },
                { simSettings.maxEtfBoostUnified = $0 }
            ),
            "TechBreakthrough": (
                { simSettings.maxTechBoostUnified },
                { simSettings.maxTechBoostUnified = $0 }
            ),
            "ScarcityEvents": (
                { simSettings.maxScarcityBoostUnified },
                { simSettings.maxScarcityBoostUnified = $0 }
            ),
            "GlobalMacroHedge": (
                { simSettings.maxMacroBoostUnified },
                { simSettings.maxMacroBoostUnified = $0 }
            ),
            "StablecoinShift": (
                { simSettings.maxStablecoinBoostUnified },
                { simSettings.maxStablecoinBoostUnified = $0 }
            ),
            "DemographicAdoption": (
                { simSettings.maxDemoBoostUnified },
                { simSettings.maxDemoBoostUnified = $0 }
            ),
            "AltcoinFlight": (
                { simSettings.maxAltcoinBoostUnified },
                { simSettings.maxAltcoinBoostUnified = $0 }
            ),
            "AdoptionFactor": (
                { simSettings.adoptionBaseFactorUnified },
                { simSettings.adoptionBaseFactorUnified = $0 }
            ),
            
            // ---------- BEARISH ----------
            "RegClampdown": (
                { simSettings.maxClampDownUnified },
                { simSettings.maxClampDownUnified = $0 }
            ),
            "CompetitorCoin": (
                { simSettings.maxCompetitorBoostUnified },
                { simSettings.maxCompetitorBoostUnified = $0 }
            ),
            "SecurityBreach": (
                { simSettings.breachImpactUnified },
                { simSettings.breachImpactUnified = $0 }
            ),
            "BubblePop": (
                { simSettings.maxPopDropUnified },
                { simSettings.maxPopDropUnified = $0 }
            ),
            "StablecoinMeltdown": (
                { simSettings.maxMeltdownDropUnified },
                { simSettings.maxMeltdownDropUnified = $0 }
            ),
            "BlackSwan": (
                { simSettings.blackSwanDropUnified },
                { simSettings.blackSwanDropUnified = $0 }
            ),
            "BearMarket": (
                { simSettings.bearWeeklyDriftUnified },
                { simSettings.bearWeeklyDriftUnified = $0 }
            ),
            "MaturingMarket": (
                { simSettings.maxMaturingDropUnified },
                { simSettings.maxMaturingDropUnified = $0 }
            ),
            "Recession": (
                { simSettings.maxRecessionDropUnified },
                { simSettings.maxRecessionDropUnified = $0 }
            ),
        ]
    }
    
    init() {
        setupNavBarAppearance()
    }
    
    var body: some View {
        let mainForm = Form {
            overallTiltSection
            factorIntensitySection
            toggleAllSection
            restoreDefaultsSection

            BullishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: { factorName in
                    activeFactor = factorName
                },
                factorEnableFrac: $simSettings.factorEnableFrac,
                animateFactor: { factorName, isOn in
                    print("Animating Bullish factor: \(factorName), isOn=\(isOn)")
                }
            )
            .environmentObject(simSettings)

            BearishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: { factorName in
                    activeFactor = factorName
                },
                factorEnableFrac: $simSettings.factorEnableFrac,
                animateFactor: { factorName, isOn in
                    print("Animating Bearish factor: \(factorName), isOn=\(isOn)")
                }
            )
            .environmentObject(simSettings)

            AdvancedSettingsSection(showAdvancedSettings: $showAdvancedSettings)
                .environmentObject(simSettings)

            aboutSection
            resetCriteriaSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.12))
        .environment(\.colorScheme, .dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .overlayPreferenceValue(TooltipAnchorKey.self) { allItems in
            tooltipOverlay(allItems)
        }

        return mainForm
            .onAppear {
                oldFactorEnableFrac = simSettings.factorEnableFrac
                hasAppeared = true
                if abs(simSettings.tiltBarValue) < 0.0000001 {
                    simSettings.tiltBarValue = displayedTilt
                }
            }
            .onChange(of: factorIntensity) { _ in
                guard hasAppeared else { return }
                simSettings.syncAllFactorsToIntensity(factorIntensity)
                simSettings.tiltBarValue = displayedTilt
            }
            .onChange(of: simSettings.factorEnableFrac) { newVal in
                disableAnimationNow = false

                // Possibly skip animations for first toggle-off
                if firstToggleOff {
                    for (key, oldVal) in oldFactorEnableFrac {
                        let updatedVal = newVal[key] ?? 0.0
                        if oldVal > 0.5 && updatedVal < 0.5 {
                            disableAnimationNow = true
                            firstToggleOff = false
                            break
                        }
                    }
                }

                // Remember if everything was OFF prior
                let wasAllOffBefore = oldFactorEnableFrac.values.allSatisfy { $0 == 0.0 }

                // ---- SINGLE PASS: store/restore custom values on toggle ----
                for factorName in newVal.keys {
                    let oldFrac = oldFactorEnableFrac[factorName] ?? 0.0
                    let newFrac = newVal[factorName] ?? 0.0

                    // Turned OFF? Store current numeric
                    if oldFrac > 0.0, newFrac == 0.0 {
                        if let accessor = factorAccessors[factorName] {
                            lastFactorValue[factorName] = accessor.get()
                        }
                    }
                    // Turned ON? Restore the stored custom value
                    else if oldFrac == 0.0, newFrac > 0.0 {
                        if let storedVal = lastFactorValue[factorName] {
                            factorAccessors[factorName]?.set(storedVal)
                        } else {
                            // If none stored, pick a default (e.g. 0.5)
                            factorAccessors[factorName]?.set(0.5)
                        }
                    }
                }

                // Update oldFactorEnableFrac after the single pass
                oldFactorEnableFrac = newVal

                // Check if everything just switched OFF => neutral tilt
                let isAllOffNow = newVal.values.allSatisfy { $0 == 0.0 }
                if !wasAllOffBefore && isAllOffNow {
                    simSettings.defaultTilt = 0.0
                    simSettings.hasCapturedDefault = true
                    simSettings.maxSwing = 1.0
                }

                // Finally, recalc tiltBarValue
                simSettings.tiltBarValue = displayedTilt
            }
            .animation(hasAppeared ? (disableAnimationNow ? nil : .easeInOut(duration: 0.3)) : nil,
                       value: simSettings.factorEnableFrac)
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: factorIntensity)
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: displayedTilt)
    }
    
    @ViewBuilder
    private func tooltipOverlay(_ allItems: [TooltipItem]) -> some View {
        GeometryReader { proxy in
            if let item = allItems.last {
                let bubbleWidth: CGFloat = 240
                let bubbleHeight: CGFloat = 220
                let offset: CGFloat = 8
                let anchorPoint = proxy[item.anchor]
                
                let anchorX = anchorPoint.x
                let anchorYBase = anchorPoint.y
                let anchorY = (item.title == "Halving") ? (anchorYBase - 16) : anchorYBase
                let spaceBelow = proxy.size.height - anchorY
                let arrowDirection: ArrowDirection = (spaceBelow > bubbleHeight + 40) ? .up : .down
                
                let proposedX = anchorX - (bubbleWidth / 2)
                let clampedX = max(10, min(proposedX, proxy.size.width - bubbleWidth - 10))
                
                let proposedY = (arrowDirection == .up)
                    ? (anchorY + offset)
                    : (anchorY - offset - bubbleHeight)
                let clampedY = max(10, min(proposedY, proxy.size.height - bubbleHeight - 10))
                
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                activeFactor = nil
                            }
                        }
                    
                    TooltipBubble(text: item.description, arrowDirection: arrowDirection)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: bubbleWidth)
                        .position(
                            x: clampedX + bubbleWidth / 2,
                            y: clampedY + bubbleHeight / 2
                        )
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
    
    // ----- Tilt Calculation & Helpers -----
    
    func computeActiveNetTilt() -> Double {
        let anyActive = simSettings.factorEnableFrac.values.contains { $0 > 0.0 }
        guard anyActive else {
            return 0.0
        }
        let eff = invertedSCurve(factorIntensity, steepness: 12.0)
        
        let bullishTotal = bullishKeys.reduce(0.0) { accum, key in
            let frac = simSettings.factorEnableFrac[key] ?? 0.0
            return accum + frac * factorWeight
        }
        let bearishTotal = bearishKeys.reduce(0.0) { accum, key in
            let frac = simSettings.factorEnableFrac[key] ?? 0.0
            return accum + frac * factorWeight
        }
        let partialSum = bullishTotal - bearishTotal
        let normalised = partialSum / Double(totalFactors)
        let netTilt = normalised * eff
        return netTilt
    }
    
    var displayedTilt: Double {
        let allOff = simSettings.factorEnableFrac.values.allSatisfy { $0 == 0.0 }
        if allOff { return 0.0 }
        guard simSettings.hasCapturedDefault else { return 0.0 }
        
        let activeTilt = computeActiveNetTilt()
        let diff = activeTilt - simSettings.defaultTilt
        let fraction = diff / max(simSettings.maxSwing, 1e-9)
        let scaled = fraction * 1.7
        let finalTilt = tanh(50.0 * scaled)
        return finalTilt
    }
    
    func computeIfAllBullish() -> Double {
        let effective = invertedSCurve(1.0, steepness: 12.0)
        var sum = 0.0
        for _ in bullishKeys {
            let frac = gentleSCurve(1.0, steepness: 6.0)
            sum += frac * factorWeight
        }
        for _ in bearishKeys {
            let frac = gentleSCurve(0.0, steepness: 6.0)
            sum -= frac * factorWeight
        }
        let normalised = sum / Double(totalFactors)
        let boosted = normalised * effective * 2.0
        return boosted
    }

    func computeIfAllBearish() -> Double {
        let effective = invertedSCurve(1.0, steepness: 12.0)
        var sum = 0.0
        for _ in bullishKeys {
            let frac = gentleSCurve(0.0, steepness: 6.0)
            sum += frac * factorWeight
        }
        for _ in bearishKeys {
            let frac = gentleSCurve(1.0, steepness: 6.0)
            sum -= frac * factorWeight
        }
        let normalised = sum / Double(totalFactors)
        let boosted = normalised * effective * 2.0
        return boosted
    }
    
    private func gentleSCurve(_ x: Double, steepness: Double = 3.0) -> Double {
        1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
    
    private func invertedSCurve(_ x: Double, steepness: Double = 6.0) -> Double {
        1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
    
    // ----- Nav Bar Appearance -----
    
    private func setupNavBarAppearance() {
        let opaqueAppearance = UINavigationBarAppearance()
        opaqueAppearance.configureWithOpaqueBackground()
        opaqueAppearance.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        opaqueAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        opaqueAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]
        
        let blurredAppearance = UINavigationBarAppearance()
        blurredAppearance.configureWithTransparentBackground()
        blurredAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        blurredAppearance.backgroundColor = UIColor(white: 0.12, alpha: 0.2)
        blurredAppearance.largeTitleTextAttributes = opaqueAppearance.largeTitleTextAttributes
        blurredAppearance.titleTextAttributes = opaqueAppearance.titleTextAttributes
        
        let chevronImage = UIImage(systemName: "chevron.left")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let backItem = UIBarButtonItemAppearance(style: .plain)
        backItem.normal.titlePositionAdjustment = UIOffset(horizontal: -3000, vertical: 0)
        
        opaqueAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        blurredAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        opaqueAppearance.backButtonAppearance = backItem
        blurredAppearance.backButtonAppearance = backItem
        
        UINavigationBar.appearance().scrollEdgeAppearance = opaqueAppearance
        UINavigationBar.appearance().standardAppearance   = blurredAppearance
        UINavigationBar.appearance().compactAppearance    = blurredAppearance
        UINavigationBar.appearance().tintColor = .white
    }
}
