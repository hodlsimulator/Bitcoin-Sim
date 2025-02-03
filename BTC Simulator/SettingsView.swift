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
    
    // Global slider (and related tilt storage)
    @State var oldFactorIntensity: Double = 0.5
    @State var storedDefaultTilt: Double? = nil
    
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    // Stores the actual numeric value of each factor before toggling off
    @State var lastFactorValue: [String: Double] = [:]
    
    @State var dragTiltOverride: Double? = nil
    
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
    @State var oldFactorEnableFrac: [String: Double] = [:]
    
    @State var updatingFromFactorEnable: Bool = false
    
    // A helper dictionary to get/set each factor’s numeric property.
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
            // Updated overall tilt bar section:
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
            .onChange(of: simSettings.factorIntensity) { newValue in
                // We leave this empty so that moving the global slider doesn't
                // override individual factor values during an update.
                // (If you want to sync all factors when the slider is moved,
                // consider using the slider’s onEditingChanged closure.)
            }
            .onChange(of: simSettings.factorEnableFrac) { newVal in
                guard !simSettings.isRestoringDefaults else { return }
                
                disableAnimationNow = false

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

                let wasAllOffBefore = oldFactorEnableFrac.values.allSatisfy { $0 == 0.0 }
                let isAllOffNow = newVal.values.allSatisfy { $0 == 0.0 }

                for factorName in newVal.keys {
                    let oldFrac = oldFactorEnableFrac[factorName] ?? 0.0
                    let newFrac = newVal[factorName] ?? 0.0

                    if oldFrac > 0.0, newFrac == 0.0 {
                        if let accessor = factorAccessors[factorName] {
                            lastFactorValue[factorName] = accessor.get()
                        }
                    } else if oldFrac == 0.0, newFrac > 0.0 {
                        if let storedVal = lastFactorValue[factorName] {
                            let t = simSettings.factorIntensity
                            simSettings.manualOffsets[factorName] = storedVal - simSettings.baseValForFactor(factorName, intensity: t)
                            withTransaction(Transaction(animation: nil)) {
                                factorAccessors[factorName]?.set(storedVal)
                            }
                        } else {
                            withTransaction(Transaction(animation: nil)) {
                                factorAccessors[factorName]?.set(0.5)
                            }
                        }
                    }
                }
                
                if !wasAllOffBefore && isAllOffNow {
                    storedDefaultTilt = simSettings.defaultTilt
                    simSettings.defaultTilt = 0.0
                    simSettings.hasCapturedDefault = true
                    simSettings.maxSwing = 1.0
                }
                
                if wasAllOffBefore && !isAllOffNow {
                    if let storedTilt = storedDefaultTilt {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            simSettings.defaultTilt = storedTilt
                        }
                        storedDefaultTilt = nil
                    } else {
                        simSettings.defaultTilt = computeActiveNetTilt()
                    }
                }

                oldFactorEnableFrac = newVal

                simSettings.tiltBarValue = displayedTilt

                // --- NEW CODE: Compute the global slider value using the 12×9 logic ---
                let bullishKeysLocal = ["Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
                                          "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
                                          "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"]
                let bearishKeysLocal = ["RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
                                          "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket", "Recession"]
                
                let totalBullish = bullishKeysLocal.reduce(0.0) { $0 + (newVal[$1] ?? 0) }
                let totalBearish = bearishKeysLocal.reduce(0.0) { $0 + (newVal[$1] ?? 0) }
                
                // Calculate the proportion on each side:
                let avgBullish = totalBullish / Double(bullishKeysLocal.count)
                let avgBearish = totalBearish / Double(bearishKeysLocal.count)
                
                // Net tilt in the range [-1, 1]. (When all are on, avgBullish and avgBearish are 1, so net = 0.)
                let net = avgBullish - avgBearish
                simSettings.factorIntensity = (net + 1) / 2
                // --- End new code ---
            }
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: simSettings.factorIntensity)
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: displayedTilt)
    }
    
    // ----- Tilt Calculation & Helpers -----
    
    var displayedTilt: Double {
        // Map the slider (factorIntensity, 0…1) to a tilt from –1 to 1.
        let sliderTilt = simSettings.factorIntensity * 2 - 1

        // Check if any toggle fractions are active.
        let togglesActive = !simSettings.factorEnableFrac.values.allSatisfy { $0 == 0.0 }
        if togglesActive {
            // Define the factor keys.
            let bullishKeys = ["Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
                                 "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
                                 "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"]
            let bearishKeys = ["RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
                               "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket", "Recession"]

            // Compute average activations.
            let normalizedBullish = bullishKeys.reduce(0.0) { $0 + (simSettings.factorEnableFrac[$1] ?? 0) } / Double(bullishKeys.count)
            let normalizedBearish = bearishKeys.reduce(0.0) { $0 + (simSettings.factorEnableFrac[$1] ?? 0) } / Double(bearishKeys.count)
            let net = normalizedBullish - normalizedBearish
            // Use an arctan transform for a smooth s‑curve on the toggle component.
            let toggleTilt = (2.6 / .pi) * atan(5.0 * net)
            // Combine the slider and toggles (and clamp the result).
            return min(max(sliderTilt + toggleTilt, -1), 1)
        } else {
            return sliderTilt
        }
    }
    
    func computeActiveNetTilt() -> Double {
        let anyActive = simSettings.factorEnableFrac.values.contains { $0 > 0.0 }
        guard anyActive else {
            return 0.0
        }
        let eff = invertedSCurve(simSettings.factorIntensity, steepness: 12.0)
        
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
    
    // ----- Tooltip Overlay -----
    
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
