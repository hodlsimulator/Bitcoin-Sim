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
    
    // MARK: - Tilt & Slider
    @State var oldFactorIntensity: Double = 0.5
    @State var storedDefaultTilt: Double? = nil
    
    // Confirmation & selection
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    // Toggling animations & extremes
    @State var hasAppeared = false
    @State var isExtremeToggle = false
    @State var extremeToggleApplied = false
    
    // Manual override of tilt
    @State var dragTiltOverride: Double? = nil
    
    // We used to store fraction-based values, but now removed them
    // We also removed factorEnableFrac references
    // We no longer track lastFactorValue or manualOffsets
    // We removed oldFactorEnableFrac, factorAccessors, etc.
    
    // For toggling
    @State var disableFactorSync = false
    @State var isManualOverride: Bool = false
    
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
    
    // Used to compute net tilt changes
    @State private var oldNetValue: Double = 0.0
    
    init() {
        setupNavBarAppearance()
    }
    
    // MARK: - Body
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
                }
            )
            .environmentObject(simSettings)
            
            BearishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: { factorName in
                    activeFactor = factorName
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
                hasAppeared = true
                // If tiltBarValue is near zero, we set a displayed tilt
                if abs(simSettings.tiltBarValue) < 0.0000001 {
                    simSettings.tiltBarValue = displayedTilt
                }
                // Compute an initial net if desired
                oldNetValue = 0.0
            }
            // If you had onChange logic for factorEnableFrac, we remove it entirely
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: simSettings.factorIntensity)
            .animation(hasAppeared ? .easeInOut(duration: 0.3) : nil, value: displayedTilt)
    }

    // MARK: - Tilt Computation
    // If you want to do something fancy with “displayedTilt” that used to combine fraction-based toggles,
    // you can remove or simplify:
    var displayedTilt: Double {
        // Just map factorIntensity in 0..1 to –1..+1
        simSettings.factorIntensity * 2 - 1
    }

    // MARK: - Tooltip Overlay
    @ViewBuilder
    private func tooltipOverlay(_ allItems: [TooltipItem]) -> some View {
        GeometryReader { proxy in
            if let item = allItems.last {
                let bubbleWidth: CGFloat = 240
                let bubbleHeight: CGFloat = 220
                let offset: CGFloat = 8
                let anchorPoint = proxy[item.anchor]
                
                let anchorX = anchorPoint.x
                let anchorY = anchorPoint.y
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

    // MARK: - Nav Bar Appearance
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
