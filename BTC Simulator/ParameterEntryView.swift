//
//  ParameterEntryView.swift
//  BTCMonteCarlo
//
//  Created by . . on 11/02/2025.
//

import SwiftUI
import UIKit // Needed to force device orientation programmatically

struct ParameterEntryView: View {
    enum ActiveField {
        case iterations, annualCAGR, annualVolatility, standardDeviation
    }
    
    @FocusState private var activeField: ActiveField?
    
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @ObservedObject var coordinator: SimulationCoordinator
    
    @Binding var isKeyboardVisible: Bool
    
    // Local copies
    @State private var localIterations: String = "100"
    @State private var localAnnualCAGR: String = "30"
    @State private var localAnnualVolatility: String = "80"
    @State private var localStandardDev: String = "150"
    
    // Ephemeral fields
    @State private var ephemeralIterations: String = ""
    @State private var ephemeralAnnualCAGR: String = ""
    @State private var ephemeralAnnualVolatility: String = ""
    @State private var ephemeralStandardDev: String = ""
    
    @AppStorage("advancedSettingsUnlocked") private var advancedSettingsUnlocked: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                activeField = nil
            }
            
            VStack(spacing: 30) {
                Spacer().frame(height: 60)
                
                Text("HODL Simulator")
                    .font(.custom("AvenirNext-Heavy", size: 36))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.6), radius: 6, x: 0, y: 0)
                
                Text("Set your simulation parameters")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                VStack(spacing: 20) {
                    // Row 1 (Iterations & CAGR)
                    HStack(spacing: 24) {
                        // Iterations
                        VStack(spacing: 4) {
                            Text("Iterations")
                                .foregroundColor(.white)
                            
                            TextField("100", text: $ephemeralIterations)
                                .keyboardType(.numberPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .iterations)
                                .onTapGesture {
                                    ephemeralIterations = localIterations
                                }
                                .onSubmit {
                                    localIterations = ephemeralIterations
                                    inputManager.iterations = ephemeralIterations
                                }
                        }
                        
                        // CAGR
                        VStack(spacing: 4) {
                            Text("CAGR (%)")
                                .foregroundColor(.white)
                            
                            TextField("30", text: $ephemeralAnnualCAGR)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .annualCAGR)
                                .onTapGesture {
                                    ephemeralAnnualCAGR = localAnnualCAGR
                                }
                                .onSubmit {
                                    localAnnualCAGR = ephemeralAnnualCAGR
                                    inputManager.annualCAGR = ephemeralAnnualCAGR
                                }
                        }
                    }
                    
                    // Row 2 (Vol & StdDev)
                    HStack(spacing: 24) {
                        // Vol
                        VStack(spacing: 4) {
                            Text("Vol (%)")
                                .foregroundColor(.white)
                            
                            TextField("80", text: $ephemeralAnnualVolatility)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .annualVolatility)
                                .onTapGesture {
                                    ephemeralAnnualVolatility = localAnnualVolatility
                                }
                                .onSubmit {
                                    localAnnualVolatility = ephemeralAnnualVolatility
                                    inputManager.annualVolatility = ephemeralAnnualVolatility
                                }
                        }
                        
                        // StdDev
                        VStack(spacing: 4) {
                            Text("StdDev")
                                .foregroundColor(.white)
                            
                            TextField("150", text: $ephemeralStandardDev)
                                .keyboardType(.decimalPad)
                                .padding(8)
                                .frame(width: 80)
                                .background(Color.white)
                                .cornerRadius(6)
                                .foregroundColor(.black)
                                .focused($activeField, equals: .standardDeviation)
                                .onTapGesture {
                                    ephemeralStandardDev = localStandardDev
                                }
                                .onSubmit {
                                    localStandardDev = ephemeralStandardDev
                                    inputManager.standardDeviation = ephemeralStandardDev
                                }
                        }
                    }
                    
                    // Row 3 (Toggles)
                    HStack(spacing: 32) {
                        Toggle("Charts", isOn: $inputManager.generateGraphs)
                            .toggleStyle(CheckboxToggleStyle())
                            .foregroundColor(.white)
                        
                        Toggle("Lock Seed", isOn: lockedRandomSeedBinding)
                            .toggleStyle(CheckboxToggleStyle())
                            .foregroundColor(.white)
                            .disabled(!advancedSettingsUnlocked)
                            .opacity(advancedSettingsUnlocked ? 1.0 : 0.5)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1).opacity(0.8))
                )
                .padding(.horizontal, 30)
                
                if coordinator.isLoading || coordinator.isChartBuilding {
                    Text(" ") // Placeholder
                        .font(.callout)
                        .foregroundColor(.clear)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .cornerRadius(8)
                        .padding(.top, 6)
                    
                    Spacer()
                } else {
                    Button {
                        commitAllFields()
                        activeField = nil
                        coordinator.isLoading = true
                        coordinator.isChartBuilding = false
                        
                        coordinator.runSimulation(
                            generateGraphs: inputManager.generateGraphs,
                            lockRandomSeed: lockedRandomSeedBinding.wrappedValue
                        )
                    } label: {
                        Text("RUN SIMULATION")
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                    .padding(.top, 6)
                    
                    Spacer()
                }
            }
        }
        // Update keyboard visibility
        .onChange(of: activeField) { newActive in
            isKeyboardVisible = (newActive != nil)
        }
        .onAppear {
            // Lock orientation to portrait
            AppDelegate.orientationLock = .portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            
            // Pre-fill from persisted/default values
            localIterations = inputManager.iterations
            localAnnualCAGR = inputManager.annualCAGR
            localAnnualVolatility = inputManager.annualVolatility
            localStandardDev = inputManager.standardDeviation
            
            ephemeralIterations = localIterations
            ephemeralAnnualCAGR = localAnnualCAGR
            ephemeralAnnualVolatility = localAnnualVolatility
            ephemeralStandardDev = localStandardDev
        }
        .onDisappear {
            // Allow all orientations again
            AppDelegate.orientationLock = .all
            UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
        }
    }
    
    private func commitAllFields() {
        localIterations = ephemeralIterations.isEmpty ? localIterations : ephemeralIterations
        localAnnualCAGR = ephemeralAnnualCAGR.isEmpty ? localAnnualCAGR : ephemeralAnnualCAGR
        localAnnualVolatility = ephemeralAnnualVolatility.isEmpty ? localAnnualVolatility : ephemeralAnnualVolatility
        localStandardDev = ephemeralStandardDev.isEmpty ? localStandardDev : ephemeralStandardDev
        
        inputManager.iterations = localIterations
        inputManager.annualCAGR = localAnnualCAGR
        inputManager.annualVolatility = localAnnualVolatility
        inputManager.standardDeviation = localStandardDev
    }
    
    // Computed Binding for "Lock Seed"
    private var lockedRandomSeedBinding: Binding<Bool> {
        Binding(
            get: {
                coordinator.useMonthly
                    ? monthlySimSettings.lockedRandomSeedMonthly
                    : simSettings.lockedRandomSeed
            },
            set: { newVal in
                if coordinator.useMonthly {
                    monthlySimSettings.lockedRandomSeedMonthly = newVal
                    if newVal {
                        let newSeed = UInt64.random(in: 0 ..< UInt64.max)
                        monthlySimSettings.seedValueMonthly = newSeed
                        monthlySimSettings.useRandomSeedMonthly = false
                    } else {
                        monthlySimSettings.seedValueMonthly = 0
                        monthlySimSettings.useRandomSeedMonthly = true
                    }
                } else {
                    simSettings.lockedRandomSeed = newVal
                    if newVal {
                        let newSeed = UInt64.random(in: 0 ..< UInt64.max)
                        simSettings.seedValue = newSeed
                        simSettings.useRandomSeed = false
                    } else {
                        simSettings.seedValue = 0
                        simSettings.useRandomSeed = true
                    }
                }
            }
        )
    }
}
