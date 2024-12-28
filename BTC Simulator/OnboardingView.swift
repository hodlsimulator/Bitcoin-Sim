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
    @EnvironmentObject var simSettings: SimulationSettings
    @Binding var didFinishOnboarding: Bool
    
    // MARK: - Steps from 0..7
    @State private var currentStep: Int = 0
    
    // Step 0: Weekly/Monthly
    @State private var chosenPeriodUnit: PeriodUnit = .weeks
    
    // Step 1: How many total periods
    @State private var totalPeriods: Int = 52
    
    // Step 2: Currency preference
    @State private var currencyPreference: PreferredCurrency = .usd
    
    // Step 3: Starting Balance
    // user can enter a balance in that chosen currency
    @State private var startingBalance: Double = 0.0
    
    // Step 4: BTC Price (fetched or typed)
    @State private var fetchedBTCPrice: String = "N/A"
    @State private var userBTCPrice: String = ""
    
    // Step 5: Contributions
    @State private var firstYearContribution: Double = 60.0
    @State private var subsequentContribution: Double = 100.0
    
    // Step 6: Withdrawals
    @State private var threshold1: Double = 30000.0
    @State private var withdraw1: Double = 100.0
    @State private var threshold2: Double = 60000.0
    @State private var withdraw2: Double = 200.0
    
    // Step 7: Final Review
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Tap away to dismiss keyboard
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    hideKeyboard()
                }
            
            VStack(spacing: 30) {
                Spacer().frame(height: 50)
                
                // Official Bitcoin Logo up top
                OfficialBitcoinLogo()
                    .frame(width: 80, height: 80)
                
                Text(titleForStep(currentStep))
                    .font(.title)
                    .foregroundColor(.white)
                
                Text(subtitleForStep(currentStep))
                    .foregroundColor(.gray)
                    .font(.callout)
                
                Spacer().frame(height: 10)
                
                // Step content
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
                    step4_BTCPriceInput()
                case 5:
                    step5_Contributions()
                case 6:
                    step6_Withdrawals()
                default:
                    step7_ReviewAndFinish()
                }
                
                Spacer()
                
                // Bottom nav bar
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                    }
                    
                    Spacer()
                    
                    // If final step => "Finish", else "Next"
                    Button(currentStep == 7 ? "Finish" : "Next") {
                        onNextTapped()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
        // Async fetch BTC price on appear
        .task {
            await fetchBTCPriceFromAPI()
        }
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
            
            TextField("e.g. 52", value: $totalPeriods, format: .number)
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
            
            Picker("Currency", selection: $currencyPreference) {
                ForEach(PreferredCurrency.allCases) { cur in
                    Text(cur.rawValue).tag(cur)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }
    
    // MARK: - Step 3
    private func step3_StartingBalance() -> some View {
        VStack(spacing: 20) {
            Text("Enter your starting balance")
                .foregroundColor(.white)
            
            TextField("e.g. 1000.0", value: $startingBalance, format: .number)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                .foregroundColor(.white)
                .frame(width: 200)
                .multilineTextAlignment(.center)
            
            Text("in \(currencyPreference.rawValue.uppercased())")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Step 4
    private func step4_BTCPriceInput() -> some View {
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
    
    // MARK: - Step 5
    private func step5_Contributions() -> some View {
        VStack(spacing: 16) {
            Text("Contributions")
                .foregroundColor(.white)
                .font(.headline)
            
            HStack {
                Text("Year1 \(chosenPeriodUnit.rawValue.capitalized):")
                    .foregroundColor(.white)
                TextField("60.0", value: $firstYearContribution, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 80)
            }
            
            HStack {
                Text("Year2+ \(chosenPeriodUnit.rawValue.capitalized):")
                    .foregroundColor(.white)
                TextField("100.0", value: $subsequentContribution, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 80)
            }
        }
    }
    
    // MARK: - Step 6
    private func step6_Withdrawals() -> some View {
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
                
                TextField("100.0", value: $withdraw1, format: .number)
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
                
                TextField("200.0", value: $withdraw2, format: .number)
                    .keyboardType(.decimalPad)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .frame(width: 80)
            }
        }
    }
    
    // MARK: - Step 7
    private func step7_ReviewAndFinish() -> some View {
        VStack(spacing: 16) {
            Text("Review & Confirm")
                .foregroundColor(.white)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Frequency: \(chosenPeriodUnit.rawValue.capitalized)")
                Text("Periods: \(totalPeriods)")
                Text("Pref. Currency: \(currencyPreference.rawValue)")
                Text("Starting Bal: \(startingBalance, specifier: "%.2f") \(currencyPreference.rawValue.uppercased())")
                Text("BTC Price: \(finalBTCPrice, specifier: "%.2f") USD")
                Text("Contrib (Y1/Y2+): \(firstYearContribution, specifier: "%.0f") / \(subsequentContribution, specifier: "%.0f")")
                Text("Withdraws: \(threshold1, specifier: "%.0f")→\(withdraw1, specifier: "%.0f"), \(threshold2, specifier: "%.0f")→\(withdraw2, specifier: "%.0f")")
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - onNextTapped
    private func onNextTapped() {
        if currentStep == 7 {
            // Apply everything
            applySettingsToSim()
            didFinishOnboarding = true
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    // MARK: - Apply settings
    private func applySettingsToSim() {
        // Convert user’s chosen period unit to total weeks
        let finalWeeks = (chosenPeriodUnit == .weeks)
            ? totalPeriods
            : totalPeriods * 4
        
        simSettings.userWeeks = finalWeeks
        simSettings.initialBTCPriceUSD = finalBTCPrice  // from finalBTCPrice property below
        
        // If you store currency preference:
        // simSettings.preferredCurrency = currencyPreference.rawValue  // e.g. "USD", "EUR", "Both"

        // If you store startingBalance:
        // simSettings.startingBalance = startingBalance
        
        // If you have inputManager or your simSettings directly handle contributions:
        simSettings.inputManager?.firstYearContribution = String(firstYearContribution)
        simSettings.inputManager?.subsequentContribution = String(subsequentContribution)
        simSettings.inputManager?.threshold1 = threshold1
        simSettings.inputManager?.withdrawAmount1 = withdraw1
        simSettings.inputManager?.threshold2 = threshold2
        simSettings.inputManager?.withdrawAmount2 = withdraw2
    }
    
    // MARK: - finalBTCPrice
    private var finalBTCPrice: Double {
        // If user typed a valid price, use it
        if let typedVal = Double(userBTCPrice), typedVal > 0 {
            return typedVal
        }
        // If we fetched a valid price, use it
        if let fetchedVal = Double(fetchedBTCPrice), fetchedVal > 0 {
            return fetchedVal
        }
        // fallback to 58,000
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
        case 4: return "BTC Price"
        case 5: return "Contributions"
        case 6: return "Withdrawals"
        default: return "Review"
        }
    }
    
    private func subtitleForStep(_ step: Int) -> String {
        switch step {
        case 0: return "Pick weekly or monthly"
        case 1: return "How many \(chosenPeriodUnit.rawValue)?"
        case 2: return "USD, EUR, or Both?"
        case 3: return "Set your starting balance"
        case 4: return "Fetch or type BTC price"
        case 5: return "Contributions per step"
        case 6: return "Set your withdrawal triggers"
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
