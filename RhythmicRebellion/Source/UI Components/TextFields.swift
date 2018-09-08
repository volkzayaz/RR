//
//  TextFields.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/3/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import UIKit
import MaterialTextField

class CountryTextField: MFTextField {

    var country: Country? {
        didSet {
            self.text = self.country?.name ?? ""
        }
    }
}

class RegionTextField: MFTextField {

    var region: Region? {
        didSet {
            self.text = self.region?.name ?? ""
        }
    }
}

class CityTextField: MFTextField {

    var city: City? {
        didSet {
            self.text = self.city?.name ?? ""
        }
    }
}

class HobbiesTextField: MFTextField {

    var hobbies: [Hobby]? {
        didSet {
            guard let hobbies = self.hobbies else { self.text = ""; return }
            self.text = hobbies.map { $0.name }.joined(separator: ", ")
        }
    }
}

class HowHearTextField: MFTextField {

    var howHear: HowHear? {
        didSet {
            self.text = howHear?.name ?? ""
        }
    }
}
