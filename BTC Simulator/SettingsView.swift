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

/// Stores the factor title, description, and an anchor to place the tooltip bubble.
struct TooltipItem {
    let title: String
    let description: String
    let anchor: Anchor<CGPoint>
}

/// A preference key collecting anchors from rows. We only display the last one if multiple are tapped.
struct TooltipAnchorKey: PreferenceKey {
    static var defaultValue: [TooltipItem] = []
    static func reduce(value: inout [TooltipItem], nextValue: () -> [TooltipItem]) {
        value.append(contentsOf: nextValue())
    }
}

/// The main Settings view where we configure bullish & bearish factors, seeds, etc.
struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings
    @State private var showResetCriteriaConfirmation = false

    /// Which factor's tooltip is currently showing. Nil if none are showing.
    @State private var activeFactor: String? = nil

    init() {
        // Custom navigation bar appearances for large vs. collapsed states
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

        // This is for the collapsed (scrolled) state
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

        // Apply to the UINavigationBar
        UINavigationBar.appearance().scrollEdgeAppearance = opaqueAppearance
        UINavigationBar.appearance().standardAppearance   = blurredAppearance
        UINavigationBar.appearance().compactAppearance    = blurredAppearance
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some View {
        Form {
            
            //==================
            // BULLISH FACTORS
            //==================
            Section("Bullish Factors") {
                // Example: Halving factor
                FactorToggleRow(
                    iconName: "globe.europe.africa",
                    title: "Halving",
                    isOn: $simSettings.useHalving,
                    sliderValue: $simSettings.halvingBump,
                    sliderRange: 0.0...1.0,
                    defaultValue: 0.20,
                    parameterDescription: """
    Occurs roughly every four years, reducing the block reward in half. 
    This lowers the new supply entering circulation, often causing supply-demand imbalances. 
    Historically, halving events have coincided with substantial BTC price increases.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                // Additional Bullish FactorToggleRows (Institutional Demand, Country Adoption, etc.)
                FactorToggleRow(
                    iconName: "building.columns.fill",
                    title: "Institutional Demand",
                    isOn: $simSettings.useInstitutionalDemand,
                    sliderValue: $simSettings.maxDemandBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.004,
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
                    isOn: $simSettings.useCountryAdoption,
                    sliderValue: $simSettings.maxCountryAdBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.0055,
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
                    isOn: $simSettings.useRegulatoryClarity,
                    sliderValue: $simSettings.maxClarityBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.0006,
                    parameterDescription: """
    Clear, favourable regulations can reduce uncertainty and risk for investors. 
    When financial watchdogs provide guidelines, more capital may flow into BTC, boosting price.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "building.2.crop.circle",
                    title: "ETF Approval",
                    isOn: $simSettings.useEtfApproval,
                    sliderValue: $simSettings.maxEtfBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.0008,
                    parameterDescription: """
    Spot BTC ETFs allow traditional investors to gain exposure without holding actual BTC. 
    The ease of acquisition via brokers or retirement accounts can significantly expand demand.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "sparkles",
                    title: "Tech Breakthrough",
                    isOn: $simSettings.useTechBreakthrough,
                    sliderValue: $simSettings.maxTechBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.002,
                    parameterDescription: """
    Major improvements in Bitcoin’s protocol or related layer-2 networks (e.g., Lightning) 
    can spur optimism and adoption. Technological leaps can also enhance scalability.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "scalemass",
                    title: "Scarcity Events",
                    isOn: $simSettings.useScarcityEvents,
                    sliderValue: $simSettings.maxScarcityBoost,
                    sliderRange: 0.0...0.05,
                    defaultValue: 0.025,
                    parameterDescription: """
    Unusual events that reduce BTC supply—such as large holders moving coins off exchanges 
    or long-term investors hoarding—can push prices upward by limiting sell pressure.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "globe.americas.fill",
                    title: "Global Macro Hedge",
                    isOn: $simSettings.useGlobalMacroHedge,
                    sliderValue: $simSettings.maxMacroBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.0015,
                    parameterDescription: """
    A narrative of BTC as “digital gold” or a store of value can be strong during times of global uncertainty. 
    Investors may seek refuge in BTC if they lose faith in fiat systems or traditional markets.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "dollarsign.arrow.circlepath",
                    title: "Stablecoin Shift",
                    isOn: $simSettings.useStablecoinShift,
                    sliderValue: $simSettings.maxStablecoinBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.0006,
                    parameterDescription: """
    Sometimes large sums of capital move from stablecoins (like USDT or USDC) directly into BTC. 
    This immediate demand spike can push the BTC price up in a short period.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "person.3.fill",
                    title: "Demographic Adoption",
                    isOn: $simSettings.useDemographicAdoption,
                    sliderValue: $simSettings.maxDemoBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.001,
                    parameterDescription: """
    Younger generations, often more tech-savvy and open to digital assets, 
    may increasingly view BTC as a standard investment, accelerating mainstream adoption.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "bitcoinsign.circle.fill",
                    title: "Altcoin Flight",
                    isOn: $simSettings.useAltcoinFlight,
                    sliderValue: $simSettings.maxAltcoinBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.001,
                    parameterDescription: """
    During periods of altcoin uncertainty or regulatory crackdowns, capital can rotate 
    back into BTC, considered the ‘blue-chip’ crypto with the strongest fundamentals.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "arrow.up.right.circle.fill",
                    title: "Adoption Factor (Incremental Drift)",
                    isOn: $simSettings.useAdoptionFactor,
                    sliderValue: $simSettings.adoptionBaseFactor,
                    sliderRange: 0.0...0.0001,
                    defaultValue: 0.000005,
                    parameterDescription: """
    A slow yet steady upward drift in BTC’s price, driven by long-term adoption trends. 
    This can reflect consistent global user growth, brand recognition, and network effects.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
            }
            .listRowBackground(Color(white: 0.15))

            //==================
            // BEARISH FACTORS
            //==================
            Section("Bearish Factors") {
                FactorToggleRow(
                    iconName: "hand.raised.slash",
                    title: "Regulatory Clampdown",
                    isOn: $simSettings.useRegClampdown,
                    sliderValue: $simSettings.maxClampDown,
                    sliderRange: -0.01...0.0,
                    defaultValue: -0.0002,
                    parameterDescription: """
    Strict government regulations or outright bans can curb trading and adoption, 
    leading to lower demand and negative price impacts.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "bitcoinsign.circle",
                    title: "Competitor Coin",
                    isOn: $simSettings.useCompetitorCoin,
                    sliderValue: $simSettings.maxCompetitorBoost,
                    sliderRange: -0.01...0.0,
                    defaultValue: -0.0018,
                    parameterDescription: """
    A rival cryptocurrency can siphon capital away from BTC if it promises superior tech, 
    faster transactions, or better scalability, reducing BTC’s dominance.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "lock.shield",
                    title: "Security Breach",
                    isOn: $simSettings.useSecurityBreach,
                    sliderValue: $simSettings.breachImpact,
                    sliderRange: -1.0...0.0,
                    defaultValue: -0.1,
                    parameterDescription: """
    A major exploit or hack targeting BTC itself, major exchanges, or custodial services 
    can severely damage market confidence and cause panic selling.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "bubble.left.and.bubble.right.fill",
                    title: "Bubble Pop",
                    isOn: $simSettings.useBubblePop,
                    sliderValue: $simSettings.maxPopDrop,
                    sliderRange: -0.01...0.0,
                    defaultValue: -0.005,
                    parameterDescription: """
    Rapidly inflating speculative bubbles can burst, leading to a sudden and sharp price crash. 
    Hype-driven rallies often correct once fear and profit-taking set in.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "exclamationmark.triangle.fill",
                    title: "Stablecoin Meltdown",
                    isOn: $simSettings.useStablecoinMeltdown,
                    sliderValue: $simSettings.maxMeltdownDrop,
                    sliderRange: -0.01...0.0,
                    defaultValue: -0.001,
                    parameterDescription: """
    If major stablecoins de-peg or collapse, it can trigger a crisis of confidence in crypto. 
    This can spill over into BTC markets, dragging prices down in panic.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "tornado",
                    title: "Black Swan Events",
                    isOn: $simSettings.useBlackSwan,
                    sliderValue: $simSettings.blackSwanDrop,
                    sliderRange: -1.0...0.0,
                    defaultValue: -0.60,
                    parameterDescription: """
    Highly unpredictable events (e.g., large-scale war, catastrophic disaster) 
    can undermine global markets, including BTC, causing rapid and extreme selloffs.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "chart.bar.xaxis",
                    title: "Bear Market Conditions",
                    isOn: $simSettings.useBearMarket,
                    sliderValue: $simSettings.bearWeeklyDrift,
                    sliderRange: -0.05...0.0,
                    defaultValue: -0.01,
                    parameterDescription: """
    A prolonged sentiment of negativity in the crypto space can produce steady downward pressure. 
    Such bear markets often see capitulations and lower volume trading.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "chart.line.downtrend.xyaxis",
                    title: "Declining ARR / Maturing Market",
                    isOn: $simSettings.useMaturingMarket,
                    sliderValue: $simSettings.maxMaturingDrop,
                    sliderRange: -0.05...0.0,
                    defaultValue: -0.015,
                    parameterDescription: """
    As BTC becomes more established, rapid growth rates might diminish. 
    Maturity can mean stable but lower returns, reducing speculative enthusiasm.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "chart.line.downtrend.xyaxis.circle.fill",
                    title: "Recession / Macro Crash",
                    isOn: $simSettings.useRecession,
                    sliderValue: $simSettings.maxRecessionDrop,
                    sliderRange: -0.01...0.0,
                    defaultValue: -0.004,
                    parameterDescription: """
    Global economic downturns can reduce disposable income and risk appetite, 
    leading investors to exit BTC positions to shore up liquidity in uncertain times.
    """,
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
            }
            .listRowBackground(Color(white: 0.15))

            // Moved here, just below the factors
            Section("Toggle All Factors") {
                Toggle("Toggle All Factors", isOn: $simSettings.toggleAll)
                    .tint(.orange)
                    .onAppear {
                        // Force toggleAll on at first
                        simSettings.toggleAll = true
                    }
                    .foregroundColor(.white)
            }
            .listRowBackground(Color(white: 0.15))
            
            //==================
            // RANDOM SEED
            //==================
            Section("Random Seed") {
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

            //==================
            // RESTORE DEFAULTS
            //==================
            Section {
                Button("Restore Defaults") {
                    simSettings.restoreDefaults()
                }
                .buttonStyle(PressableDestructiveButtonStyle())
            }
            .listRowBackground(Color(white: 0.15))

            //==================
            // ABOUT
            //==================
            Section {
                NavigationLink("About") {
                    AboutView()
                }
            }
            .listRowBackground(Color(white: 0.15))

            //==================
            // RESET CRITERIA
            //==================
            Section("Reset Criteria") {
                Button("Reset All Criteria") {
                    showResetCriteriaConfirmation = true
                }
                .buttonStyle(PressableDestructiveButtonStyle())
                .alert("Confirm Reset", isPresented: $showResetCriteriaConfirmation) {
                    Button("Reset", role: .destructive) {
                        simSettings.resetUserCriteria()
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
                // If multiple anchors, show the last
                if let item = allAnchors.last {
                    ZStack {
                        // Dim entire screen
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                // Dismiss on background tap
                                withAnimation {
                                    activeFactor = nil
                                }
                            }

                        let bubbleWidth: CGFloat = 240
                        let bubbleHeight: CGFloat = 220
                        let offset: CGFloat = 8
                        let anchorPt = proxy[item.anchor]

                        // Check if there's enough space below the anchor
                        let spaceBelow = proxy.size.height - anchorPt.y
                        let arrowDirection: ArrowDirection = spaceBelow > (bubbleHeight + 40) ? .up : .down

                        // For X positioning, centre over the anchor but clamp edges
                        let proposedX = anchorPt.x - (bubbleWidth / 2)
                        let clampedX = max(10, min(proposedX, proxy.size.width - bubbleWidth - 10))

                        // For Y positioning, place below if arrow up, above if arrow down
                        let proposedY = arrowDirection == .up
                            ? anchorPt.y + offset
                            : anchorPt.y - offset - bubbleHeight
                        let clampedY = max(10, min(proposedY, proxy.size.height - bubbleHeight - 10))

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

    /// Toggles the active factor if tapped again, or sets a new factor if tapped
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
