//
//  SnapHalfPageFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/02/2025.
//

import UIKit

/// A layout that displays 2 columns across the full width
/// (each item is half the view width), but snaps horizontally
/// in half-width increments, so each swipe slides over by 1 column.
class SnapHalfPageFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        scrollDirection = .horizontal
        sectionInset   = .zero
        minimumLineSpacing = 0

        // Each column is half the total width => 2 columns fill the screen
        let halfWidth = floor(cv.bounds.width / 2)
        let height    = cv.bounds.height
        itemSize      = CGSize(width: halfWidth, height: height)

        // For strong snapping
        cv.decelerationRate = .fast

        // Clip so partial columns never peek
        cv.clipsToBounds = true
    }

    /// Snaps to multiples of half the screen width => each 'page' shifts by one column.
    /// E.g. if columns (2,3) are in view, next swipe shows (3,4).
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let halfWidth = cv.bounds.width / 2.0
        // rawPage = how many half-widths the user scrolled
        let rawPage   = proposedContentOffset.x / halfWidth
        let nearest   = round(rawPage)
        let newX      = nearest * halfWidth

        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
