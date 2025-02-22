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
        
        // Calculate the width as an integer value using floor
        let width = floor(cv.bounds.width / 2)
        let height = cv.bounds.height
        
        itemSize = CGSize(width: width, height: height)
        minimumLineSpacing = 0
        scrollDirection = .horizontal
        
        // Force a higher deceleration rate for stronger snapping
        cv.decelerationRate = UIScrollView.DecelerationRate.fast
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        
        for attr in attributes {
            attr.frame = CGRect(
                x: round(attr.frame.origin.x),
                y: attr.frame.origin.y,
                width: attr.frame.width,
                height: attr.frame.height
            )
        }
        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attr = super.layoutAttributesForItem(at: indexPath) else { return nil }
        attr.frame = CGRect(
            x: round(attr.frame.origin.x),
            y: attr.frame.origin.y,
            width: attr.frame.width,
            height: attr.frame.height
        )
        return attr
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
