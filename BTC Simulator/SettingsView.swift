//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI
import MessageUI
import Sentry

struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    
    @AppStorage("hasOnboarded") var didFinishOnboarding = false
    @AppStorage("showAdvancedSettings") private var showAdvancedSettings: Bool = false
    
    // MARK: - Tilt & Slider
    @State var oldFactorIntensity: Double = 0.5
    @State var storedDefaultTilt: Double? = nil
    
    // Confirmation & selection
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    // Toggling animations & extremes
    @State var hasAppeared = false
    @State var isExtremeToggle = false
    @State var extremeToggleApplied = false
    
    // Manual override of tilt
    @State var dragTiltOverride: Double? = nil
    
    // For toggling
    @State var disableFactorSync = false
    @State var isManualOverride: Bool = false
    
    // Factor keys
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
    
    // Used to compute net tilt changes
    @State private var oldNetValue: Double = 0.0
    
    // New state for Feedback section
    @State private var showMailView: Bool = false
    @State private var showFeedbackConsent: Bool = false

    init() {
        setupNavBarAppearance()
    }
    
    var body: some View {
        // Build your main form as before
        let mainForm = Form {
            
            // 1) The tilt bar
            overallTiltSection
            
            // 2) Factor intensity section (slider + extreme toggles)
            factorIntensitySection
            
            // 3) Toggle-all section (changed here)
            SettingsSections.toggleAllSection(
                simSettings: simSettings,
                monthlySimSettings: monthlySimSettings
            )
            
            // 4) Restore defaults (now calls monthlySimSettings too)
            Section {
                Button(action: {
                    if simSettings.periodUnit == .months {
                        monthlySimSettings.restoreDefaultsMonthly()
                        monthlySimSettings.saveToUserDefaultsMonthly()
                    } else {
                        simSettings.restoreDefaults()
                        simSettings.saveToUserDefaults()
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
                    // Recompute the tilt bar whenever a bullish factor changes
                    simSettings.recalcTiltBarValue(
                        bullishKeys: bullishKeys,
                        bearishKeys: bearishKeys
                    )
                }
            )
            .environmentObject(simSettings)
            
            // 6) Bearish factors
            BearishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: { factorName in
                    activeFactor = factorName
                },
                onFactorChange: {
                    // Recompute the tilt bar whenever a bearish factor changes
                    simSettings.recalcTiltBarValue(
                        bullishKeys: bullishKeys,
                        bearishKeys: bearishKeys
                    )
                }
            )
            .environmentObject(simSettings)
            
            // 7) Advanced settings
            AdvancedSettingsSection(showAdvancedSettings: $showAdvancedSettings)
                .environmentObject(simSettings)
            
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
                Button(action: {
                    showFeedbackConsent = true
                }) {
                    Text("Change Data Collection Consent")
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
        
        // Now place the main form + watchers in a ZStack so watchers are rendered
        return ZStack {
            
            // The main form is your principal content
            mainForm
            
            // The watchers are invisible but in the SwiftUI hierarchy, so .onChange will fire
            UnifiedValueWatchersA(simSettings: simSettings)
            UnifiedValueWatchersB(simSettings: simSettings)
            UnifiedValueWatchersC(simSettings: simSettings)
            // For monthly watchers, you might do:
            // MonthlyValueWatchers(simSettings: simSettings, monthlySimSettings: monthlySimSettings)
        }
        .onAppear {
            hasAppeared = true
            
            // If tiltBarValue is near zero, set displayed tilt to 0
            if abs(simSettings.tiltBarValue) < 0.0000001 {
                simSettings.tiltBarValue = displayedTilt
            }
            oldNetValue = 0.0
        }
        // Provide explicit "Animation.easeInOut(...)" animations.
        .animation(
            hasAppeared ? Animation.easeInOut(duration: 0.3) : nil,
            value: simSettings.getFactorIntensity()
        )
        .animation(
            hasAppeared ? Animation.easeInOut(duration: 0.3) : nil,
            value: displayedTilt
        )
        // Present the mail view sheet.
        .sheet(isPresented: $showMailView) {
            if MFMailComposeViewController.canSendMail() {
                MailView(
                    recipients: ["hodlsimulator@gmail.com"],
                    subject: "App Feedback",
                    messageBody: ""
                )
            } else {
                // Fallback if mail services are not available.
                Text("Mail services are not available.")
                    .foregroundColor(.white)
                    .background(Color.black)
            }
        }
        // Present the consent change alert using a standard iOS alert.
        .alert("Data Collection Consent", isPresented: $showFeedbackConsent) {
            Button("No", role: .cancel) {
                UserDefaults.standard.set(false, forKey: "SentryConsentGiven")
            }
            Button("Yes") {
                UserDefaults.standard.set(true, forKey: "SentryConsentGiven")
                SentrySDK.start { options in
                    options.dsn = "https://3ca36373246f91c44a0733a5d9489f52@o4508788421623808.ingest.de.sentry.io/4508788424376400"
                    options.attachViewHierarchy = false
                    options.enableMetricKit = true
                    options.enableTimeToFullDisplayTracing = true
                    options.swiftAsyncStacktraces = true
                    options.enableAppLaunchProfiling = true
                }
            }
        } message: {
            Text("We collect error logs and usage data to improve the app. Do you consent to share this data?")
                .foregroundColor(.white)
        }
    }
    // MARK: - Tilt Computation
    var displayedTilt: Double {
        simSettings.tiltBarValue
    }

    // MARK: - Tooltip Overlay
    @ViewBuilder
    private func tooltipOverlay(_ allItems: [TooltipItem]) -> some View {
        GeometryReader { proxy in
            if let item = allItems.last {
                let bubbleWidth: CGFloat = 240
                let bubbleHeight: CGFloat = 220
                let offset: CGFloat = 8
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
