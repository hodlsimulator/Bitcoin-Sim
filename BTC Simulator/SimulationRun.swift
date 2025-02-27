//
//  SimulationRun.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/02/2025.
//

import SwiftUI

/// Make sure your SimulationRun can preserve an existing UUID.
/// By default, it generates its own ID, but you can pass one manually.
struct SimulationRun: Identifiable {
    let id: UUID
    let points: [WeekPoint]
    
    init(id: UUID = UUID(), points: [WeekPoint]) {
        self.id = id
        self.points = points
    }
}

struct WeekPoint: Identifiable {
    let id = UUID()
    let week: Int
    let value: Decimal
}
