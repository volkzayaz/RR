//
//  GradientView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/1/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {

    @IBInspectable var startColor:   UIColor = .black { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = .white { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.0 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   1.0 { didSet { updateLocations() }}

    @IBInspectable var startPoint: CGPoint {
        get { return self.gradientLayer.startPoint }
        set { self.gradientLayer.startPoint = newValue }
    }
    @IBInspectable var endPoint: CGPoint {
        get { return self.gradientLayer.endPoint }
        set { self.gradientLayer.endPoint = newValue }
    }

    override class var layerClass: AnyClass { return CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }
    func updateColors() {
        gradientLayer.colors    = [startColor.cgColor, endColor.cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLocations()
        updateColors()
    }
}


