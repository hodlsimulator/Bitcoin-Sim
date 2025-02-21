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
    
    // A callback so the parent can know which pair is centered
    // The 'pair' is an array of up to 2 columns, e.g. [("BTC Price", partial1), ("Portfolio", partial2)]
    public var onCenteredPairChanged: (([(String, PartialKeyPath<SimulationData>)]) -> Void)?

    public var columnsCollectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear

        // 1) Create the layout using CenterSnapFlowLayout
        let layout = CenterSnapFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 240, height: view.bounds.height)
        layout.minimumLineSpacing = 10

        // 2) Create the collection view
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast  // for snappier feel
        cv.isPagingEnabled = false   // partial scroll, not full paging
        cv.dataSource    = self
        cv.delegate      = self
        cv.translatesAutoresizingMaskIntoConstraints = false
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

    public func reloadCollectionData() {
        columnsCollectionView?.reloadData()
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ColumnsCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        
        cell.onScroll = { [weak self] scrollView in
            self?.onScrollSync?(scrollView)
        }
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let cv = columnsCollectionView else { return }
        let centerX = cv.bounds.width / 2 + cv.contentOffset.x
        let centerY = cv.bounds.height / 2 + cv.contentOffset.y
        let centerPoint = CGPoint(x: centerX, y: centerY)
        
        if let indexPath = cv.indexPathForItem(at: centerPoint),
           indexPath.item < pairsData.count {
            let pair = pairsData[indexPath.item]
            onCenteredPairChanged?(pair)
        }
    }
    
    // Optional: If you want it also to fire when dragging ends without deceleration
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }
}
