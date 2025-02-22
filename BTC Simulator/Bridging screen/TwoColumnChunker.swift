//
//  TwoColumnChunker.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import Foundation

/// A helper utility for chunking your list of columns into two-column pairs.
/// For example, if `columns = [A, B, C, D, E]`,
/// the result is [[A,B], [C,D], [E]] (with a single leftover).
///
/// Each inner array can then be displayed in one "page" or one collection cell.
func buildPairs(
    from columns: [(String, PartialKeyPath<SimulationData>)]
) -> [[(String, PartialKeyPath<SimulationData>)]] {
    
    // If we have 0 or 1 columns, just return them as a single item if any
    guard columns.count > 1 else {
        if columns.isEmpty { return [] }
        return [[columns[0]]]
    }
    
    var result: [[(String, PartialKeyPath<SimulationData>)]] = []
    var i = 0
    
    // Step through columns in chunks of 2
    while i < columns.count {
        let endIndex = min(i + 2, columns.count)
        let slice = Array(columns[i..<endIndex])
        result.append(slice)
        i += 2
    }
    
    return result
}
