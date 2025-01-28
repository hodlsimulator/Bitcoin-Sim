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
    
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    @State var oldFactorIntensity: Double = 0.5
    
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    private let bullishKeys: [String] = [
        "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
        "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
        "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
    ]
    private let bearishKeys: [String] = [
        "RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
        "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket",
        "Recession"
    ]
    private var totalFactors: Int {
        bullishKeys.count + bearishKeys.count
    }
    
    // Keep toggles weaker
    private let factorWeight = 0.05
    
    // We measure your default tilt & max swing, then normalise around them
    @State private var defaultTilt: Double = 0.0
    @State private var maxSwing: Double = 1.0
    
    // For turning animations on/off
    @State private var hasCapturedDefault = false
    @State private var hasAppeared = false
    
    init() {
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
    
    var body: some View {
        Form {
            
            // 1) Tilt Bar
            overallTiltSection
            
            // 2) Universal Factor Intensity
            factorIntensitySection
            
            // 3) Toggle All Factors
            toggleAllSection
            
            // 4) "Restore Defaults"
            restoreDefaultsSection
            
            // 5) Bullish Factors
            BullishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: toggleFactor,
                factorEnableFrac: $simSettings.factorEnableFrac,
                animateFactor: animateFactor
            )
            .environmentObject(simSettings)
            
            // 6) Bearish Factors
            BearishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: toggleFactor,
                factorEnableFrac: $simSettings.factorEnableFrac,
                animateFactor: animateFactor
            )
            .environmentObject(simSettings)
            
            // 7) Advanced Disclosure
            AdvancedSettingsSection(showAdvancedSettings: $showAdvancedSettings)
            
            // 8) About
            aboutSection
            
            // 9) Reset All
            resetCriteriaSection
            
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.12))
        .environment(\.colorScheme, .dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        
        // Keep the shiftAllFactors logic
        .onChange(of: factorIntensity) { newVal in
            let delta = newVal - oldFactorIntensity
            oldFactorIntensity = newVal
            shiftAllFactors(by: delta)
        }
        
        // Animate changes only after we've appeared & captured default
        .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: factorIntensity)
        .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: simSettings.factorEnableFrac)
        .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: displayedTilt)
        
        .overlayPreferenceValue(TooltipAnchorKey.self) { allAnchors in
            GeometryReader { proxy in
                if let item = allAnchors.last {
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
        .attachFactorWatchers(
            simSettings: simSettings,
            factorIntensity: factorIntensity,
            oldFactorIntensity: oldFactorIntensity,
            animateFactor: animateFactor,
            updateUniversalFactorIntensity: updateUniversalFactorIntensity
        )
        
        .onAppear {
            // Hide animations for initial load
            hasAppeared = false
            
            // Wait a little so toggles from simSettings definitely load
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                defaultTilt = computeActiveNetTilt()
                
                // Check how far "all bull" or "all bear" are from that default
                let allBull = computeIfAllBullish() - defaultTilt
                let allBear = computeIfAllBearish() - defaultTilt
                maxSwing = max(abs(allBull), abs(allBear), 0.00001) // no zero division
                
                hasCapturedDefault = true
                // Turn animations on now that default is established
                hasAppeared = true
            }
        }
    }
    
    // ---------------------------------------------------------------------------------
    // "All-bull" & "all-bear" to figure out the maximum possible tilt from default
    // ---------------------------------------------------------------------------------
    
    private func computeIfAllBullish() -> Double {
        // Pretend factorIntensity=1.0 for max effect
        let effective = invertedSCurve(1.0, steepness: 12.0)
        var sum = 0.0
        
        // Force all bullish toggles "on"
        for _ in bullishKeys {
            let frac = gentleSCurve(1.0, steepness: 2.0)
            sum += frac * factorWeight
        }
        // Force all bearish toggles "off"
        for _ in bearishKeys {
            let frac = gentleSCurve(0.0, steepness: 2.0)
            sum -= frac * factorWeight
        }
        
        let normalised = sum / Double(totalFactors)
        return normalised * effective
    }

    private func computeIfAllBearish() -> Double {
        // Also pretend factorIntensity=1.0
        let effective = invertedSCurve(1.0, steepness: 12.0)
        var sum = 0.0
        
        // Force all bullish toggles "off"
        for _ in bullishKeys {
            let frac = gentleSCurve(0.0, steepness: 2.0)
            sum += frac * factorWeight
        }
        // Force all bearish toggles "on"
        for _ in bearishKeys {
            let frac = gentleSCurve(1.0, steepness: 2.0)
            sum -= frac * factorWeight
        }
        
        let normalised = sum / Double(totalFactors)
        return normalised * effective
    }
    
    // ------------------ Helpers ------------------
    
    func syncFactorToSlider(
        _ currentValue: inout Double,
        minVal: Double,
        maxVal: Double
    ) {
        let t = factorIntensity
        currentValue = minVal + t * (maxVal - minVal)
    }
    
    private func updateUniversalFactorIntensity(_: String) {
        // optional stub
    }
    
    // -----------------------------------
    // Net Tilt Calculation
    // -----------------------------------
    
    var displayedTilt: Double {
        // If we haven't measured default yet, show 0 so we appear neutral
        if !hasCapturedDefault { return 0.0 }
        
        // normalise by maxSwing
        let fraction = (computeActiveNetTilt() - defaultTilt) / maxSwing
        
        // scale fraction to let the bar reach ±1
        let scaled = fraction * 1.5
        
        // moderate alpha so we’re not too sharp near 0
        return tanh(8.0 * scaled)
    }
    
    private func computeActiveNetTilt() -> Double {
        // The "global slider" effect
        let effective = invertedSCurve(factorIntensity, steepness: 12.0)
        
        var sum = 0.0
        for key in bullishKeys {
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            // toggles are gentle => steepness=2.0
            let frac = gentleSCurve(raw, steepness: 2.0)
            sum += frac * factorWeight
        }
        for key in bearishKeys {
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            let frac = gentleSCurve(raw, steepness: 2.0)
            sum -= frac * factorWeight
        }
        
        let normalised = sum / Double(totalFactors)
        return normalised * effective
    }
    
    // Optional older baseline logic
    private func baselineNetTilt() -> Double {
        let fractionIfOn = gentleSCurve(1.0, steepness: 4.0)
        let effectiveAtMid = invertedSCurve(0.5, steepness: 12.0)
        
        var sum = 0.0
        for _ in bullishKeys {
            sum += fractionIfOn * factorWeight
        }
        for _ in bearishKeys {
            sum -= fractionIfOn * factorWeight
        }
        
        let normalised = sum / Double(totalFactors)
        return normalised * effectiveAtMid
    }
    
    private func gentleSCurve(_ x: Double, steepness: Double = 3.0) -> Double {
        return 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
    
    private func invertedSCurve(_ x: Double, steepness: Double = 6.0) -> Double {
        // It's a normal logistic from 0..1
        return 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
}
