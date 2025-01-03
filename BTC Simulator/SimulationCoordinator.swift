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

// You can comment out or remove this if unused:
// class ForceLandscapeHostingController<Content: View>: UIHostingController<Content> {
//     override var traitCollection: UITraitCollection {
//         UITraitCollection(traitsFrom: [
//             super.traitCollection,
//             UITraitCollection(horizontalSizeClass: .regular),
//             UITraitCollection(verticalSizeClass: .compact),
//             UITraitCollection(userInterfaceIdiom: .phone)
//         ])
//     }
// }

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
            // Check iteration
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
            
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(self.inputManager.annualVolatility) ?? 1.0) / 100.0
            let userWeeks = self.simSettings.userWeeks
            let userPriceUSD = self.simSettings.initialBTCPriceUSD
            
            // The core Monte Carlo call
            let (medianRun, allIterations) = runMonteCarloSimulationsWithProgress(
                settings: self.simSettings,
                annualCAGR: userInputCAGR,
                annualVolatility: userInputVolatility,
                correlationWithSP500: 0.0,
                exchangeRateEURUSD: 1.06,
                userWeeks: userWeeks,
                iterations: total,
                initialBTCPriceUSD: userPriceUSD,
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
            
            // Sort runs
            let finalRuns = allIterations.map { ($0.last?.btcPriceUSD ?? 0.0, $0) }
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
                    
                    // Convert to [SimulationRun]
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
                            // .environmentObject(appViewModel)  // REMOVED: no longer needed
                        
                        DispatchQueue.main.async {
                            if self.isCancelled {
                                self.isChartBuilding = false
                                return
                            }
                            print("// DEBUG: now taking portrait snapshot of chartView.")
                            
                            let snapshot = chartView.snapshot()
                            print("// DEBUG: portrait snapshot => setting chartDataCache.chartSnapshot.")
                            self.chartDataCache.chartSnapshot = snapshot
                            
                            // We'll squish in geometry approach as needed
                            
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
    
    private func computeMedianSimulationData(allIterations: [[SimulationData]]) -> [SimulationData] {
        guard let firstRun = allIterations.first else { return [] }
        let totalWeeks = firstRun.count
        
        var medianResult: [SimulationData] = []
        
        for w in 0..<totalWeeks {
            let allAtWeek = allIterations.compactMap { run -> SimulationData? in
                guard w < run.count else { return nil }
                return run[w]
            }
            if allAtWeek.isEmpty { continue }
            
            let sortedBTCUSD = allAtWeek.map { $0.btcPriceUSD }.sorted()
            // etc... for other properties, then find median.
            
            func medianOfSorted(_ arr: [Double]) -> Double {
                if arr.isEmpty { return 0.0 }
                let mid = arr.count / 2
                if arr.count.isMultiple(of: 2) {
                    return (arr[mid] + arr[mid - 1]) / 2.0
                } else {
                    return arr[mid]
                }
            }
            
            let medianSimData = SimulationData(
                week: allAtWeek[0].week,
                startingBTC: medianOfSorted(allAtWeek.map { $0.startingBTC }.sorted()),
                netBTCHoldings: medianOfSorted(allAtWeek.map { $0.netBTCHoldings }.sorted()),
                btcPriceUSD: medianOfSorted(sortedBTCUSD),
                btcPriceEUR: medianOfSorted(allAtWeek.map { $0.btcPriceEUR }.sorted()),
                portfolioValueEUR: medianOfSorted(allAtWeek.map { $0.portfolioValueEUR }.sorted()),
                contributionEUR: medianOfSorted(allAtWeek.map { $0.contributionEUR }.sorted()),
                transactionFeeEUR: medianOfSorted(allAtWeek.map { $0.transactionFeeEUR }.sorted()),
                netContributionBTC: medianOfSorted(allAtWeek.map { $0.netContributionBTC }.sorted()),
                withdrawalEUR: medianOfSorted(allAtWeek.map { $0.withdrawalEUR }.sorted())
            )
            medianResult.append(medianSimData)
        }
        return medianResult
    }
    
    private func processAllResults(_ allResults: [[SimulationData]]) {
        // Any post-processing you want
    }
}
