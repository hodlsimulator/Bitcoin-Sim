//
//  ParametersFormView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI
import UIKit  // Needed for orientation

struct ParametersFormView: View {
    @FocusState private var activeField: ActiveField?
    
    @ObservedObject var inputManager: InputManager
    let runSimulation: () -> Void
    @Binding var lastViewedWeek: Int
    @Binding var lastViewedPage: Int
    
    enum ActiveField: Hashable {
        case iterations
        case annualCAGR
        case annualVolatility
    }

    var body: some View {
        VStack {
            Spacer().frame(height: 80)
            
            Form {
                Section(header: Text("SIMULATION PARAMETERS").foregroundColor(.white)) {
                    
                    // Iterations
                    HStack {
                        Text("Iterations")
                            .foregroundColor(.white)
                        
                        TextField("100", text: $inputManager.iterations)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                            .submitLabel(.next)
                            .focused($activeField, equals: .iterations)
                            .onSubmit {
                                activeField = .annualCAGR
                            }
                    }
                    
                    // Annual CAGR
                    HStack {
                        Text("Annual CAGR (%)")
                            .foregroundColor(.white)
                        
                        TextField("30", text: $inputManager.annualCAGR)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                            .submitLabel(.next)
                            .focused($activeField, equals: .annualCAGR)
                            .onSubmit {
                                activeField = .annualVolatility
                            }
                            .onChange(of: inputManager.annualCAGR, initial: false) { _, newVal in
                                // Real-time logging or updating
                                print("New CAGR value: \(newVal)")
                            }
                    }
                    
                    // Annual Volatility
                    HStack {
                        Text("Annual Volatility (%)")
                            .foregroundColor(.white)
                        
                        TextField("80", text: $inputManager.annualVolatility)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .foregroundColor(.white)
                            .submitLabel(.done)
                            .focused($activeField, equals: .annualVolatility)
                            .onSubmit {
                                activeField = nil  // Dismiss keyboard
                            }
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
        .onAppear {
            // Lock orientation to portrait
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        .onDisappear {
            // Allow all orientations again
            AppDelegate.orientationLock = .all
            UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
        }
    }
}
