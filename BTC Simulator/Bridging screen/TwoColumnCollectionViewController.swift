//
//  TwoColumnCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class TwoColumnCollectionViewController: UIViewController {

    /// The array of rows to populate each column's table
    var displayedData: [SimulationData] = []

    /// Instead of pairs, we just have an array of columns
    var columnsData: [(String, PartialKeyPath<SimulationData>)] = []

    /// Called whenever one of the single-column tables scrolls vertically
    var onScrollSync: ((UIScrollView) -> Void)?

    /// Called when the user scrolls horizontally and a new column is centred,
    /// passing the index of the centred column.
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
        cell.configure(
            columnTitle: title,
            partialKey: partial,
            displayedData: displayedData
        )

        // Sync vertical offset to the "global" offset from parent
        if let parentVC = self.parent as? PinnedColumnTablesViewController {
            let offset = parentVC.currentVerticalOffset
            cell.setVerticalOffset(offset)
        }

        // If the user scrolls vertically in this single column, bubble up
        cell.onScroll = { [weak self] scrollView in
            self?.onScrollSync?(scrollView)
        }

        return cell
    }

    // Snap-based “center” detection
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleCenteredColumn(in: scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if !willDecelerate { handleCenteredColumn(in: scrollView) }
    }

    private func handleCenteredColumn(in scrollView: UIScrollView) {
        guard let cv = internalCollectionView else { return }
        
        // Shift the 'centre' 1/4 screen to the left so we pick the left column
        let offsetX = scrollView.contentOffset.x + (scrollView.bounds.width / 4.0)
        let offsetY = scrollView.bounds.height / 2.0
        let adjustedCenterPoint = CGPoint(x: offsetX, y: offsetY)

        if let indexPath = cv.indexPathForItem(at: adjustedCenterPoint),
           indexPath.item < columnsData.count {

            // This 'left' item is now recognized as the "current" column
            let leftColumnIndex = indexPath.item
            
            // Then in your parent, you can do:
            //   col1Label = columnsData[leftColumnIndex].0
            //   col2Label = columnsData[leftColumnIndex + 1].0 (if it exists)
            onCenteredColumnChanged?(leftColumnIndex)
        }
    }
}
