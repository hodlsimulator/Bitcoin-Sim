//
//  SnapTwoColumnsFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import UIKit

/// A layout that shows 2 columns per screen width
/// and snaps horizontally in single-column increments.
class SnapTwoColumnsFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        
        // Each cell is half the collection width => 2 columns on screen
        let width = cv.bounds.width / 2
        let height = cv.bounds.height
        
        itemSize = CGSize(width: width, height: height)
        minimumLineSpacing = 0
        scrollDirection = .horizontal
    }
    
    /// Snap to half-screen boundaries.
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }
        
        let halfWidth = cv.bounds.width / 2
        let rawPage = proposedContentOffset.x / halfWidth
        let rounded = round(rawPage)
        
        return CGPoint(x: rounded * halfWidth, y: proposedContentOffset.y)
    }
}
