//
//  ValidatebleField+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import SwiftValidator

protocol DateValidatableField: ValidatableField {

    var date: Date? { get }
}

extension DateTextField: DateValidatableField {
    
}

protocol CountryValidatableField: ValidatableField {
    var country: Country? { get }
}

extension CountryTextField: CountryValidatableField {

}

protocol RegionValidatableField: ValidatableField {
    var region: Region? { get }
}

extension RegionTextField: RegionValidatableField {

}

protocol CityValidatableField: ValidatableField {
    var city: City? { get }
}

extension CityTextField: CityValidatableField {

}

protocol HobbiesValidatableField: ValidatableField {
    var hobbies: [Hobby]? { get }
}

extension HobbiesTextField: HobbiesValidatableField {

}

protocol HowHearValidatableField: ValidatableField {
    var howHear: HowHear? { get }
}

extension HowHearTextField: HowHearValidatableField {

}

protocol GenderValidatableField: ValidatableField {
    var gender: Gender? { get }
}

extension GenderSegmentedControl: GenderValidatableField {

    public var validationText: String {
        guard self.selectedSegmentIndex != -1 else { return "" }
        return String(self.selectedSegmentIndex)
    }
}
