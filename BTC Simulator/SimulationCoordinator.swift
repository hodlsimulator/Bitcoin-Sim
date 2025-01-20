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
    
    // Step-by-step median BTC prices (week or month)
    @Published var stepMedianBTCs: [Decimal] = []

    var chartDataCache: ChartDataCache
    private var simSettings: SimulationSettings
    private var inputManager: PersistentInputManager
        
    // Renamed from chartSelection to simChartSelection
    @Published var simChartSelection: SimChartSelection

    init(
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings,
        inputManager: PersistentInputManager,
        // changed from chartSelection: ChartSelection
        simChartSelection: SimChartSelection
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.inputManager = inputManager
        self.simChartSelection = simChartSelection
    }
    
    func runSimulation(generateGraphs: Bool, lockRandomSeed: Bool) {
        simSettings.lockedRandomSeed = lockRandomSeed

        let newHash = computeInputsHash()
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = \(String(describing: chartDataCache.storedInputsHash))")
        simSettings.printAllSettings()

        // Decide whether to load monthly or weekly returns
        if simSettings.periodUnit == .months {
            historicalBTCMonthlyReturns = loadBTCMonthlyReturns()
            sp500MonthlyReturns        = loadSP500MonthlyReturns()
            historicalBTCWeeklyReturns = []
            sp500WeeklyReturns         = []
        } else {
            historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
            sp500WeeklyReturns         = loadSP500WeeklyReturns()
            historicalBTCMonthlyReturns = []
            sp500MonthlyReturns         = []
        }

        print("// DEBUG: Setting up for new simulation run. isLoading=true.")
        isCancelled = false
        isLoading = true
        isChartBuilding = false
        monteCarloResults = []
        completedIterations = 0

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
            
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR()
            let userInputVolatility = Double(self.inputManager.annualVolatility) ?? 1.0

            print("// DEBUG: userInputCAGR => \(userInputCAGR)%")
            print("// DEBUG: userInputVolatility => \(userInputVolatility)%")

            let finalWeeks: Int = {
                if self.simSettings.periodUnit == .weeks {
                    return self.simSettings.userPeriods
                } else {
                    return self.simSettings.userPeriods
                }
            }()

            let userPriceUSDAsDouble = NSDecimalNumber(
                decimal: Decimal(self.simSettings.initialBTCPriceUSD)
            ).doubleValue

            // ----------------------------------------------------------------
            // Run all simulations
            // ----------------------------------------------------------------
            let (medianRun, allIterations, stepMedianPrices) = runMonteCarloSimulationsWithProgress(
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
            
            DispatchQueue.main.async {
                // Store the stepMedianPrices
                self.stepMedianBTCs = stepMedianPrices
            }

            if allIterations.isEmpty {
                print("// DEBUG: No runs => done.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            DispatchQueue.main.async {
                self.isLoading = false
                self.isChartBuilding = true
                print("// DEBUG: Simulation finished => isChartBuilding=true now.")
                
                // Next, pick the 10th, median, 90th runs by final BTC
                let finalRuns = allIterations.enumerated().map {
                    ($0.offset, $0.element.last?.btcPriceUSD ?? Decimal.zero, $0.element)
                }
                let sortedRuns = finalRuns.sorted { $0.1 < $1.1 }
                
                print("// DEBUG: sortedRuns => \(sortedRuns.count) runs.")

                if sortedRuns.isEmpty {
                    print("// DEBUG: sortedRuns empty => done.")
                    self.isChartBuilding = false
                    return
                }

                let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex    = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                
                let tenthRunIndex  = sortedRuns[tenthIndex].0
                let tenthRun       = sortedRuns[tenthIndex].2
                let medianRunIndex = sortedRuns[medianIndex].0
                let medianRun2     = sortedRuns[medianIndex].2
                let ninetiethRunIndex = sortedRuns[ninetiethIndex].0
                let ninetiethRun   = sortedRuns[ninetiethIndex].2

                self.tenthPercentileResults = tenthRun
                self.ninetiethPercentileResults = ninetiethRun
                self.medianResults = medianRun2

                // Find the single run that best fits stepMedianPrices
                let bestFitRunIndex = self.findRepresentativeRunIndex(
                    allRuns: allIterations,
                    stepMedianBTC: stepMedianPrices
                )
                let bestFitRun = allIterations[bestFitRunIndex]
                self.monteCarloResults = bestFitRun
                
                self.selectedPercentile = .median
                self.allSimData = allIterations

                // Debug outputs
                print("// DEBUG: Tenth run => iteration #\(tenthRunIndex), final BTC => \(sortedRuns[tenthIndex].1)")
                print("// DEBUG: 'median final BTC' => iteration #\(medianRunIndex), final BTC => \(sortedRuns[medianIndex].1)")
                print("// DEBUG: Ninetieth run => iteration #\(ninetiethRunIndex), final BTC => \(sortedRuns[ninetiethIndex].1)")
                print("// DEBUG: bestFitRun => iteration #\(bestFitRunIndex) chosen by distance.")
                
                // Build chart data (all runs) => faint lines
                let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                let allSimsAsPortfolioPoints = self.convertAllSimsToPortfolioWeekPoints()

                // Build chart data (BEST-FIT ONLY) => bold overlay
                let bestFitBTCPoints = bestFitRun.map { row in
                    WeekPoint(week: row.week, value: row.btcPriceUSD)
                }
                let bestFitPortfolioPoints = bestFitRun.map { row in
                    (self.simSettings.currencyPreference == .eur)
                        ? row.portfolioValueEUR
                        : row.portfolioValueUSD
                }.enumerated().map { (idx, val) in
                    WeekPoint(week: bestFitRun[idx].week, value: val)
                }

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
                
                // Store the faint lines
                self.chartDataCache.allRuns = allSimsAsWeekPoints
                self.chartDataCache.portfolioRuns = allSimsAsPortfolioPoints
                
                // Store the single best-fit line for BTC
                self.chartDataCache.bestFitRun = [
                    SimulationRun(points: bestFitBTCPoints)
                ]
                // And for the portfolio
                self.chartDataCache.bestFitPortfolioRun = [
                    SimulationRun(points: bestFitPortfolioPoints)
                ]

                self.chartDataCache.storedInputsHash = newHash
                
                let oldSelection = self.simChartSelection.selectedChart
                print("// CHANGED: oldSelection => \(oldSelection)")

                // If user doesn't want to generate charts, skip chart building
                if !generateGraphs {
                    print("// DEBUG: Skipping chart building because generateGraphs == false.")
                    self.isChartBuilding = false
                    self.isSimulationRun = true
                    return
                }
                
                // Build chart snapshots
                DispatchQueue.main.async {
                    if self.isCancelled {
                        self.isChartBuilding = false
                        return
                    }
                    self.simChartSelection.selectedChart = .btcPrice
                    let btcChartView = MonteCarloResultsView()
                        .environmentObject(self.chartDataCache)
                        .environmentObject(self.simSettings)
                        .environmentObject(self.simChartSelection)
                    
                    DispatchQueue.main.async {
                        if self.isCancelled {
                            self.isChartBuilding = false
                            return
                        }
                        let btcSnapshot = btcChartView.snapshot()
                        self.chartDataCache.chartSnapshot = btcSnapshot
                        
                        self.simChartSelection.selectedChart = .cumulativePortfolio
                        let portfolioChartView = MonteCarloResultsView()
                            .environmentObject(self.chartDataCache)
                            .environmentObject(self.simSettings)
                            .environmentObject(self.simChartSelection)
                        
                        DispatchQueue.main.async {
                            if self.isCancelled {
                                self.isChartBuilding = false
                                return
                            }
                            let portfolioSnapshot = portfolioChartView.snapshot()
                            self.chartDataCache.chartSnapshotPortfolio = portfolioSnapshot
                            
                            self.simChartSelection.selectedChart = oldSelection
                            print("// CHANGED: restored oldSelection => \(oldSelection)")

                            self.isChartBuilding = false
                            self.isSimulationRun = true
                        }
                    }
                }

                // Background analysis
                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allIterations)
                }
            }
        }
    }
    
    // MARK: - Convert All Sims => Faint Lines
    func convertAllSimsToWeekPoints() -> [SimulationRun] {
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                WeekPoint(week: row.week, value: row.btcPriceUSD)
            }
            return SimulationRun(points: wpoints)
        }
    }
    
    func convertAllSimsToPortfolioWeekPoints() -> [SimulationRun] {
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                let chosenPortfolio = (simSettings.currencyPreference == .eur)
                    ? row.portfolioValueEUR
                    : row.portfolioValueUSD
                return WeekPoint(week: row.week, value: chosenPortfolio)
            }
            return SimulationRun(points: wpoints)
        }
    }
    
    // MARK: - Helpers
    private func computeInputsHash() -> Int {
        let finalPeriods = simSettings.userPeriods // same if months or weeks

        let combinedString = """
        \(inputManager.iterations)_\(inputManager.annualCAGR)_\
        \(inputManager.annualVolatility)_\(finalPeriods)_\(simSettings.initialBTCPriceUSD)
        """
        return combinedString.hashValue
    }

    private func processAllResults(_ allResults: [[SimulationData]]) {
        print("// DEBUG: processAllResults() => got \(allResults.count) runs.")
    }
}

// MARK: - "Representative Run" logic
extension SimulationCoordinator {
    /// Returns the index in `allRuns` that is best fit to `stepMedianBTC`.
    fileprivate func findRepresentativeRunIndex(
        allRuns: [[SimulationData]],
        stepMedianBTC: [Decimal]
    ) -> Int {
        var minDistance = Double.greatestFiniteMagnitude
        var bestIndex = 0
        
        for (i, run) in allRuns.enumerated() {
            let dist = computeDistance(run: run, stepMedianBTC: stepMedianBTC, verbose: false)
            if dist < minDistance {
                minDistance = dist
                bestIndex = i
            }
        }
        return bestIndex
    }
    
    /// Calculates how “close” a run is to the median BTC array.
    fileprivate func computeDistance(
        run: [SimulationData],
        stepMedianBTC: [Decimal],
        verbose: Bool
    ) -> Double {
        var totalDist = 0.0
        let count = min(run.count, stepMedianBTC.count)
        
        for step in 0..<count {
            let runBTC = NSDecimalNumber(decimal: run[step].btcPriceUSD).doubleValue
            let medianBTC = NSDecimalNumber(decimal: stepMedianBTC[step]).doubleValue
            totalDist += abs(runBTC - medianBTC)
        }
        return totalDist
    }
}
