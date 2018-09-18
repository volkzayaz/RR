//
//  TagsView.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/18/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import CloudTagView

class TagsView: CloudTagView {

    override func layoutSubviews() {
        super.layoutSubviews()

        self.invalidateIntrinsicContentSize()
    }
}
