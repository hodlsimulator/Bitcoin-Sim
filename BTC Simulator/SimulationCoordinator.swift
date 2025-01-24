//
//  SimulationCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/01/2025.
//

import SwiftUI
import GameplayKit  // <-- for GKARC4RandomSource

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
    var mempoolDataManager: MempoolDataManager?
    private var simSettings: SimulationSettings
    private var inputManager: PersistentInputManager
        
    @Published var simChartSelection: SimChartSelection

    // NEW: We'll store the fitted GarchModel here if we calibrate it.
    private var fittedGarchModel: GarchModel? = nil

    // Historical returns storage
    private var historicalBTCWeeklyReturns: [Double] = []
    private var sp500WeeklyReturns: [Double] = []
    private var historicalBTCMonthlyReturns: [Double] = []
    private var sp500MonthlyReturns: [Double] = []

    init(
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings,
        inputManager: PersistentInputManager,
        simChartSelection: SimChartSelection
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.inputManager = inputManager
        self.simChartSelection = simChartSelection
    }
    
    func runSimulation(generateGraphs: Bool, lockRandomSeed: Bool) {
        // 1) Lock or unlock your random seed
        simSettings.lockedRandomSeed = lockRandomSeed

        let newHash = computeInputsHash()
        simSettings.printAllSettings()

        // 2) Decide whether to load monthly or weekly returns, then fill arrays
        if simSettings.periodUnit == .months {
            let btcMonthlyDict = loadBTCMonthlyReturnsAsDict()
            let spMonthlyDict  = loadSP500MonthlyReturnsAsDict()
            
            let alignedMonthly = alignBTCandSPMonthly(
                btcDict: btcMonthlyDict,
                spDict: spMonthlyDict
            )
            
            historicalBTCMonthlyReturns = alignedMonthly.map { $0.1 }
            sp500MonthlyReturns         = alignedMonthly.map { $0.2 }

            // Clear out weekly arrays
            historicalBTCWeeklyReturns = []
            sp500WeeklyReturns = []
            
        } else {
            let btcWeeklyDict = loadBTCWeeklyReturnsAsDict()
            let spWeeklyDict  = loadSP500WeeklyReturnsAsDict()
            
            let alignedWeekly = alignBTCandSPWeekly(
                btcDict: btcWeeklyDict,
                spDict: spWeeklyDict
            )
            
            historicalBTCWeeklyReturns = alignedWeekly.map { $0.1 }
            sp500WeeklyReturns         = alignedWeekly.map { $0.2 }

            // Clear out monthly arrays
            historicalBTCMonthlyReturns = []
            sp500MonthlyReturns = []
        }

        // 3) If user wants GARCH, calibrate it now
        if simSettings.useGarchVolatility {
            calibrateGarchIfNeeded()
        } else {
            fittedGarchModel = nil
        }

        // Prepare for the simulation
        isCancelled = false
        isLoading = true
        isChartBuilding = false
        monteCarloResults = []
        completedIterations = 0

        let finalSeed: UInt64?
        if simSettings.lockedRandomSeed {
            finalSeed = simSettings.seedValue
            simSettings.lastUsedSeed = simSettings.seedValue
        } else if simSettings.useRandomSeed {
            let newRandomSeed = UInt64.random(in: 0..<UInt64.max)
            finalSeed = newRandomSeed
            simSettings.lastUsedSeed = newRandomSeed
        } else {
            finalSeed = nil
            simSettings.lastUsedSeed = 0
        }

        // Example mempool data
        let mempoolArray = [Double](repeating: 50.0, count: 5000)
        let mempoolDataManager = MempoolDataManager(mempoolData: mempoolArray)

        // 4) Run in background
        DispatchQueue.global(qos: .userInitiated).async {
            // Check iterations
            guard let total = self.inputManager.getParsedIterations(), total > 0 else {
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
            let finalWeeks = self.simSettings.userPeriods
            let userPriceUSDAsDouble = NSDecimalNumber(decimal: Decimal(self.simSettings.initialBTCPriceUSD)).doubleValue

            // 5) Run the simulations
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
                seed: finalSeed,
                mempoolDataManager: mempoolDataManager,
                fittedGarchModel: self.fittedGarchModel
            )
            
            // Check for cancellation
            if self.isCancelled {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            // Store median BTC for charts
            DispatchQueue.main.async {
                self.stepMedianBTCs = stepMedianPrices
            }

            // If no runs, end
            if allIterations.isEmpty {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }

            // Build results on main queue
            DispatchQueue.main.async {
                self.isLoading = false
                self.isChartBuilding = true
        
                let finalRuns = allIterations.enumerated().map {
                    ($0.offset, $0.element.last?.btcPriceUSD ?? Decimal.zero, $0.element)
                }
                let sortedRuns = finalRuns.sorted { $0.1 < $1.1 }

                if sortedRuns.isEmpty {
                    self.isChartBuilding = false
                    return
                }

                // 10th, 50th, 90th percentile
                let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex    = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))

                let tenthRun = sortedRuns[tenthIndex].2
                let medianRun2 = sortedRuns[medianIndex].2
                let ninetiethRun = sortedRuns[ninetiethIndex].2

                self.tenthPercentileResults = tenthRun
                self.ninetiethPercentileResults = ninetiethRun
                self.medianResults = medianRun2

                // Find run closest to median BTC path
                let bestFitRunIndex = self.findRepresentativeRunIndex(
                    allRuns: allIterations,
                    stepMedianBTC: stepMedianPrices
                )
                let bestFitRun = allIterations[bestFitRunIndex]
                self.monteCarloResults = bestFitRun
                
                self.selectedPercentile = .median
                self.allSimData = allIterations

                // Debug logs
                print("// DEBUG: 'median final BTC' => iteration #\(sortedRuns[medianIndex].0), final BTC => \(sortedRuns[medianIndex].1)")
                print("// DEBUG: bestFitRun => iteration #\(bestFitRunIndex) chosen by distance.")
                print("// DEBUG: bestFitRun => final BTC => \(bestFitRun.last?.btcPriceUSD ?? 0)")
                
                // Convert all sims to chart lines
                let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                let allSimsAsPortfolioPoints = self.convertAllSimsToPortfolioWeekPoints()

                // Best-fit lines (BTC and Portfolio)
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

                // Clear old chart snapshots
                self.chartDataCache.chartSnapshot = nil
                self.chartDataCache.chartSnapshotLandscape = nil
                self.chartDataCache.chartSnapshotPortfolio = nil
                self.chartDataCache.chartSnapshotPortfolioLandscape = nil
                
                // Store faint lines & best fit lines
                self.chartDataCache.allRuns = allSimsAsWeekPoints
                self.chartDataCache.portfolioRuns = allSimsAsPortfolioPoints
                self.chartDataCache.bestFitRun = [
                    SimulationRun(points: bestFitBTCPoints)
                ]
                self.chartDataCache.bestFitPortfolioRun = [
                    SimulationRun(points: bestFitPortfolioPoints)
                ]
                self.chartDataCache.storedInputsHash = newHash
                
                let oldSelection = self.simChartSelection.selectedChart

                // If user doesn’t want charts, skip building them
                if !generateGraphs {
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

                            self.isChartBuilding = false
                            self.isSimulationRun = true
                        }
                    }
                }

                // Any extra background data analysis
                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allIterations)
                }
            }
        }
    }
    
    // MARK: - GARCH ADAM CALIBRATION
    /// Use a more sophisticated Adam-based calibrator on whichever data we loaded (weekly or monthly).
    private func calibrateGarchIfNeeded() {
        let adamCalibrator = GarchAdamCalibrator()
        
        if simSettings.periodUnit == .months {
            if !historicalBTCMonthlyReturns.isEmpty {
                let model = adamCalibrator.calibrate(
                    returns: historicalBTCMonthlyReturns,
                    iterations: 3000,
                    baseLR: 1e-3 // you can tweak these as you like
                )
                fittedGarchModel = model
                print("GARCH (Adam) Calibrated (Monthly): (ω, α, β) =",
                      model.omega, model.alpha, model.beta)
            } else {
                print("No monthly data for GARCH calibration.")
            }
        } else {
            if !historicalBTCWeeklyReturns.isEmpty {
                let model = adamCalibrator.calibrate(
                    returns: historicalBTCWeeklyReturns,
                    iterations: 3000,
                    baseLR: 1e-3
                )
                fittedGarchModel = model
                print("GARCH (Adam) Calibrated (Weekly): (ω, α, β) =",
                      model.omega, model.alpha, model.beta)
            } else {
                print("No weekly data for GARCH calibration.")
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
        let finalPeriods = simSettings.userPeriods
        let combinedString = """
        \(inputManager.iterations)_\(inputManager.annualCAGR)_\
        \(inputManager.annualVolatility)_\(finalPeriods)_\(simSettings.initialBTCPriceUSD)
        """
        return combinedString.hashValue
    }

    private func processAllResults(_ allResults: [[SimulationData]]) {
        // Additional data processing here if needed
    }
}

// MARK: - "Representative Run" logic
extension SimulationCoordinator {
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
