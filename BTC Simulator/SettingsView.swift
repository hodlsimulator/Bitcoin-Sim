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
    
    @State var isExtremeToggle: Bool = false
    @State var extremeToggleApplied: Bool = false
    
    @State var isChartExtremeBearish = false
    @State var isChartExtremeBullish = false
    
    @State var disableFactorSync = false

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
    
    @State var isManualOverride: Bool = false
    
    // ---- NEW: Store the old net tilt so we can compute deltas. ----
    @State private var oldNetValue: Double = 1.0  // or 0.0 if you start more neutral
    
    // A helper dictionary to get/set each factor’s numeric property.
    var computedFactorAccessors: [String: (get: () -> Double, set: (Double) -> Void)] {
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
    
    // ------------------------------
    // MARK: - View Body
    // ------------------------------
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
                
                // If we start near tilt=0, set factorIntensity to displayedTilt if needed
                if abs(simSettings.tiltBarValue) < 0.0000001 {
                    simSettings.tiltBarValue = displayedTilt
                }
                
                // If you want, detect pureBullish or pureBearish on appear:
                if isCurrentlyExtremeBearish {
                    oldNetValue = -1.0
                } else if isCurrentlyExtremeBullish {
                    oldNetValue = 1.0
                } else {
                    // Otherwise compute net now:
                    let net = computeCurrentNetTilt(bullishKeys, bearishKeys, simSettings.factorEnableFrac)
                    oldNetValue = net
                }
            }
            .onChange(of: simSettings.factorIntensity) { _ in
                // We leave this empty so that moving the global slider
                // doesn't override single factors.
            }
            .onChange(of: simSettings.factorEnableFrac) { newVal in
                if disableFactorSync { return }
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
                        if let accessor = simSettings.factorAccessors[factorName] {
                            lastFactorValue[factorName] = accessor.get()
                        }
                    } else if oldFrac == 0.0, newFrac > 0.0 {
                        if let storedVal = lastFactorValue[factorName] {
                            let t = simSettings.factorIntensity
                            simSettings.manualOffsets[factorName] = storedVal - simSettings.baseValForFactor(factorName, intensity: t)
                            withTransaction(Transaction(animation: nil)) {
                                simSettings.factorAccessors[factorName]?.set(storedVal)
                            }
                        } else {
                            withTransaction(Transaction(animation: nil)) {
                                simSettings.factorAccessors[factorName]?.set(0.5)
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

                // --- Part A: Skip if manual override is in effect ---
                guard !isManualOverride else {
                    return
                }

                // --- Part B: “Skip if pure” check ---
                let bullishKeysLocal = bullishKeys
                let bearishKeysLocal = bearishKeys

                let allBullishOn  = bullishKeysLocal.allSatisfy  { (newVal[$0] ?? 0.0) >= 0.9999 }
                let allBearishOff = bearishKeysLocal.allSatisfy { (newVal[$0] ?? 1.0) <= 0.0001 }
                let pureBullish = (allBullishOn && allBearishOff)

                let allBearishOn  = bearishKeysLocal.allSatisfy  { (newVal[$0] ?? 0.0) >= 0.9999 }
                let allBullishOff = bullishKeysLocal.allSatisfy { (newVal[$0] ?? 1.0) <= 0.0001 }
                let pureBearish = (allBearishOn && allBullishOff)

                // If toggles are in a pure scenario, set oldNetValue to ±1 & return
                if pureBullish {
                    oldNetValue = 1.0
                    return
                }
                if pureBearish {
                    oldNetValue = -1.0
                    return
                }

                // --- Part C: difference-based approach so we don't snap. ---
                // 1) Compute net in –1..+1
                let net = computeCurrentNetTilt(bullishKeysLocal, bearishKeysLocal, newVal)

                // 2) figure out how much net changed since last time
                let oldN = oldNetValue
                let delta = net - oldN

                // 3) scale that delta => factorIntensity
                let scale = 0.3  // tweak me
                let oldIntensity = simSettings.factorIntensity

                // each +1 net => +1 intensity, so if delta=–0.02 => intensity changes by –0.006
                var newIntensity = oldIntensity + scale * delta * 0.5

                // clamp 0..1
                if newIntensity > 1.0 { newIntensity = 1.0 }
                if newIntensity < 0.0 { newIntensity = 0.0 }

                simSettings.factorIntensity = newIntensity

                // 4) update oldNetValue for next time
                oldNetValue = net
            }
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: simSettings.factorIntensity)
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: displayedTilt)
    }
    
    // Helper to compute net from factorEnableFrac
    func computeCurrentNetTilt(
        _ bullishKeys: [String],
        _ bearishKeys: [String],
        _ fractions: [String: Double]
    ) -> Double {
        let totalBullish = bullishKeys.reduce(0.0) { $0 + (fractions[$1] ?? 0.0) }
        let totalBearish = bearishKeys.reduce(0.0) { $0 + (fractions[$1] ?? 0.0) }
        
        let avgBullish = totalBullish / Double(bullishKeys.count)
        let avgBearish = totalBearish / Double(bearishKeys.count)
        let net = avgBullish - avgBearish  // –1..+1
        return max(min(net, 1.0), -1.0)    // clamp if needed
    }
    
    var isCurrentlyExtremeBullish: Bool {
        let epsilon = 0.0001
        // Must have factorIntensity right near 1.0...
        guard abs(simSettings.factorIntensity - 1.0) < epsilon else { return false }
        // ...all bullish sliders at ~1.0
        for key in bullishKeys {
            if (simSettings.factorEnableFrac[key] ?? 0.0) < 1.0 - epsilon {
                return false
            }
        }
        // ...and all bearish sliders at ~0.0
        for key in bearishKeys {
            if (simSettings.factorEnableFrac[key] ?? 1.0) > epsilon {
                return false
            }
        }
        return true
    }

    var isCurrentlyExtremeBearish: Bool {
        let epsilon = 0.0001
        // Must have factorIntensity near 0...
        guard abs(simSettings.factorIntensity - 0.0) < epsilon else { return false }
        // ...all bearish sliders at ~1.0
        for key in bearishKeys {
            if (simSettings.factorEnableFrac[key] ?? 0.0) < 1.0 - epsilon {
                return false
            }
        }
        // ...and all bullish sliders at ~0.0
        for key in bullishKeys {
            if (simSettings.factorEnableFrac[key] ?? 1.0) > epsilon {
                return false
            }
        }
        return true
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
    
    // Helper functions to apply an extreme state:
    func applyExtremeBullish() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Set global slider and tilt bar to extreme bullish.
            simSettings.factorIntensity = 1.0
            simSettings.tiltBarValue = 1.0
            
            // Force all bullish factors ON and bearish factors OFF.
            for key in bullishKeys {
                simSettings.factorEnableFrac[key] = 1.0
                // Use your factor accessor to update the numeric property.
                computedFactorAccessors[key]?.set(1.0)
            }
            for key in bearishKeys {
                simSettings.factorEnableFrac[key] = 0.0
                computedFactorAccessors[key]?.set(0.0)
            }
            extremeToggleApplied = true
        }
    }

    func applyExtremeBearish() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Set global slider and tilt bar to extreme bearish.
            simSettings.factorIntensity = 0.0
            simSettings.tiltBarValue = -1.0
            
            // Force all bearish factors ON and bullish factors OFF.
            for key in bearishKeys {
                simSettings.factorEnableFrac[key] = 1.0
                computedFactorAccessors[key]?.set(1.0)
            }
            for key in bullishKeys {
                simSettings.factorEnableFrac[key] = 0.0
                computedFactorAccessors[key]?.set(0.0)
            }
            extremeToggleApplied = true
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
