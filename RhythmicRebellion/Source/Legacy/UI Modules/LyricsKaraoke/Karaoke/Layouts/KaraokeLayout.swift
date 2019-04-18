//
//  KaraokeScrollCollectionViewFlowLayout.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class LayoutAttributes: UICollectionViewLayoutAttributes {

    var boundsCenterOffset = CGPoint(x: 0.0, y: 0.0)
    var activeDistance: CGFloat = 0.0

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! LayoutAttributes
        copy.boundsCenterOffset = boundsCenterOffset
        copy.activeDistance = activeDistance
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard super.isEqual(object) else { return false }

        guard let karaokeLayoutAttributes = object as? LayoutAttributes else { return true }

        return karaokeLayoutAttributes.boundsCenterOffset == boundsCenterOffset && karaokeLayoutAttributes.activeDistance == activeDistance
    }
}

class KaraokeLayout: UICollectionViewFlowLayout {

    private var animator: UIDynamicAnimator!
    private var animatorIndexPaths = Set<IndexPath>()

    override class var layoutAttributesClass: AnyClass { return LayoutAttributes.self }

    var lastContentSize = CGSize.zero

    // MARK: - Initialization

    override public init() {
        super.init()
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        sectionInset = .init(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
        animator = UIDynamicAnimator(collectionViewLayout: self)
    }

    // MARK: - Overrides
    override open func prepare() {

        super.prepare()

        guard let collectionView = collectionView else { return }
        
        guard let visibleAttributes = super.layoutAttributesForElements(in: collectionView.bounds) else {
            animator.removeAllBehaviors()
            animatorIndexPaths.removeAll()
            return
        }

        if lastContentSize != collectionViewContentSize {
            animator.removeAllBehaviors()
            animatorIndexPaths.removeAll()
        }

        ////remove behaviours from no longer visible attributes
        let visibleAttributesIndexPaths = Set(visibleAttributes.map { $0.indexPath } )

        animator.behaviors.forEach { (behavior) in
            
            guard let behavior = behavior as? UIAttachmentBehavior,
                let attributes = behavior.items.first as? UICollectionViewLayoutAttributes,
                animatorIndexPaths.subtracting(visibleAttributesIndexPaths).contains(attributes.indexPath) else { return }

            animator.removeBehavior(behavior)
        }
        
        ////add behaviours to new visible attributes
        visibleAttributes
            .filter {
                animatorIndexPaths.contains($0.indexPath) == false
            }
            .forEach { layoutAttributes in
                
                let behaviour = UIAttachmentBehavior(item: layoutAttributes, attachedToAnchor: layoutAttributes.center)
                
                behaviour.length = 0.0
                behaviour.damping = 0.0
                behaviour.frequency = 0.0
                
                animator.addBehavior(behaviour)
            }

        
        
        lastContentSize = collectionViewContentSize
        animatorIndexPaths = visibleAttributesIndexPaths
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let attributes = animator.items(in: rect) as? [LayoutAttributes],
              attributes.isEmpty == false else {
            return super.layoutAttributesForElements(in: rect)
        }

        guard let collectionView = collectionView else { return attributes }

        attributes.forEach { attribute in
            update(attributes: attribute, in: collectionView)
        }

        return attributes
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let attributes = animator.layoutAttributesForCell(at: indexPath) else {
            return super.layoutAttributesForItem(at: indexPath)
        }

        return attributes
    }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {

        guard collectionView != nil else { return false }

        animator.behaviors
            .compactMap { $0 as? UIAttachmentBehavior }
            .forEach { behavior in
                
                guard let dynamicItem = behavior.items.first else { return }
                
                animator.updateItem(usingCurrentState: dynamicItem)
                
        }

        return false
    }

    open func update(attributes: LayoutAttributes, in collectionView: UICollectionView) {

        attributes.zIndex = attributes.indexPath.item

        let boundsCenterOffset = CGPoint(x: attributes.center.x - collectionView.bounds.midX - sectionInset.left,
                                         y: attributes.center.y - collectionView.bounds.midY - sectionInset.top)
        attributes.boundsCenterOffset = boundsCenterOffset
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


        if abs(attributes.boundsCenterOffset.y) <= attributes.frame.height + minimumLineSpacing {
            let scale = 1.0 - (0.4 * abs(attributes.boundsCenterOffset.y) / (attributes.frame.height + minimumLineSpacing))

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
