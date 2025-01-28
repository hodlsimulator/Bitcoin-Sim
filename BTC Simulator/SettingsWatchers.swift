//
//  SettingsWatchers.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/01/2025.
//

import SwiftUI

extension View {
    /// A helper view modifier that attaches watchers for factor changes
    /// and returns the modified `View`.
    ///
    /// We’ve removed the old .onChange(...) watchers for useHalvingUnified, etc.
    /// because we now rely on fraction-based toggles (`factorEnableFrac`).
    func attachFactorWatchers(
        simSettings: SimulationSettings,
        factorIntensity: Double,
        oldFactorIntensity: Double,
        animateFactor: @escaping (_ key: String, _ isOn: Bool) -> Void,
        updateUniversalFactorIntensity: @escaping () -> Void
    ) -> some View {
        
        self
            // Whenever any factor’s numeric unified value changes, update the universal slider
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
    }
}
