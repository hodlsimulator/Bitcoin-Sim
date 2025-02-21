//
//  ColumnsPagerViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/02/2025.
//

import UIKit

class ColumnsPagerViewController: UIPageViewController {

    // The columns you want, each with a display title and PartialKeyPath
    // (so we can handle Decimal, Double, or Int in SimulationData).
    var allColumns: [(String, PartialKeyPath<SimulationData>)] = []
    
    // All row data for each page to show in its table
    var displayedData: [SimulationData] = []
    
    // The internal array of pages, each page is [col[i], col[i+1]] (sliding pairs)
    private var pagesData: [[(String, PartialKeyPath<SimulationData>)]] = []
    
    // Track the currently visible SinglePageColumnsVC
    var currentActivePage: SinglePageColumnsVC?
    
    // A callback so the parent can observe when the page changes
    var onPageChanged: ((SinglePageColumnsVC) -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        // Ensure the scroll view is paging-enabled for snapping
        if let scrollView = view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.isPagingEnabled = true
        }
        
        // Build the "sliding pairs" pages
        pagesData = buildSlidingPairs(from: allColumns)
        
        // Show columns [2,3] by default if possible, otherwise page 0
        showPage(atIndex: 2)
    }
    
    // MARK: - Page Building Logic
    
    /// If columns = [A,B,C,D], produce pages [A,B], [B,C], [C,D].
    /// If 1 column, just one single-col page. If none, return [].
    private func buildSlidingPairs(
        from columns: [(String, PartialKeyPath<SimulationData>)]
    ) -> [[(String, PartialKeyPath<SimulationData>)]] {
        
        guard columns.count > 1 else {
            if columns.isEmpty { return [] }
            return [[columns[0]]]
        }
        
        var result: [[(String, PartialKeyPath<SimulationData>)]] = []
        for i in 0..<(columns.count - 1) {
            result.append([columns[i], columns[i+1]])
        }
        return result
    }
    
    /// Try to show a specific page index if it exists
    private func showPage(atIndex index: Int) {
        guard index >= 0, index < pagesData.count else { return }
        guard let pageVC = makeColumnsPageVC(forPageIndex: index) else { return }
        
        setViewControllers([pageVC], direction: .forward, animated: false)
        currentActivePage = pageVC
        onPageChanged?(pageVC)
    }
    
    /// Create a SinglePageColumnsVC for a particular page index
    private func makeColumnsPageVC(forPageIndex index: Int) -> SinglePageColumnsVC? {
        guard index >= 0, index < pagesData.count else { return nil }
        
        let vc = SinglePageColumnsVC()
        vc.columnsToShow = pagesData[index]
        vc.displayedData = displayedData
        return vc
    }
    
    /// Rebuild pages (e.g. if columns or data changed) and show page 0
    func reloadPages() {
        pagesData = buildSlidingPairs(from: allColumns)
        showPage(atIndex: 0)
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
    
    /// Identify which page corresponds to this SinglePageColumnsVC
    private func indexForPageVC(_ vc: SinglePageColumnsVC) -> Int? {
        guard let pageCols = vc.columnsToShow else { return nil }
        return pagesData.firstIndex { chunk in
            chunk.map(\.0) == pageCols.map(\.0)
        }
    }
}

// MARK: - UIPageViewControllerDelegate

extension ColumnsPagerViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        
        guard completed,
              let visibleVC = viewControllers?.first as? SinglePageColumnsVC else {
            return
        }
        
        currentActivePage = visibleVC
        onPageChanged?(visibleVC)
    }
}
