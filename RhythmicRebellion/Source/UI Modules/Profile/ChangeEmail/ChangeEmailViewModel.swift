//
//  ChangeEmailViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/24/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import SwiftValidator

protocol ChangeEmailViewModel: class {

    var defaultTextColor: UIColor { get }
    var defaultTintColor: UIColor { get }

    var errorColor: UIColor { get }

    var changeEmailErrorDescription: String? { get }

    var isChangeEmailSucced: Bool { get }

    func load(with delegate: ChangeEmailViewModelDelegate)

    func registerNewEmailField(_ newPasswordField: ValidatableField)
    func registerCurrentPasswordField(_ currentPasswordField: ValidatableField)

    func validateField(_ validateField: ValidatableField?)

    func changeEmail()

    func restart()
}

protocol ChangeEmailViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

    func refreshField(field: ValidatableField, didValidate validationError: ValidationError?)

}
