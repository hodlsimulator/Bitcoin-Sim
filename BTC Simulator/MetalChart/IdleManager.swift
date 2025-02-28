//
//  IdleManager.swift
//  BTCMonteCarlo
//
//  Created by . . on 28/02/2025.
//

import Foundation

class IdleManager: ObservableObject {
    private var idleTimer: Timer?
    private var lastActivityTime: Date = Date()
    private let idleTimeLimit: TimeInterval = 30.0 // 30 seconds for idle timeout
    
    // Call this method to reset the idle timer whenever there's user interaction (e.g., tapping, scrolling)
    @objc func resetIdleTimer() {
        lastActivityTime = Date()
        
        // Invalidate any existing timer to reset the idle state
        idleTimer?.invalidate()
        
        // Create a new timer to trigger idle timeout after the specified idleTimeLimit
        idleTimer = Timer.scheduledTimer(timeInterval: idleTimeLimit,
                                         target: self,
                                         selector: #selector(idleTimeout),
                                         userInfo: nil,
                                         repeats: false)
    }
    
    // This method is triggered when idle time exceeds the limit (e.g., after 30 seconds of inactivity)
    @objc private func idleTimeout() {
        // Pause ongoing tasks to save resources when the app is idle
        handleIdleState()
    }
    
    // Handles actions for when the app is idle, such as pausing tasks and releasing resources
    private func handleIdleState() {
        pauseProcessing()
        releaseResources()
    }
    
    // Pauses ongoing processing, rendering, or calculations to save resources
    private func pauseProcessing() {
        print("Pausing live processing due to inactivity.")
        // Add code here to pause Metal rendering or any ongoing data processing
    }
    
    // Releases resources that are not needed during the idle state to conserve power and memory
    private func releaseResources() {
        print("Releasing resources to save power and memory.")
        // Add code here to release GPU resources, reset buffers, or pause data updates
    }
    
    // Call this method when the app becomes active again (e.g., after user interaction)
    func resumeProcessing() {
        print("Resuming live processing.")
        // Add code here to restart rendering or resume data processing
    }
}
