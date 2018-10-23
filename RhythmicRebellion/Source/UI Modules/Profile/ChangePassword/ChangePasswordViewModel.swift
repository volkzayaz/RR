//
//  ChangePasswordViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/22/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import SwiftValidator

protocol ChangePasswordViewModel: class {

    var defaultTextColor: UIColor { get }
    var defaultTintColor: UIColor { get }

    var errorColor: UIColor { get }

    var changePasswordErrorDescription: String? { get }

    var isChangePasswordSucced: Bool { get }
    
    func load(with delegate: ChangePasswordViewModelDelegate)

    func registerCurrentPasswordField(_ currentPasswordField: ValidatableField)
    func registerNewPasswordField(_ newPasswordField: ValidatableField)
    func registerConfirmPasswordField(_ confirmPasswordField: ValidatableField, newPasswordField: ValidatableField)

    func validateField(_ validateField: ValidatableField?)
    
    func changePassword()

    func restart()
}

protocol ChangePasswordViewModelDelegate: class, ErrorPresenting {

    func refreshUI()

    func refreshField(field: ValidatableField, didValidate validationError: ValidationError?)

}
