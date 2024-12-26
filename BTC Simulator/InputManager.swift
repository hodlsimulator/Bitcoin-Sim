//
//  InputManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 26/12/2024.
//

import SwiftUI

class InputManager: ObservableObject {
    @Published var iterations = ""
    @Published var annualCAGR = ""
    @Published var annualVolatility = ""
}
