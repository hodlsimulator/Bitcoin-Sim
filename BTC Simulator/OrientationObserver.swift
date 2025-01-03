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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        handleOrientationChange() // Initial check
    }
    
    @objc func handleOrientationChange() {
        let orientation = UIDevice.current.orientation
        // Only treat .landscapeLeft / .landscapeRight as landscape:
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            isLandscape = true
        } else if orientation == .portrait || orientation == .portraitUpsideDown {
            isLandscape = false
        }
    }
}

