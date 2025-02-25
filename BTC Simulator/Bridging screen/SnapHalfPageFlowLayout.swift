//
//  SnapHalfPageFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/02/2025.
//

import UIKit

/// A layout that displays exactly 2 columns across the full width.
/// Each item is half the collectionView’s width (so 2 items fit per 'page'),
/// and it snaps horizontally in half-width increments.
class SnapHalfPageFlowLayout: UICollectionViewFlowLayout {
    
    /// We keep this property in case you want to override it somewhere,
    /// but we're no longer subtracting it to widen the columns.
    var pinnedColumnWidth: CGFloat = 70

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        scrollDirection     = .horizontal
        sectionInset        = .zero
        minimumLineSpacing  = 0
        cv.decelerationRate = .fast
        cv.clipsToBounds    = true

        // Make columns half the total width => 2 columns per full screen
        let adjustedWidth = cv.bounds.width
        let height        = cv.bounds.height
        
        if adjustedWidth > 0, height > 0 {
            let halfWidth = floor(adjustedWidth / 2.0)
            itemSize = CGSize(width: halfWidth, height: height)
        }
    }

    /// Snaps to multiples of half the collectionView width.
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
        
        let adjustedWidth = cv.bounds.width
        guard adjustedWidth > 0 else {
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset,
                withScrollingVelocity: velocity
            )
        }
        
        let halfWidth = adjustedWidth / 2.0
        let rawPage   = proposedContentOffset.x / halfWidth
        let nearest   = round(rawPage)
        let newX      = max(0, nearest * halfWidth)
        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
