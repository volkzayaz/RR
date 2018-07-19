//
//  SignInControllerViewModel.swift
//  RhythmicRebellion
//
//  Created by Alexander Obolentsev on 7/18/18.
//  Copyright (c) 2018 Patron Empowerment, LLC. All rights reserved.
//
//

import Foundation
import SwiftValidator

struct SignInUserCredentials: UserCredentials {
    let email: String
    let password: String
}

final class SignInControllerViewModel: SignInViewModel {

    // MARK: - Private properties -

    private(set) weak var delegate: SignInViewModelDelegate?
    private(set) weak var router: SignInRouter?
    private(set) weak var application: Application?

    private(set) var signInErrorDescription: String?

    private let validator: Validator
    private var emailField: ValidatableField?
    private var passwordField: ValidatableField?

    // MARK: - Lifecycle -

    init(router: SignInRouter, application: Application) {
        self.router = router
        self.application = application
        self.validator = Validator()
    }

    func load(with delegate: SignInViewModelDelegate) {
        self.delegate = delegate

        self.validator.styleTransformers(success:{ (validationRule) -> Void in
            validationRule.errorLabel?.isHidden = true
            validationRule.errorLabel?.text = ""
        }, error:{ (validationError) -> Void in
            validationError.errorLabel?.isHidden = false
            validationError.errorLabel?.text = validationError.errorMessage
        })
    }

    func registerEmailField(emailField: ValidatableField, emailErrorLabel: UILabel? = nil) {

        self.emailField = emailField
        let emailRules: [Rule] = [RequiredRule(message: "The field is required"),
                                  EmailRule(message: "Email is wrong")]
        self.validator.registerField(emailField, errorLabel: emailErrorLabel, rules: emailRules)
    }

    func registerPasswordField(passwordField: ValidatableField, passwordErrorLabel: UILabel? = nil) {
        self.passwordField = passwordField
        let passwordRules: [Rule] = [RequiredRule(message: "The password field is required")]
        self.validator.registerField(passwordField, errorLabel: passwordErrorLabel, rules: passwordRules)
    }

    func validateField(field: ValidatableField) {
        self.validator.validateField(field) { (error) in

        }
    }

    func signIn() {
        self.validator.validate { [unowned self] (error) in
            guard error.isEmpty else { return }
            guard let email = self.emailField?.validationText, let password = self.passwordField?.validationText else { return }

            let signInUserCredentials = SignInUserCredentials(email: email, password: password)

            self.application?.signIn(with: signInUserCredentials, completion: { [weak self] (error) in

                guard let error = error else { return }
                guard let appError = error as? AppError, let appErrorGroup = appError.source else {
                    self?.signInErrorDescription = error.localizedDescription
                    self?.delegate?.refreshUI()
                    return
                }

                switch appErrorGroup {
                case RestApiServiceError.serverError( _, let errors):
                    self?.signInErrorDescription = errors["email"]?.first
                default:
                    self?.signInErrorDescription = error.localizedDescription
                }

                self?.delegate?.refreshUI()
            })

        }
    }
}
