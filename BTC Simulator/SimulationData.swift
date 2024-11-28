//
//  SimulationData.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

struct SimulationData: Identifiable {
    let id: UUID
    let week: Int
    let startingBTC: Double
    let netBTCHoldings: Double
    let btcPriceUSD: Double
    let btcPriceEUR: Double
    let portfolioValueEUR: Double
    let contributionEUR: Double
    let contributionFeeEUR: Double
    let netContributionBTC: Double
    let withdrawalEUR: Double

    // Static placeholder for default data
    static let placeholder = SimulationData(
        id: UUID(),
        week: 0,
        startingBTC: 0.0,
        netBTCHoldings: 0.0,
        btcPriceUSD: 0.0,
        btcPriceEUR: 0.0,
        portfolioValueEUR: 0.0,
        contributionEUR: 0.0,
        contributionFeeEUR: 0.0,
        netContributionBTC: 0.0,
        withdrawalEUR: 0.0
        
    )

    // Updated initializer
    init(
        id: UUID = UUID(),
        week: Int,
        startingBTC: Double,
        netBTCHoldings: Double,
        btcPriceUSD: Double,
        btcPriceEUR: Double,
        portfolioValueEUR: Double,
        contributionEUR: Double,
        contributionFeeEUR: Double,
        netContributionBTC: Double,
        withdrawalEUR: Double
    ) {
        self.id = id
        self.week = week
        self.startingBTC = startingBTC
        self.netBTCHoldings = netBTCHoldings
        self.btcPriceUSD = btcPriceUSD
        self.btcPriceEUR = btcPriceEUR
        self.portfolioValueEUR = portfolioValueEUR
        self.contributionEUR = contributionEUR
        self.contributionFeeEUR = contributionFeeEUR
        self.netContributionBTC = netContributionBTC
        self.withdrawalEUR = withdrawalEUR
    }
}
