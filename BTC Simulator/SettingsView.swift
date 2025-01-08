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
    
    /// 1) Use @AppStorage to tie directly to the "hasOnboarded" key.
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
                // Halving
                FactorToggleRow(
                    iconName: "globe.europe.africa",
                    title: "Halving",
                    isOn: $simSettings.useHalving,
                    sliderValue: $simSettings.halvingBump,
                    sliderRange: 0.0...0.95934440304668566, // double of 0.47967220152334283
                    defaultValue: 0.47967220152334283,
                    parameterDescription: """
                        Occurs roughly every four years, reducing the block reward in half.
                        This lowers the new supply entering circulation, often causing supply-demand imbalances.
                        Historically, halving events have coincided with substantial BTC price increases.
                        """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
                .anchorPreference(
                    key: TooltipAnchorKey.self,
                    value: .center
                ) { pt in
                    guard activeFactor == "Halving" else { return [] }
                    let desc = """
                        Occurs roughly every four years, reducing the block reward in half.
                        Historically, halving events have coincided with substantial BTC price increases.
                        """
                    return [ TooltipItem(title: "Halving", description: desc, anchor: pt) ]
                }
                
                // Institutional Demand
                FactorToggleRow(
                    iconName: "building.columns.fill",
                    title: "Institutional Demand",
                    isOn: $simSettings.useInstitutionalDemand,
                    sliderValue: $simSettings.maxDemandBoost,
                    sliderRange: 0.0...0.0024785082677343554, // double of 0.0012392541338671777
                    defaultValue: 0.0012392541338671777,
                    parameterDescription: """
                Large financial institutions and corporate treasuries entering the BTC market can drive prices up.
                Increased legitimacy and adoption by well-known firms can attract more mainstream interest.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Country Adoption
                FactorToggleRow(
                    iconName: "flag.fill",
                    title: "Country Adoption",
                    isOn: $simSettings.useCountryAdoption,
                    sliderValue: $simSettings.maxCountryAdBoost,
                    sliderRange: 0.0...0.0009419192839966337, // double of 0.00047095964199831683
                    defaultValue: 0.00047095964199831683,
                    parameterDescription: """
                Nations adopting BTC as legal tender or as part of their reserves can lead to massive demand.
                Wider government acceptance signals mainstream credibility and potential new use cases.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Regulatory Clarity
                FactorToggleRow(
                    iconName: "checkmark.shield",
                    title: "Regulatory Clarity",
                    isOn: $simSettings.useRegulatoryClarity,
                    sliderValue: $simSettings.maxClarityBoost,
                    sliderRange: 0.0...0.0033288047498949932, // double of 0.0016644023749474966
                    defaultValue: 0.0016644023749474966,
                    parameterDescription: """
                Clear, favourable regulations can reduce uncertainty and risk for investors.
                When watchdogs provide guidelines, more capital may flow into BTC, boosting price.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // ETF Approval
                FactorToggleRow(
                    iconName: "building.2.crop.circle",
                    title: "ETF Approval",
                    isOn: $simSettings.useEtfApproval,
                    sliderValue: $simSettings.maxEtfBoost,
                    sliderRange: 0.0...0.0009093700408935548, // double of 0.0004546850204467774
                    defaultValue: 0.0004546850204467774,
                    parameterDescription: """
                Spot BTC ETFs allow traditional investors to gain exposure without holding actual BTC.
                The ease of acquisition via brokers can significantly expand demand.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Tech Breakthrough
                FactorToggleRow(
                    iconName: "sparkles",
                    title: "Tech Breakthrough",
                    isOn: $simSettings.useTechBreakthrough,
                    sliderValue: $simSettings.maxTechBoost,
                    sliderRange: 0.0...0.0008132791949127451, // double of 0.00040663959745637255
                    defaultValue: 0.00040663959745637255,
                    parameterDescription: """
                Major improvements in Bitcoin’s protocol or L2 networks (Lightning, etc.)
                can spur optimism and adoption, enhancing scalability or privacy.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Scarcity Events
                FactorToggleRow(
                    iconName: "scalemass",
                    title: "Scarcity Events",
                    isOn: $simSettings.useScarcityEvents,
                    sliderValue: $simSettings.maxScarcityBoost,
                    sliderRange: 0.0...0.0015936167868886078, // double of 0.0007968083934443039
                    defaultValue: 0.0007968083934443039,
                    parameterDescription: """
                Unusual events that reduce BTC supply—like large holders moving coins off exchanges—
                can push prices upward by limiting sell pressure.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Global Macro Hedge
                FactorToggleRow(
                    iconName: "globe.americas.fill",
                    title: "Global Macro Hedge",
                    isOn: $simSettings.useGlobalMacroHedge,
                    sliderValue: $simSettings.maxMacroBoost,
                    sliderRange: 0.0...0.000838709145784378, // double of 0.000419354572892189
                    defaultValue: 0.000419354572892189,
                    parameterDescription: """
                BTC’s “digital gold” narrative can be strong during uncertainty.
                Investors may seek refuge in BTC if they lose faith in fiat systems or markets.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Stablecoin Shift
                FactorToggleRow(
                    iconName: "dollarsign.arrow.circlepath",
                    title: "Stablecoin Shift",
                    isOn: $simSettings.useStablecoinShift,
                    sliderValue: $simSettings.maxStablecoinBoost,
                    sliderRange: 0.0...0.000809852472620355, // double of 0.0004049262363101775
                    defaultValue: 0.0004049262363101775,
                    parameterDescription: """
                Sometimes large sums move from stablecoins directly into BTC.
                This short-term demand spike can push prices up quickly.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Demographic Adoption
                FactorToggleRow(
                    iconName: "person.3.fill",
                    title: "Demographic Adoption",
                    isOn: $simSettings.useDemographicAdoption,
                    sliderValue: $simSettings.maxDemoBoost,
                    sliderRange: 0.0...0.0026113669872283936, // double of 0.0013056834936141968
                    defaultValue: 0.0013056834936141968,
                    parameterDescription: """
                Younger, more tech-savvy generations often invest in BTC,
                accelerating mainstream adoption over time.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Altcoin Flight
                FactorToggleRow(
                    iconName: "bitcoinsign.circle.fill",
                    title: "Altcoin Flight",
                    isOn: $simSettings.useAltcoinFlight,
                    sliderValue: $simSettings.maxAltcoinBoost,
                    sliderRange: 0.0...0.0005604388923606684, // double of 0.0002802194461803342
                    defaultValue: 0.0002802194461803342,
                    parameterDescription: """
                During altcoin uncertainty or crackdowns, capital can rotate into BTC,
                considered the ‘blue-chip’ crypto with the strongest fundamentals.
                """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Adoption Factor
                FactorToggleRow(
                    iconName: "arrow.up.right.circle.fill",
                    title: "Adoption Factor (Incremental Drift)",
                    isOn: $simSettings.useAdoptionFactor,
                    sliderValue: $simSettings.adoptionBaseFactor,
                    sliderRange: 0.0...0.0019370198249816894, // double of 0.0009685099124908447
                    defaultValue: 0.0009685099124908447,
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
                // Regulatory Clampdown
                FactorToggleRow(
                    iconName: "hand.raised.slash",
                    title: "Regulatory Clampdown",
                    isOn: $simSettings.useRegClampdown,
                    sliderValue: $simSettings.maxClampDown,
                    sliderRange: -0.002376651382446289...0.0, // double of -0.0011883256912231445
                    defaultValue: -0.0011883256912231445,
                    parameterDescription: """
                    Strict government regulations or bans can curb adoption,
                    leading to lower demand and negative price impacts.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Competitor Coin
                FactorToggleRow(
                    iconName: "bitcoinsign.circle",
                    title: "Competitor Coin",
                    isOn: $simSettings.useCompetitorCoin,
                    sliderValue: $simSettings.maxCompetitorBoost,
                    sliderRange: -0.0022519826889038086...0.0, // double of -0.0011259913444519043
                    defaultValue: -0.0011259913444519043,
                    parameterDescription: """
                    A rival cryptocurrency that promises superior tech or speed
                    may siphon capital away from BTC, reducing its dominance.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Security Breach
                FactorToggleRow(
                    iconName: "lock.shield",
                    title: "Security Breach",
                    isOn: $simSettings.useSecurityBreach,
                    sliderValue: $simSettings.breachImpact,
                    sliderRange: -0.0015225654668768184...0.0, // double of -0.0007612827334384092
                    defaultValue: -0.0007612827334384092,
                    parameterDescription: """
                    A major hack or exploit targeting BTC or big exchanges
                    can severely damage confidence and cause panic selling.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Bubble Pop
                FactorToggleRow(
                    iconName: "bubble.left.and.bubble.right.fill",
                    title: "Bubble Pop",
                    isOn: $simSettings.useBubblePop,
                    sliderValue: $simSettings.maxPopDrop,
                    sliderRange: -0.002511013746261597...0.0,
                    defaultValue: -0.0012555068731307985,
                    parameterDescription: """
                    Speculative bubbles can burst, causing a rapid and sharp crash
                    once fear and profit-taking set in.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Stablecoin Meltdown
                FactorToggleRow(
                    iconName: "exclamationmark.triangle.fill",
                    title: "Stablecoin Meltdown",
                    isOn: $simSettings.useStablecoinMeltdown,
                    sliderValue: $simSettings.maxMeltdownDrop,
                    sliderRange: -0.0014056092410835674...0.0, // double of -0.0007028046205417837
                    defaultValue: -0.0007028046205417837,
                    parameterDescription: """
                    Major stablecoins de-pegging or collapsing can spark a crisis of confidence
                    that spills over into BTC markets.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Black Swan Events
                FactorToggleRow(
                    iconName: "tornado",
                    title: "Black Swan Events",
                    isOn: $simSettings.useBlackSwan,
                    sliderValue: $simSettings.blackSwanDrop,
                    sliderRange: -0.0036822905567344966...0.0, // double of -0.0018411452783672483
                    defaultValue: -0.0018411452783672483,
                    parameterDescription: """
                    Highly unpredictable disasters or wars can undermine all markets,
                    including BTC, causing extreme selloffs.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Bear Market Conditions
                FactorToggleRow(
                    iconName: "chart.bar.xaxis",
                    title: "Bear Market Conditions",
                    isOn: $simSettings.useBearMarket,
                    sliderValue: $simSettings.bearWeeklyDrift,
                    sliderRange: -0.0014390611648559538...0.0,
                    defaultValue: -0.0007195305824279769,
                    parameterDescription: """
                    Prolonged negativity in crypto can produce a steady downward trend,
                    with capitulations and lower trading volumes.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Declining ARR / Maturing Market
                FactorToggleRow(
                    iconName: "chart.line.downtrend.xyaxis",
                    title: "Declining ARR / Maturing Market",
                    isOn: $simSettings.useMaturingMarket,
                    sliderValue: $simSettings.maxMaturingDrop,
                    sliderRange: -0.002511012554168704...0.0,
                    defaultValue: -0.001255506277084352,
                    parameterDescription: """
                    As BTC matures, growth rates slow, leading to smaller returns
                    and reduced speculative enthusiasm.
                    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Recession / Macro Crash
                FactorToggleRow(
                    iconName: "chart.line.downtrend.xyaxis.circle.fill",
                    title: "Recession / Macro Crash",
                    isOn: $simSettings.useRecession,
                    sliderValue: $simSettings.maxRecessionDrop,
                    sliderRange: -0.0029016160964965826...0.0,
                    defaultValue: -0.0014508080482482913,
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
            Section("Toggle All Factors") {
                Toggle("Toggle All Factors", isOn: $simSettings.toggleAll)
                    .tint(.orange)
                    .foregroundColor(.white)
            }
            .listRowBackground(Color(white: 0.15))
            
            //====================================
            // RANDOM SEED
            //====================================
            Section("Random Seed") {
                Toggle("Lock Random Seed", isOn: $simSettings.lockedRandomSeed)
                    .tint(.orange)
                    .onChange(of: simSettings.lockedRandomSeed) { locked in
                        if locked {
                            // Generate a new seed & fix it
                            let newSeed = UInt64.random(in: 0..<UInt64.max)
                            simSettings.seedValue = newSeed
                            simSettings.useRandomSeed = false
                        } else {
                            // Unlock the seed
                            simSettings.seedValue = 0
                            simSettings.useRandomSeed = true
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color(white: 0.15))

                if simSettings.lockedRandomSeed {
                    Text("Current Seed (Locked): \(simSettings.seedValue)")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .listRowBackground(Color(white: 0.15))
                } else {
                    if simSettings.lastUsedSeed == 0 {
                        Text("Current Seed: (no run yet)")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))
                    } else {
                        Text("Current Seed (Unlocked): \(simSettings.lastUsedSeed)")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .listRowBackground(Color(white: 0.15))
                    }
                }
            }
            .listRowBackground(Color(white: 0.15))

            //====================================
            // NEW: LOCK HISTORICAL SAMPLING
            //====================================
            Section("Historical Sampling") {
                Toggle("Lock Historical Sampling", isOn: $simSettings.lockHistoricalSampling)
                    .tint(.orange)
                    .foregroundColor(.white)
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
            }
            .listRowBackground(Color(white: 0.15))

            //====================================
            // ABOUT
            //====================================
            Section {
                NavigationLink("About") {
                    AboutView()
                }
            }
            .listRowBackground(Color(white: 0.15))

            //====================================
            // RESET CRITERIA
            //====================================
            Section("Reset Criteria") {
                Button("Reset All Criteria") {
                    showResetCriteriaConfirmation = true
                }
                .buttonStyle(PressableDestructiveButtonStyle())
                .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation) {
                    Button("Reset", role: .destructive) {
                        // Reset all factor settings to the old midpoints, or your custom logic
                        simSettings.restoreDefaults()
                        // 2) Ensure "hasOnboarded" is false so onboarding reappears
                        didFinishOnboarding = false
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("All custom criteria will be restored to default. This cannot be undone.")
                }
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
                guard let item = allAnchors.last else {
                    return AnyView(EmptyView())
                }
                
                let bubbleWidth: CGFloat = 240
                let bubbleHeight: CGFloat = 220
                let offset: CGFloat = 8

                let anchorX = proxy[item.anchor].x
                var anchorY = proxy[item.anchor].y

                // Nudge "Halving" tooltip up a bit
                if item.title == "Halving" {
                    anchorY -= 16
                }

                let spaceBelow = proxy.size.height - anchorY
                let arrowDirection: ArrowDirection = spaceBelow > (bubbleHeight + 40) ? .up : .down

                // Clamp X
                let proposedX = anchorX - (bubbleWidth / 2)
                let clampedX = max(10, min(proposedX, proxy.size.width - bubbleWidth - 10))

                // Clamp Y
                let proposedY = arrowDirection == .up
                    ? (anchorY + offset)
                    : (anchorY - offset - bubbleHeight)
                let clampedY = max(10, min(proposedY, proxy.size.height - bubbleHeight - 10))

                return AnyView(
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
                )
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
