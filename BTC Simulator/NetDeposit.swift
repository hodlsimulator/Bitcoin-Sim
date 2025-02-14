//
//  NetDeposit.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/01/2025.
//

import Foundation

/// Applies a transaction fee, plus currency conversion, returning net BTC.
/// The `settings.feePercentage` is expected to be something like 0.6 for 0.6%.
func computeNetDeposit(
    typedDeposit: Double,
    settings: SimulationSettings,
    btcPriceUSD: Double,
    btcPriceEUR: Double
) -> (
    feeEUR: Double,
    feeUSD: Double,
    netContribEUR: Double,
    netContribUSD: Double,
    netBTC: Double
) {
    // If deposit is zero or negative, just return zeros.
    guard typedDeposit > 0 else {
        return (0, 0, 0, 0, 0)
    }
    
    // Convert user input into a decimal (e.g. 0.6 => 0.006).
    let feeRate = settings.feePercentage / 100.0

    switch settings.currencyPreference {
    case .usd:
        // If deposit is in USD:
        let fee = typedDeposit * feeRate
        let netUSD = typedDeposit - fee
        let netBTC = netUSD / btcPriceUSD
        return (0.0, fee, 0.0, netUSD, netBTC)
        
    case .eur:
        // If deposit is in EUR:
        let fee = typedDeposit * feeRate
        let netEUR = typedDeposit - fee
        let netBTC = netEUR / btcPriceEUR
        return (fee, 0.0, netEUR, 0.0, netBTC)
        
    case .both:
        // If user has "both" for currency, check which sub‐currency they're using right now
        if settings.contributionCurrencyWhenBoth == .eur {
            let fee = typedDeposit * feeRate
            let netEUR = typedDeposit - fee
            let netBTC = netEUR / btcPriceEUR
            return (fee, 0.0, netEUR, 0.0, netBTC)
        } else {
            let fee = typedDeposit * feeRate
            let netUSD = typedDeposit - fee
            let netBTC = netUSD / btcPriceUSD
            return (0.0, fee, 0.0, netUSD, netBTC)
        }
    }
}

/// Same idea, but for monthly logic.
/// The `monthlySettings.feePercentageMonthly` is similarly user typed, e.g. 0.6 => 0.6%.
func computeNetDepositMonthly(
    typedDeposit: Double,
    monthlySettings: MonthlySimulationSettings,
    btcPriceUSD: Double,
    btcPriceEUR: Double
) -> (
    feeEUR: Double,
    feeUSD: Double,
    netContribEUR: Double,
    netContribUSD: Double,
    netBTC: Double
) {
    guard typedDeposit > 0 else {
        return (0, 0, 0, 0, 0)
    }

    // Convert user input into decimal (e.g. 0.6 => 0.006).
    let feeRate = monthlySettings.feePercentageMonthly / 100.0

    switch monthlySettings.currencyPreferenceMonthly {
    case .usd:
        let fee = typedDeposit * feeRate
        let netUSD = typedDeposit - fee
        let netBTC = netUSD / btcPriceUSD
        return (0.0, fee, 0.0, netUSD, netBTC)
        
    case .eur:
        let fee = typedDeposit * feeRate
        let netEUR = typedDeposit - fee
        let netBTC = netEUR / btcPriceEUR
        return (fee, 0.0, netEUR, 0.0, netBTC)
        
    case .both:
        // If monthly currency is "both," pick the user’s chosen sub‐currency
        switch monthlySettings.contributionCurrencyWhenBothMonthly {
        case .eur:
            let fee = typedDeposit * feeRate
            let netEUR = typedDeposit - fee
            let netBTC = netEUR / btcPriceEUR
            return (fee, 0.0, netEUR, 0.0, netBTC)
        case .usd:
            let fee = typedDeposit * feeRate
            let netUSD = typedDeposit - fee
            let netBTC = netUSD / btcPriceUSD
            return (0.0, fee, 0.0, netUSD, netBTC)
        case .both:
            // If you ever allow "both" for sub‐currency as well, handle it or pick a default
            let fee = typedDeposit * feeRate
            let netUSD = typedDeposit - fee
            let netBTC = netUSD / btcPriceUSD
            return (0.0, fee, 0.0, netUSD, netBTC)
        }
    }
}
