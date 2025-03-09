//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI
import MessageUI

struct SettingsView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    // **Add the IAPManager as an EnvironmentObject** so AdvancedSettingsSection can see it
    @EnvironmentObject var iapManager: IAPManager

    // MARK: - Onboarding Flag
    @AppStorage("hasOnboarded") var didFinishOnboarding = false

    // MARK: - State
    @State private var showAdvancedSettings = false
    
    @State var oldFactorIntensity: Double = 0.5
    @State var storedDefaultTilt: Double? = nil
    
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    @State var hasAppeared = false
    @State var isExtremeToggle = false
    @State var extremeToggleApplied = false
    
    @State var dragTiltOverride: Double? = nil
    @State var disableFactorSync = false
    @State var isManualOverride: Bool = false
    @State private var isRestoringDefaults = false
    
    // These are factor keys used in your tilt bar logic
    let bullishKeys: [String] = [
        "Halving", "InstitutionalDemand", "CountryAdoption", "RegulatoryClarity",
        "EtfApproval", "TechBreakthrough", "ScarcityEvents", "GlobalMacroHedge",
        "StablecoinShift", "DemographicAdoption", "AltcoinFlight", "AdoptionFactor"
    ]
    let bearishKeys: [String] = [
        "RegClampdown", "CompetitorCoin", "SecurityBreach", "BubblePop",
        "StablecoinMeltdown", "BlackSwan", "BearMarket", "MaturingMarket",
        "Recession"
    ]
    @State private var oldNetValue: Double = 0.0
    
    // Feedback
    @State private var showMailView: Bool = false
    @State private var showFeedbackConsent: Bool = false

    init() {
        setupNavBarAppearance()
    }
    
    var body: some View {
        let mainForm = Form {
            
            // 1) The tilt bar
            overallTiltSection
            
            // 2) Factor intensity section (slider + extreme toggles)
            factorIntensitySection
            
            // 3) Toggle-all section
            SettingsSections.toggleAllSection(
                simSettings: simSettings,
                monthlySimSettings: monthlySimSettings
            )
            
            // 4) Restore Defaults
            Section {
                Button(action: {
                    print("simSettings.periodUnit = \(simSettings.periodUnit)")
                    if simSettings.periodUnit == .weeks {
                        print("Restoring weekly defaults")
                        simSettings.restoreDefaults()
                        simSettings.saveToUserDefaults()
                        simSettings.loadFromUserDefaults()  // Force re‑load
                    } else if simSettings.periodUnit == .months {
                        print("Restoring monthly defaults")
                        monthlySimSettings.restoreDefaultsMonthly(whenIn: simSettings.periodUnit)
                        monthlySimSettings.saveToUserDefaultsMonthly()
                        monthlySimSettings.loadFromUserDefaultsMonthly()
                    }
                }) {
                    HStack {
                        Text("Restore Defaults")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listRowBackground(Color(white: 0.15))
            
            // 5) Bullish factors
            BullishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: { factorName in
                    activeFactor = factorName
                },
                onFactorChange: {
                    // Recompute tilt bar
                    if simSettings.periodUnit == .months {
                        monthlySimSettings.recalcTiltBarValueMonthly(
                            bullishKeys: bullishKeys,
                            bearishKeys: bearishKeys
                        )
                    } else {
                        simSettings.recalcTiltBarValue(
                            bullishKeys: bullishKeys,
                            bearishKeys: bearishKeys
                        )
                    }
                }
            )
            
            // 6) Bearish factors
            BearishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: { factorName in
                    activeFactor = factorName
                },
                onFactorChange: {
                    // Recompute tilt bar
                    if simSettings.periodUnit == .months {
                        monthlySimSettings.recalcTiltBarValueMonthly(
                            bullishKeys: bullishKeys,
                            bearishKeys: bearishKeys
                        )
                    } else {
                        simSettings.recalcTiltBarValue(
                            bullishKeys: bullishKeys,
                            bearishKeys: bearishKeys
                        )
                    }
                }
            )
            
            // 7) Advanced settings
            // Make sure it inherits iapManager from above (no need for .environmentObject(iapManager) again,
            // because this SettingsView already has it in its environment)
            AdvancedSettingsSection(showAdvancedSettings: $showAdvancedSettings)
            
            // 8) About + reset
            aboutSection
            resetCriteriaSection
            
            // 9) Feedback & Privacy Section
            Section("Feedback & Privacy") {
                Button(action: {
                    showMailView = true
                }) {
                    Text("Send Feedback")
                        .foregroundColor(.white)
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
        .overlayPreferenceValue(TooltipAnchorKey.self) { allItems in
            tooltipOverlay(allItems)
        }
        
        return ZStack {
            mainForm
            
            // Invisible watchers, so your .onChange logic fires
            UnifiedValueWatchersA(simSettings: simSettings)
            UnifiedValueWatchersB(simSettings: simSettings)
            UnifiedValueWatchersC(simSettings: simSettings)
            // For monthly watchers
            // MonthlyValueWatchers(simSettings: simSettings, monthlySimSettings: monthlySimSettings)
        }
        .onAppear {
            hasAppeared = true
            
            if abs(simSettings.tiltBarValue) < 0.0000001 {
                simSettings.tiltBarValue = displayedTilt
            }
            oldNetValue = 0.0
        }
        .animation(
            hasAppeared ? Animation.easeInOut(duration: 0.3) : nil,
            value: simSettings.getFactorIntensity()
        )
        .animation(
            hasAppeared ? Animation.easeInOut(duration: 0.3) : nil,
            value: displayedTilt
        )
        // Present mail composer
        .sheet(isPresented: $showMailView) {
            if MFMailComposeViewController.canSendMail() {
                MailView(
                    recipients: ["BitcoinSimApp@gmail.com"],
                    subject: "App Feedback",
                    messageBody: ""
                )
            } else {
                Text("Mail services are not available.")
                    .foregroundColor(.white)
                    .background(Color.black)
            }
        }
    }

    // MARK: - Tilt Computation
    var displayedTilt: Double {
        if monthlySimSettings.periodUnitMonthly == .months {
            return monthlySimSettings.tiltBarValueMonthly
        } else {
            return simSettings.tiltBarValue
        }
    }

    // MARK: - Tooltip Overlay
    @ViewBuilder
    private func tooltipOverlay(_ allItems: [TooltipItem]) -> some View {
        GeometryReader { proxy in
            if let item = allItems.last {
                let bubbleWidth: CGFloat = 240
                let bubbleHeight: CGFloat = 140
                let offset: CGFloat = 4
                
                let anchorPoint = proxy[item.anchor]
                let anchorX = anchorPoint.x
                let anchorY = anchorPoint.y
                
                let spaceBelow = proxy.size.height - anchorY
                let arrowDirection: ArrowDirection = (spaceBelow > bubbleHeight + 40) ? .up : .down
                
                let proposedX = anchorX - (bubbleWidth / 2)
                let clampedX = max(10, min(proposedX, proxy.size.width - bubbleWidth - 10))
                
                let proposedY = (arrowDirection == .up)
                    ? (anchorY + offset)
                    : (anchorY - offset - bubbleHeight)
                let clampedY = max(0, min(proposedY, proxy.size.height - bubbleHeight))
                
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

    // MARK: - Nav Bar Appearance
    private func setupNavBarAppearance() {
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
        
        let blurredAppearance = UINavigationBarAppearance()
        blurredAppearance.configureWithTransparentBackground()
        blurredAppearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
        blurredAppearance.backgroundColor = UIColor(white: 0.12, alpha: 0.2)
        blurredAppearance.largeTitleTextAttributes = opaqueAppearance.largeTitleTextAttributes
        blurredAppearance.titleTextAttributes = opaqueAppearance.titleTextAttributes
        
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
}
