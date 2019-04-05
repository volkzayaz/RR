//
//  ValidatebleField+Extension.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 8/30/18.
//  Copyright © 2018 Patron Empowerment, LLC. All rights reserved.
//

import Foundation
import SwiftValidator

extension GenderSegmentedControl: Validatable {

    public var validationText: String {
        guard self.selectedSegmentIndex != -1 else { return "" }
        return String(self.selectedSegmentIndex)
    }
}

extension HobbiesContainerView: Validatable {

    public var validationText: String {
        guard let hobbies = self.hobbies else { return "" }
        return hobbies.map { $0.name }.joined(separator: ", ")
    }
}

extension GenresContainerView: Validatable {

    public var validationText: String {
        guard let genres = self.genres else { return "" }
        return genres.map { $0.name }.joined(separator: ", ")
    }
}

protocol ValidatebleFieldWrapper {
    var textField: UITextField? { get }
}


class MaskedFieldWrapperWrapper: ValidatebleFieldWrapper, Validatable {

    private(set) weak var maskedTextField: MaskedTextField?

    public var textField: UITextField? { return self.maskedTextField }

    public var text: String? { return self.maskedTextField?.text }
    public var unmaskedText: String? { return self.maskedTextField?.unmaskedText }
    public var validationText: String { return self.maskedTextField?.unmaskedText ?? "" }

    init(with maskedTextField: MaskedTextField) {
        self.maskedTextField = maskedTextField
    }
}
