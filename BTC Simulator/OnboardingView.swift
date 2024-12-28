//
//  OnboardingView.swift
//  BTCMonteCarlo
//
//  Created by . . on 28/12/2024.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss

    // 1) Make sure SimulationSettings includes:
    //    @Published var userWeeks: Int = 52
    //    @Published var initialBTCPriceUSD: Double = 58000.0
    // then uncomment the next line so we can store the final user inputs.
    @EnvironmentObject var simSettings: SimulationSettings

    /// Whether we've finished onboarding (bound to the parent)
    @Binding var didFinishOnboarding: Bool

    /// The current onboarding step, from 0...N
    @State private var currentStep: Int = 0

    // MARK: - Onboarding Fields
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

            VStack {
                Spacer().frame(height: 40)

                Text("Welcome to HODL Simulator")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle(forStep: currentStep))
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.top, 4)

                Spacer().frame(height: 30)

                // Show different UI for each onboarding step
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
        // Fetch BTC price once on appear
        .task {
            await fetchBTCPriceAsync()
        }
    }

    // MARK: - Step 0
    private func step0_Welcome() -> some View {
        VStack(spacing: 20) {
            OfficialBitcoinLogo()
            Text("This short wizard helps set up your preferences.\nTap **Next** to continue.")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 40)
    }

    // MARK: - Step 1
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

    // MARK: - Step 2
    private func step2_BTCPriceEntry() -> some View {
        VStack(spacing: 24) {
            Text("Fetched BTC Price: \(fetchedBTCPrice)")
                .foregroundColor(.white)

            Text("Or enter your own BTC Price (Week 1)")
                .foregroundColor(.white)
                .font(.headline)

            TextField("e.g. 58000", text: $userSpecifiedBTCPrice)
                .keyboardType(.decimalPad)
                .padding(8)
                .background(Color.white)
                .cornerRadius(6)
                .foregroundColor(.black)
                .frame(width: 200)
        }
    }

    // MARK: - Step 3
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

    // MARK: - Step 4
    private func step4_ConfirmFinish() -> some View {
        VStack(spacing: 16) {
            Text("Review & Confirm")
                .foregroundColor(.white)
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                Text("Currency: \(preferredCurrency)")
                Text("BTC Price (Week 1): \(finalDisplayPrice())")
                Text("Weeks: \(simulationWeeks)")
            }
            .foregroundColor(.white)

            Text("Tap **Finish** to apply these settings.")
                .foregroundColor(.gray)
                .font(.subheadline)
                .padding(.top, 8)
        }
    }

    // MARK: - Onboarding Step Logic
    private func onNextTapped() {
        print("Current step: \(currentStep)")
        if currentStep == 4 {
            print("Finish tapped! Setting didFinishOnboarding to true.")

            // If you've @EnvironmentObject var simSettings,
            // store the final price + weeks for the simulation:
            simSettings.initialBTCPriceUSD = finalPriceForSimulation
            simSettings.userWeeks = simulationWeeks

            // You could also store userCurrency if you want:
            // simSettings.userCurrency = preferredCurrency

            didFinishOnboarding = true
        } else {
            currentStep += 1
        }
    }
    
    // MARK: - This var provides a numeric price for the sim
    private var finalPriceForSimulation: Double {
        if let typedVal = Double(userSpecifiedBTCPrice), typedVal > 0 {
            return typedVal
        }
        if let fetchedVal = Double(fetchedBTCPrice), fetchedVal > 0 {
            return fetchedVal
        }
        return 58000
    }

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

    private func nextButtonTitle(forStep step: Int) -> String {
        (step == 4) ? "Finish" : "Next"
    }

    /// The displayed BTC price on the final step
    private func finalDisplayPrice() -> String {
        if let typedVal = Double(userSpecifiedBTCPrice), typedVal > 0 {
            return String(format: "%.2f", typedVal)
        }
        if let fetchedVal = Double(fetchedBTCPrice), fetchedVal > 0 {
            return String(format: "%.2f", fetchedVal)
        }
        return "58000"
    }

    // If you need a numeric Double for the sim, just make a var:
    // var finalPriceForSimulation: Double {
    //     if let typedVal = Double(userSpecifiedBTCPrice), typedVal > 0 { return typedVal }
    //     if let fetchedVal = Double(fetchedBTCPrice), fetchedVal > 0 { return fetchedVal }
    //     return 58000
    // }

    // MARK: - CoinGecko Fetch
    private func fetchBTCPriceInUSD() async throws -> Double {
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        struct SimplePriceResponse: Decodable {
            let bitcoin: [String: Double]
        }
        let decoded = try JSONDecoder().decode(SimplePriceResponse.self, from: data)
        guard let price = decoded.bitcoin["usd"] else {
            throw URLError(.cannotParseResponse)
        }
        return price
    }

    private func fetchBTCPriceAsync() async {
        do {
            let price = try await fetchBTCPriceInUSD()
            fetchedBTCPrice = String(format: "%.2f", price)
            print("Fetched BTC price: \(fetchedBTCPrice)")
        } catch {
            print("Failed to fetch BTC price:", error)
            fetchedBTCPrice = "N/A"
        }
    }
}
