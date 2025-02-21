//
//  ColumnsPagerViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/02/2025.
//

import UIKit

class ColumnsPagerViewController: UIPageViewController {
    
    // 1) The columns you want to show, e.g. [("BTC Price", \.btcPriceUSD), ("Portfolio", \.portfolioValueUSD), ...]
    var allColumns: [(String, KeyPath<SimulationData, Decimal>)] = []
    
    // 2) The entire array of data so each page can display rows. Typically from "representable.displayedData".
    var displayedData: [SimulationData] = []
    
    // Internally we chunk "allColumns" into pairs so each page shows 2 columns.
    private var pagesData: [[(String, KeyPath<SimulationData, Decimal>)]] = []
    
    // Track the SinglePageColumnsVC currently visible to the user
    var currentActivePage: SinglePageColumnsVC?
    
    // A callback so the parent can observe page changes
    var onPageChanged: ((SinglePageColumnsVC) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self  // important, so we get page transition callbacks
        
        // Make the internal scroll view use paging
        if let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.isPagingEnabled = true
        }
        
        pagesData = chunkColumnsIntoPairs(allColumns)
        
        // Show page 0 by default
        if let firstVC = makeColumnsPageVC(forPageIndex: 0) {
            setViewControllers([firstVC], direction: .forward, animated: false)
            currentActivePage = firstVC
            
            // IMPORTANT: Trigger onPageChanged for the initial page,
            // so that the pinned table's "onScroll" can be set up even if we never swipe pages.
            onPageChanged?(firstVC)
        }
    }
    
    /// Splits an array of columns into subarrays of size 2 (the "pairs").
    private func chunkColumnsIntoPairs(
        _ columns: [(String, KeyPath<SimulationData, Decimal>)]
    ) -> [[(String, KeyPath<SimulationData, Decimal>)]] {
        
        var result = [[(String, KeyPath<SimulationData, Decimal>)]]()
        var temp = [(String, KeyPath<SimulationData, Decimal>)]()
        
        for col in columns {
            temp.append(col)
            if temp.count == 2 {
                result.append(temp)
                temp.removeAll()
            }
        }
        // If we had an odd number of columns, there's 1 leftover => final single-col page
        if !temp.isEmpty {
            result.append(temp)
        }
        return result
    }
    
    /// Creates a new SinglePageColumnsVC for a given page index
    private func makeColumnsPageVC(forPageIndex index: Int) -> SinglePageColumnsVC? {
        guard index >= 0 && index < pagesData.count else { return nil }
        
        let vc = SinglePageColumnsVC()
        vc.columnsToShow = pagesData[index]  // up to 2 columns
        vc.displayedData = displayedData
        return vc
    }
    
    func reloadPages() {
        pagesData = chunkColumnsIntoPairs(allColumns)
        if let first = makeColumnsPageVC(forPageIndex: 0) {
            setViewControllers([first], direction: .forward, animated: false, completion: nil)
            currentActivePage = first
            
            // Also call onPageChanged here so the pinned table gets the initial onScroll
            onPageChanged?(first)
        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension ColumnsPagerViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let singleVC = viewController as? SinglePageColumnsVC,
              let currentIndex = indexForPageVC(singleVC) else {
            return nil
        }
        let prevIndex = currentIndex - 1
        return makeColumnsPageVC(forPageIndex: prevIndex)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let singleVC = viewController as? SinglePageColumnsVC,
              let currentIndex = indexForPageVC(singleVC) else {
            return nil
        }
        let nextIndex = currentIndex + 1
        return makeColumnsPageVC(forPageIndex: nextIndex)
    }
    
    private func indexForPageVC(_ vc: SinglePageColumnsVC) -> Int? {
        guard let pageCols = vc.columnsToShow else { return nil }
        
        return pagesData.firstIndex { chunk in
            chunk.map(\.0) == pageCols.map(\.0)
        }
    }
}

// MARK: - UIPageViewControllerDelegate
extension ColumnsPagerViewController: UIPageViewControllerDelegate {
    
    /// Called when the user finishes swiping to a new page
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        
        guard completed, let visibleVC = viewControllers?.first as? SinglePageColumnsVC else {
            return
        }
        
        // Update currentActivePage
        currentActivePage = visibleVC
        
        // Notify parent so it can sync or do whatever is needed
        onPageChanged?(visibleVC)
    }
}
