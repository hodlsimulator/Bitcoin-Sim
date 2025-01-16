//
//  SimulationData.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

struct SimulationData: Identifiable {
    var id: Int { week }

    var week: Int
    let startingBTC: Double
    let netBTCHoldings: Double

    // BTC prices in both currencies
    let btcPriceUSD: Decimal
    let btcPriceEUR: Decimal

    // Portfolio values in both currencies
    let portfolioValueEUR: Decimal
    let portfolioValueUSD: Decimal

    // Contributions in both currencies
    let contributionEUR: Double
    let contributionUSD: Double

    // Fees in both currencies
    let transactionFeeEUR: Double
    let transactionFeeUSD: Double

    // Net contribution in BTC
    let netContributionBTC: Double

    // Withdrawals in both currencies
    let withdrawalEUR: Double
    let withdrawalUSD: Double

    static let placeholder = SimulationData(
        week: 0,
        startingBTC: 0.0,
        netBTCHoldings: 0.0,
        btcPriceUSD: .zero,
        btcPriceEUR: .zero,
        portfolioValueEUR: .zero,
        portfolioValueUSD: .zero,
        contributionEUR: 0.0,
        contributionUSD: 0.0,
        transactionFeeEUR: 0.0,
        transactionFeeUSD: 0.0,
        netContributionBTC: 0.0,
        withdrawalEUR: 0.0,
        withdrawalUSD: 0.0
    )

    init(
        week: Int,
        startingBTC: Double,
        netBTCHoldings: Double,
        btcPriceUSD: Decimal,
        btcPriceEUR: Decimal,
        portfolioValueEUR: Decimal,
        portfolioValueUSD: Decimal,
        contributionEUR: Double,
        contributionUSD: Double,
        transactionFeeEUR: Double,
        transactionFeeUSD: Double,
        netContributionBTC: Double,
        withdrawalEUR: Double,
        withdrawalUSD: Double
    ) {
        self.week = week
        self.startingBTC = startingBTC
        self.netBTCHoldings = netBTCHoldings
        self.btcPriceUSD = btcPriceUSD
        self.btcPriceEUR = btcPriceEUR
        self.portfolioValueEUR = portfolioValueEUR
        self.portfolioValueUSD = portfolioValueUSD
        self.contributionEUR = contributionEUR
        self.contributionUSD = contributionUSD
        self.transactionFeeEUR = transactionFeeEUR
        self.transactionFeeUSD = transactionFeeUSD
        self.netContributionBTC = netContributionBTC
        self.withdrawalEUR = withdrawalEUR
        self.withdrawalUSD = withdrawalUSD
    }
}
