//
//  IdleManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 28/02/2025.
//

import MetalKit
import Foundation

class IdleManager: ObservableObject {
    
    // Provide one weak reference to the MTKView
    weak var metalView: MTKView?
    
    @Published var isIdle: Bool = false
    
    private var idleTimer: Timer?
    private var lastActivityTime: Date = Date()
    private let idleTimeLimit: TimeInterval = 5.0 // 5 seconds
    
    /// Reset idle timer on user interaction
    @objc func resetIdleTimer() {
        lastActivityTime = Date()
        
        // Invalidate existing timer
        idleTimer?.invalidate()
        
        // Schedule a new idle timeout
        idleTimer = Timer.scheduledTimer(
            timeInterval: idleTimeLimit,
            target: self,
            selector: #selector(idleTimeout),
            userInfo: nil,
            repeats: false
        )
        print("DEBUG: Timer scheduled for \(idleTimeLimit) seconds")
        
        // If we were idle, resume
        if isIdle {
            resumeProcessing()
        }
        
        isIdle = false
    }
    
    /// Called when idle timer fires
    @objc private func idleTimeout() {
        handleIdleState()
        // Inside idleTimeout or idleManager
        if let mv = metalView {
            mv.isPaused = true
            print("Pausing \(mv). isPaused = \(mv.isPaused)")
        } else {
            print("No metalView found to pause!")
        }
    }
    
    /// Perform any idle actions (pause, free resources, etc.)
    private func handleIdleState() {
        pauseProcessing()
        releaseResources()
    }
    
    private func pauseProcessing() {
        print("Pausing live processing due to inactivity.")
        isIdle = true
    }
    
    private func releaseResources() {
        print("Releasing resources to save power and memory.")
        // Free or reduce usage if desired
    }
    
    /// Resume after user interaction
    func resumeProcessing() {
        print("Resuming live processing.")
        isIdle = false
        
        // Unpause the MTKView so it redraws
        metalView?.isPaused = false
    }
}
