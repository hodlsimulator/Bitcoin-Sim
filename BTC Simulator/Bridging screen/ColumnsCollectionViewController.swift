//
//  ColumnsCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class ColumnsCollectionViewController: UIViewController {
    
    // Instead of pairsData, we have a simple list of columns (one per cell)
    public var columnsData: [(String, PartialKeyPath<SimulationData>)] = []
    public var displayedData: [SimulationData] = []
    
    // For pinned-table vertical sync
    public var onScrollSync: ((UIScrollView) -> Void)?
    // For detecting which column is centred
    public var onCenteredColumnChanged: ((Int) -> Void)?
    
    public var columnsCollectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let layout = SnapTwoColumnsFlowLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast
        cv.dataSource = self
        cv.delegate   = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        
        // Remove content insets
        cv.contentInset = .zero
        cv.contentInsetAdjustmentBehavior = .never
        
        // Register the single-column cell
        cv.register(OneColumnCell.self, forCellWithReuseIdentifier: "OneColumnCell")
        
        view.addSubview(cv)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.columnsCollectionView = cv
    }
    
    public func reloadData() {
        columnsCollectionView?.reloadData()
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension ColumnsCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
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
        
        let (title, kp) = columnsData[indexPath.item]
        cell.configure(
            columnTitle: title,
            partialKey: kp,
            displayedData: displayedData
        )
        
        cell.onScroll = { [weak self] scrollView in
            // Already in place:
            self?.onScrollSync?(scrollView)
            
            // NEW: also call pinnedColumnTablesViewController’s scrollViewDidScroll
            if let pinnedVC = self?.parent as? PinnedColumnTablesViewController {
                pinnedVC.scrollViewDidScroll(scrollView)
            }
        }
        
        return cell
    }
    
    // Snap detection for which column is “centered”
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        handleCentredColumn(scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if !willDecelerate { handleCentredColumn(scrollView) }
    }
    
    private func handleCentredColumn(_ scrollView: UIScrollView) {
        let centerX = scrollView.contentOffset.x + (scrollView.bounds.width / 2)
        let centerPoint = CGPoint(x: centerX, y: scrollView.bounds.height / 2)
        
        if let indexPath = columnsCollectionView?.indexPathForItem(at: centerPoint) {
            onCenteredColumnChanged?(indexPath.item)
        }
    }
}
