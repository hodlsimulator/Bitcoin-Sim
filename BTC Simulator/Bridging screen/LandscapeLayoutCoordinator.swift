//
//  LandscapeLayoutCoordinator.swift
//  BTCMonteCarlo
//
//  Created by Conor on 25/02/2025.
//

import UIKit

class LandscapeLayoutCoordinator {
    unowned let vc: PinnedColumnTablesViewController
    
    init(vc: PinnedColumnTablesViewController) {
        self.vc = vc
    }
    
    func applyLandscapeLayout() {
        guard let rep = vc.representable else { return }
        
        // Hide portrait label, show landscape
        vc.pinnedHeaderLabel.isHidden = true
        vc.pinnedHeaderLabelLandscape.isHidden = false
        
        // Remove trailing "(" if present
        var cleanTitle = rep.pinnedColumnTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanTitle.hasSuffix("(") {
            cleanTitle.removeLast()
        }
        
        vc.pinnedHeaderLabelLandscape.textColor = .orange
        vc.pinnedHeaderLabelLandscape.font      = .boldSystemFont(ofSize: 16)
        vc.pinnedHeaderLabelLandscape.text      = cleanTitle
        
        // pinned table in landscape
        vc.pinnedTableWidthOverride = 120
        vc.pinnedTableView.scrollsToTop = true
        
        // Show all columns
        vc.columnHeadersVC.columnsData       = rep.columns
        vc.columnsCollectionVC.columnsData   = rep.columns
        vc.columnsCollectionVC.displayedData = rep.displayedData
        
        // Use SnapHalfPageFlowLayout but shift pinnedColumnWidth
        if let snapLayout = vc.columnHeadersVC.collectionView?.collectionViewLayout
            as? SnapHalfPageFlowLayout {
            snapLayout.pinnedColumnWidth = 100  // Keep data at x=100
        }
        if let snapLayout2 = vc.columnsCollectionVC.internalCollectionView?.collectionViewLayout
            as? SnapHalfPageFlowLayout {
            snapLayout2.pinnedColumnWidth = 100
        }
        
        // Remove any forced content insets so the background can stretch
        vc.columnHeadersVC.collectionView?.contentInset = .zero
        vc.columnsCollectionVC.internalCollectionView?.contentInset = .zero
        
        // Force offset to 0 so user sees the first columns
        vc.columnHeadersVC.collectionView?.setContentOffset(.zero, animated: false)
        vc.columnsCollectionVC.internalCollectionView?.setContentOffset(.zero, animated: false)
        
        // Reload
        vc.columnHeadersVC.collectionView?.reloadData()
        vc.columnsCollectionVC.reloadData()
        vc.pinnedTableView.reloadData()
    }
}
