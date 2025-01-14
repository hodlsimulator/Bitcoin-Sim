//
//  SimulationCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/01/2025.
//

import SwiftUI

enum PercentileChoice {
    case tenth, median, ninetieth
}

class SimulationCoordinator: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isChartBuilding: Bool = false
    @Published var isSimulationRun: Bool = false
    @Published var isCancelled: Bool = false
    
    @Published var monteCarloResults: [SimulationData] = []
    @Published var completedIterations: Int = 0
    @Published var totalIterations: Int = 1000
    
    @Published var tenthPercentileResults: [SimulationData] = []
    @Published var medianResults: [SimulationData] = []
    @Published var ninetiethPercentileResults: [SimulationData] = []
    @Published var selectedPercentile: PercentileChoice = .median
    
    @Published var allSimData: [[SimulationData]] = []
    
    var chartDataCache: ChartDataCache
    private var simSettings: SimulationSettings
    private var inputManager: PersistentInputManager
        
    // 1) Store a reference to ChartSelection
    @Published var chartSelection: ChartSelection

    // 2) Updated init to accept chartSelection:
    init(chartDataCache: ChartDataCache,
         simSettings: SimulationSettings,
         inputManager: PersistentInputManager,
         chartSelection: ChartSelection)
    {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.inputManager = inputManager
        self.chartSelection = chartSelection
    }
    
    func runSimulation(generateGraphs: Bool, lockRandomSeed: Bool) {
        // If you do want to use lockRandomSeed, you can flip the setting here:
        simSettings.lockedRandomSeed = lockRandomSeed

        let newHash = computeInputsHash()
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = \(String(describing: chartDataCache.storedInputsHash))")

        // ** Add the printAllSettings call here **
        simSettings.printAllSettings()

        // CSV loads (placeholders)
        historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
        sp500WeeklyReturns = loadSP500WeeklyReturns()

        print("// DEBUG: Setting up for new simulation run. isLoading=true.")
        isCancelled = false
        isLoading = true
        isChartBuilding = false
        monteCarloResults = []
        completedIterations = 0

        // Handle seeds
        let finalSeed: UInt64?
        if simSettings.lockedRandomSeed {
            finalSeed = simSettings.seedValue
            simSettings.lastUsedSeed = simSettings.seedValue
            print("// DEBUG: Using lockedRandomSeed: \(finalSeed ?? 0)")
        } else if simSettings.useRandomSeed {
            let newRandomSeed = UInt64.random(in: 0..<UInt64.max)
            finalSeed = newRandomSeed
            simSettings.lastUsedSeed = newRandomSeed
            print("// DEBUG: Using a fresh random seed: \(finalSeed ?? 0)")
        } else {
            finalSeed = nil
            simSettings.lastUsedSeed = 0
            print("// DEBUG: No seed locked or random => finalSeed is nil.")
        }

        // Show inputManager contents
        if let mgr = simSettings.inputManager {
            print("// DEBUG: runSimulation => firstYearContribution=\(mgr.firstYearContribution), subsequentContribution=\(mgr.subsequentContribution)")
            print("// DEBUG: runSimulation => threshold1=\(mgr.threshold1), withdraw1=\(mgr.withdrawAmount1)")
            print("// DEBUG: runSimulation => threshold2=\(mgr.threshold2), withdraw2=\(mgr.withdrawAmount2)")
        } else {
            print("// DEBUG: runSimulation => simSettings.inputManager is nil.")
        }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let total = self.inputManager.getParsedIterations(), total > 0 else {
                print("// DEBUG: No valid iteration => bailing out.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.totalIterations = total
            }
            
            // The user’s CAGR & Volatility as Doubles
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR()
            let userInputVolatility = Double(self.inputManager.annualVolatility) ?? 1.0

            print("// DEBUG: userInputCAGR => \(userInputCAGR)%")
            print("// DEBUG: userInputVolatility => \(userInputVolatility)%")

            // If the user picked months, do NOT multiply by 4 here.
            let finalWeeks: Int = {
                if self.simSettings.periodUnit == .weeks {
                    return self.simSettings.userPeriods
                } else {
                    // Now each loop iteration truly represents one month
                    return self.simSettings.userPeriods
                }
            }()

            let userPriceUSDAsDecimal = Decimal(self.simSettings.initialBTCPriceUSD)
            let userPriceUSDAsDouble = NSDecimalNumber(decimal: userPriceUSDAsDecimal).doubleValue

            // Run the simulations
            let (_, allIterations) = runMonteCarloSimulationsWithProgress(
                settings: self.simSettings,
                annualCAGR: userInputCAGR,
                annualVolatility: userInputVolatility,
                correlationWithSP500: 0.0,
                exchangeRateEURUSD: 1.06,
                userWeeks: finalWeeks,
                iterations: total,
                initialBTCPriceUSD: userPriceUSDAsDouble,
                isCancelled: { self.isCancelled },
                progressCallback: { completed in
                    if !self.isCancelled {
                        DispatchQueue.main.async {
                            self.completedIterations = completed
                        }
                    }
                },
                seed: finalSeed
            )
            
            if self.isCancelled {
                print("// DEBUG: user cancelled => stopping.")
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            // Sort runs by final portfolio (in EUR here, just for ranking)
            let finalRuns = allIterations.map { ($0.last?.portfolioValueEUR ?? Decimal.zero, $0) }
            let sortedRuns = finalRuns.sorted { $0.0 < $1.0 }
            
            print("// DEBUG: sortedRuns => \(sortedRuns.count) runs. Sample final portfolio range => first: \(sortedRuns.first?.0 ?? 0) ... last: \(sortedRuns.last?.0 ?? 0)")
            
            // Optional partial sample
            if let firstRun = allIterations.first {
                let midIndex = firstRun.count / 2
                print("// DEBUG: partial sample from first run => week1 => BTC=\(firstRun[0].btcPriceUSD), portfolio=\(firstRun[0].portfolioValueEUR)")
                print("                         => week\(midIndex) => BTC=\(firstRun[midIndex].btcPriceUSD), portfolio=\(firstRun[midIndex].portfolioValueEUR)")
                // ADDED: Print last week so logs match UI
                if let lastItem = firstRun.last {
                    print("// DEBUG: partial sample from first run => last => BTC=\(lastItem.btcPriceUSD), portfolio=\(lastItem.portfolioValueEUR)")
                }
            }

            if !sortedRuns.isEmpty {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isChartBuilding = true
                    print("// DEBUG: Simulation finished => isChartBuilding=true now.")
                    
                    // Grabbing just for 10th/median/90th percentile reference
                    let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                    let medianIndex    = sortedRuns.count / 2
                    let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                    
                    let tenthRun     = sortedRuns[tenthIndex].1
                    let medianRun    = sortedRuns[medianIndex].1
                    let ninetiethRun = sortedRuns[ninetiethIndex].1
                    
                    // The composite line used by the UI
                    let medianLineData = self.computeMedianSimulationData(allIterations: allIterations)
                    
                    // Decide which currency (USD or EUR) to show in logs
                    let medianBTCFinal: Decimal
                    let medianPortfolioFinal: Decimal
                    let tenthPortfolioFinal: Decimal
                    let ninetiethPortfolioFinal: Decimal
                    
                    switch self.simSettings.currencyPreference {
                    case .usd:
                        medianBTCFinal       = medianLineData.last?.btcPriceUSD       ?? 0
                        medianPortfolioFinal = medianLineData.last?.portfolioValueUSD ?? 0
                        
                        tenthPortfolioFinal     = tenthRun.last?.portfolioValueUSD     ?? 0
                        ninetiethPortfolioFinal = ninetiethRun.last?.portfolioValueUSD ?? 0
                        
                    case .eur:
                        medianBTCFinal       = medianLineData.last?.btcPriceEUR       ?? 0
                        medianPortfolioFinal = medianLineData.last?.portfolioValueEUR ?? 0
                        
                        tenthPortfolioFinal     = tenthRun.last?.portfolioValueEUR     ?? 0
                        ninetiethPortfolioFinal = ninetiethRun.last?.portfolioValueEUR ?? 0
                        
                    case .both:
                        // Example: default to USD for logging if "Both" is selected
                        medianBTCFinal       = medianLineData.last?.btcPriceUSD       ?? 0
                        medianPortfolioFinal = medianLineData.last?.portfolioValueUSD ?? 0
                        
                        tenthPortfolioFinal     = tenthRun.last?.portfolioValueUSD     ?? 0
                        ninetiethPortfolioFinal = ninetiethRun.last?.portfolioValueUSD ?? 0
                    }

                    print("// DEBUG: Tenth final portfolio => \(tenthPortfolioFinal)")
                    print("// DEBUG: Ninetieth final portfolio => \(ninetiethPortfolioFinal)")
                    print("// DEBUG: medianLineData => \(medianLineData.count) weeks. Final BTC => \(medianBTCFinal), final portfolio => \(medianPortfolioFinal)")
                    
                    // Store data
                    self.tenthPercentileResults = tenthRun
                    self.medianResults = medianLineData
                    self.ninetiethPercentileResults = ninetiethRun
                    self.monteCarloResults = medianLineData
                    self.selectedPercentile = .median
                    self.allSimData = allIterations
                    
                    // Convert runs for BTC chart and Portfolio
                    let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                    let allSimsAsPortfolioPoints = self.convertAllSimsToPortfolioWeekPoints()
                    
                    // Clear old snapshots
                    if self.chartDataCache.chartSnapshot != nil {
                        print("// DEBUG: clearing old BTC chartSnapshot.")
                    }
                    if self.chartDataCache.chartSnapshotPortfolio != nil {
                        print("// DEBUG: clearing old Portfolio chartSnapshot.")
                    }
                    self.chartDataCache.chartSnapshot = nil
                    self.chartDataCache.chartSnapshotLandscape = nil
                    self.chartDataCache.chartSnapshotPortfolio = nil
                    self.chartDataCache.chartSnapshotPortfolioLandscape = nil
                    
                    // Store runs
                    self.chartDataCache.allRuns = allSimsAsWeekPoints
                    self.chartDataCache.portfolioRuns = allSimsAsPortfolioPoints
                    self.chartDataCache.storedInputsHash = newHash
                    
                    print("// DEBUG: ADDED PRINT => just assigned chartDataCache.allRuns with \(allSimsAsWeekPoints.count) BTC runs.")
                    if let first = allSimsAsWeekPoints.first?.points, !first.isEmpty {
                        print("// DEBUG: ADDED PRINT => first BTC run has \(first.count) weeks, e.g. week=\(first[0].week), val=\(first[0].value)")
                    }
                    
                    print("// DEBUG: ADDED PRINT => just assigned chartDataCache.portfolioRuns with \(allSimsAsPortfolioPoints.count) portfolio runs.")
                    if let firstPort = allSimsAsPortfolioPoints.first?.points, !firstPort.isEmpty {
                        print("// DEBUG: ADDED PRINT => first portfolio run has \(firstPort.count) weeks, e.g. week=\(firstPort[0].week), val=\(firstPort[0].value)")
                    }
                    
                    print("// DEBUG: chartDataCache => storedInputsHash=\(newHash), allRuns.count=\(allSimsAsWeekPoints.count), portfolioRuns.count=\(allSimsAsPortfolioPoints.count)")
                    
                    let oldSelection = self.chartSelection.selectedChart
                    print("// CHANGED: oldSelection => \(oldSelection)")

                    // ADDED OR MODIFIED: Only build snapshots if generateGraphs == true
                    if !generateGraphs {
                        print("// DEBUG: Skipping chart building because generateGraphs == false.")
                        self.isChartBuilding = false
                        self.isSimulationRun = true
                        return
                    }
                    
                    DispatchQueue.main.async {
                        if self.isCancelled {
                            self.isChartBuilding = false
                            return
                        }
                        // Temporarily force BTC chart, then build
                        self.chartSelection.selectedChart = .btcPrice
                        print("// DEBUG: building chartView (BTC portrait) for layout pass.")
                        
                        let btcChartView = MonteCarloResultsView()
                            .environmentObject(self.chartDataCache)
                            .environmentObject(self.simSettings)
                            .environmentObject(self.chartSelection)
                        
                        DispatchQueue.main.async {
                            if self.isCancelled {
                                self.isChartBuilding = false
                                return
                            }
                            print("// DEBUG: now taking portrait snapshot of BTC chartView.")
                            
                            let btcSnapshot = btcChartView.snapshot()
                            print("// DEBUG: BTC portrait snapshot => setting chartDataCache.chartSnapshot.")
                            self.chartDataCache.chartSnapshot = btcSnapshot
                            
                            // Now do the same for Portfolio
                            print("// DEBUG: building chartView (Portfolio portrait) for layout pass.")
                            self.chartSelection.selectedChart = .cumulativePortfolio
                            
                            let portfolioChartView = MonteCarloResultsView()
                                .environmentObject(self.chartDataCache)
                                .environmentObject(self.simSettings)
                                .environmentObject(self.chartSelection)
                            
                            DispatchQueue.main.async {
                                if self.isCancelled {
                                    self.isChartBuilding = false
                                    return
                                }
                                print("// DEBUG: now taking portrait snapshot of Portfolio chartView.")
                                
                                let portfolioSnapshot = portfolioChartView.snapshot()
                                print("// DEBUG: [Portfolio] portrait snapshot => setting chartDataCache.chartSnapshotPortfolio.")
                                self.chartDataCache.chartSnapshotPortfolio = portfolioSnapshot
                                
                                // Restore old selection
                                self.chartSelection.selectedChart = oldSelection
                                print("// CHANGED: restored oldSelection => \(oldSelection)")

                                self.isChartBuilding = false
                                self.isSimulationRun = true
                            }
                        }
                    }
                }
            } else {
                print("// DEBUG: No runs => done.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
            
            // Possibly do background tasks
            DispatchQueue.global(qos: .background).async {
                self.processAllResults(allIterations)
            }
        }
    }
    
    /// Convert `[[SimulationData]]` to `[SimulationRun]` with BTC decimal values
    func convertAllSimsToWeekPoints() -> [SimulationRun] {
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                WeekPoint(week: row.week, value: row.btcPriceUSD)
            }
            return SimulationRun(points: wpoints)
        }
    }
    
    /// Convert `[[SimulationData]]` to `[SimulationRun]` but use portfolioValueEUR
    func convertAllSimsToPortfolioWeekPoints() -> [SimulationRun] {
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                WeekPoint(week: row.week, value: row.portfolioValueEUR)
            }
            return SimulationRun(points: wpoints)
        }
    }
    
    private func computeInputsHash() -> Int {
        let finalPeriods = (simSettings.periodUnit == .weeks)
            ? simSettings.userPeriods
            : simSettings.userPeriods  // no longer multiply by 4

        let combinedString = """
        \(inputManager.iterations)_\(inputManager.annualCAGR)_\(inputManager.annualVolatility)_\
        \(finalPeriods)_\(simSettings.initialBTCPriceUSD)
        """
        return combinedString.hashValue
    }
    
    private func computeMedianSimulationData(allIterations: [[SimulationData]]) -> [SimulationData] {
        guard let firstRun = allIterations.first else { return [] }
        let totalWeeks = firstRun.count
        
        var medianResult: [SimulationData] = []
        
        for w in 0..<totalWeeks {
            // Grab the same "week" across all runs
            let allAtWeek = allIterations.compactMap { run -> SimulationData? in
                guard w < run.count else { return nil }
                return run[w]
            }
            if allAtWeek.isEmpty { continue }
            
            // Grab all the decimals
            let allBTCPriceUSD       = allAtWeek.map { $0.btcPriceUSD }
            let allBTCPriceEUR       = allAtWeek.map { $0.btcPriceEUR }
            let allPortfolioValueEUR = allAtWeek.map { $0.portfolioValueEUR }
            let allPortfolioValueUSD = allAtWeek.map { $0.portfolioValueUSD }

            // Grab the double fields
            let allStartingBTC    = allAtWeek.map { $0.startingBTC }
            let allNetBTCHoldings = allAtWeek.map { $0.netBTCHoldings }
            let allContribEUR     = allAtWeek.map { $0.contributionEUR }
            let allFeeEUR         = allAtWeek.map { $0.transactionFeeEUR }
            let allContribUSD     = allAtWeek.map { $0.contributionUSD }
            let allFeeUSD         = allAtWeek.map { $0.transactionFeeUSD }
            let allNetContribBTC  = allAtWeek.map { $0.netContributionBTC }
            let allWithdrawalEUR  = allAtWeek.map { $0.withdrawalEUR }
            let allWithdrawalUSD  = allAtWeek.map { $0.withdrawalUSD }

            // 1) Take median for decimal fields
            let medianBTCPriceUSD       = medianOfDecimalArray(allBTCPriceUSD)
            let medianBTCPriceEUR       = medianOfDecimalArray(allBTCPriceEUR)
            let medianPortfolioValueEUR = medianOfDecimalArray(allPortfolioValueEUR)
            let medianPortfolioValueUSD = medianOfDecimalArray(allPortfolioValueUSD)

            // 2) Take median for double fields
            let medianStartingBTC       = medianOfDoubleArray(allStartingBTC)
            let medianNetBTCHoldings    = medianOfDoubleArray(allNetBTCHoldings)
            let medianContributionEUR   = medianOfDoubleArray(allContribEUR)
            let medianFeeEUR            = medianOfDoubleArray(allFeeEUR)
            let medianContributionUSD   = medianOfDoubleArray(allContribUSD)
            let medianFeeUSD            = medianOfDoubleArray(allFeeUSD)
            let medianNetContributionBTC = medianOfDoubleArray(allNetContribBTC)
            let medianWithdrawalEUR     = medianOfDoubleArray(allWithdrawalEUR)
            let medianWithdrawalUSD     = medianOfDoubleArray(allWithdrawalUSD)

            // 3) Build the aggregated record
            let medianSimData = SimulationData(
                week: allAtWeek[0].week,
                startingBTC: medianStartingBTC,
                netBTCHoldings: medianNetBTCHoldings,
                btcPriceUSD: medianBTCPriceUSD,
                btcPriceEUR: medianBTCPriceEUR,
                portfolioValueEUR: medianPortfolioValueEUR,
                portfolioValueUSD: medianPortfolioValueUSD,
                contributionEUR: medianContributionEUR,
                contributionUSD: medianContributionUSD,
                transactionFeeEUR: medianFeeEUR,
                transactionFeeUSD: medianFeeUSD,
                netContributionBTC: medianNetContributionBTC,
                withdrawalEUR: medianWithdrawalEUR,
                withdrawalUSD: medianWithdrawalUSD
            )
            
            medianResult.append(medianSimData)
        }
        
        return medianResult
    }
    
    private func processAllResults(_ allResults: [[SimulationData]]) {
        print("// DEBUG: processAllResults() => got \(allResults.count) runs to do further analysis on (if desired).")
    }
}

/// For Decimal arrays
func medianOfDecimalArray(_ arr: [Decimal]) -> Decimal {
    if arr.isEmpty { return .zero }
    let sortedArr = arr.sorted(by: <)
    let mid = sortedArr.count / 2
    if sortedArr.count.isMultiple(of: 2) {
        let sum = sortedArr[mid] + sortedArr[mid - 1]
        return sum / Decimal(2)
    } else {
        return sortedArr[mid]
    }
}

/// For Double arrays
func medianOfDoubleArray(_ arr: [Double]) -> Double {
    if arr.isEmpty { return 0.0 }
    let sortedArr = arr.sorted()
    let mid = sortedArr.count / 2
    if sortedArr.count.isMultiple(of: 2) {
        return (sortedArr[mid] + sortedArr[mid - 1]) / 2.0
    } else {
        return sortedArr[mid]
    }
}
