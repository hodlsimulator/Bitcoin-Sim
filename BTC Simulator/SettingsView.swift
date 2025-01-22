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
            bullishFactorsSection
            bearishFactorsSection
            toggleAllSection
            randomSeedSection
            growthModelSection
            historicalSamplingSection
            autocorrelationSection
            volatilitySection
            restoreDefaultsSection
            aboutSection
            resetCriteriaSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.12))
        .environment(\.colorScheme, .dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
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
    
    // MARK: - BULLISH FACTORS
    private var bullishFactorsSection: some View {
        Section("Bullish Factors") {
            // HALVING
            FactorToggleRow(
                iconName: "globe.europe.africa",
                title: "Halving",
                isOn: $simSettings.useHalvingUnified,
                sliderValue: $simSettings.halvingBumpUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0875...0.6125
                    : 0.0875...0.6125,
                defaultValue: simSettings.periodUnit == .weeks ? 0.35 : 0.35,
                parameterDescription: """
                    Occurs roughly every four years, reducing the block reward in half.
                    Historically, halving events have coincided with substantial BTC price increases.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useHalvingUnified) { newValue in
                print("DEBUG: UI sees useHalvingUnified changed to \(newValue)")
            }
            
            // INSTITUTIONAL DEMAND
            FactorToggleRow(
                iconName: "building.columns.fill",
                title: "Institutional Demand",
                isOn: $simSettings.useInstitutionalDemandUnified,
                sliderValue: $simSettings.maxDemandBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00030975...0.00216825
                    : 0.00141475...0.00990322,
                defaultValue: simSettings.periodUnit == .weeks ? 0.001239 : 0.0056589855,
                parameterDescription: """
                    Large financial institutions and corporate treasuries entering the BTC market can drive prices up.
                    Increased legitimacy and adoption by well-known firms can attract more mainstream interest.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useInstitutionalDemandUnified) { newValue in
                print("DEBUG: UI sees useInstitutionalDemandUnified changed to \(newValue)")
            }
            
            // COUNTRY ADOPTION
            FactorToggleRow(
                iconName: "flag.fill",
                title: "Country Adoption",
                isOn: $simSettings.useCountryAdoptionUnified,
                sliderValue: $simSettings.maxCountryAdBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00024885...0.00174193
                    : 0.00137888...0.00965215,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00099539 : 0.005515515952320099,
                parameterDescription: """
                    Nations adopting BTC as legal tender or as part of their reserves can lead to massive demand.
                    Wider government acceptance signals mainstream credibility and new use cases.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useCountryAdoptionUnified) { newValue in
                print("DEBUG: UI sees useCountryAdoptionUnified changed to \(newValue)")
            }
            
            // REGULATORY CLARITY
            FactorToggleRow(
                iconName: "checkmark.shield",
                title: "Regulatory Clarity",
                isOn: $simSettings.useRegulatoryClarityUnified,
                sliderValue: $simSettings.maxClarityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00019846...0.00138924
                    : 0.00101843...0.00712903,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00079385 : 0.0040737327,
                parameterDescription: """
                    Clear, favourable regulations can reduce uncertainty and risk for investors.
                    When watchdogs provide guidelines, more capital may flow into BTC, boosting price.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useRegulatoryClarityUnified) { newValue in
                print("DEBUG: UI sees useRegulatoryClarityUnified changed to \(newValue)")
            }
            
            // ETF APPROVAL
            FactorToggleRow(
                iconName: "building.2.crop.circle",
                title: "ETF Approval",
                isOn: $simSettings.useEtfApprovalUnified,
                sliderValue: $simSettings.maxEtfBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0005...0.0035
                    : 0.00142857...0.01,
                defaultValue: simSettings.periodUnit == .weeks ? 0.002 : 0.0057142851,
                parameterDescription: """
                    Spot BTC ETFs allow traditional investors to gain exposure without holding actual BTC.
                    The ease of acquisition via brokers can significantly expand demand.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useEtfApprovalUnified) { newValue in
                print("DEBUG: UI sees useEtfApprovalUnified changed to \(newValue)")
            }
            
            // TECH BREAKTHROUGH
            FactorToggleRow(
                iconName: "sparkles",
                title: "Tech Breakthrough",
                isOn: $simSettings.useTechBreakthroughUnified,
                sliderValue: $simSettings.maxTechBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.0001779...0.00124534
                    : 0.00070968...0.00496739,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00071162 : 0.0028387091,
                parameterDescription: """
                    Major improvements in Bitcoin’s protocol or L2 networks (Lightning, etc.)
                    can spur optimism and adoption, enhancing scalability or privacy.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useTechBreakthroughUnified) { newValue in
                print("DEBUG: UI sees useTechBreakthroughUnified changed to \(newValue)")
            }
            
            // SCARCITY EVENTS
            FactorToggleRow(
                iconName: "scalemass",
                title: "Scarcity Events",
                isOn: $simSettings.useScarcityEventsUnified,
                sliderValue: $simSettings.maxScarcityBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00010327...0.00072291
                    : 0.00082322...0.00576252,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00041309 : 0.0032928705475521085,
                parameterDescription: """
                    Unusual events that reduce BTC supply—like large holders removing coins from exchanges—
                    can push prices up by limiting sell pressure.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useScarcityEventsUnified) { newValue in
                print("DEBUG: UI sees useScarcityEventsUnified changed to \(newValue)")
            }
            
            // GLOBAL MACRO HEDGE
            FactorToggleRow(
                iconName: "globe.americas.fill",
                title: "Global Macro Hedge",
                isOn: $simSettings.useGlobalMacroHedgeUnified,
                sliderValue: $simSettings.maxMacroBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00010484...0.00073386
                    : 0.00081106...0.00567742,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00041935 : 0.0032442397,
                parameterDescription: """
                    BTC’s “digital gold” narrative can be strong during macro uncertainty.
                    Investors may seek refuge in BTC if they lose faith in fiat or broader markets.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useGlobalMacroHedgeUnified) { newValue in
                print("DEBUG: UI sees useGlobalMacroHedgeUnified changed to \(newValue)")
            }
            
            // STABLECOIN SHIFT
            FactorToggleRow(
                iconName: "dollarsign.arrow.circlepath",
                title: "Stablecoin Shift",
                isOn: $simSettings.useStablecoinShiftUnified,
                sliderValue: $simSettings.maxStablecoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00010123...0.00070863
                    : 0.00057604...0.00403226,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00040493 : 0.0023041475,
                parameterDescription: """
                    Large sums sometimes move from stablecoins into BTC.
                    This demand spike can push prices up quickly.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useStablecoinShiftUnified) { newValue in
                print("DEBUG: UI sees useStablecoinShiftUnified changed to \(newValue)")
            }
            
            // DEMOGRAPHIC ADOPTION
            FactorToggleRow(
                iconName: "person.3.fill",
                title: "Demographic Adoption",
                isOn: $simSettings.useDemographicAdoptionUnified,
                sliderValue: $simSettings.maxDemoBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00032642...0.00228494
                    : 0.00182278...0.01275947,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00130568 : 0.007291124714649915,
                parameterDescription: """
                    Younger, tech-savvy generations often invest in BTC,
                    accelerating mainstream adoption over time.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useDemographicAdoptionUnified) { newValue in
                print("DEBUG: UI sees useDemographicAdoptionUnified changed to \(newValue)")
            }
            
            // ALTCOIN FLIGHT
            FactorToggleRow(
                iconName: "bitcoinsign.circle.fill",
                title: "Altcoin Flight",
                isOn: $simSettings.useAltcoinFlightUnified,
                sliderValue: $simSettings.maxAltcoinBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00007005...0.00049038
                    : 0.00053917...0.00377419,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00028022 : 0.0021566817,
                parameterDescription: """
                    During altcoin uncertainty, capital can rotate into BTC,
                    the ‘blue-chip’ crypto with the strongest fundamentals.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useAltcoinFlightUnified) { newValue in
                print("DEBUG: UI sees useAltcoinFlightUnified changed to \(newValue)")
            }
            
            // ADOPTION FACTOR
            FactorToggleRow(
                iconName: "arrow.up.right.circle.fill",
                title: "Adoption Factor (Incremental Drift)",
                isOn: $simSettings.useAdoptionFactorUnified,
                sliderValue: $simSettings.adoptionBaseFactorUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? 0.00040113...0.00280789
                    : 0.00366524...0.02565668,
                defaultValue: simSettings.periodUnit == .weeks ? 0.00160451 : 0.014660959934071304,
                parameterDescription: """
                    A slow, steady upward drift in BTC price from ongoing adoption growth.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useAdoptionFactorUnified) { newValue in
                print("DEBUG: UI sees useAdoptionFactorUnified changed to \(newValue)")
            }
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - BEARISH FACTORS
    private var bearishFactorsSection: some View {
        Section("Bearish Factors") {
            FactorToggleRow(
                iconName: "hand.raised.slash",
                title: "Regulatory Clampdown",
                isOn: $simSettings.useRegClampdownUnified,
                sliderValue: $simSettings.maxClampDownUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00339726 ... -0.00048532
                    : -0.035 ... -0.005,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00194129 : -0.02,
                parameterDescription: """
                    Strict government regulations or bans can curb adoption,
                    leading to lower demand and negative price impacts.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useRegClampdownUnified) { newValue in
                print("DEBUG: UI sees useRegClampdownUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "bitcoinsign.circle",
                title: "Competitor Coin",
                isOn: $simSettings.useCompetitorCoinUnified,
                sliderValue: $simSettings.maxCompetitorBoostUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00197629 ... -0.00028233
                    : -0.014 ... -0.002,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00112931 : -0.008,
                parameterDescription: """
                    A rival cryptocurrency with superior tech or speed may siphon capital away from BTC,
                    reducing its dominance.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useCompetitorCoinUnified) { newValue in
                print("DEBUG: UI sees useCompetitorCoinUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "lock.shield",
                title: "Security Breach",
                isOn: $simSettings.useSecurityBreachUnified,
                sliderValue: $simSettings.breachImpactUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00222245 ... -0.00031749
                    : -0.01225 ... -0.00175,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00126997 : -0.007,
                parameterDescription: """
                    A major hack or exploit can severely damage confidence and cause panic selling.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useSecurityBreachUnified) { newValue in
                print("DEBUG: UI sees useSecurityBreachUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "bubble.left.and.bubble.right.fill",
                title: "Bubble Pop",
                isOn: $simSettings.useBubblePopUnified,
                sliderValue: $simSettings.maxPopDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00562501 ... -0.00080357
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00321429 : -0.01,
                parameterDescription: """
                    Speculative bubbles can burst, causing a rapid and sharp crash
                    once fear and profit-taking set in.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useBubblePopUnified) { newValue in
                print("DEBUG: UI sees useBubblePopUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "exclamationmark.triangle.fill",
                title: "Stablecoin Meltdown",
                isOn: $simSettings.useStablecoinMeltdownUnified,
                sliderValue: $simSettings.maxMeltdownDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00296371 ... -0.00042339
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00169355 : -0.01,
                parameterDescription: """
                    Major stablecoins de-pegging or collapsing can spark a crisis of confidence
                    that spills over into BTC.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useStablecoinMeltdownUnified) { newValue in
                print("DEBUG: UI sees useStablecoinMeltdownUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "tornado",
                title: "Black Swan Events",
                isOn: $simSettings.useBlackSwanUnified,
                sliderValue: $simSettings.blackSwanDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -1.196655 ... -0.398885
                    : -0.8 ... 0.0,
                defaultValue: simSettings.periodUnit == .weeks ? -0.79777 : -0.4,
                parameterDescription: """
                    Highly unpredictable disasters or wars can undermine all markets,
                    including BTC, causing extreme selloffs.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useBlackSwanUnified) { newValue in
                print("DEBUG: UI sees useBlackSwanUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "chart.bar.xaxis",
                title: "Bear Market Conditions",
                isOn: $simSettings.useBearMarketUnified,
                sliderValue: $simSettings.bearWeeklyDriftUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00175 ... -0.00025
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks ? -0.001 : -0.01,
                parameterDescription: """
                    Prolonged negativity in crypto can produce a steady downward trend,
                    with capitulations and lower trading volumes.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useBearMarketUnified) { newValue in
                print("DEBUG: UI sees useBearMarketUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis",
                title: "Declining ARR / Maturing Market",
                isOn: $simSettings.useMaturingMarketUnified,
                sliderValue: $simSettings.maxMaturingDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00572043 ... -0.00081720
                    : -0.0175 ... -0.0025,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00326882 : -0.01,
                parameterDescription: """
                    As BTC matures, growth rates slow, reducing speculative enthusiasm
                    and leading to smaller returns.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useMaturingMarketUnified) { newValue in
                print("DEBUG: UI sees useMaturingMarketUnified changed to \(newValue)")
            }
            
            FactorToggleRow(
                iconName: "chart.line.downtrend.xyaxis.circle.fill",
                title: "Recession / Macro Crash",
                isOn: $simSettings.useRecessionUnified,
                sliderValue: $simSettings.maxRecessionDropUnified,
                sliderRange: simSettings.periodUnit == .weeks
                    ? -0.00176280 ... -0.00025183
                    : -0.00217621 ... -0.00072540,
                defaultValue: simSettings.periodUnit == .weeks ? -0.00100732 : -0.00145081,
                parameterDescription: """
                    Global economic downturns reduce risk appetite,
                    prompting investors to exit BTC to shore up liquidity.
                    """,
                activeFactor: activeFactor,
                onTitleTap: toggleFactor
            )
            .onChange(of: simSettings.useRecessionUnified) { newValue in
                print("DEBUG: UI sees useRecessionUnified changed to \(newValue)")
            }
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - TOGGLE ALL FACTORS
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
            .onChange(of: simSettings.toggleAll) { newVal in
                print("DEBUG: UI sees toggleAll changed to \(newVal)")
            }
        } header: {
            Text("Toggle All Factors")
        } footer: {
            Text("Switch all bullish and bearish factors on or off at once.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - RANDOM SEED
    private var randomSeedSection: some View {
        Section {
            Toggle("Lock Random Seed", isOn: $simSettings.lockedRandomSeed)
                .tint(.orange)
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
                .foregroundColor(.white)
            
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
        } header: {
            Text("Random Seed")
        } footer: {
            Text("Locking this seed gives consistent simulation results. Unlock for new randomness each run.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - GROWTH MODEL
    private var growthModelSection: some View {
        Section {
            Toggle("Use Lognormal Growth", isOn: $simSettings.useLognormalGrowth)
                .tint(.orange)
                .foregroundColor(.white)
        } header: {
            Text("Growth Model")
        } footer: {
            Text("Uses a lognormal model for Bitcoin’s price growth distribution.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - HISTORICAL SAMPLING
    private var historicalSamplingSection: some View {
        Section {
            Toggle("Use Historical Sampling", isOn: $simSettings.useHistoricalSampling)
                .tint(.orange)
                .foregroundColor(.white)
            Toggle("Lock Historical Sampling", isOn: $simSettings.lockHistoricalSampling)
                .tint(.orange)
                .foregroundColor(.white)
        } header: {
            Text("Historical Sampling")
        } footer: {
            Text("Samples real-world BTC returns. Locking ensures the same historical data window each run.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - AUTOCORRELATION
    private var autocorrelationSection: some View {
        Section {
            Toggle("Use Autocorrelation", isOn: $simSettings.useAutoCorrelation)
                // Toggle is orange when on, grey otherwise
                .tint(simSettings.useAutoCorrelation ? .orange : .gray)
                .foregroundColor(.white)
            
            // Sliders in a group so they're both disabled/dimmed together
            Group {
                // Strength slider
                HStack {
                    Button {
                        simSettings.autoCorrelationStrength = 0.3
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                    
                    Text("Autocorrelation Strength")
                        .foregroundColor(.white)
                    
                    Slider(value: $simSettings.autoCorrelationStrength, in: 0...1, step: 0.05)
                        .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                }
                
                // Mean reversion slider
                HStack {
                    Button {
                        simSettings.meanReversionTarget = 0.0
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                    
                    Text("Mean Reversion Target")
                        .foregroundColor(.white)
                    
                    Slider(value: $simSettings.meanReversionTarget, in: -0.02...0.02, step: 0.001)
                        .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                }
            }
            .disabled(!simSettings.useAutoCorrelation)
            .opacity(simSettings.useAutoCorrelation ? 1.0 : 0.4)
        } header: {
            Text("Autocorrelation & Mean Reversion")
        } footer: {
            Text("Allows returns to partially follow or revert from the previous step. Higher strength means a bigger influence on the next period’s return.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - VOLATILITY
    private var volatilitySection: some View {
        Section {
            Toggle("Use Volatility Shocks", isOn: $simSettings.useVolShocks)
                .tint(.orange)
                .foregroundColor(.white)
            Toggle("Use GARCH Volatility", isOn: $simSettings.useGarchVolatility)
                .tint(.orange)
                .foregroundColor(.white)
        } header: {
            Text("Volatility")
        } footer: {
            Text("Use GARCH to make volatility evolve based on recent returns (more realistic swings).")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - RESTORE DEFAULTS
    private var restoreDefaultsSection: some View {
        Section {
            Button("Restore Defaults") {
                simSettings.restoreDefaults()
            }
            .buttonStyle(PressableDestructiveButtonStyle())
        } footer: {
            Text("Sets all simulation parameters back to their original defaults.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - ABOUT
    private var aboutSection: some View {
        Section {
            NavigationLink("About") {
                AboutView()
            }
        } header: {
            Text("About")
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - RESET CRITERIA
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
        } header: {
            Text("Reset Criteria")
        } footer: {
            Text("Completely clears custom settings and restarts the onboarding flow.")
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color(white: 0.15))
    }
    
    // MARK: - Toggle Factor
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
