//
//  ChangePasswordControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 10/22/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator

final class ChangePasswordControllerViewModel: ChangePasswordViewModel {

    // MARK: - Public properties -

    var defaultTextColor: UIColor { return #colorLiteral(red: 0.1780987382, green: 0.2085041404, blue: 0.4644742608, alpha: 1) }
    var defaultTintColor: UIColor { return #colorLiteral(red: 0.1468808055, green: 0.1904500723, blue: 0.8971034884, alpha: 1) }

    var errorColor: UIColor { return #colorLiteral(red: 0.9567829967, green: 0.2645464838, blue: 0.213359952, alpha: 1) }

    // MARK: - Private properties -

    private(set) var application: Application

    private(set) weak var delegate: ChangePasswordViewModelDelegate?
    private(set) weak var router: ChangePasswordRouter?

    // MARK: - Lifecycle -

    private(set) var isChangePasswordSucced: Bool = false

    private let validator: Validator

    private(set) var changePasswordErrorDescription: String?

    private var currentPasswordField: ValidatableField?
    private var newPasswordField: ValidatableField?
    private var confirmPasswordField: ValidatableField?



    init(router: ChangePasswordRouter, application: Application) {
        self.router = router
        self.application = application
        self.validator = Validator()
    }

    func load(with delegate: ChangePasswordViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ [unowned self] (validationRule) -> Void in
            self.delegate?.refreshField(field: validationRule.field, didValidate: nil)
            }, error:{ (validationError) -> Void in
                self.delegate?.refreshField(field: validationError.field, didValidate: validationError)
        })

        self.delegate?.refreshUI()
    }

    func registerCurrentPasswordField(_ currentPasswordField: ValidatableField) {
        let passwordRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Current Password field is required.",
                                                                             comment: "Password validataion message")),
                                     MinLengthRule(length: 6,
                                                   message: NSLocalizedString("The Current Password must be at least %ld characters",
                                                                              comment: "Password validataion template"))]
        self.validator.registerField(currentPasswordField, rules: passwordRules)

        self.currentPasswordField = currentPasswordField

        self.delegate?.refreshField(field: currentPasswordField, didValidate: nil)
    }

    func registerNewPasswordField(_ newPasswordField: ValidatableField) {
        let newPasswordRules: [Rule] = [RequiredRule(message: NSLocalizedString("The New Password field is required.",
                                                                                comment: "Password validataion message")),
                                        MinLengthRule(length: 6,
                                                      message: NSLocalizedString("The New Password must be at least %ld characters",
                                                                                 comment: "Password validataion template"))]

        self.validator.registerField(newPasswordField, rules: newPasswordRules)

        self.newPasswordField = newPasswordField

        self.delegate?.refreshField(field: newPasswordField, didValidate: nil)
    }

    func registerConfirmPasswordField(_ confirmPasswordField: ValidatableField, newPasswordField: ValidatableField) {
        let confirmPasswordRules: [Rule] = [RequiredRule(message: NSLocalizedString("The Confirm Password field is required.",
                                                                                    comment: "Repeat Password validataion message")),
                                            ConfirmationRule(confirmField: newPasswordField,
                                                             message: NSLocalizedString("Your Password and Confirmation Password do not match.",
                                                                                        comment: "Repeat Password validataion message"))]

        self.validator.registerField(confirmPasswordField, rules: confirmPasswordRules)

        self.confirmPasswordField = confirmPasswordField

        self.delegate?.refreshField(field: confirmPasswordField, didValidate: nil)
    }

    func validateField(_ validateField: ValidatableField?) {
        guard let validateField = validateField else { return }
        self.validator.validateField(validateField) { (validationError) in }

        if validateField === self.newPasswordField,
            let confirmPasswordField = self.confirmPasswordField,
            !confirmPasswordField.validationText.isEmpty {
            self.validator.validateField(confirmPasswordField) { (validationError) in }
        }
    }

    func validatebleField(for key: String) -> ValidatableField? {

        switch key {
        case "current_password": return self.currentPasswordField
        case "new_password": return self.newPasswordField
        case "confirm_password": return self.confirmPasswordField
        default: break
        }

        return nil
    }


    func changePassword() {
        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let currentPassword = self.currentPasswordField?.validationText,
                let newPassword = self.newPasswordField?.validationText,
                let confirmPassword = self.confirmPasswordField?.validationText else { return }

            self.application.changePassword(currentPassword: currentPassword,
                                            newPassword: newPassword,
                                            newPasswordConfirmation:confirmPassword,
                                            completion: { [weak self] (changePasswordResult) in
                                                switch changePasswordResult {
                                                case .success(_):
                                                    self?.isChangePasswordSucced = true
                                                    self?.delegate?.refreshUI()
                                                case .failure(let error):
                                                    guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                                                        self?.delegate?.show(error: error)
                                                        return
                                                    }

                                                    switch appErrorGroup {
                                                    case RestApiServiceError.serverError( let errorDescription, let errors):
                                                        self?.changePasswordErrorDescription = errorDescription
                                                        for (key, errorStrings) in errors {
                                                            guard let validatebleField = self?.validatebleField(for: key), let validatebleFieldErrorString = errorStrings.first else { continue }

                                                            let validationError = ValidationError(field: validatebleField, errorLabel: nil, error: validatebleFieldErrorString)
                                                            self?.delegate?.refreshField(field: validatebleField, didValidate: validationError)
                                                        }

                                                    default:
                                                        self?.delegate?.show(error: error)
                                                    }

                                                    self?.delegate?.refreshUI()

                                                }
            })
        }
    }
}
