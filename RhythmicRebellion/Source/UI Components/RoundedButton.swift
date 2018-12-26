//
//  RoundedButton.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/21/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
open class RoundedButton: UIButton {

    @IBInspectable
    public var isRounded: Bool = true {
        didSet {
            self.setNeedsLayout()
        }
    }

    open override var clipsToBounds: Bool {
        get {
            guard isRounded == false else { return super.clipsToBounds }
            return true
        }

        set { super.clipsToBounds = newValue }
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = isRounded ? min(self.bounds.midX, self.bounds.midY) : 0
    }
}
