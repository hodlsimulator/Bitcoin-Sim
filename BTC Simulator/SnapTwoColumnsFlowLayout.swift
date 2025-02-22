//
//  SnapTwoColumnsFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import UIKit

class SnapTwoColumnsFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        
        // Each item is half the collection width => 2 columns per screen
        let width  = cv.bounds.width / 2
        let height = cv.bounds.height
        
        itemSize = CGSize(width: width, height: height)
        minimumLineSpacing = 0
        scrollDirection = .horizontal
        
        // Force a higher deceleration rate for stronger snapping
        cv.decelerationRate = UIScrollView.DecelerationRate.fast
        // If you want it even more abrupt, you can do:
        // cv.decelerationRate = UIScrollView.DecelerationRate(rawValue: UIScrollView.DecelerationRate.fast.rawValue * 2.0)
    }
    
    /// Force a snap to half-screen boundaries,
    /// ignoring velocity so it always lands on the nearest page.
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        guard let cv = collectionView else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }
        
        // Each "page" is half the screen
        let halfWidth = cv.bounds.width / 2
        
        // We'll ignore the actual velocity and snap to the nearest half page
        let rawPage = proposedContentOffset.x / halfWidth
        let rounded = round(rawPage)
        let newX = rounded * halfWidth
        
        return CGPoint(x: newX, y: proposedContentOffset.y)
    }
}
