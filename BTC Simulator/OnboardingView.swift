//
//  OnboardingView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 28/12/2024.
//

import SwiftUI

enum PeriodUnit: String, CaseIterable, Identifiable {
    case weeks
    case months
    var id: String { rawValue }
}

enum PreferredCurrency: String, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case both = "Both"
    var id: String { rawValue }
}

struct OnboardingView: View {
    // Pull in your SimulationSettings & PersistentInputManager from Environment
    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    
    // Bind to know when the user has finished onboarding
    @Binding var didFinishOnboarding: Bool
    
    // MARK: - Steps 0..8
    @State private var currentStep: Int = 0
    
    // Step 0: Weekly or Monthly
    @State private var chosenPeriodUnit: PeriodUnit = .weeks
    
    // Step 1: How many total periods
    @State private var totalPeriods: Int = 1040
    
    // Step 2: Which currency to display (USD/EUR/Both)
    @State private var currencyPreference: PreferredCurrency = .usd
    
    // Step 3: Starting Balance
    @State private var startingBalance: Double = 0.0
    @State private var startingBalanceCurrencyForBoth: PreferredCurrency = .usd
    
    // Step 4: Average BTC Purchase Price
    @State private var averageCostBasis: Double = 58000
    
    // Step 5: BTC Price (fetched or typed)
    @State private var fetchedBTCPrice: String = "N/A"
    @State private var userBTCPrice: String = ""
    
    // Step 6: Single contribution for the entire simulation
    @State private var contributionPerStep: Double = 0.0
    
    // Step 7: Withdrawals default to thresholds at 30k & 60k, zero withdraw
    @State private var threshold1: Double = 30000
    @State private var withdraw1: Double = 0.0
    @State private var threshold2: Double = 60000
    @State private var withdraw2: Double = 0.0
    
    // MARK: - Button positioning
    // For steps 0..7 => Next button at 260
    // For step=8 => Finish button can differ for "both" vs normal
    private let bottomPaddingNext: CGFloat       = 260   // steps 0..7
    private let bottomPaddingFinish: CGFloat     = 150   // step 8 if not both
    private let bottomPaddingFinishBoth: CGFloat = 110   // step 8 if both
    
    // Decide the bottom padding for the Next/Finish button
    private var bottomPaddingForStep: CGFloat {
        if currentStep != 8 {
            // Not final => Next button
            return bottomPaddingNext
        } else {
            // Step 8 => Finish
            if currencyPreference == .both {
                return bottomPaddingFinishBoth
            } else {
                return bottomPaddingFinish
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    Spacer().frame(height: 40)
                    
                    OfficialBitcoinLogo()
                        .frame(width: 80, height: 80)
                    
                    Text(titleForStep(currentStep))
                        .font(.title)
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    if !subtitleForStep(currentStep).isEmpty {
                        Text(subtitleForStep(currentStep))
                            .foregroundColor(.gray)
                            .font(.callout)
                            .padding(.top, 2)
                    }
                    
                    // Switch on currentStep
                    switch currentStep {
                    case 0:
                        step0_PeriodFrequency()
                    case 1:
                        step1_TotalPeriods()
                    case 2:
                        step2_PickCurrency()
                    case 3:
                        step3_StartingBalance()
                    case 4:
                        step4_AverageCostBasis()
                    case 5:
                        step5_BTCPriceInput()
                    case 6:
                        step6_Contributions()
                    case 7:
                        step7_Withdrawals()
                    default:
                        step8_ReviewAndFinish()
                    }
                    
                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
                .background(Color.clear)
                .contentShape(Rectangle())
                // Dismiss keyboard on background tap
                .onTapGesture {
                    hideKeyboard()
                }
            }
        }
        // Back arrow if step > 0
        .overlay(
            Group {
                if currentStep > 0 {
                    Button {
                        withAnimation {
                            currentStep -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 50)
                    .padding(.leading, 20)
                }
            },
            alignment: .topLeading
        )
        // Next or Finish button
        .overlay(
            Button(currentStep == 8 ? "Finish" : "Next") {
                onNextTapped()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            .padding(.bottom, bottomPaddingForStep),
            alignment: .bottom
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // If you fetch a live BTC price:
        .task {
            await fetchBTCPriceFromAPI()
        }
        // If you want to force brand-new defaults each time, keep .onAppear commented out
        /*
        .onAppear {
            // e.g. if (contributionPerStep == 0.0) then load from old inputManager
            // or comment out to always use the new defaults
        }
        */
    }
    
    // MARK: - Step 0
    private func step0_PeriodFrequency() -> some View {
        VStack(spacing: 20) {
            Text("Choose Weekly or Monthly")
                .foregroundColor(.white)
            Picker("Freq", selection: $chosenPeriodUnit) {
                ForEach(PeriodUnit.allCases) { unit in
                    Text(unit.rawValue.capitalized).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }
    
    // MARK: - Step 1
    private func step1_TotalPeriods() -> some View {
        VStack(spacing: 16) {
            Text(chosenPeriodUnit == .weeks
                 ? "How many weeks?"
                 : "How many months?")
                .foregroundColor(.white)
            
            TextField("e.g. 1040", value: $totalPeriods, format: .number)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                .foregroundColor(.white)
                .frame(width: 150)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step 2
    private func step2_PickCurrency() -> some View {
        VStack(spacing: 20) {
            Text("Which currency do you want to display?")
                .foregroundColor(.white)
            
            Picker("ContribCurrency", selection: $simSettings.contributionCurrencyWhenBoth) {
                Text("USD").tag(PreferredCurrency.usd)
                Text("EUR").tag(PreferredCurrency.eur)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }
    
    // MARK: - Step 3
    private func step3_StartingBalance() -> some View {
        VStack(spacing: 20) {
            if currencyPreference == .both {
                Text("Starting Balance")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Text("Are you entering your balance in USD or EUR?")
                    .foregroundColor(.white)
                
                Picker("StartingBalCurrency", selection: $startingBalanceCurrencyForBoth) {
                    Text("USD").tag(PreferredCurrency.usd)
                    Text("EUR").tag(PreferredCurrency.eur)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            } else {
                Text("Enter your starting balance in \(currencyPreference.rawValue.uppercased())")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            
            TextField("e.g. 1000.0", value: $startingBalance, format: .number)
                .keyboardType(.decimalPad)
                .padding(8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                .foregroundColor(.white)
                .frame(width: 200)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step 4
    private func step4_AverageCostBasis() -> some View {
        VStack(spacing: 20) {
            Text("Enter your average BTC purchase price")
                .foregroundColor(.white)
            
            TextField("e.g. 58000.0", value: $averageCostBasis, format: .number)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                .foregroundColor(.white)
                .frame(width: 200)
                .multilineTextAlignment(.center)
            
            Text("(in USD)")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Step 5
    private func step5_BTCPriceInput() -> some View {
        VStack(spacing: 16) {
            Text("Fetched BTC Price (USD): \(fetchedBTCPrice)")
                .foregroundColor(.white)
            
            Text("Or type your own:")
                .foregroundColor(.white)
            
            TextField("e.g. 58000", text: $userBTCPrice)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                .foregroundColor(.white)
                .frame(width: 200)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Step 6 (Single contribution)
    private func step6_Contributions() -> some View {
        let frequencyWord = (chosenPeriodUnit == .weeks) ? "weekly" : "monthly"
        
        return VStack(spacing: 20) {
            if currencyPreference == .both {
                Spacer().frame(height: 20)
                
                Text("Are these contributions in USD or EUR?")
                    .foregroundColor(.white)
                
                Picker("ContribCurrency", selection: $simSettings.contributionCurrencyWhenBoth) {
                    Text("USD").tag(PreferredCurrency.usd)
                    Text("EUR").tag(PreferredCurrency.eur)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
                
                HStack {
                    Text("\(frequencyWord.capitalized) Amount:")
                        .foregroundColor(.white)
                    TextField("100.0", value: $contributionPerStep, format: .number)
                        .keyboardType(.decimalPad)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                        .frame(width: 80)
                }
                
            } else {
                Spacer().frame(height: 20)
                
                Text("Contribution Setup")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Text("Enter your \(frequencyWord) contribution amount")
                    .foregroundColor(.gray)
                
                HStack {
                    Text("\(frequencyWord.capitalized) Amount:")
                        .foregroundColor(.white)
                    TextField("100.0", value: $contributionPerStep, format: .number)
                        .keyboardType(.decimalPad)
                        .padding(8)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                        .frame(width: 80)
                }
            }
        }
    }
    
    // MARK: - Step 7: Withdrawals
    private func step7_Withdrawals() -> some View {
        VStack(spacing: 16) {
            Text("Withdrawal Rules")
                .foregroundColor(.white)
                .font(.headline)
            
            HStack {
                TextField("Threshold1", value: $threshold1, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 100)
                
                Text("→ withdraw:")
                    .foregroundColor(.white)
                
                // Default to 0.0
                TextField("0.0", value: $withdraw1, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 80)
            }
            
            HStack {
                TextField("Threshold2", value: $threshold2, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 100)
                
                Text("→ withdraw:")
                    .foregroundColor(.white)
                
                // Default to 0.0
                TextField("0.0", value: $withdraw2, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 80)
            }
        }
    }
    
    // MARK: - Step 8
    private func step8_ReviewAndFinish() -> some View {
        VStack(spacing: 16) {
            Text("Review & Confirm")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Frequency: \(chosenPeriodUnit.rawValue.capitalized)")
                Text("Periods: \(totalPeriods)")
                Text("Pref. Currency: \(currencyPreference.rawValue)")
                
                if currencyPreference == .both {
                    Text("Starting Bal typed in: \(startingBalanceCurrencyForBoth.rawValue)")
                }
                Text("Starting Bal: \(startingBalance, specifier: "%.2f")")
                
                Text("Avg. Cost Basis: \(averageCostBasis, specifier: "%.2f") USD")
                Text("BTC Price: \(finalBTCPrice, specifier: "%.2f") USD")
                
                if currencyPreference == .both {
                    Text("Contrib typed in: \(simSettings.contributionCurrencyWhenBoth.rawValue)")
                }
                Text("Contribution: \(contributionPerStep, specifier: "%.0f")")
                
                Text("Withdraws: \(threshold1, specifier: "%.0f")→\(withdraw1, specifier: "%.0f"), \(threshold2, specifier: "%.0f")→\(withdraw2, specifier: "%.0f")")
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - onNextTapped
    private func onNextTapped() {
        // If final step => finish
        if currentStep == 8 {
            applySettingsToSim()
            didFinishOnboarding = true
        } else {
            // Otherwise go to the next
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    // MARK: - Apply settings
    private func applySettingsToSim() {
        // Convert chosen period to total weeks
        let finalWeeks = (chosenPeriodUnit == .weeks) ? totalPeriods : totalPeriods * 4
        simSettings.userWeeks = finalWeeks
        
        // Final BTC price
        simSettings.initialBTCPriceUSD = finalBTCPrice
        
        // If "both," record which currency the user typed for starting balance
        if currencyPreference == .both {
            simSettings.startingBalanceCurrencyWhenBoth = startingBalanceCurrencyForBoth
        }
        simSettings.startingBalance = startingBalance
        simSettings.averageCostBasis = averageCostBasis
        
        // Overall currency preference
        simSettings.currencyPreference = currencyPreference
        
        // Single contribution => store in inputManager
        inputManager.firstYearContribution = String(contributionPerStep)
        inputManager.subsequentContribution = String(contributionPerStep)
        
        if currencyPreference == .both {
            // Also store which currency user typed their contribution in
            simSettings.contributionCurrencyWhenBoth = simSettings.contributionCurrencyWhenBoth
        }
        
        // Thresholds & withdrawal
        inputManager.threshold1 = threshold1
        inputManager.withdrawAmount1 = withdraw1
        inputManager.threshold2 = threshold2
        inputManager.withdrawAmount2 = withdraw2
        
        // Optionally persist
        UserDefaults.standard.set(startingBalance, forKey: "savedStartingBalance")
        UserDefaults.standard.set(averageCostBasis, forKey: "savedAverageCostBasis")
        UserDefaults.standard.set(finalWeeks, forKey: "savedUserWeeks")
        UserDefaults.standard.set(finalBTCPrice, forKey: "savedInitialBTCPriceUSD")
        
        // Debug
        print("// DEBUG: applySettingsToSim => currencyPreference=\(currencyPreference.rawValue)")
        print("// DEBUG: startingBalance=\(startingBalance)")
        print("// DEBUG: contributionPerStep=\(contributionPerStep)")
        print("// DEBUG: threshold1=\(threshold1), withdraw1=\(withdraw1)")
        print("// DEBUG: threshold2=\(threshold2), withdraw2=\(withdraw2)")
    }
    
    // MARK: - finalBTCPrice
    private var finalBTCPrice: Double {
        if let typedVal = Double(userBTCPrice), typedVal > 0 {
            return typedVal
        }
        if let fetchedVal = Double(fetchedBTCPrice), fetchedVal > 0 {
            return fetchedVal
        }
        return 58000
    }
    
    // MARK: - Networking
    private func fetchBTCPriceFromAPI() async {
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
        guard let url = URL(string: urlString) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct SimplePriceResponse: Decodable {
                let bitcoin: [String: Double]
            }
            let decoded = try JSONDecoder().decode(SimplePriceResponse.self, from: data)
            if let price = decoded.bitcoin["usd"] {
                fetchedBTCPrice = String(format: "%.2f", price)
            } else {
                fetchedBTCPrice = "N/A"
            }
        } catch {
            fetchedBTCPrice = "N/A"
        }
    }
    
    // MARK: - Titles
    private func titleForStep(_ step: Int) -> String {
        switch step {
        case 0: return "Frequency"
        case 1: return "Total Periods"
        case 2: return "Currency"
        case 3: return "Starting Balance"
        case 4: return "Avg. Cost Basis"
        case 5: return "BTC Price"
        case 6: return "Contributions"
        case 7: return "Withdrawals"
        default: return "Review"
        }
    }
    
    // MARK: - Subtitles
    private func subtitleForStep(_ step: Int) -> String {
        switch step {
        case 0: return "Pick weekly or monthly"
        case 1: return "How many \(chosenPeriodUnit.rawValue)?"
        case 2: return "USD, EUR, or Both?"
        case 3: return ""
        case 4: return "What did you pay for BTC before?"
        case 5: return "Fetch or type current BTC price"
        case 6: return ""
        case 7: return "Set your withdrawal triggers"
        default: return "Confirm your setup"
        }
    }
}

// MARK: - Hide Keyboard Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}

