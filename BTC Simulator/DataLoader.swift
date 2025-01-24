//
//  DataLoader.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/01/2025.
//

import Foundation

func loadAndAlignWeeklyData() {
    let btcWeeklyDict = loadBTCWeeklyReturnsAsDict()
    let spWeeklyDict  = loadSP500WeeklyReturnsAsDict()
    let alignedWeekly = alignBTCandSPWeekly(btcDict: btcWeeklyDict, spDict: spWeeklyDict)

    // If you want separate arrays of Double:
    let sortedBTC = alignedWeekly.map { $0.1 }  // .1 is btcReturn
    let sortedSP  = alignedWeekly.map { $0.2 }  // .2 is spReturn

    // Or if you want a single (btc, sp) array for block bootstrap:
    let combinedWeeklyData = alignedWeekly.map { (_, btc, sp) in (btc, sp) }
    
    // Store them somewhere or return them from the function.
}
