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
    @Published var isCancelled: Bool = false
    
    @Published var monteCarloResults: [SimulationData] = []
    @Published var completedIterations: Int = 0
    @Published var totalIterations: Int = 1000
    
    @Published var tenthPercentileResults: [SimulationData] = []
    @Published var medianResults: [SimulationData] = []
    @Published var ninetiethPercentileResults: [SimulationData] = []
    @Published var selectedPercentile: PercentileChoice = .median
    
    @Published var allSimData: [[SimulationData]] = []
    
    // Step-by-step median BTC prices (weekly or monthly)
    @Published var stepMedianBTCs: [Decimal] = []
    // Step-by-step median *portfolio* values (so we can do best-fit for portfolio separately)
    @Published var stepMedianPortfolio: [Decimal] = []
    
    @Published var useMonthly: Bool = false

    var chartDataCache: ChartDataCache
    var mempoolDataManager: MempoolDataManager?
    private(set) var simSettings: SimulationSettings
    private var inputManager: PersistentInputManager
        
    @Published var simChartSelection: SimChartSelection

    private var fittedGarchModel: GarchModel? = nil

    // We keep historical returns in arrays for either weekly or monthly:
    private var historicalBTCWeeklyReturns: [Double] = []
    private var sp500WeeklyReturns: [Double] = []
    private var historicalBTCMonthlyReturns: [Double] = []
    private var sp500MonthlyReturns: [Double] = []
    
    // Extended returns for bootstrap or GARCH
    private var extendedWeeklyReturns: [Double] = []
    private var extendedMonthlyReturns: [Double] = []
    
    private var monthlySimSettings: MonthlySimulationSettings
    private var idleManager: IdleManager

    // Let the coordinator notify our SwiftUI view (or metal chart) that new data is ready
    var onChartDataUpdated: (() -> Void)?

    init(
        chartDataCache: ChartDataCache,
        simSettings: SimulationSettings,
        monthlySimSettings: MonthlySimulationSettings,
        inputManager: PersistentInputManager,
        simChartSelection: SimChartSelection,
        idleManager: IdleManager
    ) {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.monthlySimSettings = monthlySimSettings
        self.inputManager = inputManager
        self.simChartSelection = simChartSelection
        self.idleManager = idleManager
    }
    
    func runSimulation(generateGraphs: Bool, lockRandomSeed: Bool) {
        print("Coordinator ID in runSimulation =>", ObjectIdentifier(self))
        print("DEBUG: runSimulation() - current simChartSelection.selectedChart = \(simChartSelection.selectedChart)")
        
        let isMonthly = self.useMonthly

        // 1) Apply factor tweaks + set random seed lock
        if isMonthly {
            monthlySimSettings.lockedRandomSeedMonthly = lockRandomSeed
            print("""
            DEBUG (Monthly Mode):
              userPeriodsMonthly = \(monthlySimSettings.userPeriodsMonthly)
              initialBTCPriceUSDMonthly = \(monthlySimSettings.initialBTCPriceUSDMonthly)
              startingBalanceMonthly = \(monthlySimSettings.startingBalanceMonthly)
              averageCostBasisMonthly = \(monthlySimSettings.averageCostBasisMonthly)
              currencyPreferenceMonthly = \(monthlySimSettings.currencyPreferenceMonthly)
            """)
        } else {
            simSettings.applyDictionaryFactorsToSim()
            simSettings.lockedRandomSeed = lockRandomSeed
            simSettings.printAllSettings()
        }

        // 2) Load historical returns (weekly or monthly)
        if isMonthly {
            let btcMonthlyDict = loadBTCMonthlyReturnsAsDict()
            let spMonthlyDict  = loadSP500MonthlyReturnsAsDict()
            let alignedMonthly = alignBTCandSPMonthly(btcDict: btcMonthlyDict, spDict: spMonthlyDict)

            historicalBTCMonthlyReturns = alignedMonthly.map { $0.1 }
            sp500MonthlyReturns         = alignedMonthly.map { $0.2 }
            extendedMonthlyReturns      = historicalBTCMonthlyReturns

            // Clear weekly arrays since we're in monthly mode:
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

            // Clear monthly arrays since we're in weekly mode:
            historicalBTCMonthlyReturns = []
            sp500MonthlyReturns = []
            extendedMonthlyReturns = []

            print("Loaded \(historicalBTCWeeklyReturns.count) weekly returns.")
            print("extendedWeeklyReturns = \(extendedWeeklyReturns.count)")
        }

        // 3) Decide if GARCH is on
        let isGarchOn = isMonthly
            ? monthlySimSettings.useGarchVolatilityMonthly
            : simSettings.useGarchVolatility
        
        if isGarchOn {
            calibrateGarchIfNeeded()
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

            // If empty or cancelled, bail out
            if self.isCancelled || allIterations.isEmpty {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            // 10) Switch back to main thread to finalize results
            DispatchQueue.main.async {
                self.isLoading = false
                self.isChartBuilding = true
                // stepMedianBTCs is from aggregator
                self.stepMedianBTCs = stepMedianPrices

                // Sort runs by final BTC price => pick 10th / median / 90th
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

                // We still compute stepMedianPortfolio for reference, but we won't pick the best-fit run for it
                self.stepMedianPortfolio = self.computeStepMedianPortfolio(
                    allIterations: allIterations,
                    isMonthly: isMonthly
                )

                // *** A) We find the best-fit run for BTC only
                let bestFitRunIndexBTC = self.findRepresentativeRunIndexByBTC(
                    allRuns: allIterations,
                    stepMedianBTC: self.stepMedianBTCs
                )
                let bestFitRun = allIterations[bestFitRunIndexBTC]

                // *** B) We'll use THAT same run for the portfolio best-fit line (no separate aggregator for portfolio)
                self.monteCarloResults = bestFitRun  // convenience storage
                print("DEBUG: bestFitRun BTC => iteration #\(bestFitRunIndexBTC). Using same iteration for portfolio best-fit.")

                self.selectedPercentile = .median
                self.allSimData = allIterations

                // Convert all runs => faint lines for chart
                let allSimsAsWeekPoints       = self.convertAllSimsToWeekPoints()
                let allSimsAsPortfolioPoints  = self.convertAllSimsToPortfolioWeekPoints()

                // *** Reuse the faint-line ID for the BTC best-fit
                let bestFitFaintLineBTC = allSimsAsWeekPoints[bestFitRunIndexBTC]
                let bestFitSimIDBTC = bestFitFaintLineBTC.id
                let bestFitBTCPoints = bestFitRun.map { row in
                    WeekPoint(week: row.week, value: row.btcPriceUSD)
                }
                let bestFitBTC = SimulationRun(id: bestFitSimIDBTC, points: bestFitBTCPoints)

                // *** For portfolio, also use bestFitRunIndexBTC
                let bestFitFaintLinePortfolio = allSimsAsPortfolioPoints[bestFitRunIndexBTC]
                let bestFitSimIDPort = bestFitFaintLinePortfolio.id
                let bestFitPortfolioPoints = bestFitRun.map { row in
                    let isEUR = isMonthly
                        ? (self.monthlySimSettings.currencyPreferenceMonthly == .eur)
                        : (self.simSettings.currencyPreference == .eur)
                    return WeekPoint(
                        week: row.week,
                        value: isEUR ? row.portfolioValueEUR : row.portfolioValueUSD
                    )
                }
                let bestFitPortfolio = SimulationRun(id: bestFitSimIDPort, points: bestFitPortfolioPoints)

                // 11) Clear old charts
                self.chartDataCache.chartSnapshot = nil
                self.chartDataCache.chartSnapshotLandscape = nil
                self.chartDataCache.chartSnapshotPortfolio = nil
                self.chartDataCache.chartSnapshotPortfolioLandscape = nil

                // 12) Save new runs in chartDataCache
                self.chartDataCache.allRuns             = allSimsAsWeekPoints
                self.chartDataCache.portfolioRuns       = allSimsAsPortfolioPoints
                self.chartDataCache.bestFitRun          = [bestFitBTC]       // same iteration as BTC
                self.chartDataCache.bestFitPortfolioRun = [bestFitPortfolio] // same iteration
                self.chartDataCache.storedInputsHash    = newHash

                // 13) Let the chart know we updated data
                self.onChartDataUpdated?()

                // 14) Optionally build chart snapshots
                let oldSelection = self.simChartSelection.selectedChart
                if !generateGraphs {
                    self.isChartBuilding = false
                    print("DEBUG: runSimulation complete. Not generating charts.")
                    return
                }
                
                DispatchQueue.main.async {
                    if self.isCancelled {
                        self.isChartBuilding = false
                        return
                    }
                    
                    // Build BTC chart
                    self.simChartSelection.selectedChart = .btcPrice
                    let btcChartView = MonteCarloResultsView(onSwitchToPortfolio: {
                        // If you have a navigateTo(.portfolio) or other code, call it here.
                        // Otherwise, leave it empty if you don’t need that.
                    })
                    .environmentObject(self)
                    .environmentObject(self.chartDataCache)
                    .environmentObject(self.simSettings)
                    .environmentObject(self.simChartSelection)
                    .environmentObject(self.idleManager)
                    
                    let btcSnapshot = btcChartView.snapshot()
                    self.chartDataCache.chartSnapshot = btcSnapshot

                    // Then build portfolio chart
                    self.simChartSelection.selectedChart = .cumulativePortfolio
                    let portfolioChartView = MonteCarloResultsView(onSwitchToPortfolio: {
                        // Similar closure as above, if needed
                    })
                    .environmentObject(self)
                    .environmentObject(self.chartDataCache)
                    .environmentObject(self.simSettings)
                    .environmentObject(self.simChartSelection)
                    .environmentObject(self.idleManager)
                    
                    let portfolioSnapshot = portfolioChartView.snapshot()
                    self.chartDataCache.chartSnapshotPortfolio = portfolioSnapshot

                    // Restore original chart selection
                    self.simChartSelection.selectedChart = oldSelection
                    self.isChartBuilding = false
                    print("DEBUG: runSimulation finished successfully.")
                }

                // Extra background if needed
                DispatchQueue.global(qos: .background).async {
                    self.processAllResults(allIterations)
                }
            }
        }
    }
    
    // MARK: - GARCH ADAM CALIBRATION
    private func calibrateGarchIfNeeded() {
        let adamCalibrator = GarchAdamCalibrator()
        
        // NOTE: We look at simSettings.periodUnit. If .months, we clamp more aggressively.
        // If you truly want to clamp GARCH for monthly, pass timeFrame: .monthly and set
        // small maxVarianceClamp & small (alpha+beta) limit in GarchAdamCalibrator itself.
        
        if simSettings.periodUnit == .months {
            if !historicalBTCMonthlyReturns.isEmpty {
                // >>> TWEAK HERE <<< You can clamp further by lowering maxVarianceClamp,
                // or scaling monthly returns more.
                // e.g. scaleForMonthly: 0.05 => scale monthly returns to 5%.
                // e.g. timeFrame: .monthly => alpha+beta <= 0.001 in the calibrator code.
                let model = adamCalibrator.calibrate(
                    returns: historicalBTCMonthlyReturns,
                    iterations: 3000,
                    baseLR: 1e-3,
                    timeFrame: .monthly,         // Identify it's monthly for stronger clamp
                    maxVarianceClamp: 0.0,       // <= clamp large variance
                    scaleForMonthly: 0.8         // <= shrink monthly returns to 50%
                )
                fittedGarchModel = model
                print("GARCH (Adam) Calibrated (Monthly): (ω, α, β) =", model.omega, model.alpha, model.beta)
            } else {
                print("No monthly data for GARCH calibration.")
            }
        } else {
            if !historicalBTCWeeklyReturns.isEmpty {
                // For weekly, we can be more lenient or turn it off completely if you want
                let model = adamCalibrator.calibrate(
                    returns: historicalBTCWeeklyReturns,
                    iterations: 3000,
                    baseLR: 1e-3,
                    timeFrame: .weekly,
                    maxVarianceClamp: 1.0, // you can clamp less for weekly
                    scaleForMonthly: 1.0   // not used for weekly
                )
                fittedGarchModel = model
                print("GARCH (Adam) Calibrated (Weekly): (ω, α, β) =", model.omega, model.alpha, model.beta)
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
                // Decide EUR vs USD based on user preference:
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

    // MARK: - Compute step-wise median *portfolio*
    private func computeStepMedianPortfolio(allIterations: [[SimulationData]], isMonthly: Bool) -> [Decimal] {
        guard !allIterations.isEmpty else { return [] }

        let maxSteps = allIterations[0].count
        var medians = [Decimal](repeating: 0, count: maxSteps)

        for i in 0..<maxSteps {
            var stepValues = [Decimal]()
            for run in allIterations {
                let row = run[i]
                let isEUR = isMonthly
                    ? (monthlySimSettings.currencyPreferenceMonthly == .eur)
                    : (simSettings.currencyPreference == .eur)
                let portfolioVal = isEUR ? row.portfolioValueEUR : row.portfolioValueUSD
                stepValues.append(portfolioVal)
            }
            stepValues.sort()
            let midIndex = stepValues.count / 2
            if stepValues.count % 2 == 0 {
                let val1 = stepValues[midIndex - 1]
                let val2 = stepValues[midIndex]
                medians[i] = (val1 + val2) / Decimal(2)
            } else {
                medians[i] = stepValues[midIndex]
            }
        }
        return medians
    }
}

// MARK: - "Representative Run" logic
extension SimulationCoordinator {
    fileprivate func findRepresentativeRunIndexByBTC(
        allRuns: [[SimulationData]],
        stepMedianBTC: [Decimal]
    ) -> Int {
        var minDistance = Double.greatestFiniteMagnitude
        var bestIndex = 0
        
        for (i, run) in allRuns.enumerated() {
            let dist = computeDistanceFromBTCMedian(run: run, stepMedianBTC: stepMedianBTC)
            if dist < minDistance {
                minDistance = dist
                bestIndex = i
            }
        }
        return bestIndex
    }
    
    fileprivate func findRepresentativeRunIndexByPortfolio(
        allRuns: [[SimulationData]],
        stepMedianPortfolio: [Decimal],
        isMonthly: Bool
    ) -> Int {
        var minDistance = Double.greatestFiniteMagnitude
        var bestIndex = 0
        
        for (i, run) in allRuns.enumerated() {
            let dist = computeDistanceFromPortfolioMedian(
                run: run,
                stepMedianPortfolio: stepMedianPortfolio,
                isMonthly: isMonthly
            )
            if dist < minDistance {
                minDistance = dist
                bestIndex = i
            }
        }
        return bestIndex
    }
    
    fileprivate func computeDistanceFromBTCMedian(
        run: [SimulationData],
        stepMedianBTC: [Decimal]
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
    
    fileprivate func computeDistanceFromPortfolioMedian(
        run: [SimulationData],
        stepMedianPortfolio: [Decimal],
        isMonthly: Bool
    ) -> Double {
        var totalDist = 0.0
        let count = min(run.count, stepMedianPortfolio.count)
        
        let isEUR = isMonthly
            ? (monthlySimSettings.currencyPreferenceMonthly == .eur)
            : (simSettings.currencyPreference == .eur)
        
        for step in 0..<count {
            let runVal = isEUR
                ? NSDecimalNumber(decimal: run[step].portfolioValueEUR).doubleValue
                : NSDecimalNumber(decimal: run[step].portfolioValueUSD).doubleValue
            let medianVal = NSDecimalNumber(decimal: stepMedianPortfolio[step]).doubleValue
            totalDist += abs(runVal - medianVal)
        }
        return totalDist
    }
}
