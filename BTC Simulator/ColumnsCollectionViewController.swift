//
//  ColumnsCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class ColumnsCollectionViewController: UIViewController {

    // We'll now store pairs of columns (two columns per item)
    public var pairsData: [[(String, PartialKeyPath<SimulationData>)]] = []
    public var displayedData: [SimulationData] = []

    // For pinned-table scrolling sync
    public var onScrollSync: ((UIScrollView) -> Void)?

    // (Optional) track a current index
    // (Optional) track an active index if needed

    // The collection view + flow layout
    // Renamed to avoid overshadowing dataSource func "collectionView(_:_:)"
    public var columnsCollectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear

        // 1) Create the layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        // For partial columns, each cell narrower than screen
        layout.itemSize = CGSize(width: 240, height: view.bounds.height)
        layout.minimumLineSpacing = 10

        // 2) Create the collection view
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast  // for snappier feel
        cv.isPagingEnabled = false   // we want partial scroll, not full paging
        cv.dataSource    = self
        cv.delegate      = self
        cv.translatesAutoresizingMaskIntoConstraints = false

        // Store in our public var
        self.columnsCollectionView = cv

        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Register the two-column cell
        cv.register(ColumnsCollectionCell.self, forCellWithReuseIdentifier: "ColumnsCollectionCell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // If you want to default to the 3rd pair, for example:
        if pairsData.count > 2 {
            let idxPath = IndexPath(item: 2, section: 0)
            columnsCollectionView?.scrollToItem(at: idxPath, at: .left, animated: false)
        }
    }

    /// Public method so other VCs can trigger a reload easily
    public func reloadCollectionData() {
        columnsCollectionView?.reloadData()
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ColumnsCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return pairsData.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ColumnsCollectionCell",
            for: indexPath
        ) as? ColumnsCollectionCell else {
            return UICollectionViewCell()
        }
        
        let pair = pairsData[indexPath.item]
        cell.configure(pair: pair, displayedData: displayedData)
        
        // If you want vertical scroll sync:
        cell.onScroll = { [weak self] scrollView in
            // Pass up to pinned table
            self?.onScrollSync?(scrollView)
        }
        
        return cell
    }
}
