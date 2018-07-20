//
//  SignInViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import SwiftValidator

protocol SignInViewModel: class {

    var defaultTextColor: UIColor { get }
    var defaultTintColor: UIColor { get }

    var errorColor: UIColor { get }

    var signInErrorDescription: String? { get }

    func load(with delegate: SignInViewModelDelegate)

    func registerEmailField(emailField: ValidatableField)
    func registerPasswordField(passwordField: ValidatableField)

    func validateField(field: ValidatableField)

    func signIn()
}

protocol SignInViewModelDelegate: class {

    func refreshUI()

    func refreshEmailField(field: ValidatableField, didValidate error: ValidationError?)
    func refreshPasswordField(field: ValidatableField, didValidate error: ValidationError?)

    func show(error: Error)

}
