//
//  OrientationObserver.swift
//  BTCMonteCarlo
//
//  Created by . . on 03/01/2025.
//

import Foundation
import SwiftUI

class OrientationObserver: ObservableObject {
    @Published var isLandscape: Bool = false

    init() {
        handleOrientationChange()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    @objc private func handleOrientationChange() {
        let orientation = UIDevice.current.orientation
        // Only treat left/right as landscape
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            isLandscape = true
        } else {
            isLandscape = false
        }
    }
}
