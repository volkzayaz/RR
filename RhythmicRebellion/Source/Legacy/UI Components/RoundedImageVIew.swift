//
//  RoundedImageVIew.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/11/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedImageView: UIImageView {

    @IBInspectable
    public var isRounded: Bool = true {
        didSet {
            self.setNeedsLayout()
        }
    }

    public override var clipsToBounds: Bool {
        get {
            guard isRounded == false else { return super.clipsToBounds }
            return true
        }

        set { super.clipsToBounds = newValue }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = isRounded ? self.bounds.midX : 0
    }
}
