//
//  OnboardingView.swift
//  BTCMonteCarlo
//
//  Created by Conor on 28/12/2024.
//

import SwiftUI
import UIKit

// MARK: - Enums (if not elsewhere)
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

// MARK: - Main View
struct OnboardingView: View {
    // Environment Objects
    @EnvironmentObject var weeklySimSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var coordinator: SimulationCoordinator
    @EnvironmentObject var simSettings: SimulationSettings
    
    @Binding var didFinishOnboarding: Bool
    
    // Steps 0..8
    @State var currentStep: Int = 0
    
    // Step 0
    @State var chosenPeriodUnit: PeriodUnit = .weeks
    
    // Step 1
    @State var totalPeriods: Int = 1040
    
    // Step 2
    @State var currencyPreference: PreferredCurrency = .usd
    
    // Step 3
    @State var startingBalanceText: String = "1,000"
    @State var startingBalanceCurrencyForBoth: PreferredCurrency = .usd
    
    // Step 4
    @State var averageCostBasis: Double = 58000
    
    // Step 5
    @State var fetchedBTCPrice: String = "N/A"
    @State var userBTCPrice: String = ""
    
    // Step 6
    @State var contributionPerStep: Double = 100.0
    @State var feePercentage: Double = 0.6
    
    // Step 7
    @State var threshold1: Double = 30000
    @State var withdraw1: Double = 0.0
    @State var threshold2: Double = 60000
    @State var withdraw2: Double = 0.0
    
    // Layout
    let bottomPaddingNext: CGFloat       = 260
    let bottomPaddingFinish: CGFloat     = 150
    let bottomPaddingFinishBoth: CGFloat = 110
    
    // A formatter for re-formatting
    let currencyFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = true
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "en_US")
        return nf
    }()
    
    // We track device orientation, but let iOS handle rotation automatically
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    
    // MARK: - Computed
    var startingBalanceDouble: Double {
        let digitsOnly = startingBalanceText
            .replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Double(digitsOnly) ?? 0
    }
    
    var finalBTCPrice: Double {
        if let typedVal = Double(userBTCPrice), typedVal > 0 {
            return typedVal
        }
        if let fetchedVal = Double(fetchedBTCPrice), fetchedVal > 0 {
            return fetchedVal
        }
        return 58000
    }
    
    // We'll consider deviceOrientation just in case we want it for logic,
    // but iOS handles rotation for us (no manual rotationEffect).
    var isLandscape: Bool {
        if deviceOrientation.isValidInterfaceOrientation {
            return deviceOrientation.isLandscape
        } else {
            return UIScreen.main.bounds.width > UIScreen.main.bounds.height
        }
    }
    
    var body: some View {
        // The offset used to shift content up a bit for the first 8 steps
        let offsetForContent: CGFloat = (currentStep == 8) ? 0 : -30
        
        // Decide how far from the bottom the Next/Finish button is in portrait
        // (or used if in portrait?). The user’s code also uses it in portrait logic.
        let bottomPaddingForStep: CGFloat = {
            if currentStep != 8 {
                return bottomPaddingNext
            } else {
                return (currencyPreference == .both)
                    ? bottomPaddingFinishBoth
                    : bottomPaddingFinish
            }
        }()
        
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(white: 0.15), Color.black]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                hideKeyboard()
            }
            
            // Main step content
            VStack(spacing: 20) {
                Text(titleForStep(currentStep))
                    .font(.title)
                    .foregroundColor(.white)
                
                if !subtitleForStep(currentStep).isEmpty {
                    Text(subtitleForStep(currentStep))
                        .foregroundColor(.gray)
                        .font(.callout)
                        .padding(.top, -2)
                }
                
                // Show the current step subview
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
                
                Spacer().frame(height: 20)
            }
            // Shift entire step content up a bit if not final step
            .offset(y: offsetForContent)
            .frame(maxWidth: .infinity)
        }
        // Overlays for *portrait* only, as your original code
        // We do NOT rotate them ourselves; iOS auto-rotates them.
        .overlay(
            portraitLogoOverlay,
            alignment: .top
        )
        .overlay(
            portraitBackButtonOverlay,
            alignment: .topLeading
        )
        .overlay(
            portraitNextOverlay(bottomPaddingForStep),
            alignment: .bottom
        )
        
        // Overlays for *landscape* only
        .overlay(
            landscapeOverlay
        )
        
        // If user picks weeks->months or vice versa
        .onChange(of: chosenPeriodUnit, initial: false) { _, newVal in
            if newVal == .months {
                totalPeriods = 240
            } else {
                totalPeriods = 1040
            }
        }
        // Listen for orientation changes, but do NOT forcibly rotate anything
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let newOrientation = UIDevice.current.orientation
                guard newOrientation.isValidInterfaceOrientation else { return }
                // We just store it, no manual rotation
                deviceOrientation = newOrientation
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .task {
            // fetch BTC price
            await fetchBTCPriceFromAPI()
            updateAverageCostBasisIfNeeded()
        }
    }
}

// MARK: - Portrait Overlays
extension OnboardingView {
    @ViewBuilder
    var portraitLogoOverlay: some View {
        // Show only if not in landscape
        if !isLandscape {
            OfficialBitcoinLogo()
                .frame(width: 80, height: 80)
                // If you want to move the logo left, or up/down, tweak these paddings:
                // Right now it's top-centred, .padding(.top, 67).
                .padding(.top, 67)
        }
    }
    
    @ViewBuilder
    var portraitBackButtonOverlay: some View {
        // Show only in portrait if currentStep > 0
        if !isLandscape, currentStep > 0 {
            Button {
                withAnimation(.easeOut(duration: 0.05)) {
                    currentStep -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(10)
            }
            // If you want to move it further left or up, adjust .padding here:
            .padding(.top, 50)
            .padding(.leading, 20)
        }
    }
    
    @ViewBuilder
    func portraitNextOverlay(_ bottomPaddingForStep: CGFloat) -> some View {
        // Show only in portrait
        if !isLandscape {
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
            // If you want the Next button to come *down* a bit, reduce the
            // bottom padding or add a negative offset. For example:
            .padding(.bottom, bottomPaddingForStep - 0)
            // ^ For example, you could change "- 0" to "- 20" or remove it
            // altogether to place the button lower in portrait.
        }
    }
}

// MARK: - Landscape Overlays
extension OnboardingView {
    @ViewBuilder
    var landscapeOverlay: some View {
        // Show only if in landscape
        if isLandscape {
            ZStack {
                // If not on step0, show a back button top-left
                if currentStep > 0 {
                    Button {
                        withAnimation(.easeOut(duration: 0.05)) {
                            currentStep -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                    }
                    .padding(.top, 50)
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                
                // The logo on the left in landscape. If you want it further left,
                // increase .padding(.leading). If you want it further up or down,
                // add .padding(.top) or .offset.
                OfficialBitcoinLogo()
                    .frame(width: 80, height: 80)
                    .padding(.leading, 50)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                
                // Next/Finish on the right in landscape
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
                .padding(.trailing, 50)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
    }
}

// MARK: - Helpers
extension OnboardingView {
    func onNextTapped() {
        if currentStep == 8 {
            applySettingsToSim()
            didFinishOnboarding = true
        } else {
            currentStep += 1
        }
    }
    
    func applySettingsToSim() {
        if chosenPeriodUnit == .months {
            monthlySimSettings.periodUnitMonthly         = .months
            monthlySimSettings.userPeriodsMonthly        = totalPeriods
            monthlySimSettings.initialBTCPriceUSDMonthly = finalBTCPrice
            monthlySimSettings.startingBalanceMonthly    = startingBalanceDouble
            monthlySimSettings.averageCostBasisMonthly   = averageCostBasis
            monthlySimSettings.currencyPreferenceMonthly = currencyPreference
            monthlySimSettings.feePercentageMonthly      = feePercentage

            inputManager.firstYearContribution  = String(contributionPerStep)
            inputManager.threshold1             = threshold1
            inputManager.withdrawAmount1        = withdraw1
            inputManager.threshold2             = threshold2
            inputManager.withdrawAmount2        = withdraw2

            monthlySimSettings.saveToUserDefaultsMonthly()
            simSettings.periodUnit = .months
            simSettings.userPeriods = totalPeriods  // Add this
            coordinator.useMonthly = true
        } else {
            monthlySimSettings.periodUnitMonthly = .weeks
            monthlySimSettings.userPeriodsMonthly = 1040  // Reset to avoid stale data

            weeklySimSettings.periodUnit         = .weeks
            weeklySimSettings.userPeriods        = totalPeriods
            weeklySimSettings.initialBTCPriceUSD = finalBTCPrice
            weeklySimSettings.startingBalance    = startingBalanceDouble
            weeklySimSettings.averageCostBasis   = averageCostBasis
            weeklySimSettings.currencyPreference = currencyPreference
            weeklySimSettings.feePercentage      = feePercentage

            weeklySimSettings.saveToUserDefaults()
            simSettings.periodUnit = .weeks
            simSettings.userPeriods = totalPeriods
            coordinator.useMonthly = false
        }

        // Force UserDefaults sync
        UserDefaults.standard.set(chosenPeriodUnit.rawValue, forKey: "savedPeriodUnit")
        UserDefaults.standard.set(totalPeriods, forKey: "savedUserPeriods")
        UserDefaults.standard.set(finalBTCPrice, forKey: "savedInitialBTCPriceUSD")
        UserDefaults.standard.set(startingBalanceDouble, forKey: "savedStartingBalance")
        UserDefaults.standard.set(averageCostBasis, forKey: "savedAverageCostBasis")
        UserDefaults.standard.set(feePercentage, forKey: "savedFeePercentage")
        UserDefaults.standard.synchronize()  // Ensure immediate write
    }
    
    func fetchBTCPriceFromAPI() async {
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
    
    func updateAverageCostBasisIfNeeded() {
        guard averageCostBasis == 58000,
              let fetchedVal = Double(fetchedBTCPrice) else { return }
        averageCostBasis = fetchedVal
    }
    
    func titleForStep(_ step: Int) -> String {
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
    
    func subtitleForStep(_ step: Int) -> String {
        switch step {
        case 0: return "Pick weekly or monthly"
        case 1: return "How many \(chosenPeriodUnit.rawValue)?"
        case 2: return "USD, EUR, or Both?"
        case 4: return "What did you pay for BTC before?"
        case 5: return "Fetch or type current BTC price"
        case 7: return "Set your withdrawal triggers"
        default: return ""
        }
    }
}

// MARK: - Hide Keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
