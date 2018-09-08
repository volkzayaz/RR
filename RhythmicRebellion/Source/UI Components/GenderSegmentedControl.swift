//
//  SegmentedControl.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/7/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit

class GenderSegmentedControl: UISegmentedControl {

    var gender: Gender? {
        guard self.selectedSegmentIndex != -1 else { return nil }
        return Gender(rawValue: self.selectedSegmentIndex + 1)
    }
}
