//
//  CenterSnapFlowLayout.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

/// A custom UICollectionViewFlowLayout that snaps cells so one item
/// is centred horizontally after the user finishes scrolling.
class CenterSnapFlowLayout: UICollectionViewFlowLayout {

    /// Called when the user ends dragging, to finalize the scrolling position.
    override func targetContentOffset(
        forProposedContentOffset proposedContentOffset: CGPoint,
        withScrollingVelocity velocity: CGPoint
    ) -> CGPoint {
        
        guard let collectionView = self.collectionView else {
            // If something's off, fall back on default behavior
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }
        
        // The center of the collectionView once we've stopped
        let cvCenterX = proposedContentOffset.x + (collectionView.bounds.width / 2.0)
        let proposedRect = CGRect(
            x: proposedContentOffset.x,
            y: 0,
            width: collectionView.bounds.width,
            height: collectionView.bounds.height
        )

        // Grab layout attributes for the items in that area
        guard let attributesArray = self.layoutAttributesForElements(in: proposedRect) else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }

        // Find the cell that is closest to the center
        var candidateAttr: UICollectionViewLayoutAttributes?
        for attributes in attributesArray {
            if candidateAttr == nil {
                candidateAttr = attributes
                continue
            }
            let aCenterX = attributes.center.x
            let cCenterX = candidateAttr!.center.x
            
            // Compare which is closer to the (eventual) center
            if abs(aCenterX - cvCenterX) < abs(cCenterX - cvCenterX) {
                candidateAttr = attributes
            }
        }

        guard let bestAttr = candidateAttr else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset,
                                             withScrollingVelocity: velocity)
        }
        
        // Now, shift the content offset so that bestAttr is centered
        let newOffsetX = bestAttr.center.x - (collectionView.bounds.width / 2.0)
        return CGPoint(x: newOffsetX, y: proposedContentOffset.y)
    }
}
