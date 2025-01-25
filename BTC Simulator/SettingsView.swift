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
    // 0 => fully bearish
    // 1 => fully bullish
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
        // Apply factor slider logic any time factorIntensity changes
        .onChange(of: factorIntensity) { _ in
            updateAllFactors()
        }
        .onAppear {
            // (Change A) Keep them synced on appear
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
    
    // MARK: - Universal Factor Intensity
    private var factorIntensitySection: some View {
        Section {
            HStack {
                // Left => Fully Bearish => factorIntensity = 0 => Red
                Button {
                    factorIntensity = 0.0
                } label: {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Slider(value: $factorIntensity, in: 0...1, step: 0.01)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))

                // Right => Fully Bullish => factorIntensity = 1 => Green
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
            Toggle(
                "Toggle All Factors",
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
    
    // MARK: - Tilt Bar
    private var overallTiltSection: some View {
        Section {
            HStack {
                GeometryReader { geo in
                    // Compute tilt in a local function or closure,
                    // so SwiftUI sees this entire block as returning a single View.
                    let tilt: Double = {
                        if factorIntensity <= 0.001 {
                            return -1
                        } else if factorIntensity >= 0.999 {
                            return 1
                        } else if abs(factorIntensity - 0.5) < 0.0001 {
                            return 0
                        } else {
                            return max(-1, min(netTilt, 1))
                        }
                    }()

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
    
    // We normalise net tilt so it can approach ±1
    private var netTilt: Double {
        // Sum all toggled-on bullish vs. bearish
        let bullVal: Double = {
            var sum = 0.0
            if simSettings.useHalvingUnified {
                sum += simSettings.halvingBumpUnified
            }
            if simSettings.useInstitutionalDemandUnified {
                sum += simSettings.maxDemandBoostUnified
            }
            if simSettings.useCountryAdoptionUnified {
                sum += simSettings.maxCountryAdBoostUnified
            }
            if simSettings.useRegulatoryClarityUnified {
                sum += simSettings.maxClarityBoostUnified
            }
            if simSettings.useEtfApprovalUnified {
                sum += simSettings.maxEtfBoostUnified
            }
            if simSettings.useTechBreakthroughUnified {
                sum += simSettings.maxTechBoostUnified
            }
            if simSettings.useScarcityEventsUnified {
                sum += simSettings.maxScarcityBoostUnified
            }
            if simSettings.useGlobalMacroHedgeUnified {
                sum += simSettings.maxMacroBoostUnified
            }
            if simSettings.useStablecoinShiftUnified {
                sum += simSettings.maxStablecoinBoostUnified
            }
            if simSettings.useDemographicAdoptionUnified {
                sum += simSettings.maxDemoBoostUnified
            }
            if simSettings.useAltcoinFlightUnified {
                sum += simSettings.maxAltcoinBoostUnified
            }
            if simSettings.useAdoptionFactorUnified {
                sum += simSettings.adoptionBaseFactorUnified
            }
            return sum
        }()
        
        let bearVal: Double = {
            var sum = 0.0
            if simSettings.useRegClampdownUnified {
                sum += abs(simSettings.maxClampDownUnified)
            }
            if simSettings.useCompetitorCoinUnified {
                sum += abs(simSettings.maxCompetitorBoostUnified)
            }
            if simSettings.useSecurityBreachUnified {
                sum += abs(simSettings.breachImpactUnified)
            }
            if simSettings.useBubblePopUnified {
                sum += abs(simSettings.maxPopDropUnified)
            }
            if simSettings.useStablecoinMeltdownUnified {
                sum += abs(simSettings.maxMeltdownDropUnified)
            }
            if simSettings.useBlackSwanUnified {
                sum += abs(simSettings.blackSwanDropUnified)
            }
            if simSettings.useBearMarketUnified {
                sum += abs(simSettings.bearWeeklyDriftUnified)
            }
            if simSettings.useMaturingMarketUnified {
                sum += abs(simSettings.maxMaturingDropUnified)
            }
            if simSettings.useRecessionUnified {
                sum += abs(simSettings.maxRecessionDropUnified)
            }
            return sum
        }()
        
        let total = bullVal + bearVal
        // If neither side has anything toggled on, or sum=0, no tilt
        guard total > 0 else { return 0 }
        
        // Normalise to [-1...+1]
        return (bullVal - bearVal) / total
    }
    
    // MARK: - Restore Defaults
    private var restoreDefaultsSection: some View {
        Section {
            Button("Restore Defaults") {
                simSettings.restoreDefaults()
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
            current = minVal + factorIntensity * (maxVal - minVal)
        }
        
        // BULLISH
        if simSettings.periodUnit == .weeks {
            setBullish(&simSettings.halvingBumpUnified, minVal: 0.0673386887, maxVal: 0.5923386887)
            setBullish(&simSettings.maxDemandBoostUnified, minVal: 0.00030975, maxVal: 0.00216825)
            setBullish(&simSettings.maxCountryAdBoostUnified, minVal: 0.0003910479977, maxVal: 0.0018841279977)
            setBullish(&simSettings.maxClarityBoostUnified, minVal: 0.0001216354861605167, maxVal: 0.0013124154861605167)
            setBullish(&simSettings.maxEtfBoostUnified, minVal: 0.0002880183160305023, maxVal: 0.0032880183160305023)
            setBullish(&simSettings.maxTechBoostUnified, minVal: 0.0000745993579173088, maxVal: 0.0011420393579173088)
            setBullish(&simSettings.maxScarcityBoostUnified, minVal: 0.00010326753681182863, maxVal: 0.00072290753681182863)
            setBullish(&simSettings.maxMacroBoostUnified, minVal: 0.0000352709724932909, maxVal: 0.0006642909724932909)
            setBullish(&simSettings.maxStablecoinBoostUnified, minVal: 0.0000275209116327763, maxVal: 0.0006349209116327763)
            setBullish(&simSettings.maxDemoBoostUnified, minVal: 0.0000827332036626339, maxVal: 0.0020412532036626339)
            setBullish(&simSettings.maxAltcoinBoostUnified, minVal: 0.0000700544461803342, maxVal: 0.0004903844461803342)
            setBullish(&simSettings.adoptionBaseFactorUnified, minVal: 0.0004011309088897705, maxVal: 0.0028078909088897705)
        } else {
            setBullish(&simSettings.halvingBumpUnified, minVal: 0.0875, maxVal: 0.6125)
            setBullish(&simSettings.maxDemandBoostUnified, minVal: 0.00141475, maxVal: 0.00990322)
            setBullish(&simSettings.maxCountryAdBoostUnified, minVal: 0.00137888, maxVal: 0.00965215)
            setBullish(&simSettings.maxClarityBoostUnified, minVal: 0.00101843, maxVal: 0.00712903)
            setBullish(&simSettings.maxEtfBoostUnified, minVal: 0.00142857, maxVal: 0.01)
            setBullish(&simSettings.maxTechBoostUnified, minVal: 0.00070968, maxVal: 0.00496739)
            setBullish(&simSettings.maxScarcityBoostUnified, minVal: 0.00082322, maxVal: 0.00576252)
            setBullish(&simSettings.maxMacroBoostUnified, minVal: 0.00081106, maxVal: 0.00567742)
            setBullish(&simSettings.maxStablecoinBoostUnified, minVal: 0.00057604, maxVal: 0.00403226)
            setBullish(&simSettings.maxDemoBoostUnified, minVal: 0.00182278, maxVal: 0.01275947)
            setBullish(&simSettings.maxAltcoinBoostUnified, minVal: 0.00053917, maxVal: 0.00377419)
            setBullish(&simSettings.adoptionBaseFactorUnified, minVal: 0.00366524, maxVal: 0.02565668)
        }
        
        // BEARISH
        if simSettings.periodUnit == .weeks {
            setBearish(&simSettings.maxClampDownUnified, minVal: -0.0025921152243542672, maxVal: 0.0003198247756457328)
            setBearish(&simSettings.maxCompetitorBoostUnified, minVal: -0.0018617981746411323, maxVal: -0.0001678381746411323)
            setBearish(&simSettings.breachImpactUnified, minVal: -0.0020439515168380737, maxVal: -0.0001389915168380737)
            setBearish(&simSettings.maxPopDropUnified, minVal: -0.004173393890762329, maxVal: 0.000648046109237671)
            setBearish(&simSettings.maxMeltdownDropUnified, minVal: -0.0019842626159477233, maxVal: 0.0005560573840522763)
            setBearish(&simSettings.blackSwanDropUnified, minVal: -0.79777, maxVal: 0.0)
            setBearish(&simSettings.bearWeeklyDriftUnified, minVal: -0.0016278802752494812, maxVal: -0.0001278802752494812)
            setBearish(&simSettings.maxMaturingDropUnified, minVal: -0.0039956381055486196, maxVal: 0.0009075918944513804)
            setBearish(&simSettings.maxRecessionDropUnified, minVal: -0.0016560341467487811, maxVal: -0.0001450641467487811)
        } else {
            setBearish(&simSettings.maxClampDownUnified, minVal: -0.035, maxVal: -0.005)
            setBearish(&simSettings.maxCompetitorBoostUnified, minVal: -0.014, maxVal: -0.002)
            setBearish(&simSettings.breachImpactUnified, minVal: -0.01225, maxVal: -0.00175)
            setBearish(&simSettings.maxPopDropUnified, minVal: -0.0175, maxVal: -0.0025)
            setBearish(&simSettings.maxMeltdownDropUnified, minVal: -0.0175, maxVal: -0.0025)
            setBearish(&simSettings.blackSwanDropUnified, minVal: -0.8, maxVal: 0.0)
            setBearish(&simSettings.bearWeeklyDriftUnified, minVal: -0.0175, maxVal: -0.0025)
            setBearish(&simSettings.maxMaturingDropUnified, minVal: -0.0175, maxVal: -0.0025)
            setBearish(&simSettings.maxRecessionDropUnified, minVal: -0.00217621, maxVal: -0.00072540)
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
