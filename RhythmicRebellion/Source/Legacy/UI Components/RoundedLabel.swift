//
//  RoundedLabel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 6/22/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
open class RoundedLabel: UILabel {

    @IBInspectable
    public var cornerRadius: CGFloat {
        get { return self.layer.cornerRadius }
        set { self.layer.cornerRadius = newValue }
    }

}
