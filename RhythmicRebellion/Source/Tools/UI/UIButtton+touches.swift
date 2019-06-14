//
//  UIButtton+touches.swift
//  RhythmicRebellion
//
//  Created by Vlad Soroka on 6/14/19.
//  Copyright © 2019 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class DaButton: UIButton {
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = true
        super.touchesBegan(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        super.touchesEnded(touches, with: event)
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHighlighted = false
        super.touchesCancelled(touches, with: event)
    }
    
}
