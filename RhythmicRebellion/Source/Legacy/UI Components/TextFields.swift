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

    var city: CityInfo? {
        didSet {
            self.text = self.city?.name ?? ""
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

class LanguageTextField: MFTextField {

    var language: Language? {
        didSet {
            self.text = language?.name ?? ""
        }
    }

}
