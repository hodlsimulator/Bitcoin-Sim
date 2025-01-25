//
//  ParametersFormView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import Foundation
import SwiftUI

struct ParametersFormView: View {
    @FocusState var activeField: ActiveField?
    @ObservedObject var inputManager: InputManager
    let runSimulation: () -> Void
    @Binding var lastViewedWeek: Int
    @Binding var lastViewedPage: Int
    
    var body: some View {
        VStack {
            Spacer().frame(height: 80)
            
            Form {
                Section(header: Text("SIMULATION PARAMETERS").foregroundColor(.white)) {
                    HStack {
                        Text("Iterations")
                            .foregroundColor(.white)
                        TextField("100", text: $inputManager.iterations)
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                            .focused($activeField, equals: .iterations)
                    }
                    HStack {
                        Text("Annual CAGR (%)")
                            .foregroundColor(.white)
                        TextField("30", text: $inputManager.annualCAGR)
                            .keyboardType(.decimalPad)
                            .onChange(of: inputManager.annualCAGR) { newVal in
                                print("User typed new CAGR value: \(newVal)")
                            }
                            .foregroundColor(.white)
                            .focused($activeField, equals: .annualCAGR)
                    }
                    HStack {
                        Text("Annual Volatility (%)")
                            .foregroundColor(.white)
                        TextField("80", text: $inputManager.annualVolatility)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .focused($activeField, equals: .annualVolatility)
                    }
                }
                .listRowBackground(Color(white: 0.15))
                
                Section {
                    Button(action: {
                        activeField = nil
                        runSimulation()
                    }) {
                        Text("Run Simulation")
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    
                    Button("Reset Saved Data") {
                        UserDefaults.standard.removeObject(forKey: "lastViewedWeek")
                        UserDefaults.standard.removeObject(forKey: "lastViewedPage")
                        lastViewedWeek = 0
                        lastViewedPage = 0
                    }
                    .foregroundColor(.red)
                    .listRowBackground(Color(white: 0.15))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(white: 0.12))
            .listStyle(GroupedListStyle())
        }
    }
}
