//
//  SimulationData.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

//
// SimulationData.swift
// BTCMonteCarloSimulator
//

import Foundation

struct SimulationData: Identifiable {
    let id: UUID
    let week: Int
    let cyclePhase: String
    let startingBTC: Double
    let btcGrowth: Double
    let netBTCHoldings: Double
    let btcPriceUSD: Double
    let btcPriceEUR: Double
    let portfolioValueEUR: Double
    let contributionEUR: Double
    let contributionFeeEUR: Double
    let netContributionBTC: Double
    let withdrawalEUR: Double
    let portfolioPreWithdrawalEUR: Double

    // Static placeholder for default data
    static let placeholder = SimulationData(
        id: UUID(), // Added id field
        week: 0,
        cyclePhase: "N/A",
        startingBTC: 0.0,
        btcGrowth: 0.0,
        netBTCHoldings: 0.0,
        btcPriceUSD: 0.0,
        btcPriceEUR: 0.0,
        portfolioValueEUR: 0.0,
        contributionEUR: 0.0,
        contributionFeeEUR: 0.0,
        netContributionBTC: 0.0,
        withdrawalEUR: 0.0,
        portfolioPreWithdrawalEUR: 0.0
    )

    // Initializer
    init(
        id: UUID = UUID(),
        week: Int,
        cyclePhase: String,
        startingBTC: Double,
        btcGrowth: Double,
        netBTCHoldings: Double,
        btcPriceUSD: Double,
        btcPriceEUR: Double,
        portfolioValueEUR: Double,
        contributionEUR: Double,
        contributionFeeEUR: Double,
        netContributionBTC: Double,
        withdrawalEUR: Double,
        portfolioPreWithdrawalEUR: Double
    ) {
        self.id = id
        self.week = week
        self.cyclePhase = cyclePhase
        self.startingBTC = startingBTC
        self.btcGrowth = btcGrowth
        self.netBTCHoldings = netBTCHoldings
        self.btcPriceUSD = btcPriceUSD
        self.btcPriceEUR = btcPriceEUR
        self.portfolioValueEUR = portfolioValueEUR
        self.contributionEUR = contributionEUR
        self.contributionFeeEUR = contributionFeeEUR
        self.netContributionBTC = netContributionBTC
        self.withdrawalEUR = withdrawalEUR
        self.portfolioPreWithdrawalEUR = portfolioPreWithdrawalEUR
    }
}
