//
//  UIColor+Extentions.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/23/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            rendererContext.cgContext.setFillColor(self.cgColor)
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
}
