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
        get {
            guard self.selectedSegmentIndex != -1 else { return nil }
            return Gender(rawValue: self.selectedSegmentIndex + 1)
        }

        set {
            guard let gender = newValue, self.numberOfSegments > gender.rawValue - 1 else { self.selectedSegmentIndex = -1; return }
            self.selectedSegmentIndex = gender.rawValue - 1
        }
    }
}
