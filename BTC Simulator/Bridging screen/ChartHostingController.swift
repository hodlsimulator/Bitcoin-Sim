//
//  ChartHostingController.swift
//  BTCMonteCarlo
//
//  Created by . . on 23/02/2025.
//

import SwiftUI
import UIKit

class ChartHostingController<Root: View>: UIHostingController<AnyView> {

    /// Custom init: wrap your `Root` in `AnyView` after adding environmentObject.
    init(rootView: Root, idleManager: IdleManager) {
        let wrappedView = AnyView(
            rootView.environmentObject(idleManager)
        )
        super.init(rootView: wrappedView)
    }
    
    /// Required by UIHostingController for storyboard/XIB use
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear

        let itemAppearance = UIBarButtonItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = itemAppearance
        appearance.backButtonAppearance = itemAppearance
        
        // Hide default back text
        appearance.backButtonAppearance.normal.titlePositionAdjustment =
            UIOffset(horizontal: -2000, vertical: 0)
        
        navigationItem.standardAppearance   = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.backButtonDisplayMode = .minimal
        
        navigationController?.navigationBar.tintColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}
