//
//  UIColor+Extentions.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

extension UIColor {

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
