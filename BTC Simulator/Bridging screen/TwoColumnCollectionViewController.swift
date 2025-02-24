//
//  TwoColumnCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class TwoColumnCollectionViewController: UIViewController {

    // The array of rows for each column's table
    var displayedData: [SimulationData] = []

    // The columns, e.g. [("BTC Price", ...), ("Portfolio", ...), etc.]
    var columnsData: [(String, PartialKeyPath<SimulationData>)] = []

    // Called whenever a table scrolls vertically
    var onScrollSync: ((UIScrollView) -> Void)?

    // Called when the user horizontally snaps so we can get the new left column index
    var onCenteredColumnChanged: ((Int) -> Void)?

    var internalCollectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // Use SnapHalfPageFlowLayout => 2 columns visible, shifts by 1 column each swipe
        let layout = SnapHalfPageFlowLayout()

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.clipsToBounds   = true
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .never

        cv.dataSource = self
        cv.delegate   = self

        // Register your OneColumnCell
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Example: if col 2 is "BTC Price", scroll so we see columns (2,3)
        scrollToColumnIndex(2)
    }
}

// MARK: - UICollectionViewDataSource & Delegate
extension TwoColumnCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return columnsData.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "OneColumnCell",
            for: indexPath
        ) as? OneColumnCell else {
            return UICollectionViewCell()
        }

        let (title, partial) = columnsData[indexPath.item]
        cell.configure(columnTitle: title, partialKey: partial, displayedData: displayedData)

        // Sync pinned offset
        if let parentVC = self.parent as? PinnedColumnTablesViewController {
            DispatchQueue.main.async {
                cell.setVerticalOffset(parentVC.currentVerticalOffset)
            }
        }

        // Bubble up scroll events
        cell.onScroll = { [weak self] scrollView in
            self?.onScrollSync?(scrollView)
            if let pinnedVC = self?.parent as? PinnedColumnTablesViewController {
                pinnedVC.scrollViewDidScroll(scrollView)
            }
        }

        return cell
    }

    // Also ensure newly displayed columns pick up the pinned offset
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if let oneColCell = cell as? OneColumnCell,
           let parentVC = self.parent as? PinnedColumnTablesViewController {
            oneColCell.setVerticalOffset(parentVC.currentVerticalOffset)
        }
    }

    // Snap-based detection of the left column index
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        identifyLeftColumn(in: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if !willDecelerate {
            identifyLeftColumn(in: scrollView)
        }
    }

    /// Identify which column index is on the left side of this 2-col half-page
    private func identifyLeftColumn(in scrollView: UIScrollView) {
        guard let cv = internalCollectionView else { return }

        // Because each page is half the width (one-column shift),
        // we shift the detection point by 1/4 the screen so we pick the left item.
        let quarterWidth = scrollView.bounds.width / 4.0
        let offsetX = scrollView.contentOffset.x + quarterWidth
        let offsetY = scrollView.bounds.height / 2.0
        let point   = CGPoint(x: offsetX, y: offsetY)

        if let indexPath = cv.indexPathForItem(at: point),
           indexPath.item < columnsData.count {
            onCenteredColumnChanged?(indexPath.item)
        }
    }
}

// MARK: - Helper for scrolling so columns [columnIndex, columnIndex+1] fill the screen
extension TwoColumnCollectionViewController {

    func scrollToColumnIndex(_ columnIndex: Int) {
        guard let cv = internalCollectionView else { return }
        guard columnIndex >= 0 && columnIndex < columnsData.count else { return }

        let indexPath = IndexPath(item: columnIndex, section: 0)
        cv.scrollToItem(at: indexPath, at: .left, animated: false)
    }
}
