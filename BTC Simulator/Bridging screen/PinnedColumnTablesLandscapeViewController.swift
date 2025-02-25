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
        
        let width  = cv.bounds.width
        let height = cv.bounds.height
        // Two columns per full page width
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
        
        let halfPageWidth = cv.bounds.width / 2
        let rawOffsetX    = proposedContentOffset.x
        let index         = round(rawOffsetX / halfPageWidth)
        let snappedX      = index * halfPageWidth
        return CGPoint(x: snappedX, y: proposedContentOffset.y)
    }
}

class PinnedColumnTablesLandscapeViewController: PinnedColumnTablesViewController {
    
    override var pinnedTableWidth: CGFloat {
        return 120
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1) Hide the parent’s label so it doesn’t appear in landscape
        pinnedHeaderLabel.isHidden = true
        
        // 2) Add our own pinned header label
        pinnedHeaderView.addSubview(pinnedHeaderLabelLandscape)
        NSLayoutConstraint.activate([
            pinnedHeaderLabelLandscape.leadingAnchor.constraint(
                equalTo: pinnedHeaderView.leadingAnchor,
                constant: 10
            ),
            pinnedHeaderLabelLandscape.centerYAnchor.constraint(
                equalTo: pinnedHeaderView.centerYAnchor
            )
        ])
        
        // 3) Use our 2-column layout
        let headersLayout = LandscapeTwoColumnFlowLayout()
        columnHeadersVC.collectionView?.setCollectionViewLayout(headersLayout, animated: false)
        
        if let dataCV = columnsCollectionVC.internalCollectionView {
            let columnsLayout = LandscapeTwoColumnFlowLayout()
            dataCV.setCollectionViewLayout(columnsLayout, animated: false)
        }
    }
    
    /// Completely skip the parent’s viewWillAppear logic
    override func viewWillAppear(_ animated: Bool) {
        // no super.viewWillAppear
        guard let rep = representable else { return }
        
        pinnedHeaderLabelLandscape.text = rep.pinnedColumnTitle + " (Landscape)"
        
        // Reload pinned table
        pinnedTableView.reloadData()
        
        // Scroll pinned table to lastViewedRow
        let totalRows = rep.displayedData.count
        if totalRows > 0 {
            let safeRow = min(rep.lastViewedRow, totalRows - 1)
            pinnedTableView.scrollToRow(at: IndexPath(row: safeRow, section: 0), at: .top, animated: false)
        }
        
        // Just pick 2 columns
        let twoColumns = Array(rep.columns.prefix(2))
        
        columnHeadersVC.columnsData         = twoColumns
        columnsCollectionVC.columnsData     = twoColumns
        columnsCollectionVC.displayedData   = rep.displayedData
        
        columnHeadersVC.collectionView?.reloadData()
        columnsCollectionVC.reloadData()
    }
    
    /// Prevent the parent from “restoring” 4 columns by skipping super
    override func viewDidLayoutSubviews() {
        // Don’t call super.viewDidLayoutSubviews()
        // so we do NOT run the parent's restoreColumnIfNeeded() code.
        
        // If you need to adjust pinnedTable insets or do any custom layout, do it here:
        let bottomSafeArea = view.safeAreaInsets.bottom
        pinnedTableView.contentInset.bottom = bottomSafeArea
        pinnedTableView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: bottomSafeArea, right: 0
        )
        
        // If you want a special “restore column” in landscape, do it manually:
        // e.g. columnsCollectionVC.scrollToColumnIndex(0)
        // Or just leave as-is if you always want to start with the first page.
    }
}
