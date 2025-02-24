//
//  SnapTwoColumnsFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import UIKit

/// A flow layout that shows exactly 2 columns per page.
/// Each column is (collectionViewWidth / 2) wide.
/// Auto-snaps so we always land on a boundary aligned with multiples of half the width.
class SnapTwoColumnsFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        
        scrollDirection = .horizontal
        sectionInset   = .zero
        minimumLineSpacing = 0

        // Each "page" shows 2 items => each item is half the total width
        let halfWidth = floor(cv.bounds.width / 2)
        let height    = cv.bounds.height
        itemSize      = CGSize(width: halfWidth, height: height)

        // Strong snapping
        cv.decelerationRate = .fast

        // Clip partial columns
        cv.clipsToBounds = true
    }

    /// Force the collection to snap horizontally to half-screen boundaries
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let halfWidth = cv.bounds.width / 2.0
        let rawPage   = proposedContentOffset.x / halfWidth
        let nearest   = round(rawPage)
        let newX      = nearest * halfWidth

        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
    
