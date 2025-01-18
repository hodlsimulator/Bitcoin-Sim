//
//  TestBearishFactorsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 18/01/2025.
//
import SwiftUI

struct TestBearishFactorsView: View {
    @EnvironmentObject var simSettings: SimulationSettings

    var body: some View {
        VStack(spacing: 20) {
            Text("Is Reg Clampdown On? \(simSettings.useRegClampdown.description)")

            Toggle("Regulatory Clampdown", isOn: $simSettings.useRegClampdown)

            Button("Toggle All Factors") {
                simSettings.toggleAll.toggle()
            }
        }
        .padding()
    }
}
