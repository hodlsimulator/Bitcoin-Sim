//
//  PinnedColumnTablesLandscapeViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/02/2025.
//

import UIKit

class LandscapeTwoColumnFlowLayout: UICollectionViewFlowLayout {
    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        
        scrollDirection = .horizontal
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        
        // Two columns per full screen width
        let width  = cv.bounds.width
        let height = cv.bounds.height
        itemSize = CGSize(width: width / 2, height: height)
    }
    
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset,
                withScrollingVelocity: velocity
            )
        }
        
        let twoColWidth = cv.bounds.width / 2
        let rawOffsetX = proposedContentOffset.x
        let index = round(rawOffsetX / twoColWidth)
        let clampedIndex = max(index, 0)
        let snappedX = clampedIndex * twoColWidth
        
        return CGPoint(x: snappedX, y: proposedContentOffset.y)
    }
}

class PinnedColumnTablesLandscapeViewController: PinnedColumnTablesViewController {
    
    var pinnedTableWidth: CGFloat {
        return 120
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1) Hide the parent’s pinned header label (portrait)
        pinnedHeaderLabel.isHidden = true
        
        // 2) Show the landscape label
        pinnedHeaderLabelLandscape.isHidden = false
        pinnedHeaderLabelLandscape.textColor = .orange
        pinnedHeaderLabelLandscape.font = .boldSystemFont(ofSize: 16)
        
        // 3) Use a 2-column layout
        let headersLayout = LandscapeTwoColumnFlowLayout()
        columnHeadersVC.collectionView?.setCollectionViewLayout(headersLayout, animated: false)
        
        if let dataCV = columnsCollectionVC.internalCollectionView {
            let columnsLayout = LandscapeTwoColumnFlowLayout()
            dataCV.setCollectionViewLayout(columnsLayout, animated: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Don’t call super
        guard let rep = representable else { return }
        
        // Clean up pinnedColumnTitle if trailing "("
        var cleanTitle = rep.pinnedColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.hasSuffix("(") {
            cleanTitle.removeLast()
        }
        pinnedHeaderLabelLandscape.text = cleanTitle + " (Landscape)"
        
        // Reload pinned table
        pinnedTableView.reloadData()
        
        // Scroll pinned table to lastViewedRow
        let totalRows = rep.displayedData.count
        if totalRows > 0 {
            let safeRow = min(rep.lastViewedRow, totalRows - 1)
            pinnedTableView.scrollToRow(at: IndexPath(row: safeRow, section: 0), at: .top, animated: false)
        }
        
        // Show ALL columns (instead of prefix(2))
        columnHeadersVC.columnsData       = rep.columns
        columnsCollectionVC.columnsData   = rep.columns
        columnsCollectionVC.displayedData = rep.displayedData
        
        columnHeadersVC.collectionView?.reloadData()
        columnsCollectionVC.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        // Don’t call super
        let bottomSafeArea = view.safeAreaInsets.bottom
        pinnedTableView.contentInset.bottom = bottomSafeArea
        pinnedTableView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: bottomSafeArea, right: 0
        )
    }
}
