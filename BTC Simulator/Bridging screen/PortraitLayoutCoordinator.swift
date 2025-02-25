//
//  PortraitLayoutCoordinator.swift
//  BTCMonteCarlo
//
//  Created by Conor on 25/02/2025.
//

import UIKit

/// Responsible for setting up or restoring portrait layout.
class PortraitLayoutCoordinator {

    unowned let vc: PinnedColumnTablesViewController

    init(vc: PinnedColumnTablesViewController) {
        self.vc = vc
    }

    /// Called when we switch to portrait or on initial load if in portrait.
    func applyPortraitLayout() {
        // 1) Show the portrait pinnedHeaderLabel, hide any landscape label
        vc.pinnedHeaderLabel.isHidden = false
        vc.pinnedHeaderLabelLandscape.isHidden = true

        // 2) If you want the pinned table 70 wide in portrait, do:
        // (But if your constraints are anchored to pinnedTableWidth, just override the var)
        vc.pinnedTableWidthOverride = 70

        // 3) If you want 4 columns for portrait, just assign them from representable:
        guard let rep = vc.representable else { return }
        vc.columnHeadersVC.columnsData       = rep.columns
        vc.columnsCollectionVC.columnsData   = rep.columns
        vc.columnsCollectionVC.displayedData = rep.displayedData

        // 4) Re-run collection/table reload if necessary
        vc.columnHeadersVC.collectionView?.reloadData()
        vc.columnsCollectionVC.reloadData()

        // 5) If you have any portrait-specific constraints or sizes, do them here.
        // For instance, if you need to reset the flow layouts for 4 columns per "page",
        // you'd apply a SnapHalfPageFlowLayout or whatever you used originally.
    }
}
