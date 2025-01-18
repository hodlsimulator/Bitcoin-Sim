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
                    
                    // ±50% around weekly=0.48 => range 0.24...0.72
                    // ±50% around monthly=0.58 => range 0.29...0.87
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.24...0.72
                        : 0.29...0.87,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.48
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

                    // default ~0.001239 => ±50% => 0.00062...0.00186
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00062...0.00186
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

                    // default ~0.00047096 => ±50% => 0.00023548...0.00070644
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00023548...0.00070644
                        : 0.00023548...0.00070644,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? 0.00047096
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

                    // default ~0.0016644 => ±50% => 0.0008322...0.0024966
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.0008322...0.0024966
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

                    // default ~0.000454685 => ±50% => 0.00022734...0.00068203
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00022734...0.00068203
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

                    // default ~0.00040664 => ±50% => 0.00020332...0.00060996
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00020332...0.00060996
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

                    // default ~0.0007968 => ±50% => 0.0003984...0.0011952
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.0003984...0.0011952
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

                    // default ~0.00041935 => ±50% => 0.00020968...0.00062904
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00020968...0.00062904
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

                    // default ~0.00040493 => ±50% => 0.00020246...0.00060739
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00020246...0.00060739
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

                    // default ~0.00130568 => ±50% => 0.00065284...0.00195852
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00065284...0.00195852
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

                    // default ~0.00028022 => ±50% => 0.00014011...0.00042033
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00014011...0.00042033
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

                    // default ~0.00096851 => ±50% => 0.00048425...0.00145276
                    sliderRange: simSettings.periodUnit == .weeks
                        ? 0.00048425...0.00145276
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
                    
                    // default ~-0.00118833 => ±50% => range -0.00178249 ... -0.00059416
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00178249 ... -0.00059416
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
                    
                    // default ~-0.00112599 => ±50% => range -0.00168899 ... -0.00056299
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00168899 ... -0.00056299
                        : -0.00168899 ... -0.00056299,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00112599
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
                    
                    // default ~-0.00076128 => ±50% => range -0.00114192 ... -0.00038064
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00114192 ... -0.00038064
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
                    
                    // default ~-0.00125551 => ±50% => range -0.00188326 ... -0.00062775
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00188326 ... -0.00062775
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
                    
                    // default ~-0.00070280 => ±50% => range -0.00105421 ... -0.00035140
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00105421 ... -0.00035140
                        : -0.00105421 ... -0.00035140,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00070280
                        : -0.00070280,
                    
                    parameterDescription: """
                    Major stablecoins de-pegging or collapsing can spark a crisis of confidence
                    that spills over into BTC markets.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                
                FactorToggleRow(
                    iconName: "tornado",
                    title: "Black Swan Events",
                    isOn: $simSettings.useBlackSwanUnified,
                    sliderValue: $simSettings.blackSwanDropUnified,
                    
                    // default ~-0.00184115 => ±50% => range -0.00276172 ... -0.00092057
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00276172 ... -0.00092057
                        : -0.00276172 ... -0.00092057,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00184115
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
                    
                    // default ~-0.00071953 => ±50% => range -0.00107930 ... -0.00035977
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00107930 ... -0.00035977
                        : -0.00107930 ... -0.00035977,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00071953
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
                    
                    // default -0.004 => ±50% => range -0.006 ... -0.002
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.006 ... -0.002
                        : -0.006 ... -0.002,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.004
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
                    
                    // default ~-0.00145081 => ±50% => range -0.00217621 ... -0.00072540
                    sliderRange: simSettings.periodUnit == .weeks
                        ? -0.00217621 ... -0.00072540
                        : -0.00217621 ... -0.00072540,
                    defaultValue: simSettings.periodUnit == .weeks
                        ? -0.00145081
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
