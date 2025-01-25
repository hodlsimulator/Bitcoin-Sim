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
    @AppStorage("factorIntensity") private var factorIntensity: Double = 0.5
    
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
            
            // 1) Universal Factor Intensity
            factorIntensitySection
            
            // 2) Toggle All Factors
            toggleAllSection
            
            // 3) Tilt Bar
            overallTiltSection
            
            // 4) Bullish + Bearish
            bullishFactorsSection
            bearishFactorsSection
            
            // 5) "Restore Defaults"
            restoreDefaultsSection
            
            // 6) Advanced Disclosure
            Section {
                DisclosureGroup("Advanced Settings", isExpanded: $showAdvancedSettings) {
                    // RANDOM SEED
                    Group {
                        Toggle("Lock Random Seed", isOn: $simSettings.lockedRandomSeed)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .onChange(of: simSettings.lockedRandomSeed) { locked in
                                if locked {
                                    let newSeed = UInt64.random(in: 0..<UInt64.max)
                                    simSettings.seedValue = newSeed
                                    simSettings.useRandomSeed = false
                                } else {
                                    simSettings.seedValue = 0
                                    simSettings.useRandomSeed = true
                                }
                            }
                        
                        if simSettings.lockedRandomSeed {
                            Text("Current Seed (Locked): \(simSettings.seedValue)")
                                .font(.footnote)
                                .foregroundColor(.white)
                        } else {
                            if simSettings.lastUsedSeed == 0 {
                                Text("Current Seed: (no run yet)")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            } else {
                                Text("Current Seed (Unlocked): \(simSettings.lastUsedSeed)")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            }
                        }
                        Text("""
                             Locking this seed ensures consistent simulation results every run. Unlock for new randomness.
                             """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Divider()
                    }
                    
                    // GROWTH MODEL
                    Group {
                        Toggle("Use Lognormal Growth", isOn: $simSettings.useLognormalGrowth)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .onChange(of: simSettings.useLognormalGrowth) { newVal in
                                // Flip useAnnualStep
                                simSettings.useAnnualStep = !newVal
                            }
                        
                        Text("""
                             Uses a lognormal model for Bitcoin’s price distribution. Uncheck to use an alternative approach (annual step).
                             """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Divider()
                    }
                    
                    // HISTORICAL SAMPLING
                    Group {
                        Toggle("Use Historical Sampling", isOn: $simSettings.useHistoricalSampling)
                            .tint(.orange)
                            .foregroundColor(.white)
                        Toggle("Use Extended Historical Sampling", isOn: $simSettings.useExtendedHistoricalSampling)
                            .tint(.orange)
                            .foregroundColor(.white)
                        Toggle("Lock Historical Sampling", isOn: $simSettings.lockHistoricalSampling)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("""
                             Pulls contiguous historical blocks from BTC + S&P data, preserving volatility clustering. Lock it to avoid random draws.
                             """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Divider()
                    }
                    
                    // AUTOCORRELATION
                    Group {
                        Toggle("Use Autocorrelation", isOn: $simSettings.useAutoCorrelation)
                            .tint(simSettings.useAutoCorrelation ? .orange : .gray)
                            .foregroundColor(.white)
                        
                        // Strength slider
                        HStack {
                            Button {
                                simSettings.autoCorrelationStrength = 0.05
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                            
                            Text("Autocorrelation Strength")
                                .foregroundColor(.white)
                            
                            Slider(value: $simSettings.autoCorrelationStrength,
                                   in: 0.01...0.09, step: 0.01)
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        }
                        .disabled(!simSettings.useAutoCorrelation)
                        .opacity(simSettings.useAutoCorrelation ? 1.0 : 0.4)
                        
                        // Mean reversion
                        HStack {
                            Button {
                                simSettings.meanReversionTarget = 0.03
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                            
                            Text("Mean Reversion Target")
                                .foregroundColor(.white)
                            
                            Slider(value: $simSettings.meanReversionTarget,
                                   in: 0.01...0.05, step: 0.001)
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        }
                        .disabled(!simSettings.useAutoCorrelation)
                        .opacity(simSettings.useAutoCorrelation ? 1.0 : 0.4)
                        
                        Text("""
                             Autocorrelation makes returns partially follow their previous trend, while mean reversion nudges them back toward a target.
                             """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Divider()
                    }
                    
                    // VOLATILITY
                    Group {
                        Toggle("Use Volatility Shocks", isOn: $simSettings.useVolShocks)
                            .tint(.orange)
                            .foregroundColor(.white)
                        Toggle("Use GARCH Volatility", isOn: $simSettings.useGarchVolatility)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("""
                             Volatility Shocks can randomly spike or dampen volatility. GARCH models let volatility evolve based on recent price moves.
                             """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        
                        Divider()
                    }
                    
                    // REGIME SWITCHING
                    Group {
                        Toggle("Use Regime Switching", isOn: $simSettings.useRegimeSwitching)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("""
                             Dynamically shifts between bull, bear, and hype states using a Markov chain to create more realistic cyclical patterns.
                             """)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .listRowBackground(Color(white: 0.15))
            
            // 7) About
            aboutSection
            
            // 8) Reset All
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
            // Keep them synced on appear
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
                // Left button => Tortoise => "Fully Bullish" => factorIntensity=1
                Button {
                    factorIntensity = 1.0
                } label: {
                    Image(systemName: "tortoise.fill")
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                
                Slider(value: $factorIntensity, in: 0...1, step: 0.01)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                
                // Right button => Lightning => "Fully Bearish" => factorIntensity=0
                Button {
                    factorIntensity = 0.0
                } label: {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        } footer: {
            Text("Scales all bullish and bearish factors. Left (green) = maximum bull, right (red) = maximum bear.")
                .foregroundColor(.red)
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
                .foregroundColor(.red)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - Tilt Bar
    private var overallTiltSection: some View {
        Section {
            HStack {
                GeometryReader { geo in
                    let tilt = max(-1, min(netTilt, 1))  // clamp to [-1, 1]
                    
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
                .foregroundColor(.red)
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
    
    // MARK: - Bullish Factors
    private var bullishFactorsSection: some View {
        Section("Bullish Factors") {
            // HALVING
            FactorToggleRow(
                iconName: "globe.europe.africa",
                title: "Halving",
                isOn: $simSettings.useHalvingUnified,
                sliderValue: $simSettings.halvingBumpUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0673386887 ... 0.5923386887
                    : 0.0875 ... 0.6125,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.3298386887
                    : 0.35,
                parameterDescription: """
                    Occurs roughly every four years, reducing the block reward in half.
                    Historically associated with strong BTC price increases.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // INSTITUTIONAL DEMAND
            FactorToggleRow(
                iconName: "building.columns.fill",
                title: "Institutional Demand",
                isOn: $simSettings.useInstitutionalDemandUnified,
                sliderValue: $simSettings.maxDemandBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00030975 ... 0.00216825
                    : 0.00141475 ... 0.00990322,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.001239
                    : 0.0056589855,
                parameterDescription: """
                    Entry by large financial institutions & treasuries can drive significant BTC price appreciation.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // COUNTRY ADOPTION
            FactorToggleRow(
                iconName: "flag.fill",
                title: "Country Adoption",
                isOn: $simSettings.useCountryAdoptionUnified,
                sliderValue: $simSettings.maxCountryAdBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0003910479977 ... 0.0018841279977
                    : 0.00137888 ... 0.00965215,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0011375879977
                    : 0.005515515952320099,
                parameterDescription: """
                    Nations adopting BTC as legal tender or in their reserves create surges in demand and legitimacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // REGULATORY CLARITY
            FactorToggleRow(
                iconName: "checkmark.shield",
                title: "Regulatory Clarity",
                isOn: $simSettings.useRegulatoryClarityUnified,
                sliderValue: $simSettings.maxClarityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0001216354861605167 ... 0.0013124154861605167
                    : 0.00101843 ... 0.00712903,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0007170254861605167
                    : 0.0040737327,
                parameterDescription: """
                    Clear, favourable regulations can reduce uncertainty and risk, drawing more capital into BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // ETF APPROVAL
            FactorToggleRow(
                iconName: "building.2.crop.circle",
                title: "ETF Approval",
                isOn: $simSettings.useEtfApprovalUnified,
                sliderValue: $simSettings.maxEtfBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0002880183160305023 ... 0.0032880183160305023
                    : 0.00142857 ... 0.01,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0017880183160305023
                    : 0.0057142851,
                parameterDescription: """
                    Spot BTC ETFs allow traditional investors to gain exposure without custody, broadening the market.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // TECH BREAKTHROUGH
            FactorToggleRow(
                iconName: "sparkles",
                title: "Tech Breakthrough",
                isOn: $simSettings.useTechBreakthroughUnified,
                sliderValue: $simSettings.maxTechBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000745993579173088 ... 0.0011420393579173088
                    : 0.00070968 ... 0.00496739,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0006083193579173088
                    : 0.0028387091,
                parameterDescription: """
                    Major protocol/L2 improvements can generate optimism, e.g. better scalability or privacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // SCARCITY EVENTS
            FactorToggleRow(
                iconName: "scalemass",
                title: "Scarcity Events",
                isOn: $simSettings.useScarcityEventsUnified,
                sliderValue: $simSettings.maxScarcityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00010326753681182863 ... 0.00072290753681182863
                    : 0.00082322 ... 0.00576252,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.00041308753681182863
                    : 0.0032928705475521085,
                parameterDescription: """
                    Unusual supply reductions (e.g. large holders removing coins from exchanges) can elevate price.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // GLOBAL MACRO HEDGE
            FactorToggleRow(
                iconName: "globe.americas.fill",
                title: "Global Macro Hedge",
                isOn: $simSettings.useGlobalMacroHedgeUnified,
                sliderValue: $simSettings.maxMacroBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000352709724932909 ... 0.0006642909724932909
                    : 0.00081106 ... 0.00567742,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0003497809724932909
                    : 0.0032442397,
                parameterDescription: """
                    During macro uncertainty, BTC’s “digital gold” narrative can attract investors seeking a hedge.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // STABLECOIN SHIFT
            FactorToggleRow(
                iconName: "dollarsign.arrow.circlepath",
                title: "Stablecoin Shift",
                isOn: $simSettings.useStablecoinShiftUnified,
                sliderValue: $simSettings.maxStablecoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000275209116327763 ... 0.0006349209116327763
                    : 0.00057604 ... 0.00403226,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0003312209116327763
                    : 0.0023041475,
                parameterDescription: """
                    Sudden inflows from stablecoins into BTC can push prices up quickly.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // DEMOGRAPHIC ADOPTION
            FactorToggleRow(
                iconName: "person.3.fill",
                title: "Demographic Adoption",
                isOn: $simSettings.useDemographicAdoptionUnified,
                sliderValue: $simSettings.maxDemoBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000827332036626339 ... 0.0020412532036626339
                    : 0.00182278 ... 0.01275947,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0010619932036626339
                    : 0.007291124714649915,
                parameterDescription: """
                    Younger, tech-savvy generations often drive steady BTC adoption over time.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // ALTCOIN FLIGHT
            FactorToggleRow(
                iconName: "bitcoinsign.circle.fill",
                title: "Altcoin Flight",
                isOn: $simSettings.useAltcoinFlightUnified,
                sliderValue: $simSettings.maxAltcoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0000700544461803342 ... 0.0004903844461803342
                    : 0.00053917 ... 0.00377419,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0002802194461803342
                    : 0.0021566817,
                parameterDescription: """
                    During altcoin uncertainty, capital may rotate into BTC as the ‘blue-chip’ crypto.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            // ADOPTION FACTOR
            FactorToggleRow(
                iconName: "arrow.up.right.circle.fill",
                title: "Adoption Factor (Incremental Drift)",
                isOn: $simSettings.useAdoptionFactorUnified,
                sliderValue: $simSettings.adoptionBaseFactorUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0004011309088897705 ... 0.0028078909088897705
                    : 0.00366524 ... 0.02565668,
                defaultValue: simSettings.periodUnit == .weeks
                    ? 0.0016045109088897705
                    : 0.014660959934071304,
                parameterDescription: """
                    A slow, steady upward drift in BTC price from ongoing adoption growth.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - Bearish Factors
    private var bearishFactorsSection: some View {
        Section("Bearish Factors") {
            FactorToggleRow(
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                isOn: $simSettings.useRegClampdownUnified,
                sliderValue: $simSettings.maxClampDownUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0025921152243542672 ... 0.0003198247756457328
                    : -0.035 ... -0.005,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0011361452243542672
                    : -0.02,
                parameterDescription: """
                    Strict government bans/regulations can curb adoption and reduce demand.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "bitcoinsign.circle",
                title: "Competitor Coin",
                isOn: $simSettings.useCompetitorCoinUnified,
                sliderValue: $simSettings.maxCompetitorBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0018617981746411323 ... -0.0001678381746411323
                    : -0.014 ... -0.002,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010148181746411323
                    : -0.008,
                parameterDescription: """
                    A rival crypto with better tech or speed may siphon market share from BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "lock.shield",
                title: "Security Breach",
                isOn: $simSettings.useSecurityBreachUnified,
                sliderValue: $simSettings.breachImpactUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0020439515168380737 ... -0.0001389915168380737
                    : -0.01225 ... -0.00175,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0010914715168380737
                    : -0.007,
                parameterDescription: """
                    Major hacks or protocol exploits can damage confidence and spark selloffs.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "bubble.left.and.bubble.right.fill",
                title: "Bubble Pop",
                isOn: $simSettings.useBubblePopUnified,
                sliderValue: $simSettings.maxPopDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.004173393890762329 ... 0.000648046109237671
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.001762673890762329
                    : -0.01,
                parameterDescription: """
                    Speculative manias can end abruptly, causing prices to crash.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "exclamationmark.triangle.fill",
                title: "Stablecoin Meltdown",
                isOn: $simSettings.useStablecoinMeltdownUnified,
                sliderValue: $simSettings.maxMeltdownDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0019842626159477233 ... 0.0005560573840522763
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0007141026159477233
                    : -0.01,
                parameterDescription: """
                    If major stablecoins collapse or de-peg, confidence can erode across all crypto, including BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "tornado",
                title: "Black Swan Events",
                isOn: $simSettings.useBlackSwanUnified,
                sliderValue: $simSettings.blackSwanDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.79777 ... 0.0
                    : -0.8 ... 0.0,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.398885
                    : -0.4,
                parameterDescription: """
                    Extreme, unforeseen disasters or wars can slam all markets, including BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "chart.bar.xaxis",
                title: "Bear Market Conditions",
                isOn: $simSettings.useBearMarketUnified,
                sliderValue: $simSettings.bearWeeklyDriftUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0016278802752494812 ... -0.0001278802752494812
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0008778802752494812
                    : -0.01,
                parameterDescription: """
                    Prolonged negativity leads to gradual price declines and capitulation.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis",
                title: "Declining ARR / Maturing Market",
                isOn: $simSettings.useMaturingMarketUnified,
                sliderValue: $simSettings.maxMaturingDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0039956381055486196 ... 0.0009075918944513804
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0015440231055486196
                    : -0.01,
                parameterDescription: """
                    As BTC matures, growth slows, diminishing speculative returns over time.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis.circle.fill",
                title: "Recession / Macro Crash",
                isOn: $simSettings.useRecessionUnified,
                sliderValue: $simSettings.maxRecessionDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.0016560341467487811 ... -0.0001450641467487811
                    : -0.00217621 ... -0.00072540,
                defaultValue: simSettings.periodUnit == .weeks
                    ? -0.0009005491467487811
                    : -0.0014508080482482913,
                parameterDescription: """
                    A broader economic downturn reduces risk appetite, pulling capital from BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
        }
        .listRowBackground(Color(white: 0.15))
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
    // If factorIntensity=0 => fully bearish => bullish factors=their min, bearish factors=their max
    // If factorIntensity=1 => fully bullish => bullish factors=their max, bearish factors=their min
    private func updateAllFactors() {
        func setBullish(_ current: inout Double, minVal: Double, maxVal: Double) {
            let newVal = minVal + factorIntensity * (maxVal - minVal)
            current = newVal
        }
        func setBearish(_ current: inout Double, minVal: Double, maxVal: Double) {
            let newVal = maxVal - factorIntensity * (maxVal - minVal)
            current = newVal
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
