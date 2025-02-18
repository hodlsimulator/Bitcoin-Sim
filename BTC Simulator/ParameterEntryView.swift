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
    @ObservedObject var simSettings: SimulationSettings
    @ObservedObject var coordinator: SimulationCoordinator
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings

    // Binding to let the parent know whether the keyboard is visible.
    @Binding var isKeyboardVisible: Bool

    // Binding that triggers navigation to pinned columns when set to true.
    @Binding var showPinnedColumns: Bool

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

    // If advanced settings are locked
    @AppStorage("advancedSettingsUnlocked") private var advancedSettingsUnlocked: Bool = false

    // We’ll keep this if the parent wants to do navigation after "Run Simulation."
    @State private var navigateToPinnedColumns = false

    var body: some View {
        // A ZStack that aligns content to the top-right
        ZStack(alignment: .topTrailing) {
            // 1) The main content
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

            // 2) The forward chevron if there's at least 1 simulation result
            if !coordinator.monteCarloResults.isEmpty {
                Button {
                    // Tapping this sets showPinnedColumns -> triggers navigation in ContentView
                    showPinnedColumns = true
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title)          // bigger icon
                        .foregroundColor(.white)
                        .padding()
                }
                // Some spacing so it appears just below the nav bar
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
        }
    }

    // MARK: - The unmodified portrait layout
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

                // Input fields + toggles
                VStack(spacing: 20) {
                    // Row 1 (Iterations & CAGR)
                    HStack(spacing: 24) {
                        iterationField
                        cagrField
                    }
                    // Row 2 (Vol & StdDev)
                    HStack(spacing: 24) {
                        volField
                        stdDevField
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

                // The Run Simulation Button
                if coordinator.isLoading || coordinator.isChartBuilding {
                    Text(" ") // placeholder
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
                Spacer().frame(height: 30)

                Text("HODL Simulator")
                    .font(.custom("AvenirNext-Heavy", size: 36))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(0.6), radius: 6, x: 0, y: 0)

                Spacer().frame(height: 30)

                VStack(spacing: 20) {
                    Text("Set your simulation parameters")
                        .font(.callout)
                        .foregroundColor(.gray)

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
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.1).opacity(0.8))
                    )
                    .padding(.horizontal, 15)
                }
                .padding(.bottom, 50)

                Spacer()
            }
        }
    }

    // MARK: - Shared text fields

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

    // MARK: - Binding for "Lock Seed"
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
