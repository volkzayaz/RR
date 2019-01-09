//
//  KaraokeScrollCollectionViewFlowLayout.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 12/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit


protocol KaraokeCollectionViewFlowLayoutViewModel {
    func itemSize(at indexPath: IndexPath, for width: CGFloat) -> CGSize
}

class KaraokeCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {

    var boundsCenterOffset = CGPoint(x: 0.0, y: 0.0)
    var activeDistance: CGFloat = 0.0

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! KaraokeCollectionViewLayoutAttributes
        copy.boundsCenterOffset = self.boundsCenterOffset
        copy.activeDistance = self.activeDistance
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard super.isEqual(object) else { return false }

        guard let karaokeLayoutAttributes = object as? KaraokeCollectionViewLayoutAttributes else { return true }

        return karaokeLayoutAttributes.boundsCenterOffset == self.boundsCenterOffset && karaokeLayoutAttributes.activeDistance == self.activeDistance
    }
}

class KaraokeCollectionViewFlowLayout: UICollectionViewFlowLayout {

    private var dynamicAnimator: UIDynamicAnimator!
    private var dynamicAnimatorIndexPaths = Set<IndexPath>()

    override class var layoutAttributesClass: AnyClass { return KaraokeCollectionViewLayoutAttributes.self }

    var lastCollectionViewContentSize: CGSize = CGSize.zero

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
        dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
    }

    // MARK: - Overrides
    override open func prepare() {

        super.prepare()

        guard let collectionView = self.collectionView else { return }
        
        guard let inBoundsLayoutAttributes = super.layoutAttributesForElements(in: collectionView.bounds) else {
            self.dynamicAnimator.removeAllBehaviors()
            self.dynamicAnimatorIndexPaths.removeAll()
            return
        }

        if self.lastCollectionViewContentSize != self.collectionViewContentSize {
            self.dynamicAnimator.removeAllBehaviors()
            self.dynamicAnimatorIndexPaths.removeAll()
        }

        let indexPathsForInBoundsLayoutAttributes = Set(inBoundsLayoutAttributes.map { $0.indexPath } )

        let indexPathsForNoLongerInBoundsLayoutAttributes = self.dynamicAnimatorIndexPaths.subtracting(indexPathsForInBoundsLayoutAttributes)
        self.dynamicAnimator.behaviors.forEach { (behavior) in
            guard let behavior = behavior as? UIAttachmentBehavior,
                let layoutAttributes = behavior.items.first as? UICollectionViewLayoutAttributes,
                indexPathsForNoLongerInBoundsLayoutAttributes.contains(layoutAttributes.indexPath) else { return }

            self.dynamicAnimator.removeBehavior(behavior)
        }

        let newlyInBoundsLayoutAttributes = inBoundsLayoutAttributes.filter { self.dynamicAnimatorIndexPaths.contains($0.indexPath) == false }
        newlyInBoundsLayoutAttributes.forEach { layoutAttributes in
            let attachmentBehaviour = UIAttachmentBehavior(item: layoutAttributes, attachedToAnchor: layoutAttributes.center)

            attachmentBehaviour.length = 0.0
            attachmentBehaviour.damping = 0.0
            attachmentBehaviour.frequency = 0.0

            self.dynamicAnimator.addBehavior(attachmentBehaviour)
        }

        self.dynamicAnimatorIndexPaths = indexPathsForInBoundsLayoutAttributes
        self.lastCollectionViewContentSize = self.collectionViewContentSize
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let elementsLayoutAttributes = dynamicAnimator.items(in: rect) as? [KaraokeCollectionViewLayoutAttributes], elementsLayoutAttributes.isEmpty == false else {
            return super.layoutAttributesForElements(in: rect)
        }

        guard let collectionView = collectionView else { return elementsLayoutAttributes }

        elementsLayoutAttributes.forEach { karaokeLayoutAttributes in
            self.update(karaokeLayoutAttributes: karaokeLayoutAttributes, in: collectionView)
        }

        return elementsLayoutAttributes
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributesForItem = dynamicAnimator.layoutAttributesForCell(at: indexPath) else {
            return super.layoutAttributesForItem(at: indexPath)
        }

        return layoutAttributesForItem
    }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {

        guard self.collectionView != nil else { return false }

        dynamicAnimator.behaviors.compactMap { $0 as? UIAttachmentBehavior }.forEach { behavior in
            guard let dynamicItem = behavior.items.first else { return }
            self.dynamicAnimator.updateItem(usingCurrentState: dynamicItem)
        }

        return false
    }

    open func update(karaokeLayoutAttributes: KaraokeCollectionViewLayoutAttributes, in collectionView: UICollectionView) {

        karaokeLayoutAttributes.zIndex = karaokeLayoutAttributes.indexPath.item

        let boundsCenterOffset = CGPoint(x: karaokeLayoutAttributes.center.x - collectionView.bounds.midX - sectionInset.left,
                                         y: karaokeLayoutAttributes.center.y - collectionView.bounds.midY - sectionInset.top)
        karaokeLayoutAttributes.boundsCenterOffset = boundsCenterOffset
        karaokeLayoutAttributes.activeDistance = karaokeLayoutAttributes.frame.height + self.minimumLineSpacing
    }

    open func itemSize(at indexPath: IndexPath, with viewModel: KaraokeCollectionViewFlowLayoutViewModel) -> CGSize {

        guard let collectionView = self.collectionView else { return CGSize.zero }

        let width = collectionView.frame.width - (self.sectionInset.left + self.sectionInset.right)
        var itemSize = viewModel.itemSize(at: indexPath, for: width)

        itemSize.height += 2

        return itemSize
    }
}

class KaraokeScrollCollectionViewFlowLayout: KaraokeCollectionViewFlowLayout {
}

class KaraokeOnePhraseCollectionViewFlowLayout: KaraokeCollectionViewFlowLayout {

    open override func update(karaokeLayoutAttributes: KaraokeCollectionViewLayoutAttributes, in collectionView: UICollectionView) {

        super.update(karaokeLayoutAttributes: karaokeLayoutAttributes, in: collectionView)


        if abs(karaokeLayoutAttributes.boundsCenterOffset.y) <= karaokeLayoutAttributes.frame.height + 10.0 {
            let scale = 1.0 - (0.4 * abs(karaokeLayoutAttributes.boundsCenterOffset.y) / (karaokeLayoutAttributes.frame.height + 10.0))

            karaokeLayoutAttributes.transform = CGAffineTransform(scaleX: scale, y: scale)

        } else {
            karaokeLayoutAttributes.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        }

    }

    open override func itemSize(at indexPath: IndexPath, with viewModel: KaraokeCollectionViewFlowLayoutViewModel) -> CGSize {

        guard let collectionView = self.collectionView else { return CGSize.zero }

        let itemSize = super.itemSize(at: indexPath, with: viewModel)

        return CGSize(width: itemSize.width, height: max(itemSize.height, collectionView.frame.height / 3))
    }
}
