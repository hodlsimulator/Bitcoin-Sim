//
//  SettingsWatchers.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension View {
    /// A helper view modifier that attaches all those `.onChange` watchers
    /// and returns the modified `View`.
    func attachFactorWatchers(
        simSettings: SimulationSettings,
        factorIntensity: Double,
        oldFactorIntensity: Double,
        animateFactor: @escaping (_ key: String, _ isOn: Bool) -> Void,
        updateUniversalFactorIntensity: @escaping () -> Void,
        syncFactorToSlider: @escaping (inout Double, Double, Double) -> Void
    ) -> some View {  // <-- Return type is now 'some View'
        
        self
            // -------------- Toggling a factor re-renders --------------
            .onChange(of: simSettings.useHalvingUnified)                { _ in }
            .onChange(of: simSettings.useInstitutionalDemandUnified)    { _ in }
            .onChange(of: simSettings.useCountryAdoptionUnified)        { _ in }
            .onChange(of: simSettings.useRegulatoryClarityUnified)      { _ in }
            .onChange(of: simSettings.useEtfApprovalUnified)            { _ in }
            .onChange(of: simSettings.useTechBreakthroughUnified)       { _ in }
            .onChange(of: simSettings.useScarcityEventsUnified)         { _ in }
            .onChange(of: simSettings.useGlobalMacroHedgeUnified)       { _ in }
            .onChange(of: simSettings.useStablecoinShiftUnified)        { _ in }
            .onChange(of: simSettings.useDemographicAdoptionUnified)    { _ in }
            .onChange(of: simSettings.useAltcoinFlightUnified)          { _ in }
            .onChange(of: simSettings.useAdoptionFactorUnified)         { _ in }
            .onChange(of: simSettings.useRegClampdownUnified)           { _ in }
            .onChange(of: simSettings.useCompetitorCoinUnified)         { _ in }
            .onChange(of: simSettings.useSecurityBreachUnified)         { _ in }
            .onChange(of: simSettings.useBubblePopUnified)              { _ in }
            .onChange(of: simSettings.useStablecoinMeltdownUnified)     { _ in }
            .onChange(of: simSettings.useBlackSwanUnified)              { _ in }
            .onChange(of: simSettings.useBearMarketUnified)             { _ in }
            .onChange(of: simSettings.useMaturingMarketUnified)         { _ in }
            .onChange(of: simSettings.useRecessionUnified)              { _ in }

            // -------------- Also watch factor *value* changes --------------
            .onChange(of: simSettings.halvingBumpUnified)               { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxDemandBoostUnified)            { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxCountryAdBoostUnified)         { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxClarityBoostUnified)           { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxEtfBoostUnified)               { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxTechBoostUnified)              { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxScarcityBoostUnified)          { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxMacroBoostUnified)             { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxStablecoinBoostUnified)        { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxDemoBoostUnified)              { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxAltcoinBoostUnified)           { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.adoptionBaseFactorUnified)        { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxClampDownUnified)              { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxCompetitorBoostUnified)        { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.breachImpactUnified)              { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxPopDropUnified)                { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxMeltdownDropUnified)           { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.blackSwanDropUnified)             { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.bearWeeklyDriftUnified)           { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxMaturingDropUnified)           { _ in updateUniversalFactorIntensity() }
            .onChange(of: simSettings.maxRecessionDropUnified)          { _ in updateUniversalFactorIntensity() }

            // -------------- Example Toggle watchers for BULLISH factors --------------
            .onChange(of: simSettings.useHalvingUnified) { isOn in
                animateFactor("Halving", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.halvingBumpUnified,
                        0.2773386887,
                        0.3823386887
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useInstitutionalDemandUnified) { isOn in
                animateFactor("InstitutionalDemand", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxDemandBoostUnified,
                        0.00105315,
                        0.00142485
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useCountryAdoptionUnified) { isOn in
                animateFactor("CountryAdoption", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxCountryAdBoostUnified,
                        0.0009882799977,
                        0.0012868959977
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useRegulatoryClarityUnified) { isOn in
                animateFactor("RegulatoryClarity", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxClarityBoostUnified,
                        0.0005979474861605167,
                        0.0008361034861605167
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useEtfApprovalUnified) { isOn in
                animateFactor("EtfApproval", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxEtfBoostUnified,
                        0.0014880183160305023,
                        0.0020880183160305023
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useTechBreakthroughUnified) { isOn in
                animateFactor("TechBreakthrough", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxTechBoostUnified,
                        0.0005015753579173088,
                        0.0007150633579173088
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useScarcityEventsUnified) { isOn in
                animateFactor("ScarcityEvents", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxScarcityBoostUnified,
                        0.00035112353681182863,
                        0.00047505153681182863
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useGlobalMacroHedgeUnified) { isOn in
                animateFactor("GlobalMacroHedge", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxMacroBoostUnified,
                        0.0002868789724932909,
                        0.0004126829724932909
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useStablecoinShiftUnified) { isOn in
                animateFactor("StablecoinShift", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxStablecoinBoostUnified,
                        0.0002704809116327763,
                        0.0003919609116327763
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useDemographicAdoptionUnified) { isOn in
                animateFactor("DemographicAdoption", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxDemoBoostUnified,
                        0.0008661432036626339,
                        0.0012578432036626339
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useAltcoinFlightUnified) { isOn in
                animateFactor("AltcoinFlight", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxAltcoinBoostUnified,
                        0.0002381864461803342,
                        0.0003222524461803342
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useAdoptionFactorUnified) { isOn in
                animateFactor("AdoptionFactor", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.adoptionBaseFactorUnified,
                        0.0013638349088897705,
                        0.0018451869088897705
                    )
                }
                updateUniversalFactorIntensity()
            }

            // -------------- Example Toggle watchers for BEARISH factors --------------
            .onChange(of: simSettings.useRegClampdownUnified) { isOn in
                animateFactor("RegClampdown", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxClampDownUnified,
                        -0.0014273392243542672,
                        -0.0008449512243542672
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useCompetitorCoinUnified) { isOn in
                animateFactor("CompetitorCoin", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxCompetitorBoostUnified,
                        -0.0011842141746411323,
                        -0.0008454221746411323
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useSecurityBreachUnified) { isOn in
                animateFactor("SecurityBreach", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.breachImpactUnified,
                        -0.0012819675168380737,
                        -0.0009009755168380737
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useBubblePopUnified) { isOn in
                animateFactor("BubblePop", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxPopDropUnified,
                        -0.002244817890762329,
                        -0.001280529890762329
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useStablecoinMeltdownUnified) { isOn in
                animateFactor("StablecoinMeltdown", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxMeltdownDropUnified,
                        -0.0009681346159477233,
                        -0.0004600706159477233
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useBlackSwanUnified) { isOn in
                animateFactor("BlackSwan", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.blackSwanDropUnified,
                        -0.478662,
                        -0.319108
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useBearMarketUnified) { isOn in
                animateFactor("BearMarket", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.bearWeeklyDriftUnified,
                        -0.0010278802752494812,
                        -0.0007278802752494812
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useMaturingMarketUnified) { isOn in
                animateFactor("MaturingMarket", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxMaturingDropUnified,
                        -0.0020343461055486196,
                        -0.0010537001055486196
                    )
                }
                updateUniversalFactorIntensity()
            }
            .onChange(of: simSettings.useRecessionUnified) { isOn in
                animateFactor("Recession", isOn)
                if isOn {
                    syncFactorToSlider(
                        &simSettings.maxRecessionDropUnified,
                        -0.0010516462467487811,
                        -0.0007494520467487811
                    )
                }
                updateUniversalFactorIntensity()
            }
    }
}
