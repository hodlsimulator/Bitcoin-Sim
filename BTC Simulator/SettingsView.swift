//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

// MARK: - PressableDestructiveButtonStyle
struct PressableDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.red)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.none, value: configuration.isPressed)
    }
}

// MARK: - TooltipItem & PreferenceKey
struct TooltipItem {
    let title: String
    let description: String
    let anchor: Anchor<CGPoint>
}

struct TooltipAnchorKey: PreferenceKey {
    static var defaultValue: [TooltipItem] = []
    static func reduce(value: inout [TooltipItem], nextValue: () -> [TooltipItem]) {
        value.append(contentsOf: nextValue())
    }
}

struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false
    
    // Collapsed/expanded state for the Advanced disclosure
    @AppStorage("showAdvancedSettings") private var showAdvancedSettings: Bool = false
    
    // Factor Intensity in [0...1], default to 0.5
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    // Track old slider value, for shift-based math
    @State private var oldFactorIntensity: Double = 0.5
    
    @State private var showResetCriteriaConfirmation = false
    @State private var activeFactor: String? = nil
    
    init() {
        // Custom nav bar style
        let opaqueAppearance = UINavigationBarAppearance()
        opaqueAppearance.configureWithOpaqueBackground()
        opaqueAppearance.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // Large title
        opaqueAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        // Normal title
        opaqueAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]

        // Collapsed nav appearance
        let blurredAppearance = UINavigationBarAppearance()
        blurredAppearance.configureWithTransparentBackground()
        blurredAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        blurredAppearance.backgroundColor = UIColor(white: 0.12, alpha: 0.2)
        blurredAppearance.largeTitleTextAttributes = opaqueAppearance.largeTitleTextAttributes
        blurredAppearance.titleTextAttributes = opaqueAppearance.titleTextAttributes
        
        // Back button (just chevron)
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
            BullishFactorsSection(activeFactor: $activeFactor, toggleFactor: toggleFactor)
                .environmentObject(simSettings)
            
            // 6) Bearish Factors
            BearishFactorsSection(activeFactor: $activeFactor, toggleFactor: toggleFactor)
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
        // Shift-based approach instead of overwriting
        .onChange(of: factorIntensity) { newVal in
            let delta = newVal - oldFactorIntensity
            oldFactorIntensity = newVal
            shiftAllFactors(by: delta)
        }
        // Tooltip overlay
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
    }
    
    // MARK: - Tilt Bar
    private var overallTiltSection: some View {
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
    
    // This is the final displayed tilt: S-curve around factorIntensity=0.5 => zero
    private var displayedTilt: Double {
        let alpha = 4.0
        let raw = computeNetTilt()
        let offset = computeNetTilt(atIntensity: 0.5)
        let shifted = raw - offset
        let scaleFactor = 5.0
        return tanh(alpha * shifted * scaleFactor)
    }
    
    // Compute "Raw" Tilt from toggles
    private func computeNetTilt() -> Double {
        computeNetTilt(atIntensity: factorIntensity)
    }
    
    // If you want to see net tilt for a hypothetical intensity
    private func computeNetTilt(atIntensity intensity: Double) -> Double {
        func bull(minVal: Double, maxVal: Double, val: Bool = true) -> Double {
            // We only compute the range. The real factor is in simSettings,
            // but this sample formula used to rely on factorIntensity = intensity.
            // If you still want it to scale, you can do so. Or treat them as you prefer.
            minVal + intensity * (maxVal - minVal)
        }
        func bear(minVal: Double, maxVal: Double) -> Double {
            abs(minVal + intensity * (maxVal - minVal))
        }
        
        // We'll keep your original calculation.
        // It's fine if you still want the old net tilt logic that depends on
        // 'intensity' but not the actual factor's real-time value.
        
        var bullVal = 0.0
        var bearVal = 0.0
        
        // BULLISH
        if simSettings.useHalvingUnified {
            bullVal += bull(minVal: 0.2773386887, maxVal: 0.3823386887)
        }
        if simSettings.useInstitutionalDemandUnified {
            bullVal += bull(minVal: 0.00105315, maxVal: 0.00142485)
        }
        if simSettings.useCountryAdoptionUnified {
            bullVal += bull(minVal: 0.0009882799977, maxVal: 0.0012868959977)
        }
        if simSettings.useRegulatoryClarityUnified {
            bullVal += bull(minVal: 0.0005979474861605167, maxVal: 0.0008361034861605167)
        }
        if simSettings.useEtfApprovalUnified {
            bullVal += bull(minVal: 0.0014880183160305023, maxVal: 0.0020880183160305023)
        }
        if simSettings.useTechBreakthroughUnified {
            bullVal += bull(minVal: 0.0005015753579173088, maxVal: 0.0007150633579173088)
        }
        if simSettings.useScarcityEventsUnified {
            bullVal += bull(minVal: 0.00035112353681182863, maxVal: 0.00047505153681182863)
        }
        if simSettings.useGlobalMacroHedgeUnified {
            bullVal += bull(minVal: 0.0002868789724932909, maxVal: 0.0004126829724932909)
        }
        if simSettings.useStablecoinShiftUnified {
            bullVal += bull(minVal: 0.0002704809116327763, maxVal: 0.0003919609116327763)
        }
        if simSettings.useDemographicAdoptionUnified {
            bullVal += bull(minVal: 0.0008661432036626339, maxVal: 0.0012578432036626339)
        }
        if simSettings.useAltcoinFlightUnified {
            bullVal += bull(minVal: 0.0002381864461803342, maxVal: 0.0003222524461803342)
        }
        if simSettings.useAdoptionFactorUnified {
            bullVal += bull(minVal: 0.0013638349088897705, maxVal: 0.0018451869088897705)
        }
        
        // BEARISH
        if simSettings.useRegClampdownUnified {
            bearVal += bear(minVal: -0.0014273392243542672, maxVal: -0.0008449512243542672)
        }
        if simSettings.useCompetitorCoinUnified {
            bearVal += bear(minVal: -0.0011842141746411323, maxVal: -0.0008454221746411323)
        }
        if simSettings.useSecurityBreachUnified {
            bearVal += bear(minVal: -0.0012819675168380737, maxVal: -0.0009009755168380737)
        }
        if simSettings.useBubblePopUnified {
            bearVal += bear(minVal: -0.002244817890762329, maxVal: -0.001280529890762329)
        }
        if simSettings.useStablecoinMeltdownUnified {
            bearVal += bear(minVal: -0.0009681346159477233, maxVal: -0.0004600706159477233)
        }
        if simSettings.useBlackSwanUnified {
            bearVal += bear(minVal: -0.478662, maxVal: -0.319108)
        }
        if simSettings.useBearMarketUnified {
            bearVal += bear(minVal: -0.0010278802752494812, maxVal: -0.0007278802752494812)
        }
        if simSettings.useMaturingMarketUnified {
            bearVal += bear(minVal: -0.0020343461055486196, maxVal: -0.0010537001055486196)
        }
        if simSettings.useRecessionUnified {
            bearVal += bear(minVal: -0.0010516462467487811, maxVal: -0.0007494520467487811)
        }
        
        let total = bullVal + bearVal
        guard total > 0 else { return 0.0 }
        
        return (bullVal - bearVal) / total
    }
    
    // MARK: - Universal Factor Intensity (Slider)
    private var factorIntensitySection: some View {
        Section {
            HStack {
                Button {
                    factorIntensity = 0.0
                } label: {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                
                Slider(value: $factorIntensity, in: 0...1, step: 0.01)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                
                Button {
                    factorIntensity = 1.0
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
    private var toggleAllSection: some View {
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
    private var restoreDefaultsSection: some View {
        Section {
            Button(action: {
                simSettings.restoreDefaults()
                // Also reset the universal slider:
                factorIntensity = 0.5
                oldFactorIntensity = 0.5
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
    private var aboutSection: some View {
        Section {
            NavigationLink("About") {
                AboutView()
            }
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - Reset All Criteria
    private var resetCriteriaSection: some View {
        Section {
            Button("Reset All Criteria") {
                showResetCriteriaConfirmation = true
            }
            .buttonStyle(PressableDestructiveButtonStyle())
            .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation, actions: {
                Button("Reset", role: .destructive) {
                    simSettings.restoreDefaults()
                    didFinishOnboarding = false
                    factorIntensity = 0.5
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

// MARK: - SHIFT Approach
extension SettingsView {
    
    /// Adds `delta` * (range) to each factor in simSettings, clamped to [minVal...maxVal].
    private func shiftAllFactors(by delta: Double) {
        // We'll define a clamp function for convenience
        func clamp(_ x: Double, minVal: Double, maxVal: Double) -> Double {
            // Make sure minVal <= maxVal, even if they're negative
            let lower = min(minVal, maxVal)
            let upper = max(minVal, maxVal)
            return max(lower, min(upper, x))
        }
        
        // If you only want to shift weekly factors, or monthly factors,
        // check simSettings.periodUnit, etc. This example shows weekly.

        // ---------- BULLISH FACTORS ----------
        if simSettings.useHalvingUnified {
            let range = (0.3823386887 - 0.2773386887) // ~0.105
            simSettings.halvingBumpUnified = clamp(
                simSettings.halvingBumpUnified + delta * range,
                minVal: 0.2773386887,
                maxVal: 0.3823386887
            )
        }
        if simSettings.useInstitutionalDemandUnified {
            let range = (0.00142485 - 0.00105315)
            simSettings.maxDemandBoostUnified = clamp(
                simSettings.maxDemandBoostUnified + delta * range,
                minVal: 0.00105315,
                maxVal: 0.00142485
            )
        }
        if simSettings.useCountryAdoptionUnified {
            let range = (0.0012868959977 - 0.0009882799977)
            simSettings.maxCountryAdBoostUnified = clamp(
                simSettings.maxCountryAdBoostUnified + delta * range,
                minVal: 0.0009882799977,
                maxVal: 0.0012868959977
            )
        }
        if simSettings.useRegulatoryClarityUnified {
            let range = (0.0008361034861605167 - 0.0005979474861605167)
            simSettings.maxClarityBoostUnified = clamp(
                simSettings.maxClarityBoostUnified + delta * range,
                minVal: 0.0005979474861605167,
                maxVal: 0.0008361034861605167
            )
        }
        if simSettings.useEtfApprovalUnified {
            let range = (0.0020880183160305023 - 0.0014880183160305023)
            simSettings.maxEtfBoostUnified = clamp(
                simSettings.maxEtfBoostUnified + delta * range,
                minVal: 0.0014880183160305023,
                maxVal: 0.0020880183160305023
            )
        }
        if simSettings.useTechBreakthroughUnified {
            let range = (0.0007150633579173088 - 0.0005015753579173088)
            simSettings.maxTechBoostUnified = clamp(
                simSettings.maxTechBoostUnified + delta * range,
                minVal: 0.0005015753579173088,
                maxVal: 0.0007150633579173088
            )
        }
        if simSettings.useScarcityEventsUnified {
            let range = (0.00047505153681182863 - 0.00035112353681182863)
            simSettings.maxScarcityBoostUnified = clamp(
                simSettings.maxScarcityBoostUnified + delta * range,
                minVal: 0.00035112353681182863,
                maxVal: 0.00047505153681182863
            )
        }
        if simSettings.useGlobalMacroHedgeUnified {
            let range = (0.0004126829724932909 - 0.0002868789724932909)
            simSettings.maxMacroBoostUnified = clamp(
                simSettings.maxMacroBoostUnified + delta * range,
                minVal: 0.0002868789724932909,
                maxVal: 0.0004126829724932909
            )
        }
        if simSettings.useStablecoinShiftUnified {
            let range = (0.0003919609116327763 - 0.0002704809116327763)
            simSettings.maxStablecoinBoostUnified = clamp(
                simSettings.maxStablecoinBoostUnified + delta * range,
                minVal: 0.0002704809116327763,
                maxVal: 0.0003919609116327763
            )
        }
        if simSettings.useDemographicAdoptionUnified {
            let range = (0.0012578432036626339 - 0.0008661432036626339)
            simSettings.maxDemoBoostUnified = clamp(
                simSettings.maxDemoBoostUnified + delta * range,
                minVal: 0.0008661432036626339,
                maxVal: 0.0012578432036626339
            )
        }
        if simSettings.useAltcoinFlightUnified {
            let range = (0.0003222524461803342 - 0.0002381864461803342)
            simSettings.maxAltcoinBoostUnified = clamp(
                simSettings.maxAltcoinBoostUnified + delta * range,
                minVal: 0.0002381864461803342,
                maxVal: 0.0003222524461803342
            )
        }
        if simSettings.useAdoptionFactorUnified {
            let range = (0.0018451869088897705 - 0.0013638349088897705)
            simSettings.adoptionBaseFactorUnified = clamp(
                simSettings.adoptionBaseFactorUnified + delta * range,
                minVal: 0.0013638349088897705,
                maxVal: 0.0018451869088897705
            )
        }
        
        // ---------- BEARISH FACTORS ----------
        if simSettings.useRegClampdownUnified {
            let range = (-0.0008449512243542672 - (-0.0014273392243542672)) // ~0.000582388
            simSettings.maxClampDownUnified = clamp(
                simSettings.maxClampDownUnified + delta * range,
                minVal: -0.0014273392243542672,
                maxVal: -0.0008449512243542672
            )
        }
        if simSettings.useCompetitorCoinUnified {
            let range = (-0.0008454221746411323 - (-0.0011842141746411323))
            simSettings.maxCompetitorBoostUnified = clamp(
                simSettings.maxCompetitorBoostUnified + delta * range,
                minVal: -0.0011842141746411323,
                maxVal: -0.0008454221746411323
            )
        }
        if simSettings.useSecurityBreachUnified {
            let range = (-0.0009009755168380737 - (-0.0012819675168380737))
            simSettings.breachImpactUnified = clamp(
                simSettings.breachImpactUnified + delta * range,
                minVal: -0.0012819675168380737,
                maxVal: -0.0009009755168380737
            )
        }
        if simSettings.useBubblePopUnified {
            let range = (-0.001280529890762329 - (-0.002244817890762329))
            simSettings.maxPopDropUnified = clamp(
                simSettings.maxPopDropUnified + delta * range,
                minVal: -0.002244817890762329,
                maxVal: -0.001280529890762329
            )
        }
        if simSettings.useStablecoinMeltdownUnified {
            let range = (-0.0004600706159477233 - (-0.0009681346159477233))
            simSettings.maxMeltdownDropUnified = clamp(
                simSettings.maxMeltdownDropUnified + delta * range,
                minVal: -0.0009681346159477233,
                maxVal: -0.0004600706159477233
            )
        }
        if simSettings.useBlackSwanUnified {
            let range = (-0.319108 - (-0.478662)) // ~0.159554
            simSettings.blackSwanDropUnified = clamp(
                simSettings.blackSwanDropUnified + delta * range,
                minVal: -0.478662,
                maxVal: -0.319108
            )
        }
        if simSettings.useBearMarketUnified {
            let range = (-0.0007278802752494812 - (-0.0010278802752494812))
            simSettings.bearWeeklyDriftUnified = clamp(
                simSettings.bearWeeklyDriftUnified + delta * range,
                minVal: -0.0010278802752494812,
                maxVal: -0.0007278802752494812
            )
        }
        if simSettings.useMaturingMarketUnified {
            let range = (-0.0010537001055486196 - (-0.0020343461055486196))
            simSettings.maxMaturingDropUnified = clamp(
                simSettings.maxMaturingDropUnified + delta * range,
                minVal: -0.0020343461055486196,
                maxVal: -0.0010537001055486196
            )
        }
        if simSettings.useRecessionUnified {
            let range = (-0.0007494520467487811 - (-0.0010516462467487811))
            simSettings.maxRecessionDropUnified = clamp(
                simSettings.maxRecessionDropUnified + delta * range,
                minVal: -0.0010516462467487811,
                maxVal: -0.0007494520467487811
            )
        }
        
        // Done shifting. Now you can recalc tilt if you want,
        // but the SwiftUI .body automatically updates.
    }
    
    // MARK: - Tap factor -> show/hide tooltip
    private func toggleFactor(_ tappedTitle: String) {
        withAnimation {
            if activeFactor == tappedTitle {
                activeFactor = nil
            } else {
                activeFactor = tappedTitle
            }
        }
    }
}
