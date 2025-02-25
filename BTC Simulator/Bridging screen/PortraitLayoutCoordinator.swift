//
//  PortraitLayoutCoordinator.swift
//  BTCMonteCarlo
//
//  Created by Conor on 25/02/2025.
//

import UIKit

class PortraitLayoutCoordinator {
    unowned let vc: PinnedColumnTablesViewController
    
    init(vc: PinnedColumnTablesViewController) {
        self.vc = vc
    }
    
    func applyPortraitLayout() {
        guard let rep = vc.representable else { return }
        
        // Remove trailing "(" if present
        var cleanTitle = rep.pinnedColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.hasSuffix("(") {
            cleanTitle.removeLast()
        }
        
        // Show portrait label, hide landscape
        vc.pinnedHeaderLabel.isHidden          = false
        vc.pinnedHeaderLabelLandscape.isHidden = true
        
        vc.pinnedHeaderLabel.textColor = .orange
        vc.pinnedHeaderLabel.text      = cleanTitle
        
        // pinned table width
        vc.pinnedTableWidthOverride = 70
        vc.pinnedTableView.scrollsToTop = true
        
        // Use the full columns
        vc.columnHeadersVC.columnsData       = rep.columns
        vc.columnsCollectionVC.columnsData   = rep.columns
        vc.columnsCollectionVC.displayedData = rep.displayedData
        
        // Use SnapHalfPageFlowLayout
        if let snapLayout = vc.columnHeadersVC.collectionView?.collectionViewLayout
            as? SnapHalfPageFlowLayout {
            snapLayout.pinnedColumnWidth = 70
        }
        if let snapLayout2 = vc.columnsCollectionVC.internalCollectionView?.collectionViewLayout
            as? SnapHalfPageFlowLayout {
            snapLayout2.pinnedColumnWidth = 70
        }
        
        // Force offsets to 0
        vc.columnHeadersVC.collectionView?.contentOffset.x = 0
        vc.columnsCollectionVC.internalCollectionView?.contentOffset.x = 0
        
        // Reload
        vc.columnHeadersVC.collectionView?.reloadData()
        vc.columnsCollectionVC.reloadData()
        vc.pinnedTableView.reloadData()
    }
}
