//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

/// A simple style that makes a destructive button scale & fade slightly when pressed.
struct PressableDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.red)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.none, value: configuration.isPressed)
    }
}

/// A small struct storing which factor’s tooltip is tapped, plus the anchor.
struct TooltipItem {
    let title: String
    let description: String
    let anchor: Anchor<CGPoint>
}

/// Collects all anchors in a preference key. If multiple are tapped, we only use the last.
struct TooltipAnchorKey: PreferenceKey {
    static var defaultValue: [TooltipItem] = []
    static func reduce(value: inout [TooltipItem], nextValue: () -> [TooltipItem]) {
        value.append(contentsOf: nextValue())
    }
}

/// The main Settings view that shows bullish & bearish factors, toggles, seeds, etc.
struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    /// Ties directly to the "hasOnboarded" key for re-triggering onboarding.
    @AppStorage("hasOnboarded") private var didFinishOnboarding = false
    
    /// Whether to show a confirmation alert before resetting criteria.
    @State private var showResetCriteriaConfirmation = false
    
    /// Name of the factor currently showing a tooltip (or nil if none).
    @State private var activeFactor: String? = nil

    init() {
        // Setup custom nav bar appearances
        let opaqueAppearance = UINavigationBarAppearance()
        opaqueAppearance.configureWithOpaqueBackground()
        opaqueAppearance.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // Large title style
        opaqueAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        // Standard title style
        opaqueAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]

        // Collapsed (scrolled) nav appearance
        let blurredAppearance = UINavigationBarAppearance()
        blurredAppearance.configureWithTransparentBackground()
        blurredAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        blurredAppearance.backgroundColor = UIColor(white: 0.12, alpha: 0.2)
        blurredAppearance.largeTitleTextAttributes = opaqueAppearance.largeTitleTextAttributes
        blurredAppearance.titleTextAttributes = opaqueAppearance.titleTextAttributes

        // Hide "Back" text, show only a white chevron
        let chevronImage = UIImage(systemName: "chevron.left")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let backItem = UIBarButtonItemAppearance(style: .plain)
        backItem.normal.titlePositionAdjustment = UIOffset(horizontal: -3000, vertical: 0)
        
        opaqueAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        blurredAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        opaqueAppearance.backButtonAppearance = backItem
        blurredAppearance.backButtonAppearance = backItem

        // Apply it
        UINavigationBar.appearance().scrollEdgeAppearance = opaqueAppearance
        UINavigationBar.appearance().standardAppearance   = blurredAppearance
        UINavigationBar.appearance().compactAppearance    = blurredAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some View {
        Form {
            //====================================
            // BULLISH FACTORS
            //====================================
            Section("Bullish Factors") {
                FactorToggleRow(
                    iconName: "globe.europe.africa",
                    title: "Halving",
                    isOn: $simSettings.useHalvingUnified,
                    sliderValue: $simSettings.halvingBumpUnified,
                    
                    // New weekly default = 0.024 => ±75% => 0.024 * 0.75 = 0.018
                    // Range: 0.024 - 0.018 ... 0.024 + 0.018 => 0.006 ... 0.042
                    // Monthly unchanged => 0.58 => range 0.29 ... 0.87
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.006...0.042
                        : 0.29...0.87,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.024
                        : 0.58,
                    
                    parameterDescription: """
                        Occurs roughly every four years, reducing the block reward in half.
                        Historically, halving events have coincided with substantial BTC price increases.
                        """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                .anchorPreference(key: TooltipAnchorKey.self, value: .center) { pt in
                    if activeFactor == "Halving" {
                        let desc = """
                            Occurs roughly every four years, reducing the block reward in half.
                            Historically, halving events have coincided with big BTC price increases.
                            """
                        return [ TooltipItem(title: "Halving", description: desc, anchor: pt) ]
                    } else {
                        return []
                    }
                }

                FactorToggleRow(
                    iconName: "building.columns.fill",
                    title: "Institutional Demand",
                    isOn: $simSettings.useInstitutionalDemandUnified,
                    sliderValue: $simSettings.maxDemandBoostUnified,

                    // New weekly default = 0.001239 => ±75% => ~0.00092925
                    // Range: 0.001239 - 0.00092925 ... 0.001239 + 0.00092925
                    //        => 0.00030975 ... 0.00216825
                    // Monthly unchanged => 0.001239 => range 0.00062...0.00186
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00030975...0.00216825
                        : 0.00062...0.00186,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.001239
                        : 0.001239,

                    parameterDescription: """
                    Large financial institutions and corporate treasuries entering the BTC market can drive prices up.
                    Increased legitimacy and adoption by well-known firms can attract more mainstream interest.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "flag.fill",
                    title: "Country Adoption",
                    isOn: $simSettings.useCountryAdoptionUnified,
                    sliderValue: $simSettings.maxCountryAdBoostUnified,

                    // New weekly default = 0.003 => ±75% => 0.00225
                    // Range: 0.003 - 0.00225 ... 0.003 + 0.00225
                    //        => 0.00075 ... 0.00525
                    // Monthly unchanged => 0.00047096 => range 0.00023548...0.00070644
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00075...0.00525
                        : 0.00023548...0.00070644,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.003
                        : 0.00047096,

                    parameterDescription: """
                    Nations adopting BTC as legal tender or as part of their reserves can lead to massive demand.
                    Wider government acceptance signals mainstream credibility and potential new use cases.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "checkmark.shield",
                    title: "Regulatory Clarity",
                    isOn: $simSettings.useRegulatoryClarityUnified,
                    sliderValue: $simSettings.maxClarityBoostUnified,

                    // New weekly default = 0.0016644 => ±75% => ~0.0012483
                    // Range: 0.0016644 - 0.0012483 ... 0.0016644 + 0.0012483
                    //        => 0.0004161 ... 0.0029127
                    // Monthly unchanged => 0.0016644 => range 0.0008322...0.0024966
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.0004161...0.0029127
                        : 0.0008322...0.0024966,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.0016644
                        : 0.0016644,

                    parameterDescription: """
                    Clear, favourable regulations can reduce uncertainty and risk for investors.
                    When watchdogs provide guidelines, more capital may flow into BTC, boosting price.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "building.2.crop.circle",
                    title: "ETF Approval",
                    isOn: $simSettings.useEtfApprovalUnified,
                    sliderValue: $simSettings.maxEtfBoostUnified,

                    // New weekly default = 0.00045468 => ±75% => ~0.00034101
                    // Range: 0.00011367 ... 0.00079569
                    // Monthly unchanged => 0.00045468 => range 0.00022734...0.00068203
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00011367...0.00079569
                        : 0.00022734...0.00068203,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00045468
                        : 0.00045468,

                    parameterDescription: """
                    Spot BTC ETFs allow traditional investors to gain exposure without holding actual BTC.
                    The ease of acquisition via brokers can significantly expand demand.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "sparkles",
                    title: "Tech Breakthrough",
                    isOn: $simSettings.useTechBreakthroughUnified,
                    sliderValue: $simSettings.maxTechBoostUnified,

                    // New weekly default = 0.00040664 => ±75% => ~0.00030498
                    // Range: 0.00010166 ... 0.00071162
                    // Monthly unchanged => 0.00040664 => range 0.00020332...0.00060996
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00010166...0.00071162
                        : 0.00020332...0.00060996,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00040664
                        : 0.00040664,

                    parameterDescription: """
                    Major improvements in Bitcoin’s protocol or L2 networks (Lightning, etc.)
                    can spur optimism and adoption, enhancing scalability or privacy.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "scalemass",
                    title: "Scarcity Events",
                    isOn: $simSettings.useScarcityEventsUnified,
                    sliderValue: $simSettings.maxScarcityBoostUnified,

                    // New weekly default = 0.0007968 => ±75% => ~0.0005976
                    // Range: 0.0001992 ... 0.0013944
                    // Monthly unchanged => 0.0007968 => range 0.0003984...0.0011952
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.0001992...0.0013944
                        : 0.0003984...0.0011952,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.0007968
                        : 0.0007968,

                    parameterDescription: """
                    Unusual events that reduce BTC supply—like large holders moving coins off exchanges—
                    can push prices upward by limiting sell pressure.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "globe.americas.fill",
                    title: "Global Macro Hedge",
                    isOn: $simSettings.useGlobalMacroHedgeUnified,
                    sliderValue: $simSettings.maxMacroBoostUnified,

                    // New weekly default = 0.00041935 => ±75% => ~0.00031451
                    // Range: 0.00010484 ... 0.00073386
                    // Monthly unchanged => 0.00041935 => range 0.00020968...0.00062904
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00010484...0.00073386
                        : 0.00020968...0.00062904,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00041935
                        : 0.00041935,

                    parameterDescription: """
                    BTC’s “digital gold” narrative can be strong during uncertainty.
                    Investors may seek refuge in BTC if they lose faith in fiat systems or markets.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "dollarsign.arrow.circlepath",
                    title: "Stablecoin Shift",
                    isOn: $simSettings.useStablecoinShiftUnified,
                    sliderValue: $simSettings.maxStablecoinBoostUnified,

                    // New weekly default = 0.00040493 => ±75% => ~0.00030370
                    // Range: 0.00010123 ... 0.00070863
                    // Monthly unchanged => 0.00040493 => range 0.00020246...0.00060739
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00010123...0.00070863
                        : 0.00020246...0.00060739,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00040493
                        : 0.00040493,

                    parameterDescription: """
                    Sometimes large sums move from stablecoins directly into BTC.
                    This short-term demand spike can push prices up quickly.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "person.3.fill",
                    title: "Demographic Adoption",
                    isOn: $simSettings.useDemographicAdoptionUnified,
                    sliderValue: $simSettings.maxDemoBoostUnified,

                    // New weekly default = 0.00130568 => ±75% => ~0.00097926
                    // Range: 0.00032642 ... 0.00228494
                    // Monthly unchanged => 0.00130568 => range 0.00065284...0.00195852
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00032642...0.00228494
                        : 0.00065284...0.00195852,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00130568
                        : 0.00130568,

                    parameterDescription: """
                    Younger, more tech-savvy generations often invest in BTC,
                    accelerating mainstream adoption over time.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "bitcoinsign.circle.fill",
                    title: "Altcoin Flight",
                    isOn: $simSettings.useAltcoinFlightUnified,
                    sliderValue: $simSettings.maxAltcoinBoostUnified,

                    // New weekly default = 0.000280219... => ±75% => ~0.0002101646
                    // Range: 0.00007005 ... 0.00049038
                    // Monthly unchanged => 0.00028022 => range 0.00014011...0.00042033
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00007005...0.00049038
                        : 0.00014011...0.00042033,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00028022
                        : 0.00028022,

                    parameterDescription: """
                    During altcoin uncertainty or crackdowns, capital can rotate into BTC,
                    considered the ‘blue-chip’ crypto with the strongest fundamentals.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "arrow.up.right.circle.fill",
                    title: "Adoption Factor (Incremental Drift)",
                    isOn: $simSettings.useAdoptionFactorUnified,
                    sliderValue: $simSettings.adoptionBaseFactorUnified,

                    // New weekly default = 0.0009685099 => ±75% => ~0.0007263824
                    // Range: 0.00024213 ... 0.00169489
                    // Monthly unchanged => 0.00096851 => range 0.00048425...0.00145276
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00024213...0.00169489
                        : 0.00048425...0.00145276,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00096851
                        : 0.00096851,

                    parameterDescription: """
                    A slow, steady upward drift in BTC price from incremental adoption.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
            }
            .listRowBackground(Color(white: 0.15))
            
            //====================================
            // BEARISH FACTORS
            //====================================
            Section("Bearish Factors") {
                FactorToggleRow(
                    iconName: "hand.raised.slash",
                    title: "Regulatory Clampdown",
                    isOn: $simSettings.useRegClampdownUnified,
                    sliderValue: $simSettings.maxClampDownUnified,
                    
                    // New weekly default = -0.0011883257 => ±75% => ~0.00089124
                    // Range: -0.00207956 ... -0.00029709
                    // Monthly unchanged => -0.00118833 => range -0.00178249 ... -0.00059416
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00207956 ... -0.00029709
                        : -0.00178249 ... -0.00059416,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00118833
                        : -0.00118833,
                    
                    parameterDescription: """
                    Strict government regulations or bans can curb adoption,
                    leading to lower demand and negative price impacts.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "bitcoinsign.circle",
                    title: "Competitor Coin",
                    isOn: $simSettings.useCompetitorCoinUnified,
                    sliderValue: $simSettings.maxCompetitorBoostUnified,
                    
                    // New weekly default = -0.0007437381 => ±75% => ~0.00055780
                    // Range: -0.00130154 ... -0.00018593
                    // Monthly unchanged => -0.00112599 => range -0.00168899 ... -0.00056299
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00130154 ... -0.00018593
                        : -0.00168899 ... -0.00056299,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00074374
                        : -0.00112599,
                    
                    parameterDescription: """
                    A rival cryptocurrency that promises superior tech or speed
                    may siphon capital away from BTC, reducing its dominance.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "lock.shield",
                    title: "Security Breach",
                    isOn: $simSettings.useSecurityBreachUnified,
                    sliderValue: $simSettings.breachImpactUnified,
                    
                    // New weekly default = -0.0007612827 => ±75% => ~0.00057096
                    // Range: -0.00133224 ... -0.00019032
                    // Monthly unchanged => -0.00076128 => range -0.00114192 ... -0.00038064
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00133224 ... -0.00019032
                        : -0.00114192 ... -0.00038064,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00076128
                        : -0.00076128,
                    
                    parameterDescription: """
                    A major hack or exploit targeting BTC or big exchanges
                    can severely damage confidence and cause panic selling.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "bubble.left.and.bubble.right.fill",
                    title: "Bubble Pop",
                    isOn: $simSettings.useBubblePopUnified,
                    sliderValue: $simSettings.maxPopDropUnified,
                    
                    // Weekly default remains -0.0012555069 => ±75% => ~0.00094163
                    // Range: -0.00219713 ... -0.00031388
                    // Monthly unchanged => -0.00125551 => range -0.00188326...-0.00062775
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00219713 ... -0.00031388
                        : -0.00188326 ... -0.00062775,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00125551
                        : -0.00125551,
                    
                    parameterDescription: """
                    Speculative bubbles can burst, causing a rapid and sharp crash
                    once fear and profit-taking set in.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "exclamationmark.triangle.fill",
                    title: "Stablecoin Meltdown",
                    isOn: $simSettings.useStablecoinMeltdownUnified,
                    sliderValue: $simSettings.maxMeltdownDropUnified,
                    
                    // New weekly default = -0.0006013240 => ±75% => ~0.000450993
                    // Range: -0.00105231 ... -0.00015033
                    // Monthly unchanged => -0.00070280 => range -0.00105421 ... -0.00035140
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00105231 ... -0.00015033
                        : -0.00105421 ... -0.00035140,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00060132
                        : -0.00070280,
                    
                    parameterDescription: """
                    Major stablecoins de-pegging or collapsing can spark a crisis of confidence
                    that spills over into BTC markets.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                // 6) Black Swan Events
                FactorToggleRow(
                    iconName: "tornado",
                    title: "Black Swan Events",
                    isOn: $simSettings.useBlackSwanUnified,
                    sliderValue: $simSettings.blackSwanDropUnified,

                    // new weekly default -0.3 => ±50% => half = 0.15 => range -0.45 ... -0.15
                    // monthly unchanged => -0.00276172 ... -0.00092057
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.45 ... -0.15
                        : -0.00276172 ... -0.00092057,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.3
                        : -0.00184115,

                    parameterDescription: """
                    Highly unpredictable disasters or wars can undermine all markets,
                    including BTC, causing extreme selloffs.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "chart.bar.xaxis",
                    title: "Bear Market Conditions",
                    isOn: $simSettings.useBearMarketUnified,
                    sliderValue: $simSettings.bearWeeklyDriftUnified,
                    
                    // New weekly default = -0.0001 => ±75% => 0.000075
                    // Range: -0.000175 ... -0.000025
                    // Monthly unchanged => -0.00071953 => range -0.00107930 ... -0.00035977
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.000175 ... -0.000025
                        : -0.00107930 ... -0.00035977,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.0001
                        : -0.00071953,
                    
                    parameterDescription: """
                    Prolonged negativity in crypto can produce a steady downward trend,
                    with capitulations and lower trading volumes.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "chart.line.downtrend.xyaxis",
                    title: "Declining ARR / Maturing Market",
                    isOn: $simSettings.useMaturingMarketUnified,
                    sliderValue: $simSettings.maxMaturingDropUnified,
                    
                    // New weekly default = -0.0032688174 => ±75% => ~0.002451613
                    // Range: -0.00572043 ... -0.00081720
                    // Monthly unchanged => -0.004 => range -0.006 ... -0.002
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00572043 ... -0.00081720
                        : -0.006 ... -0.002,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00326882
                        : -0.004,
                    
                    parameterDescription: """
                    As BTC matures, growth rates slow, leading to smaller returns
                    and reduced speculative enthusiasm.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "chart.line.downtrend.xyaxis.circle.fill",
                    title: "Recession / Macro Crash",
                    isOn: $simSettings.useRecessionUnified,
                    sliderValue: $simSettings.maxRecessionDropUnified,
                    
                    // New weekly default = -0.0010073162 => ±75% => ~0.000755487
                    // Range: -0.00176280 ... -0.00025183
                    // Monthly unchanged => -0.00145081 => range -0.00217621 ... -0.00072540
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00176280 ... -0.00025183
                        : -0.00217621 ... -0.00072540,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00100732
                        : -0.00145081,
                    
                    parameterDescription: """
                    Global economic downturns reduce risk appetite,
                    prompting investors to exit BTC to shore up liquidity.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
            }
            .listRowBackground(Color(white: 0.15))
            
            //====================================
            // TOGGLE ALL FACTORS
            //====================================
            Section {
                Toggle("Toggle All Factors",
                       isOn: Binding<Bool>(
                           get: { simSettings.toggleAll },
                           set: { newValue in
                               // When the user toggles in the UI, set the flag
                               simSettings.userIsActuallyTogglingAll = true
                               simSettings.toggleAll = newValue
                           }
                       )
                )
                .tint(.orange)
                .foregroundColor(.white)
            } header: {
                Text("Toggle All Factors")
            } footer: {
                Text("Switch all bullish and bearish factors on or off at once.")
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color(white: 0.15))
            
            //====================================
            // RANDOM SEED
            //====================================
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
            
            //====================================
            // GROWTH MODEL TOGGLE
            //====================================
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
            
            //====================================
            // HISTORICAL SAMPLING
            //====================================
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
            
            //====================================
            // VOLATILITY
            //====================================
            Section {
                Toggle("Use Volatility Shocks", isOn: $simSettings.useVolShocks)
                    .tint(.orange)
                    .foregroundColor(.white)
            } header: {
                Text("Volatility")
            } footer: {
                Text("Enables random volatility spikes during simulations.")
                    .foregroundColor(.secondary)
            }
            .listRowBackground(Color(white: 0.15))
            
            //====================================
            // RESTORE DEFAULTS
            //====================================
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
            
            //====================================
            // ABOUT
            //====================================
            Section {
                NavigationLink("About") {
                    AboutView()
                }
            } header: {
                Text("About")
            }
            .listRowBackground(Color(white: 0.15))
            
            //====================================
            // RESET CRITERIA
            //====================================
            Section {
                Button("Reset All Criteria") {
                    showResetCriteriaConfirmation = true
                }
                .buttonStyle(PressableDestructiveButtonStyle())
                .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation, actions: {
                    Button("Reset", role: .destructive) {
                        // Reset all factor settings
                        simSettings.restoreDefaults()
                        // Force onboarding again
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

                    let anchorX = proxy[item.anchor].x
                    let baseY = proxy[item.anchor].y
                    let anchorY = (item.title == "Halving") ? (baseY - 16) : baseY
                    
                    let spaceBelow = proxy.size.height - anchorY
                    let arrowDirection: ArrowDirection = spaceBelow > (bubbleHeight + 40) ? .up : .down

                    let proposedX = anchorX - (bubbleWidth / 2)
                    let clampedX = max(10, min(proposedX, proxy.size.width - bubbleWidth - 10))

                    let proposedY = arrowDirection == .up
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
                        
                        TooltipBubble(
                            text: item.description,
                            arrowDirection: arrowDirection
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: bubbleWidth)
                        .position(
                            x: clampedX + bubbleWidth / 2,
                            y: clampedY + bubbleHeight / 2
                        )
                    }
                    .transition(.opacity)
                    .zIndex(999)
                } else {
                    EmptyView()
                }
            }
        }
    }
    
    /// If tapped factor is already active, hide it. Otherwise activate it.
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
