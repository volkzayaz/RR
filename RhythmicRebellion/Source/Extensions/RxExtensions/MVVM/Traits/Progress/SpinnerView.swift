//
//  ProgressView.swift
//     
//
//  Created by Vlad Soroka on 10/11/16.
//  Copyright © 2016    All rights reserved.
//

import UIKit

class SpinnerView : UIImageView {
    
    convenience init() {
        
        let image = UIImage(named: "InfinityMark") //R.image.spinner()!
        
        self.init(image: image)
        
        let animationDuration: CFTimeInterval = 0.8;
        let linearCurve = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0;
        animation.toValue = Double.pi * 2
        animation.duration = animationDuration;
        animation.timingFunction = linearCurve;
        animation.isRemovedOnCompletion = false
        animation.repeatCount = Float.greatestFiniteMagnitude;
        animation.fillMode = CAMediaTimingFillMode.forwards;
        animation.autoreverses = false;
        self.layer.add(animation, forKey:"rotate")
        
        self.backgroundColor = UIColor.clear
        
    }
    
}
