//
//  MempoolDataManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/01/2025.
//

import Foundation

class MempoolDataManager {
    /// Store your per-week (or per-month) mempool data
    var mempoolData: [Double]
    
    init(mempoolData: [Double]) {
        self.mempoolData = mempoolData
    }
    
    /// Optionally load from JSON, API, or local file
    // func loadFromFile(...) { ... }
    
    /// Helper to safely fetch the mempool value at a given step
    func stressLevel(at index: Int) -> Double {
        // Return 0 if index out of bounds, or handle however you like
        guard index >= 0 && index < mempoolData.count else {
            return 0.0
        }
        return mempoolData[index]
    }
}
