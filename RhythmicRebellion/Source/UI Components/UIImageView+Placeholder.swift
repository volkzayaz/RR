//
//  UIImageView+Placeholder.swift
//  RhythmicRebellion
//
//  Created by Petro on 8/15/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

extension UIImageView {
    func makePlaylistPlaceholder() {
        self.contentMode = .center
        self.backgroundColor = UIColor(red: 0.35, green: 0.35, blue: 0.56, alpha: 1.0)
        self.image = UIImage(named: "playlistPlaceholder")
    }
}
