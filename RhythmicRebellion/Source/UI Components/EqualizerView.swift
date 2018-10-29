//
//  EqualizerView.swift
//  TestEqualizer
//
//  Created by Petro on 8/16/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class EqualizerView: UIView {
    
    var gradient1 : CAGradientLayer!
    var gradient2 : CAGradientLayer!
    var gradient3 : CAGradientLayer!
    
    var gap : CGFloat {
        return 2
    }
    
    var barWidth : CGFloat {
        return (self.frame.width - CGFloat(2 * gap)) / 3
    }
    var barHeight : CGFloat {
        return self.frame.height - 2 * gap
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        gradient1 = barLayer(with: 0)
        gradient2 = barLayer(with: 1)
        gradient3 = barLayer(with: 2)
        
        self.layer.addSublayer(gradient1)
        self.layer.addSublayer(gradient2)
        self.layer.addSublayer(gradient3)
    }
    
    private func barLayer(with index: Int) -> CAGradientLayer {
        let height = barHeight
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(red: 0.46, green: 0.01, blue: 0.66, alpha: 1.0).cgColor ,
                           UIColor(red: 1, green: 0.24, blue: 0.65, alpha: 1.0).cgColor ]
        gradient.frame = CGRect(x: gap * CGFloat(1 + index) + barWidth * CGFloat(index), y: gap, width: barWidth, height: height)

        return gradient
    }
    
    private func barAnimation(with index: Int) -> CAAnimationGroup {
        let animationDuration = 1.5
        
        let heightAnimation = CAKeyframeAnimation(keyPath: "bounds.size.height")
        heightAnimation.values = gradientHeights(index: index)
        heightAnimation.keyTimes = stride(from: 0, to: 1, by: 0.04).map {NSNumber(value: $0)}
        heightAnimation.duration = animationDuration
        heightAnimation.repeatCount = Float.infinity
        
        let yAnimation = CAKeyframeAnimation(keyPath: "position.y")
        yAnimation.values = gradientHeights(index: index).map {
            return (self.frame.height / 2) + (barHeight - $0) / 2
        }
        yAnimation.keyTimes = stride(from: 0, to: 1, by: 0.04).map {NSNumber(value: $0)}
        yAnimation.duration = animationDuration
        yAnimation.repeatCount = Float.infinity
        
        let group = CAAnimationGroup()
        group.animations = [heightAnimation, yAnimation]
        group.duration = animationDuration
        group.repeatCount = Float.infinity
        return group
    }
        
    func gradientHeights(index: Int) -> [CGFloat] {
        let height = barHeight
        
        let two = height / 7;
        let four = height / 3.5;
        let five = height / 2.8;
        let six = height / 2.333333333;
        let seven = height / 2;
        let eight = height / 1.75;
        let nine = height / 1.555555556;
        let ten = height / 1.4;
        let eleven = height / 1.272727273;
        let twelve = height / 1.166666667;
        let thirteen = height / 1.076923077;
        let fourteen = height;
        
        if index == 0 {
            return [ four, two, four, seven, ten, thirteen, twelve, eleven, eleven, eight, ten, ten, eleven, twelve, thirteen, twelve, twelve, eleven, ten, eleven, twelve, twelve, thirteen, ten, seven, four]
        } else if index == 1 {
            return [twelve, thirteen, twelve, twelve, eleven, eleven, eleven, twelve, twelve, thirteen, thirteen, thirteen, eleven, eight, six, eight, ten, eleven, thirteen, twelve, twelve, eleven, eleven, nine, eleven, twelve]
        } else if index == 2 {
            return [nine, seven, nine, eleven, thirteen, thirteen, fourteen, eleven, nine, eight, seven, five, eight, ten, eleven, thirteen, twelve, eleven, eleven, ten, twelve, thirteen, fourteen, twelve, ten, nine]
        }
        
        return [ four, two, four, seven, ten, thirteen, twelve, eleven, eleven, eight, ten, ten, eleven, twelve, thirteen, twelve, twelve, eleven, ten, eleven, twelve, twelve, thirteen, ten, seven, four]
    }
    
//    private func logIfShown(str: String) {
//        if !self.isHidden {
//            print("\(str) \(Unmanaged.passUnretained(self).toOpaque())")
//        }
//    }
    
    private var animationStarted : Bool = false
    func startAnimating() {
        if (animationStarted) {
//            logIfShown(str: "Start with animation started")
            resume()
        } else {
//            logIfShown(str: "Start without animation started")
            animationStarted = true
            gradient1.add(barAnimation(with: 0), forKey: "heigthanim")
            gradient2.add(barAnimation(with: 1), forKey: "heigthanim")
            gradient3.add(barAnimation(with: 2), forKey: "heigthanim")
        }
    }
    
    private var paused : Bool = false
    func pause() {
        if !animationStarted || paused {
//            logIfShown(str: "Pause without animation or paused \(paused)")
            return
        }
//        logIfShown(str: "PAUSED")
        let pausedTime = self.layer.convertTime(CACurrentMediaTime(), from: nil)
        self.layer.timeOffset = pausedTime
        self.layer.speed = 0.0
        paused = true
    }
    
    func resume() {
        if !animationStarted {
//            logIfShown(str: "RESUME without animation")
            startAnimating()
        } else if paused {
//            logIfShown(str: "RESUME")
            let pausedTime = self.layer.timeOffset
            self.layer.speed = 1.0
            self.layer.timeOffset = 0.0
            self.layer.beginTime = 0.0
            let timeSincePause = self.layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime

            print("timeSincePause: \(timeSincePause)")

            layer.beginTime = timeSincePause;
        } else {
//            logIfShown(str: "RESUME walready playing")
        }

        paused = false
    }
    
}
