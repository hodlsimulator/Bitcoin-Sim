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
///
/// To align with a pinned column (70pt), you can either:
/// (1) Subtract 70 from the collection view’s frame so itemSize
///     is truly half the *remaining* width, or
/// (2) Let the collection view fill the screen and rely on a top-level
///     layout guide so the collection starts at X=70. This code below
///     demonstrates approach (1).
class SnapHalfPageFlowLayout: UICollectionViewFlowLayout {

    /// Adjust this if you have a pinned column of a fixed width
    /// and you want the 'snapping' columns to fill (screenWidth - pinnedWidth).
    var pinnedColumnWidth: CGFloat = 0

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        scrollDirection = .horizontal
        sectionInset   = .zero
        minimumLineSpacing = 0

        // If the pinned column is separate, you might do:
        // let availableWidth = cv.bounds.width - pinnedColumnWidth
        // But if your collection view is itself sized to exclude the pinned column,
        // then you can just do:
        let availableWidth = cv.bounds.width

        let halfWidth = floor(availableWidth / 2)
        let height    = cv.bounds.height
        itemSize      = CGSize(width: halfWidth, height: height)

        // Strong snapping so it locks to each half-width.
        cv.decelerationRate = .fast

        // Clip so partial columns never peek
        cv.clipsToBounds = true
    }

    /// Snaps to multiples of half the screen width => each 'page' shifts by one column.
    /// e.g. if columns (2,3) are in view, next swipe reveals (3,4).
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

        let availableWidth = cv.bounds.width
        let halfWidth      = availableWidth / 2.0
        
        // rawPage = how many half-widths the user scrolled
        let rawPage   = proposedContentOffset.x / halfWidth
        let nearest   = round(rawPage)
        let newX      = nearest * halfWidth

        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
