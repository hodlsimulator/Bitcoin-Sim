//
//  OnboardingSteps.swift
//  BTCMonteCarlo
//
//  Created by . . on 16/02/2025.
//

import SwiftUI

extension OnboardingView {
    
    // MARK: - Step 0
    func step0_PeriodFrequency() -> some View {
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
    func step1_TotalPeriods() -> some View {
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
    func step2_PickCurrency() -> some View {
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
    func step3_StartingBalance() -> some View {
        VStack(spacing: 20) {
            if currencyPreference == .both {
                Text("Starting Balance")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Text("Are you entering your balance in USD or EUR?")
                    .foregroundColor(.white)
                
                Picker("StartBalCurrency", selection: $startingBalanceCurrencyForBoth) {
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
                .onChange(of: startingBalanceText) { newValue in
                    // Example live formatting
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
    func step4_AverageCostBasis() -> some View {
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
    func step5_BTCPriceInput() -> some View {
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
    func step6_Contributions() -> some View {
        let frequencyWord = (chosenPeriodUnit == .weeks) ? "weekly" : "monthly"
        
        let placeholderText: String = {
            switch currencyPreference {
            case .usd:  return "$100.0"
            case .eur:  return "€100.0"
            case .both: return "100.0"
            }
        }()
        
        return VStack(spacing: 20) {
            if currencyPreference == .both {
                Spacer().frame(height: 20)
                
                Text("Are these contributions in USD or EUR?")
                    .foregroundColor(.white)
                
                if chosenPeriodUnit == .months {
                    Picker("ContribCurrency", selection: $monthlySimSettings.contributionCurrencyWhenBothMonthly) {
                        Text("USD").tag(PreferredCurrency.usd)
                        Text("EUR").tag(PreferredCurrency.eur)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                } else {
                    Picker("ContribCurrency", selection: $weeklySimSettings.contributionCurrencyWhenBoth) {
                        Text("USD").tag(PreferredCurrency.usd)
                        Text("EUR").tag(PreferredCurrency.eur)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                
                VStack(spacing: 10) {
                    // 1) Amount row
                    HStack {
                        Text("\(frequencyWord.capitalized) Amount:")
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField(placeholderText, value: $contributionPerStep, format: .number)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                    
                    // 2) Fees row
                    HStack {
                        Text("Fees (%):")
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField("0.6", value: $feePercentage, format: .number)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                }
                
            } else {
                Spacer().frame(height: 20)
                
                Text("Contribution Setup")
                    .foregroundColor(.white)
                    .font(.headline)
                
                Text("Enter your \(frequencyWord) contribution amount")
                    .foregroundColor(.gray)
                
                VStack(spacing: 10) {
                    // 1) Amount row
                    HStack {
                        Text("\(frequencyWord.capitalized) Amount:")
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField(placeholderText, value: $contributionPerStep, format: .number)
                            .keyboardType(.decimalPad)
                            .padding(8)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .frame(width: 80)
                    }
                    
                    // 2) Fees row
                    HStack {
                        Text("Fees (%):")
                            .foregroundColor(.white)
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField("0.6", value: $feePercentage, format: .number)
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
        .offset(y: -20)
    }
    
    // MARK: - Step 7
    func step7_Withdrawals() -> some View {
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
    func step8_ReviewAndFinish() -> some View {
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
                
                Text("Contribution: \(contributionPerStep, specifier: "%.2f")")
                Text("Fees (%): \(feePercentage, specifier: "%.2f")")
                Text("Withdrawals: \(threshold1, specifier: "%.0f")→\(withdraw1, specifier: "%.0f"), \(threshold2, specifier: "%.0f")→\(withdraw2, specifier: "%.0f")")
            }
            .foregroundColor(.white)
        }
        .offset(y: 50) // Moved down slightly
    }
}
