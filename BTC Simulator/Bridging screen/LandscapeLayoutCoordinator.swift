//
//  LandscapeLayoutCoordinator.swift
//  BTCMonteCarlo
//
//  Created by Conor on 25/02/2025.
//

import UIKit

/// Responsible for setting up or restoring landscape layout.
class LandscapeLayoutCoordinator {

    unowned let vc: PinnedColumnTablesViewController

    init(vc: PinnedColumnTablesViewController) {
        self.vc = vc
    }

    /// Called when we switch to landscape or on initial load if in landscape.
    func applyLandscapeLayout() {
        // 1) Hide the portrait label, show a landscape label
        vc.pinnedHeaderLabel.isHidden = true
        vc.pinnedHeaderLabelLandscape.isHidden = false
        vc.pinnedHeaderLabelLandscape.textColor = .systemYellow
        vc.pinnedHeaderLabelLandscape.font = .boldSystemFont(ofSize: 16)
        // Optionally set text if you want
        if let rep = vc.representable {
            vc.pinnedHeaderLabelLandscape.text = rep.pinnedColumnTitle + " (Landscape)"
        }

        // 2) If you want pinned table 120 wide in landscape, do:
        vc.pinnedTableWidthOverride = 120

        // 3) If you only want 2 columns, do:
        guard let rep = vc.representable else { return }
        let twoColumns = Array(rep.columns.prefix(2))
        vc.columnHeadersVC.columnsData       = twoColumns
        vc.columnsCollectionVC.columnsData   = twoColumns
        vc.columnsCollectionVC.displayedData = rep.displayedData

        // 4) Use a custom flow layout that shows 2 columns/page
        let landscapeHeadersLayout = LandscapeTwoColumnFlowLayout()
        vc.columnHeadersVC.collectionView?.setCollectionViewLayout(
            landscapeHeadersLayout, animated: false
        )
        let landscapeColumnsLayout = LandscapeTwoColumnFlowLayout()
        vc.columnsCollectionVC.internalCollectionView?.setCollectionViewLayout(
            landscapeColumnsLayout, animated: false
        )

        // 5) Reload
        vc.columnHeadersVC.collectionView?.reloadData()
        vc.columnsCollectionVC.reloadData()
    }
}
