//
//  TwoColumnCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class TwoColumnCollectionViewController: UIViewController {

    // The array of rows to populate each column's table
    var displayedData: [SimulationData] = []

    // Instead of pairs, we just have an array of columns
    var columnsData: [(String, PartialKeyPath<SimulationData>)] = []

    // Called whenever one of the single-column tables scrolls vertically
    var onScrollSync: ((UIScrollView) -> Void)?

    // Called when the user scrolls horizontally and a new column is centred,
    // passing the index of the centred column
    var onCenteredColumnChanged: ((Int) -> Void)?

    var internalCollectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // e.g. SnapTwoColumnsFlowLayout so 2 columns fit side by side
        let layout = SnapTwoColumnsFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .never

        cv.dataSource = self
        cv.delegate   = self

        // Register the single‑column cell
        cv.register(OneColumnCell.self, forCellWithReuseIdentifier: "OneColumnCell")

        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.internalCollectionView = cv
    }

    func reloadData() {
        internalCollectionView?.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        internalCollectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - New code to ensure we scroll horizontally after layout is ready
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // If "BTC Price" is at index 2, call the helper so that columns 2 & 3 are visible
        scrollToColumnIndex(2)
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension TwoColumnCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    // 1) Required data source method
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return columnsData.count
    }

    // 2) Required data source method
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "OneColumnCell",
            for: indexPath
        ) as? OneColumnCell else {
            return UICollectionViewCell()
        }

        let (title, partial) = columnsData[indexPath.item]
        cell.configure(
            columnTitle: title,
            partialKey: partial,
            displayedData: displayedData
        )

        // Sync vertical offset asynchronously
        if let parentVC = self.parent as? PinnedColumnTablesViewController {
            DispatchQueue.main.async {
                cell.setVerticalOffset(parentVC.currentVerticalOffset)
            }
        }

        cell.onScroll = { [weak self] scrollView in
            self?.onScrollSync?(scrollView)
            if let pinnedVC = self?.parent as? PinnedColumnTablesViewController {
                pinnedVC.scrollViewDidScroll(scrollView)
            }
        }

        return cell
    }

    // 3) Optional but helpful: triggers right before a cell becomes visible
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        
        if let oneColCell = cell as? OneColumnCell,
           let parentVC = self.parent as? PinnedColumnTablesViewController {
            // Make sure newly displayed cells start at the correct vertical offset
            oneColCell.setVerticalOffset(parentVC.currentVerticalOffset)
        }
    }

    // Snap-based “center” detection
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleCenteredColumn(in: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if !willDecelerate {
            handleCenteredColumn(in: scrollView)
        }
    }

    private func handleCenteredColumn(in scrollView: UIScrollView) {
        guard let cv = internalCollectionView else { return }

        // Shift the 'centre' 1/4 screen to the left so we pick the left column
        let offsetX = scrollView.contentOffset.x + (scrollView.bounds.width / 4.0)
        let offsetY = scrollView.bounds.height / 2.0
        let adjustedCenterPoint = CGPoint(x: offsetX, y: offsetY)

        if let indexPath = cv.indexPathForItem(at: adjustedCenterPoint),
           indexPath.item < columnsData.count {
            
            let leftColumnIndex = indexPath.item
            onCenteredColumnChanged?(leftColumnIndex)
        }
    }
}

// MARK: - Helper for scrolling horizontally to a column index

extension TwoColumnCollectionViewController {

    /// Scroll so that the item at `columnIndex` is on the left side,
    /// showing columns `columnIndex` and `columnIndex + 1`.
    func scrollToColumnIndex(_ columnIndex: Int) {
        guard let cv = internalCollectionView else { return }
        guard columnIndex >= 0 && columnIndex < columnsData.count else { return }

        // Easiest approach: scroll-to-item with .left alignment
        let indexPath = IndexPath(item: columnIndex, section: 0)
        cv.scrollToItem(at: indexPath, at: .left, animated: false)
    }
}
