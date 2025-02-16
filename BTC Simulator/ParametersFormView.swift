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
                // SAME gradient angle for both orientations
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // A vertical layout controlling top spacing, etc.
                VStack(spacing: 0) {
                    // Adjust top spacing based on orientation
                    Spacer().frame(height: isLandscape ? 40 : 80)
                    
                    // Wrap the Form in a ZStack for a "dark box" effect in landscape
                    ZStack {
                        // Fill behind the form with a dark rectangle
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.12).opacity(isLandscape ? 0.9 : 1.0))
                        
                        Form {
                            Section(header: Text("SIMULATION PARAMETERS").foregroundColor(.white)) {
                                // In landscape, place all fields side-by-side
                                // In portrait, keep your original stacked layout
                                if isLandscape {
                                    // LANDSCAPE: single row
                                    HStack(alignment: .top, spacing: 24) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Iterations")
                                                .foregroundColor(.white)
                                            TextField("100", text: $inputManager.iterations)
                                                .keyboardType(.numberPad)
                                                .foregroundColor(.white)
                                                .focused($activeField, equals: .iterations)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Annual CAGR (%)")
                                                .foregroundColor(.white)
                                            TextField("30", text: $inputManager.annualCAGR)
                                                .keyboardType(.decimalPad)
                                                .onChange(of: inputManager.annualCAGR, initial: false) { _, newVal in
                                                    print("User typed new CAGR value: \(newVal)")
                                                }
                                                .foregroundColor(.white)
                                                .focused($activeField, equals: .annualCAGR)
                                        }
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Annual Volatility (%)")
                                                .foregroundColor(.white)
                                            TextField("80", text: $inputManager.annualVolatility)
                                                .keyboardType(.decimalPad)
                                                .foregroundColor(.white)
                                                .focused($activeField, equals: .annualVolatility)
                                        }
                                    }
                                } else {
                                    // PORTRAIT: original layout
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
                                            .onChange(of: inputManager.annualCAGR, initial: false) { _, newVal in
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
                            }
                            // Make sure form sections are transparent
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
                            // Also transparent background
                            .listRowBackground(Color.clear)
                        }
                        .scrollContentBackground(.hidden)
                        // Force the form's background to be clear too
                        .listStyle(GroupedListStyle())
                    }
                    // Add horizontal padding in landscape to “tighten” the box
                    .padding(.horizontal, isLandscape ? 60 : 0)
                    
                    Spacer()
                }
            }
        }
    }
}
