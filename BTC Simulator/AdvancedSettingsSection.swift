//
//  AdvancedSettingsSection.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/01/2025.
//

import SwiftUI
import StoreKit

@MainActor
class IAPManager: ObservableObject {
    @Published var product: Product?

    init() {
        listenForTransactions()
    }
    
    /// Continuously listen for any transaction updates (e.g. pending, completed on another device).
    private func listenForTransactions() {
        Task {
            for await verificationResult in Transaction.updates {
                do {
                    let transaction = try checkVerification(verificationResult)
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Fetch the product from the App Store using its product ID.
    func fetchProduct() async {
        do {
            // Replace with your actual product ID from App Store Connect
            let productIDs = ["com.conornolan.bitcoinsim.advsettings"]
            let storeProducts = try await Product.products(for: productIDs)
            
            guard let firstProduct = storeProducts.first else {
                print("No matching in-app product found.")
                return
            }
            // Because this class is @MainActor, it's safe to assign directly here
            self.product = firstProduct
        } catch {
            print("Error fetching products: \(error)")
        }
    }

    /// Purchase flow using async/await (StoreKit 2).
    func purchaseAdvancedSettings() async throws -> Bool {
        guard let product = product else {
            print("No product available to purchase.")
            return false
        }
        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerification(verificationResult)
            await transaction.finish()
            return true

        case .userCancelled:
            print("User cancelled the purchase.")
            return false

        case .pending:
            print("Purchase is pending external action.")
            return false

        @unknown default:
            print("Unknown purchase result: \(result).")
            return false
        }
    }

    /// Helper to verify the transaction
    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified:
            throw StoreError.unverifiedTransaction
        }
    }
}

enum StoreError: Error {
    case unverifiedTransaction
}


struct AdvancedSettingsSection: View {
    @EnvironmentObject var weeklySimSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var coordinator: SimulationCoordinator
    
    // Inject the IAP manager as an environment object:
    @EnvironmentObject var iapManager: IAPManager

    @Binding var showAdvancedSettings: Bool

    @AppStorage("advancedSettingsUnlocked") var advancedSettingsUnlocked: Bool = false
    @State private var showUnlockAlert = false
    
    var body: some View {
        Section {
            HStack {
                Button(action: {
                    withAnimation {
                        showAdvancedSettings.toggle()
                    }
                }) {
                    HStack {
                        Text("Advanced Settings")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: showAdvancedSettings ? "chevron.down" : "chevron.forward")
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                if !advancedSettingsUnlocked {
                    Button(action: {
                        showUnlockAlert = true
                    }) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }
            }
            .alert(isPresented: $showUnlockAlert) {
                Alert(
                    title: Text("Unlock Advanced Settings"),
                    message: Text("Do you want to unlock advanced settings for $2.99?"),
                    primaryButton: .default(Text("Unlock"), action: {
                        Task {
                            do {
                                let success = try await iapManager.purchaseAdvancedSettings()
                                advancedSettingsUnlocked = success
                            } catch {
                                print("Purchase error: \(error)")
                            }
                        }
                    }),
                    secondaryButton: .cancel()
                )
            }
            
            if showAdvancedSettings {
                Group {
                    // RANDOM SEED Section
                    Section {
                        Toggle("Lock Random Seed", isOn: lockedRandomSeedBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        if lockedRandomSeedBinding.wrappedValue {
                            Text("Current Seed (Locked): \(currentSeedValue)")
                                .font(.footnote)
                                .foregroundColor(.white)
                        } else {
                            if lastUsedSeedValue == 0 {
                                Text("Current Seed: (no run yet)")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            } else {
                                Text("Current Seed (Unlocked): \(lastUsedSeedValue)")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("Locking this seed ensures consistent simulation results every run. Unlock for new randomness.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("RANDOM SEED")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Growth Model Section
                    Section {
                        Toggle("Use Lognormal Growth", isOn: lognormalGrowthBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Uses a lognormal model for Bitcoin’s price distribution. Uncheck to use an alternative approach (annual step).")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Growth Model")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Historical Sampling Section
                    Section {
                        Toggle("Use Historical Sampling", isOn: historicalSamplingBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Toggle("Use Extended Historical Sampling", isOn: extendedHistoricalSamplingBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                            .disabled(!historicalSamplingBinding.wrappedValue)
                        
                        Toggle("Lock Historical Sampling", isOn: lockHistoricalSamplingBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Pulls contiguous historical blocks from BTC + S&P data, preserving volatility clustering. Lock it to avoid random draws.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Historical Sampling")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Autocorrelation Section
                    Section {
                        Toggle("Use Autocorrelation", isOn: autoCorrelationBinding)
                            .tint(autoCorrelationBinding.wrappedValue ? .orange : .gray)
                            .foregroundColor(.white)
                        
                        HStack {
                            Button {
                                autoCorrelationStrengthBinding.wrappedValue = 0.05
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                            
                            Text("Autocorrelation Strength")
                                .foregroundColor(.white)
                            
                            Slider(
                                value: autoCorrelationStrengthBinding,
                                in: 0.01...0.09,
                                step: 0.01
                            )
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        }
                        .disabled(!autoCorrelationBinding.wrappedValue)
                        .opacity(autoCorrelationBinding.wrappedValue ? 1.0 : 0.4)
                        
                        HStack {
                            Button {
                                meanReversionTargetBinding.wrappedValue = 0.03
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 4)
                            
                            Text("Mean Reversion Target")
                                .foregroundColor(.white)
                            
                            Slider(
                                value: meanReversionTargetBinding,
                                in: 0.01...0.05,
                                step: 0.001
                            )
                            .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                        }
                        .disabled(!autoCorrelationBinding.wrappedValue)
                        .opacity(autoCorrelationBinding.wrappedValue ? 1.0 : 0.4)
                        
                        Text("Autocorrelation makes returns partially follow their previous trend, while mean reversion nudges them back toward a target.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Autocorrelation")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Volatility Section
                    Section {
                        Toggle("Use Volatility Shocks", isOn: volShocksBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Toggle("Use GARCH Volatility", isOn: garchBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Volatility Shocks can randomly spike or dampen volatility. GARCH models let volatility evolve based on recent price moves.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Volatility")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                    
                    // Regime Switching Section
                    Section {
                        Toggle("Use Regime Switching", isOn: regimeSwitchingBinding)
                            .tint(.orange)
                            .foregroundColor(.white)
                        
                        Text("Dynamically shifts between bull, bear, and hype states using a Markov chain to create more realistic cyclical patterns.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    } header: {
                        Text("Regime Switching")
                            .font(.caption)
                            .textCase(.uppercase)
                            .foregroundColor(.gray)
                    }
                    .listRowBackground(Color(white: 0.15))
                }
                .disabled(!advancedSettingsUnlocked)
                .opacity(advancedSettingsUnlocked ? 1.0 : 0.5)
                
                if !advancedSettingsUnlocked {
                    Button("Unlock Advanced Settings for $2.99") {
                        showUnlockAlert = true
                    }
                    .foregroundColor(.orange)
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
            }
        }
        .listRowBackground(Color(white: 0.15))
        // Fetch product whenever this view appears
        .task {
            await iapManager.fetchProduct()
        }
    }
}

// MARK: - Computed BINDINGS for Weekly vs Monthly
extension AdvancedSettingsSection {

    private var isMonthly: Bool {
        coordinator.useMonthly
    }

    // LOCKED RANDOM SEED
    private var lockedRandomSeedBinding: Binding<Bool> {
        Binding(
            get: {
                isMonthly
                ? monthlySimSettings.lockedRandomSeedMonthly
                : weeklySimSettings.lockedRandomSeed
            },
            set: { newVal in
                guard advancedSettingsUnlocked else {
                    print("User tried to toggle lockedRandomSeed but advanced settings are not unlocked.")
                    return
                }
                
                if isMonthly {
                    monthlySimSettings.lockedRandomSeedMonthly = newVal
                    if newVal {
                        let newSeed = UInt64.random(in: 0..<UInt64.max)
                        monthlySimSettings.seedValueMonthly = newSeed
                        monthlySimSettings.useRandomSeedMonthly = false
                    } else {
                        monthlySimSettings.seedValueMonthly = 0
                        monthlySimSettings.useRandomSeedMonthly = true
                    }
                } else {
                    weeklySimSettings.lockedRandomSeed = newVal
                    if newVal {
                        let newSeed = UInt64.random(in: 0..<UInt64.max)
                        weeklySimSettings.seedValue = newSeed
                        weeklySimSettings.useRandomSeed = false
                    } else {
                        weeklySimSettings.seedValue = 0
                        weeklySimSettings.useRandomSeed = true
                    }
                }
            }
        )
    }

    // CURRENT / LAST USED SEED text
    private var currentSeedValue: UInt64 {
        isMonthly
            ? monthlySimSettings.seedValueMonthly
            : weeklySimSettings.seedValue
    }
    private var lastUsedSeedValue: UInt64 {
        isMonthly
            ? monthlySimSettings.lastUsedSeedMonthly
            : weeklySimSettings.lastUsedSeed
    }

    // LOGNORMAL GROWTH
    private var lognormalGrowthBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useLognormalGrowthMonthly : weeklySimSettings.useLognormalGrowth },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.useLognormalGrowthMonthly = newVal
                    monthlySimSettings.useAnnualStepMonthly = !newVal
                } else {
                    weeklySimSettings.useLognormalGrowth = newVal
                    weeklySimSettings.useAnnualStep = !newVal
                }
            }
        )
    }

    // HISTORICAL SAMPLING
    private var historicalSamplingBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useHistoricalSamplingMonthly : weeklySimSettings.useHistoricalSampling },
            set: { newVal in
                print("Binding setting Historical to \(newVal)")
                if isMonthly {
                    monthlySimSettings.useHistoricalSamplingMonthly = newVal
                    if !newVal {
                        print("Binding forcing Extended OFF (monthly)")
                        monthlySimSettings.useExtendedHistoricalSamplingMonthly = false
                    }
                } else {
                    weeklySimSettings.useHistoricalSampling = newVal
                    if !newVal {
                        print("Binding forcing Extended OFF (weekly)")
                        weeklySimSettings.useExtendedHistoricalSampling = false
                    }
                }
                print("Binding result: Historical=\(isMonthly ? monthlySimSettings.useHistoricalSamplingMonthly : weeklySimSettings.useHistoricalSampling), Extended=\(isMonthly ? monthlySimSettings.useExtendedHistoricalSamplingMonthly : weeklySimSettings.useExtendedHistoricalSampling)")
            }
        )
    }

    private var extendedHistoricalSamplingBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useExtendedHistoricalSamplingMonthly : weeklySimSettings.useExtendedHistoricalSampling },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.useExtendedHistoricalSamplingMonthly = newVal
                } else {
                    weeklySimSettings.useExtendedHistoricalSampling = newVal
                }
            }
        )
    }

    private var lockHistoricalSamplingBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.lockHistoricalSamplingMonthly : weeklySimSettings.lockHistoricalSampling },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.lockHistoricalSamplingMonthly = newVal
                } else {
                    weeklySimSettings.lockHistoricalSampling = newVal
                }
            }
        )
    }

    // AUTOCORRELATION
    private var autoCorrelationBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useAutoCorrelationMonthly : weeklySimSettings.useAutoCorrelation },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.useAutoCorrelationMonthly = newVal
                    if !newVal { monthlySimSettings.useMeanReversionMonthly = false }
                } else {
                    weeklySimSettings.useAutoCorrelation = newVal
                    if !newVal { weeklySimSettings.useMeanReversion = false }
                }
            }
        )
    }

    private var autoCorrelationStrengthBinding: Binding<Double> {
        Binding(
            get: { isMonthly ? monthlySimSettings.autoCorrelationStrengthMonthly : weeklySimSettings.autoCorrelationStrength },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.autoCorrelationStrengthMonthly = newVal
                } else {
                    weeklySimSettings.autoCorrelationStrength = newVal
                }
            }
        )
    }

    private var meanReversionTargetBinding: Binding<Double> {
        Binding(
            get: { isMonthly ? monthlySimSettings.meanReversionTargetMonthly : weeklySimSettings.meanReversionTarget },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.meanReversionTargetMonthly = newVal
                } else {
                    weeklySimSettings.meanReversionTarget = newVal
                }
            }
        )
    }

    // VOLATILITY
    private var volShocksBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useVolShocksMonthly : weeklySimSettings.useVolShocks },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.useVolShocksMonthly = newVal
                } else {
                    weeklySimSettings.useVolShocks = newVal
                }
            }
        )
    }

    private var garchBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useGarchVolatilityMonthly : weeklySimSettings.useGarchVolatility },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.useGarchVolatilityMonthly = newVal
                } else {
                    weeklySimSettings.useGarchVolatility = newVal
                }
            }
        )
    }

    // REGIME SWITCHING
    private var regimeSwitchingBinding: Binding<Bool> {
        Binding(
            get: { isMonthly ? monthlySimSettings.useRegimeSwitchingMonthly : weeklySimSettings.useRegimeSwitching },
            set: { newVal in
                if isMonthly {
                    monthlySimSettings.useRegimeSwitchingMonthly = newVal
                } else {
                    weeklySimSettings.useRegimeSwitching = newVal
                }
            }
        )
    }
}
