//
//  ParameterEntryView.swift
//  BTCMonteCarlo
//
//  Created by ... on 26/12/2024.
//

import SwiftUI

struct ParameterEntryView: View {
    // MARK: - Focus
    enum ActiveField {
        case iterations, annualCAGR, annualVolatility, standardDeviation
    }

    @FocusState private var activeField: ActiveField?

    // MARK: - Observed Objects
    @ObservedObject var inputManager: PersistentInputManager
    @ObservedObject var simSettings: SimulationSettings
    @ObservedObject var coordinator: SimulationCoordinator
    @ObservedObject var monthlySimSettings: MonthlySimulationSettings
    
    // MARK: - Bindings
    @Binding var isKeyboardVisible: Bool
    @Binding var showPinnedColumns: Bool

    // MARK: - Local copies
    @State private var localIterations: String       = "50"
    @State private var localAnnualCAGR: String       = "30"
    @State private var localAnnualVolatility: String = "80"
    @State private var localStandardDev: String      = "150"

    // Ephemeral fields
    @State private var ephemeralIterations: String       = ""
    @State private var ephemeralAnnualCAGR: String       = ""
    @State private var ephemeralAnnualVolatility: String = ""
    @State private var ephemeralStandardDev: String      = ""

    // If advanced settings are locked
    @AppStorage("advancedSettingsUnlocked") private var advancedSettingsUnlocked: Bool = false

    // Delay for idleManager
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                ZStack(alignment: .topTrailing) {
                    GeometryReader { geo in
                        let isLandscape = geo.size.width > geo.size.height
                        
                        if !isLandscape {
                            originalPortraitLayout
                        } else {
                            landscapeLayout
                        }
                    }
                    .onChange(of: activeField) { newActive in
                        isKeyboardVisible = (newActive != nil)
                    }
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
                    
                    // Slide button if results exist
                    if !coordinator.monteCarloResults.isEmpty {
                        Button {
                            showPinnedColumns = true
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .contentShape(Rectangle())
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            isLoaded = true
        }
    }

    // MARK: - Portrait
    private var originalPortraitLayout: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(white: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                activeField = nil
            }

            VStack(spacing: 30) {
                Spacer().frame(height: 60)

                Text("Bitcoin Sim")
                    .font(.custom("AvenirNext-Heavy", size: 40))
                    .foregroundColor(.white)

                Text("Set your simulation parameters")
                    .font(.callout)
                    .foregroundColor(.gray)

                VStack(spacing: 20) {
                    HStack(spacing: 24) {
                        iterationField
                        cagrField
                    }
                    HStack(spacing: 24) {
                        volField
                        stdDevField
                    }
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
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.1).opacity(0.85))
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal, 30)

                if coordinator.isLoading || coordinator.isChartBuilding {
                    Text(" ")
                        .font(.callout)
                        .foregroundColor(.clear)
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

                    Spacer()
                }
            }
        }
    }

    // MARK: - Landscape
    private var landscapeLayout: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(white: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                activeField = nil
            }

            VStack(spacing: 0) {
                Spacer().frame(height: 30)

                Text("Bitcoin Sim")
                    .font(.custom("AvenirNext-Heavy", size: 40))
                    .foregroundColor(.white)

                Spacer().frame(height: 30)

                VStack(spacing: 20) {
                    Text("Set your simulation parameters")
                        .font(.callout)
                        .foregroundColor(.gray)

                    VStack(spacing: 24) {
                        HStack(spacing: 24) {
                            iterationField
                            cagrField
                            volField
                            stdDevField
                        }
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

                        if coordinator.isLoading || coordinator.isChartBuilding {
                            Text(" ")
                                .font(.callout)
                                .foregroundColor(.clear)
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
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.1).opacity(0.85))
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
                    .padding(.horizontal, 15)
                }
                .padding(.bottom, 50)

                Spacer()
            }
        }
    }

    // MARK: - Fields
    private var iterationField: some View {
        VStack(spacing: 4) {
            Text("Iterations")
                .foregroundColor(.white)
            TextField("50", text: $ephemeralIterations)
                .keyboardType(.numberPad)
                .padding(6)
                .frame(width: 80)
                .background(Color(white: 0.25))
                .cornerRadius(6)
                .foregroundColor(.white)
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
                .padding(6)
                .frame(width: 80)
                .background(Color(white: 0.25))
                .cornerRadius(6)
                .foregroundColor(.white)
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
                .padding(6)
                .frame(width: 80)
                .background(Color(white: 0.25))
                .cornerRadius(6)
                .foregroundColor(.white)
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
                .padding(6)
                .frame(width: 80)
                .background(Color(white: 0.25))
                .cornerRadius(6)
                .foregroundColor(.white)
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

    // MARK: - Commit fields
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

    // MARK: - Lock seed binding
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
