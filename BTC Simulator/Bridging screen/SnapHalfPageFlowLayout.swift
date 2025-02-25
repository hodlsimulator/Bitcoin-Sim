//
//  SnapHalfPageFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/02/2025.
//

import UIKit

/// A layout that displays 2 columns across the full width
/// (each item is half the (collectionWidth - pinnedColumnWidth)),
/// then snaps horizontally in half-width increments.
///
/// This now subtracts `pinnedColumnWidth` so we don't
/// partially show a third column, and clamps negative offsets.
class SnapHalfPageFlowLayout: UICollectionViewFlowLayout {

    /// Adjust if you have a pinned column of fixed width
    var pinnedColumnWidth: CGFloat = 70

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        scrollDirection     = .horizontal
        sectionInset        = .zero
        minimumLineSpacing  = 0
        cv.decelerationRate = .fast
        cv.clipsToBounds    = true

        let adjustedWidth = cv.bounds.width - pinnedColumnWidth
        let height        = cv.bounds.height

        // Only set itemSize if valid
        if adjustedWidth > 0, height > 0 {
            let halfWidth = floor(adjustedWidth / 2.0)
            itemSize = CGSize(width: halfWidth, height: height)
        }
    }

    /// Snaps to multiples of half the (cvWidth - pinnedColumnWidth).
    /// Clamps negative offsets so columns don't scroll too far right.
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

        let adjustedWidth = cv.bounds.width - pinnedColumnWidth
        guard adjustedWidth > 0 else {
            // fallback
            return super.targetContentOffset(
                forProposedContentOffset: proposedContentOffset,
                withScrollingVelocity: velocity
            )
        }

        let halfWidth = adjustedWidth / 2.0
        let rawPage   = proposedContentOffset.x / halfWidth
        let nearest   = round(rawPage)
        let newX      = max(0, nearest * halfWidth)  // clamp to >= 0

        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
