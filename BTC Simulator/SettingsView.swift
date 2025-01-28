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
        
        // Back button (chevron only)
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
            BullishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: toggleFactor,
                // Pass the environment object’s fraction dictionary
                factorEnableFrac: $simSettings.factorEnableFrac
            )
            .environmentObject(simSettings)
            
            // 6) Bearish Factors
            BearishFactorsSection(
                activeFactor: $activeFactor,
                toggleFactor: toggleFactor,
                factorEnableFrac: $simSettings.factorEnableFrac
            )
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
        
        // Update all factor values whenever the universal slider changes
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
        
        // Return the form with watchers attached
        return mainForm
            .transaction { txn in
                txn.animation = nil
            }
            .attachFactorWatchers(
                simSettings: simSettings,
                factorIntensity: factorIntensity,
                oldFactorIntensity: oldFactorIntensity,
                animateFactor: animateFactor,
                updateUniversalFactorIntensity: updateUniversalFactorIntensity
                // Removed syncFactorToSlider here, because it's no longer in the signature
            )
    }
    
    // ------------------ Helpers ------------------
    
    func syncFactorToSlider(
        _ currentValue: inout Double,
        minVal: Double,
        maxVal: Double
    ) {
        // Force the factor’s internal value to match the universal factorIntensity proportion.
        let t = factorIntensity
        currentValue = minVal + t * (maxVal - minVal)
    }
    
    private func updateUniversalFactorIntensity(_: String) {
        // optional stub
    }
    
    // MARK: - Net Tilt Calculation
    var displayedTilt: Double {
        // if every factor fraction is 0 => return 0
        if simSettings.factorEnableFrac.values.allSatisfy({ $0 == 0.0 }) {
            return 0.0  // neutral
        }
        
        let alpha = 4.0
        let baseline = baselineNetTilt()
        let raw = computeActiveNetTilt()
        let shifted = raw - baseline
        let scaleFactor = 5.0
        return tanh(alpha * shifted * scaleFactor)
    }
    
    private func baselineNetTilt() -> Double {
        var bullVal = 0.0
        var bearVal = 0.0
        
        // Bullish (all on @ intensity=0.5)
        bullVal += bull(minVal: 0.2773386887,         maxVal: 0.3823386887,         intensity: 0.5)
        bullVal += bull(minVal: 0.00105315,           maxVal: 0.00142485,           intensity: 0.5)
        bullVal += bull(minVal: 0.0009882799977,      maxVal: 0.0012868959977,      intensity: 0.5)
        bullVal += bull(minVal: 0.0005979474861605167,maxVal: 0.0008361034861605167,intensity: 0.5)
        bullVal += bull(minVal: 0.0014880183160305023,maxVal: 0.0020880183160305023,intensity: 0.5)
        bullVal += bull(minVal: 0.0005015753579173088,maxVal: 0.0007150633579173088,intensity: 0.5)
        bullVal += bull(minVal: 0.00035112353681182863,maxVal: 0.00047505153681182863,intensity: 0.5)
        bullVal += bull(minVal: 0.0002868789724932909,maxVal: 0.0004126829724932909,intensity: 0.5)
        bullVal += bull(minVal: 0.0002704809116327763,maxVal: 0.0003919609116327763,intensity: 0.5)
        bullVal += bull(minVal: 0.0008661432036626339,maxVal: 0.0012578432036626339,intensity: 0.5)
        bullVal += bull(minVal: 0.0002381864461803342,maxVal: 0.0003222524461803342,intensity: 0.5)
        bullVal += bull(minVal: 0.0013638349088897705,maxVal: 0.0018451869088897705,intensity: 0.5)
        
        // Bearish (all on @ intensity=0.5)
        bearVal += bear(minVal: -0.0014273392243542672, maxVal: -0.0008449512243542672, intensity: 0.5)
        bearVal += bear(minVal: -0.0011842141746411323, maxVal: -0.0008454221746411323, intensity: 0.5)
        bearVal += bear(minVal: -0.0012819675168380737, maxVal: -0.0009009755168380737, intensity: 0.5)
        bearVal += bear(minVal: -0.002244817890762329,  maxVal: -0.001280529890762329,  intensity: 0.5)
        bearVal += bear(minVal: -0.0009681346159477233, maxVal: -0.0004600706159477233, intensity: 0.5)
        bearVal += bear(minVal: -0.478662,              maxVal: -0.319108,              intensity: 0.5)
        bearVal += bear(minVal: -0.0010278802752494812, maxVal: -0.0007278802752494812, intensity: 0.5)
        bearVal += bear(minVal: -0.0020343461055486196, maxVal: -0.0010537001055486196, intensity: 0.5)
        bearVal += bear(minVal: -0.0010516462467487811, maxVal: -0.0007494520467487811, intensity: 0.5)
        
        let total = bullVal + bearVal
        return total > 0 ? (bullVal - bearVal) / total : 0.0
    }
    
    private func computeActiveNetTilt() -> Double {
        var bullVal = 0.0
        var bearVal = 0.0

        // Instead of factorEnableFrac in our local view,
        // we reference simSettings.factorEnableFrac.
        func sFrac(_ key: String) -> Double {
            let raw = simSettings.factorEnableFrac[key] ?? 0.0
            if raw == 0 {
                return 0  // skip logistic, ensures 0 means truly off
            }
            // otherwise do your logistic curve
            return gentleSCurve(raw, steepness: 3.0)
        }
        
        // BULLISH
        bullVal += sFrac("Halving")
            * bull(minVal: 0.2773386887, maxVal: 0.3823386887, intensity: factorIntensity)
        bullVal += sFrac("InstitutionalDemand")
            * bull(minVal: 0.00105315, maxVal: 0.00142485, intensity: factorIntensity)
        bullVal += sFrac("CountryAdoption")
            * bull(minVal: 0.0009882799977, maxVal: 0.0012868959977, intensity: factorIntensity)
        bullVal += sFrac("RegulatoryClarity")
            * bull(minVal: 0.0005979474861605167, maxVal: 0.0008361034861605167, intensity: factorIntensity)
        bullVal += sFrac("EtfApproval")
            * bull(minVal: 0.0014880183160305023, maxVal: 0.0020880183160305023, intensity: factorIntensity)
        bullVal += sFrac("TechBreakthrough")
            * bull(minVal: 0.0005015753579173088, maxVal: 0.0007150633579173088, intensity: factorIntensity)
        bullVal += sFrac("ScarcityEvents")
            * bull(minVal: 0.00035112353681182863, maxVal: 0.00047505153681182863, intensity: factorIntensity)
        bullVal += sFrac("GlobalMacroHedge")
            * bull(minVal: 0.0002868789724932909, maxVal: 0.0004126829724932909, intensity: factorIntensity)
        bullVal += sFrac("StablecoinShift")
            * bull(minVal: 0.0002704809116327763, maxVal: 0.0003919609116327763, intensity: factorIntensity)
        bullVal += sFrac("DemographicAdoption")
            * bull(minVal: 0.0008661432036626339, maxVal: 0.0012578432036626339, intensity: factorIntensity)
        bullVal += sFrac("AltcoinFlight")
            * bull(minVal: 0.0002381864461803342, maxVal: 0.0003222524461803342, intensity: factorIntensity)
        bullVal += sFrac("AdoptionFactor")
            * bull(minVal: 0.0013638349088897705, maxVal: 0.0018451869088897705, intensity: factorIntensity)
        
        // BEARISH
        bearVal += sFrac("RegClampdown")
            * bear(minVal: -0.0014273392243542672, maxVal: -0.0008449512243542672, intensity: factorIntensity)
        bearVal += sFrac("CompetitorCoin")
            * bear(minVal: -0.0011842141746411323, maxVal: -0.0008454221746411323, intensity: factorIntensity)
        bearVal += sFrac("SecurityBreach")
            * bear(minVal: -0.0012819675168380737, maxVal: -0.0009009755168380737, intensity: factorIntensity)
        bearVal += sFrac("BubblePop")
            * bear(minVal: -0.002244817890762329, maxVal: -0.001280529890762329, intensity: factorIntensity)
        bearVal += sFrac("StablecoinMeltdown")
            * bear(minVal: -0.0009681346159477233, maxVal: -0.0004600706159477233, intensity: factorIntensity)
        bearVal += sFrac("BlackSwan")
            * bear(minVal: -0.478662, maxVal: -0.319108, intensity: factorIntensity)
        bearVal += sFrac("BearMarket")
            * bear(minVal: -0.0010278802752494812, maxVal: -0.0007278802752494812, intensity: factorIntensity)
        bearVal += sFrac("MaturingMarket")
            * bear(minVal: -0.0020343461055486196, maxVal: -0.0010537001055486196, intensity: factorIntensity)
        bearVal += sFrac("Recession")
            * bear(minVal: -0.0010516462467487811, maxVal: -0.0007494520467487811, intensity: factorIntensity)
        
        // Let tilt go negative if total < 0
        let total = bullVal + bearVal
        if total == 0 {
            return 0.0
        }
        return (bullVal - bearVal) / total
    }
    
    private func gentleSCurve(_ x: Double, steepness: Double = 3.0) -> Double {
        return 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
    }

    // Basic bull/bear interpolation
    private func bull(minVal: Double, maxVal: Double, intensity: Double) -> Double {
        minVal + intensity * (maxVal - minVal)
    }
    private func bear(minVal: Double, maxVal: Double, intensity: Double) -> Double {
        abs(minVal + intensity * (maxVal - minVal))
    }
    
    /// Inverted S-curve transforms 0..1 so that transitions away from 0/1 are gentler.
    private func invertedSCurve(_ x: Double, steepness: Double = 6.0) -> Double {
        let logistic = 1.0 / (1.0 + exp(-steepness * (x - 0.5)))
        return 1.0 - logistic
    }
}
