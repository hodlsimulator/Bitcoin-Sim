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

struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings

    /// Which factor's tooltip is currently showing. Nil if none.
    @State private var activeFactor: String? = nil

    init() {
        // Opaque for large title
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

        // Blurred & semi-transparent for collapsed state
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
                FactorToggleRow(
                    iconName: "globe.europe.africa",
                    title: "Halving",
                    isOn: $simSettings.useHalving,
                    sliderValue: $simSettings.halvingBump,
                    sliderRange: 0.0...1.0,
                    defaultValue: 0.20,
                    parameterDescription: "Occurs ~every 4 years; block rewards are cut in half.",
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )

                FactorToggleRow(
                    iconName: "building.columns.fill",
                    title: "Institutional Demand",
                    isOn: $simSettings.useInstitutionalDemand,
                    sliderValue: $simSettings.maxDemandBoost,
                    sliderRange: 0.0...0.01,
                    defaultValue: 0.004,
                    parameterDescription: "Large players buying BTC, possibly pushing prices up.",
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
                    parameterDescription: "Countries adopting BTC as legal tender or reserve asset.",
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
                    parameterDescription: "Clear regulations may encourage more institutional participation.",
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
                    parameterDescription: "Spot BTC ETFs increase ease of exposure for traditional investors.",
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
                    parameterDescription: "Major improvements in Bitcoin's scaling or features.",
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
                    parameterDescription: "Events limiting BTC supply, causing potential price spikes.",
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
                    parameterDescription: "Global economic issues drive more investors to store value in BTC.",
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
                    parameterDescription: "Shift from stablecoins into BTC, boosting demand.",
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
                    parameterDescription: "Younger generations adopt BTC, broadening the user base.",
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
                    parameterDescription: "Funds rotating out of altcoins into BTC as a 'safer' crypto.",
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
                    parameterDescription: "A slow, continuous adoption-driven drift upwards each week.",
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
                    parameterDescription: "Governments heavily regulating or banning BTC usage.",
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
                    parameterDescription: "A new crypto emerges and draws capital away from BTC.",
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
                    parameterDescription: "A major vulnerability discovered or exploited in BTC or key services.",
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
                    parameterDescription: "BTC speculation grows too big too fast, then collapses.",
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
                    parameterDescription: "Key stablecoins fail, undermining confidence in crypto markets.",
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
                    parameterDescription: "Severe unforeseen events causing massive sell-offs (e.g., war).",
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
                    parameterDescription: "Sustained market pessimism and negative price drift each week.",
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
                    parameterDescription: "As BTC matures, returns decline over time (lower ARR).",
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
                    parameterDescription: "Global or local economic downturn affects crypto markets.",
                    activeFactor: activeFactor,
                    onTitleTap: toggleFactor
                )
            }
            .listRowBackground(Color(white: 0.15))

            //==================
            // RANDOM SEED
            //==================
            Section("Random Seed") {
                Toggle("Lock Random Seed", isOn: $simSettings.lockedRandomSeed)
                    .onChange(of: simSettings.lockedRandomSeed) { newValue in
                        if newValue {
                            let newSeed = UInt64.random(in: 0..<UInt64.max)
                            simSettings.seedValue = newSeed
                            simSettings.useRandomSeed = false
                        } else {
                            simSettings.useRandomSeed = true
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color(white: 0.15))

                Text("Current Seed: \(simSettings.seedValue)")
                    .font(.footnote)
                    .foregroundColor(.white)
                    .listRowBackground(Color(white: 0.15))
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

        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.12))
        .environment(\.colorScheme, .dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)

        // Single top-level overlay reading anchor preferences
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

                        let arrowDirection: ArrowDirection = .up
                        let bubbleWidth: CGFloat = 240
                        let bubbleHeight: CGFloat = 100
                        let offset: CGFloat = 8

                        let anchorPt = proxy[item.anchor]
                        let proposedX = anchorPt.x - bubbleWidth / 2
                        let proposedY = anchorPt.y + offset

                        let edge: CGFloat = 10
                        let finalX = max(edge, min(proposedX, proxy.size.width - bubbleWidth - edge))
                        let finalY = max(edge, min(proposedY, proxy.size.height - bubbleHeight - edge))

                        TooltipBubble(text: item.description, arrowDirection: arrowDirection)
                            .frame(width: bubbleWidth, height: bubbleHeight)
                            .position(
                                x: finalX + bubbleWidth / 2,
                                y: finalY + bubbleHeight / 2
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
