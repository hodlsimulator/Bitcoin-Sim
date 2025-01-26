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
    
    // Factor Intensity in [0...1].
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    
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
        // Whenever we appear or intensity changes, re-apply factor values.
        .onAppear {
            updateAllFactors()
        }
        .onChange(of: factorIntensity) { _ in
            updateAllFactors()
        }
        // Recompute intensities any time a factor toggle changes.
        .onReceive(simSettings.objectWillChange) { _ in
            updateAllFactors()
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
    
    // MARK: - Tilt Bar (uses offset so factorIntensity=0.5 => tilt=0)
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
    
    // This is the final displayed tilt: we do an S-curve around an offset so that
    // factorIntensity=0.5 => bar is exactly neutral/zero.
    private var displayedTilt: Double {
        let alpha = 4.0
        let raw = computeNetTilt(for: factorIntensity)
        let offset = computeNetTilt(for: 0.5)
        let shifted = raw - offset
        
        // Because the net tilt is now about 1/5 as large,
        // multiply by 5 to preserve the old bar range.
        let scaleFactor = 5.0
        let scaled = shifted * scaleFactor

        return tanh(alpha * scaled)
    }
    
    // Compute "Raw" Tilt from all toggles
    private func computeNetTilt(for intensity: Double) -> Double {
        func bull(minVal: Double, maxVal: Double) -> Double {
            minVal + intensity * (maxVal - minVal)
        }
        func bear(minVal: Double, maxVal: Double) -> Double {
            // We'll add its absolute value to bearVal
            abs(minVal + intensity * (maxVal - minVal))
        }
        
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
    
    // MARK: - Universal Factor Intensity
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
            Text("Scales all bullish & bearish factors. Left (red) = max bear, right (green) = max bull.")
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
    
    // MARK: - Restore Defaults (full-width tappable)
    private var restoreDefaultsSection: some View {
        Section {
            Button(action: {
                simSettings.restoreDefaults()
                updateAllFactors()
            }) {
                HStack {
                    Text("Restore Defaults")
                        .foregroundColor(.red)
                    Spacer()
                }
                .contentShape(Rectangle()) // Ensures entire row is tappable
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
                    updateAllFactors()
                }
                Button("Cancel", role: .cancel) { }
            }, message: {
                Text("All custom criteria will be restored to default. This cannot be undone.")
            })
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - Update All Factors
    private func updateAllFactors() {
        func setBullish(_ current: inout Double, minVal: Double, maxVal: Double) {
            let newVal = minVal + factorIntensity * (maxVal - minVal)
            current = newVal
        }
        func setBearish(_ current: inout Double, minVal: Double, maxVal: Double) {
            let newVal = minVal + factorIntensity * (maxVal - minVal)
            current = newVal
        }
        
        if simSettings.periodUnit == .weeks {
            // BULLISH
            if simSettings.useHalvingUnified {
                setBullish(&simSettings.halvingBumpUnified,
                           minVal: 0.2773386887,
                           maxVal: 0.3823386887)
            }
            if simSettings.useInstitutionalDemandUnified {
                setBullish(&simSettings.maxDemandBoostUnified,
                           minVal: 0.00105315,
                           maxVal: 0.00142485)
            }
            if simSettings.useCountryAdoptionUnified {
                setBullish(&simSettings.maxCountryAdBoostUnified,
                           minVal: 0.0009882799977,
                           maxVal: 0.0012868959977)
            }
            if simSettings.useRegulatoryClarityUnified {
                setBullish(&simSettings.maxClarityBoostUnified,
                           minVal: 0.0005979474861605167,
                           maxVal: 0.0008361034861605167)
            }
            if simSettings.useEtfApprovalUnified {
                setBullish(&simSettings.maxEtfBoostUnified,
                           minVal: 0.0014880183160305023,
                           maxVal: 0.0020880183160305023)
            }
            if simSettings.useTechBreakthroughUnified {
                setBullish(&simSettings.maxTechBoostUnified,
                           minVal: 0.0005015753579173088,
                           maxVal: 0.0007150633579173088)
            }
            if simSettings.useScarcityEventsUnified {
                setBullish(&simSettings.maxScarcityBoostUnified,
                           minVal: 0.00035112353681182863,
                           maxVal: 0.00047505153681182863)
            }
            if simSettings.useGlobalMacroHedgeUnified {
                setBullish(&simSettings.maxMacroBoostUnified,
                           minVal: 0.0002868789724932909,
                           maxVal: 0.0004126829724932909)
            }
            if simSettings.useStablecoinShiftUnified {
                setBullish(&simSettings.maxStablecoinBoostUnified,
                           minVal: 0.0002704809116327763,
                           maxVal: 0.0003919609116327763)
            }
            if simSettings.useDemographicAdoptionUnified {
                setBullish(&simSettings.maxDemoBoostUnified,
                           minVal: 0.0008661432036626339,
                           maxVal: 0.0012578432036626339)
            }
            if simSettings.useAltcoinFlightUnified {
                setBullish(&simSettings.maxAltcoinBoostUnified,
                           minVal: 0.0002381864461803342,
                           maxVal: 0.0003222524461803342)
            }
            if simSettings.useAdoptionFactorUnified {
                setBullish(&simSettings.adoptionBaseFactorUnified,
                           minVal: 0.0013638349088897705,
                           maxVal: 0.0018451869088897705)
            }
            
            // BEARISH
            if simSettings.useRegClampdownUnified {
                setBearish(&simSettings.maxClampDownUnified,
                           minVal: -0.0014273392243542672,
                           maxVal: -0.0008449512243542672)
            }
            if simSettings.useCompetitorCoinUnified {
                setBearish(&simSettings.maxCompetitorBoostUnified,
                           minVal: -0.0011842141746411323,
                           maxVal: -0.0008454221746411323)
            }
            if simSettings.useSecurityBreachUnified {
                setBearish(&simSettings.breachImpactUnified,
                           minVal: -0.0012819675168380737,
                           maxVal: -0.0009009755168380737)
            }
            if simSettings.useBubblePopUnified {
                setBearish(&simSettings.maxPopDropUnified,
                           minVal: -0.002244817890762329,
                           maxVal: -0.001280529890762329)
            }
            if simSettings.useStablecoinMeltdownUnified {
                setBearish(&simSettings.maxMeltdownDropUnified,
                           minVal: -0.0009681346159477233,
                           maxVal: -0.0004600706159477233)
            }
            if simSettings.useBlackSwanUnified {
                setBearish(&simSettings.blackSwanDropUnified,
                           minVal: -0.478662,
                           maxVal: -0.319108)
            }
            if simSettings.useBearMarketUnified {
                setBearish(&simSettings.bearWeeklyDriftUnified,
                           minVal: -0.0010278802752494812,
                           maxVal: -0.0007278802752494812)
            }
            if simSettings.useMaturingMarketUnified {
                setBearish(&simSettings.maxMaturingDropUnified,
                           minVal: -0.0020343461055486196,
                           maxVal: -0.0010537001055486196)
            }
            if simSettings.useRecessionUnified {
                setBearish(&simSettings.maxRecessionDropUnified,
                           minVal: -0.0010516462467487811,
                           maxVal: -0.0007494520467487811)
            }
            
        } else {
            // Monthly or other period
            // (Same logic, but with compressed ranges preserving midpoints)
            if simSettings.useHalvingUnified {
                setBullish(&simSettings.halvingBumpUnified,
                           minVal: 0.2975,
                           maxVal: 0.4025)
            }
            if simSettings.useInstitutionalDemandUnified {
                setBullish(&simSettings.maxDemandBoostUnified,
                           minVal: 0.00481014,
                           maxVal: 0.00650783)
            }
            if simSettings.useCountryAdoptionUnified {
                setBullish(&simSettings.maxCountryAdBoostUnified,
                           minVal: 0.00468819,
                           maxVal: 0.00634284)
            }
            if simSettings.useRegulatoryClarityUnified {
                setBullish(&simSettings.maxClarityBoostUnified,
                           minVal: 0.00346267,
                           maxVal: 0.00468479)
            }
            if simSettings.useEtfApprovalUnified {
                setBullish(&simSettings.maxEtfBoostUnified,
                           minVal: 0.00485714,
                           maxVal: 0.00657143)
            }
            if simSettings.useTechBreakthroughUnified {
                setBullish(&simSettings.maxTechBoostUnified,
                           minVal: 0.00241294,
                           maxVal: 0.00326448)
            }
            if simSettings.useScarcityEventsUnified {
                setBullish(&simSettings.maxScarcityBoostUnified,
                           minVal: 0.00279894,
                           maxVal: 0.00378680)
            }
            if simSettings.useGlobalMacroHedgeUnified {
                setBullish(&simSettings.maxMacroBoostUnified,
                           minVal: 0.00275760,
                           maxVal: 0.00373088)
            }
            if simSettings.useStablecoinShiftUnified {
                setBullish(&simSettings.maxStablecoinBoostUnified,
                           minVal: 0.00195853,
                           maxVal: 0.00264977)
            }
            if simSettings.useDemographicAdoptionUnified {
                setBullish(&simSettings.maxDemoBoostUnified,
                           minVal: 0.00619746,
                           maxVal: 0.00838479)
            }
            if simSettings.useAltcoinFlightUnified {
                setBullish(&simSettings.maxAltcoinBoostUnified,
                           minVal: 0.00183318,
                           maxVal: 0.00248018)
            }
            if simSettings.useAdoptionFactorUnified {
                setBullish(&simSettings.adoptionBaseFactorUnified,
                           minVal: 0.01246182,
                           maxVal: 0.01686010)
            }
            
            // BEARISH
            if simSettings.useRegClampdownUnified {
                setBearish(&simSettings.maxClampDownUnified,
                           minVal: -0.023,
                           maxVal: -0.017)
            }
            if simSettings.useCompetitorCoinUnified {
                setBearish(&simSettings.maxCompetitorBoostUnified,
                           minVal: -0.0092,
                           maxVal: -0.0068)
            }
            if simSettings.useSecurityBreachUnified {
                setBearish(&simSettings.breachImpactUnified,
                           minVal: -0.00805,
                           maxVal: -0.00595)
            }
            if simSettings.useBubblePopUnified {
                setBearish(&simSettings.maxPopDropUnified,
                           minVal: -0.0115,
                           maxVal: -0.0085)
            }
            if simSettings.useStablecoinMeltdownUnified {
                setBearish(&simSettings.maxMeltdownDropUnified,
                           minVal: -0.0115,
                           maxVal: -0.0085)
            }
            if simSettings.useBlackSwanUnified {
                setBearish(&simSettings.blackSwanDropUnified,
                           minVal: -0.48,
                           maxVal: -0.32)
            }
            if simSettings.useBearMarketUnified {
                setBearish(&simSettings.bearWeeklyDriftUnified,
                           minVal: -0.0115,
                           maxVal: -0.0085)
            }
            if simSettings.useMaturingMarketUnified {
                setBearish(&simSettings.maxMaturingDropUnified,
                           minVal: -0.0115,
                           maxVal: -0.0085)
            }
            if simSettings.useRecessionUnified {
                setBearish(&simSettings.maxRecessionDropUnified,
                           minVal: -0.00159589,
                           maxVal: -0.00130573)
            }
        }
    }
    
    // MARK: - Tap factor titles => show/hide tooltip only
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
