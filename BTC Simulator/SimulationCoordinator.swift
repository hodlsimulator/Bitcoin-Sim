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
    // @Published var isSimulationRun: Bool = false
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
    
    @Published var useMonthly: Bool = false

    var chartDataCache: ChartDataCache
    var mempoolDataManager: MempoolDataManager?
    private(set) var simSettings: SimulationSettings
    private var inputManager: PersistentInputManager
        
    @Published var simChartSelection: SimChartSelection

    // We'll store the fitted GarchModel here if we calibrate it.
    private var fittedGarchModel: GarchModel? = nil

    // Historical returns storage
    private var historicalBTCWeeklyReturns: [Double] = []
    private var sp500WeeklyReturns: [Double] = []
    private var historicalBTCMonthlyReturns: [Double] = []
    private var sp500MonthlyReturns: [Double] = []
    
    private var monthlySimSettings: MonthlySimulationSettings

    init(
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings,
        monthlySimSettings: MonthlySimulationSettings,
        inputManager: PersistentInputManager,
        simChartSelection: SimChartSelection
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.monthlySimSettings = monthlySimSettings
        self.inputManager = inputManager
        self.simChartSelection = simChartSelection
    }
    
    func runSimulation(generateGraphs: Bool, lockRandomSeed: Bool) {
        print("Coordinator ID in runSimulation =>", ObjectIdentifier(self))
        print("DEBUG: runSimulation() - current simChartSelection.selectedChart = \(simChartSelection.selectedChart)")
        
        // 1) Apply dictionary-based factor tweaks
        simSettings.applyDictionaryFactorsToSim()
        
        // 2) Respect monthly vs weekly lock
        if self.useMonthly {
            monthlySimSettings.lockedRandomSeedMonthly = lockRandomSeed
        } else {
            simSettings.lockedRandomSeed = lockRandomSeed
        }
        
        let newHash = computeInputsHash()
        simSettings.printAllSettings()
        
        // 3) Load monthly or weekly returns
        if simSettings.periodUnit == .months {
            let btcMonthlyDict = loadBTCMonthlyReturnsAsDict()
            let spMonthlyDict  = loadSP500MonthlyReturnsAsDict()
            let alignedMonthly = alignBTCandSPMonthly(btcDict: btcMonthlyDict, spDict: spMonthlyDict)
            
            historicalBTCMonthlyReturns = alignedMonthly.map { $0.1 }
            sp500MonthlyReturns         = alignedMonthly.map { $0.2 }
            extendedMonthlyReturns      = historicalBTCMonthlyReturns
            
            // Clear weekly
            historicalBTCWeeklyReturns = []
            sp500WeeklyReturns = []
            extendedWeeklyReturns = []
            
            print("Loaded \(historicalBTCMonthlyReturns.count) monthly returns.")
            print("extendedMonthlyReturns = \(extendedMonthlyReturns.count)")
            
        } else {
            let btcWeeklyDict = loadBTCWeeklyReturnsAsDict()
            let spWeeklyDict  = loadSP500WeeklyReturnsAsDict()
            let alignedWeekly = alignBTCandSPWeekly(btcDict: btcWeeklyDict, spDict: spWeeklyDict)
            
            historicalBTCWeeklyReturns = alignedWeekly.map { $0.1 }
            sp500WeeklyReturns         = alignedWeekly.map { $0.2 }
            extendedWeeklyReturns      = historicalBTCWeeklyReturns
            
            // Clear monthly
            historicalBTCMonthlyReturns = []
            sp500MonthlyReturns = []
            extendedMonthlyReturns = []
            
            print("Loaded \(historicalBTCWeeklyReturns.count) weekly returns.")
            print("extendedWeeklyReturns = \(extendedWeeklyReturns.count)")
        }
        
        // 4) Calibrate GARCH if requested
        if simSettings.useGarchVolatility {
            calibrateGarchIfNeeded()
        } else {
            fittedGarchModel = nil
        }
        
        // Prepare
        isCancelled = false
        isLoading = true
        isChartBuilding = false
        monteCarloResults = []
        completedIterations = 0
        
        // 5) Figure out final seed
        let finalSeed: UInt64?
        if self.useMonthly {
            if monthlySimSettings.lockedRandomSeedMonthly {
                finalSeed = monthlySimSettings.seedValueMonthly
                monthlySimSettings.lastUsedSeedMonthly = monthlySimSettings.seedValueMonthly
            } else if monthlySimSettings.useRandomSeedMonthly {
                let newRandomSeed = UInt64.random(in: 0 ..< UInt64.max)
                finalSeed = newRandomSeed
                monthlySimSettings.lastUsedSeedMonthly = newRandomSeed
            } else {
                finalSeed = nil
                monthlySimSettings.lastUsedSeedMonthly = 0
            }
        } else {
            if simSettings.lockedRandomSeed {
                finalSeed = simSettings.seedValue
                simSettings.lastUsedSeed = simSettings.seedValue
            } else if simSettings.useRandomSeed {
                let newRandomSeed = UInt64.random(in: 0 ..< UInt64.max)
                finalSeed = newRandomSeed
                simSettings.lastUsedSeed = newRandomSeed
            } else {
                finalSeed = nil
                simSettings.lastUsedSeed = 0
            }
        }
        
        // 6) Example mempool data
        let mempoolArray = [Double](repeating: 50.0, count: 5000)
        let mempoolDataManager = MempoolDataManager(mempoolData: mempoolArray)
        
        // 6.5) Quick fix for toggling autocorr
        func fixAutocorrAtStartup() {
            if self.useMonthly {
                if monthlySimSettings.useAutoCorrelationMonthly {
                    monthlySimSettings.useAutoCorrelationMonthly = false
                    monthlySimSettings.useAutoCorrelationMonthly = true
                    print("Replicated monthly autocorr toggle off->on behind the scenes.")
                }
            } else {
                if simSettings.useAutoCorrelation {
                    simSettings.useAutoCorrelation = false
                    simSettings.useAutoCorrelation = true
                    print("Replicated weekly autocorr toggle off->on behind the scenes.")
                }
            }
        }
        fixAutocorrAtStartup()
        
        // 7) Dispatch to background
        DispatchQueue.global(qos: .userInitiated).async {
            guard let total = self.inputManager.getParsedIterations(), total > 0 else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            DispatchQueue.main.async {
                self.totalIterations = total
            }
            
            let userInputCAGR       = self.inputManager.getParsedAnnualCAGR()
            let userInputVolatility = Double(self.inputManager.annualVolatility) ?? 1.0
            let finalWeeks          = self.simSettings.userPeriods
            let userPriceUSDAsDouble = NSDecimalNumber(decimal: Decimal(self.simSettings.initialBTCPriceUSD)).doubleValue
            
            print("DEBUG: Going to run simulation with userInputCAGR = \(userInputCAGR), userInputVolatility = \(userInputVolatility)")
            
            // 8) Run simulations
            let (medianRun, allIterations, stepMedianPrices) = runMonteCarloSimulationsWithProgress(
                settings: self.simSettings,
                monthlySettings: self.monthlySimSettings,
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
            
            // Check cancel
            if self.isCancelled {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            DispatchQueue.main.async {
                self.stepMedianBTCs = stepMedianPrices
            }
            
            if allIterations.isEmpty {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            // Build results on main
            DispatchQueue.main.async {
                self.isLoading = false
                self.isChartBuilding = true
                
                // Sort runs by final BTC price
                let finalRuns = allIterations.enumerated().map {
                    ($0.offset, $0.element.last?.btcPriceUSD ?? Decimal.zero, $0.element)
                }
                let sortedRuns = finalRuns.sorted { $0.1 < $1.1 }
                if sortedRuns.isEmpty {
                    self.isChartBuilding = false
                    return
                }
                
                let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex    = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                
                let tenthRun      = sortedRuns[tenthIndex].2
                let medianRun2    = sortedRuns[medianIndex].2
                let ninetiethRun  = sortedRuns[ninetiethIndex].2
                
                self.tenthPercentileResults     = tenthRun
                self.ninetiethPercentileResults = ninetiethRun
                self.medianResults              = medianRun2
                
                // Find run closest to median path
                let bestFitRunIndex = self.findRepresentativeRunIndex(
                    allRuns: allIterations,
                    stepMedianBTC: stepMedianPrices
                )
                let bestFitRun = allIterations[bestFitRunIndex]
                self.monteCarloResults = bestFitRun
                
                print("coordinator.monteCarloResults after run =>")
                for row in self.monteCarloResults.prefix(20) {
                    // ...
                }
                
                print("// DEBUG: 'median final BTC' => iteration #\(sortedRuns[medianIndex].0), final BTC => \(sortedRuns[medianIndex].1)")
                print("// DEBUG: bestFitRun => iteration #\(bestFitRunIndex) chosen by distance.")
                print("// DEBUG: bestFitRun => final BTC => \(bestFitRun.last?.btcPriceUSD ?? 0)")
                
                self.selectedPercentile = .median
                self.allSimData = allIterations
                
                // Convert all runs => faint lines
                let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                let allSimsAsPortfolioPoints = self.convertAllSimsToPortfolioWeekPoints()
                
                // -------------
                // Reuse the ID from the best-fit run in the faint lines array!
                // -------------
                
                // 1) Grab the same run object from allSimsAsWeekPoints
                //    so it has the correct ID for the bestFit.
                let bestFitSim = allSimsAsWeekPoints[bestFitRunIndex]
                let bestFitSimID = bestFitSim.id  // We'll reuse this
                
                // 2) Build new points for BTC or portfolio, as you prefer:
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
                
                // 3) Create new runs with the same ID as bestFitSim
                let bestFitBTC = SimulationRun(id: bestFitSimID, points: bestFitBTCPoints)
                let bestFitPortfolio = SimulationRun(id: bestFitSimID, points: bestFitPortfolioPoints)
                
                // Clear old charts
                self.chartDataCache.chartSnapshot = nil
                self.chartDataCache.chartSnapshotLandscape = nil
                self.chartDataCache.chartSnapshotPortfolio = nil
                self.chartDataCache.chartSnapshotPortfolioLandscape = nil
                
                // Store faint lines & bestFit lines
                self.chartDataCache.allRuns = allSimsAsWeekPoints
                self.chartDataCache.portfolioRuns = allSimsAsPortfolioPoints
                
                // Reuse the same ID
                self.chartDataCache.bestFitRun = [ bestFitBTC ]
                self.chartDataCache.bestFitPortfolioRun = [ bestFitPortfolio ]
                
                self.chartDataCache.storedInputsHash = newHash
                
                let oldSelection = self.simChartSelection.selectedChart
                
                // If user doesn’t want charts, skip
                if !generateGraphs {
                    self.isChartBuilding = false
                    print("DEBUG: runSimulation complete. Not generating charts.")
                    print("DEBUG: runSimulation FINISHED - selectedChart still = \(self.simChartSelection.selectedChart)")
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
                            print("DEBUG: runSimulation finished successfully.")
                            print("DEBUG: runSimulation FINISHED - final simChartSelection.selectedChart = \(self.simChartSelection.selectedChart)")
                        }
                    }
                }
                
                // Extra background processing
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
                    baseLR: 1e-3 // tweak as needed
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
