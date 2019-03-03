//
//  VerticalButton.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/4/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
class VerticalButton: UIButton {

    override var isEnabled: Bool { didSet { self.tintColor = self.currentTitleColor } }
    override var isSelected: Bool { didSet { self.tintColor = self.currentTitleColor } }
    override var isHighlighted: Bool { didSet { self.tintColor = self.currentTitleColor } }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.titleLabel?.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.titleLabel?.textAlignment = .center
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        self.setNeedsLayout()
        self.setNeedsDisplay()
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageRect = super.imageRect(forContentRect: contentRect)
        return CGRect(origin: CGPoint(x: (contentRect.width - imageRect.width) / 2.0 , y: 0), size: imageRect.size)
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let titleRect = super.titleRect(forContentRect: contentRect)

        return CGRect(origin: CGPoint(x: 0, y: contentRect.maxY - titleRect.height), size: CGSize(width: contentRect.width, height: titleRect.height))
    }

    override var intrinsicContentSize: CGSize {

        let imageSize = self.imageView?.intrinsicContentSize ?? CGSize.zero
        let titleSize = self.titleLabel?.intrinsicContentSize ?? CGSize.zero

        return CGSize(width: max(imageSize.width, titleSize.width),
                      height: imageSize.height + titleSize.height)
    }
}
