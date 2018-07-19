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

    var signInErrorDescription: String? { get }

    func load(with delegate: SignInViewModelDelegate)

    func registerEmailField(emailField: ValidatableField, emailErrorLabel: UILabel?)
    func registerPasswordField(passwordField: ValidatableField, passwordErrorLabel: UILabel?)

    func validateField(field: ValidatableField)

    func signIn()
}

protocol SignInViewModelDelegate: class {

    func refreshUI()

}
