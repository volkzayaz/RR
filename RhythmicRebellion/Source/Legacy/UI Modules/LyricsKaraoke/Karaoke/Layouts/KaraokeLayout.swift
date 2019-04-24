//
//  KaraokeScrollCollectionViewFlowLayout.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class LayoutAttributes: UICollectionViewLayoutAttributes {

    var verticalOffset: CGFloat = 0.0
    var activeDistance: CGFloat = 0.0

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! LayoutAttributes
        copy.verticalOffset = verticalOffset
        copy.activeDistance = activeDistance
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard super.isEqual(object) else { return false }

        guard let karaokeLayoutAttributes = object as? LayoutAttributes else { return true }

        return karaokeLayoutAttributes.verticalOffset == verticalOffset && karaokeLayoutAttributes.activeDistance == activeDistance
    }
}

class KaraokeLayout: UICollectionViewFlowLayout {

    override class var layoutAttributesClass: AnyClass { return LayoutAttributes.self }

    // MARK: - Overrides
    override open func prepare() {

        super.prepare()

        guard let collectionView = collectionView else { return }
        
        sectionInset = .init(top: collectionView.bounds.size.height / 2, left: 15.0, bottom: collectionView.bounds.size.height / 2, right: 15.0)

    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let attributes = super.layoutAttributesForElements(in: rect) as? [LayoutAttributes],
              attributes.isEmpty == false else {
            return super.layoutAttributesForElements(in: rect)
        }

        guard let collectionView = collectionView else { return attributes }

        attributes.forEach { attribute in
            update(attributes: attribute, in: collectionView)
        }

        return attributes
    }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {

        guard collectionView != nil else { return false }

        return true
    }

    open func update(attributes: LayoutAttributes, in collectionView: UICollectionView) {

        attributes.zIndex = attributes.indexPath.item

        attributes.verticalOffset = attributes.center.y - collectionView.bounds.midY
        attributes.activeDistance = attributes.frame.height + minimumLineSpacing
    }

    open func itemSize(at indexPath: IndexPath, with viewModel: KaraokeViewModel) -> CGSize {

        guard let collectionView = collectionView else { return CGSize.zero }

        let width = collectionView.frame.width - (sectionInset.left + sectionInset.right)
        var itemSize = viewModel.itemSize(at: indexPath, for: width)

        itemSize.height += 2

        return itemSize
    }
}

class KaraokeScrollLayout: KaraokeLayout {
    
    override init() {
        super.init()
        
        minimumLineSpacing = 10.0
        minimumInteritemSpacing = 0.0
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class KaraokeOnePhraseLayout: KaraokeLayout {

    open override func update(attributes: LayoutAttributes, in collectionView: UICollectionView) {

        super.update(attributes: attributes, in: collectionView)


        if abs(attributes.verticalOffset) <= attributes.frame.height + minimumLineSpacing {
            let scale = 1.0 - (0.4 * abs(attributes.verticalOffset) / (attributes.frame.height + minimumLineSpacing))

            attributes.transform = CGAffineTransform(scaleX: scale, y: scale)

        } else {
            attributes.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }

    }

    open override func itemSize(at indexPath: IndexPath, with viewModel: KaraokeViewModel) -> CGSize {

        guard let collectionView = collectionView else { return CGSize.zero }

        let itemSize = super.itemSize(at: indexPath, with: viewModel)

        return CGSize(width: itemSize.width, height: max(itemSize.height, collectionView.frame.height / 3))
    }
}
