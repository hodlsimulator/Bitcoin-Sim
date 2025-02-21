//
//  TwoColumnCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

/// A horizontally scrolling collection view that displays "two columns" per cell.
/// We chunk the columns into pairs beforehand, then each item in `pairsData` has
/// up to two (String, PartialKeyPath<SimulationData>) entries.
class TwoColumnCollectionViewController: UIViewController {

    /// Each item represents 2 columns (or 1 leftover). For example:
    ///   [("BTC Price", \.btcPriceUSD), ("Portfolio", \.portfolioValueUSD)]
    var pairsData: [[(String, PartialKeyPath<SimulationData>)]] = []

    /// The array of rows to populate each column's table
    var displayedData: [SimulationData] = []

    /// Called whenever one of the two tables in a cell scrolls vertically;
    /// the parent can sync with the pinned table.
    var onScrollSync: ((UIScrollView) -> Void)?

    /// Called when the user scrolls horizontally and a new cell is centred,
    /// so the parent can update "col1Label" and "col2Label" with the new columns.
    var onCenteredPairChanged: (([(String, PartialKeyPath<SimulationData>)]) -> Void)?

    /// The underlying collection view (with center snapping)
    private var collectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // 1) Create a snapping flow layout
        let layout = CenterSnapFlowLayout()
        layout.scrollDirection = .horizontal

        // Each cell is narrower than the full screen => partial-page scroll
        // Adjust to your preference (width ~ 0.7 * screen)
        layout.itemSize = CGSize(width: view.bounds.width * 0.7, height: view.bounds.height)
        layout.minimumLineSpacing = 20

        // 2) Create the collection view
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false

        // Set dataSource & delegate
        cv.dataSource = self
        cv.delegate = self

        // Register the 2-col cell
        cv.register(TwoColumnPairCell.self, forCellWithReuseIdentifier: "TwoColumnPairCell")

        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.collectionView = cv
    }

    /// Call this after updating `pairsData` or `displayedData` to refresh
    func reloadData() {
        collectionView?.reloadData()
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension TwoColumnCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return pairsData.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TwoColumnPairCell",
            for: indexPath
        ) as? TwoColumnPairCell else {
            return UICollectionViewCell()
        }

        // The pair of columns for this "page"
        let pair = pairsData[indexPath.item]

        // Configure the cell with the two columns plus row data
        cell.configure(pair: pair, displayedData: displayedData)

        // If the user scrolls vertically in either table, pass that up to pinned table
        cell.onScroll = { [weak self] scrollView in
            self?.onScrollSync?(scrollView)
        }

        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Determine which cell is currently near the center of the screen
        let centerX = scrollView.contentOffset.x + (scrollView.bounds.width / 2.0)
        let centerPoint = CGPoint(x: centerX, y: scrollView.bounds.height / 2.0)

        guard let cv = collectionView,
              let indexPath = cv.indexPathForItem(at: centerPoint) else {
            return
        }

        // The "active" pair
        let pair = pairsData[indexPath.item]
        onCenteredPairChanged?(pair)
    }
}
