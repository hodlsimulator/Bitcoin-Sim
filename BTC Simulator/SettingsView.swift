//
//  SettingsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    @AppStorage("hasOnboarded") var didFinishOnboarding = false
    
    // Collapsed/expanded state for the Advanced disclosure
    @AppStorage("showAdvancedSettings") private var showAdvancedSettings: Bool = false
    
    // Factor Intensity in [0...1], default to 0.5
    @AppStorage("factorIntensity") var factorIntensity: Double = 0.5
    // Track old slider value, for shift-based math
    @State var oldFactorIntensity: Double = 0.5
    
    @State var showResetCriteriaConfirmation = false
    @State var activeFactor: String? = nil
    
    @State private var halvingEnableFrac: Double = 1.0
    
    // MARK: - NEW: Factor "enable" fractions for each factor
    // These start at 1.0 if you want them “on” by default.
    // If a factor is toggled off at the start, set 0.0.
    @State var factorEnableFrac: [String: Double] = [
        "Halving": 1.0,
        "InstitutionalDemand": 1.0,
        "CountryAdoption": 1.0,
        "RegulatoryClarity": 1.0,
        "EtfApproval": 1.0,
        "TechBreakthrough": 1.0,
        "ScarcityEvents": 1.0,
        "GlobalMacroHedge": 1.0,
        "StablecoinShift": 1.0,
        "DemographicAdoption": 1.0,
        "AltcoinFlight": 1.0,
        "AdoptionFactor": 1.0,
        "RegClampdown": 1.0,
        "CompetitorCoin": 1.0,
        "SecurityBreach": 1.0,
        "BubblePop": 1.0,
        "StablecoinMeltdown": 1.0,
        "BlackSwan": 1.0,
        "BearMarket": 1.0,
        "MaturingMarket": 1.0,
        "Recession": 1.0,
    ]
    
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
        // 1) Build the main Form as a local constant:
        let mainForm = Form {
            
            // 1) Tilt Bar
            overallTiltSection
            
            // 2) Universal Factor Intensity
            factorIntensitySection
            
            // 3) Toggle All Factors
            toggleAllSection
            
            // 4) "Restore Defaults"
            restoreDefaultsSection
            
            // 5) Bullish Factors
            BullishFactorsSection(activeFactor: $activeFactor, toggleFactor: toggleFactor)
                .environmentObject(simSettings)
            
            // 6) Bearish Factors
            BearishFactorsSection(activeFactor: $activeFactor, toggleFactor: toggleFactor)
                .environmentObject(simSettings)
            
            // 7) Advanced Disclosure
            AdvancedSettingsSection(showAdvancedSettings: $showAdvancedSettings)
            
            // 8) About
            aboutSection
            
            // 9) Reset All
            resetCriteriaSection
            
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(white: 0.12))
        .environment(\.colorScheme, .dark)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        
        // When the universal slider changes, shift all toggled-on factors accordingly
        .onChange(of: factorIntensity) { newVal in
            let delta = newVal - oldFactorIntensity
            oldFactorIntensity = newVal
            shiftAllFactors(by: delta)
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
        
        // 2) Return that Form with watchers attached:
        return mainForm.attachFactorWatchers(
            simSettings: simSettings,
            factorIntensity: factorIntensity,
            oldFactorIntensity: oldFactorIntensity,
            animateFactor: animateFactor,
            updateUniversalFactorIntensity: updateUniversalFactorIntensity,
            syncFactorToSlider: syncFactorToSlider
        )
    }
    
    // -------------- Helper Function --------------
    private func syncFactorToSlider(
        currentValue: inout Double,
        minVal: Double,
        maxVal: Double
    ) {
        // E.g., if universal slider is 0.3, we set currentValue to
        // minVal + 0.3*(maxVal - minVal).
        // This ensures the factor’s real value matches the universal slider’s proportion.
        
        let t = factorIntensity
        currentValue = minVal + t * (maxVal - minVal)
    }
    
    // Compute "Raw" Tilt from toggles
    private func computeNetTilt() -> Double {
        computeNetTilt(atIntensity: factorIntensity)
    }
    
    // If you want to see net tilt for a hypothetical intensity
    private func computeNetTilt(atIntensity intensity: Double) -> Double {
        func bull(minVal: Double, maxVal: Double) -> Double {
            minVal + intensity * (maxVal - minVal)
        }
        func bear(minVal: Double, maxVal: Double) -> Double {
            abs(minVal + intensity * (maxVal - minVal))
        }
        
        var bullVal = 0.0
        var bearVal = 0.0
        
        // BULLISH
        if simSettings.useHalvingUnified {
            bullVal += bull(minVal: 0.2773386887, maxVal: 0.3823386887)
        }
        if simSettings.useInstitutionalDemandUnified {
            bullVal += bull(minVal: 0.00105315, maxVal: 0.00142485)
        }
        if simSettings.useCountryAdoptionUnified {
            bullVal += bull(minVal: 0.0009882799977, maxVal: 0.0012868959977)
        }
        if simSettings.useRegulatoryClarityUnified {
            bullVal += bull(minVal: 0.0005979474861605167, maxVal: 0.0008361034861605167)
        }
        if simSettings.useEtfApprovalUnified {
            bullVal += bull(minVal: 0.0014880183160305023, maxVal: 0.0020880183160305023)
        }
        if simSettings.useTechBreakthroughUnified {
            bullVal += bull(minVal: 0.0005015753579173088, maxVal: 0.0007150633579173088)
        }
        if simSettings.useScarcityEventsUnified {
            bullVal += bull(minVal: 0.00035112353681182863, maxVal: 0.00047505153681182863)
        }
        if simSettings.useGlobalMacroHedgeUnified {
            bullVal += bull(minVal: 0.0002868789724932909, maxVal: 0.0004126829724932909)
        }
        if simSettings.useStablecoinShiftUnified {
            bullVal += bull(minVal: 0.0002704809116327763, maxVal: 0.0003919609116327763)
        }
        if simSettings.useDemographicAdoptionUnified {
            bullVal += bull(minVal: 0.0008661432036626339, maxVal: 0.0012578432036626339)
        }
        if simSettings.useAltcoinFlightUnified {
            bullVal += bull(minVal: 0.0002381864461803342, maxVal: 0.0003222524461803342)
        }
        if simSettings.useAdoptionFactorUnified {
            bullVal += bull(minVal: 0.0013638349088897705, maxVal: 0.0018451869088897705)
        }
        
        // BEARISH
        if simSettings.useRegClampdownUnified {
            bearVal += bear(minVal: -0.0014273392243542672, maxVal: -0.0008449512243542672)
        }
        if simSettings.useCompetitorCoinUnified {
            bearVal += bear(minVal: -0.0011842141746411323, maxVal: -0.0008454221746411323)
        }
        if simSettings.useSecurityBreachUnified {
            bearVal += bear(minVal: -0.0012819675168380737, maxVal: -0.0009009755168380737)
        }
        if simSettings.useBubblePopUnified {
            bearVal += bear(minVal: -0.002244817890762329, maxVal: -0.001280529890762329)
        }
        if simSettings.useStablecoinMeltdownUnified {
            bearVal += bear(minVal: -0.0009681346159477233, maxVal: -0.0004600706159477233)
        }
        if simSettings.useBlackSwanUnified {
            bearVal += bear(minVal: -0.478662, maxVal: -0.319108)
        }
        if simSettings.useBearMarketUnified {
            bearVal += bear(minVal: -0.0010278802752494812, maxVal: -0.0007278802752494812)
        }
        if simSettings.useMaturingMarketUnified {
            bearVal += bear(minVal: -0.0020343461055486196, maxVal: -0.0010537001055486196)
        }
        if simSettings.useRecessionUnified {
            bearVal += bear(minVal: -0.0010516462467487811, maxVal: -0.0007494520467487811)
        }
        
        let total = bullVal + bearVal
        guard total > 0 else { return 0.0 }
        
        return (bullVal - bearVal) / total
    }
    
    var displayedTilt: Double {
        let alpha = 4.0
        let baseline = baselineNetTilt()           // All factors ON at 0.5
        let raw = computeActiveNetTilt()           // Actually-toggled factors at real intensities
        let shifted = raw - baseline               // Deviation from baseline
        let scaleFactor = 5.0
        
        return tanh(alpha * shifted * scaleFactor)
    }

    // 1) Baseline always sums *all* factors, ignoring toggles, at 0.5 intensity.
    private func baselineNetTilt() -> Double {
        var bullVal = 0.0
        var bearVal = 0.0
        
        // MARK: - Bullish Factors (All On, Intensity=0.5)
        bullVal += bull(minVal: 0.2773386887,         maxVal: 0.3823386887,         intensity: 0.5) // Halving
        bullVal += bull(minVal: 0.00105315,           maxVal: 0.00142485,           intensity: 0.5) // Institutional Demand
        bullVal += bull(minVal: 0.0009882799977,      maxVal: 0.0012868959977,      intensity: 0.5) // Country Adoption
        bullVal += bull(minVal: 0.0005979474861605167,maxVal: 0.0008361034861605167,intensity: 0.5) // Regulatory Clarity
        bullVal += bull(minVal: 0.0014880183160305023,maxVal: 0.0020880183160305023,intensity: 0.5) // ETF Approval
        bullVal += bull(minVal: 0.0005015753579173088,maxVal: 0.0007150633579173088,intensity: 0.5) // Tech Breakthrough
        bullVal += bull(minVal: 0.00035112353681182863,maxVal: 0.00047505153681182863,intensity: 0.5) // Scarcity Events
        bullVal += bull(minVal: 0.0002868789724932909,maxVal: 0.0004126829724932909,intensity: 0.5) // Global Macro Hedge
        bullVal += bull(minVal: 0.0002704809116327763,maxVal: 0.0003919609116327763,intensity: 0.5) // Stablecoin Shift
        bullVal += bull(minVal: 0.0008661432036626339,maxVal: 0.0012578432036626339,intensity: 0.5) // Demographic Adoption
        bullVal += bull(minVal: 0.0002381864461803342,maxVal: 0.0003222524461803342,intensity: 0.5) // Altcoin Flight
        bullVal += bull(minVal: 0.0013638349088897705,maxVal: 0.0018451869088897705,intensity: 0.5) // Adoption Factor
        
        // MARK: - Bearish Factors (All On, Intensity=0.5)
        bearVal += bear(minVal: -0.0014273392243542672, maxVal: -0.0008449512243542672, intensity: 0.5) // Regulatory Clampdown
        bearVal += bear(minVal: -0.0011842141746411323, maxVal: -0.0008454221746411323, intensity: 0.5) // Competitor Coin
        bearVal += bear(minVal: -0.0012819675168380737, maxVal: -0.0009009755168380737, intensity: 0.5) // Security Breach
        bearVal += bear(minVal: -0.002244817890762329,  maxVal: -0.001280529890762329,  intensity: 0.5) // Bubble Pop
        bearVal += bear(minVal: -0.0009681346159477233, maxVal: -0.0004600706159477233, intensity: 0.5) // Stablecoin Meltdown
        bearVal += bear(minVal: -0.478662,              maxVal: -0.319108,              intensity: 0.5) // Black Swan
        bearVal += bear(minVal: -0.0010278802752494812, maxVal: -0.0007278802752494812, intensity: 0.5) // Bear Market
        bearVal += bear(minVal: -0.0020343461055486196, maxVal: -0.0010537001055486196, intensity: 0.5) // Maturing Market
        bearVal += bear(minVal: -0.0010516462467487811, maxVal: -0.0007494520467487811, intensity: 0.5) // Recession
        
        let total = bullVal + bearVal
        return total > 0 ? (bullVal - bearVal) / total : 0.0
    }

    // 2) Actual net tilt from toggled-on factors & their real intensities
    private func computeActiveNetTilt() -> Double {
        var bullVal = 0.0
        var bearVal = 0.0
        
        // Helper to get fraction for each factor
        // and run it through the inverted S-curve to avoid linear scaling
        func sFrac(_ key: String) -> Double {
            let rawFraction = factorEnableFrac[key] ?? 0.0
            return invertedSCurve(rawFraction)  // Non-linear transformation
        }

        // BULLISH
        if simSettings.useHalvingUnified {
            bullVal += sFrac("Halving") * bull(
                minVal: 0.2773386887,
                maxVal: 0.3823386887,
                intensity: factorIntensity
            )
        }
        if simSettings.useInstitutionalDemandUnified {
            bullVal += sFrac("InstitutionalDemand") * bull(
                minVal: 0.00105315,
                maxVal: 0.00142485,
                intensity: factorIntensity
            )
        }
        if simSettings.useCountryAdoptionUnified {
            bullVal += sFrac("CountryAdoption") * bull(
                minVal: 0.0009882799977,
                maxVal: 0.0012868959977,
                intensity: factorIntensity
            )
        }
        if simSettings.useRegulatoryClarityUnified {
            bullVal += sFrac("RegulatoryClarity") * bull(
                minVal: 0.0005979474861605167,
                maxVal: 0.0008361034861605167,
                intensity: factorIntensity
            )
        }
        if simSettings.useEtfApprovalUnified {
            bullVal += sFrac("EtfApproval") * bull(
                minVal: 0.0014880183160305023,
                maxVal: 0.0020880183160305023,
                intensity: factorIntensity
            )
        }
        if simSettings.useTechBreakthroughUnified {
            bullVal += sFrac("TechBreakthrough") * bull(
                minVal: 0.0005015753579173088,
                maxVal: 0.0007150633579173088,
                intensity: factorIntensity
            )
        }
        if simSettings.useScarcityEventsUnified {
            bullVal += sFrac("ScarcityEvents") * bull(
                minVal: 0.00035112353681182863,
                maxVal: 0.00047505153681182863,
                intensity: factorIntensity
            )
        }
        if simSettings.useGlobalMacroHedgeUnified {
            bullVal += sFrac("GlobalMacroHedge") * bull(
                minVal: 0.0002868789724932909,
                maxVal: 0.0004126829724932909,
                intensity: factorIntensity
            )
        }
        if simSettings.useStablecoinShiftUnified {
            bullVal += sFrac("StablecoinShift") * bull(
                minVal: 0.0002704809116327763,
                maxVal: 0.0003919609116327763,
                intensity: factorIntensity
            )
        }
        if simSettings.useDemographicAdoptionUnified {
            bullVal += sFrac("DemographicAdoption") * bull(
                minVal: 0.0008661432036626339,
                maxVal: 0.0012578432036626339,
                intensity: factorIntensity
            )
        }
        if simSettings.useAltcoinFlightUnified {
            bullVal += sFrac("AltcoinFlight") * bull(
                minVal: 0.0002381864461803342,
                maxVal: 0.0003222524461803342,
                intensity: factorIntensity
            )
        }
        if simSettings.useAdoptionFactorUnified {
            bullVal += sFrac("AdoptionFactor") * bull(
                minVal: 0.0013638349088897705,
                maxVal: 0.0018451869088897705,
                intensity: factorIntensity
            )
        }
        
        // BEARISH
        if simSettings.useRegClampdownUnified {
            bearVal += sFrac("RegClampdown") * bear(
                minVal: -0.0014273392243542672,
                maxVal: -0.0008449512243542672,
                intensity: factorIntensity
            )
        }
        if simSettings.useCompetitorCoinUnified {
            bearVal += sFrac("CompetitorCoin") * bear(
                minVal: -0.0011842141746411323,
                maxVal: -0.0008454221746411323,
                intensity: factorIntensity
            )
        }
        if simSettings.useSecurityBreachUnified {
            bearVal += sFrac("SecurityBreach") * bear(
                minVal: -0.0012819675168380737,
                maxVal: -0.0009009755168380737,
                intensity: factorIntensity
            )
        }
        if simSettings.useBubblePopUnified {
            bearVal += sFrac("BubblePop") * bear(
                minVal: -0.002244817890762329,
                maxVal: -0.001280529890762329,
                intensity: factorIntensity
            )
        }
        if simSettings.useStablecoinMeltdownUnified {
            bearVal += sFrac("StablecoinMeltdown") * bear(
                minVal: -0.0009681346159477233,
                maxVal: -0.0004600706159477233,
                intensity: factorIntensity
            )
        }
        if simSettings.useBlackSwanUnified {
            bearVal += sFrac("BlackSwan") * bear(
                minVal: -0.478662,
                maxVal: -0.319108,
                intensity: factorIntensity
            )
        }
        if simSettings.useBearMarketUnified {
            bearVal += sFrac("BearMarket") * bear(
                minVal: -0.0010278802752494812,
                maxVal: -0.0007278802752494812,
                intensity: factorIntensity
            )
        }
        if simSettings.useMaturingMarketUnified {
            bearVal += sFrac("MaturingMarket") * bear(
                minVal: -0.0020343461055486196,
                maxVal: -0.0010537001055486196,
                intensity: factorIntensity
            )
        }
        if simSettings.useRecessionUnified {
            bearVal += sFrac("Recession") * bear(
                minVal: -0.0010516462467487811,
                maxVal: -0.0007494520467487811,
                intensity: factorIntensity
            )
        }
        
        let total = bullVal + bearVal
        return total > 0 ? (bullVal - bearVal) / total : 0.0
    }

    // Helpers for bull/bear
    private func bull(minVal: Double, maxVal: Double, intensity: Double) -> Double {
        minVal + intensity * (maxVal - minVal)
    }
    private func bear(minVal: Double, maxVal: Double, intensity: Double) -> Double {
        abs(minVal + intensity * (maxVal - minVal))
    }
    
    /// Maps 0...1 through an inverted S-curve.
    /// Adjust 'steepness' to control how sharply it transitions near 0.5.
    private func invertedSCurve(_ x: Double, steepness: Double = 6.0) -> Double {
        // Basic logistic in 0..1, but 'inverted' by subtracting from 1
        let logistic = 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
        return 1.0 - logistic
    }
}
