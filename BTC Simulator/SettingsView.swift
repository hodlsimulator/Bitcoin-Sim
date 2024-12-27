//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings

    init() {
        // 1) OPAQUE for LARGE TITLE (expanded/scrollEdge)
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

        // 2) BLURRED & SEMI-TRANSPARENT for COLLAPSED (standard)
        let blurredAppearance = UINavigationBarAppearance()
        blurredAppearance.configureWithTransparentBackground()
        blurredAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        blurredAppearance.backgroundColor = UIColor(white: 0.12, alpha: 0.3)

        blurredAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        blurredAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular)
        ]

        // 3) HIDE “Back” TEXT, SHOW ONLY A WHITE CHEVRON (pre-tinted)
        let chevronImage = UIImage(systemName: "chevron.left")?
            .withTintColor(.white, renderingMode: .alwaysOriginal)

        // Create an appearance for the back button that shifts text off-screen
        let backItem = UIBarButtonItemAppearance(style: .plain)
        backItem.normal.titlePositionAdjustment = UIOffset(horizontal: -3000, vertical: 0)
        
        // Assign the tinted chevron to each appearance
        opaqueAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        blurredAppearance.setBackIndicatorImage(chevronImage, transitionMaskImage: chevronImage)
        
        opaqueAppearance.backButtonAppearance = backItem
        blurredAppearance.backButtonAppearance = backItem

        // 4) Assign them to the relevant nav states
        UINavigationBar.appearance().scrollEdgeAppearance = opaqueAppearance   // Large title = opaque
        UINavigationBar.appearance().standardAppearance   = blurredAppearance  // Collapsed = blurred
        UINavigationBar.appearance().compactAppearance    = blurredAppearance

        // 5) Try also forcing the nav bar’s tintColor to white
        UINavigationBar.appearance().tintColor = .white
    }

    var body: some View {
        Form {
            // BULLISH FACTORS
            Section("Bullish Factors") {
                Toggle("Halving", isOn: $simSettings.useHalving)
                Toggle("Institutional Demand", isOn: $simSettings.useInstitutionalDemand)
                Toggle("Country Adoption", isOn: $simSettings.useCountryAdoption)
                Toggle("Regulatory Clarity", isOn: $simSettings.useRegulatoryClarity)
                Toggle("ETF Approval", isOn: $simSettings.useEtfApproval)
                Toggle("Tech Breakthrough", isOn: $simSettings.useTechBreakthrough)
                Toggle("Scarcity Events", isOn: $simSettings.useScarcityEvents)
                Toggle("Global Macro Hedge", isOn: $simSettings.useGlobalMacroHedge)
                Toggle("Stablecoin Shift", isOn: $simSettings.useStablecoinShift)
                Toggle("Demographic Adoption", isOn: $simSettings.useDemographicAdoption)
                Toggle("Altcoin Flight", isOn: $simSettings.useAltcoinFlight)
                Toggle("Adoption Factor (Incremental Drift)", isOn: $simSettings.useAdoptionFactor)
            }
            .listRowBackground(Color(white: 0.15))

            // BEARISH FACTORS
            Section("Bearish Factors") {
                Toggle("Regulatory Clampdown", isOn: $simSettings.useRegClampdown)
                Toggle("Competitor Coin", isOn: $simSettings.useCompetitorCoin)
                Toggle("Security Breach", isOn: $simSettings.useSecurityBreach)
                Toggle("Bubble Pop", isOn: $simSettings.useBubblePop)
                Toggle("Stablecoin Meltdown", isOn: $simSettings.useStablecoinMeltdown)
                Toggle("Black Swan Events", isOn: $simSettings.useBlackSwan)
                Toggle("Bear Market Conditions", isOn: $simSettings.useBearMarket)
                Toggle("Declining ARR / Maturing Market", isOn: $simSettings.useMaturingMarket)
                Toggle("Recession / Macro Crash", isOn: $simSettings.useRecession)
            }
            .listRowBackground(Color(white: 0.15))
        }
        .environment(\.colorScheme, .dark)
        .listStyle(GroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.12))

        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}
