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

        // A convenience flag:
        let isMonthly = self.useMonthly

        // 1) Apply factor tweaks + set random seed lock
        //    If monthly => apply monthly factor logic & lock monthly seed
        //    If weekly => apply weekly factor logic & lock weekly seed
        if isMonthly {
            // If you have a monthly "applyDictionaryFactors" method, call it here
            // monthlySimSettings.applyDictionaryFactorsToSimMonthly()  // if it exists

            // Lock or unlock seed:
            monthlySimSettings.lockedRandomSeedMonthly = lockRandomSeed

            // Print or log monthly settings to confirm
            print("""
            DEBUG (Monthly Mode):
              userPeriodsMonthly = \(monthlySimSettings.userPeriodsMonthly)
              initialBTCPriceUSDMonthly = \(monthlySimSettings.initialBTCPriceUSDMonthly)
              startingBalanceMonthly = \(monthlySimSettings.startingBalanceMonthly)
              averageCostBasisMonthly = \(monthlySimSettings.averageCostBasisMonthly)
              currencyPreferenceMonthly = \(monthlySimSettings.currencyPreferenceMonthly)
            """)

        } else {
            // Weekly path
            simSettings.applyDictionaryFactorsToSim()
            simSettings.lockedRandomSeed = lockRandomSeed
            simSettings.printAllSettings()
        }

        // 2) Load historical returns (monthly if isMonthly, else weekly)
        if isMonthly {
            let btcMonthlyDict = loadBTCMonthlyReturnsAsDict()
            let spMonthlyDict  = loadSP500MonthlyReturnsAsDict()
            let alignedMonthly = alignBTCandSPMonthly(btcDict: btcMonthlyDict, spDict: spMonthlyDict)

            historicalBTCMonthlyReturns = alignedMonthly.map { $0.1 }
            sp500MonthlyReturns         = alignedMonthly.map { $0.2 }
            extendedMonthlyReturns      = historicalBTCMonthlyReturns

            // Clear out weekly arrays
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

            // Clear out monthly arrays
            historicalBTCMonthlyReturns = []
            sp500MonthlyReturns = []
            extendedMonthlyReturns = []

            print("Loaded \(historicalBTCWeeklyReturns.count) weekly returns.")
            print("extendedWeeklyReturns = \(extendedWeeklyReturns.count)")
        }

        // 3) Decide if GARCH is on (check monthlySimSettings or simSettings)
        let isGarchOn = isMonthly
            ? monthlySimSettings.useGarchVolatilityMonthly
            : simSettings.useGarchVolatility

        if isGarchOn {
            calibrateGarchIfNeeded()  // This checks if periodUnit == .months or .weeks internally
        } else {
            fittedGarchModel = nil
        }

        // 4) Compute final random seed
        let finalSeed: UInt64?
        if isMonthly {
            if monthlySimSettings.lockedRandomSeedMonthly {
                finalSeed = monthlySimSettings.seedValueMonthly
                monthlySimSettings.lastUsedSeedMonthly = monthlySimSettings.seedValueMonthly
            } else if monthlySimSettings.useRandomSeedMonthly {
                let newRand = UInt64.random(in: 0..<UInt64.max)
                finalSeed = newRand
                monthlySimSettings.lastUsedSeedMonthly = newRand
            } else {
                finalSeed = nil
                monthlySimSettings.lastUsedSeedMonthly = 0
            }
        } else {
            if simSettings.lockedRandomSeed {
                finalSeed = simSettings.seedValue
                simSettings.lastUsedSeed = simSettings.seedValue
            } else if simSettings.useRandomSeed {
                let newRand = UInt64.random(in: 0..<UInt64.max)
                finalSeed = newRand
                simSettings.lastUsedSeed = newRand
            } else {
                finalSeed = nil
                simSettings.lastUsedSeed = 0
            }
        }

        // 5) Quick fix for toggling autocorr each run
        func fixAutocorrAtStartup() {
            if isMonthly {
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

        // 6) Prep overall period count, BTC price, etc.
        let periodCount = isMonthly ? monthlySimSettings.userPeriodsMonthly : simSettings.userPeriods
        let initialBTCPriceUSD = isMonthly
            ? monthlySimSettings.initialBTCPriceUSDMonthly
            : simSettings.initialBTCPriceUSD

        print("DEBUG: Running simulation with \(periodCount) \(isMonthly ? "months" : "weeks"), starting BTC=\(initialBTCPriceUSD)")

        // 7) Mark ourselves busy
        let newHash = computeInputsHash()
        isCancelled = false
        isLoading = true
        isChartBuilding = false
        monteCarloResults.removeAll()
        completedIterations = 0

        // 8) Dispatch heavy Monte Carlo to background
        DispatchQueue.global(qos: .userInitiated).async {
            guard let totalIterations = self.inputManager.getParsedIterations(),
                  totalIterations > 0
            else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            
            DispatchQueue.main.async {
                self.totalIterations = totalIterations
            }

            // Annual CAGR & volatility from user
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR()
            let userInputVol  = Double(self.inputManager.annualVolatility) ?? 1.0

            print("DEBUG: Going to run simulation with userInputCAGR = \(userInputCAGR), userInputVolatility = \(userInputVol)")
            
            // 9) Actually run the simulation
            let (medianRun, allIterations, stepMedianPrices) = runMonteCarloSimulationsWithProgress(
                settings: self.simSettings,
                monthlySettings: self.monthlySimSettings,
                annualCAGR: userInputCAGR,
                annualVolatility: userInputVol,
                correlationWithSP500: 0.0,
                exchangeRateEURUSD: 1.06,
                userWeeks: periodCount,
                iterations: totalIterations,
                initialBTCPriceUSD: initialBTCPriceUSD,
                isCancelled: { self.isCancelled },
                progressCallback: { completedCount in
                    if !self.isCancelled {
                        DispatchQueue.main.async {
                            self.completedIterations = completedCount
                        }
                    }
                },
                seed: finalSeed,
                mempoolDataManager: MempoolDataManager(
                    mempoolData: [Double](repeating: 50.0, count: 5000)
                ),
                fittedGarchModel: self.fittedGarchModel
            )

            // 10) Check for cancel or empty
            if self.isCancelled {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }
            if allIterations.isEmpty {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            // 11) Switch back to main thread to finalize results & build charts
            DispatchQueue.main.async {
                self.isLoading = false
                self.isChartBuilding = true
                self.stepMedianBTCs = stepMedianPrices

                // Sort runs, pick 10th/median/90th, find best fit, etc.
                let finalRuns = allIterations.enumerated().map { (idx, run) -> (Int, Decimal, [SimulationData]) in
                    let finalBTC = run.last?.btcPriceUSD ?? Decimal.zero
                    return (idx, finalBTC, run)
                }
                let sortedRuns = finalRuns.sorted { $0.1 < $1.1 }
                if sortedRuns.isEmpty {
                    self.isChartBuilding = false
                    return
                }
                let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex    = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))

                self.tenthPercentileResults     = sortedRuns[tenthIndex].2
                self.medianResults              = sortedRuns[medianIndex].2
                self.ninetiethPercentileResults = sortedRuns[ninetiethIndex].2

                // Find representative “best fit” run
                let bestFitRunIndex = self.findRepresentativeRunIndex(
                    allRuns: allIterations,
                    stepMedianBTC: stepMedianPrices
                )
                let bestFitRun = allIterations[bestFitRunIndex]
                self.monteCarloResults = bestFitRun

                print("coordinator.monteCarloResults after run =>")
                print("// DEBUG: median final BTC => iteration #\(sortedRuns[medianIndex].0), final BTC => \(sortedRuns[medianIndex].1)")
                print("// DEBUG: bestFitRun => iteration #\(bestFitRunIndex) chosen by distance. final BTC => \(bestFitRun.last?.btcPriceUSD ?? 0)")

                self.selectedPercentile = .median
                self.allSimData = allIterations

                // Convert all runs => faint lines for chart
                let allSimsAsWeekPoints       = self.convertAllSimsToWeekPoints()
                let allSimsAsPortfolioPoints  = self.convertAllSimsToPortfolioWeekPoints()
                
                let bestFitSim = allSimsAsWeekPoints[bestFitRunIndex]
                let bestFitSimID = bestFitSim.id
                let bestFitBTCPoints = bestFitRun.map { row in
                    WeekPoint(week: row.week, value: row.btcPriceUSD)
                }
                let bestFitPortfolioPoints = bestFitRun.map { row in
                    // If monthly => check monthly currency preference
                    // else weekly => check weekly currency preference
                    let isEUR = isMonthly
                        ? (self.monthlySimSettings.currencyPreferenceMonthly == .eur)
                        : (self.simSettings.currencyPreference == .eur)
                    
                    return isEUR ? row.portfolioValueEUR : row.portfolioValueUSD
                }.enumerated().map { (idx, val) in
                    WeekPoint(week: bestFitRun[idx].week, value: val)
                }

                let bestFitBTC = SimulationRun(id: bestFitSimID, points: bestFitBTCPoints)
                let bestFitPortfolio = SimulationRun(id: bestFitSimID, points: bestFitPortfolioPoints)

                // Clear old charts
                self.chartDataCache.chartSnapshot = nil
                self.chartDataCache.chartSnapshotLandscape = nil
                self.chartDataCache.chartSnapshotPortfolio = nil
                self.chartDataCache.chartSnapshotPortfolioLandscape = nil

                // Save new runs in chartDataCache
                self.chartDataCache.allRuns               = allSimsAsWeekPoints
                self.chartDataCache.portfolioRuns         = allSimsAsPortfolioPoints
                self.chartDataCache.bestFitRun            = [bestFitBTC]
                self.chartDataCache.bestFitPortfolioRun   = [bestFitPortfolio]
                self.chartDataCache.storedInputsHash      = newHash

                // Optionally build charts if generateGraphs == true
                let oldSelection = self.simChartSelection.selectedChart
                if !generateGraphs {
                    self.isChartBuilding = false
                    print("DEBUG: runSimulation complete. Not generating charts.")
                    return
                }
                
                // Chart building snippet, same as before...
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
                        }
                    }
                }

                // Extra background processing if needed
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
