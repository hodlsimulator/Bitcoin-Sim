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
    
    // Store references so off-screen columns can also sync
    private var columnCells: [Int: OneColumnCell] = [:]

    var internalCollectionView: UICollectionView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        // (A) Set up snap layout => 2 columns per screen
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

        // (B) Add a tap gesture so tapping left side => page left, right side => page right
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToPage(_:)))
        // Attach the gesture to the entire controller’s view
        // (so it sees taps anywhere within the full area):
        view.addGestureRecognizer(tapGesture)
    }

    func reloadData() {
        internalCollectionView?.reloadData()
    }

    // Sync all columns (including off-screen)
    func updateAllColumnsVerticalOffset(_ offset: CGPoint) {
        for (_, cell) in columnCells {
            cell.setVerticalOffset(offset)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Example: if col 2 is "BTC Price", scroll so we see columns (2,3)
        // scrollToColumnIndex(2)
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

        columnCells[indexPath.item] = cell

        cell.onScroll = { [weak self] scrollView in
            self?.onScrollSync?(scrollView)
            if let pinnedVC = self?.parent as? PinnedColumnTablesViewController {
                pinnedVC.scrollViewDidScroll(scrollView)
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        if let oneColCell = cell as? OneColumnCell,
           let parentVC    = self.parent as? PinnedColumnTablesViewController {
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

    private func identifyLeftColumn(in scrollView: UIScrollView) {
        guard let cv = internalCollectionView else { return }

        // Because each 'page' is half the width (1-column shift),
        // we shift the detection point by 1/4 the screen to pick the left item.
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

    func scrollToColumnIndex(_ index: Int) {
        guard index >= 0 && index < columnsData.count else { return }
        let indexPath = IndexPath(item: index, section: 0)
        internalCollectionView?.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.left, animated: false)
    }
}

// MARK: - Tap-to-Page Implementation
extension TwoColumnCollectionViewController {

    // This is the code you provided
    @objc private func handleTapToPage(_ gesture: UITapGestureRecognizer) {
        guard let cv = internalCollectionView else { return }

        // 1) Where the user tapped in *this VC’s* coordinate space
        let pointInSelf = gesture.location(in: self.view)
        let screenHalf  = self.view.bounds.width / 2.0

        // 2) Identify the current column via content offset
        let halfWidth = cv.bounds.width / 2.0
        let rawPage   = cv.contentOffset.x / halfWidth
        var currentPage = Int(round(rawPage))

        // 3) If the user tapped the left half of the screen => -1, else => +1
        if pointInSelf.x < screenHalf {
            currentPage -= 1
        } else {
            currentPage += 1
        }

        // 4) Clamp
        currentPage = max(0, min(currentPage, columnsData.count - 1))

        // 5) Scroll
        scrollToColumnIndex(currentPage)
    }
}
