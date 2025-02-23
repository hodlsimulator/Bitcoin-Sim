//
//  ChartHostingController.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/02/2025.
//

import UIKit
import SwiftUI

class ChartHostingController<Content: View>: UIHostingController<Content> {

    override func viewDidLoad() {
        super.viewDidLoad()

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear

        // Make the bar button (including back arrow) white
        let itemAppearance = UIBarButtonItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = itemAppearance
        appearance.backButtonAppearance = itemAppearance

        // Hide default back text
        appearance.backButtonAppearance.normal.titlePositionAdjustment =
            UIOffset(horizontal: -2000, vertical: 0)

        // Apply to standard & scrollEdge
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        
        // Also ensure 'Back' text is minimal
        navigationItem.backButtonDisplayMode = .minimal
        
        // This sets the nav bar’s tint for the arrow icon
        navigationController?.navigationBar.tintColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show the system nav bar for this screen
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        // Make sure interactive swipe is on
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}
