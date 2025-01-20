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
        
    @Published var chartSelection: ChartSelection

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

            let userPriceUSDAsDouble = NSDecimalNumber(decimal: Decimal(self.simSettings.initialBTCPriceUSD)).doubleValue

            // ----------------------------------------------------------------
            // We call runMonteCarloSimulationsWithProgress
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
                    // We'll keep iteration index from enumerated() for logging
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

                // NEW CODE: find the single run that best fits stepMedianPrices
                let bestFitRunIndex = self.findRepresentativeRunIndex(allRuns: allIterations, stepMedianBTC: stepMedianPrices)
                let bestFitRun = allIterations[bestFitRunIndex]
                
                // We'll use that best-fit run as the main "display" run
                self.monteCarloResults = bestFitRun
                
                self.selectedPercentile = .median
                self.allSimData = allIterations

                // Debug outputs
                print("// DEBUG: Tenth run => iteration #\(tenthRunIndex), final BTC => \(sortedRuns[tenthIndex].1)")
                print("// DEBUG: 'median final BTC' => iteration #\(medianRunIndex), final BTC => \(sortedRuns[medianIndex].1)")
                print("// DEBUG: Ninetieth run => iteration #\(ninetiethRunIndex), final BTC => \(sortedRuns[ninetiethIndex].1)")
                print("// DEBUG: bestFitRun => iteration #\(bestFitRunIndex) chosen by distance. =>")
                let dist = self.computeDistance(run: bestFitRun, stepMedianBTC: stepMedianPrices, iterationIndex: bestFitRunIndex, verbose: true)
                print("// DEBUG:   totalDist => \(dist)")

                // NEW CODE: Log the best-fit run's actual steps
                print("// VERBOSE: Logging the best-fit run (#\(bestFitRunIndex)) step-by-step:")
                for (stepIdx, row) in bestFitRun.enumerated() { // NEW CODE
                    let monthNum = stepIdx + 1
                    // Convert Decimals to Double if you want more clarity
                    let btcDouble = NSDecimalNumber(decimal: row.btcPriceUSD).doubleValue
                    let portDouble = NSDecimalNumber(decimal: row.portfolioValueUSD).doubleValue
                    
                    print("//   Month=\(monthNum), BTC=\(btcDouble), portfolio=\(portDouble), depositUSD=\(row.contributionUSD), withdrawal=\(row.withdrawalUSD)")
                }
                
                // Build chart data
                let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                let allSimsAsPortfolioPoints = self.convertAllSimsToPortfolioWeekPoints()
                
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
                
                self.chartDataCache.allRuns = allSimsAsWeekPoints
                self.chartDataCache.portfolioRuns = allSimsAsPortfolioPoints

                self.chartDataCache.storedInputsHash = newHash
                
                let oldSelection = self.chartSelection.selectedChart
                print("// CHANGED: oldSelection => \(oldSelection)")

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
                    self.chartSelection.selectedChart = .btcPrice
                    let btcChartView = MonteCarloResultsView()
                        .environmentObject(self.chartDataCache)
                        .environmentObject(self.simSettings)
                        .environmentObject(self.chartSelection)
                    
                    DispatchQueue.main.async {
                        if self.isCancelled {
                            self.isChartBuilding = false
                            return
                        }
                        let btcSnapshot = btcChartView.snapshot()
                        self.chartDataCache.chartSnapshot = btcSnapshot
                        
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
                            let portfolioSnapshot = portfolioChartView.snapshot()
                            self.chartDataCache.chartSnapshotPortfolio = portfolioSnapshot
                            
                            self.chartSelection.selectedChart = oldSelection
                            print("// CHANGED: restored oldSelection => \(oldSelection)")

                            self.isChartBuilding = false
                            self.isSimulationRun = true
                        }
                    }
                }
            }

            // We do any background analysis here
            DispatchQueue.global(qos: .background).async {
                self.processAllResults(allIterations)
            }
        }
    }
    
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
    
    private func computeInputsHash() -> Int {
        let finalPeriods = (simSettings.periodUnit == .weeks)
            ? simSettings.userPeriods
            : simSettings.userPeriods

        let combinedString = """
        \(inputManager.iterations)_\(inputManager.annualCAGR)_\(inputManager.annualVolatility)_\
        \(finalPeriods)_\(simSettings.initialBTCPriceUSD)
        """
        return combinedString.hashValue
    }

    private func processAllResults(_ allResults: [[SimulationData]]) {
        print("// DEBUG: processAllResults() => got \(allResults.count) runs.")
    }
}

// MARK: - "Representative Run" with verbose logging
extension SimulationCoordinator {
    /// Returns the index in `allRuns` that is best fit to `stepMedianBTC`.
    /// We'll print a verbose log for every iteration.
    fileprivate func findRepresentativeRunIndex(
        allRuns: [[SimulationData]],
        stepMedianBTC: [Decimal]
    ) -> Int {
        var minDistance = Double.greatestFiniteMagnitude
        var bestIndex = 0
        
        // 1) Find the run with smallest distance
        for (i, run) in allRuns.enumerated() {
            let dist = computeDistance(
                run: run,
                stepMedianBTC: stepMedianBTC,
                iterationIndex: i,
                verbose: false
            )
            if dist < minDistance {
                minDistance = dist
                bestIndex = i
            }
        }
        
        // 2) Print summary for all runs
        print("// VERBOSE: Representative run search results:")
        for (j, run) in allRuns.enumerated() {
            let dist = computeDistance(run: run, stepMedianBTC: stepMedianBTC, iterationIndex: j, verbose: false)
            let marker = (j == bestIndex) ? "<-- BEST" : ""
            print("//   run #\(j) => total distance=\(dist) \(marker)")
        }
        
        // 3) Also log the EXACT steps of the best-fit run
        print("// VERBOSE: Logging the best-fit run (#\(bestIndex)) step-by-step:")
        logRunSteps(bestRun: allRuns[bestIndex], runIndex: bestIndex)
        
        return bestIndex
    }
    
    /// Detailed distance computation. If `verbose == true`, we also print each step's difference.
    fileprivate func computeDistance(
        run: [SimulationData],
        stepMedianBTC: [Decimal],
        iterationIndex: Int,
        verbose: Bool
    ) -> Double {
        var totalDist = 0.0
        let count = min(run.count, stepMedianBTC.count)
        
        if verbose {
            print("// DEBUG: Distances for iteration #\(iterationIndex):")
        }
        
        for step in 0..<count {
            let runBTC = NSDecimalNumber(decimal: run[step].btcPriceUSD).doubleValue
            let medianBTC = NSDecimalNumber(decimal: stepMedianBTC[step]).doubleValue
            let diff = abs(runBTC - medianBTC)
            
            totalDist += diff
            
            if verbose {
                print("   Step=\(step + 1), runBTC=\(runBTC), median=\(medianBTC), diff=\(diff)")
            }
        }
        
        if verbose {
            print("   => totalDist=\(totalDist)")
        }
        
        return totalDist
    }
    
    /// NEW CODE: Dump the step-by-step BTC price & portfolio for the chosen run.
    private func logRunSteps(bestRun: [SimulationData], runIndex: Int) {
        print("// VERBOSE: bestRun #\(runIndex) => step-by-step detail:")
        for (i, row) in bestRun.enumerated() {
            let step = i + 1
            let btcUSD = NSDecimalNumber(decimal: row.btcPriceUSD).doubleValue
            let portfolioUSD = NSDecimalNumber(decimal: row.portfolioValueUSD).doubleValue
            print("""
            //   step=\(step), BTC=\(btcUSD), holdings=\(row.netBTCHoldings), 
            //     portfolio=\(portfolioUSD), depositUSD=\(row.contributionUSD), 
            //     withdrawal=\(row.withdrawalUSD)
            """)
        }
    }
}
