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
    
    init(chartDataCache: ChartDataCache,
         simSettings: SimulationSettings,
         inputManager: PersistentInputManager)
    {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.inputManager = inputManager
    }
    
    func runSimulation() {
        let newHash = computeInputsHash()
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = \(String(describing: chartDataCache.storedInputsHash))")
        
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
            // We now call getParsedAnnualCAGR() to clamp it to max 1000.
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(self.inputManager.annualVolatility) ?? 1.0) / 100.0
            let userWeeks = self.simSettings.userWeeks
            
            // If initialBTCPriceUSD is a Double, convert to Decimal:
            let userPriceUSDAsDecimal = Decimal(self.simSettings.initialBTCPriceUSD)
            
            // Convert your Decimal to Double right before calling:
            let userPriceUSDAsDouble = NSDecimalNumber(decimal: userPriceUSDAsDecimal).doubleValue

            let (medianRun, allIterations) = runMonteCarloSimulationsWithProgress(
                settings: self.simSettings,
                annualCAGR: userInputCAGR,      // <= clamped from above
                annualVolatility: userInputVolatility,
                correlationWithSP500: 0.0,
                exchangeRateEURUSD: 1.06,
                userWeeks: userWeeks,
                iterations: total,
                initialBTCPriceUSD: userPriceUSDAsDouble, // pass Double here
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
            
            // Sort runs based on final BTC price
            let finalRuns = allIterations.map { ($0.last?.btcPriceUSD ?? Decimal.zero, $0) }
            let sortedRuns = finalRuns.sorted { $0.0 < $1.0 }
            
            if !sortedRuns.isEmpty {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isChartBuilding = true
                    print("// DEBUG: Simulation finished => isChartBuilding=true now.")
                    
                    // Indices
                    let tenthIndex     = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                    let medianIndex    = sortedRuns.count / 2
                    let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                    
                    let tenthRun        = sortedRuns[tenthIndex].1
                    let singleMedianRun = sortedRuns[medianIndex].1
                    let ninetiethRun    = sortedRuns[ninetiethIndex].1
                    let medianLineData  = self.computeMedianSimulationData(allIterations: allIterations)
                    
                    self.tenthPercentileResults = tenthRun
                    self.medianResults = singleMedianRun
                    self.ninetiethPercentileResults = ninetiethRun
                    self.monteCarloResults = medianLineData
                    self.selectedPercentile = .median
                    self.medianResults = medianLineData
                    self.allSimData = allIterations
                    
                    // Convert all runs to [SimulationRun] (each with [WeekPoint(week, Decimal)])
                    let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                    
                    // Clear old snapshots
                    if self.chartDataCache.chartSnapshot != nil {
                        print("// DEBUG: clearing old chartSnapshot.")
                    }
                    self.chartDataCache.chartSnapshot = nil
                    self.chartDataCache.chartSnapshotLandscape = nil
                    self.chartDataCache.allRuns = allSimsAsWeekPoints
                    self.chartDataCache.storedInputsHash = newHash
                    
                    // Build only the portrait snapshot
                    DispatchQueue.main.async {
                        if self.isCancelled {
                            self.isChartBuilding = false
                            return
                        }
                        print("// DEBUG: building chartView (portrait) for layout pass.")
                        
                        let chartView = MonteCarloResultsView(simulations: allSimsAsWeekPoints)
                            .environmentObject(self.chartDataCache)
                            .environmentObject(self.simSettings)
                        
                        DispatchQueue.main.async {
                            if self.isCancelled {
                                self.isChartBuilding = false
                                return
                            }
                            print("// DEBUG: now taking portrait snapshot of chartView.")
                            
                            let snapshot = chartView.snapshot()
                            print("// DEBUG: portrait snapshot => setting chartDataCache.chartSnapshot.")
                            self.chartDataCache.chartSnapshot = snapshot
                            
                            self.isChartBuilding = false
                            self.isSimulationRun = true
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
    
    /// Convert `[[SimulationData]]` to `[SimulationRun]` with Decimal values
    func convertAllSimsToWeekPoints() -> [SimulationRun] {
        allSimData.map { singleRun -> SimulationRun in
            let wpoints = singleRun.map { row in
                WeekPoint(week: row.week, value: row.btcPriceUSD)
            }
            return SimulationRun(points: wpoints)
        }
    }
    
    private func computeInputsHash() -> Int {
        let combinedString = """
        \(inputManager.iterations)_\(inputManager.annualCAGR)_\(inputManager.annualVolatility)_\
        \(simSettings.userWeeks)_\(simSettings.initialBTCPriceUSD)
        """
        return combinedString.hashValue
    }
    
    /// Computes median SimulationData across all runs at each week index
    private func computeMedianSimulationData(allIterations: [[SimulationData]]) -> [SimulationData] {
        guard let firstRun = allIterations.first else { return [] }
        let totalWeeks = firstRun.count
        
        var medianResult: [SimulationData] = []
        
        for w in 0..<totalWeeks {
            // Collect all SimulationData objects at this week
            let allAtWeek = allIterations.compactMap { run -> SimulationData? in
                guard w < run.count else { return nil }
                return run[w]
            }
            
            // If nothing is present, skip
            if allAtWeek.isEmpty { continue }
            
            // 1) Extract Decimal fields
            let allBTCPriceUSD = allAtWeek.map { $0.btcPriceUSD }
            let allBTCPriceEUR = allAtWeek.map { $0.btcPriceEUR }
            let allPortfolioValueEUR = allAtWeek.map { $0.portfolioValueEUR }
            
            // 2) Extract Double fields
            let allStartingBTC = allAtWeek.map { $0.startingBTC }
            let allNetBTCHoldings = allAtWeek.map { $0.netBTCHoldings }
            let allContribEUR = allAtWeek.map { $0.contributionEUR }
            let allFeeEUR = allAtWeek.map { $0.transactionFeeEUR }
            let allNetContribBTC = allAtWeek.map { $0.netContributionBTC }
            let allWithdrawalEUR = allAtWeek.map { $0.withdrawalEUR }
            
            // 3) Compute medians separately
            let medianBTCPriceUSD = medianOfDecimalArray(allBTCPriceUSD)
            let medianBTCPriceEUR = medianOfDecimalArray(allBTCPriceEUR)
            let medianPortfolioValueEUR = medianOfDecimalArray(allPortfolioValueEUR)
            
            let medianStartingBTC = medianOfDoubleArray(allStartingBTC)
            let medianNetBTCHoldings = medianOfDoubleArray(allNetBTCHoldings)
            let medianContributionEUR = medianOfDoubleArray(allContribEUR)
            let medianFeeEUR = medianOfDoubleArray(allFeeEUR)
            let medianNetContributionBTC = medianOfDoubleArray(allNetContribBTC)
            let medianWithdrawalEUR = medianOfDoubleArray(allWithdrawalEUR)

            // 4) Build the new median row
            let medianSimData = SimulationData(
                week: allAtWeek[0].week,
                
                // Double fields
                startingBTC: medianStartingBTC,
                netBTCHoldings: medianNetBTCHoldings,
                
                // Decimal fields
                btcPriceUSD: medianBTCPriceUSD,
                btcPriceEUR: medianBTCPriceEUR,
                portfolioValueEUR: medianPortfolioValueEUR,
                
                // Double fields
                contributionEUR: medianContributionEUR,
                transactionFeeEUR: medianFeeEUR,
                netContributionBTC: medianNetContributionBTC,
                withdrawalEUR: medianWithdrawalEUR
            )
            
            medianResult.append(medianSimData)
        }
        
        return medianResult
    }
    
    private func processAllResults(_ allResults: [[SimulationData]]) {
        // Any post-processing you might need
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
