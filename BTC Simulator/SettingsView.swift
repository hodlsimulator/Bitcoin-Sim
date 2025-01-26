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
    // 0 => fully bearish, 1 => fully bullish
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
        .onAppear {
            // If you still need your old factor-scaling logic at startup:
            updateAllFactors()
        }
        .onChange(of: factorIntensity) { _ in
            // If you still need your old factor-scaling logic whenever factorIntensity changes:
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
    
    // MARK: - Tilt Bar (uses offset so that factorIntensity=0.5 => tilt=0)
    private var overallTiltSection: some View {
        Section {
            HStack {
                GeometryReader { geo in
                    let tilt = displayedTilt // final S-curve tilt
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
    
    // This is the final displayed tilt: we do S-curve around an offset so that
    // at factorIntensity = 0.5, the bar is exactly zero.
    private var displayedTilt: Double {
        let alpha = 4.0
        let raw = computeNetTilt(for: factorIntensity)
        let offset = computeNetTilt(for: 0.5)  // tilt at 0.5
        let shifted = raw - offset            // shift so tilt=0 at 0.5
        return tanh(alpha * shifted)
    }
    
    // MARK: - Compute "Raw" Tilt from all toggles
    private func computeNetTilt(for intensity: Double) -> Double {
        // 1) Summation of toggled-on bullish (and negative for toggled-on bearish).
        //    We do the same linear interpolation as your updateAllFactors code,
        //    but purely in this function so we can see how big each factor is
        //    WITHOUT actually overwriting simSettings.* each time.
        
        // BULLISH FACTORS
        func bull(minVal: Double, maxVal: Double) -> Double {
            let val = minVal + intensity * (maxVal - minVal)
            return val
        }
        
        // Negative factors
        func bear(minVal: Double, maxVal: Double) -> Double {
            let val = minVal + intensity * (maxVal - minVal)
            return abs(val) // we'll sum up the magnitude for the negative side
        }
        
        // Decide minVal, maxVal depending on weeks or months, etc.
        // For brevity, I'll just do your "weeks" snippet.
        // If you need the "else" case for months/days, replicate that pattern.
        
        var bullVal = 0.0
        var bearVal = 0.0
        
        // BULLISH
        if simSettings.useHalvingUnified {
            // weeks (min=0.067..., max=0.5923...)
            bullVal += bull(minVal: 0.0673386887, maxVal: 0.5923386887)
        }
        if simSettings.useInstitutionalDemandUnified {
            bullVal += bull(minVal: 0.00030975, maxVal: 0.00216825)
        }
        if simSettings.useCountryAdoptionUnified {
            bullVal += bull(minVal: 0.0003910479977, maxVal: 0.0018841279977)
        }
        if simSettings.useRegulatoryClarityUnified {
            bullVal += bull(minVal: 0.0001216354861605167, maxVal: 0.0013124154861605167)
        }
        if simSettings.useEtfApprovalUnified {
            bullVal += bull(minVal: 0.0002880183160305023, maxVal: 0.0032880183160305023)
        }
        if simSettings.useTechBreakthroughUnified {
            bullVal += bull(minVal: 0.0000745993579173088, maxVal: 0.0011420393579173088)
        }
        if simSettings.useScarcityEventsUnified {
            bullVal += bull(minVal: 0.00010326753681182863, maxVal: 0.00072290753681182863)
        }
        if simSettings.useGlobalMacroHedgeUnified {
            bullVal += bull(minVal: 0.0000352709724932909, maxVal: 0.0006642909724932909)
        }
        if simSettings.useStablecoinShiftUnified {
            bullVal += bull(minVal: 0.0000275209116327763, maxVal: 0.0006349209116327763)
        }
        if simSettings.useDemographicAdoptionUnified {
            bullVal += bull(minVal: 0.0000827332036626339, maxVal: 0.0020412532036626339)
        }
        if simSettings.useAltcoinFlightUnified {
            bullVal += bull(minVal: 0.0000700544461803342, maxVal: 0.0004903844461803342)
        }
        if simSettings.useAdoptionFactorUnified {
            bullVal += bull(minVal: 0.0004011309088897705, maxVal: 0.0028078909088897705)
        }
        
        // BEARISH
        if simSettings.useRegClampdownUnified {
            bearVal += bear(minVal: -0.0025921152243542672, maxVal: 0.0003198247756457328)
        }
        if simSettings.useCompetitorCoinUnified {
            bearVal += bear(minVal: -0.0018617981746411323, maxVal: -0.0001678381746411323)
        }
        if simSettings.useSecurityBreachUnified {
            bearVal += bear(minVal: -0.0020439515168380737, maxVal: -0.0001389915168380737)
        }
        if simSettings.useBubblePopUnified {
            bearVal += bear(minVal: -0.004173393890762329, maxVal: 0.000648046109237671)
        }
        if simSettings.useStablecoinMeltdownUnified {
            bearVal += bear(minVal: -0.0019842626159477233, maxVal: 0.0005560573840522763)
        }
        if simSettings.useBlackSwanUnified {
            bearVal += bear(minVal: -0.79777, maxVal: 0.0)
        }
        if simSettings.useBearMarketUnified {
            bearVal += bear(minVal: -0.0016278802752494812, maxVal: -0.0001278802752494812)
        }
        if simSettings.useMaturingMarketUnified {
            bearVal += bear(minVal: -0.0039956381055486196, maxVal: 0.0009075918944513804)
        }
        if simSettings.useRecessionUnified {
            bearVal += bear(minVal: -0.0016560341467487811, maxVal: -0.0001450641467487811)
        }
        
        let total = bullVal + bearVal
        if total <= 0 { return 0 }
        
        // Tilt in [-1 ... +1]
        return (bullVal - bearVal) / total
    }
    
    // MARK: - Universal Factor Intensity
    private var factorIntensitySection: some View {
        Section {
            HStack {
                Button {
                    factorIntensity = 0.0
                } label: {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Slider(value: $factorIntensity, in: 0...1, step: 0.01)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))

                Button {
                    factorIntensity = 1.0
                } label: {
                    Image(systemName: "bolt.fill")
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
    
    // MARK: - Restore Defaults
    private var restoreDefaultsSection: some View {
        Section {
            Button("Restore Defaults") {
                simSettings.restoreDefaults()
                // You said all factors must be ON by default, including Black Swan,
                // so we do *not* turn anything off here.
            }
            .buttonStyle(PressableDestructiveButtonStyle())
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
                    // Again, everything on.
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
            // factorIntensity=0 => pick minVal (most negative).
            // factorIntensity=1 => pick maxVal (least negative).
            let newVal = minVal + factorIntensity * (maxVal - minVal)
            current = newVal
        }
        
        if simSettings.periodUnit == .weeks {
            // -------------------------
            // BULLISH FACTORS
            // -------------------------
            if simSettings.useHalvingUnified {
                setBullish(&simSettings.halvingBumpUnified,
                           minVal: 0.0673386887,
                           maxVal: 0.5923386887)
            }
            if simSettings.useInstitutionalDemandUnified {
                setBullish(&simSettings.maxDemandBoostUnified,
                           minVal: 0.00030975,
                           maxVal: 0.00216825)
            }
            if simSettings.useCountryAdoptionUnified {
                setBullish(&simSettings.maxCountryAdBoostUnified,
                           minVal: 0.0003910479977,
                           maxVal: 0.0018841279977)
            }
            if simSettings.useRegulatoryClarityUnified {
                setBullish(&simSettings.maxClarityBoostUnified,
                           minVal: 0.0001216354861605167,
                           maxVal: 0.0013124154861605167)
            }
            if simSettings.useEtfApprovalUnified {
                setBullish(&simSettings.maxEtfBoostUnified,
                           minVal: 0.0002880183160305023,
                           maxVal: 0.0032880183160305023)
            }
            if simSettings.useTechBreakthroughUnified {
                setBullish(&simSettings.maxTechBoostUnified,
                           minVal: 0.0000745993579173088,
                           maxVal: 0.0011420393579173088)
            }
            if simSettings.useScarcityEventsUnified {
                setBullish(&simSettings.maxScarcityBoostUnified,
                           minVal: 0.00010326753681182863,
                           maxVal: 0.00072290753681182863)
            }
            if simSettings.useGlobalMacroHedgeUnified {
                setBullish(&simSettings.maxMacroBoostUnified,
                           minVal: 0.0000352709724932909,
                           maxVal: 0.0006642909724932909)
            }
            if simSettings.useStablecoinShiftUnified {
                setBullish(&simSettings.maxStablecoinBoostUnified,
                           minVal: 0.0000275209116327763,
                           maxVal: 0.0006349209116327763)
            }
            if simSettings.useDemographicAdoptionUnified {
                setBullish(&simSettings.maxDemoBoostUnified,
                           minVal: 0.0000827332036626339,
                           maxVal: 0.0020412532036626339)
            }
            if simSettings.useAltcoinFlightUnified {
                setBullish(&simSettings.maxAltcoinBoostUnified,
                           minVal: 0.0000700544461803342,
                           maxVal: 0.0004903844461803342)
            }
            if simSettings.useAdoptionFactorUnified {
                setBullish(&simSettings.adoptionBaseFactorUnified,
                           minVal: 0.0004011309088897705,
                           maxVal: 0.0028078909088897705)
            }
            
            // -------------------------
            // BEARISH FACTORS
            // -------------------------
            if simSettings.useRegClampdownUnified {
                setBearish(&simSettings.maxClampDownUnified,
                           minVal: -0.0025921152243542672,
                           maxVal:  0.0003198247756457328)
            }
            if simSettings.useCompetitorCoinUnified {
                setBearish(&simSettings.maxCompetitorBoostUnified,
                           minVal: -0.0018617981746411323,
                           maxVal: -0.0001678381746411323)
            }
            if simSettings.useSecurityBreachUnified {
                setBearish(&simSettings.breachImpactUnified,
                           minVal: -0.0020439515168380737,
                           maxVal: -0.0001389915168380737)
            }
            if simSettings.useBubblePopUnified {
                setBearish(&simSettings.maxPopDropUnified,
                           minVal: -0.004173393890762329,
                           maxVal:  0.000648046109237671)
            }
            if simSettings.useStablecoinMeltdownUnified {
                setBearish(&simSettings.maxMeltdownDropUnified,
                           minVal: -0.0019842626159477233,
                           maxVal:  0.0005560573840522763)
            }
            if simSettings.useBlackSwanUnified {
                setBearish(&simSettings.blackSwanDropUnified,
                           minVal: -0.79777,
                           maxVal:  0.0)
            }
            if simSettings.useBearMarketUnified {
                setBearish(&simSettings.bearWeeklyDriftUnified,
                           minVal: -0.0016278802752494812,
                           maxVal: -0.0001278802752494812)
            }
            if simSettings.useMaturingMarketUnified {
                setBearish(&simSettings.maxMaturingDropUnified,
                           minVal: -0.0039956381055486196,
                           maxVal:  0.0009075918944513804)
            }
            if simSettings.useRecessionUnified {
                setBearish(&simSettings.maxRecessionDropUnified,
                           minVal: -0.0016560341467487811,
                           maxVal: -0.0001450641467487811)
            }
            
        } else {
            // ************************************************
            // Repeat all BULLISH & BEARISH for other periodUnit
            // ************************************************
            
            // -------------------------
            // BULLISH FACTORS
            // -------------------------
            if simSettings.useHalvingUnified {
                setBullish(&simSettings.halvingBumpUnified,
                           minVal: 0.0875,
                           maxVal: 0.6125)
            }
            if simSettings.useInstitutionalDemandUnified {
                setBullish(&simSettings.maxDemandBoostUnified,
                           minVal: 0.00141475,
                           maxVal: 0.00990322)
            }
            if simSettings.useCountryAdoptionUnified {
                setBullish(&simSettings.maxCountryAdBoostUnified,
                           minVal: 0.00137888,
                           maxVal: 0.00965215)
            }
            if simSettings.useRegulatoryClarityUnified {
                setBullish(&simSettings.maxClarityBoostUnified,
                           minVal: 0.00101843,
                           maxVal: 0.00712903)
            }
            if simSettings.useEtfApprovalUnified {
                setBullish(&simSettings.maxEtfBoostUnified,
                           minVal: 0.00142857,
                           maxVal: 0.01)
            }
            if simSettings.useTechBreakthroughUnified {
                setBullish(&simSettings.maxTechBoostUnified,
                           minVal: 0.00070968,
                           maxVal: 0.00496739)
            }
            if simSettings.useScarcityEventsUnified {
                setBullish(&simSettings.maxScarcityBoostUnified,
                           minVal: 0.00082322,
                           maxVal: 0.00576252)
            }
            if simSettings.useGlobalMacroHedgeUnified {
                setBullish(&simSettings.maxMacroBoostUnified,
                           minVal: 0.00081106,
                           maxVal: 0.00567742)
            }
            if simSettings.useStablecoinShiftUnified {
                setBullish(&simSettings.maxStablecoinBoostUnified,
                           minVal: 0.00057604,
                           maxVal: 0.00403226)
            }
            if simSettings.useDemographicAdoptionUnified {
                setBullish(&simSettings.maxDemoBoostUnified,
                           minVal: 0.00182278,
                           maxVal: 0.01275947)
            }
            if simSettings.useAltcoinFlightUnified {
                setBullish(&simSettings.maxAltcoinBoostUnified,
                           minVal: 0.00053917,
                           maxVal: 0.00377419)
            }
            if simSettings.useAdoptionFactorUnified {
                setBullish(&simSettings.adoptionBaseFactorUnified,
                           minVal: 0.00366524,
                           maxVal: 0.02565668)
            }
            
            // -------------------------
            // BEARISH FACTORS
            // -------------------------
            if simSettings.useRegClampdownUnified {
                setBearish(&simSettings.maxClampDownUnified,
                           minVal: -0.035,
                           maxVal: -0.005)
            }
            if simSettings.useCompetitorCoinUnified {
                setBearish(&simSettings.maxCompetitorBoostUnified,
                           minVal: -0.014,
                           maxVal: -0.002)
            }
            if simSettings.useSecurityBreachUnified {
                setBearish(&simSettings.breachImpactUnified,
                           minVal: -0.01225,
                           maxVal: -0.00175)
            }
            if simSettings.useBubblePopUnified {
                setBearish(&simSettings.maxPopDropUnified,
                           minVal: -0.0175,
                           maxVal: -0.0025)
            }
            if simSettings.useStablecoinMeltdownUnified {
                setBearish(&simSettings.maxMeltdownDropUnified,
                           minVal: -0.0175,
                           maxVal: -0.0025)
            }
            if simSettings.useBlackSwanUnified {
                setBearish(&simSettings.blackSwanDropUnified,
                           minVal: -0.8,
                           maxVal:  0.0)
            }
            if simSettings.useBearMarketUnified {
                setBearish(&simSettings.bearWeeklyDriftUnified,
                           minVal: -0.0175,
                           maxVal: -0.0025)
            }
            if simSettings.useMaturingMarketUnified {
                setBearish(&simSettings.maxMaturingDropUnified,
                           minVal: -0.0175,
                           maxVal: -0.0025)
            }
            if simSettings.useRecessionUnified {
                setBearish(&simSettings.maxRecessionDropUnified,
                           minVal: -0.00217621,
                           maxVal: -0.00072540)
            }
        }
    }
    
    // MARK: - Toggle Factor (tooltips)
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
