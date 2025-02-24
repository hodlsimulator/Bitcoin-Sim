//
//  SnapFixedWidthFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 24/02/2025.
//

import UIKit
/*
class SnapFixedWidthFlowLayout: UICollectionViewFlowLayout {
    let columnWidth: CGFloat = 150
    
    override func prepare() {
        super.prepare()
        guard let cv = collectionView else { return }
        scrollDirection = .horizontal
        minimumLineSpacing = 0

        // Each item is 150 points wide
        itemSize = CGSize(width: columnWidth, height: cv.bounds.height)
        cv.decelerationRate = .fast
    }

    override func targetContentOffset(
      forProposedContentOffset proposedContentOffset: CGPoint,
      withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        let rawPage = proposedContentOffset.x / columnWidth
        let nearest = round(rawPage)
        return CGPoint(x: nearest * columnWidth, y: proposedContentOffset.y)
    }
}
*/
