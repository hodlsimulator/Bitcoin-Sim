//
//  DataLoader.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/01/2025.
//
/*
import Foundation

func loadAndAlignWeeklyData() {
    let btcWeeklyDict = loadBTCWeeklyReturnsAsDict()
    let spWeeklyDict  = loadSP500WeeklyReturnsAsDict()
    let alignedWeekly = alignBTCandSPWeekly(btcDict: btcWeeklyDict, spDict: spWeeklyDict)
    let justBtcWeekly = alignedWeekly.map { $0.1 }

    // Or if you want a single (btc, sp) array for block bootstrap:
    let combinedWeeklyData = alignedWeekly.map { (_, btc, sp) in (btc, sp) }
    
    return (justBtcWeekly, combinedWeeklyData)
}
*/
