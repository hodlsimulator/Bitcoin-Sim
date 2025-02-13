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
    @EnvironmentObject var weeklySimSettings: SimulationSettings          // weekly logic
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings // monthly logic
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var coordinator: SimulationCoordinator
    @EnvironmentObject var simSettings: SimulationSettings
    
    @Binding var didFinishOnboarding: Bool
    
    // MARK: - Steps 0..8
    @State private var currentStep: Int = 0
    
    // Step 0: Weekly or Monthly
    @State private var chosenPeriodUnit: PeriodUnit = .weeks
    
    // Step 1: How many total periods
    @State private var totalPeriods: Int = 1040
    
    // Step 2: Which currency
    @State private var currencyPreference: PreferredCurrency = .usd
    
    // Step 3: Starting Balance as a String
    @State private var startingBalanceText: String = "1,000"
    @State private var startingBalanceCurrencyForBoth: PreferredCurrency = .usd
    
    // Step 4: Average BTC Purchase Price
    @State private var averageCostBasis: Double = 58000
    
    // Step 5: BTC Price
    @State private var fetchedBTCPrice: String = "N/A"
    @State private var userBTCPrice: String = ""
    
    // Step 6: Single contribution
    @State private var contributionPerStep: Double = 100.0
    
    // Step 7: Withdrawals
    @State private var threshold1: Double = 30000
    @State private var withdraw1: Double = 0.0
    @State private var threshold2: Double = 60000
    @State private var withdraw2: Double = 0.0
    
    private let bottomPaddingNext: CGFloat       = 260
    private let bottomPaddingFinish: CGFloat     = 150
    private let bottomPaddingFinishBoth: CGFloat = 110
    
    private var bottomPaddingForStep: CGFloat {
        if currentStep != 8 {
            return bottomPaddingNext
        } else {
            if currencyPreference == .both {
                return bottomPaddingFinishBoth
            } else {
                return bottomPaddingFinish
            }
        }
    }
    
    // A simple formatter to re‐format “live”
    private let currencyFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = true
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "en_US")
        return nf
    }()
    
    // Convert the user’s typed string into a Double. If parsing fails, treat as zero.
    private var startingBalanceDouble: Double {
        let digitsOnly = startingBalanceText.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(digitsOnly) ?? 0
    }
    
    var body: some View {
        // 1) Decide how far to shift main content (titles/fields) for steps 0–7 vs. the final step (8)
        //    - We set it to -30 for steps 0..7 so they move up a bit more
        //    - On the final step, we bring them down (offset = 0) so there's more space from the bottom
        let offsetForContent: CGFloat = (currentStep == 8) ? 0 : -30

        ZStack {
            // 2) Background gradient that also dismisses numberPad when you tap away.
            //    We place the onTapGesture on the gradient so any tap outside the fields
            //    will call hideKeyboard().
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                // This dismisses the numberPad
                hideKeyboard()
            }

            // 3) Main content (titles, text fields, etc.), placed in a VStack.
            //    We apply .offset(y: offsetForContent) to shift it up or down based on the step.
            VStack(spacing: 20) {
                Text(titleForStep(currentStep))
                    .font(.title)
                    .foregroundColor(.white)
                
                // Optional subtitle
                if !subtitleForStep(currentStep).isEmpty {
                    Text(subtitleForStep(currentStep))
                        .foregroundColor(.gray)
                        .font(.callout)
                        // Slight negative top padding to tuck it closer if needed
                        .padding(.top, -2)
                }
                
                // Render different fields or text based on which step we are on
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
                
                // A bit of space below the dynamic content
                Spacer().frame(height: 20)
            }
            .offset(y: offsetForContent) // Moves the main content up (negative) or down
            .frame(maxWidth: .infinity)
        }
        // 4) The Bitcoin logo pinned at the top (so it never bobs up/down).
        //    We set top padding to 67 so it’s aligned with the back button's top padding.
        .overlay(
            OfficialBitcoinLogo()
                .frame(width: 80, height: 80)
                .padding(.top, 67),  // Adjust up/down if you want the logo higher/lower
            alignment: .top
        )
        // 5) Back button pinned top-left.
        //    We give it similar .padding(.top, 50) (or 67 if you want exact alignment with the logo),
        //    extra padding for a bigger tap area, and a high zIndex so it's above other overlays.
        .overlay(
            Group {
                if currentStep > 0 {
                    Button {
                        // Use a shorter animation to make transitions quicker
                        withAnimation(.easeOut(duration: 0.05)) {
                            currentStep -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)       // Extra padding for a larger tap area
                    }
                    .background(Color.clear)
                    .contentShape(Rectangle()) // Ensure the whole area is tappable
                    .padding(.top, 50)         // Move down from the very top
                    .padding(.leading, 20)
                    .zIndex(10)               // Ensure it's above any other overlay
                }
            },
            alignment: .topLeading
        )
        // 6) Next/Finish button pinned at the bottom with appropriate bottom padding.
        //    We also shorten the animation here so transitions are quicker.
        .overlay(
            Button(currentStep == 8 ? "Finish" : "Next") {
                withAnimation(.easeOut(duration: 0.15)) {
                    onNextTapped()
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(6)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
            .padding(.bottom, bottomPaddingForStep)
            .zIndex(5),
            alignment: .bottom
        )
        // 7) Keep the keyboard area safe, so it doesn't hide your fields
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // 8) If user changes from weekly to monthly, or vice versa, update totalPeriods
        .onChange(of: chosenPeriodUnit, initial: false) { _, newVal in
            if newVal == .months {
                totalPeriods = 240
            } else {
                totalPeriods = 1040
            }
        }
        // 9) On .task, fetch BTC price and possibly update cost basis
        .task {
            await fetchBTCPriceFromAPI()
            updateAverageCostBasisIfNeeded()
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
            Text(chosenPeriodUnit == .weeks ? "How many weeks?" : "How many months?")
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
            
            Picker("Currency", selection: $currencyPreference) {
                Text("USD").tag(PreferredCurrency.usd)
                Text("EUR").tag(PreferredCurrency.eur)
                Text("Both").tag(PreferredCurrency.both)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
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
            
            TextField("e.g. 1,000", text: $startingBalanceText)
                .keyboardType(.decimalPad)
                .padding(8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(6)
                .foregroundColor(.white)
                .frame(width: 200)
                .multilineTextAlignment(.center)
                .onChange(of: startingBalanceText, initial: false) { _, newValue in
                    let digitsOnly = newValue.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                    if let doubleVal = Double(digitsOnly) {
                        if let formatted = currencyFormatter.string(from: NSNumber(value: doubleVal)) {
                            if formatted != startingBalanceText {
                                startingBalanceText = formatted
                            }
                        }
                    } else {
                        if newValue != "" {
                            startingBalanceText = ""
                        }
                    }
                }
        }
    }
    
    // MARK: - Step 4
    private func step4_AverageCostBasis() -> some View {
        VStack(spacing: 20) {
            let currencyLabelForCostBasis = (currencyPreference == .eur) ? "EUR" : "USD"
            
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
            
            Text("(in \(currencyLabelForCostBasis))")
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Step 5
    private func step5_BTCPriceInput() -> some View {
        VStack(spacing: 16) {
            let currencyLabelForBTCPrice = (currencyPreference == .eur) ? "EUR" : "USD"
            
            Text("Fetched BTC Price (\(currencyLabelForBTCPrice)): \(fetchedBTCPrice)")
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
    
    // MARK: - Step 6
    private func step6_Contributions() -> some View {
        let frequencyWord = (chosenPeriodUnit == .weeks) ? "weekly" : "monthly"
        
        let placeholderText: String = {
            switch currencyPreference {
            case .usd:  return "$100.0"
            case .eur:  return "€100.0"
            case .both: return "100.0"
            }
        }()
        
        return VStack(spacing: 20) {
            if currencyPreference == .both  {
                Spacer().frame(height: 20)
                
                Text("Are these contributions in USD or EUR?")
                    .foregroundColor(.white)
                
                if chosenPeriodUnit == .months {
                    Picker("ContribCurrency",
                           selection: $monthlySimSettings.contributionCurrencyWhenBothMonthly) {
                        Text("USD").tag(PreferredCurrency.usd)
                        Text("EUR").tag(PreferredCurrency.eur)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                } else {
                    Picker("ContribCurrency",
                           selection: $weeklySimSettings.contributionCurrencyWhenBoth) {
                        Text("USD").tag(PreferredCurrency.usd)
                        Text("EUR").tag(PreferredCurrency.eur)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                
                HStack {
                    Text("\(frequencyWord.capitalized) Amount:")
                        .foregroundColor(.white)
                    TextField(placeholderText, value: $contributionPerStep, format: .number)
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
                    TextField(placeholderText, value: $contributionPerStep, format: .number)
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
    
    // MARK: - Step 7
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
                Text("Starting Bal: \(startingBalanceDouble, specifier: "%.2f")")
                
                Text("Avg. Cost Basis: \(averageCostBasis, specifier: "%.2f") \(currencyPreference == .eur ? "EUR" : "USD")")
                Text("BTC Price: \(finalBTCPrice, specifier: "%.2f") \(currencyPreference == .eur ? "EUR" : "USD")")
                
                if currencyPreference == .both {
                    if chosenPeriodUnit == .months {
                        Text("Contrib typed in: \(monthlySimSettings.contributionCurrencyWhenBothMonthly.rawValue)")
                    } else {
                        Text("Contrib typed in: \(weeklySimSettings.contributionCurrencyWhenBoth.rawValue)")
                    }
                }
                Text("Contribution: \(contributionPerStep, specifier: "%.0f")")
                
                Text("Withdraws: \(threshold1, specifier: "%.0f")→\(withdraw1, specifier: "%.0f"), \(threshold2, specifier: "%.0f")→\(withdraw2, specifier: "%.0f")")
            }
            .foregroundColor(.white)
        }
    }
    
    // MARK: - onNextTapped
    private func onNextTapped() {
        if currentStep == 8 {
            applySettingsToSim()
            didFinishOnboarding = true
        } else {
            withAnimation {
                currentStep += 1
            }
        }
    }
    
    // MARK: - applySettingsToSim
    private func applySettingsToSim() {
        if chosenPeriodUnit == .months {
            // Update monthly defaults
            monthlySimSettings.periodUnitMonthly = .months
            monthlySimSettings.userPeriodsMonthly = totalPeriods
            monthlySimSettings.initialBTCPriceUSDMonthly = finalBTCPrice
            monthlySimSettings.startingBalanceMonthly = startingBalanceDouble
            print("Onboarding set monthlySimSettings.startingBalanceMonthly to", monthlySimSettings.startingBalanceMonthly)
            monthlySimSettings.averageCostBasisMonthly = averageCostBasis
            monthlySimSettings.currencyPreferenceMonthly = currencyPreference

            if currencyPreference != .both {
                monthlySimSettings.contributionCurrencyWhenBothMonthly = currencyPreference
            }

            if currencyPreference == .both {
                monthlySimSettings.startingBalanceCurrencyWhenBothMonthly = startingBalanceCurrencyForBoth
            }

            inputManager.firstYearContribution  = String(contributionPerStep)
            inputManager.subsequentContribution = String(contributionPerStep)
            inputManager.threshold1      = threshold1
            inputManager.withdrawAmount1 = withdraw1
            inputManager.threshold2      = threshold2
            inputManager.withdrawAmount2 = withdraw2

            monthlySimSettings.saveToUserDefaultsMonthly()
            print("Just saved to user defaults, verifying =>", monthlySimSettings.startingBalanceMonthly)

            simSettings.periodUnit = .months
            simSettings.userPeriods = totalPeriods
            simSettings.initialBTCPriceUSD = finalBTCPrice
            simSettings.startingBalance = startingBalanceDouble
            simSettings.averageCostBasis = averageCostBasis
            simSettings.currencyPreference = currencyPreference

            coordinator.useMonthly = true

        } else {
            weeklySimSettings.periodUnit = .weeks
            weeklySimSettings.userPeriods = totalPeriods
            weeklySimSettings.initialBTCPriceUSD = finalBTCPrice
            weeklySimSettings.startingBalance    = startingBalanceDouble
            weeklySimSettings.averageCostBasis   = averageCostBasis
            weeklySimSettings.currencyPreference = currencyPreference
            monthlySimSettings.periodUnitMonthly = .weeks

            if currencyPreference == .both {
                weeklySimSettings.startingBalanceCurrencyWhenBoth = startingBalanceCurrencyForBoth
            }

            inputManager.firstYearContribution  = String(contributionPerStep)
            inputManager.subsequentContribution = String(contributionPerStep)
            inputManager.threshold1      = threshold1
            inputManager.withdrawAmount1 = withdraw1
            inputManager.threshold2      = threshold2
            inputManager.withdrawAmount2 = withdraw2

            weeklySimSettings.saveToUserDefaults()

            coordinator.useMonthly = false
        }

        // Save shared defaults
        UserDefaults.standard.set(startingBalanceDouble, forKey: "savedStartingBalance")
        UserDefaults.standard.set(averageCostBasis,      forKey: "savedAverageCostBasis")
        UserDefaults.standard.set(totalPeriods,          forKey: "savedUserPeriods")
        UserDefaults.standard.set(chosenPeriodUnit.rawValue, forKey: "savedPeriodUnit")
        UserDefaults.standard.set(finalBTCPrice,         forKey: "savedInitialBTCPriceUSD")

        print("// DEBUG: applySettingsToSim => periodUnit=\(chosenPeriodUnit.rawValue)")
        print("// DEBUG: totalPeriods=\(totalPeriods)")
        print("// DEBUG: currencyPreference=\(currencyPreference.rawValue)")
        print("// DEBUG: startingBalance=\(startingBalanceDouble)")
        print("// DEBUG: contributionPerStep=\(contributionPerStep)")
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
        let currencyToFetch = (currencyPreference == .eur) ? "eur" : "usd"
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=\(currencyToFetch)"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct SimplePriceResponse: Decodable {
                let bitcoin: [String: Double]
            }
            let decoded = try JSONDecoder().decode(SimplePriceResponse.self, from: data)
            
            if let price = decoded.bitcoin[currencyToFetch] {
                fetchedBTCPrice = String(format: "%.2f", price)
            } else {
                fetchedBTCPrice = "N/A"
            }
        } catch {
            fetchedBTCPrice = "N/A"
        }
    }
    
    private func updateAverageCostBasisIfNeeded() {
        guard averageCostBasis == 58000, let fetchedVal = Double(fetchedBTCPrice) else { return }
        averageCostBasis = fetchedVal
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
