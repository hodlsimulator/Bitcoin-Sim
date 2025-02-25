//
//  PinnedColumnTablesLandscapeViewController.swift
//  BTCMonteCarlo
//
//  Created by . . on 25/02/2025.
//

import UIKit

/// A flow layout that snaps so only 2 columns are visible per 'page'.
/// Feel free to tweak the snapping logic or item size as needed.
class LandscapeTwoColumnFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        
        // Horizontal scroll
        scrollDirection = .horizontal
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
        
        // Each page = cv.bounds.width, so 2 columns per page => each column half of that width
        let pageWidth = cv.bounds.width
        let itemWidth = pageWidth / 2
        let itemHeight = cv.bounds.height
        itemSize = CGSize(width: itemWidth, height: itemHeight)
    }
    
    /// This tries to snap each scroll so that columns land precisely on half-page boundaries.
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let cv = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        
        let pageWidth = cv.bounds.width
        // We snap to multiples of (pageWidth / 2)
        let halfPageWidth = pageWidth / 2
        
        // Proposed offset x
        let rawOffsetX = proposedContentOffset.x
        
        // Snap to the nearest halfPage boundary
        let index = round(rawOffsetX / halfPageWidth)
        let snappedX = index * halfPageWidth
        
        return CGPoint(x: snappedX, y: proposedContentOffset.y)
    }
}

/// This subclass overrides the pinned table width for landscape,
/// and replaces the default flow layout with our 2-column layout.
class PinnedColumnTablesLandscapeViewController: PinnedColumnTablesViewController {

    override var pinnedTableWidth: CGFloat {
        return 120
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1) We can optionally change rowHeight, backgrounds, etc. for landscape:
        // pinnedTableView.rowHeight = 60
        
        // 2) Replace the layout of the *headers* collection view:
        let headersLayout = LandscapeTwoColumnFlowLayout()
        columnHeadersVC.collectionView?.setCollectionViewLayout(headersLayout, animated: false)
        
        // 3) Replace the layout of the main columns collection as well:
        if let dataCV = columnsCollectionVC.internalCollectionView {
            let columnsLayout = LandscapeTwoColumnFlowLayout()
            dataCV.setCollectionViewLayout(columnsLayout, animated: false)
        }
        
        // This setup ensures that we see exactly 2 columns (and 2 corresponding titles)
        // per “page” in landscape, and they scroll/snap together.
    }
}
