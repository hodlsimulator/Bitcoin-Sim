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

        // If the user scrolls vertically in this single column
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
        let centerX = scrollView.contentOffset.x + (scrollView.bounds.width / 2.0)
        let centerPoint = CGPoint(x: centerX, y: scrollView.bounds.height / 2.0)

        guard let cv = internalCollectionView else { return }
        guard let indexPath = cv.indexPathForItem(at: centerPoint),
              indexPath.item < columnsData.count else {
            return
        }

        // Pass the item index as an Int
        onCenteredColumnChanged?(indexPath.item)
    }
}
