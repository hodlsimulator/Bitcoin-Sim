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
    
    // Just listing factor keys for clarity
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
    
    init() {
        // Navigation bar styling ...
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
        let mainForm = Form {
            
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
        .onChange(of: factorIntensity) { newVal in
            let delta = newVal - oldFactorIntensity
            oldFactorIntensity = newVal
            shiftAllFactors(by: delta)
        }
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
        .transaction { txn in
            txn.animation = nil
        }
        .attachFactorWatchers(
            simSettings: simSettings,
            factorIntensity: factorIntensity,
            oldFactorIntensity: oldFactorIntensity,
            animateFactor: animateFactor,
            updateUniversalFactorIntensity: updateUniversalFactorIntensity
        )
        
        return mainForm
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
        // All off => neutral
        if simSettings.factorEnableFrac.values.allSatisfy({ $0 == 0.0 }) {
            return 0.0
        }
        
        // We'll apply an offset from the baseline, then a tanh scaling
        let alpha = 4.0
        let scaleFactor = 5.0
        
        let raw = computeActiveNetTilt()
        let base = baselineNetTilt() // we subtract this
        let shifted = raw - base
        
        return tanh(alpha * shifted * scaleFactor)
    }
    
    // UPDATED BASELINE: do the same sum-of-sCurves but with fraction=1 for every factor,
    // then multiply by `invertedSCurve(0.5)`, so it exactly matches a scenario of “all toggles on at 0.5”.
    private func baselineNetTilt() -> Double {
        // Pretend each factor is turned on fully => fraction=1 => s-curve(1)
        let fractionIfOn = gentleSCurve(1.0, steepness: 3.0) // ~0.8187, not 1.0
        let effectiveAtMid = invertedSCurve(0.5, steepness: 6.0) // typically 0.5
        
        var sum = 0.0
        for _ in bullishKeys {
            sum += fractionIfOn
        }
        for _ in bearishKeys {
            sum -= fractionIfOn
        }
        
        let normalised = sum / Double(totalFactors)
        return normalised * effectiveAtMid
    }
    
    private func computeActiveNetTilt() -> Double {
        let effective = invertedSCurve(factorIntensity, steepness: 6.0)
        
        var sum = 0.0
        for key in bullishKeys {
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            let frac = gentleSCurve(raw, steepness: 3.0)
            sum += frac
        }
        for key in bearishKeys {
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            let frac = gentleSCurve(raw, steepness: 3.0)
            sum -= frac
        }
        
        let normalised = sum / Double(totalFactors)
        return normalised * effective
    }
    
    private func gentleSCurve(_ x: Double, steepness: Double = 3.0) -> Double {
        return 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
    
    private func invertedSCurve(_ x: Double, steepness: Double = 6.0) -> Double {
        return 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
}
