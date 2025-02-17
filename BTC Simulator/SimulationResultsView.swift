//
//  SimulationResultsView.swift
//  BTCMonteCarlo
//
//  Created by . . on 16/02/2025.
//
//  Description:
//    A parent "ResponsiveSimulationResultsView" that chooses either
//    "SimulationResultsPortraitView" (your original code) or a
//    "SimulationResultsLandscapeView" (new layout) based on orientation.
//

import SwiftUI
import UIKit

struct SimulationResultsView: View {

    @EnvironmentObject var simSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings
    @EnvironmentObject var inputManager: PersistentInputManager
    @EnvironmentObject var chartDataCache: ChartDataCache
    @EnvironmentObject var coordinator: SimulationCoordinator

    @Binding var lastViewedPage: Int
    @Binding var lastViewedWeek: Int
    @Binding var isAtBottom: Bool
    @Binding var showHistograms: Bool
    @Binding var scrollToBottom: Bool
    @Binding var lastScrollTime: Date
    @Binding var contentScrollProxy: ScrollViewProxy?
    @Binding var currentPage: Int
    @Binding var hideScrollIndicators: Bool

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            if isLandscape {
                SimulationResultsLandscapeView(
                    lastViewedPage: $lastViewedPage,
                    lastViewedWeek: $lastViewedWeek,
                    isAtBottom: $isAtBottom,
                    showHistograms: $showHistograms,
                    scrollToBottom: $scrollToBottom,
                    lastScrollTime: $lastScrollTime,
                    contentScrollProxy: $contentScrollProxy,
                    currentPage: $currentPage,
                    hideScrollIndicators: $hideScrollIndicators
                )
            } else {
                SimulationResultsPortraitView(
                    lastViewedPage: $lastViewedPage,
                    lastViewedWeek: $lastViewedWeek,
                    isAtBottom: $isAtBottom,
                    showHistograms: $showHistograms,
                    scrollToBottom: $scrollToBottom,
                    lastScrollTime: $lastScrollTime,
                    contentScrollProxy: $contentScrollProxy,
                    currentPage: $currentPage,
                    hideScrollIndicators: $hideScrollIndicators
                )
            }
        }
    }
}
