//
//  CustomBarViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import UIKit

class CustomBarViewController: UIViewController, UIGestureRecognizerDelegate {

    private let customNavBar = UIView()
    private let backButton   = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        // 1) Hide the system nav bar
        navigationController?.isNavigationBarHidden = true
        
        // 2) Enable the edge-swipe pop gesture
        if let nav = navigationController {
            nav.interactivePopGestureRecognizer?.delegate = self
            nav.interactivePopGestureRecognizer?.isEnabled = true
        }
        
        // 3) Add a custom top bar (fake nav bar)
        customNavBar.backgroundColor = .darkGray
        customNavBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(customNavBar)
        
        NSLayoutConstraint.activate([
            customNavBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavBar.heightAnchor.constraint(equalToConstant: 56) // or whatever
        ])
        
        // 4) Add a custom back button
        backButton.setTitle("", for: .normal)              // no text
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(handleCustomBack), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        customNavBar.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: customNavBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: customNavBar.centerYAnchor)
        ])
    }
    
    @objc private func handleCustomBack() {
        navigationController?.popViewController(animated: true)
    }
    
    // 5) Decide if the edge-swipe should begin
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}

