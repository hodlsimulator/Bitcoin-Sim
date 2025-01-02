//
//  SimulationCoordinator.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/01/2025.
//

import SwiftUI

// MARK: - PercentileChoice
enum PercentileChoice {
    case tenth, median, ninetieth
}

class SimulationCoordinator: ObservableObject {
    // We store references to other needed objects, e.g. chartDataCache
    // and whatever else you used in ContentView (like simSettings).
    
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
    @State private var medianSimData: [SimulationData] = []
    
    // References to your environment objects or input managers:
    var chartDataCache: ChartDataCache
    private var simSettings: SimulationSettings
    private var inputManager: PersistentInputManager
    
    // A typical init injecting these dependencies
    init(chartDataCache: ChartDataCache,
         simSettings: SimulationSettings,
         inputManager: PersistentInputManager)
    {
        self.chartDataCache = chartDataCache
        self.simSettings = simSettings
        self.inputManager = inputManager
    }
    
    // MARK: - Run Simulation
    func runSimulation() {
        let newHash = computeInputsHash()
        print("// DEBUG: runSimulation() => newHash = \(newHash), storedInputsHash = \(String(describing: chartDataCache.storedInputsHash))")
        
        // CSV loads
        historicalBTCWeeklyReturns = loadBTCWeeklyReturns()
        sp500WeeklyReturns = loadSP500WeeklyReturns()
        
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
        
        // Do the heavy simulation on a background thread:
        DispatchQueue.global(qos: .userInitiated).async {
            guard let total = self.inputManager.getParsedIterations(), total > 0 else {
                print("// DEBUG: No valid iteration => bailing out.")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            // Let the UI know how many total iterations we’ll run
            DispatchQueue.main.async {
                self.totalIterations = total
            }
            
            let userInputCAGR = self.inputManager.getParsedAnnualCAGR() / 100.0
            let userInputVolatility = (Double(self.inputManager.annualVolatility) ?? 1.0) / 100.0
            let userWeeks = self.simSettings.userWeeks
            let userPriceUSD = self.simSettings.initialBTCPriceUSD
            
            print("// DEBUG: Iterations from inputManager => \(self.inputManager.iterations)")
            print("// DEBUG: runMonteCarloSimulationsWithProgress(...)")
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
                // Here's the key: each iteration calls progressCallback.
                // We dispatch to main so SwiftUI sees completedIterations change.
                progressCallback: { completed in
                    if !self.isCancelled {
                        DispatchQueue.main.async {
                            self.completedIterations = completed
                            print("// DEBUG: progress = \(completed)")
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
            
            // Sort final runs by last week's BTC price
            let finalRuns = allIterations.map { ($0.last?.btcPriceUSD ?? 0.0, $0) }
            let sortedRuns = finalRuns.sorted { $0.0 < $1.0 }
            
            if !sortedRuns.isEmpty {
                let tenthIndex = max(0, Int(Double(sortedRuns.count - 1) * 0.10))
                let medianIndex = sortedRuns.count / 2
                let ninetiethIndex = min(sortedRuns.count - 1, Int(Double(sortedRuns.count - 1) * 0.90))
                
                let tenthRun = sortedRuns[tenthIndex].1
                let singleMedianRun = sortedRuns[medianIndex].1
                let ninetiethRun = sortedRuns[ninetiethIndex].1
                let medianLineData = self.computeMedianSimulationData(allIterations: allIterations)
                
                DispatchQueue.main.async {
                    // Simulation done => turn off isLoading
                    self.isLoading = false

                    // Start building chart
                    self.isChartBuilding = true
                    print("// DEBUG: Simulation finished => isChartBuilding=true now.")

                    // *** NEW PRINT STATEMENT ***
                    print("// DEBUG: Now assigning final results and preparing portrait snapshot…")

                    // Assign results
                    self.tenthPercentileResults = tenthRun
                    self.medianResults = singleMedianRun
                    self.ninetiethPercentileResults = ninetiethRun
                    self.monteCarloResults = medianLineData
                    self.selectedPercentile = .median
                    self.medianResults = medianLineData
                    self.allSimData = allIterations
                    
                    let allSimsAsWeekPoints = self.convertAllSimsToWeekPoints()
                    
                    // Clear old snapshot
                    if self.chartDataCache.chartSnapshot != nil {
                        print("// DEBUG: clearing old chartSnapshot.")
                    }
                    self.chartDataCache.chartSnapshot = nil
                    self.chartDataCache.chartSnapshotLandscape = nil
                    self.chartDataCache.allRuns = allSimsAsWeekPoints
                    self.chartDataCache.storedInputsHash = newHash
                    self.medianSimData = medianLineData
                    
                    // 1) Build portrait chart & snapshot
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
                            print("// DEBUG: portrait snapshot built => setting chartDataCache.chartSnapshot.")
                            self.chartDataCache.chartSnapshot = snapshot
                            
                            // 2) Build landscape chart & snapshot
                            print("// DEBUG: building wide chart for layout pass.")
                            
                            let landscapeChart = MonteCarloResultsView(simulations: allSimsAsWeekPoints)
                                .environmentObject(self.chartDataCache)
                                .environmentObject(self.simSettings)
                                .frame(width: 800, height: 400)
                            
                            let hostingControllerWide = UIHostingController(rootView: landscapeChart)
                            hostingControllerWide.view.frame = CGRect(x: 0, y: 0, width: 800, height: 400)
                            hostingControllerWide.view.layoutIfNeeded()
                            
                            print("// DEBUG: taking 'truly wide' landscape snapshot.")
                            let rendererWide = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 400))
                            let wideSnapshot = rendererWide.image { ctx in
                                hostingControllerWide.view.layer.render(in: ctx.cgContext)
                            }
                            self.chartDataCache.chartSnapshotLandscape = wideSnapshot
                            
                            // Done building => user can see results
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
            
            // Process all results on a background thread
            DispatchQueue.global(qos: .background).async {
                self.processAllResults(allIterations)
            }
        }
    }
    
    // MARK: - Convert all runs to [SimulationRun]
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
    
    // MARK: - Median logic
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
            
            let sortedStartingBTC = allAtWeek.map { $0.startingBTC }.sorted()
            let sortedNetBTCHoldings = allAtWeek.map { $0.netBTCHoldings }.sorted()
            let sortedBtcPriceUSD = allAtWeek.map { $0.btcPriceUSD }.sorted()
            let sortedBtcPriceEUR = allAtWeek.map { $0.btcPriceEUR }.sorted()
            let sortedPortfolioValueEUR = allAtWeek.map { $0.portfolioValueEUR }.sorted()
            let sortedContributionEUR = allAtWeek.map { $0.contributionEUR }.sorted()
            let sortedFeeEUR = allAtWeek.map { $0.transactionFeeEUR }.sorted()
            let sortedNetContribBTC = allAtWeek.map { $0.netContributionBTC }.sorted()
            let sortedWithdrawalEUR = allAtWeek.map { $0.withdrawalEUR }.sorted()
            
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
                startingBTC: medianOfSorted(sortedStartingBTC),
                netBTCHoldings: medianOfSorted(sortedNetBTCHoldings),
                btcPriceUSD: medianOfSorted(sortedBtcPriceUSD),
                btcPriceEUR: medianOfSorted(sortedBtcPriceEUR),
                portfolioValueEUR: medianOfSorted(sortedPortfolioValueEUR),
                contributionEUR: medianOfSorted(sortedContributionEUR),
                transactionFeeEUR: medianOfSorted(sortedFeeEUR),
                netContributionBTC: medianOfSorted(sortedNetContribBTC),
                withdrawalEUR: medianOfSorted(sortedWithdrawalEUR)
            )
            medianResult.append(medianSimData)
        }
        return medianResult
    }
    
    private func processAllResults(_ allResults: [[SimulationData]]) {
            // ...
        }
}
