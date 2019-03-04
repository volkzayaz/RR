//
//  TrackPreviewOptionsFormatter.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/26/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class TextImageGenerator {

    let font: UIFont
    var cachedImages: [String : UIImage]

    init(font: UIFont) {
        self.font = font
        cachedImages = [String : UIImage]()
    }

    func image(for text: String) -> UIImage? {

        var cachedImage = self.cachedImages[text]

        if cachedImage == nil {
            let attributes = [NSAttributedString.Key.font: self.font] as [NSAttributedString.Key : Any]

            let stringSize = text.size(withAttributes: attributes)

            UIGraphicsBeginImageContextWithOptions(stringSize, false, 0)
            text.draw(in: CGRect(origin: CGPoint.zero, size: stringSize), withAttributes: attributes)
            cachedImage = UIGraphicsGetImageFromCurrentImageContext()?.withRenderingMode(.alwaysTemplate);
            UIGraphicsEndImageContext();

            self.cachedImages[text] = cachedImage

        }

        return cachedImage
    }
}
