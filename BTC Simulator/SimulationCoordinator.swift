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

        // Load historical returns for whichever period we use (weeks or months)
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

            let userPriceUSDAsDouble =
                NSDecimalNumber(decimal: Decimal(self.simSettings.initialBTCPriceUSD)).doubleValue

            // Run the Monte Carlo sims
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
            
            // Instead of sorting by final portfolio, we now sort by final BTC price (USD).
            // This picks the run whose end-of-run BTC price is at the median.
            let finalRuns = allIterations.map {
                // Grab the final week's BTC price in USD
                ($0.last?.btcPriceUSD ?? Decimal.zero, $0)
            }
            let sortedRuns = finalRuns.sorted { $0.0 < $1.0 }
            
            print("// DEBUG: sortedRuns => \(sortedRuns.count) runs. " +
                  "Sample final BTC price range => first: \(sortedRuns.first?.0 ?? 0) " +
                  "... last: \(sortedRuns.last?.0 ?? 0)")

            // Just a partial sample debug
            if let firstRun = allIterations.first {
                let midIndex = firstRun.count / 2
                print("// DEBUG: partial sample => week1 => BTC=\(firstRun[0].btcPriceUSD), portfolio=\(firstRun[0].portfolioValueEUR)")
                print("                  => week\(midIndex) => BTC=\(firstRun[midIndex].btcPriceUSD), portfolio=\(firstRun[midIndex].portfolioValueEUR)")
                if let lastItem = firstRun.last {
                    print("// DEBUG: partial sample => last => BTC=\(lastItem.btcPriceUSD), portfolio=\(lastItem.portfolioValueEUR)")
                }
            }

            if sortedRuns.isEmpty {
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
                
                let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex    = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                
                // Single-run approach for 10th, median, 90th:
                let tenthRun     = sortedRuns[tenthIndex].1
                let medianRun    = sortedRuns[medianIndex].1
                let ninetiethRun = sortedRuns[ninetiethIndex].1

                // For demonstration: we set `medianResults` and `monteCarloResults` to that single run
                // (the run whose final BTC price is in the middle).
                self.tenthPercentileResults = tenthRun
                self.ninetiethPercentileResults = ninetiethRun

                // OLD SPLICED APPROACH: we skip `computeMedianSimulationData`.
                // let medianLineData = self.computeMedianSimulationData(allIterations: allIterations)
                // self.medianResults = medianLineData
                // self.monteCarloResults = medianLineData

                // Instead, pick the single iteration for the median final BTC price:
                self.medianResults = medianRun
                self.monteCarloResults = medianRun

                // We'll still keep references for the chart logic:
                self.selectedPercentile = .median
                self.allSimData = allIterations

                // If needed, you can do "range band" chart if you want 10th & 90th lines.
                // But for a single line chart, just rely on `monteCarloResults`.

                // For debugging:
                let tenthFinalBTC     = tenthRun.last?.btcPriceUSD     ?? 0
                let ninetiethFinalBTC = ninetiethRun.last?.btcPriceUSD ?? 0
                let medianFinalBTC    = medianRun.last?.btcPriceUSD    ?? 0

                print("// DEBUG: Tenth final BTC price => \(tenthFinalBTC)")
                print("// DEBUG: Ninetieth final BTC price => \(ninetiethFinalBTC)")
                print("// DEBUG: medianRun => \(medianRun.count) weeks. " +
                      "Final BTC => \(medianFinalBTC)")

                // Build or skip chart snapshots
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
                
                // Possibly not used, but we'll store them anyway:
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

    // -- REMOVED usage of the "spliced" median approach here:
    /*
    private func computeMedianSimulationData(allIterations: [[SimulationData]]) -> [SimulationData] {
        // *We no longer call this to build 'medianLineData'*
        // If you want to keep the spliced approach for debugging, you can
        // still have this function but comment out usage in the final block.
        ...
    }
    */

    private func processAllResults(_ allResults: [[SimulationData]]) {
        print("// DEBUG: processAllResults() => got \(allResults.count) runs.")
    }
}

// Helper for median of Decimal arrays
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

// Helper for median of Double arrays
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
