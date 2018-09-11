//
//  RestorePasswordViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 9/10/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import UIKit
import SwiftValidator

protocol RestorePasswordViewModel: class {

    var defaultTextColor: UIColor { get }
    var defaultTintColor: UIColor { get }

    var errorColor: UIColor { get }

    var restorePasswordErrorDescription: String? { get }

    var isRestorePasswordSucced: Bool { get }

    func load(with delegate: RestorePasswordViewModelDelegate)

    func registerEmailField(_ emailField: ValidatableField)

    func validateField(_ validateField: ValidatableField?)

    func restorePassword()
}

protocol RestorePasswordViewModelDelegate: class, ErrorPresnting {

    func refreshUI()

    func refreshField(field: ValidatableField, didValidate error: ValidationError?)

    func refreshEmailField(with email: String?)
}
