//
//  UIColor+Extentions.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

extension UIColor {

    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(fromHex:Int) {
        self.init(red:(fromHex >> 16) & 0xff, green:(fromHex >> 8) & 0xff, blue:fromHex & 0xff)
    }
    
    class func gradientColor(from fromColor: UIColor, to toColor: UIColor, percentage: CGFloat) -> UIColor {
        guard percentage > 0, percentage < 1 else {
            guard percentage >= 1 else { return fromColor }
            return toColor
        }

        var fromColorRed: CGFloat = 0.0
        var fromColorGreen: CGFloat = 0.0
        var fromColorBlue: CGFloat = 0.0
        var fromColorAlpha: CGFloat = 0.0

        var toColorRed: CGFloat = 0.0
        var toColorGreen: CGFloat = 0.0
        var toColorBlue: CGFloat = 0.0
        var toColorAlpha: CGFloat = 0.0


        guard fromColor.getRed(&fromColorRed, green: &fromColorGreen, blue: &fromColorBlue, alpha: &fromColorAlpha) == true,
            toColor.getRed(&toColorRed, green: &toColorGreen, blue: &toColorBlue, alpha: &toColorAlpha) == true else {
                guard percentage >= 0.5 else { return fromColor }
                return toColor
        }

        return UIColor(red: fromColorRed + percentage * (toColorRed - fromColorRed),
                       green: fromColorGreen + percentage * (toColorGreen - fromColorGreen),
                       blue: fromColorBlue + percentage * (toColorBlue - fromColorBlue),
                       alpha: fromColorAlpha + percentage * (toColorAlpha - fromColorAlpha))
    }


    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            rendererContext.cgContext.setFillColor(self.cgColor)
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
}


extension UIColor {
    
    static let primaryPink = UIColor(fromHex: 0xFF3EA7)
    static let blockedYellow = UIColor(fromHex: 0xF8E71C)
    
}
