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
    
    @State var lastFactorFrac: [String: Double] = [:]
    
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
    
    // Keep toggles weaker
    private let factorWeight = 0.04
    
    // For turning animations on/off
    @State private var hasAppeared = false
    
    // For skipping the very first toggle-off animation
    @State private var firstToggleOff = true
    @State private var disableAnimationNow = false
    @State private var oldFactorEnableFrac: [String: Double] = [:]
    
    @State var tiltBarValue: Double = 0.0
    
    init() {
        setupNavBarAppearance()
    }
    
    var body: some View {
        Form {
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
            
            // Insert AdvancedSettingsSection here, just before the about section
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
        .onChange(of: factorIntensity) { newVal in
            let delta = newVal - oldFactorIntensity
            if delta == 0 {
                print("DEBUG: No change in slider value (delta is zero).")
            }
            shiftAllFactors(by: delta)
            oldFactorIntensity = newVal
            tiltBarValue = displayedTilt
        }
        .animation(hasAppeared ? (disableAnimationNow ? nil : .easeInOut(duration: 0.3)) : nil,
                   value: simSettings.factorEnableFrac)
        .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: factorIntensity)
        .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: displayedTilt)
        .overlayPreferenceValue(TooltipAnchorKey.self) { allItems in
            tooltipOverlay(allItems)
        }
        .onChange(of: simSettings.factorEnableFrac) { newVal in
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
            oldFactorEnableFrac = newVal
            tiltBarValue = displayedTilt
        }
        .onAppear {
            oldFactorEnableFrac = simSettings.factorEnableFrac
            hasAppeared = true
        }
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
    
    func computeActiveNetTilt() -> Double {
        let eff = invertedSCurve(factorIntensity, steepness: 12.0)
        var partialSum = 0.0
        let bullishTotal = bullishKeys.reduce(0.0) { accum, key in
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            let frac = gentleSCurve(raw, steepness: 2.0)
            return accum + frac * factorWeight
        }
        let bearishTotal = bearishKeys.reduce(0.0) { accum, key in
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            let frac = gentleSCurve(raw, steepness: 2.0)
            return accum + frac * factorWeight
        }
        partialSum = bullishTotal - bearishTotal
        let normalised = partialSum / Double(totalFactors)
        let netTilt = normalised * eff
        return netTilt
    }
    
    var displayedTilt: Double {
        guard simSettings.hasCapturedDefault else {
            return 0.0
        }
        let activeTilt = computeActiveNetTilt()
        let diff = activeTilt - simSettings.defaultTilt
        let fraction = diff / max(simSettings.maxSwing, 1e-9)
        let scaled = fraction * 1.7
        let finalTilt = tanh(8.0 * scaled)
        return finalTilt
    }
    
    func computeIfAllBullish() -> Double {
        let effective = invertedSCurve(1.0, steepness: 12.0)
        var sum = 0.0
        for _ in bullishKeys {
            let frac = gentleSCurve(1.0, steepness: 2.0)
            sum += frac * factorWeight
        }
        for _ in bearishKeys {
            let frac = gentleSCurve(0.0, steepness: 2.0)
            sum -= frac * factorWeight
        }
        let normalised = sum / Double(totalFactors)
        return normalised * effective
    }
    
    func computeIfAllBearish() -> Double {
        let effective = invertedSCurve(1.0, steepness: 12.0)
        var sum = 0.0
        for _ in bullishKeys {
            let frac = gentleSCurve(0.0, steepness: 2.0)
            sum += frac * factorWeight
        }
        for _ in bearishKeys {
            let frac = gentleSCurve(1.0, steepness: 2.0)
            sum -= frac * factorWeight
        }
        let normalised = sum / Double(totalFactors)
        return normalised * effective
    }
    
    private func gentleSCurve(_ x: Double, steepness: Double = 3.0) -> Double {
        1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
    
    private func invertedSCurve(_ x: Double, steepness: Double = 6.0) -> Double {
        1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }
    
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
