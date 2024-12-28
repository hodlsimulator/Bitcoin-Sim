//
//  OnboardingView.swift
//  BTCMonteCarlo
//
//  Created by . . on 28/12/2024.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    // If you have a SimulationSettings or similar model, you can inject it here:
    // @EnvironmentObject var simSettings: SimulationSettings

    /// The current onboarding step, from 0...N
    @State private var currentStep: Int = 0
    
    @Binding var didFinishOnboarding: Bool

    /// Temporary storage for user inputs. Move them into your real settings model later.
    @State private var preferredCurrency: String = "USD"
    @State private var fetchedBTCPrice: String = ""
    @State private var userSpecifiedBTCPrice: String = ""
    @State private var simulationWeeks: Int = 52

    var body: some View {
        ZStack {
            // Background gradient
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

            // Main content
            VStack {
                Spacer().frame(height: 40)

                // Title
                Text("Welcome to HODL Simulator")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                // Subheadline
                Text(subtitle(forStep: currentStep))
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

                Spacer().frame(height: 30)

                // Step content
                switch currentStep {
                case 0:
                    step0_Welcome()
                case 1:
                    step1_SelectCurrency()
                case 2:
                    step2_BTCPriceEntry()
                case 3:
                    step3_NumberOfWeeks()
                default:
                    step4_ConfirmFinish()
                }

                Spacer()

                // Navigation controls
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

                    Button(nextButtonTitle(forStep: currentStep)) {
                        withAnimation {
                            onNextTapped()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Optionally fetch BTC price in the background
            fetchBTCPrice()
        }
    }

    // MARK: - Step 0
    private func step0_Welcome() -> some View {
        VStack(spacing: 20) {
            // Replace the system image with the official BTC logo
            OfficialBitcoinLogo()
                // .frame(width: 120, height: 120) // optional, since OfficialBitcoinLogo itself has a fixed size

            Text("This short wizard helps set up your preferences.\nTap **Next** to continue.")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
    }

    // MARK: - Step 1: Select currency
    private func step1_SelectCurrency() -> some View {
        VStack(spacing: 24) {
            Text("Select your preferred currency")
                .foregroundColor(.white)
                .font(.headline)
            Picker("Currency", selection: $preferredCurrency) {
                Text("USD").tag("USD")
                Text("EUR").tag("EUR")
                Text("Both").tag("Both")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Step 2: BTC Price Entry
    private func step2_BTCPriceEntry() -> some View {
        VStack(spacing: 24) {
            Text("Fetched BTC Price: \(fetchedBTCPrice)")
                .foregroundColor(.white)

            Text("Or enter your own BTC Price (Week 1)")
                .foregroundColor(.white)
                .font(.headline)

            TextField("e.g. 27000", text: $userSpecifiedBTCPrice)
                .keyboardType(.decimalPad)
                .padding(8)
                .background(Color.white)
                .cornerRadius(6)
                .foregroundColor(.black)
                .frame(width: 200)
        }
    }

    // MARK: - Step 3: Number of weeks
    private func step3_NumberOfWeeks() -> some View {
        VStack(spacing: 16) {
            Text("How many weeks do you plan to simulate?")
                .foregroundColor(.white)
                .font(.headline)

            HStack {
                TextField("e.g. 52", value: $simulationWeeks, format: .number)
                    .keyboardType(.numberPad)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(6)
                    .foregroundColor(.black)
                    .frame(width: 100)
            }
        }
    }

    // MARK: - Step 4: Confirmation
    private func step4_ConfirmFinish() -> some View {
        VStack(spacing: 16) {
            Text("Review & Confirm")
                .foregroundColor(.white)
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Text("Currency: \(preferredCurrency)")
                Text("BTC Price: \(userChosenBTCPrice())")
                Text("Weeks: \(simulationWeeks)")
            }
            .foregroundColor(.white)

            Text("Tap **Finish** to apply these settings.")
                .foregroundColor(.gray)
                .font(.subheadline)
                .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    /// A short subtitle for each step
    private func subtitle(forStep step: Int) -> String {
        switch step {
        case 0: return "Quick wizard to set up your preferences"
        case 1: return "Pick a default currency"
        case 2: return "We can fetch or override your BTC price"
        case 3: return "Specify how many weeks to simulate"
        case 4: return "Final check"
        default: return ""
        }
    }

    /// The label for the Next button
    private func nextButtonTitle(forStep step: Int) -> String {
        if step == 4 {
            return "Finish"
        } else {
            return "Next"
        }
    }

    /// Called whenever user taps the Next button
    private func onNextTapped() {
        print("Current step: \(currentStep)")
        if currentStep == 4 {
            print("Finish tapped! Setting didFinishOnboarding to true.")
            didFinishOnboarding = true
        } else {
            currentStep += 1
        }
    }

    /// If userSpecifiedBTCPrice is empty, fallback to fetchedBTCPrice
    private func userChosenBTCPrice() -> String {
        return userSpecifiedBTCPrice.isEmpty ? fetchedBTCPrice : userSpecifiedBTCPrice
    }

    /// Fake a fetch call—here we just set a dummy price after 1s
    private func fetchBTCPrice() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // In production, you’d call a real API (CoinGecko, etc.)
            self.fetchedBTCPrice = "27654.12"
        }
    }
}
