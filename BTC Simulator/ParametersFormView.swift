//
//  ParametersFormView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

struct ParametersFormView: View {
    @FocusState var activeField: ActiveField?
    @ObservedObject var inputManager: InputManager
    let runSimulation: () -> Void
    @Binding var lastViewedWeek: Int
    @Binding var lastViewedPage: Int
    
    enum ActiveField: Hashable {
        case iterations, annualCAGR, annualVolatility
    }
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: isLandscape ? 40 : 80)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.12).opacity(isLandscape ? 0.9 : 1.0))
                        
                        Form {
                            Section(header: Text("SIMULATION PARAMETERS").foregroundColor(.white)) {
                                if isLandscape {
                                    // LANDSCAPE
                                    HStack(alignment: .top, spacing: 24) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Iterations")
                                                .foregroundColor(.white)
                                            TextField("50", text: $inputManager.iterations)
                                                .keyboardType(.numberPad)
                                                .focused($activeField, equals: .iterations)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Annual CAGR (%)")
                                                .foregroundColor(.white)
                                            TextField("30", text: $inputManager.annualCAGR)
                                                .keyboardType(.decimalPad)
                                                .onChange(of: inputManager.annualCAGR, initial: false) { _, newVal in
                                                    print("User typed new CAGR value: \(newVal)")
                                                }
                                                .focused($activeField, equals: .annualCAGR)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Annual Volatility (%)")
                                                .foregroundColor(.white)
                                            TextField("80", text: $inputManager.annualVolatility)
                                                .keyboardType(.decimalPad)
                                                .focused($activeField, equals: .annualVolatility)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    // PORTRAIT
                                    HStack {
                                        Text("Iterations")
                                            .foregroundColor(.white)
                                        TextField("50", text: $inputManager.iterations)
                                            .keyboardType(.numberPad)
                                            .focused($activeField, equals: .iterations)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                    }
                                    HStack {
                                        Text("Annual CAGR (%)")
                                            .foregroundColor(.white)
                                        TextField("30", text: $inputManager.annualCAGR)
                                            .keyboardType(.decimalPad)
                                            .onChange(of: inputManager.annualCAGR, initial: false) { _, newVal in
                                                print("User typed new CAGR value: \(newVal)")
                                            }
                                            .focused($activeField, equals: .annualCAGR)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                    }
                                    HStack {
                                        Text("Annual Volatility (%)")
                                            .foregroundColor(.white)
                                        TextField("80", text: $inputManager.annualVolatility)
                                            .keyboardType(.decimalPad)
                                            .focused($activeField, equals: .annualVolatility)
                                            .background(Color.black)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            
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
                            .listRowBackground(Color.clear)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(GroupedListStyle())
                    }
                    .padding(.horizontal, isLandscape ? 60 : 0)
                    
                    Spacer()
                }
            }
        }
    }
}
