//
//  SimulationData.swift
//  BTCMonteCarloSimulator
//
//  Created by Conor on 20/11/2024.
//

import Foundation

struct SimulationData: Codable, Identifiable {
    let id: UUID
    var week: Int
    var cyclePhase: String
    var startingBTC: Double
    var btcGrowth: Double
    var netBTCHoldings: Double
    var btcPriceUSD: Double // Updated to Double
    var btcPriceEUR: Double // Updated to Double
    var portfolioValueEUR: Double
    var contributionEUR: Double
    var contributionFeeEUR: Double
    var netContributionBTC: Double
    var withdrawalEUR: Double
    var portfolioPreWithdrawalEUR: Double

    static let placeholder = SimulationData(
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
