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
                // Subtler gradient with a faint hint of gray
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(white: 0.12),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: isLandscape ? 40 : 80)
                    
                    ZStack {
                        // Add a semi-transparent fill
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.15).opacity(isLandscape ? 0.95 : 1.0))
                            .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                        
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
                                                .padding(6)
                                                .background(Color(white: 0.25))
                                                .cornerRadius(6)
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
                                                .padding(6)
                                                .background(Color(white: 0.25))
                                                .cornerRadius(6)
                                                .foregroundColor(.white)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Annual Volatility (%)")
                                                .foregroundColor(.white)
                                            TextField("80", text: $inputManager.annualVolatility)
                                                .keyboardType(.decimalPad)
                                                .focused($activeField, equals: .annualVolatility)
                                                .padding(6)
                                                .background(Color(white: 0.25))
                                                .cornerRadius(6)
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
                                            .padding(6)
                                            .background(Color(white: 0.25))
                                            .cornerRadius(6)
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
                                            .padding(6)
                                            .background(Color(white: 0.25))
                                            .cornerRadius(6)
                                            .foregroundColor(.white)
                                    }
                                    HStack {
                                        Text("Annual Volatility (%)")
                                            .foregroundColor(.white)
                                        TextField("80", text: $inputManager.annualVolatility)
                                            .keyboardType(.decimalPad)
                                            .focused($activeField, equals: .annualVolatility)
                                            .padding(6)
                                            .background(Color(white: 0.25))
                                            .cornerRadius(6)
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
                                .listRowBackground(Color.orange)
                                
                                Button("Reset Saved Data") {
                                    UserDefaults.standard.removeObject(forKey: "lastViewedWeek")
                                    UserDefaults.standard.removeObject(forKey: "lastViewedPage")
                                    lastViewedWeek = 0
                                    lastViewedPage = 0
                                }
                                .foregroundColor(.red)
                                .listRowBackground(Color(white: 0.2))
                            }
                            .listRowBackground(Color.clear)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(GroupedListStyle())
                    }
                    .padding(.horizontal, isLandscape ? 60 : 20)
                    
                    Spacer()
                }
            }
        }
    }
}
