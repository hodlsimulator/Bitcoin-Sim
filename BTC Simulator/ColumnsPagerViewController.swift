//
//  ColumnsPagerViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/02/2025.
//

import UIKit

// Replace 'SimulationData' with whatever your actual data model is.
// Also adjust KeyPath if your columns are something else.
class ColumnsPagerViewController: UIPageViewController {
    
    // 1) The columns you want to show, e.g. [("BTC Price", \.btcPriceUSD), ("Portfolio", \.portfolioValueUSD), ...]
    var allColumns: [(String, KeyPath<SimulationData, Decimal>)] = []
    
    // 2) The entire array of data so each page can display rows. Typically from "representable.displayedData".
    var displayedData: [SimulationData] = []
    
    // Internally we chunk "allColumns" into pairs so each page shows 2 columns.
    private var pagesData: [[(String, KeyPath<SimulationData, Decimal>)]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // We are our own dataSource and delegate.
        dataSource = self
        delegate = self
        
        // Make sure the scroll view inside UIPageViewController uses "paging".
        if let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.isPagingEnabled = true
        }
        
        // Convert allColumns into an array of pairs. (If there's an odd number, the last page has 1 column.)
        pagesData = chunkColumnsIntoPairs(allColumns)
        
        // Show page 0 by default
        if let firstVC = makeColumnsPageVC(forPageIndex: 0) {
            setViewControllers([firstVC], direction: .forward, animated: false)
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
        vc.displayedData = displayedData     // entire table’s worth of data
        return vc
    }
}

// MARK: - UIPageViewControllerDataSource
extension ColumnsPagerViewController: UIPageViewControllerDataSource {
    
    // The view controller before the current page
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        
        guard let singleVC = viewController as? SinglePageColumnsVC,
              let currentIndex = indexForPageVC(singleVC) else {
            return nil
        }
        let prevIndex = currentIndex - 1
        return makeColumnsPageVC(forPageIndex: prevIndex)
    }
    
    // The view controller after the current page
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        
        guard let singleVC = viewController as? SinglePageColumnsVC,
              let currentIndex = indexForPageVC(singleVC) else {
            return nil
        }
        let nextIndex = currentIndex + 1
        return makeColumnsPageVC(forPageIndex: nextIndex)
    }
    
    /// Helper to find the current page index for SinglePageColumnsVC
    private func indexForPageVC(_ vc: SinglePageColumnsVC) -> Int? {
        guard let pageCols = vc.columnsToShow else { return nil }
        
        // We compare just the column titles .map(\.0) to see if they match the chunk
        return pagesData.firstIndex { chunk in
            chunk.map(\.0) == pageCols.map(\.0)
        }
    }
    
    // In ColumnsPagerViewController:
    func reloadPages() {
        pagesData = chunkColumnsIntoPairs(allColumns)
        if let first = makeColumnsPageVC(forPageIndex: 0) {
            setViewControllers([first], direction: .forward, animated: false, completion: nil)
        }
    }
}

// MARK: - UIPageViewControllerDelegate
extension ColumnsPagerViewController: UIPageViewControllerDelegate {
    // (Optional) implement any delegate methods you need
}
