//
//  ParameterEntryView.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//


import SwiftUI

struct ParameterEntryView: View {
    // MARK: - Focus
    enum ActiveField {
        case iterations, annualCAGR, annualVolatility, standardDeviation
    }
    
    @FocusState private var activeField: ActiveField?
    
    // MARK: - Real values stored in your manager
    @ObservedObject var inputManager: PersistentInputManager
    
    // IMPORTANT: This is your weekly settings:
    @ObservedObject var simSettings: SimulationSettings
    
    // For monthly settings, we either bring it in as an @EnvironmentObject
    // or get it from the Coordinator, e.g.:
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    
    @ObservedObject var coordinator: SimulationCoordinator
    
    // Binding to let the parent know whether the keyboard is visible.
    @Binding var isKeyboardVisible: Bool
    
    // MARK: - Local copies of fields
    @State private var localIterations: String = "100"
    @State private var localAnnualCAGR: String = "30"
    @State private var localAnnualVolatility: String = "80"
    @State private var localStandardDev: String = "150"
    
    // MARK: - Ephemeral text fields
    @State private var ephemeralIterations: String = ""
    @State private var ephemeralAnnualCAGR: String = ""
    @State private var ephemeralAnnualVolatility: String = ""
    @State private var ephemeralStandardDev: String = ""
    
    // Use the same AppStorage property that controls unlocking in the AdvancedSettingsSection
    @AppStorage("advancedSettingsUnlocked") private var advancedSettingsUnlocked: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            // If portrait, use your original code unaltered.
            if !isLandscape {
                originalPortraitLayout
            } else {
                // Landscape-specific layout
                landscapeLayout
            }
        }
        // Keep track of keyboard
        .onChange(of: activeField) { newActive in
            isKeyboardVisible = (newActive != nil)
        }
        // Pre-fill local fields on appear
        .onAppear {
            localIterations       = inputManager.iterations
            localAnnualCAGR       = inputManager.annualCAGR
            localAnnualVolatility = inputManager.annualVolatility
            localStandardDev      = inputManager.standardDeviation
            
            ephemeralIterations       = localIterations
            ephemeralAnnualCAGR       = localAnnualCAGR
            ephemeralAnnualVolatility = localAnnualVolatility
            ephemeralStandardDev      = localStandardDev
        }
    }
    
    // MARK: - The unmodified portrait layout (your original code)
    private var originalPortraitLayout: some View {
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
                        
                        // Lock Seed toggle now disabled if advanced settings are not unlocked
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
                    // Just a placeholder for spacing.
                    Text(" ")
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
                        // Commit anything typed if user forgot to hit return.
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
    }
    
    // MARK: - Landscape layout
    private var landscapeLayout: some View {
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
            
            VStack(spacing: 0) {
                
                // Keep "HODL Simulator" up top
                Spacer().frame(height: 30)
                
                Text("HODL Simulator")
                    .font(.custom("AvenirNext-Heavy", size: 36))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.6), radius: 6, x: 0, y: 0)
                
                // Move everything else further down
                Spacer().frame(height: 30)
                
                VStack(spacing: 20) {
                    // Place "Set your simulation parameters" INSIDE the dark box
                    Text("Set your simulation parameters")
                        .font(.callout)
                        .foregroundColor(.gray)
                    
                    // The box is narrower in landscape
                    VStack(spacing: 24) {
                        // Single row for all 4 fields
                        HStack(spacing: 24) {
                            iterationField
                            cagrField
                            volField
                            stdDevField
                        }
                        // Toggles
                        if !(coordinator.isLoading || coordinator.isChartBuilding) {
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
                        
                        // The button
                        if coordinator.isLoading || coordinator.isChartBuilding {
                            Text(" ")
                                .font(.callout)
                                .foregroundColor(.clear)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
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
                        }
                    }
                    // Dark box is narrower in landscape
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.1).opacity(0.8))
                    )
                    .padding(.horizontal, 15)
                }
                // Extra bottom space so your bottom icons can be nudged down
                .padding(.bottom, 50)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Shared Fields/Toggles
    private var iterationField: some View {
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
    }
    
    private var cagrField: some View {
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
    
    private var volField: some View {
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
    }
    
    private var stdDevField: some View {
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
    
    // MARK: - Helper to commit fields
    private func commitAllFields() {
        localIterations       = ephemeralIterations.isEmpty       ? localIterations       : ephemeralIterations
        localAnnualCAGR       = ephemeralAnnualCAGR.isEmpty       ? localAnnualCAGR       : ephemeralAnnualCAGR
        localAnnualVolatility = ephemeralAnnualVolatility.isEmpty ? localAnnualVolatility : ephemeralAnnualVolatility
        localStandardDev      = ephemeralStandardDev.isEmpty      ? localStandardDev      : ephemeralStandardDev
        
        inputManager.iterations        = localIterations
        inputManager.annualCAGR        = localAnnualCAGR
        inputManager.annualVolatility  = localAnnualVolatility
        inputManager.standardDeviation = localStandardDev
    }
    
    // MARK: - Computed Binding for "Lock Seed"
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
