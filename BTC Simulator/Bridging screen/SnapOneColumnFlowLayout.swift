//
//  SnapOneColumnFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/02/2025.
//

import UIKit

/// A flow layout that snaps horizontally so each item takes the full width.
/// That means exactly 1 column is visible at a time, as if paging.
class SnapOneColumnFlowLayout: UICollectionViewFlowLayout {

    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }

        scrollDirection = .horizontal
        sectionInset = .zero
        minimumLineSpacing = 0
        
        // Each page = 1 column that fills the entire collection width
        let width  = cv.bounds.width
        let height = cv.bounds.height
        itemSize   = CGSize(width: width, height: height)
        
        // Fast deceleration => strong snap
        cv.decelerationRate = .fast
        
        // So partial off‑screen columns don’t peek in
        cv.clipsToBounds = true
    }

    /// Force snapping to full collection‑view‑width pages
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }

        let pageWidth = cv.bounds.width
        let approximatePage = proposedContentOffset.x / pageWidth
        
        // If velocity.x == 0 => user basically stopped => round to nearest page
        // If velocity.x > 0 => user flicked to the next page
        // If velocity.x < 0 => previous page
        let currentPage: CGFloat
        if velocity.x == 0 {
            currentPage = round(approximatePage)
        } else if velocity.x > 0 {
            currentPage = floor(approximatePage) + 1
        } else {
            currentPage = ceil(approximatePage) - 1
        }

        let newX = max(0, currentPage * pageWidth)
        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
