//
//  ColumnsCollectionViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class ColumnsCollectionViewController: UIViewController {

    // The columns & data we want to display.
    // PartialKeyPath so each property can be Int/Double/Decimal.
    var allColumns: [(String, PartialKeyPath<SimulationData>)] = []
    var displayedData: [SimulationData] = []

    // For pinned-table scrolling sync
    var onScrollSync: ((UIScrollView) -> Void)?

    // Optionally track a “currentActiveIndex” if needed
    private var currentActiveIndex: Int = 0

    // The collection view + a custom layout
    private var collectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear

        // 1) Create the layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        // For partial columns:
        //   - item width < screen width
        //   - a bit of spacing so you see a “peek” of next column
        layout.itemSize = CGSize(width: 240, height: view.bounds.height)
        layout.minimumLineSpacing = 10

        // 2) Create the collection view
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.decelerationRate = .fast       // for a snappier feel
        cv.isPagingEnabled = false        // we want partial scroll, not full paging
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView = cv

        view.addSubview(cv)

        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // 3) Register a custom cell
        cv.register(ColumnsCollectionCell.self, forCellWithReuseIdentifier: "ColumnsCollectionCell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // If you want to default to columns #2 and #3,
        // you might scroll to index 2 so it’s at or near the left edge:
        if allColumns.count > 2 {
            let idxPath = IndexPath(item: 2, section: 0)
            collectionView?.scrollToItem(at: idxPath, at: .left, animated: false)
        }
    }
}

extension ColumnsCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return allColumns.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ColumnsCollectionCell",
            for: indexPath
        ) as? ColumnsCollectionCell else {
            return UICollectionViewCell()
        }

        let (title, partial) = allColumns[indexPath.item]
        cell.configure(
            columnTitle: title,
            partialKeyPath: partial,
            displayedData: displayedData
        )

        return cell
    }

    // If you want custom spacing or sizing beyond the FlowLayout’s itemSize,
    // implement delegateFlowLayout methods here. But the big one is itemSize.
}
