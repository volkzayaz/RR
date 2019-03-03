//
//  View+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 11/16/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

extension UIView {

    func makeSnapshotImage(for rect: CGRect, afterScreenUpdates: Bool = true) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(self.bounds.size, true, 1)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: afterScreenUpdates)
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()

        return image
    }
}
