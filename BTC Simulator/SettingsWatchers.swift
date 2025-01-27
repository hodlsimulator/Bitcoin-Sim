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
    ) -> some View {
        
        self
            // These empty watchers just force re-render but do nothing
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

            // Watch real factor changes -> update universal intensity
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

            // MARK: - BULLISH Factor Toggles
            .onChange(of: simSettings.useHalvingUnified) { isOn in
                // 1) Animate the fraction first
                animateFactor("Halving", isOn)

                if isOn {
                    // 2) Once fraction's 0.6s animation finishes, snap factor
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.halvingBumpUnified,
                                0.2773386887,
                                0.3823386887
                            )
                        }
                        // 3) Recompute universal intensity
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useInstitutionalDemandUnified) { isOn in
                animateFactor("InstitutionalDemand", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxDemandBoostUnified,
                                0.00105315,
                                0.00142485
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useCountryAdoptionUnified) { isOn in
                animateFactor("CountryAdoption", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxCountryAdBoostUnified,
                                0.0009882799977,
                                0.0012868959977
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useRegulatoryClarityUnified) { isOn in
                animateFactor("RegulatoryClarity", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxClarityBoostUnified,
                                0.0005979474861605167,
                                0.0008361034861605167
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useEtfApprovalUnified) { isOn in
                animateFactor("EtfApproval", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxEtfBoostUnified,
                                0.0014880183160305023,
                                0.0020880183160305023
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useTechBreakthroughUnified) { isOn in
                animateFactor("TechBreakthrough", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxTechBoostUnified,
                                0.0005015753579173088,
                                0.0007150633579173088
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useScarcityEventsUnified) { isOn in
                animateFactor("ScarcityEvents", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxScarcityBoostUnified,
                                0.00035112353681182863,
                                0.00047505153681182863
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useGlobalMacroHedgeUnified) { isOn in
                animateFactor("GlobalMacroHedge", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxMacroBoostUnified,
                                0.0002868789724932909,
                                0.0004126829724932909
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useStablecoinShiftUnified) { isOn in
                animateFactor("StablecoinShift", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxStablecoinBoostUnified,
                                0.0002704809116327763,
                                0.0003919609116327763
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useDemographicAdoptionUnified) { isOn in
                animateFactor("DemographicAdoption", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxDemoBoostUnified,
                                0.0008661432036626339,
                                0.0012578432036626339
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useAltcoinFlightUnified) { isOn in
                animateFactor("AltcoinFlight", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxAltcoinBoostUnified,
                                0.0002381864461803342,
                                0.0003222524461803342
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useAdoptionFactorUnified) { isOn in
                animateFactor("AdoptionFactor", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.adoptionBaseFactorUnified,
                                0.0013638349088897705,
                                0.0018451869088897705
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }

            // MARK: - BEARISH Factor Toggles
            .onChange(of: simSettings.useRegClampdownUnified) { isOn in
                animateFactor("RegClampdown", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxClampDownUnified,
                                -0.0014273392243542672,
                                -0.0008449512243542672
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useCompetitorCoinUnified) { isOn in
                animateFactor("CompetitorCoin", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxCompetitorBoostUnified,
                                -0.0011842141746411323,
                                -0.0008454221746411323
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useSecurityBreachUnified) { isOn in
                animateFactor("SecurityBreach", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.breachImpactUnified,
                                -0.0012819675168380737,
                                -0.0009009755168380737
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useBubblePopUnified) { isOn in
                animateFactor("BubblePop", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxPopDropUnified,
                                -0.002244817890762329,
                                -0.001280529890762329
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useStablecoinMeltdownUnified) { isOn in
                animateFactor("StablecoinMeltdown", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxMeltdownDropUnified,
                                -0.0009681346159477233,
                                -0.0004600706159477233
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useBlackSwanUnified) { isOn in
                animateFactor("BlackSwan", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.blackSwanDropUnified,
                                -0.478662,
                                -0.319108
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useBearMarketUnified) { isOn in
                animateFactor("BearMarket", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.bearWeeklyDriftUnified,
                                -0.0010278802752494812,
                                -0.0007278802752494812
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useMaturingMarketUnified) { isOn in
                animateFactor("MaturingMarket", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxMaturingDropUnified,
                                -0.0020343461055486196,
                                -0.0010537001055486196
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
            .onChange(of: simSettings.useRecessionUnified) { isOn in
                animateFactor("Recession", isOn)
                if isOn {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) {
                            syncFactorToSlider(
                                &simSettings.maxRecessionDropUnified,
                                -0.0010516462467487811,
                                -0.0007494520467487811
                            )
                        }
                        updateUniversalFactorIntensity()
                    }
                } else {
                    updateUniversalFactorIntensity()
                }
            }
    }
}
