//
//  ProgressView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/27/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
class ProgressView: UISlider {

    @IBInspectable
    var restrictedTrackTintColor: UIColor = UIColor.clear {
        didSet { self.setNeedsDisplay() }
    }

    var restrictedValue: Float? {
        didSet { self.setNeedsDisplay() }
    }

//    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
//        let value = super.beginTracking(touch, with: event)
//        print("beginTracking")
//        return value
//    }
//
//    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
//        let value = super.continueTracking(touch, with: event)
//        print("continueTracking")
//        return value
//    }
//
//    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
//        super.endTracking(touch, with: event)
//        print("endTracking")
//    }
//
//    override func cancelTracking(with event: UIEvent?) {
//        super.cancelTracking(with: event)
//        print("cancelTracking")
//    }


    override func draw(_ rect: CGRect) {
        super.draw(rect)

        if let restrictedValue = self.restrictedValue, restrictedValue > 0.0 {
            var restrictedTrackRect = self.trackRect(forBounds: self.bounds)
            let thumbRect = self.thumbRect(forBounds: self.bounds, trackRect: restrictedTrackRect, value: self.value)
            restrictedTrackRect.size.width = ((self.bounds.width - thumbRect.width) * CGFloat(restrictedValue) + thumbRect.width).rounded() - 2 * restrictedTrackRect.origin.x
            restrictedTrackRect.origin.x += 1

            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()

            context?.setFillColor(self.restrictedTrackTintColor.cgColor)
            context?.fill(restrictedTrackRect)

            context?.restoreGState()
        }
    }
}
