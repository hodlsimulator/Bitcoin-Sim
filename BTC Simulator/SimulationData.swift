// SimulationData.swift
// BTCMonteCarloSimulator
//
// Created by Conor on 20/11/2024.
//

import Foundation

struct SimulationData: Identifiable {
    var id: Int { week }

    let week: Int
    let startingBTC: Double
    let netBTCHoldings: Double

    // The following are Decimals:
    let btcPriceUSD: Decimal
    let btcPriceEUR: Decimal
    let portfolioValueEUR: Decimal

    // The following remain Doubles:
    let contributionEUR: Double
    let transactionFeeEUR: Double
    let netContributionBTC: Double
    let withdrawalEUR: Double

    static let placeholder = SimulationData(
        week: 0,
        startingBTC: 0.0,
        netBTCHoldings: 0.0,
        btcPriceUSD: .zero,
        btcPriceEUR: .zero,
        portfolioValueEUR: .zero,
        contributionEUR: 0.0,
        transactionFeeEUR: 0.0,
        netContributionBTC: 0.0,
        withdrawalEUR: 0.0
    )

    init(
        week: Int,
        startingBTC: Double,
        netBTCHoldings: Double,
        btcPriceUSD: Decimal,
        btcPriceEUR: Decimal,
        portfolioValueEUR: Decimal,
        contributionEUR: Double,
        transactionFeeEUR: Double,
        netContributionBTC: Double,
        withdrawalEUR: Double
    ) {
        self.week = week
        self.startingBTC = startingBTC
        self.netBTCHoldings = netBTCHoldings
        self.btcPriceUSD = btcPriceUSD
        self.btcPriceEUR = btcPriceEUR
        self.portfolioValueEUR = portfolioValueEUR
        self.contributionEUR = contributionEUR
        self.transactionFeeEUR = transactionFeeEUR
        self.netContributionBTC = netContributionBTC
        self.withdrawalEUR = withdrawalEUR
    }
}
